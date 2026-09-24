import 'learning_twin_motion_state.dart';

final class LearningTwinMotionDescriptor {
  const LearningTwinMotionDescriptor({
    required this.state,
    required this.assetPath,
    required this.fallbackSvgPath,
    required this.loop,
    required this.duration,
    required this.priority,
    required this.motionIntensity,
  });

  final LearningTwinMotionState state;
  final String assetPath;
  final String fallbackSvgPath;
  final bool loop;
  final Duration duration;
  final int priority;
  final int motionIntensity;
}
