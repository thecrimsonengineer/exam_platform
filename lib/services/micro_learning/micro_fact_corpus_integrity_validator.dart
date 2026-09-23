import 'corpus_comparison_evidence_validator.dart';
import 'duplicate_contradiction_policy_validator.dart';
import 'micro_fact_corpus_comparison.dart';
import 'micro_fact_schema_validator.dart';

class MicroFactCorpusIntegrityIssue {
  const MicroFactCorpusIntegrityIssue({
    required this.code,
    required this.path,
    required this.message,
  });

  final String code;
  final String path;
  final String message;

  @override
  String toString() => code + ' at ' + path + ': ' + message;
}

class MicroFactCorpusReviewCandidate {
  const MicroFactCorpusReviewCandidate({
    required this.pairKey,
    required this.signals,
    required this.displayJaccard,
    required this.shortJaccard,
    required this.conceptJaccard,
  });

  final String pairKey;
  final Set<String> signals;
  final double displayJaccard;
  final double shortJaccard;
  final double conceptJaccard;
}

class MicroFactCorpusConcentrationSignal {
  const MicroFactCorpusConcentrationSignal({
    required this.code,
    required this.key,
    required this.count,
    required this.share,
  });

  final String code;
  final String key;
  final int count;
  final double? share;
}

class MicroFactCorpusIntegrityResult {
  const MicroFactCorpusIntegrityResult({
    required this.issues,
    required this.reviewCandidates,
    required this.concentrationSignals,
  });

  final List<MicroFactCorpusIntegrityIssue> issues;
  final List<MicroFactCorpusReviewCandidate> reviewCandidates;
  final List<MicroFactCorpusConcentrationSignal> concentrationSignals;

  bool get isValid => issues.isEmpty;
}

class MicroFactCorpusIntegrityValidator {
  const MicroFactCorpusIntegrityValidator();

