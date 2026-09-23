import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/services/micro_learning/startup_pedagogy_evidence_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const path =
      'test/fixtures/micro_learning/valid_startup_pedagogy_evidence_v1.json';
  const validator = StartupPedagogyEvidenceValidator();

  Map<String, dynamic> load() =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  Map<String, dynamic> clone() =>
      jsonDecode(jsonEncode(load())) as Map<String, dynamic>;

  test('valid startup pedagogy evidence passes', () {
    final result = validator.validateMap(load());
    expect(result.issues, isEmpty, reason: result.issues.join('\n'));
  });

  test('unknown root field fails closed', () {
    final evidence = clone();
    evidence['shadowOverride'] = true;

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_EVIDENCE_UNKNOWN_FIELD'),
    );
  });

  test('unknown nested review field fails closed', () {
    final evidence = clone();
    final review = Map<String, dynamic>.from(evidence['pedagogyReview'] as Map);
    review['skipMeaningCheck'] = true;
    evidence['pedagogyReview'] = review;

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_EVIDENCE_UNKNOWN_FIELD'),
    );
  });

  test('invalid display hash is rejected', () {
    final evidence = clone();
    final fingerprint = Map<String, dynamic>.from(
      evidence['contentFingerprint'] as Map,
    );
    fingerprint['displayTextSha256'] = 'bad';
    evidence['contentFingerprint'] = fingerprint;

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_EVIDENCE_DISPLAY_HASH'),
    );
  });

  test('partial short metrics are rejected', () {
    final evidence = clone();
    final metrics = Map<String, dynamic>.from(evidence['metrics'] as Map);
    metrics
      ..['shortWordCount'] = null
      ..['shortSentenceCount'] = 1
      ..['computedShortReadSeconds'] = 4;
    evidence['metrics'] = metrics;

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_EVIDENCE_SHORT_METRICS_PARTIAL'),
    );
  });

  test('passing pedagogy review requires every human attestation', () {
    final evidence = clone();
    final review = Map<String, dynamic>.from(evidence['pedagogyReview'] as Map);
    review['singleConceptConfirmed'] = false;
    evidence['pedagogyReview'] = review;

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_EVIDENCE_PEDAGOGY_PASS_REQUIREMENTS'),
    );
  });

  test('passing accessibility review requires visual independence', () {
    final evidence = clone();
    final review = Map<String, dynamic>.from(
      evidence['accessibilityReview'] as Map,
    );
    review['visualIndependenceConfirmed'] = false;
    evidence['accessibilityReview'] = review;

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_EVIDENCE_ACCESSIBILITY_PASS_REQUIREMENTS'),
    );
  });

  test('pedagogy reviewer role must be approved', () {
    final evidence = clone();
    final review = Map<String, dynamic>.from(evidence['pedagogyReview'] as Map);
    review['reviewerRole'] = 'ai_reviewer';
    evidence['pedagogyReview'] = review;

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_EVIDENCE_PEDAGOGY_ROLE'),
    );
  });

  test('accessibility reviewer role must be approved', () {
    final evidence = clone();
    final review = Map<String, dynamic>.from(
      evidence['accessibilityReview'] as Map,
    );
    review['reviewerRole'] = 'subject_matter_reviewer';
    evidence['accessibilityReview'] = review;

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_EVIDENCE_ACCESSIBILITY_ROLE'),
    );
  });

  test('review due date cannot precede review date', () {
    final evidence = clone();
    final review = Map<String, dynamic>.from(
      evidence['accessibilityReview'] as Map,
    );
    review['nextReviewDueAt'] = '2026-09-22';
    evidence['accessibilityReview'] = review;

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_EVIDENCE_REVIEW_DATE_ORDER'),
    );
  });

  test('formal ML-7 evidence policy version is frozen', () {
    final evidence = clone();
    evidence['pedagogyPolicyVersion'] = '2.0.0';

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_EVIDENCE_POLICY_VERSION'),
    );
  });
}
