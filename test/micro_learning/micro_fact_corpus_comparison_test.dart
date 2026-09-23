import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/services/micro_learning/micro_fact_corpus_comparison.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const policyPath =
      'content/micro_learning/duplicate_contradiction_policy_v1.json';
  const basePath = 'test/fixtures/micro_learning/valid_micro_fact_v1.json';
  const distinctPath =
      'test/fixtures/micro_learning/distinct_micro_fact_v1.json';
  const nearPath =
      'test/fixtures/micro_learning/near_duplicate_micro_fact_v1.json';
  const polarityPath =
      'test/fixtures/micro_learning/polarity_conflict_micro_fact_v1.json';
  const legalPath =
      'test/fixtures/micro_learning/legal_status_conflict_micro_fact_v1.json';
  const noise90Path = 'test/fixtures/micro_learning/numeric_fact_90dba_v1.json';
  const noise85Path = 'test/fixtures/micro_learning/numeric_fact_85dba_v1.json';

  const comparison = MicroFactCorpusComparison();

  Map<String, dynamic> load(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  Map<String, dynamic> clone(Map<String, dynamic> value) =>
      jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

  test('normalization removes stop words but preserves negation', () {
    final policy = load(policyPath);
    final normalization = Map<String, dynamic>.from(
      policy['normalization'] as Map,
    );

    final tokens = MicroFactCorpusComparison.normalizedTokens(
      'The control must not be removed from the machine.',
      normalization,
    );

    expect(
      tokens,
      containsAll(['control', 'must', 'not', 'removed', 'machine']),
    );
    expect(tokens, isNot(contains('the')));
    expect(tokens, isNot(contains('from')));
  });

  test('distinct facts produce no duplicate or contradiction candidate', () {
    final result = comparison.compare(
      left: load(basePath),
      right: load(distinctPath),
      policy: load(policyPath),
    );

    expect(result.hasExactDuplicate, isFalse);
    expect(result.signals, isEmpty);
  });

  test('identical text across different fact IDs is an exact duplicate', () {
    final left = load(basePath);
    final right = clone(left);
    right['microFactId'] = 'mf_loto_exact_copy_0002';

    final result = comparison.compare(
      left: left,
      right: right,
      policy: load(policyPath),
    );

    expect(result.hasExactDuplicate, isTrue);
    expect(
      result.exactDuplicateReasons,
      containsAll([
        'exact_normalized_display',
        'exact_normalized_short',
        'exact_display_hash',
      ]),
    );
  });

  test('near duplicate is detected deterministically', () {
    final result = comparison.compare(
      left: load(basePath),
      right: load(nearPath),
      policy: load(policyPath),
    );

    expect(result.hasExactDuplicate, isFalse);
    expect(result.signals, contains('near_duplicate'));
    expect(result.signals, contains('concept_assisted_duplicate'));
    expect(result.displayJaccard, greaterThanOrEqualTo(0.8));
    expect(result.conceptJaccard, 1.0);
  });

  test('opposite negation creates polarity conflict candidate', () {
    final result = comparison.compare(
      left: load(basePath),
      right: load(polarityPath),
      policy: load(policyPath),
    );

    expect(result.signals, contains('polarity_conflict'));
  });

  test(
    'legal-status disagreement on same concept creates review candidate',
    () {
      final result = comparison.compare(
        left: load(basePath),
        right: load(legalPath),
        policy: load(policyPath),
      );

      expect(result.signals, contains('legal_status_conflict'));
    },
  );

  test(
    'different numeric values in the same unit create conflict candidate',
    () {
      final result = comparison.compare(
        left: load(noise90Path),
        right: load(noise85Path),
        policy: load(policyPath),
      );

      expect(result.signals, contains('numerical_conflict'));
      expect(result.signals, contains('same_source_locator_overlap'));
    },
  );

  test('same numeric value does not create numerical conflict', () {
    final left = load(noise90Path);
    final right = clone(left);
    right['microFactId'] = 'mf_noise_limit_same_value_0003';
    final display = Map<String, dynamic>.from(right['display'] as Map);
    display['displayText'] =
        'For general industry, OSHA uses 90 dBA as the 8-hour occupational noise exposure limit.';
    display['shortVariant'] =
        'OSHA uses 90 dBA for the 8-hour occupational noise limit.';
    right['display'] = display;

    final result = comparison.compare(
      left: left,
      right: right,
      policy: load(policyPath),
    );

    expect(result.signals, isNot(contains('numerical_conflict')));
  });

  test('different units are not automatically reconciled or conflicted', () {
    final left = load(noise90Path);
    final right = clone(load(noise85Path));
    final display = Map<String, dynamic>.from(right['display'] as Map);
    display['displayText'] =
        "OSHA's occupational noise rule uses 85 ppm as an 8-hour permissible exposure limit for general industry.";
    display['shortVariant'] =
        'OSHA uses 85 ppm for the 8-hour noise exposure limit.';
    right['display'] = display;

    final result = comparison.compare(
      left: left,
      right: right,
      policy: load(policyPath),
    );

    expect(result.signals, isNot(contains('numerical_conflict')));
  });

  test(
    'edition change on same source locator creates edition-drift candidate',
    () {
      final left = load(basePath);
      final right = clone(load(nearPath));
      final provenance = Map<String, dynamic>.from(right['provenance'] as Map);
      provenance['editionOrRevision'] = '29 CFR 1910.147 revised';
      right['provenance'] = provenance;

      final result = comparison.compare(
        left: left,
        right: right,
        policy: load(policyPath),
      );

      expect(result.signals, contains('edition_drift'));
    },
  );

  test('pair key is canonical regardless of input order', () {
    final left = load(basePath);
    final right = load(distinctPath);

    expect(
      MicroFactCorpusComparison.pairKey(left, right),
      MicroFactCorpusComparison.pairKey(right, left),
    );
  });

  test(
    'comparison fingerprint changes when comparison-relevant text changes',
    () {
      final left = load(basePath);
      final changed = clone(left);
      final display = Map<String, dynamic>.from(changed['display'] as Map);
      display['displayText'] =
          'Changed wording about hazardous energy during servicing.';
      changed['display'] = display;

      expect(
        MicroFactCorpusComparison.comparisonFingerprint(left),
        isNot(MicroFactCorpusComparison.comparisonFingerprint(changed)),
      );
    },
  );

  test('numeric signatures normalize equivalent unit spellings', () {
    final fact = load(noise90Path);
    final signatures = MicroFactCorpusComparison.numericSignatures(fact);

    expect(signatures['dba'], contains('90'));
  });
}
