import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/services/micro_learning/micro_fact_schema_validator.dart';
import 'package:exam_platform/services/micro_learning/micro_fact_source_gate_validator.dart';
import 'package:exam_platform/services/micro_learning/micro_fact_claim_gate_validator.dart';
import 'package:exam_platform/services/micro_learning/micro_fact_rights_gate_validator.dart';
import 'package:exam_platform/services/micro_learning/micro_fact_curriculum_gate_validator.dart';
import 'package:exam_platform/services/micro_learning/micro_fact_startup_suitability_gate_validator.dart';
import 'package:exam_platform/services/micro_learning/micro_fact_corpus_integrity_validator.dart';

const _releaseDate = '2026-09-24';
const _maxSourceVerificationAgeDays = 365;

Future<void> main(List<String> args) async {
  final publishedMode = args.contains('--published');

  const bankManifestPath =
      'content/micro_learning/curated_bank_manifest_v1.json';
  const ml9eFreezePath =
      'content/micro_learning/review/ml9e_human_review_freeze.json';
  const authorityPath =
      'content/micro_learning/authority_registry_v1.json';
  const claimPolicyPath =
      'content/micro_learning/claim_semantics_policy_v1.json';
  const rightsPolicyPath =
      'content/micro_learning/rights_provenance_policy_v1.json';
  const curriculumPolicyPath =
      'content/micro_learning/canonical_curriculum_policy_v1.json';
  const curriculumRegistryPath =
      'content/micro_learning/canonical_curriculum_registry_v1.json';
  const pedagogyPolicyPath =
      'content/micro_learning/startup_pedagogy_policy_v1.json';
  const duplicatePolicyPath =
      'content/micro_learning/duplicate_contradiction_policy_v1.json';

  final bankManifest = await _readObject(bankManifestPath);
  final ml9eFreeze = await _readObject(ml9eFreezePath);
  final authority = await _readObject(authorityPath);
  final claimPolicy = await _readObject(claimPolicyPath);
  final rightsPolicy = await _readObject(rightsPolicyPath);
  final curriculumPolicy = await _readObject(curriculumPolicyPath);
  final curriculumRegistry = await _readObject(curriculumRegistryPath);
  final pedagogyPolicy = await _readObject(pedagogyPolicyPath);
  final duplicatePolicy = await _readObject(duplicatePolicyPath);
  if (exitCode != 0) return;

  final issues = <String>[];

  final ml9eLifecycle = ml9eFreeze['lifecycle'];
  if (ml9eFreeze['freezeStatus'] != 'closed_human_review_checkpoint' ||
      ml9eLifecycle is! Map ||
      ml9eLifecycle['validatedFactCount'] != 120 ||
      ml9eLifecycle['publishedFactCount'] != 0 ||
      ml9eLifecycle['startupEligibleFactCount'] != 0) {
    issues.add('ML9F_PARENT_FREEZE: ML-9E closed validation state is required.');
  }

  final slots = bankManifest['slots'];
  if (bankManifest['candidateFactCount'] != 120 ||
      slots is! List ||
      slots.length != 120) {
    issues.add('ML9F_BANK_MANIFEST: expected exactly 120 bound fact slots.');
    _fail(issues);
    return;
  }

  final evidenceById = <String, Map<String, dynamic>>{};
  for (var batch = 1; batch <= 12; batch++) {
    final id = batch.toString().padLeft(2, '0');
    final bundle = await _readObject(
      'content/micro_learning/evidence/ml9c_batch_${id}_gate_evidence.json',
    );
    if (exitCode != 0) return;
    final facts = bundle['facts'];
    if (facts is! List || facts.length != 10) {
      issues.add('ML9F_EVIDENCE_BUNDLE: batch $id must contain 10 records.');
      continue;
    }
    for (final raw in facts.whereType<Map>()) {
      final entry = Map<String, dynamic>.from(raw);
      final factId = entry['microFactId'];
      if (factId is! String || evidenceById.containsKey(factId)) {
        issues.add('ML9F_EVIDENCE_ID: invalid or duplicate evidence for $factId.');
      } else {
        evidenceById[factId] = entry;
      }
    }
  }

  if (evidenceById.length != 120) {
    issues.add(
      'ML9F_EVIDENCE_COVERAGE: expected 120 evidence-bound facts, got '
      '${evidenceById.length}.',
    );
  }

  final actualFacts = <Map<String, dynamic>>[];
  final releaseFacts = <Map<String, dynamic>>[];
  final ids = <String>{};

  var sourceFreshCount = 0;
  var mappedCount = 0;
  var generalCount = 0;

  final releaseDate = DateTime.parse(_releaseDate);

  for (final rawSlot in slots) {
    if (rawSlot is! Map) {
      issues.add('ML9F_SLOT_OBJECT: manifest contains a non-object slot.');
      continue;
    }
    final slot = Map<String, dynamic>.from(rawSlot);
    final factId = slot['microFactId'];
    final path = slot['candidatePath'];
    if (factId is! String || !ids.add(factId)) {
      issues.add('ML9F_FACT_ID: invalid or duplicate ID $factId.');
      continue;
    }
    if (path is! String || path.isEmpty) {
      issues.add('ML9F_FACT_PATH: missing fact path for $factId.');
      continue;
    }

    final fact = await _readObject(path);
    if (exitCode != 0) return;
    if (fact['microFactId'] != factId || fact['contentVersion'] != 1) {
      issues.add('ML9F_FACT_BINDING: $factId.');
    }

    final expectedStatus = publishedMode ? 'published' : 'validated';
    final expectedStartup = publishedMode;
    if (fact['status'] != expectedStatus) {
      issues.add(
        'ML9F_LIFECYCLE_STATUS: $factId expected $expectedStatus, got '
        '${fact['status']}.',
      );
    }
    final runtime = fact['runtime'];
    if (runtime is! Map || runtime['startupEligible'] != expectedStartup) {
      issues.add(
        'ML9F_STARTUP_STATE: $factId expected startupEligible=$expectedStartup.',
      );
    }

    final review = Map<String, dynamic>.from(fact['review'] as Map);
    for (final field in const [
      'technicalStatus',
      'sourceStatus',
      'pedagogyStatus',
      'copyrightStatus',
      'uiStatus',
      'humanTechnicalStatus',
    ]) {
      if (review[field] != 'pass') {
        issues.add('ML9F_FACT_REVIEW: $factId $field is not pass.');
      }
    }
    if (review['reviewedAt'] != _releaseDate ||
        review['nextReviewDueAt'] != '2027-09-24') {
      issues.add('ML9F_FACT_REVIEW_DATES: $factId review dates drifted.');
    }

    final provenance = Map<String, dynamic>.from(fact['provenance'] as Map);
    final sourceVerifiedAt = _strictDate(provenance['sourceVerifiedAt']);
    if (sourceVerifiedAt == null ||
        sourceVerifiedAt.isAfter(releaseDate) ||
        releaseDate.difference(sourceVerifiedAt).inDays >
            _maxSourceVerificationAgeDays) {
      issues.add('ML9F_SOURCE_FRESHNESS: $factId source verification is stale.');
    } else {
      sourceFreshCount++;
    }

    final evidence = evidenceById[factId];
    if (evidence == null) {
      issues.add('ML9F_EVIDENCE_MISSING: $factId.');
      continue;
    }

    final rightsEvidence =
        Map<String, dynamic>.from(evidence['rightsEvidence'] as Map);
    final rightsReview =
        Map<String, dynamic>.from(rightsEvidence['review'] as Map);
    if (rightsReview['status'] != 'pass' ||
        rightsReview['humanReviewed'] != true) {
      issues.add('ML9F_RIGHTS_HUMAN_PASS: $factId.');
    }

    final curriculum = Map<String, dynamic>.from(fact['curriculum'] as Map);
    Map<String, dynamic>? curriculumEvidence;
    if (curriculum['scope'] == 'mapped') {
      mappedCount++;
      final rawMapping = evidence['curriculumEvidence'];
      if (rawMapping is! Map) {
        issues.add('ML9F_MAPPING_MISSING: $factId.');
      } else {
        curriculumEvidence = Map<String, dynamic>.from(rawMapping);
        final mappingReview =
            Map<String, dynamic>.from(curriculumEvidence['review'] as Map);
        if (mappingReview['status'] != 'pass' ||
            mappingReview['humanReviewed'] != true ||
            mappingReview['conceptAlignmentConfirmed'] != true) {
          issues.add('ML9F_MAPPING_HUMAN_PASS: $factId.');
        }
      }
    } else if (curriculum['scope'] == 'general') {
      generalCount++;
      if (evidence['curriculumEvidence'] != null) {
        issues.add('ML9F_GENERAL_MAPPING_FORBIDDEN: $factId.');
      }
    } else {
      issues.add('ML9F_CURRICULUM_SCOPE: $factId.');
    }

    final pedagogyEvidence =
        Map<String, dynamic>.from(evidence['pedagogyEvidence'] as Map);
    final pedagogyReview =
        Map<String, dynamic>.from(pedagogyEvidence['pedagogyReview'] as Map);
    final accessibilityReview = Map<String, dynamic>.from(
      pedagogyEvidence['accessibilityReview'] as Map,
    );
    if (pedagogyReview['status'] != 'pass' ||
        pedagogyReview['humanReviewed'] != true ||
        accessibilityReview['status'] != 'pass' ||
        accessibilityReview['humanReviewed'] != true) {
      issues.add('ML9F_STARTUP_HUMAN_PASS: $factId.');
    }

    final releaseFact = _deepCopy(fact);
    releaseFact['status'] = 'published';
    final releaseRuntime =
        Map<String, dynamic>.from(releaseFact['runtime'] as Map);
    releaseRuntime['startupEligible'] = true;
    releaseFact['runtime'] = releaseRuntime;

    _addIssues(
      issues,
      'ML2_SCHEMA $factId',
      MicroFactSchemaValidator().validateMap(releaseFact).issues,
    );
    _addIssues(
      issues,
      'ML3_SOURCE $factId',
      const MicroFactSourceGateValidator()
          .validateMaps(
            microFact: releaseFact,
            authorityRegistry: authority,
          )
          .issues,
    );
    _addIssues(
      issues,
      'ML4_CLAIM $factId',
      const MicroFactClaimGateValidator()
          .validateMaps(
            microFact: releaseFact,
            authorityRegistry: authority,
            claimPolicy: claimPolicy,
          )
          .issues,
    );
    _addIssues(
      issues,
      'ML5_RIGHTS $factId',
      const MicroFactRightsGateValidator()
          .validateMaps(
            microFact: releaseFact,
            authorityRegistry: authority,
            claimPolicy: claimPolicy,
            rightsPolicy: rightsPolicy,
            rightsEvidence: rightsEvidence,
          )
          .issues,
    );
    _addIssues(
      issues,
      'ML6_CURRICULUM $factId',
      const MicroFactCurriculumGateValidator()
          .validateMaps(
            microFact: releaseFact,
            authorityRegistry: authority,
            claimPolicy: claimPolicy,
            rightsPolicy: rightsPolicy,
            rightsEvidence: rightsEvidence,
            curriculumPolicy: curriculumPolicy,
            curriculumRegistry: curriculumRegistry,
            curriculumEvidence: curriculumEvidence,
          )
          .issues,
    );
    _addIssues(
      issues,
      'ML7_STARTUP $factId',
      const MicroFactStartupSuitabilityGateValidator()
          .validateMaps(
            microFact: releaseFact,
            authorityRegistry: authority,
            claimPolicy: claimPolicy,
            rightsPolicy: rightsPolicy,
            rightsEvidence: rightsEvidence,
            curriculumPolicy: curriculumPolicy,
            curriculumRegistry: curriculumRegistry,
            curriculumEvidence: curriculumEvidence,
            pedagogyPolicy: pedagogyPolicy,
            pedagogyEvidence: pedagogyEvidence,
          )
          .issues,
    );

    actualFacts.add(fact);
    releaseFacts.add(releaseFact);
  }

  if (actualFacts.length != 120 ||
      releaseFacts.length != 120 ||
      sourceFreshCount != 120 ||
      mappedCount != 114 ||
      generalCount != 6) {
    issues.add(
      'ML9F_COUNTS: expected facts=120 freshSources=120 mapped=114 general=6; '
      'got facts=${actualFacts.length} release=${releaseFacts.length} '
      'fresh=$sourceFreshCount mapped=$mappedCount general=$generalCount.',
    );
  }

  final corpus = const MicroFactCorpusIntegrityValidator().validate(
    facts: releaseFacts,
    policy: duplicatePolicy,
    adjudications: const [],
  );
  for (final issue in corpus.issues) {
    issues.add('ML8_CORPUS: $issue');
  }
  if (corpus.reviewCandidates.isNotEmpty) {
    issues.add(
      'ML9F_ML8_REVIEW_CANDIDATES: '
      '${corpus.reviewCandidates.length} unresolved pair(s).',
    );
  }
  if (corpus.concentrationSignals.isNotEmpty) {
    issues.add(
      'ML9F_ML8_CONCENTRATION: '
      '${corpus.concentrationSignals.length} concentration signal(s).',
    );
  }

  final pairCount = releaseFacts.length * (releaseFacts.length - 1) ~/ 2;
  if (pairCount != 7140) {
    issues.add('ML9F_PAIR_COUNT: expected 7140, got $pairCount.');
  }

  if (issues.isNotEmpty) {
    _fail(issues);
    return;
  }

  stdout.writeln(
    publishedMode
        ? 'ML-9F PUBLISHED CORPUS VALID'
        : 'ML-9F PUBLICATION READINESS VALID',
  );
  stdout.writeln('Facts: 120');
  stdout.writeln('Source-current facts: 120');
  stdout.writeln('Mapped facts: 114');
  stdout.writeln('General-scope facts: 6');
  stdout.writeln('Pairwise ML-8 comparisons: 7140');
  stdout.writeln('Unresolved ML-8 review candidates: 0');
  stdout.writeln('ML-8 concentration signals: 0');
  stdout.writeln(
    'Published facts: ${publishedMode ? 120 : 0}',
  );
  stdout.writeln(
    'Startup-eligible facts: ${publishedMode ? 120 : 0}',
  );
}