  MicroFactCorpusIntegrityResult validate({
    required List<Map<String, dynamic>> facts,
    required Map<String, dynamic> policy,
    List<Map<String, dynamic>> adjudications = const [],
  }) {
    final issues = <MicroFactCorpusIntegrityIssue>[];
    final candidates = <MicroFactCorpusReviewCandidate>[];

    final policyResult = const DuplicateContradictionPolicyValidator()
        .validateMap(policy);
    for (final issue in policyResult.issues) {
      _add(
        issues,
        'ML8_POLICY_PREREQUISITE_INVALID',
        issue.path,
        issue.code + ': ' + issue.message,
      );
    }
    if (issues.isNotEmpty) {
      return MicroFactCorpusIntegrityResult(
        issues: List.unmodifiable(issues),
        reviewCandidates: const [],
        concentrationSignals: const [],
      );
    }

    final validFacts = <Map<String, dynamic>>[];
    for (var i = 0; i < facts.length; i++) {
      final result = const MicroFactSchemaValidator().validateMap(facts[i]);
      if (!result.isValid) {
        for (final issue in result.issues) {
          _add(
            issues,
            'ML8_FACT_SCHEMA_INVALID',
            r'$facts[' + i.toString() + ']' + issue.path.substring(1),
            issue.code + ': ' + issue.message,
          );
        }
      } else {
        validFacts.add(facts[i]);
      }
    }

    if (validFacts.length != facts.length) {
      return MicroFactCorpusIntegrityResult(
        issues: List.unmodifiable(issues),
        reviewCandidates: const [],
        concentrationSignals: const [],
      );
    }

    final scope = Map<String, dynamic>.from(policy['corpusScope'] as Map);
    final comparisonStatuses = (scope['comparisonStatuses'] as List)
        .whereType<String>()
        .toSet();
    final activeFacts = validFacts
        .where((fact) => comparisonStatuses.contains(fact['status']))
        .toList(growable: false);

    _validateUniqueActiveIds(activeFacts, issues);

    final adjudicationIndex = <String, Map<String, dynamic>>{};
    for (var i = 0; i < adjudications.length; i++) {
      final evidence = adjudications[i];
      final evidenceResult = const CorpusComparisonEvidenceValidator()
          .validateMap(evidence);
      for (final issue in evidenceResult.issues) {
        _add(
          issues,
          'ML8_EVIDENCE_PREREQUISITE_INVALID',
          r'$adjudications[' + i.toString() + ']' + issue.path.substring(9),
          issue.code + ': ' + issue.message,
        );
      }

      final pairKey = evidence['pairKey'];
      if (pairKey is String) {
        if (adjudicationIndex.containsKey(pairKey)) {
          _add(
            issues,
            'ML8_DUPLICATE_ADJUDICATION',
            r'$adjudications[' + i.toString() + '].pairKey',
            'Only one adjudication record may exist for a fact pair.',
          );
        } else {
          adjudicationIndex[pairKey] = evidence;
        }
      }
    }

    final comparison = const MicroFactCorpusComparison();
    final candidateKeys = <String>{};

    for (var i = 0; i < activeFacts.length; i++) {
      for (var j = i + 1; j < activeFacts.length; j++) {
        final left = activeFacts[i];
        final right = activeFacts[j];

        if (left['microFactId'] == right['microFactId']) {
          continue;
        }

        final pair = comparison.compare(
          left: left,
          right: right,
          policy: policy,
        );

        if (pair.hasExactDuplicate) {
          _add(
            issues,
            'ML8_EXACT_DUPLICATE',
            r'$pairs.' + pair.pairKey,
            'Exact duplicate detected: ' +
                pair.exactDuplicateReasons.join(', ') +
                '. Exact duplicates cannot be waived by adjudication.',
          );
          continue;
        }

        if (!pair.requiresAdjudication) {
          continue;
        }

        candidateKeys.add(pair.pairKey);
        candidates.add(
          MicroFactCorpusReviewCandidate(
            pairKey: pair.pairKey,
            signals: pair.signals,
            displayJaccard: pair.displayJaccard,
            shortJaccard: pair.shortJaccard,
            conceptJaccard: pair.conceptJaccard,
          ),
        );

        final evidence = adjudicationIndex[pair.pairKey];
        if (evidence == null) {
          _add(
            issues,
            'ML8_ADJUDICATION_REQUIRED',
            r'$pairs.' + pair.pairKey,
            'Duplicate/contradiction candidate requires human adjudication.',
          );
          continue;
        }

        _validateEvidenceBinding(
          left: left,
          right: right,
          comparison: pair,
          evidence: evidence,
          policy: policy,
          issues: issues,
        );
      }
    }

    for (final entry in adjudicationIndex.entries) {
      if (!candidateKeys.contains(entry.key)) {
        _add(
          issues,
          'ML8_ORPHAN_ADJUDICATION',
          r'$adjudications.' + entry.key,
          'Adjudication no longer corresponds to a current ML-8 review candidate.',
        );
      }
    }

    final concentrationSignals = _buildConcentrationSignals(
      activeFacts,
      policy,
    );

    return MicroFactCorpusIntegrityResult(
      issues: List.unmodifiable(issues),
      reviewCandidates: List.unmodifiable(candidates),
      concentrationSignals: List.unmodifiable(concentrationSignals),
    );
  }

  void _validateUniqueActiveIds(
    List<Map<String, dynamic>> facts,
    List<MicroFactCorpusIntegrityIssue> issues,
  ) {
    final versionsById = <String, List<int>>{};
    for (final fact in facts) {
      final id = fact['microFactId'] as String;
      final version = fact['contentVersion'] as int;
      versionsById.putIfAbsent(id, () => <int>[]).add(version);
    }

    for (final entry in versionsById.entries) {
      if (entry.value.length > 1) {
        _add(
          issues,
          'ML8_ACTIVE_VERSION_COLLISION',
          r'$facts.' + entry.key,
          'More than one comparison-eligible version is active for ' +
              entry.key +
              ': ' +
              entry.value.join(', ') +
              '.',
        );
      }
    }
  }

