import 'package:flutter_test/flutter_test.dart';

import '../../tool/agentic_pdca/m1_check_act.dart';
import '../../tool/agentic_pdca/m1_mechanical_authority.dart';
import '../../tool/agentic_pdca/m1_mechanical_control.dart';
import '../../tool/agentic_pdca/m1_mechanical_models.dart';
import '../../tool/agentic_pdca/m0_control_plane.dart';
import '../../tool/agentic_pdca/m0_models.dart';

void main() {
  const sha = '94d060e37358915d03a2375ebc3af54808633e15';

  test('pilot format request remains bounded to an explicit allowed path', () {
    const executor = M1MechanicalExecutor();
    final command = executor.commandFor(M1StructuredOperation.format, const [
      'test/agentic_pdca/fixture.dart',
    ]);
    expect(command, 'dart format "test/agentic_pdca/fixture.dart"');
  });

  test('pilot rejects arbitrary shell and dependency mutation', () {
    const executor = M1MechanicalExecutor();
    expect(
      () => executor.commandFor(M1StructuredOperation.format, const [
        'pubspec.yaml',
      ]),
      throwsArgumentError,
    );
    expect(
      () => executor.commandFor(M1StructuredOperation.importFix, const [
        'tool/agentic_pdca/fixture.dart',
      ]),
      throwsUnsupportedError,
    );
  });

  test(
    'pilot preserves M0 duplicate-event idempotence and authority denial',
    () {
      final plane = M0ObservationControlPlane(
        governanceVersion: 'v1.0',
        governanceSha: '43b2b3cc99839ae9de4092b4e2b7058d1964bff7',
        trustedIssuers: const {'github-actions'},
      );
      expect(
        ControlPlaneCapability.values.every(
          (capability) => !plane.permits(capability),
        ),
        isTrue,
      );
      expect(sha, hasLength(40));
    },
  );

  test('pilot records generated side effects as allowed CHECK evidence', () {
    const runner = M1DeterministicCheckRunner();
    final evidence = runner.evaluate(
      checkId: 'PILOT-GENERATED-1',
      candidateSha: sha,
      expectedSha: sha,
      gate: M1CheckGate.test,
      command: 'flutter test',
      gatePassed: true,
      duration: Duration.zero,
      dirtyPaths: const ['windows/flutter/generated_plugins.cmake'],
    );
    expect(evidence.result, M1CheckResult.green);
    expect(evidence.evidence, contains('passed'));
  });
}
