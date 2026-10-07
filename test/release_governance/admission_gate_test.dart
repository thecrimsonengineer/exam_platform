import 'package:flutter_test/flutter_test.dart';

import '../../tool/release_governance/release_admission.dart';

void main() {
  group('ReleaseAdmissionPolicy canonical registry', () {
    test('freezes all 17 required REL-GOV gates in order', () {
      expect(
        ReleaseAdmissionPolicy.canonicalDefinitions
            .map((definition) => '${definition.gateId}:${definition.name}')
            .toList(),
        <String>[
          'RG001:repository_clean',
          'RG002:repository_identity',
          'RG003:version_valid',
          'RG004:build_number_valid',
          'RG005:dependency_lock',
          'RG006:environment_valid',
          'RG007:formatter',
          'RG008:analyzer',
          'RG009:unit_tests',
          'RG010:widget_tests',
          'RG011:schema_validation',
          'RG012:component_evidence',
          'RG013:artifact_inventory',
          'RG014:artifact_hashes',
          'RG015:provenance',
          'RG016:release_state',
          'RG017:manifest_completeness',
        ],
      );

      expect(
        ReleaseAdmissionPolicy.canonicalDefinitions.every(
          (definition) =>
              definition.blocking &&
              definition.severity == ReleaseAdmissionGateSeverity.error,
        ),
        isTrue,
      );
    });
  });

  group('ReleaseAdmissionPolicy evaluate', () {
    const policy = ReleaseAdmissionPolicy();

    test('admits only the complete evidence-backed PASS set', () {
      final result = policy.evaluate(_passingGates());

      expect(result.admissible, isTrue);
      expect(result.decision, ReleaseAdmissionDecision.admissible);
      expect(result.requiredGateCount, 17);
      expect(result.passedGateCount, 17);
      expect(result.blockingFailureCount, 0);
      expect(result.issues, isEmpty);
    });

    test('blocks a failed required gate', () {
      final gates = _passingGates();
      gates[8] = gates[8].copyWith(
        status: ReleaseAdmissionGateStatus.fail,
        message: 'Unit tests failed.',
      );

      final result = policy.evaluate(gates);

      expect(result.admissible, isFalse);
      expect(result.passedGateCount, 16);
      expect(
        result.issues.map((issue) => issue.code),
        contains('RGA012_REQUIRED_GATE_FAILED'),
      );
    });

    test('blocks a missing required gate', () {
      final gates = _passingGates()
        ..removeWhere((gate) => gate.gateId == 'RG014');

      final result = policy.evaluate(gates);

      expect(result.admissible, isFalse);
      expect(
        result.issues.any(
          (issue) =>
              issue.code == 'RGA003_MISSING_REQUIRED_GATE' &&
              issue.gateId == 'RG014',
        ),
        isTrue,
      );
    });

    test('blocks duplicate canonical gates', () {
      final gates = _passingGates()..add(_passingGates().first);

      final result = policy.evaluate(gates);

      expect(result.admissible, isFalse);
      expect(
        result.issues.map((issue) => issue.code),
        contains('RGA001_DUPLICATE_GATE'),
      );
    });

    test('blocks unknown gates', () {
      final gates = _passingGates()
        ..add(
          const ReleaseAdmissionGate(
            gateId: 'RG999',
            name: 'invented_gate',
            status: ReleaseAdmissionGateStatus.pass,
            severity: ReleaseAdmissionGateSeverity.error,
            blocking: true,
            evidence: <String>['evidence/rg999.json'],
            message: 'Invented gate passed.',
          ),
        );

      final result = policy.evaluate(gates);

      expect(result.admissible, isFalse);
      expect(
        result.issues.map((issue) => issue.code),
        contains('RGA002_UNKNOWN_GATE'),
      );
    });

    test('blocks PASS without evidence', () {
      final gates = _passingGates();
      gates[2] = gates[2].copyWith(evidence: const <String>[]);

      final result = policy.evaluate(gates);

      expect(result.admissible, isFalse);
      expect(result.passedGateCount, 16);
      expect(
        result.issues.map((issue) => issue.code),
        contains('RGA008_PASS_EVIDENCE_MISSING'),
      );
    });

    test('blocks blank and duplicate evidence references', () {
      final gates = _passingGates();
      gates[4] = gates[4].copyWith(
        evidence: const <String>[
          'evidence/dependencies.json',
          '',
          'evidence/dependencies.json',
        ],
      );

      final result = policy.evaluate(gates);
      final codes = result.issues.map((issue) => issue.code).toList();

      expect(result.admissible, isFalse);
      expect(codes, contains('RGA009_INVALID_EVIDENCE_REF'));
      expect(codes, contains('RGA010_DUPLICATE_EVIDENCE_REF'));
    });

    test('blocks attempts to weaken canonical gate policy', () {
      final gates = _passingGates();
      gates[0] = gates[0].copyWith(
        name: 'repository_optional',
        severity: ReleaseAdmissionGateSeverity.warning,
        blocking: false,
      );

      final result = policy.evaluate(gates);
      final codes = result.issues.map((issue) => issue.code).toList();

      expect(result.admissible, isFalse);
      expect(codes, contains('RGA004_GATE_NAME_MISMATCH'));
      expect(codes, contains('RGA005_GATE_SEVERITY_MISMATCH'));
      expect(codes, contains('RGA006_GATE_BLOCKING_MISMATCH'));
    });

    test('blocks empty gate messages', () {
      final gates = _passingGates();
      gates[6] = gates[6].copyWith(message: '   ');

      final result = policy.evaluate(gates);

      expect(result.admissible, isFalse);
      expect(
        result.issues.map((issue) => issue.code),
        contains('RGA007_GATE_MESSAGE_MISSING'),
      );
    });

    test('blocks NOT_APPLICABLE unless policy explicitly permits it', () {
      final gates = _passingGates();
      gates[12] = gates[12].copyWith(
        status: ReleaseAdmissionGateStatus.notApplicable,
        message: 'Artifact inventory not applicable.',
      );

      final result = policy.evaluate(gates);

      expect(result.admissible, isFalse);
      expect(
        result.issues.map((issue) => issue.code),
        contains('RGA011_NOT_APPLICABLE_NOT_PERMITTED'),
      );
    });

    test('permits NOT_APPLICABLE only through explicit policy', () {
      const policyWithException = ReleaseAdmissionPolicy(
        permittedNotApplicableGateIds: <String>{'RG013'},
      );
      final gates = _passingGates();
      gates[12] = gates[12].copyWith(
        status: ReleaseAdmissionGateStatus.notApplicable,
        message: 'Artifact inventory explicitly exempted by policy.',
      );

      final result = policyWithException.evaluate(gates);

      expect(result.admissible, isTrue);
      expect(result.passedGateCount, 16);
      expect(result.blockingFailureCount, 0);
    });

    test('rejects invalid NOT_APPLICABLE policy gate IDs', () {
      const invalidPolicy = ReleaseAdmissionPolicy(
        permittedNotApplicableGateIds: <String>{'RG999'},
      );

      expect(
        () => invalidPolicy.evaluate(_passingGates()),
        throwsArgumentError,
      );
    });

    test('emits canonical gate order independent of input order', () {
      final reversed = _passingGates().reversed.toList();

      final result = policy.evaluate(reversed);

      expect(
        result.gates.map((gate) => gate.gateId).toList(),
        ReleaseAdmissionPolicy.canonicalDefinitions
            .map((definition) => definition.gateId)
            .toList(),
      );
    });

    test('serializes frozen uppercase result vocabulary', () {
      final result = policy.evaluate(_passingGates());
      final json = result.toJson();
      final gates = json['gates']! as List<Object?>;
      final firstGate = gates.first! as Map<String, Object?>;

      expect(json['decision'], 'ADMISSIBLE');
      expect(firstGate['status'], 'PASS');
      expect(firstGate['severity'], 'ERROR');
    });
  });
}

List<ReleaseAdmissionGate> _passingGates() {
  return ReleaseAdmissionPolicy.canonicalDefinitions.map((definition) {
    return ReleaseAdmissionGate(
      gateId: definition.gateId,
      name: definition.name,
      status: ReleaseAdmissionGateStatus.pass,
      severity: definition.severity,
      blocking: definition.blocking,
      evidence: <String>['evidence/${definition.gateId.toLowerCase()}.json'],
      message: 'Verified ${definition.name}.',
    );
  }).toList();
}
