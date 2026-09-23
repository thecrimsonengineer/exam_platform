import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/services/micro_learning/corpus_comparison_evidence_validator.dart';
import 'package:exam_platform/services/micro_learning/micro_fact_corpus_comparison.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const basePath = 'test/fixtures/micro_learning/valid_micro_fact_v1.json';
  const nearPath =
      'test/fixtures/micro_learning/near_duplicate_micro_fact_v1.json';
  const validator = CorpusComparisonEvidenceValidator();

  Map<String, dynamic> load(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  Map<String, dynamic> clone(Map<String, dynamic> value) =>
      jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

  Map<String, dynamic> validEvidence() {
    final leftFact = load(basePath);
    final rightFact = load(nearPath);
    final facts = [leftFact, rightFact]
      ..sort(
        (a, b) => MicroFactCorpusComparison.factVersionKey(a).compareTo(
          MicroFactCorpusComparison.factVersionKey(b),
        ),
      );

    Map<String, dynamic> ref(Map<String, dynamic> fact) => {
          'microFactId': fact['microFactId'],
          'contentVersion': fact['contentVersion'],
          'comparisonFingerprintSha256':
              MicroFactCorpusComparison.comparisonFingerprint(fact),
        };

    return {
      'schemaVersion': 1,
      'evidenceId': 'mfce_loto_pair_0001',
      'policyVersion': '1.0.0',
      'pairKey': MicroFactCorpusComparison.pairKey(leftFact, rightFact),
      'left': ref(facts[0]),
      'right': ref(facts[1]),
      'detectedSignals': [
        'near_duplicate',
        'concept_assisted_duplicate',
        'same_source_locator_overlap',
      ],
      'decision': 'distinct_valid',
      'review': {
        'status': 'pass',
        'reviewerRole': 'content_governance_reviewer',
        'humanReviewed': true,
        'rationale':
            'The two facts address different learner emphasis despite high wording overlap.',
        'reviewedAt': '2026-09-23',
        'nextReviewDueAt': '2027-09-23',
      },
    };
  }

  test('valid corpus comparison evidence passes', () {
    final result = validator.validateMap(validEvidence());
    expect(result.issues, isEmpty, reason: result.issues.join('\n'));
  });

  test('unknown root field fails closed', () {
    final evidence = validEvidence();
    evidence['shadowOverride'] = true;

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML8_EVIDENCE_UNKNOWN_FIELD'),
    );
  });

  test('pair ordering must be canonical', () {
    final evidence = validEvidence();
    final left = Map<String, dynamic>.from(evidence['left'] as Map);
    final right = Map<String, dynamic>.from(evidence['right'] as Map);
    evidence
      ..['left'] = right
      ..['right'] = left;

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML8_EVIDENCE_PAIR_ORDER'),
    );
  });

  test('pair key must match canonical references', () {
    final evidence = validEvidence();
    evidence['pairKey'] = 'mf_fake@1||mf_other@1';

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML8_EVIDENCE_PAIR_KEY'),
    );
  });

  test('unknown comparison signal is rejected', () {
    final evidence = validEvidence();
    evidence['detectedSignals'] = ['ai_similarity_guess'];

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML8_EVIDENCE_SIGNALS'),
    );
  });

  test('duplicate signals are rejected', () {
    final evidence = validEvidence();
    evidence['detectedSignals'] = ['near_duplicate', 'near_duplicate'];

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML8_EVIDENCE_SIGNALS'),
    );
  });

  test('fact fingerprint must be lowercase SHA-256', () {
    final evidence = validEvidence();
    final left = Map<String, dynamic>.from(evidence['left'] as Map);
    left['comparisonFingerprintSha256'] = 'bad';
    evidence['left'] = left;

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML8_EVIDENCE_FINGERPRINT'),
    );
  });

  test('unknown adjudication decision is rejected', () {
    final evidence = validEvidence();
    evidence['decision'] = 'let_ai_choose';

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML8_EVIDENCE_DECISION'),
    );
  });

  test('passing adjudication requires human review', () {
    final evidence = validEvidence();
    final review = Map<String, dynamic>.from(evidence['review'] as Map);
    review['humanReviewed'] = false;
    evidence['review'] = review;

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML8_EVIDENCE_PASS_REQUIREMENTS'),
    );
  });

  test('reviewer role must be approved', () {
    final evidence = validEvidence();
    final review = Map<String, dynamic>.from(evidence['review'] as Map);
    review['reviewerRole'] = 'ai_reviewer';
    evidence['review'] = review;

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML8_EVIDENCE_REVIEWER_ROLE'),
    );
  });

  test('review due date cannot precede review date', () {
    final evidence = validEvidence();
    final review = Map<String, dynamic>.from(evidence['review'] as Map);
    review['nextReviewDueAt'] = '2026-09-22';
    evidence['review'] = review;

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML8_EVIDENCE_REVIEW_DATE_ORDER'),
    );
  });

  test('evidence cloning remains deterministic for adversarial mutation', () {
    final evidence = validEvidence();
    final copied = clone(evidence);

    expect(copied, evidence);
  });
}
