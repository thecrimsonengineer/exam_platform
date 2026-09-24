import 'dart:io';

import 'package:exam_platform/features/learning_twin/ui/learning_twin_motion_rollout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('canonical idle clip presence matches the LTAM-5 admission switch', () {
    final idleClip = File('assets/learning_twin/motion/twin_idle.json');

    expect(
      idleClip.existsSync(),
      LearningTwinMotionRollout.canonicalIdleClipAdmitted,
      reason:
          'The canonical idle clip must not silently enter or leave production. '
          'Asset presence and the reviewed LTAM-5 admission switch must change '
          'together after visual/device acceptance.',
    );
  });
}
