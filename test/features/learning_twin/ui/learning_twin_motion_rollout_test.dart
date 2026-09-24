import 'package:exam_platform/features/learning_twin/ui/learning_twin_motion_rollout.dart';
import 'package:exam_platform/features/learning_twin/ui/learning_twin_motion_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Hero pilot is requested but gated by canonical idle asset admission', () {
    expect(LearningTwinMotionRollout.heroPilotRequested, isTrue);
    expect(LearningTwinMotionRollout.canonicalIdleClipAdmitted, isFalse);
    expect(LearningTwinMotionRollout.heroMotionEnabled, isFalse);
    expect(
      LearningTwinMotionRollout.blockedReasonFor(
        LearningTwinMotionSurface.hero,
      ),
      'canonical_idle_clip_not_admitted',
    );
  });

  test('only idle is permitted for the LTAM-5 Hero pilot', () {
    for (final state in canonicalLearningTwinMotionStates) {
      expect(
        LearningTwinMotionRollout.stateAllowedFor(
          LearningTwinMotionSurface.hero,
          state,
        ),
        state == LearningTwinMotionState.idle,
        reason: 'Unexpected Hero pilot state permission for ${state.name}.',
      );
    }
  });

  test('all non-Hero surfaces remain motion-disabled', () {
    for (final surface in LearningTwinMotionSurface.values) {
      if (surface == LearningTwinMotionSurface.hero) {
        continue;
      }

      expect(LearningTwinMotionRollout.enabledFor(surface), isFalse);
      expect(
        LearningTwinMotionRollout.blockedReasonFor(surface),
        'surface_rollout_disabled',
      );
    }
  });
}