  void _validateEvidenceBinding({
    required Map<String, dynamic> left,
    required Map<String, dynamic> right,
    required MicroFactPairComparison comparison,
    required Map<String, dynamic> evidence,
    required Map<String, dynamic> policy,
    required List<MicroFactCorpusIntegrityIssue> issues,
  }) {
    final orderedFacts = [left, right]
      ..sort(
        (a, b) => MicroFactCorpusComparison.factVersionKey(
          a,
        ).compareTo(MicroFactCorpusComparison.factVersionKey(b)),
      );

    final leftRef = Map<String, dynamic>.from(evidence['left'] as Map);
    final rightRef = Map<String, dynamic>.from(evidence['right'] as Map);

    _validateFactRefBinding(
      fact: orderedFacts[0],
      ref: leftRef,
      path: r'$evidence.left',
      issues: issues,
    );
    _validateFactRefBinding(
      fact: orderedFacts[1],
      ref: rightRef,
      path: r'$evidence.right',
      issues: issues,
    );

    final evidenceSignals = (evidence['detectedSignals'] as List)
        .whereType<String>()
        .toSet();
    if (!_setEquals(evidenceSignals, comparison.signals)) {
      _add(
        issues,
        'ML8_EVIDENCE_SIGNAL_DRIFT',
        r'$evidence.detectedSignals',
        'Adjudication signal set no longer matches deterministic ML-8 detection.',
      );
    }

    final review = Map<String, dynamic>.from(evidence['review'] as Map);
    final adjudicationRules = Map<String, dynamic>.from(
      policy['adjudicationRules'] as Map,
    );

    if (review['status'] != 'pass' || review['humanReviewed'] != true) {
      _add(
        issues,
        'ML8_ADJUDICATION_UNRESOLVED',
        r'$evidence.review',
        'Review candidate remains blocked until human adjudication passes.',
      );
    }

    final decision = evidence['decision'];
    final blockDecisions = (adjudicationRules['blockDecisions'] as List)
        .whereType<String>()
        .toSet();
    final passDecisions = (adjudicationRules['passDecisions'] as List)
        .whereType<String>()
        .toSet();

    if (blockDecisions.contains(decision)) {
      _add(
        issues,
        'ML8_ADJUDICATED_BLOCK',
        r'$evidence.decision',
        'Human adjudication concluded that this pair must not coexist.',
      );
    } else if (!passDecisions.contains(decision)) {
      _add(
        issues,
        'ML8_ADJUDICATION_UNRESOLVED',
        r'$evidence.decision',
        'Pair does not have an allowed coexistence decision.',
      );
    }

    _validateEvidenceChronology(
      left: left,
      right: right,
      review: review,
      maxAgeDays: adjudicationRules['maxEvidenceAgeDays'] as int,
      issues: issues,
    );
  }

  void _validateFactRefBinding({
    required Map<String, dynamic> fact,
    required Map<String, dynamic> ref,
    required String path,
    required List<MicroFactCorpusIntegrityIssue> issues,
  }) {
    if (ref['microFactId'] != fact['microFactId']) {
      _add(
        issues,
        'ML8_EVIDENCE_FACT_ID_MISMATCH',
        path + '.microFactId',
        'Adjudication references the wrong MicroFact.',
      );
    }

    if (ref['contentVersion'] != fact['contentVersion']) {
      _add(
        issues,
        'ML8_EVIDENCE_CONTENT_VERSION_MISMATCH',
        path + '.contentVersion',
        'Adjudication references the wrong MicroFact version.',
      );
    }

    final expectedFingerprint = MicroFactCorpusComparison.comparisonFingerprint(
      fact,
    );
    if (ref['comparisonFingerprintSha256'] != expectedFingerprint) {
      _add(
        issues,
        'ML8_EVIDENCE_FINGERPRINT_DRIFT',
        path + '.comparisonFingerprintSha256',
        'MicroFact changed after duplicate/contradiction adjudication.',
      );
    }
  }

  void _validateEvidenceChronology({
    required Map<String, dynamic> left,
    required Map<String, dynamic> right,
    required Map<String, dynamic> review,
    required int maxAgeDays,
    required List<MicroFactCorpusIntegrityIssue> issues,
  }) {
    final reviewedAt = _parseStrictDate(review['reviewedAt']);
    final dueAt = _parseStrictDate(review['nextReviewDueAt']);
    final factReviewDates = <DateTime>[];

    for (final fact in [left, right]) {
      final factReview = Map<String, dynamic>.from(fact['review'] as Map);
      final date = _parseStrictDate(factReview['reviewedAt']);
      if (date != null) factReviewDates.add(date);
    }

    if (reviewedAt != null && factReviewDates.isNotEmpty) {
      final latestFactReview = factReviewDates.reduce(
        (a, b) => a.isAfter(b) ? a : b,
      );
      if (reviewedAt.isBefore(latestFactReview)) {
        _add(
          issues,
          'ML8_ADJUDICATION_PREDATES_FACT_REVIEW',
          r'$evidence.review.reviewedAt',
          'Pair adjudication cannot predate the latest individual fact review.',
        );
      }
    }

    if (reviewedAt != null && dueAt != null) {
      final lifespanDays = dueAt.difference(reviewedAt).inDays;
      if (lifespanDays > maxAgeDays) {
        _add(
          issues,
          'ML8_ADJUDICATION_VALIDITY_TOO_LONG',
          r'$evidence.review.nextReviewDueAt',
          'Adjudication validity exceeds the frozen maximum age.',
        );
      }
    }
  }

