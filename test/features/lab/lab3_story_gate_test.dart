import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/features/lab/lab_runtime.dart';
import 'package:exam_platform/features/lab/lab_story_gate.dart';
import 'package:flutter_test/flutter_test.dart';

import 'lab_test_fixtures.dart';

void main() {
  const evaluator = LabGateEvaluator();

  for (var i = 0; i < 40; i++) {
    test('LAB-3 numeric predicate ' + (i + 1).toString(), () {
      final operators = LabNumericOperator.values;
      final op = operators[i % operators.length];
      final condition = LabNumericCondition(
        stateId: 'risk_score',
        operator: op,
        value: 10,
      );
      final actual = condition.evaluate(buildState(riskScore: 10));
      final expected = switch (op) {
        LabNumericOperator.lessThan => false,
        LabNumericOperator.lessOrEqual => true,
        LabNumericOperator.equal => true,
        LabNumericOperator.greaterOrEqual => true,
        LabNumericOperator.greaterThan => false,
      };
      expect(actual, expected);
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-3 boolean predicate ' + (i + 1).toString(), () {
      final expected = i.isEven;
      final condition = LabBooleanCondition(
        stateId: 'hazard_active',
        expected: expected,
      );
      expect(condition.evaluate(buildState(hazardActive: expected)), isTrue);
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-3 enum predicate ' + (i + 1).toString(), () {
      final expected = i.isEven ? 'active' : 'stopped';
      final condition = LabEnumCondition(
        stateId: 'work_status',
        expected: expected,
      );
      expect(condition.evaluate(buildState(workStatus: expected)), isTrue);
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-3 set predicate ' + (i + 1).toString(), () {
      final member = 'tag_' + i.toString();
      final condition = LabSetContainsCondition(
        stateId: 'evidence_tags',
        member: member,
      );
      expect(condition.evaluate(buildState(evidenceTags: [member])), isTrue);
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-3 compound AND ' + (i + 1).toString(), () {
      final condition = LabAllCondition([
        const LabAlwaysCondition(),
        LabBooleanCondition(stateId: 'hazard_active', expected: true),
      ]);
      expect(condition.evaluate(buildState(hazardActive: true)), isTrue);
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-3 compound OR ' + (i + 1).toString(), () {
      final condition = LabAnyCondition([
        LabBooleanCondition(stateId: 'hazard_active', expected: true),
        const LabAlwaysCondition(),
      ]);
      expect(condition.evaluate(buildState(hazardActive: false)), isTrue);
    });
  }

  for (var i = 0; i < 20; i++) {
    test('LAB-3 deterministic priority ' + (i + 1).toString(), () {
      final result = evaluator.evaluate(
        state: buildState(),
        currentNodeId: 'decision_start',
        gates: [
          LabStoryGate(
            id: 'low_' + i.toString(),
            type: LabGateType.route,
            priority: i,
            condition: const LabAlwaysCondition(),
            targetNodeId: 'low_target',
          ),
          LabStoryGate(
            id: 'high_' + i.toString(),
            type: LabGateType.route,
            priority: 100 + i,
            condition: const LabAlwaysCondition(),
            targetNodeId: 'high_target',
          ),
        ],
      );
      expect(result?.targetNodeId, 'high_target');
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-3 equal-priority ambiguity ' + (i + 1).toString(), () {
      expect(
        () => evaluator.evaluate(
          state: buildState(),
          currentNodeId: 'decision_start',
          gates: [
            LabStoryGate(
              id: 'amb_a_' + i.toString(),
              type: LabGateType.route,
              priority: 5,
              condition: const LabAlwaysCondition(),
              targetNodeId: 'target_a',
            ),
            LabStoryGate(
              id: 'amb_b_' + i.toString(),
              type: LabGateType.route,
              priority: 5,
              condition: const LabAlwaysCondition(),
              targetNodeId: 'target_b',
            ),
          ],
        ),
        throwsA(isA<LabGateAmbiguityException>()),
      );
    });
  }

  for (var i = 0; i < 30; i++) {
    test('LAB-3 six gate types ' + (i + 1).toString(), () {
      final type = LabGateType.values[i % LabGateType.values.length];
      final LabStoryGate gate;
      if (type == LabGateType.completion) {
        gate = LabStoryGate(
          id: 'gate_' + i.toString(),
          type: type,
          priority: 10,
          condition: const LabAlwaysCondition(),
          endingId: 'safe_end',
        );
      } else if (type == LabGateType.route ||
          type == LabGateType.criticalEvent ||
          type == LabGateType.convergence) {
        gate = LabStoryGate(
          id: 'gate_' + i.toString(),
          type: type,
          priority: 10,
          condition: const LabAlwaysCondition(),
          targetNodeId: 'next_scene',
        );
      } else {
        gate = LabStoryGate(
          id: 'gate_' + i.toString(),
          type: type,
          priority: 10,
          condition: const LabAlwaysCondition(),
        );
      }
      final result = evaluator.evaluate(
        state: buildState(),
        currentNodeId: 'decision_start',
        gates: [gate],
      );
      expect(result?.type, type);
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-3 deterministic replay ' + (i + 1).toString(), () {
      final gates = [
        LabStoryGate(
          id: 'replay_' + i.toString(),
          type: LabGateType.convergence,
          priority: 30,
          condition: const LabAlwaysCondition(),
          targetNodeId: 'shared_scene',
        ),
      ];
      final state = buildState();
      final first = evaluator.evaluate(
        state: state,
        currentNodeId: 'decision_start',
        gates: gates,
      );
      final second = evaluator.evaluate(
        state: state,
        currentNodeId: 'decision_start',
        gates: gates,
      );
      expect(first?.gateId, second?.gateId);
      expect(first?.targetNodeId, second?.targetNodeId);
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-3 consequence then gate runtime ' + (i + 1).toString(), () {
      final options = List<LabDecisionOption>.generate(
        4,
        (index) => LabDecisionOption(
          id: 'option_' + (index + 1).toString(),
          text: 'Option ' + (index + 1).toString(),
          isBest: index == 0,
          quality: index == 0
              ? LabDecisionQuality.optimal
              : LabDecisionQuality.weak,
          consequence: LabConsequence(
            id: 'runtime_consequence_' + (index + 1).toString(),
            mutations: [
              LabStateMutation(
                kind: LabMutationKind.set,
                stateId: 'risk_score',
                value: index == 0 ? 20 : 70,
              ),
            ],
          ),
        ),
      );
      final node = LabDecisionNode(
        id: 'decision_start',
        prompt: 'Choose.',
        options: options,
      );
      const runtime = LabDeterministicRuntime();
      final result = runtime.resolveDecision(
        state: buildState(),
        node: node,
        optionId: 'option_1',
        applicationKey: 'runtime_' + i.toString(),
        gates: [
          LabStoryGate(
            id: 'route_safe_' + i.toString(),
            type: LabGateType.route,
            priority: 20,
            condition: LabNumericCondition(
              stateId: 'risk_score',
              operator: LabNumericOperator.lessOrEqual,
              value: 20,
            ),
            targetNodeId: 'safe_scene',
          ),
        ],
      );
      expect(result.state.valueOf('risk_score'), 20);
      expect(result.gate?.targetNodeId, 'safe_scene');
    });
  }
}
