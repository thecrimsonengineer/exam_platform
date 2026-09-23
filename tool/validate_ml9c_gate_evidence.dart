import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/services/micro_learning/curriculum_mapping_evidence_validator.dart';
import 'package:exam_platform/services/micro_learning/micro_fact_curriculum_gate_validator.dart';
import 'package:exam_platform/services/micro_learning/micro_fact_rights_gate_validator.dart';
import 'package:exam_platform/services/micro_learning/rights_evidence_validator.dart';
import 'package:exam_platform/services/micro_learning/startup_pedagogy_evidence_validator.dart';
import 'package:exam_platform/services/micro_learning/startup_text_metrics.dart';

Future<void> main() async {
  const manifestPath = 'content/micro_learning/curated_bank_manifest_v1.json';
  const authorityPath = 'content/micro_learning/authority_registry_v1.json';
  const claimPolicyPath = 'content/micro_learning/claim_semantics_policy_v1.json';
  const rightsPolicyPath = 'content/micro_learning/rights_provenance_policy_v1.json';
  const curriculumPolicyPath =
      'content/micro_learning/canonical_curriculum_policy_v1.json';
  const curriculumRegistryPath =
      'content/micro_learning/canonical_curriculum_registry_v1.json';
  const pedagogyPolicyPath =
      'content/micro_learning/startup_pedagogy_policy_v1.json';

  final manifest = await _readObject(manifestPath);
  final authority = await _readObject(authorityPath);
  final claimPolicy = await _readObject(claimPolicyPath);
  final rightsPolicy = await _readObject(rightsPolicyPath);
  final curriculumPolicy = await _readObject(curriculumPolicyPath);
  final curriculumRegistry = await _readObject(curriculumRegistryPath);
  final pedagogyPolicy = await _readObject(pedagogyPolicyPath);

  if (exitCode != 0) return;

  final issues = <String>[];
  final slots = (manifest['slots'] as List)
      .whereType<Map>()
      .map(Map<String, dynamic>.from)
      .toList(growable: false);

  if (manifest['candidateFactCount'] != 120 || slots.length != 120) {
    issues.add('ML9C_CORPUS_SIZE: expected exactly 120 candidate slots.');
  }

  final slotById = <String, Map<String, dynamic>>{
    for (final slot in slots) slot['microFactId'] as String: slot,
  };

  final seenFacts = <String>{};
  final seenRights = <String>{};
  final seenMappings = <String>{};
  final seenPedagogy = <String>{};

  var mappedCount = 0;
  var generalCount = 0;
  var rightsPassCount = 0;
  var mappingPassCount = 0;
  var pedagogyPassCount = 0;
  var accessibilityPassCount = 0;

  for (var batch = 1; batch <= 12; batch++) {
    final batchId = batch.toString().padLeft(2, '0');
    final path =
        'content/micro_learning/evidence/ml9c_batch_${batchId}_gate_evidence.json';
    final bundle = await _readObject(path);
    if (bundle.isEmpty && exitCode != 0) return;

    _requireEqual(bundle['schemaVersion'], 1, issues, '$path.schemaVersion');
    _requireEqual(bundle['phase'], 'ML-9C', issues, '$path.phase');
    _requireEqual(
      bundle['batchId'],
      'ml9_batch_$batchId',
      issues,
      '$path.batchId',
    );
    _requireEqual(
      bundle['generationMode'],
      'machine_prepared_pending_human_review',
      issues,
      '$path.generationMode',
    );

    final entries = bundle['facts'];
    if (entries is! List || entries.length != 10) {
      issues.add('ML9C_BATCH_SIZE: $path must contain exactly 10 facts.');
      continue;
    }

    for (final rawEntry in entries) {
      if (rawEntry is! Map) {
        issues.add('ML9C_ENTRY_OBJECT: $path contains a non-object entry.');
        continue;
      }
      final entry = Map<String, dynamic>.from(rawEntry);
      final factId = entry['microFactId'];
      if (factId is! String || !seenFacts.add(factId)) {
        issues.add('ML9C_FACT_ID: invalid or duplicate fact ID $factId.');
        continue;
      }

      final slot = slotById[factId];
      if (slot == null) {
        issues.add('ML9C_FACT_NOT_IN_MANIFEST: $factId.');
        continue;
      }
      final candidatePath = slot['candidatePath'];
      if (candidatePath is! String || candidatePath.isEmpty) {
        issues.add('ML9C_FACT_PATH_MISSING: $factId.');
        continue;
      }

      final fact = await _readObject(candidatePath);
      if (fact.isEmpty && exitCode != 0) return;

      if (fact['status'] != 'review' ||
          (fact['runtime'] as Map)['startupEligible'] != false) {
        issues.add('ML9C_FACT_LIFECYCLE: $factId must remain review/non-startup.');
      }

      final factReview = Map<String, dynamic>.from(fact['review'] as Map);
      for (final field in const [
        'technicalStatus',
        'sourceStatus',
        'pedagogyStatus',
        'copyrightStatus',
        'uiStatus',
        'humanTechnicalStatus',
      ]) {
        if (factReview[field] != 'pending') {
          issues.add('ML9C_FACT_REVIEW_PREMATURE: $factId $field.');
        }
      }

      final rights = _requiredMap(entry['rightsEvidence'], factId, 'rights', issues);
      if (rights != null) {
        final evidenceId = rights['evidenceId'];
        if (evidenceId is! String || !seenRights.add(evidenceId)) {
          issues.add('ML9C_RIGHTS_ID: invalid or duplicate rights evidence for $factId.');
        }

        final result = const RightsEvidenceValidator().validateMap(rights);
        for (final issue in result.issues) {
          issues.add('ML9C_RIGHTS_SCHEMA $factId: $issue');
        }

        final gate = const MicroFactRightsGateValidator().validateMaps(
          microFact: fact,
          authorityRegistry: authority,
          claimPolicy: claimPolicy,
          rightsPolicy: rightsPolicy,
          rightsEvidence: rights,
        );
        for (final issue in gate.issues) {
          issues.add('ML9C_RIGHTS_BINDING $factId: $issue');
        }

        final review = Map<String, dynamic>.from(rights['review'] as Map);
        if (review['status'] == 'pass') rightsPassCount++;
        _requirePendingHumanReview(
          review,
          factId,
          'rights',
          issues,
        );
      }

      final curriculum = Map<String, dynamic>.from(fact['curriculum'] as Map);
      final mappingRaw = entry['curriculumEvidence'];
      Map<String, dynamic>? mapping;

      if (curriculum['scope'] == 'mapped') {
        mappedCount++;
        mapping = _requiredMap(mappingRaw, factId, 'curriculum', issues);
        if (mapping == null) {
          continue;
        }

        final evidenceId = mapping['evidenceId'];
        if (evidenceId is! String || !seenMappings.add(evidenceId)) {
          issues.add('ML9C_MAPPING_ID: invalid or duplicate mapping evidence for $factId.');
        }

        final result = const CurriculumMappingEvidenceValidator().validateMap(
          mapping,
        );
        for (final issue in result.issues) {
          issues.add('ML9C_MAPPING_SCHEMA $factId: $issue');
        }

        final review = Map<String, dynamic>.from(mapping['review'] as Map);
        if (review['status'] == 'pass') mappingPassCount++;
        if (review['status'] != 'pending' ||
            review['humanReviewed'] != false ||
            review['conceptAlignmentConfirmed'] != false ||
            review['reviewedAt'] != null ||
            review['nextReviewDueAt'] != null) {
          issues.add('ML9C_MAPPING_REVIEW_PREMATURE: $factId.');
        }
      } else if (curriculum['scope'] == 'general') {
        generalCount++;
        if (mappingRaw != null) {
          issues.add('ML9C_GENERAL_MAPPING_FORBIDDEN: $factId.');
        }
      } else {
        issues.add('ML9C_SCOPE_INVALID: $factId.');
      }

      if (rights != null) {
        final curriculumGate =
            const MicroFactCurriculumGateValidator().validateMaps(
          microFact: fact,
          authorityRegistry: authority,
          claimPolicy: claimPolicy,
          rightsPolicy: rightsPolicy,
          rightsEvidence: rights,
          curriculumPolicy: curriculumPolicy,
          curriculumRegistry: curriculumRegistry,
          curriculumEvidence: mapping,
        );
        for (final issue in curriculumGate.issues) {
          issues.add('ML9C_CURRICULUM_BINDING $factId: $issue');
        }
      }

      final pedagogy =
          _requiredMap(entry['pedagogyEvidence'], factId, 'pedagogy', issues);
      if (pedagogy != null) {
        final evidenceId = pedagogy['evidenceId'];
        if (evidenceId is! String || !seenPedagogy.add(evidenceId)) {
          issues.add('ML9C_PEDAGOGY_ID: invalid or duplicate pedagogy evidence for $factId.');
        }

        final result =
            const StartupPedagogyEvidenceValidator().validateMap(pedagogy);
        for (final issue in result.issues) {
          issues.add('ML9C_PEDAGOGY_SCHEMA $factId: $issue');
        }

        _validatePedagogyBinding(
          fact: fact,
          evidence: pedagogy,
          policy: pedagogyPolicy,
          issues: issues,
        );

        final pedagogyReview =
            Map<String, dynamic>.from(pedagogy['pedagogyReview'] as Map);
        final accessibilityReview =
            Map<String, dynamic>.from(pedagogy['accessibilityReview'] as Map);
        if (pedagogyReview['status'] == 'pass') pedagogyPassCount++;
        if (accessibilityReview['status'] == 'pass') accessibilityPassCount++;

        _requirePendingPedagogyReview(
          pedagogyReview,
          factId,
          issues,
        );
        _requirePendingAccessibilityReview(
          accessibilityReview,
          factId,
          issues,
        );
      }
    }
  }

  if (seenFacts.length != 120 ||
      seenRights.length != 120 ||
      seenPedagogy.length != 120) {
    issues.add(
      'ML9C_COVERAGE: expected 120 facts/rights/pedagogy records; '
      'got facts=${seenFacts.length}, rights=${seenRights.length}, '
      'pedagogy=${seenPedagogy.length}.',
    );
  }
  if (mappedCount != 114 ||
      generalCount != 6 ||
      seenMappings.length != 114) {
    issues.add(
      'ML9C_CURRICULUM_COVERAGE: expected 114 mapped and 6 general; '
      'got mapped=$mappedCount general=$generalCount '
      'evidence=${seenMappings.length}.',
    );
  }

  if (rightsPassCount != 0 ||
      mappingPassCount != 0 ||
      pedagogyPassCount != 0 ||
      accessibilityPassCount != 0) {
    issues.add(
      'ML9C_HUMAN_APPROVAL_PREMATURE: no ML-9C evidence may be auto-passed.',
    );
  }

  if (issues.isNotEmpty) {
    stderr.writeln('ML-9C GATE EVIDENCE INVALID with ${issues.length} issue(s):');
    for (final issue in issues) {
      stderr.writeln(' - $issue');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln('ML-9C GATE EVIDENCE VALID');
  stdout.writeln('Facts covered: 120');
  stdout.writeln('Rights evidence: 120');
  stdout.writeln('Curriculum evidence: 114 mapped / 6 general exempt');
  stdout.writeln('Pedagogy/accessibility evidence: 120');
  stdout.writeln('Human approvals asserted: 0');
  stdout.writeln('Facts promoted to validated/published/startup: 0');
}

void _validatePedagogyBinding({
  required Map<String, dynamic> fact,
  required Map<String, dynamic> evidence,
  required Map<String, dynamic> policy,
  required List<String> issues,
}) {
  final id = fact['microFactId'] as String;
  final display = Map<String, dynamic>.from(fact['display'] as Map);
  final fingerprint =
      Map<String, dynamic>.from(evidence['contentFingerprint'] as Map);
  final metrics = Map<String, dynamic>.from(evidence['metrics'] as Map);
  final textRules = Map<String, dynamic>.from(policy['textRules'] as Map);
  final wpm = textRules['nominalReadingWordsPerMinute'] as int;
  final short = display['shortVariant'] as String?;

  if (evidence['microFactId'] != id ||
      evidence['contentVersion'] != fact['contentVersion']) {
    issues.add('ML9C_PEDAGOGY_FACT_BINDING: $id.');
  }

  if (fingerprint['displayTextSha256'] !=
          StartupTextMetrics.sha256Text(display['displayText'] as String) ||
      fingerprint['shortVariantSha256'] !=
          (short == null ? null : StartupTextMetrics.sha256Text(short)) ||
      fingerprint['estimatedReadSeconds'] != display['estimatedReadSeconds']) {
    issues.add('ML9C_PEDAGOGY_FINGERPRINT_DRIFT: $id.');
  }

  final full = display['displayText'] as String;
  if (metrics['displayWordCount'] != StartupTextMetrics.wordCount(full) ||
      metrics['displaySentenceCount'] != StartupTextMetrics.sentenceCount(full) ||
      metrics['computedDisplayReadSeconds'] !=
          StartupTextMetrics.readSeconds(full, wpm) ||
      metrics['shortWordCount'] !=
          (short == null ? null : StartupTextMetrics.wordCount(short)) ||
      metrics['shortSentenceCount'] !=
          (short == null ? null : StartupTextMetrics.sentenceCount(short)) ||
      metrics['computedShortReadSeconds'] !=
          (short == null ? null : StartupTextMetrics.readSeconds(short, wpm))) {
    issues.add('ML9C_PEDAGOGY_METRIC_DRIFT: $id.');
  }
}

void _requirePendingHumanReview(
  Map<String, dynamic> review,
  String factId,
  String kind,
  List<String> issues,
) {
  if (review['status'] != 'pending' ||
      review['humanReviewed'] != false ||
      review['reviewedAt'] != null ||
      review['nextReviewDueAt'] != null) {
    issues.add('ML9C_${kind.toUpperCase()}_REVIEW_PREMATURE: $factId.');
  }
}

void _requirePendingPedagogyReview(
  Map<String, dynamic> review,
  String factId,
  List<String> issues,
) {
  if (review['status'] != 'pending' ||
      review['humanReviewed'] != false ||
      review['reviewedAt'] != null ||
      review['nextReviewDueAt'] != null) {
    issues.add('ML9C_PEDAGOGY_REVIEW_PREMATURE: $factId.');
  }
  for (final field in const [
    'singleConceptConfirmed',
    'standaloneMeaningConfirmed',
    'cognitiveLoadAcceptable',
    'jargonLoadAcceptable',
    'shortVariantMeaningPreserved',
    'precisionPreserved',
    'assessmentLeakageReviewed',
  ]) {
    if (review[field] != false) {
      issues.add('ML9C_PEDAGOGY_ATTESTATION_PREMATURE: $factId $field.');
    }
  }
}

void _requirePendingAccessibilityReview(
  Map<String, dynamic> review,
  String factId,
  List<String> issues,
) {
  if (review['status'] != 'pending' ||
      review['humanReviewed'] != false ||
      review['reviewedAt'] != null ||
      review['nextReviewDueAt'] != null) {
    issues.add('ML9C_ACCESSIBILITY_REVIEW_PREMATURE: $factId.');
  }
  for (final field in const [
    'screenReaderStandaloneConfirmed',
    'visualIndependenceConfirmed',
    'reducedMotionEquivalentConfirmed',
    'plainLanguageAccessibleConfirmed',
    'noForcedInteractionConfirmed',
  ]) {
    if (review[field] != false) {
      issues.add('ML9C_ACCESSIBILITY_ATTESTATION_PREMATURE: $factId $field.');
    }
  }
}

Map<String, dynamic>? _requiredMap(
  dynamic value,
  String factId,
  String kind,
  List<String> issues,
) {
  if (value is! Map) {
    issues.add('ML9C_${kind.toUpperCase()}_EVIDENCE_MISSING: $factId.');
    return null;
  }
  return Map<String, dynamic>.from(value);
}

Future<Map<String, dynamic>> _readObject(String path) async {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('ML-9C required file not found: $path');
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

void _requireEqual(
  dynamic actual,
  dynamic expected,
  List<String> issues,
  String path,
) {
  if (actual != expected) {
    issues.add('ML9C_VALUE_MISMATCH: $path expected $expected got $actual.');
  }
}
