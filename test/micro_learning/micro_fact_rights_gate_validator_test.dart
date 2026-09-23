import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/services/micro_learning/micro_fact_rights_gate_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const factPath = 'test/fixtures/micro_learning/valid_micro_fact_v1.json';
  const evidencePath =
      'test/fixtures/micro_learning/valid_rights_evidence_v1.json';
  const registryPath = 'content/micro_learning/authority_registry_v1.json';
  const claimPolicyPath =
      'content/micro_learning/claim_semantics_policy_v1.json';
  const rightsPolicyPath =
      'content/micro_learning/rights_provenance_policy_v1.json';

  const validator = MicroFactRightsGateValidator();

  Map<String, dynamic> loadJson(String path) {
    return jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  }

  Map<String, dynamic> cloneMap(Map<String, dynamic> value) {
    return jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
  }

  Map<String, dynamic> loadFact() => loadJson(factPath);
  Map<String, dynamic> loadEvidence() => loadJson(evidencePath);
  Map<String, dynamic> loadRegistry() => loadJson(registryPath);
  Map<String, dynamic> loadClaimPolicy() => loadJson(claimPolicyPath);
  Map<String, dynamic> loadRightsPolicy() => loadJson(rightsPolicyPath);

  Map<String, dynamic> cloneFact() => cloneMap(loadFact());
  Map<String, dynamic> cloneEvidence() => cloneMap(loadEvidence());

  String hashOf(String character) => List.filled(64, character).join();

  MicroFactRightsGateResult validate(
    Map<String, dynamic> fact, {
    Map<String, dynamic>? evidence,
  }) {
    return validator.validateMaps(
      microFact: fact,
      authorityRegistry: loadRegistry(),
      claimPolicy: loadClaimPolicy(),
      rightsPolicy: loadRightsPolicy(),
      rightsEvidence: evidence ?? loadEvidence(),
    );
  }

  test('valid ML-5 fixture pair passes copyright/provenance gates', () {
    final result = validate(loadFact());

    expect(result.issues, isEmpty, reason: result.issues.join('\n'));
  });

  test('validated or published fact cannot omit rights evidence', () {
    final result = validator.validateMaps(
      microFact: loadFact(),
      authorityRegistry: loadRegistry(),
      claimPolicy: loadClaimPolicy(),
      rightsPolicy: loadRightsPolicy(),
      rightsEvidence: null,
    );

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_RIGHTS_EVIDENCE_REQUIRED'),
    );
  });

  test('evidence from another MicroFact is rejected', () {
    final evidence = cloneEvidence();
    evidence['microFactId'] = 'mf_other_fact_0001';

    final result = validate(loadFact(), evidence: evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_EVIDENCE_FACT_ID_MISMATCH'),
    );
  });

  test('evidence from another content version is rejected', () {
    final evidence = cloneEvidence();
    evidence['contentVersion'] = 2;

    final result = validate(loadFact(), evidence: evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_EVIDENCE_CONTENT_VERSION_MISMATCH'),
    );
  });

  test('rights treatment cannot change after evidence review', () {
    final fact = cloneFact();
    final provenance = Map<String, dynamic>.from(fact['provenance'] as Map);
    provenance['rightsTreatment'] = 'brief_summary';
    fact['provenance'] = provenance;

    final result = validate(fact);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_RIGHTS_TREATMENT_MISMATCH'),
    );
  });

  test('source URL cannot change after rights review', () {
    final evidence = cloneEvidence();
    final fingerprint = Map<String, dynamic>.from(
      evidence['sourceFingerprint'] as Map,
    );
    fingerprint['officialUrl'] =
        'https://www.osha.gov/laws-regs/regulations/standardnumber/1910/1910.146';
    evidence['sourceFingerprint'] = fingerprint;

    final result = validate(loadFact(), evidence: evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_SOURCE_FINGERPRINT_MISMATCH'),
    );
  });

  test('published fact requires passing rights evidence', () {
    final evidence = cloneEvidence();
    final review = Map<String, dynamic>.from(evidence['review'] as Map);
    review['status'] = 'pending';
    evidence['review'] = review;

    final result = validate(loadFact(), evidence: evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      containsAll({
        'ML5_RIGHTS_EVIDENCE_NOT_PASS',
        'ML5_STARTUP_RIGHTS_EVIDENCE_NOT_PASS',
      }),
    );
  });

  test('validated fact requires MicroFact copyright review pass', () {
    final fact = cloneFact();
    fact['status'] = 'validated';

    final runtime = Map<String, dynamic>.from(fact['runtime'] as Map);
    runtime['startupEligible'] = false;
    fact['runtime'] = runtime;

    final review = Map<String, dynamic>.from(fact['review'] as Map);
    review['copyrightStatus'] = 'pending';
    fact['review'] = review;

    final result = validate(fact);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_COPYRIGHT_REVIEW_NOT_PASS'),
    );
  });

  test('rights review cannot predate source verification', () {
    final evidence = cloneEvidence();
    final review = Map<String, dynamic>.from(evidence['review'] as Map);
    review
      ..['reviewedAt'] = '2026-09-22'
      ..['nextReviewDueAt'] = '2027-09-22';
    evidence['review'] = review;

    final result = validate(loadFact(), evidence: evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_RIGHTS_REVIEW_BEFORE_SOURCE_VERIFICATION'),
    );
  });

  test('final fact review cannot predate its rights review', () {
    final evidence = cloneEvidence();
    final review = Map<String, dynamic>.from(evidence['review'] as Map);
    review
      ..['reviewedAt'] = '2026-09-24'
      ..['nextReviewDueAt'] = '2027-09-24';
    evidence['review'] = review;

    final result = validate(loadFact(), evidence: evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_RIGHTS_REVIEW_AFTER_FACT_REVIEW'),
    );
  });

  test('rights evidence cannot already be stale at final fact review', () {
    final fact = cloneFact();
    final factReview = Map<String, dynamic>.from(fact['review'] as Map);
    factReview
      ..['reviewedAt'] = '2026-10-02'
      ..['nextReviewDueAt'] = '2027-10-02';
    fact['review'] = factReview;

    final evidence = cloneEvidence();
    final rightsReview = Map<String, dynamic>.from(evidence['review'] as Map);
    rightsReview['nextReviewDueAt'] = '2026-10-01';
    evidence['review'] = rightsReview;

    final result = validate(fact, evidence: evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_RIGHTS_EVIDENCE_ALREADY_STALE'),
    );
  });

  test('rights evidence older than 365 days is rejected', () {
    final fact = cloneFact();
    final factReview = Map<String, dynamic>.from(fact['review'] as Map);
    factReview
      ..['reviewedAt'] = '2027-09-24'
      ..['nextReviewDueAt'] = '2028-09-24';
    fact['review'] = factReview;

    final evidence = cloneEvidence();
    final rightsReview = Map<String, dynamic>.from(evidence['review'] as Map);
    rightsReview['nextReviewDueAt'] = '2028-09-23';
    evidence['review'] = rightsReview;

    final result = validate(fact, evidence: evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_RIGHTS_EVIDENCE_TOO_OLD'),
    );
  });

  test('minimal quote must be visibly marked in learner text', () {
    final fact = cloneFact();
    final provenance = Map<String, dynamic>.from(fact['provenance'] as Map);
    provenance['rightsTreatment'] = 'minimal_quote';
    fact['provenance'] = provenance;

    final evidence = cloneEvidence();
    evidence['rightsTreatment'] = 'minimal_quote';
    final transformation = Map<String, dynamic>.from(
      evidence['transformation'] as Map,
    );
    transformation
      ..['independentWordingConfirmed'] = false
      ..['directQuoteUsed'] = true
      ..['quoteWordCount'] = 4
      ..['quoteSegmentCount'] = 1
      ..['quoteTextSha256'] = hashOf('a')
      ..['quoteNecessity'] = 'Exact regulatory term is intentionally quoted.'
      ..['longestVerbatimRunWords'] = 4;
    evidence['transformation'] = transformation;

    final result = validate(fact, evidence: evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_QUOTE_NOT_VISIBLY_MARKED'),
    );
  });

  test('properly marked minimal quote can pass', () {
    final fact = cloneFact();
    final provenance = Map<String, dynamic>.from(fact['provenance'] as Map);
    provenance['rightsTreatment'] = 'minimal_quote';
    fact['provenance'] = provenance;

    final display = Map<String, dynamic>.from(fact['display'] as Map);
    display
      ..['displayText'] =
          'OSHA uses the phrase "control of hazardous energy" for this standard.'
      ..['shortVariant'] = null;
    fact['display'] = display;

    final evidence = cloneEvidence();
    evidence['rightsTreatment'] = 'minimal_quote';
    final transformation = Map<String, dynamic>.from(
      evidence['transformation'] as Map,
    );
    transformation
      ..['independentWordingConfirmed'] = false
      ..['directQuoteUsed'] = true
      ..['quoteWordCount'] = 4
      ..['quoteSegmentCount'] = 1
      ..['quoteTextSha256'] = hashOf('b')
      ..['quoteNecessity'] = 'Exact regulatory term is intentionally quoted.'
      ..['longestVerbatimRunWords'] = 4;
    evidence['transformation'] = transformation;

    final result = validate(fact, evidence: evidence);

    expect(result.issues, isEmpty, reason: result.issues.join('\n'));
  });

  test('paraphrase treatment cannot hide quotation markers', () {
    final fact = cloneFact();
    final display = Map<String, dynamic>.from(fact['display'] as Map);
    display['displayText'] =
        'OSHA describes "control of hazardous energy" during servicing.';
    fact['display'] = display;

    final result = validate(fact);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_UNDECLARED_QUOTATION_MARKERS'),
    );
  });

  test('licensed excerpt cannot be used after license expiry', () {
    final fact = cloneFact();
    final provenance = Map<String, dynamic>.from(fact['provenance'] as Map);
    provenance['rightsTreatment'] = 'licensed_excerpt';
    fact['provenance'] = provenance;

    final display = Map<String, dynamic>.from(fact['display'] as Map);
    display
      ..['displayText'] = 'Licensed wording: "control of hazardous energy".'
      ..['shortVariant'] = null;
    fact['display'] = display;

    final evidence = cloneEvidence();
    evidence['rightsTreatment'] = 'licensed_excerpt';

    final transformation = Map<String, dynamic>.from(
      evidence['transformation'] as Map,
    );
    transformation
      ..['independentWordingConfirmed'] = false
      ..['directQuoteUsed'] = true
      ..['quoteWordCount'] = 4
      ..['quoteSegmentCount'] = 1
      ..['quoteTextSha256'] = hashOf('c')
      ..['quoteNecessity'] = 'Licensed wording.'
      ..['longestVerbatimRunWords'] = 4;
    evidence['transformation'] = transformation;

    final license = Map<String, dynamic>.from(evidence['license'] as Map);
    license
      ..['required'] = true
      ..['licenseId'] = 'LIC-EXPIRED-001'
      ..['licensor'] = 'Test Licensor'
      ..['scope'] = 'Startup display and digital redistribution.'
      ..['effectiveDate'] = '2026-01-01'
      ..['expiresAt'] = '2026-09-22'
      ..['startupDisplayPermitted'] = true
      ..['digitalRedistributionPermitted'] = true
      ..['protectedStructureReusePermitted'] = false;
    evidence['license'] = license;

    final result = validate(fact, evidence: evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_LICENSE_EXPIRED_AT_REVIEW'),
    );
  });

  test('rights-sensitive standards source requires edition provenance', () {
    final registry = loadRegistry();
    final iso = (registry['authorities'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((authority) => authority['id'] == 'SRC-04');

    final fact = cloneFact();
    final provenance = Map<String, dynamic>.from(fact['provenance'] as Map);
    provenance
      ..['sourceRegistryId'] = 'SRC-04'
      ..['sourceClass'] = 'international_standard'
      ..['sourceTitle'] = 'ISO occupational health and safety standard'
      ..['officialUrl'] = (iso['officialEntryPoints'] as List).first as String
      ..['sourceLocator'] = 'ISO 45001 management-system requirements'
      ..['editionOrRevision'] = null
      ..['sourceSection'] = 'Management system requirements'
      ..['sourcePage'] = null
      ..['sourceVerifiedAt'] = iso['verifiedAt'].toString()
      ..['rightsTreatment'] = 'original_paraphrase';
    fact['provenance'] = provenance;

    final claim = Map<String, dynamic>.from(fact['claim'] as Map);
    claim
      ..['legalStatus'] = 'international_standard'
      ..['jurisdiction'] = null
      ..['numericalClaim'] = false
      ..['safetyCritical'] = false
      ..['simplificationRisk'] = 'low';
    fact['claim'] = claim;

    final display = Map<String, dynamic>.from(fact['display'] as Map);
    display
      ..['displayText'] =
          'ISO 45001 provides requirements for occupational health and safety management systems.'
      ..['shortVariant'] = null;
    fact['display'] = display;

    final factReview = Map<String, dynamic>.from(fact['review'] as Map);
    factReview
      ..['reviewedAt'] = iso['verifiedAt'].toString()
      ..['nextReviewDueAt'] = '2027-09-23';
    fact['review'] = factReview;

    final evidence = cloneEvidence();
    final fingerprint = Map<String, dynamic>.from(
      evidence['sourceFingerprint'] as Map,
    );
    fingerprint
      ..['sourceRegistryId'] = 'SRC-04'
      ..['officialUrl'] = (iso['officialEntryPoints'] as List).first as String
      ..['sourceLocator'] = 'ISO 45001 management-system requirements'
      ..['editionOrRevision'] = null;
    evidence['sourceFingerprint'] = fingerprint;

    final rightsReview = Map<String, dynamic>.from(evidence['review'] as Map);
    rightsReview
      ..['reviewedAt'] = iso['verifiedAt'].toString()
      ..['nextReviewDueAt'] = '2027-09-23';
    evidence['review'] = rightsReview;

    final result = validator.validateMaps(
      microFact: fact,
      authorityRegistry: registry,
      claimPolicy: loadClaimPolicy(),
      rightsPolicy: loadRightsPolicy(),
      rightsEvidence: evidence,
    );

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_RIGHTS_SENSITIVE_EDITION_REQUIRED'),
    );
  });

  test('formal ML-5 evidence schema remains fail closed', () {
    final schema = loadJson(
      'content/micro_learning/rights_evidence_schema_v1.json',
    );
    final extension = Map<String, dynamic>.from(schema['x-csp11'] as Map);

    expect(schema['additionalProperties'], isFalse);
    expect(extension['phase'], 'ML-5');
    expect(extension['rightsPolicyVersion'], '1.0.0');
    expect(extension['failClosed'], isTrue);
  });
}
