import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/features/lab/lab_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'lab_test_fixtures.dart';

void main() {
  const engine = LabConsequenceEngine();

  for (var i = 0; i < 20; i++) {
    test('LAB-2 boolean mutation ' + (i + 1).toString(), () {
      final expected = i.isEven;
      final result = engine.apply(
        state: buildState(),
        consequence: consequence(
          id: 'bool_' + i.toString(),
          mutations: [
            LabStateMutation(
              kind: LabMutationKind.set,
              stateId: 'hazard_active',
              value: expected,
            ),
          ],
        ),
        applicationKey: 'bool_key_' + i.toString(),
      );
      expect(result.state.valueOf('hazard_active'), expected);
      expect(result.delta.containsKey('hazard_active'), isTrue);
    });
  }

  for (var i = 0; i < 40; i++) {
    test('LAB-2 bounded numeric mutation ' + (i + 1).toString(), () {
      final increment = (i % 5) + 1;
      final result = engine.apply(
        state: buildState(riskScore: 10),
        consequence: consequence(
          id: 'num_' + i.toString(),
          mutations: [
            LabStateMutation(
              kind: LabMutationKind.increment,
              stateId: 'risk_score',
              value: increment,
            ),
          ],
        ),
        applicationKey: 'num_key_' + i.toString(),
      );
      expect(result.state.valueOf('risk_score'), 10 + increment);
    });
  }

  for (var i = 0; i < 20; i++) {
    test('LAB-2 numeric bound rejection ' + (i + 1).toString(), () {
      expect(
        () => engine.apply(
          state: buildState(riskScore: 95),
          consequence: consequence(
            id: 'bound_' + i.toString(),
            mutations: [
              LabStateMutation(
                kind: LabMutationKind.increment,
                stateId: 'risk_score',
                value: 10 + i,
              ),
            ],
          ),
          applicationKey: 'bound_key_' + i.toString(),
        ),
        throwsA(isA<LabContractException>()),
      );
    });
  }

  for (var i = 0; i < 20; i++) {
    test('LAB-2 enum mutation ' + (i + 1).toString(), () {
      final expected = i.isEven ? 'active' : 'stopped';
      final result = engine.apply(
        state: buildState(),
        consequence: consequence(
          id: 'enum_' + i.toString(),
          mutations: [
            LabStateMutation(
              kind: LabMutationKind.set,
              stateId: 'work_status',
              value: expected,
            ),
          ],
        ),
        applicationKey: 'enum_key_' + i.toString(),
      );
      expect(result.state.valueOf('work_status'), expected);
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-2 set mutation ' + (i + 1).toString(), () {
      final member = 'tag_' + i.toString();
      final result = engine.apply(
        state: buildState(),
        consequence: consequence(
          id: 'set_' + i.toString(),
          mutations: [
            LabStateMutation(
              kind: LabMutationKind.add,
              stateId: 'evidence_tags',
              value: member,
            ),
          ],
        ),
        applicationKey: 'set_key_' + i.toString(),
      );
      expect(result.state.valueOf('evidence_tags'), contains(member));
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-2 list mutation ' + (i + 1).toString(), () {
      final member = 'action_' + i.toString();
      final result = engine.apply(
        state: buildState(),
        consequence: consequence(
          id: 'list_' + i.toString(),
          mutations: [
            LabStateMutation(
              kind: LabMutationKind.add,
              stateId: 'actions',
              value: member,
            ),
          ],
        ),
        applicationKey: 'list_key_' + i.toString(),
      );
      expect(result.state.valueOf('actions'), contains(member));
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-2 evidence and simulated time ' + (i + 1).toString(), () {
      final result = engine.apply(
        state: buildState(),
        consequence: consequence(
          id: 'time_' + i.toString(),
          mutations: const [LabStateMutation(kind: LabMutationKind.noOp)],
          evidenceUnlocks: ['evidence_' + i.toString()],
          simulatedMinutes: i,
        ),
        applicationKey: 'time_key_' + i.toString(),
      );
      expect(
        result.state.evidenceUnlocked,
        contains('evidence_' + i.toString()),
      );
      expect(result.state.simulatedMinutes, i);
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-2 irreversible flag ' + (i + 1).toString(), () {
      final first = engine.apply(
        state: buildState(),
        consequence: consequence(
          id: 'irreversible_set_' + i.toString(),
          mutations: const [
            LabStateMutation(
              kind: LabMutationKind.set,
              stateId: 'worker_collapsed',
              value: true,
            ),
          ],
        ),
        applicationKey: 'irreversible_first_' + i.toString(),
      );

      expect(
        () => engine.apply(
          state: first.state,
          consequence: consequence(
            id: 'irreversible_reset_' + i.toString(),
            mutations: const [
              LabStateMutation(
                kind: LabMutationKind.set,
                stateId: 'worker_collapsed',
                value: false,
              ),
            ],
          ),
          applicationKey: 'irreversible_second_' + i.toString(),
        ),
        throwsA(isA<LabContractException>()),
      );
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-2 idempotent consequence ' + (i + 1).toString(), () {
      final item = consequence(
        id: 'idem_' + i.toString(),
        mutations: const [
          LabStateMutation(
            kind: LabMutationKind.increment,
            stateId: 'risk_score',
            value: 5,
          ),
        ],
      );
      final first = engine.apply(
        state: buildState(),
        consequence: item,
        applicationKey: 'idem_key_' + i.toString(),
      );
      final second = engine.apply(
        state: first.state,
        consequence: item,
        applicationKey: 'idem_key_' + i.toString(),
      );
      expect(second.duplicate, isTrue);
      expect(second.state.valueOf('risk_score'), 15);
      expect(second.before.values, second.after.values);
    });
  }
}
