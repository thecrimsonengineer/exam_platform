import 'm1_mechanical_authority_test.dart' as authority_boundaries;
import 'm1_check_act_test.dart' as check_boundaries;
import 'm1_path_guard_test.dart' as path_boundaries;
import 'package:flutter_test/flutter_test.dart';

import '../../tool/agentic_pdca/m0_control_plane.dart';
import '../../tool/agentic_pdca/m0_models.dart';
import '../../tool/agentic_pdca/m1_check_act.dart';
import '../../tool/agentic_pdca/m1_mechanical_authority.dart';

void main() {
  authority_boundaries.main();
  check_boundaries.main();
  path_boundaries.main();
  test('M1 architecture boundaries remain mechanical and non-closure', () {
    final plane = M0ObservationControlPlane(
      governanceVersion: 'v1.0',
      governanceSha: '43b2b3cc99839ae9de4092b4e2b7058d1964bff7',
      trustedIssuers: const {'github-actions'},
    );
    expect(
      ControlPlaneCapability.values.every((value) => !plane.permits(value)),
      isTrue,
    );
    for (final failure in M1FailureClass.values) {
      final route = const M1ActRouter().route(
        M1ActEvidence(
          failureClass: failure,
          candidateSha: '94d060e37358915d03a2375ebc3af54808633e15',
          evidence: 'boundary',
        ),
      );
      expect(
        route,
        isIn([
          M1ActRoute.format,
          M1ActRoute.importFix,
          M1ActRoute.simpleAnalyzerFix,
          M1ActRoute.safeTestHarnessFix,
          M1ActRoute.retry,
          M1ActRoute.escalate,
        ]),
      );
    }
    expect(M1ActRoute.values, hasLength(6));
    for (final operation in M1StructuredOperation.values.where(
      (op) => op != M1StructuredOperation.format,
    )) {
      expect(
        () => const M1MechanicalExecutor().commandFor(operation, [
          'tool/agentic_pdca/a.dart',
        ]),
        throwsUnsupportedError,
      );
    }
    for (final path in ['../lib/main.dart', '/tmp/x', r'tool\agentic_pdca\x']) {
      expect(
        () => const M1MechanicalExecutor().commandFor(
          M1StructuredOperation.format,
          [path],
        ),
        throwsArgumentError,
      );
    }
  });
}
