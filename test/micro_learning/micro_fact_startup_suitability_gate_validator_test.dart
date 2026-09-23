import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/services/micro_learning/micro_fact_startup_suitability_gate_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const factPath = 'test/fixtures/micro_learning/valid_micro_fact_v1.json';
  const authorityPath = 'content/micro_learning/authority_registry_v1.json';
  const claimPolicyPath =
      'content/micro_learning/claim_semantics_policy_v1.json';
  const rightsPolicyPath =
      'content/micro_learning/rights_provenance_policy_v1.json';
  const rightsEvidencePath =
      'test/fixtures/micro_learning/valid_rights_evidence_v1.json';
  const curriculumPolicyPath =
      'content/micro_learning/canonical_curriculum_policy_v1.json';
  const curriculumRegistryPath =
      'content/micro_learning/canonical_curriculum_registry_v1.json';
  const pedagogyPolicyPath =
      'content/micro_learning/startup_pedagogy_policy_v1.json';
  const pedagogyEvidencePath =
      'test/fixtures/micro_learning/valid_startup_pedagogy_evidence_v1.json';

  const validator = MicroFactStartupSuitabilityGateValidator();

  Map<String, dynamic> loadJson(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  Map<String, dynamic> cloneMap(Map<String, dynamic> value) =>
      jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

  Map<String, dynamic> loadFact() => loadJson(factPath);
  Map<String, dynamic> loadPedagogyEvidence() => loadJson(pedagogyEvidencePath);

  MicroFactStartupSuitabilityResult validate(
    Map<String, dynamic> fact, {
    Map<String, dynamic>? pedagogyEvidence,
    bool provideEvidence = true,
  }) {
    return validator.validateMaps(
      microFact: fact,
      authorityRegistry: loadJson(authorityPath),
      claimPolicy: loadJson(claimPolicyPath),
      rightsPolicy: loadJson(rightsPolicyPath),
      rightsEvidence: loadJson(rightsEvidencePath),
      curriculumPolicy: loadJson(curriculumPolicyPath),
      curriculumRegistry: loadJson(curriculumRegistryPath),
      curriculumEvidence: null,
      pedagogyPolicy: loadJson(pedagogyPolicyPath),
      pedagogyEvidence: provideEvidence
          ? (pedagogyEvidence ?? loadPedagogyEvidence())
          : null,
    );
  }

  test('valid startup-eligible MicroFact passes ML-7', () {
    final result = validate(loadFact());
    expect(result.issues, isEmpty, reason: result.issues.join('\n'));
  });

  test('non-startup fact does not require ML-7 evidence', () {
    final fact = loadFact();
    final runtime = Map<String, dynamic>.from(fact['runtime'] as Map);
    runtime['startupEligible'] = false;
    fact['runtime'] = runtime;

    final result = validate(fact, provideEvidence: false);

    expect(result.issues, isEmpty, reason: result.issues.join('\n'));
  });

  test('published startup fact cannot omit pedagogy evidence', () {
    final result = validate(loadFact(), provideEvidence: false);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_PEDAGOGY_EVIDENCE_REQUIRED'),
    );
  });

  test('startup fact requires a short variant', () {
    final fact = loadFact();
    final display = Map<String, dynamic>.from(fact['display'] as Map);
    display['shortVariant'] = null;
    fact['display'] = display;

    final result = validate(fact);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_SHORT_VARIANT_REQUIRED'),
    );
  });

  test('startup short variant cannot exceed 18 words', () {
    final fact = loadFact();
    final display = Map<String, dynamic>.from(fact['display'] as Map);
    display['shortVariant'] =
        'Lockout/tagout addresses hazardous energy during servicing and maintenance of machines and equipment by controlling unexpected energization and stored energy.';
    fact['display'] = display;

    final result = validate(fact);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_SHORT_VARIANT_LIMIT'),
    );
  });

  test('startup short variant must be materially compressed', () {
    final fact = loadFact();
    final display = Map<String, dynamic>.from(fact['display'] as Map);
    display['shortVariant'] =
        'Lockout/tagout standard addresses control of hazardous energy during servicing and maintenance of machines and equipment.';
    fact['display'] = display;

    final result = validate(fact);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_SHORT_COMPRESSION_INSUFFICIENT'),
    );
  });

  test('full startup fact cannot exceed display word limit', () {
    final fact = loadFact();
    final display = Map<String, dynamic>.from(fact['display'] as Map);
    display['displayText'] =
        'OSHA lockout/tagout requirements address hazardous energy during servicing and maintenance of machines and equipment, including energy control procedures and protective steps intended to prevent unexpected energization, startup, or release of stored energy while work is performed.';
    fact['display'] = display;

    final result = validate(fact);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_DISPLAY_TEXT_LIMIT'),
    );
  });

  test('estimated read seconds must match deterministic metric', () {
    final fact = loadFact();
    final display = Map<String, dynamic>.from(fact['display'] as Map);
    display['estimatedReadSeconds'] = 1;
    fact['display'] = display;

    final result = validate(fact);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_ESTIMATED_READ_SECONDS_MISMATCH'),
    );
  });

  test('startup copy cannot contain embedded line breaks', () {
    final fact = loadFact();
    final display = Map<String, dynamic>.from(fact['display'] as Map);
    display['shortVariant'] =
        'Lockout/tagout addresses hazardous energy during servicing\nand maintenance.';
    fact['display'] = display;

    final result = validate(fact);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_PLAIN_TEXT_VIOLATION'),
    );
  });

  test('unknown all-caps jargon is blocked', () {
    final fact = loadFact();
    final display = Map<String, dynamic>.from(fact['display'] as Map);
    display['shortVariant'] =
        'Lockout/tagout addresses hazardous energy during servicing and maintenance under XYZ controls.';
    fact['display'] = display;

    final result = validate(fact);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_UNKNOWN_UPPERCASE_JARGON'),
    );
  });

  test('startup copy cannot depend on visual position', () {
    final fact = loadFact();
    final display = Map<String, dynamic>.from(fact['display'] as Map);
    display['shortVariant'] =
        'Lockout/tagout addresses hazardous energy during servicing, as shown above.';
    fact['display'] = display;

    final result = validate(fact);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_VISUAL_DEPENDENCY_LANGUAGE'),
    );
  });

  test('question form is reserved for think-about-it category', () {
    final fact = loadFact();
    final display = Map<String, dynamic>.from(fact['display'] as Map);
    display['shortVariant'] =
        'Does lockout/tagout address hazardous energy during servicing?';
    fact['display'] = display;

    final result = validate(fact);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_QUESTION_MARK_CATEGORY'),
    );
  });

  test('answer-key language is blocked from startup facts', () {
    final fact = loadFact();
    final display = Map<String, dynamic>.from(fact['display'] as Map);
    display['shortVariant'] =
        'For hazardous energy questions, the correct answer is LOTO.';
    fact['display'] = display;

    final result = validate(fact);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_ANSWER_KEY_LANGUAGE'),
    );
  });

  test('high assessment sensitivity is blocked from startup', () {
    final fact = loadFact();
    final assessment = Map<String, dynamic>.from(fact['assessment'] as Map);
    assessment['sensitivity'] = 'high';
    fact['assessment'] = assessment;

    final result = validate(fact);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_ASSESSMENT_SENSITIVITY_BLOCKED'),
    );
  });

  test('pedagogy evidence cannot be replayed for another fact', () {
    final evidence = loadPedagogyEvidence();
    evidence['microFactId'] = 'mf_other_fact_0001';

    final result = validate(loadFact(), pedagogyEvidence: evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_EVIDENCE_FACT_ID_MISMATCH'),
    );
  });

  test('display copy edit invalidates previous pedagogy fingerprint', () {
    final evidence = loadPedagogyEvidence();
    final fingerprint = Map<String, dynamic>.from(
      evidence['contentFingerprint'] as Map,
    );
    fingerprint['displayTextSha256'] = List.filled(64, 'a').join();
    evidence['contentFingerprint'] = fingerprint;

    final result = validate(loadFact(), pedagogyEvidence: evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_DISPLAY_TEXT_FINGERPRINT_DRIFT'),
    );
  });

  test('stored text metrics cannot drift from actual MicroFact', () {
    final evidence = loadPedagogyEvidence();
    final metrics = Map<String, dynamic>.from(evidence['metrics'] as Map);
    metrics['shortWordCount'] = 12;
    evidence['metrics'] = metrics;

    final result = validate(loadFact(), pedagogyEvidence: evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_METRIC_DRIFT'),
    );
  });

  test('validated startup fact requires MicroFact pedagogy and UI pass', () {
    final fact = loadFact();
    fact['status'] = 'validated';
    final review = Map<String, dynamic>.from(fact['review'] as Map);
    review
      ..['pedagogyStatus'] = 'pending'
      ..['uiStatus'] = 'pending';
    fact['review'] = review;

    final result = validate(fact);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_FACT_REVIEW_NOT_PASS'),
    );
  });

  test('startup evidence must pass both human review tracks', () {
    final evidence = loadPedagogyEvidence();
    final accessibility = Map<String, dynamic>.from(
      evidence['accessibilityReview'] as Map,
    );
    accessibility['status'] = 'pending';
    evidence['accessibilityReview'] = accessibility;

    final result = validate(loadFact(), pedagogyEvidence: evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_EVIDENCE_NOT_PASS'),
    );
  });

  test('startup review cannot occur after final fact review', () {
    final evidence = loadPedagogyEvidence();
    final pedagogy = Map<String, dynamic>.from(
      evidence['pedagogyReview'] as Map,
    );
    pedagogy
      ..['reviewedAt'] = '2026-09-24'
      ..['nextReviewDueAt'] = '2027-09-24';
    evidence['pedagogyReview'] = pedagogy;

    final result = validate(loadFact(), pedagogyEvidence: evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_REVIEW_AFTER_FACT_REVIEW'),
    );
  });

  test('startup evidence older than frozen maximum age is rejected', () {
    final evidence = loadPedagogyEvidence();
    final pedagogy = Map<String, dynamic>.from(
      evidence['pedagogyReview'] as Map,
    );
    pedagogy
      ..['reviewedAt'] = '2025-09-22'
      ..['nextReviewDueAt'] = '2027-09-22';
    evidence['pedagogyReview'] = pedagogy;

    final result = validate(loadFact(), pedagogyEvidence: evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_EVIDENCE_TOO_OLD'),
    );
  });

  test('safety-critical fact requires explicit precision preservation', () {
    final evidence = loadPedagogyEvidence();
    final pedagogy = Map<String, dynamic>.from(
      evidence['pedagogyReview'] as Map,
    );
    pedagogy
      ..['status'] = 'pending'
      ..['precisionPreserved'] = false;
    evidence['pedagogyReview'] = pedagogy;

    final result = validate(loadFact(), pedagogyEvidence: evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_PRECISION_REVIEW_REQUIRED'),
    );
  });

  test('formal ML-7 evidence schema remains fail closed', () {
    final schema = loadJson(
      'content/micro_learning/startup_pedagogy_evidence_schema_v1.json',
    );
    final extension = Map<String, dynamic>.from(schema['x-csp11'] as Map);

    expect(schema['additionalProperties'], isFalse);
    expect(extension['phase'], 'ML-7');
    expect(extension['pedagogyPolicyVersion'], '1.0.0');
    expect(extension['failClosed'], isTrue);
  });
}
