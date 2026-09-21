import 'package:flutter_test/flutter_test.dart';

import '../../tool/agentic_pdca/m0_control_plane.dart';
import '../../tool/agentic_pdca/m0_models.dart';
import '../../tool/agentic_pdca/m1_mechanical_control.dart';
import '../../tool/agentic_pdca/m1_mechanical_models.dart';

void main() {
  const baseSha = '94d060e37358915d03a2375ebc3af54808633e15';
  const allowedPaths = <String>[
    'tool/agentic_pdca/**',
    'test/agentic_pdca/**',
    'docs/agentic/implementation/**',
  ];
  final classifier = M1MechanicalEligibilityClassifier();

  M1MechanicalRequest request({
    String actionClass = 'formatting',
    String sha = baseSha,
    List<String> requestedPaths = const ['tool/agentic_pdca/m1_models.dart'],
    List<String> expectedChangedPaths = const [
      'tool/agentic_pdca/m1_models.dart',
    ],
    List<String> allowed = allowedPaths,
  }) => M1MechanicalRequest(
    taskId: 'TASK-M1-001',
    lineageId: 'LINEAGE-M1-001',
    baseSha: sha,
    allowedPaths: allowed,
    requestedPaths: requestedPaths,
    actionClass: actionClass,
    plannedCommand: 'dart format tool/agentic_pdca',
    expectedChangedPaths: expectedChangedPaths,
    requiredGates: const [
      'dart format --output=none --set-exit-if-changed',
      'flutter test test/agentic_pdca/',
      'flutter analyze',
    ],
  );

  group('M1 DO-1 eligibility', () {
    test('accepts all four mechanical action classes', () {
      for (final actionClass in <String>[
        'formatting',
        'imports',
        'simple_analyzer_fixes',
        'safe_test_harness_corrections',
      ]) {
        final result = classifier.classify(request(actionClass: actionClass));
        expect(result.disposition, M1EligibilityDisposition.accepted);
        expect(result.plan, isNotNull);
      }
    });

    test(
      'records the complete mechanical action plan without executing it',
      () {
        final result = classifier.classify(request());
        final plan = result.plan!;

        expect(plan.taskId, 'TASK-M1-001');
        expect(plan.lineageId, 'LINEAGE-M1-001');
        expect(plan.exactBaseSha, baseSha);
        expect(plan.allowedPaths, allowedPaths);
        expect(plan.actionClass, M1MechanicalActionClass.formatting);
        expect(plan.plannedCommand, 'dart format tool/agentic_pdca');
        expect(plan.expectedChangedPaths, ['tool/agentic_pdca/m1_models.dart']);
        expect(plan.requiredGates, hasLength(3));
        expect(plan.toJson()['execution_planned_only'], isTrue);
      },
    );
  });

  group('M1 fail-closed scope controls', () {
    test(
      'escalates feature behavior and architecture/security/backend work',
      () {
        for (final actionClass in <String>[
          'feature_behavior',
          'architecture',
          'security',
          'backend',
        ]) {
          final result = classifier.classify(request(actionClass: actionClass));
          expect(result.disposition, M1EligibilityDisposition.escalated);
          expect(result.plan, isNull);
        }
      },
    );

    test('rejects forbidden paths even for a mechanical class', () {
      final result = classifier.classify(
        request(
          requestedPaths: const ['lib/main.dart'],
          expectedChangedPaths: const ['lib/main.dart'],
        ),
      );

      expect(result.disposition, M1EligibilityDisposition.rejected);
      expect(result.reason, contains('lib/main.dart'));
    });

    test('rejects test weakening explicitly', () {
      final result = classifier.classify(
        request(actionClass: 'test_weakening'),
      );

      expect(result.disposition, M1EligibilityDisposition.rejected);
      expect(result.plan, isNull);
    });

    test('rejects unknown actions instead of guessing', () {
      final result = classifier.classify(
        request(actionClass: 'remove_failing_test'),
      );

      expect(result.disposition, M1EligibilityDisposition.rejected);
      expect(result.actionClass, M1MechanicalActionClass.unknown);
    });

    test('requires an exact base SHA', () {
      final result = classifier.classify(request(sha: 'HEAD'));

      expect(result.disposition, M1EligibilityDisposition.rejected);
      expect(result.reason, contains('exact 40-character base SHA'));
    });

    test('rejects paths outside the declared allow-list', () {
      final result = classifier.classify(
        request(
          allowed: const ['tool/agentic_pdca/**'],
          requestedPaths: const ['test/agentic_pdca/m1_test.dart'],
          expectedChangedPaths: const ['test/agentic_pdca/m1_test.dart'],
        ),
      );

      expect(result.disposition, M1EligibilityDisposition.rejected);
    });
  });

  test('M0 protected capabilities remain unavailable', () {
    final controlPlane = M0ObservationControlPlane(
      governanceVersion: 'v1.0',
      governanceSha: '43b2b3cc99839ae9de4092b4e2b7058d1964bff7',
      trustedIssuers: const {'github-actions'},
    );

    for (final capability in ControlPlaneCapability.values) {
      expect(controlPlane.permits(capability), isFalse);
    }
  });
}
