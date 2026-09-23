import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/features/lab/lab_decision_question_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../quality_validator_contract/dqg300/_support/dqg300_fixture.dart';

String _source() =>
    File('test/fixtures/lab/l2_valid_lab.json').readAsStringSync();

LabPackage _package() => LabPackage.decode(_source());

final _evidence = perfectDqg300Evidence();

void main() {
  const adapter = LabDecisionQuestionAdapter();

  test('Q2 converts a LAB Decision into canonical parser fields', () {
    final package = _package();
    final node = package.nodes.whereType<LabDecisionNode>().first;

    final draft = adapter.toCanonicalDraft(
      package: package,
      node: node,
      evidence: _evidence,
    );

    expect(draft.question, node.prompt);
    expect(draft.options, node.options.map((option) => option.text).toList());
    expect(draft.correctAnswer, 0);
    expect(draft.difficulty, 'Hard');
    expect(draft.cognitiveLevel, 'analysis');
    expect(draft.questionType, 'scenario_mcq');
    expect(draft.reference, 'HSE L101');
    expect(draft.tags, ['lab-dqg300', node.id]);
    expect(draft.explanation, isNotEmpty);
    expect(draft.bestAnswerRationale, isNotEmpty);
  });

  test('Q2 attaches LAB identity after canonical parsing', () {
    final package = _package();
    final node = package.nodes.whereType<LabDecisionNode>().first;

    final question = adapter.toQuestion(
      package: package,
      node: node,
      evidence: _evidence,
      decisionIndex: 0,
    );

    expect(question.id, 1);
    expect(question.domain, 7);
    expect(question.competencyId, 'd07_c01');
    expect(question.topicId, isEmpty);
    expect(question.subtopicId, isEmpty);
    expect(question.quizId, 'l2_lab_decision_one');
    expect(question.contentPackageId, 'l2_lab-v1');
    expect(question.question, node.prompt);
    expect(question.correctAnswer, 0);
    expect(question.status, 'validated');
    expect(question.version, 1);
  });

  test('Q2 preserves a BEST answer that is not option A', () {
    final package = _package();
    final original = package.nodes.whereType<LabDecisionNode>().first;
    final options = <LabDecisionOption>[
      LabDecisionOption(
        id: 'q2_option_a',
        text: 'Option A',
        isBest: false,
        quality: LabDecisionQuality.defensible,
        consequence: LabConsequence(id: 'q2_consequence_a', explicitNoOp: true),
      ),
      LabDecisionOption(
        id: 'q2_option_b',
        text: 'Option B',
        isBest: false,
        quality: LabDecisionQuality.weak,
        consequence: LabConsequence(id: 'q2_consequence_b', explicitNoOp: true),
      ),
      LabDecisionOption(
        id: 'q2_option_c',
        text: 'Option C',
        isBest: true,
        quality: LabDecisionQuality.optimal,
        consequence: LabConsequence(id: 'q2_consequence_c', explicitNoOp: true),
      ),
      LabDecisionOption(
        id: 'q2_option_d',
        text: 'Option D',
        isBest: false,
        quality: LabDecisionQuality.critical,
        consequence: LabConsequence(id: 'q2_consequence_d', explicitNoOp: true),
      ),
    ];
    final node = LabDecisionNode(
      id: original.id,
      prompt: original.prompt,
      options: options,
    );

    final question = adapter.toQuestion(
      package: package,
      node: node,
      evidence: _evidence,
      decisionIndex: 0,
    );

    expect(question.correctAnswer, 2);
    expect(question.options[question.correctAnswer], 'Option C');
  });

  test('Q2 uses the first canonical competency mapping for identity', () {
    final decoded = jsonDecode(_source()) as Map;
    final root = decoded.cast<String, Object?>();
    root['competencyMappings'] = <String>['d06_c05', 'd07_c01'];
    final package = LabPackage.fromJson(root);
    final node = package.nodes.whereType<LabDecisionNode>().first;

    final question = adapter.toQuestion(
      package: package,
      node: node,
      evidence: _evidence,
      decisionIndex: 1,
    );

    expect(question.id, 2);
    expect(question.domain, 6);
    expect(question.competencyId, 'd06_c05');
  });

  test('Q2 preserves compatibility behavior when competency is absent', () {
    final decoded = jsonDecode(_source()) as Map;
    final root = decoded.cast<String, Object?>();
    root['competencyMappings'] = <String>[];
    final package = LabPackage.fromJson(root);
    final node = package.nodes.whereType<LabDecisionNode>().first;

    final question = adapter.toQuestion(
      package: package,
      node: node,
      evidence: _evidence,
      decisionIndex: 0,
    );

    expect(question.domain, 0);
    expect(question.competencyId, isEmpty);
  });

  test('Q2 rejects a negative decision index', () {
    final package = _package();
    final node = package.nodes.whereType<LabDecisionNode>().first;

    expect(
      () => adapter.toQuestion(
        package: package,
        node: node,
        evidence: _evidence,
        decisionIndex: -1,
      ),
      throwsArgumentError,
    );
  });
}
