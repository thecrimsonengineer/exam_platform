import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/services/micro_learning/rights_evidence_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const evidencePath =
      'test/fixtures/micro_learning/valid_rights_evidence_v1.json';
  const validator = RightsEvidenceValidator();

  Map<String, dynamic> loadEvidence() {
    return jsonDecode(File(evidencePath).readAsStringSync())
        as Map<String, dynamic>;
  }

  Map<String, dynamic> cloneEvidence() {
    return jsonDecode(jsonEncode(loadEvidence())) as Map<String, dynamic>;
  }

  test('valid ML-5 rights evidence fixture passes', () {
    final result = validator.validateMap(loadEvidence());

    expect(result.issues, isEmpty, reason: result.issues.join('\n'));
  });

  test('unknown evidence field fails closed', () {
    final evidence = cloneEvidence();
    evidence['hiddenOverride'] = true;

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_EVIDENCE_UNKNOWN_FIELD'),
    );
  });

  test('unknown nested transformation field fails closed', () {
    final evidence = cloneEvidence();
    final transformation = Map<String, dynamic>.from(
      evidence['transformation'] as Map,
    );
    transformation['ignoreSimilarity'] = true;
    evidence['transformation'] = transformation;

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_EVIDENCE_UNKNOWN_FIELD'),
    );
  });

  test('paraphrase cannot declare direct quotation', () {
    final evidence = cloneEvidence();
    final transformation = Map<String, dynamic>.from(
      evidence['transformation'] as Map,
    );
    transformation
      ..['directQuoteUsed'] = true
      ..['quoteWordCount'] = 3
      ..['quoteSegmentCount'] = 1
      ..['quoteTextSha256'] = 'a' * 64
      ..['quoteNecessity'] = 'Test quote';
    evidence['transformation'] = transformation;

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_EVIDENCE_PARAPHRASE_CONTAINS_QUOTE'),
    );
  });

  test('paraphrase cannot retain more than five verbatim words', () {
    final evidence = cloneEvidence();
    final transformation = Map<String, dynamic>.from(
      evidence['transformation'] as Map,
    );
    transformation['longestVerbatimRunWords'] = 6;
    evidence['transformation'] = transformation;

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_EVIDENCE_VERBATIM_RUN_TOO_LONG'),
    );
  });

  test('minimal quote cannot exceed twelve words', () {
    final evidence = cloneEvidence();
    evidence['rightsTreatment'] = 'minimal_quote';

    final transformation = Map<String, dynamic>.from(
      evidence['transformation'] as Map,
    );
    transformation
      ..['independentWordingConfirmed'] = false
      ..['directQuoteUsed'] = true
      ..['quoteWordCount'] = 13
      ..['quoteSegmentCount'] = 1
      ..['quoteTextSha256'] = 'b' * 64
      ..['quoteNecessity'] = 'Exact wording is necessary for this test.'
      ..['longestVerbatimRunWords'] = 13;
    evidence['transformation'] = transformation;

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_EVIDENCE_QUOTE_WORD_LIMIT'),
    );
  });

  test('minimal quote requires exactly one quote segment', () {
    final evidence = cloneEvidence();
    evidence['rightsTreatment'] = 'minimal_quote';

    final transformation = Map<String, dynamic>.from(
      evidence['transformation'] as Map,
    );
    transformation
      ..['independentWordingConfirmed'] = false
      ..['directQuoteUsed'] = true
      ..['quoteWordCount'] = 6
      ..['quoteSegmentCount'] = 2
      ..['quoteTextSha256'] = 'c' * 64
      ..['quoteNecessity'] = 'Exact wording is necessary for this test.'
      ..['longestVerbatimRunWords'] = 6;
    evidence['transformation'] = transformation;

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_EVIDENCE_QUOTE_SEGMENT_LIMIT'),
    );
  });

  test('minimal quote requires quote fingerprint and necessity', () {
    final evidence = cloneEvidence();
    evidence['rightsTreatment'] = 'minimal_quote';

    final transformation = Map<String, dynamic>.from(
      evidence['transformation'] as Map,
    );
    transformation
      ..['independentWordingConfirmed'] = false
      ..['directQuoteUsed'] = true
      ..['quoteWordCount'] = 6
      ..['quoteSegmentCount'] = 1
      ..['quoteTextSha256'] = null
      ..['quoteNecessity'] = null
      ..['longestVerbatimRunWords'] = 6;
    evidence['transformation'] = transformation;

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      containsAll({
        'ML5_EVIDENCE_QUOTE_HASH_REQUIRED',
        'ML5_EVIDENCE_QUOTE_NECESSITY_REQUIRED',
      }),
    );
  });

  test('licensed excerpt requires startup and redistribution permission', () {
    final evidence = cloneEvidence();
    evidence['rightsTreatment'] = 'licensed_excerpt';

    final transformation = Map<String, dynamic>.from(
      evidence['transformation'] as Map,
    );
    transformation
      ..['independentWordingConfirmed'] = false
      ..['directQuoteUsed'] = true
      ..['quoteWordCount'] = 20
      ..['quoteSegmentCount'] = 1
      ..['quoteTextSha256'] = 'd' * 64
      ..['quoteNecessity'] = 'Licensed source excerpt.'
      ..['longestVerbatimRunWords'] = 20;
    evidence['transformation'] = transformation;

    final license = Map<String, dynamic>.from(evidence['license'] as Map);
    license
      ..['required'] = true
      ..['licenseId'] = 'LIC-TEST-001'
      ..['licensor'] = 'Test Licensor'
      ..['scope'] = 'Digital use in CSP11 micro-learning.'
      ..['effectiveDate'] = '2026-09-01'
      ..['expiresAt'] = '2027-09-01'
      ..['startupDisplayPermitted'] = false
      ..['digitalRedistributionPermitted'] = true
      ..['protectedStructureReusePermitted'] = false;
    evidence['license'] = license;

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_EVIDENCE_LICENSE_INCOMPLETE'),
    );
  });

  test('protected structure requires explicit licensed permission', () {
    final evidence = cloneEvidence();
    final transformation = Map<String, dynamic>.from(
      evidence['transformation'] as Map,
    );
    transformation['tableCopied'] = true;
    evidence['transformation'] = transformation;

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_EVIDENCE_PROTECTED_STRUCTURE_NOT_LICENSED'),
    );
  });

  test('licensed protected structure can pass with explicit permission', () {
    final evidence = cloneEvidence();
    evidence['rightsTreatment'] = 'licensed_excerpt';

    final transformation = Map<String, dynamic>.from(
      evidence['transformation'] as Map,
    );
    transformation
      ..['independentWordingConfirmed'] = false
      ..['directQuoteUsed'] = true
      ..['quoteWordCount'] = 20
      ..['quoteSegmentCount'] = 1
      ..['quoteTextSha256'] = 'e' * 64
      ..['quoteNecessity'] = 'Licensed table excerpt.'
      ..['longestVerbatimRunWords'] = 20
      ..['tableCopied'] = true;
    evidence['transformation'] = transformation;

    final license = Map<String, dynamic>.from(evidence['license'] as Map);
    license
      ..['required'] = true
      ..['licenseId'] = 'LIC-TEST-002'
      ..['licensor'] = 'Test Licensor'
      ..['scope'] = 'Licensed startup display including table structure.'
      ..['effectiveDate'] = '2026-09-01'
      ..['expiresAt'] = '2027-09-01'
      ..['startupDisplayPermitted'] = true
      ..['digitalRedistributionPermitted'] = true
      ..['protectedStructureReusePermitted'] = true;
    evidence['license'] = license;

    final result = validator.validateMap(evidence);

    expect(result.issues, isEmpty, reason: result.issues.join('\n'));
  });

  test('raw protected source document cannot be stored in evidence', () {
    final evidence = cloneEvidence();
    final restricted = Map<String, dynamic>.from(
      evidence['restrictedMaterial'] as Map,
    );
    restricted['rawSourceDocumentStored'] = true;
    evidence['restrictedMaterial'] = restricted;

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_EVIDENCE_PROTECTED_SOURCE_STORED'),
    );
  });

  test('uncleared third-party material fails closed', () {
    final evidence = cloneEvidence();
    final restricted = Map<String, dynamic>.from(
      evidence['restrictedMaterial'] as Map,
    );
    restricted
      ..['thirdPartyMaterialPresent'] = true
      ..['thirdPartyMaterialCleared'] = false;
    evidence['restrictedMaterial'] = restricted;

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_EVIDENCE_THIRD_PARTY_NOT_CLEARED'),
    );
  });

  test('passing review requires human review', () {
    final evidence = cloneEvidence();
    final review = Map<String, dynamic>.from(evidence['review'] as Map);
    review['humanReviewed'] = false;
    evidence['review'] = review;

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_EVIDENCE_PASS_REQUIRES_HUMAN_REVIEW'),
    );
  });

  test('rights review due date cannot precede review date', () {
    final evidence = cloneEvidence();
    final review = Map<String, dynamic>.from(evidence['review'] as Map);
    review['nextReviewDueAt'] = '2026-09-22';
    evidence['review'] = review;

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_EVIDENCE_REVIEW_DATE_ORDER'),
    );
  });

  test('license expiry cannot precede effective date', () {
    final evidence = cloneEvidence();
    evidence['rightsTreatment'] = 'licensed_excerpt';

    final transformation = Map<String, dynamic>.from(
      evidence['transformation'] as Map,
    );
    transformation
      ..['independentWordingConfirmed'] = false
      ..['directQuoteUsed'] = true
      ..['quoteWordCount'] = 10
      ..['quoteSegmentCount'] = 1
      ..['quoteTextSha256'] = 'f' * 64
      ..['quoteNecessity'] = 'Licensed excerpt.'
      ..['longestVerbatimRunWords'] = 10;
    evidence['transformation'] = transformation;

    final license = Map<String, dynamic>.from(evidence['license'] as Map);
    license
      ..['required'] = true
      ..['licenseId'] = 'LIC-TEST-003'
      ..['licensor'] = 'Test Licensor'
      ..['scope'] = 'Digital use.'
      ..['effectiveDate'] = '2026-09-23'
      ..['expiresAt'] = '2026-09-22'
      ..['startupDisplayPermitted'] = true
      ..['digitalRedistributionPermitted'] = true
      ..['protectedStructureReusePermitted'] = false;
    evidence['license'] = license;

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_EVIDENCE_LICENSE_DATE_ORDER'),
    );
  });

  test('paraphrase cannot carry unexpected license metadata', () {
    final evidence = cloneEvidence();
    final license = Map<String, dynamic>.from(evidence['license'] as Map);
    license['licenseId'] = 'UNEXPECTED';
    evidence['license'] = license;

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_EVIDENCE_UNEXPECTED_LICENSE'),
    );
  });
}
