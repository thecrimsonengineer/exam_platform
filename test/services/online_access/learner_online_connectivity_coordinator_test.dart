import 'dart:async';

import 'package:exam_platform/services/online_access/learner_connectivity_signal_source.dart';
import 'package:exam_platform/services/online_access/learner_online_access_gate.dart';
import 'package:exam_platform/services/online_access/learner_online_access_session_controller.dart';
import 'package:exam_platform/services/online_access/learner_online_connectivity_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FR8D transport-online signal never authorizes by itself', () async {
    final validator = _SequenceValidator([
      LearnerOnlineAccessStatus.authorized,
    ]);
    final controller = LearnerOnlineAccessSessionController(
      validator: validator,
      currentUserId: () => 'student-1',
    );
    final source = _FakeConnectivitySource(initial: true);
    final coordinator = LearnerOnlineConnectivityCoordinator(
      controller: controller,
      signalSource: source,
    );
    addTearDown(coordinator.dispose);
    addTearDown(controller.dispose);
    addTearDown(source.dispose);

    expect(await coordinator.start(), isTrue);

    expect(controller.snapshot.status, LearnerOnlineSessionStatus.locked);
    expect(validator.calls, 0);
  });

  test('FR8D offline launch locks without attempting authorization', () async {
    final validator = _SequenceValidator([
      LearnerOnlineAccessStatus.authorized,
    ]);
    final controller = LearnerOnlineAccessSessionController(
      validator: validator,
      currentUserId: () => 'student-1',
    );
    final source = _FakeConnectivitySource(initial: false);
    final coordinator = LearnerOnlineConnectivityCoordinator(
      controller: controller,
      signalSource: source,
    );
    addTearDown(coordinator.dispose);
    addTearDown(controller.dispose);
    addTearDown(source.dispose);

    expect(await coordinator.start(), isFalse);

    expect(controller.snapshot.status, LearnerOnlineSessionStatus.locked);
    expect(
      controller.snapshot.lockReason,
      LearnerOnlineLockReason.connectivityLost,
    );
    expect(validator.calls, 0);
  });

  test(
    'FR8D confirmed loss after grace fails closed through remote revalidation',
    () async {
      final delay = _ControlledDelay();
      final validator = _SequenceValidator([
        LearnerOnlineAccessStatus.authorized,
        LearnerOnlineAccessStatus.backendUnavailable,
      ]);
      final controller = LearnerOnlineAccessSessionController(
        validator: validator,
        currentUserId: () => 'student-1',
        delay: delay.call,
      );
      final source = _FakeConnectivitySource(initial: true);
      final coordinator = LearnerOnlineConnectivityCoordinator(
        controller: controller,
        signalSource: source,
      );
      addTearDown(coordinator.dispose);
      addTearDown(controller.dispose);
      addTearDown(source.dispose);

      await controller.authorizeCurrentUser();
      await coordinator.start();
      expect(controller.isAuthorizedFor('student-1'), isTrue);

      source.emit(false);
      await Future<void>.delayed(Duration.zero);

      expect(controller.isAuthorizedFor('student-1'), isTrue);
      expect(delay.calls, 1);

      delay.complete();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.snapshot.status, LearnerOnlineSessionStatus.locked);
      expect(
        controller.snapshot.lockReason,
        LearnerOnlineLockReason.backendUnavailable,
      );
      expect(validator.calls, 2);
      expect(validator.lastForceRefresh, isTrue);
    },
  );

  test(
    'FR8D recovery cancels stale loss grace and reauthorizes remotely',
    () async {
      final delay = _ControlledDelay();
      final validator = _SequenceValidator([
        LearnerOnlineAccessStatus.authorized,
        LearnerOnlineAccessStatus.authorized,
      ]);
      final controller = LearnerOnlineAccessSessionController(
        validator: validator,
        currentUserId: () => 'student-1',
        delay: delay.call,
      );
      final source = _FakeConnectivitySource(initial: true);
      final coordinator = LearnerOnlineConnectivityCoordinator(
        controller: controller,
        signalSource: source,
      );
      addTearDown(coordinator.dispose);
      addTearDown(controller.dispose);
      addTearDown(source.dispose);

      await controller.authorizeCurrentUser();
      await coordinator.start();

      source.emit(false);
      await Future<void>.delayed(Duration.zero);
      expect(delay.calls, 1);

      source.emit(true);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.isAuthorizedFor('student-1'), isTrue);
      expect(validator.calls, 2);
      expect(validator.lastForceRefresh, isTrue);

      delay.complete();
      await Future<void>.delayed(Duration.zero);

      expect(controller.isAuthorizedFor('student-1'), isTrue);
      expect(validator.calls, 2);
    },
  );

  test('FR8D connectivity monitor failure locks protected access', () async {
    final validator = _SequenceValidator([
      LearnerOnlineAccessStatus.authorized,
    ]);
    final controller = LearnerOnlineAccessSessionController(
      validator: validator,
      currentUserId: () => 'student-1',
    );
    final source = _FakeConnectivitySource(initial: true);
    final coordinator = LearnerOnlineConnectivityCoordinator(
      controller: controller,
      signalSource: source,
    );
    addTearDown(coordinator.dispose);
    addTearDown(controller.dispose);
    addTearDown(source.dispose);

    await controller.authorizeCurrentUser();
    await coordinator.start();

    source.fail();
    await Future<void>.delayed(Duration.zero);

    expect(controller.snapshot.status, LearnerOnlineSessionStatus.locked);
    expect(
      controller.snapshot.lockReason,
      LearnerOnlineLockReason.connectivityLost,
    );
  });
}

class _FakeConnectivitySource implements LearnerConnectivitySignalSource {
  _FakeConnectivitySource({required this.initial});

  final bool initial;
  final StreamController<bool> _changes = StreamController<bool>.broadcast(
    sync: true,
  );

  @override
  Future<bool> hasConnectivity() async => initial;

  @override
  Stream<bool> get changes => _changes.stream;

  void emit(bool value) {
    _changes.add(value);
  }

  void fail() {
    _changes.addError(StateError('monitor unavailable'));
  }

  Future<void> dispose() => _changes.close();
}

class _ControlledDelay {
  final Completer<void> _completer = Completer<void>();
  int calls = 0;

  Future<void> call(Duration duration) {
    calls++;
    return _completer.future;
  }

  void complete() {
    if (!_completer.isCompleted) {
      _completer.complete();
    }
  }
}

class _SequenceValidator implements LearnerOnlineAccessValidator {
  _SequenceValidator(this.statuses);

  final List<LearnerOnlineAccessStatus> statuses;
  int calls = 0;
  bool? lastForceRefresh;

  @override
  Future<LearnerOnlineAccessResult> validate({
    bool forceRefreshToken = false,
  }) async {
    lastForceRefresh = forceRefreshToken;
    final index = calls < statuses.length ? calls : statuses.length - 1;
    calls++;

    return LearnerOnlineAccessResult(
      status: statuses[index],
      checkedAt: DateTime.utc(2026, 9, 22),
    );
  }
}