Map<String, dynamic> _deepCopy(Map<String, dynamic> value) =>
    Map<String, dynamic>.from(
      jsonDecode(jsonEncode(value)) as Map<String, dynamic>,
    );

DateTime? _strictDate(dynamic value) {
  if (value is! String ||
      !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    return null;
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return null;
  final normalized =
      '${parsed.year.toString().padLeft(4, '0')}-'
      '${parsed.month.toString().padLeft(2, '0')}-'
      '${parsed.day.toString().padLeft(2, '0')}';
  return normalized == value ? parsed : null;
}

void _addIssues(
  List<String> target,
  String prefix,
  Iterable<dynamic> gateIssues,
) {
  for (final issue in gateIssues) {
    target.add('$prefix: $issue');
  }
}

Future<Map<String, dynamic>> _readObject(String path) async {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('ML-9F required file not found: $path');
    exitCode = 2;
    return <String, dynamic>{};
  }
  try {
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is Map<String, dynamic>) return decoded;
  } on FormatException catch (error) {
    stderr.writeln('Invalid JSON in $path: ${error.message}');
    exitCode = 2;
    return <String, dynamic>{};
  }
  stderr.writeln('JSON root must be an object: $path');
  exitCode = 2;
  return <String, dynamic>{};
}

void _fail(List<String> issues) {
  stderr.writeln('ML-9F INVALID with ${issues.length} issue(s):');
  for (final issue in issues) {
    stderr.writeln(' - $issue');
  }
  exitCode = 1;
}
