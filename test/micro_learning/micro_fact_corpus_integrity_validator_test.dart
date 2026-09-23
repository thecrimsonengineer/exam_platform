import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/services/micro_learning/micro_fact_corpus_comparison.dart';
import 'package:exam_platform/services/micro_learning/micro_fact_corpus_integrity_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const policyPath =
      'content/micro_learning/duplicate_contradiction_policy_v1.json';
  const basePath = 'test/fixtures/micro_learning/valid_micro_fact_v1.json';
  const distinctPath =
      'test/fixtures/micro_learning/distinct_micro_fact_v1.json';
  const nearPath =
      'test/fixtures/micro_learning/near_duplicate_micro_fact_v1.json';
  const legalPath =
      'test/fixtures/micro_learning/legal_status_conflict_micro_fact_v1.json';
  const polarityPath =
      'test/fixtures/micro_learning/polarity_conflict_micro_fact_v1.json';
  const noise90Path =
      'test/fixtures/micro_learning/numeric_fact_90dba_v1.json';
  const noise85Path =
      'test/fixtures/micro_learning/numeric_fact_85dba_v1.json';

  const validator = MicroFactCorpusIntegrityValidator();
  const comparison = MicroFactCorpusComparison();

  Map<String, dynamic> load(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  Map<String, dynamic> clone(Map<String, dynamic> value) =>
      jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

  Map<String, dynamic> adjudication(
    Map<String, dynamic> left,
    Map<String, dynamic> right, {
    String decision = 'distinct_valid',
    String status = 'pass',
  }) {
    final pair = comparison.compare(
      left: left,
      right: right,
      policy: load(policyPath),
    );
    final ordered = [left, right]
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
      'evidenceId': 'mfce_corpus_pair_0001',
      'policyVersion': '1.0.0',
      'pairKey': pair.pairKey,
      'left': ref(ordered[0]),
      'right': ref(ordered[1]),
      'detectedSignals': pair.signals.toList()..sort(),
      'decision': decision,
      'review': {
        'status': status,
        'reviewerRole': 'content_governance_reviewer',
        'humanReviewed': true,
        'rationale':
            'Human comparison confirmed the appropriate pair disposition.',
        'reviewedAt': '2026-09-23',
        'nextReviewDueAt': '2027-09-23',
      },
    };
  }

  MicroFactCorpusIntegrityResult validate(
    List<Map<String, dynamic>> facts, {
    List<Map<String, dynamic>> adjudications = const [],
  }) {
    return validator.validate(
      facts: facts,
      policy: load(policyPath),
      adjudications: adjudications,
    );
  }

  test('two distinct facts pass without adjudication', () {
    final result = validate([load(basePath), load(distinctPath)]);

    expect(result.issues, isEmpty, reason: result.issues.join('\n'));
    expect(result.reviewCandidates, isEmpty);
  });

  test('exact duplicate is blocked without waiver path', () {
    final left = load(basePath);
    final right = clone(left);
    right['microFactId'] = 'mf_loto_exact_copy_0002';

    final result = validate([left, right]);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML8_EXACT_DUPLICATE'),
    );
  });

  test('near duplicate without adjudication fails closed', () {
    final left = load(basePath);
    final right = load(nearPath);

    final result = validate([left, right]);

    expect(result.isValid, isFalse);
    expect(result.reviewCandidates, hasLength(1));
    expect(
      result.reviewCandidates.single.signals,
      contains('near_duplicate'),
    );
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML8_ADJUDICATION_REQUIRED'),
    );
  });

  test('passing human distinct-valid adjudication allows coexistence', () {
    final left = load(basePath);
    final right = load(nearPath);
    final evidence = adjudication(left, right);

    final result = validate(
      [left, right],
      adjudications: [evidence],
    );

    expect(result.issues, isEmpty, reason: result.issues.join('\n'));
    expect(result.reviewCandidates, hasLength(1));
  });

  test('human duplicate-block decision blocks coexistence', () {
    final left = load(basePath);
    final right = load(nearPath);
    final evidence = adjudication(
      left,
      right,
      decision: 'duplicate_block',
    );

    final result = validate(
      [left, right],
      adjudications: [evidence],
    );

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML8_ADJUDICATED_BLOCK'),
    );
  });

  test('pending review cannot satisfy a detected pair', () {
    final left = load(basePath);
    final right = load(nearPath);
    final evidence = adjudication(left, right, status: 'pending');

    final result = validate(
      [left, right],
      adjudications: [evidence],
    );

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML8_ADJUDICATION_UNRESOLVED'),
    );
  });

  test('copy edit invalidates previous pair fingerprint', () {
    final left = load(basePath);
    final right = load(nearPath);
    final evidence = adjudication(left, right);

    final changed = clone(right);
    final display = Map<String, dynamic>.from(changed['display'] as Map);
    display['displayText'] =
        (display['displayText'] as String) + ' Workers remain protected.';
    changed['display'] = display;

    final result = validate(
      [left, changed],
      adjudications: [evidence],
    );

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML8_EVIDENCE_FINGERPRINT_DRIFT'),
    );
  });

  test('detected-signal drift invalidates adjudication', () {
    final left = load(basePath);
    final right = load(nearPath);
    final evidence = adjudication(left, right);
    evidence['detectedSignals'] = ['near_duplicate'];

    final result = validate(
      [left, right],
      adjudications: [evidence],
    );

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML8_EVIDENCE_SIGNAL_DRIFT'),
    );
  });

  test('orphaned adjudication fails closed', () {
    final base = load(basePath);
    final near = load(nearPath);
    final evidence = adjudication(base, near);

    final result = validate(
      [base, load(distinctPath)],
      adjudications: [evidence],
    );

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML8_ORPHAN_ADJUDICATION'),
    );
  });

  test('multiple active versions of one MicroFact ID are blocked', () {
    final first = load(basePath);
    final second = clone(first);
    second['contentVersion'] = 2;
    final display = Map<String, dynamic>.from(second['display'] as Map);
    display['displayText'] =
        'Revised hazardous energy wording for a second active content version.';
    display['shortVariant'] =
        'Revised hazardous energy wording for servicing.';
    second['display'] = display;

    final result = validate([first, second]);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML8_ACTIVE_VERSION_COLLISION'),
    );
  });

  test('superseded fact is excluded from blocking pair scan', () {
    final active = load(basePath);
    final superseded = clone(active);
    superseded
      ..['microFactId'] = 'mf_loto_retired_0009'
      ..['status'] = 'superseded';
    final runtime = Map<String, dynamic>.from(superseded['runtime'] as Map);
    runtime['startupEligible'] = false;
    superseded['runtime'] = runtime;
    final supersession = Map<String, dynamic>.from(
      superseded['supersession'] as Map,
    );
    supersession['supersededByMicroFactId'] = 'mf_loto_control_0001';
    superseded['supersession'] = supersession;

    final result = validate([active, superseded]);

    expect(result.issues, isEmpty, reason: result.issues.join('\n'));
  });

  test('numerical disagreement requires adjudication', () {
    final left = load(noise90Path);
    final right = load(noise85Path);

    final result = validate([left, right]);

    expect(result.isValid, isFalse);
    expect(result.reviewCandidates, hasLength(1));
    expect(
      result.reviewCandidates.single.signals,
      contains('numerical_conflict'),
    );
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML8_ADJUDICATION_REQUIRED'),
    );
  });

  test('legal-status conflict may coexist only after human scope decision', () {
    final left = load(basePath);
    final right = load(legalPath);
    final evidence = adjudication(
      left,
      right,
      decision: 'source_context_difference_valid',
    );

    final result = validate(
      [left, right],
      adjudications: [evidence],
    );

    expect(result.issues, isEmpty, reason: result.issues.join('\n'));
    expect(
      result.reviewCandidates.single.signals,
      contains('legal_status_conflict'),
    );
  });

  test('polarity conflict blocks when human decision confirms contradiction', () {
    final left = load(basePath);
    final right = load(polarityPath);
    final evidence = adjudication(
      left,
      right,
      decision: 'contradiction_block',
    );

    final result = validate(
      [left, right],
      adjudications: [evidence],
    );

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML8_ADJUDICATED_BLOCK'),
    );
  });

  test('concept concentration is reported but does not block ML-8', () {
    final seed = load(basePath);
    final facts = <Map<String, dynamic>>[];

    for (var i = 0; i < 4; i++) {
      final fact = clone(seed);
      fact['microFactId'] = 'mf_energy_density_000' + i.toString();
      final display = Map<String, dynamic>.from(fact['display'] as Map);
      final texts = [
        'Unexpected energy can injure workers during maintenance if machinery is not isolated.',
        'Maintenance planning should identify hazardous energy sources before service work begins.',
        'Stored machine energy can remain dangerous after a normal shutdown sequence.',
        'Energy-isolation planning considers electrical, mechanical, hydraulic, and other hazardous sources.',
      ];
      final shorts = [
        'Unexpected energy can injure workers during maintenance.',
        'Identify hazardous energy before maintenance begins.',
        'Stored energy may remain after normal shutdown.',
        'Isolation planning considers multiple hazardous energy sources.',
      ];
      display
        ..['displayText'] = texts[i]
        ..['shortVariant'] = shorts[i];
      fact['display'] = display;
      facts.add(fact);
    }

    final result = validate(facts);

    expect(result.issues, isEmpty, reason: result.issues.join('\n'));
    expect(
      result.concentrationSignals.map((signal) => signal.code),
      contains('ML8_CONCEPT_SET_CONCENTRATION'),
    );
  });

  test('authority concentration is audit-only at corpus scale', () {
    final seed = load(basePath);
    final facts = <Map<String, dynamic>>[];

    for (var i = 0; i < 20; i++) {
      final fact = clone(seed);
      fact['microFactId'] =
          'mf_authority_audit_' + i.toString().padLeft(2, '0') + '00';
      final display = Map<String, dynamic>.from(fact['display'] as Map);
      display
        ..['displayText'] =
            'Unique safety topic token' +
                i.toString() +
                ' describes a distinct prevention concept for workers.'
        ..['shortVariant'] =
            'Distinct prevention topic token' + i.toString() + ' for workers.';
      fact['display'] = display;

      final curriculum = Map<String, dynamic>.from(fact['curriculum'] as Map);
      curriculum['conceptIds'] = [
        'unique_concept_' + i.toString(),
        'unique_topic_' + i.toString(),
      ];
      fact['curriculum'] = curriculum;
      fact['tags'] = [
        'unique_concept_' + i.toString(),
        'unique_topic_' + i.toString(),
      ];

      final provenance = Map<String, dynamic>.from(
        fact['provenance'] as Map,
      );
      provenance['sourceLocator'] = 'Unique locator ' + i.toString();
      fact['provenance'] = provenance;
      facts.add(fact);
    }

    final result = validate(facts);

    expect(result.issues, isEmpty, reason: result.issues.join('\n'));
    expect(
      result.concentrationSignals.map((signal) => signal.code),
      contains('ML8_AUTHORITY_CONCENTRATION'),
    );
  });

  test('adjudication cannot be valid for more than 365 days', () {
    final left = load(basePath);
    final right = load(nearPath);
    final evidence = adjudication(left, right);
    final review = Map<String, dynamic>.from(evidence['review'] as Map);
    review['nextReviewDueAt'] = '2028-09-23';
    evidence['review'] = review;

    final result = validate(
      [left, right],
      adjudications: [evidence],
    );

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML8_ADJUDICATION_VALIDITY_TOO_LONG'),
    );
  });

  test('adjudication cannot predate individual fact review', () {
    final left = load(basePath);
    final right = load(nearPath);
    final evidence = adjudication(left, right);
    final review = Map<String, dynamic>.from(evidence['review'] as Map);
    review
      ..['reviewedAt'] = '2026-09-22'
      ..['nextReviewDueAt'] = '2027-09-22';
    evidence['review'] = review;

    final result = validate(
      [left, right],
      adjudications: [evidence],
    );

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML8_ADJUDICATION_PREDATES_FACT_REVIEW'),
    );
  });

  test('formal ML-8 evidence schema remains fail closed', () {
    final schema = load(
      'content/micro_learning/corpus_comparison_evidence_schema_v1.json',
    );
    final extension = Map<String, dynamic>.from(schema['x-csp11'] as Map);

    expect(schema['additionalProperties'], isFalse);
    expect(extension['phase'], 'ML-8');
    expect(extension['duplicateContradictionPolicyVersion'], '1.0.0');
    expect(extension['failClosed'], isTrue);
  });
}
