import 'dart:io';

import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/features/lab/lab_decision_question_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../quality_validator_contract/dqg300/_support/dqg300_fixture.dart';

String _source() =>
    File('test/fixtures/lab/l2_valid_lab.json').readAsStringSync();

LabPackage _package() => LabPackage.decode(_source());

void main() {
  const adapter = LabDecisionQuestionAdapter();

  test('Q3 builds scenario-specific explanation from pinned evidence', () {
    final package = _package();
    final node = package.nodes.whereType<LabDecisionNode>().first;
    final evidence = perfectDqg300Evidence();

    final draft = adapter.toCanonicalDraft(
      package: package,
      node: node,
      evidence: evidence,
    );

    for (final fact in evidence.decisiveScenarioFacts) {
      expect(draft.explanation, contains(fact));
    }
    for (final criterion in evidence.keySatisfiedCriteria) {
      expect(draft.explanation, contains(criterion));
    }
    expect(draft.explanation, isNot(contains('Internal DQG300-LAB evidence')));
  });

  test('Q3 builds BEST rationale from reviewed superiority proof', () {
    final package = _package();
    final node = package.nodes.whereType<LabDecisionNode>().first;
    final evidence = perfectDqg300Evidence();

    final draft = adapter.toCanonicalDraft(
      package: package,
      node: node,
      evidence: evidence,
    );

    expect(draft.bestAnswerRationale, contains('the BEST action'));
    expect(draft.bestAnswerRationale, contains('alternative 1'));
    expect(draft.bestAnswerRationale, contains('alternative 2'));
    expect(draft.bestAnswerRationale, contains('alternative 3'));
    expect(draft.bestAnswerRationale, isNot(contains('Internal DQG300-LAB')));
    expect(draft.bestAnswerRationale, isNot(contains('KEY')));
  });

  test('Q3 explanation and rationale remain deterministic', () {
    final package = _package();
    final node = package.nodes.whereType<LabDecisionNode>().first;
    final evidence = perfectDqg300Evidence();

    final first = adapter.toCanonicalDraft(
      package: package,
      node: node,
      evidence: evidence,
    );
    final second = adapter.toCanonicalDraft(
      package: package,
      node: node,
      evidence: evidence,
    );

    expect(second.explanation, first.explanation);
    expect(second.bestAnswerRationale, first.bestAnswerRationale);
  });

  test('Q3 fails closed when decisive scenario facts are absent', () {
    final package = _package();
    final node = package.nodes.whereType<LabDecisionNode>().first;
    final evidence = perfectDqg300Evidence().copyWith(
      decisiveScenarioFacts: const <String>[],
    );

    expect(
      () => adapter.toCanonicalDraft(
        package: package,
        node: node,
        evidence: evidence,
      ),
      throwsA(isA<LabContractException>()),
    );
  });

  test('Q3 fails closed when BEST criteria are absent', () {
    final package = _package();
    final node = package.nodes.whereType<LabDecisionNode>().first;
    final evidence = perfectDqg300Evidence().copyWith(
      keySatisfiedCriteria: const <String>[],
    );

    expect(
      () => adapter.toCanonicalDraft(
        package: package,
        node: node,
        evidence: evidence,
      ),
      throwsA(isA<LabContractException>()),
    );
  });

  test('Q3 fails closed when superiority proof is absent', () {
    final package = _package();
    final node = package.nodes.whereType<LabDecisionNode>().first;
    final evidence = perfectDqg300Evidence().copyWith(
      keySuperiorityProof: const <int, String>{},
    );

    expect(
      () => adapter.toCanonicalDraft(
        package: package,
        node: node,
        evidence: evidence,
      ),
      throwsA(isA<LabContractException>()),
    );
  });
}
