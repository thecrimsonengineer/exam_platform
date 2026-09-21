import 'package:flutter_test/flutter_test.dart';

import '../../tool/agentic_pdca/m0_control_plane.dart';
import '../../tool/agentic_pdca/m0_models.dart';
import '../../tool/agentic_pdca/m1_check_act.dart';
import '../../tool/agentic_pdca/m1_mechanical_authority.dart';

void main() {
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
    expect(M1ActRoute.values, contains(M1ActRoute.escalate));
    expect(M1MechanicalClass.values, contains(M1MechanicalClass.testWeakening));
  });
}
