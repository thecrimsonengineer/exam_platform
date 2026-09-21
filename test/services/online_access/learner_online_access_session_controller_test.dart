import 'dart:async';

import 'package:exam_platform/services/online_access/learner_online_access_gate.dart';
import 'package:exam_platform/services/online_access/learner_online_access_session_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final checkedAt = DateTime.utc(2026, 9, 21, 15);
  final changedAt = DateTime.utc(2026, 9, 21, 16);

  test('FR8 authorizes only the currently active Firebase UID', () async {
    var currentUserId = 'user-a';
    final validator = _FakeValidator(
      result: LearnerOnlineAccessResult(
        status: LearnerOnlineAccessStatus.authorized,
        checkedAt: checkedAt,
      ),
    );
    final controller = LearnerOnlineAccessSessionController(
      validator: validator,
      currentUserId: () => currentUserId,
      clock: () => changedAt,
    );
    addTearDown(controller.dispose);

    final result = await controller.authorizeForUser('user-a');

    expect(result.status, LearnerOnlineSessionStatus.authorized);
    expect(result.userId, 'user-a');
    expect(result.authorizationCheckedAt, checkedAt);
    expect(controller.isAuthorizedFor('user-a'), isTrue);
    expect(controller.isAuthorizedFor('user-b'), isFalse);

    currentUserId = 'user-b';
    controller.handleAuthUserChanged(currentUserId);

    expect(controller.snapshot.status, LearnerOnlineSessionStatus.locked);
    expect(controller.snapshot.lockReason, LearnerOnlineLockReason.userChanged);
    expect(controller.isAuthorizedFor('user-a'), isFalse);
  });

  test('FR8 refuses authorization when requested UID is not active', () async {
    final validator = _FakeValidator(
      result: LearnerOnlineAccessResult(
        status: LearnerOnlineAccessStatus.authorized,
        checkedAt: checkedAt,
      ),
    );
    final controller = LearnerOnlineAccessSessionController(
      validator: validator,
      currentUserId: () => 'user-b',
    );
    addTearDown(controller.dispose);

    final result = await controller.authorizeForUser('user-a');

    expect(result.status, LearnerOnlineSessionStatus.locked);
    expect(result.lockReason, LearnerOnlineLockReason.userChanged);
    expect(validator.calls, 0);
  });

  test('FR8 maps backend authorization failure to a locked session', () async {
    final controller = LearnerOnlineAccessSessionController(
      validator: _FakeValidator(
        result: LearnerOnlineAccessResult(
          status: LearnerOnlineAccessStatus.backendUnavailable,
          checkedAt: checkedAt,
        ),
      ),
      currentUserId: () => 'user-a',
    );
    addTearDown(controller.dispose);

    final result = await controller.authorizeCurrentUser();

    expect(result.status, LearnerOnlineSessionStatus.locked);
    expect(result.lockReason, LearnerOnlineLockReason.backendUnavailable);
  });

  test('FR8 resume locks first and then forces reauthorization', () async {
    final validator = _FakeValidator(
      result: LearnerOnlineAccessResult(
        status: LearnerOnlineAccessStatus.authorized,
        checkedAt: checkedAt,
      ),
    );
    final controller = LearnerOnlineAccessSessionController(
      validator: validator,
      currentUserId: () => 'user-a',
    );
    addTearDown(controller.dispose);

    await controller.authorizeCurrentUser();
    final observed = <LearnerOnlineAccessSessionSnapshot>[];
    final subscription = controller.changes.listen(observed.add);
    addTearDown(subscription.cancel);

    final result = await controller.revalidateOnResume();

    expect(result.status, LearnerOnlineSessionStatus.authorized);
    expect(validator.lastForceRefresh, isTrue);
    expect(
      observed.any(
        (item) =>
            item.status == LearnerOnlineSessionStatus.locked &&
            item.lockReason == LearnerOnlineLockReason.appResumed,
      ),
      isTrue,
    );
  });

  test(
    'FR8 confirmed network loss locks protected cache access immediately',
    () async {
      final controller = LearnerOnlineAccessSessionController(
        validator: _FakeValidator(
          result: LearnerOnlineAccessResult(
            status: LearnerOnlineAccessStatus.authorized,
            checkedAt: checkedAt,
          ),
        ),
        currentUserId: () => 'user-a',
      );
      addTearDown(controller.dispose);

      await controller.authorizeCurrentUser();
      expect(controller.isAuthorizedFor('user-a'), isTrue);

      controller.handleConfirmedNetworkLoss();

      expect(controller.isAuthorizedFor('user-a'), isFalse);
      expect(
        controller.snapshot.lockReason,
        LearnerOnlineLockReason.connectivityLost,
      );
    },
  );

  test(
    'FR8 transient handover keeps access during grace then revalidates',
    () async {
      final delayCompleter = Completer<void>();
      final validator = _FakeValidator(
        result: LearnerOnlineAccessResult(
          status: LearnerOnlineAccessStatus.authorized,
          checkedAt: checkedAt,
        ),
      );
      final controller = LearnerOnlineAccessSessionController(
        validator: validator,
        currentUserId: () => 'user-a',
        delay: (_) => delayCompleter.future,
      );
      addTearDown(controller.dispose);

      await controller.authorizeCurrentUser();
      final handover = controller.handleTransientConnectivityLoss();

      expect(controller.isAuthorizedFor('user-a'), isTrue);

      delayCompleter.complete();
      final result = await handover;

      expect(result.status, LearnerOnlineSessionStatus.authorized);
      expect(validator.calls, 2);
      expect(validator.lastForceRefresh, isTrue);
    },
  );

  test(
    'FR8 stale in-flight validation cannot reopen a manually locked session',
    () async {
      final validator = _ControlledValidator();
      final controller = LearnerOnlineAccessSessionController(
        validator: validator,
        currentUserId: () => 'user-a',
      );
      addTearDown(controller.dispose);

      final pending = controller.authorizeCurrentUser();
      expect(controller.snapshot.status, LearnerOnlineSessionStatus.validating);

      controller.lock();
      validator.complete(
        LearnerOnlineAccessResult(
          status: LearnerOnlineAccessStatus.authorized,
          checkedAt: checkedAt,
        ),
      );

      final result = await pending;

      expect(result.status, LearnerOnlineSessionStatus.locked);
      expect(result.lockReason, LearnerOnlineLockReason.manual);
      expect(controller.isAuthorizedFor('user-a'), isFalse);
    },
  );
}

class _FakeValidator implements LearnerOnlineAccessValidator {
  _FakeValidator({required this.result});

  final LearnerOnlineAccessResult result;
  int calls = 0;
  bool? lastForceRefresh;

  @override
  Future<LearnerOnlineAccessResult> validate({
    bool forceRefreshToken = false,
  }) async {
    calls++;
    lastForceRefresh = forceRefreshToken;
    return result;
  }
}

class _ControlledValidator implements LearnerOnlineAccessValidator {
  final Completer<LearnerOnlineAccessResult> _completer =
      Completer<LearnerOnlineAccessResult>();

  @override
  Future<LearnerOnlineAccessResult> validate({bool forceRefreshToken = false}) {
    return _completer.future;
  }

  void complete(LearnerOnlineAccessResult result) {
    _completer.complete(result);
  }
}
