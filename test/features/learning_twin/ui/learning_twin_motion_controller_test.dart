import 'package:exam_platform/features/learning_twin/ui/learning_twin_motion_controller.dart';
import 'package:exam_platform/features/learning_twin/ui/learning_twin_motion_descriptor.dart';
import 'package:exam_platform/features/learning_twin/ui/learning_twin_motion_state.dart';
import 'package:flutter_test/flutter_test.dart';

LearningTwinMotionDescriptor descriptor(
  LearningTwinMotionState state, {
  bool? loop,
}) {
  return LearningTwinMotionDescriptor(
    state: state,
    assetPath: 'assets/learning_twin/motion/twin_${state.manifestKey}.json',
    fallbackSvgPath: 'assets/learning_twin/naveed_twin.svg',
    loop: loop ?? state.isLooping,
    duration: const Duration(seconds: 1),
    priority: state.defaultPriority,
    motionIntensity: 1,
  );
}

void main() {
  test('idle starts as a loop', () {
    final controller = LearningTwinMotionController();
    addTearDown(controller.dispose);

    expect(
      controller.request(descriptor(LearningTwinMotionState.idle)),
      isTrue,
    );
    expect(controller.currentState, LearningTwinMotionState.idle);
    expect(controller.isPlaying, isTrue);
    expect(controller.isLooping, isTrue);
  });

  test('one-shot completes and returns to idle', () {
    final controller = LearningTwinMotionController();
    addTearDown(controller.dispose);
    final idle = descriptor(LearningTwinMotionState.idle);

    controller.request(
      descriptor(LearningTwinMotionState.celebrate),
      eventKey: 'milestone:1',
    );
    controller.completeCurrent(idleDescriptor: idle);

    expect(controller.currentState, LearningTwinMotionState.idle);
    expect(controller.isLooping, isTrue);
    expect(controller.lastCompletedState, LearningTwinMotionState.celebrate);
    expect(controller.lastCompletedEventKey, 'milestone:1');
  });

  test('thinking is interruptible by a higher-priority meaningful state', () {
    final controller = LearningTwinMotionController();
    addTearDown(controller.dispose);

    controller.request(descriptor(LearningTwinMotionState.thinking));
    final started = controller.request(
      descriptor(LearningTwinMotionState.explain),
      eventKey: 'message:1',
    );

    expect(started, isTrue);
    expect(controller.currentState, LearningTwinMotionState.explain);
  });

  test('lower-priority state becomes the single pending state', () {
    final controller = LearningTwinMotionController();
    addTearDown(controller.dispose);

    controller.request(
      descriptor(LearningTwinMotionState.checkpoint),
      eventKey: 'checkpoint:1',
    );
    controller.request(
      descriptor(LearningTwinMotionState.explain),
      eventKey: 'explain:1',
    );
    controller.request(
      descriptor(LearningTwinMotionState.insightReady),
      eventKey: 'insight:1',
    );

    expect(controller.currentState, LearningTwinMotionState.checkpoint);
    expect(controller.pendingState, LearningTwinMotionState.insightReady);
    expect(controller.pendingEventKey, 'insight:1');
  });

  test('completed event key cannot replay without an override', () {
    final controller = LearningTwinMotionController();
    addTearDown(controller.dispose);
    final celebrate = descriptor(LearningTwinMotionState.celebrate);

    controller.request(celebrate, eventKey: 'milestone:1');
    controller.completeCurrent();

    expect(controller.request(celebrate, eventKey: 'milestone:1'), isFalse);
    expect(controller.request(celebrate, eventKey: 'milestone:2'), isTrue);
  });

  test('app inactive pauses and resume restarts current playback', () {
    final controller = LearningTwinMotionController();
    addTearDown(controller.dispose);

    controller.request(descriptor(LearningTwinMotionState.thinking));
    controller.setAppActive(false);
    expect(controller.isPlaying, isFalse);

    controller.setAppActive(true);
    expect(controller.isPlaying, isTrue);
  });

  test('disposed controller ignores new requests', () {
    final controller = LearningTwinMotionController();
    controller.dispose();

    expect(controller.isDisposed, isTrue);
    expect(
      controller.request(descriptor(LearningTwinMotionState.idle)),
      isFalse,
    );
  });
}