  List<MicroFactCorpusConcentrationSignal> _buildConcentrationSignals(
    List<Map<String, dynamic>> facts,
    Map<String, dynamic> policy,
  ) {
    final audit = Map<String, dynamic>.from(
      policy['concentrationAudit'] as Map,
    );
    if (audit['enabled'] != true || facts.isEmpty) {
      return const [];
    }

    final signals = <MicroFactCorpusConcentrationSignal>[];
    final conceptCounts = <String, int>{};
    final sourceLocatorCounts = <String, int>{};
    final authorityCounts = <String, int>{};

    for (final fact in facts) {
      final curriculum = Map<String, dynamic>.from(fact['curriculum'] as Map);
      final provenance = Map<String, dynamic>.from(fact['provenance'] as Map);

      final concepts =
          (curriculum['conceptIds'] as List).whereType<String>().toList()
            ..sort();
      final conceptKey = concepts.join('|');
      conceptCounts[conceptKey] = (conceptCounts[conceptKey] ?? 0) + 1;

      final sourceKey =
          (provenance['sourceRegistryId'] as String) +
          '|' +
          (provenance['sourceLocator'] as String).trim().toLowerCase();
      sourceLocatorCounts[sourceKey] =
          (sourceLocatorCounts[sourceKey] ?? 0) + 1;

      final authority = provenance['sourceRegistryId'] as String;
      authorityCounts[authority] = (authorityCounts[authority] ?? 0) + 1;
    }

    final conceptThreshold = audit['exactConceptSetReviewThreshold'] as int;
    for (final entry in conceptCounts.entries) {
      if (entry.value >= conceptThreshold) {
        signals.add(
          MicroFactCorpusConcentrationSignal(
            code: 'ML8_CONCEPT_SET_CONCENTRATION',
            key: entry.key,
            count: entry.value,
            share: entry.value / facts.length,
          ),
        );
      }
    }

    final locatorThreshold = audit['sameSourceLocatorReviewThreshold'] as int;
    for (final entry in sourceLocatorCounts.entries) {
      if (entry.value >= locatorThreshold) {
        signals.add(
          MicroFactCorpusConcentrationSignal(
            code: 'ML8_SOURCE_LOCATOR_CONCENTRATION',
            key: entry.key,
            count: entry.value,
            share: entry.value / facts.length,
          ),
        );
      }
    }

    final minCorpus = audit['authorityShareMinimumCorpusSize'] as int;
    final shareThreshold = (audit['authorityShareReviewThreshold'] as num)
        .toDouble();
    if (facts.length >= minCorpus) {
      for (final entry in authorityCounts.entries) {
        final share = entry.value / facts.length;
        if (share > shareThreshold) {
          signals.add(
            MicroFactCorpusConcentrationSignal(
              code: 'ML8_AUTHORITY_CONCENTRATION',
              key: entry.key,
              count: entry.value,
              share: share,
            ),
          );
        }
      }
    }

    return signals;
  }

  static DateTime? _parseStrictDate(dynamic value) {
    if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return null;
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;
    final normalized =
        parsed.year.toString().padLeft(4, '0') +
        '-' +
        parsed.month.toString().padLeft(2, '0') +
        '-' +
        parsed.day.toString().padLeft(2, '0');
    return normalized == value ? parsed : null;
  }

  static bool _setEquals(Set<String> left, Set<String> right) =>
      left.length == right.length && left.containsAll(right);

  static void _add(
    List<MicroFactCorpusIntegrityIssue> issues,
    String code,
    String path,
    String message,
  ) {
    issues.add(
      MicroFactCorpusIntegrityIssue(code: code, path: path, message: message),
    );
  }
}
