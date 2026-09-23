import 'dart:async';

import 'package:exam_platform/services/online_access/learner_online_access_gate.dart';
import 'package:exam_platform/services/online_access/learner_online_access_session_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('INT-R9A4 authorization chain regression', () {
    test('valid Firebase token and remote approval authorize bound learner', () async {
      final tokenProvider = _RecordingTokenProvider('firebase-token-a');
      final probe = _RecordingProbe(authorized: true);
      final gate = LearnerOnlineAccessGate(
        tokenProvider: tokenProvider,
        authorizationProbe: probe,
        clock: () => DateTime.utc(2026, 9, 23, 2),
      );
      final controller = LearnerOnlineAccessSessionController(
        validator: gate,
        currentUserId: () => 'user-a',
      );
      addTearDown(controller.dispose);

      final result = await controller.authorizeCurrentUser();

      expect(result.status, LearnerOnlineSessionStatus.authorized);
      expect(result.isAuthorizedFor('user-a'), isTrue);
      expect(controller.isAuthorizedFor('user-a'), isTrue);
      expect(controller.isAuthorizedFor('user-b'), isFalse);
      expect(tokenProvider.calls, 1);
      expect(tokenProvider.lastForceRefresh, isFalse);
      expect(probe.calls, 1);
      expect(probe.lastToken, 'firebase-token-a');
    });

    test('missing Firebase token locks without calling remote probe', () async {
      final tokenProvider = _RecordingTokenProvider(null);
      final probe = _RecordingProbe(authorized: true);
      final controller = LearnerOnlineAccessSessionController(
        validator: LearnerOnlineAccessGate(
          tokenProvider: tokenProvider,
          authorizationProbe: probe,
        ),
        currentUserId: () => 'user-a',
      );
      addTearDown(controller.dispose);

      final result = await controller.authorizeCurrentUser();

      expect(result.status, LearnerOnlineSessionStatus.locked);
      expect(
        result.lockReason,
        LearnerOnlineLockReason.noAuthenticatedUser,
      );
      expect(controller.isAuthorizedFor('user-a'), isFalse);
      expect(probe.calls, 0);
    });

    test('remote rejection locks the learner session', () async {
      final controller = LearnerOnlineAccessSessionController(
        validator: LearnerOnlineAccessGate(
          tokenProvider: _RecordingTokenProvider('firebase-token-a'),
          authorizationProbe: _RecordingProbe(authorized: false),
        ),
        currentUserId: () => 'user-a',
      );
      addTearDown(controller.dispose);

      final result = await controller.authorizeCurrentUser();

      expect(result.status, LearnerOnlineSessionStatus.locked);
      expect(result.lockReason, LearnerOnlineLockReason.rejected);
      expect(controller.isAuthorizedFor('user-a'), isFalse);
    });

    test('remote outage fails closed as backendUnavailable', () async {
      final controller = LearnerOnlineAccessSessionController(
        validator: LearnerOnlineAccessGate(
          tokenProvider: _RecordingTokenProvider('firebase-token-a'),
          authorizationProbe: _RecordingProbe(
            error: StateError('backend unavailable'),
          ),
        ),
        currentUserId: () => 'user-a',
      );
      addTearDown(controller.dispose);

      final result = await controller.authorizeCurrentUser();

      expect(result.status, LearnerOnlineSessionStatus.locked);
      expect(
        result.lockReason,
        LearnerOnlineLockReason.backendUnavailable,
      );
      expect(controller.isAuthorizedFor('user-a'), isFalse);
    });

    test('app resume locks first then reauthorizes with refreshed token', () async {
      final tokenProvider = _RecordingTokenProvider('firebase-token-a');
      final controller = LearnerOnlineAccessSessionController(
        validator: LearnerOnlineAccessGate(
          tokenProvider: tokenProvider,
          authorizationProbe: _RecordingProbe(authorized: true),
        ),
        currentUserId: () => 'user-a',
      );
      addTearDown(controller.dispose);

      await controller.authorizeCurrentUser();
      final snapshots = <LearnerOnlineAccessSessionSnapshot>[];
      final subscription = controller.changes.listen(snapshots.add);
      addTearDown(subscription.cancel);

      final result = await controller.revalidateOnResume();

      expect(result.status, LearnerOnlineSessionStatus.authorized);
      expect(tokenProvider.calls, 2);
      expect(tokenProvider.lastForceRefresh, isTrue);
      expect(
        snapshots.any(
          (snapshot) =>
              snapshot.status == LearnerOnlineSessionStatus.locked &&
              snapshot.lockReason == LearnerOnlineLockReason.appResumed,
        ),
        isTrue,
      );
    });

    test('confirmed network loss locks and restoration forces reauthorization', () async {
      final tokenProvider = _RecordingTokenProvider('firebase-token-a');
      final controller = LearnerOnlineAccessSessionController(
        validator: LearnerOnlineAccessGate(
          tokenProvider: tokenProvider,
          authorizationProbe: _RecordingProbe(authorized: true),
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

      final restored = await controller.handleConnectivityRestored();

      expect(restored.status, LearnerOnlineSessionStatus.authorized);
      expect(controller.isAuthorizedFor('user-a'), isTrue);
      expect(tokenProvider.lastForceRefresh, isTrue);
    });

    test('user switch during in-flight authorization cannot authorize old user', () async {
      var currentUserId = 'user-a';
      final probe = _ControlledProbe();
      final controller = LearnerOnlineAccessSessionController(
        validator: LearnerOnlineAccessGate(
          tokenProvider: _RecordingTokenProvider('firebase-token-a'),
          authorizationProbe: probe,
        ),
        currentUserId: () => currentUserId,
      );
      addTearDown(controller.dispose);

      final pending = controller.authorizeCurrentUser();
      await Future<void>.delayed(Duration.zero);
      expect(
        controller.snapshot.status,
        LearnerOnlineSessionStatus.validating,
      );

      currentUserId = 'user-b';
      probe.complete(true);

      final result = await pending;

      expect(result.status, LearnerOnlineSessionStatus.locked);
      expect(result.lockReason, LearnerOnlineLockReason.userChanged);
      expect(controller.isAuthorizedFor('user-a'), isFalse);
      expect(controller.isAuthorizedFor('user-b'), isFalse);
    });
  });
}

class _RecordingTokenProvider implements LearnerAccessTokenProvider {
  _RecordingTokenProvider(this.token);

  final String? token;
  int calls = 0;
  bool? lastForceRefresh;

  @override
  Future<String?> currentToken({bool forceRefresh = false}) async {
    calls++;
    lastForceRefresh = forceRefresh;
    return token;
  }
}

class _RecordingProbe implements LearnerRemoteAuthorizationProbe {
  _RecordingProbe({this.authorized, this.error});

  final bool? authorized;
  final Object? error;
  int calls = 0;
  String? lastToken;

  @override
  Future<bool> authorize({required String accessToken}) async {
    calls++;
    lastToken = accessToken;
    if (error != null) {
      throw error!;
    }
    return authorized ?? false;
  }
}

class _ControlledProbe implements LearnerRemoteAuthorizationProbe {
  final Completer<bool> _completer = Completer<bool>();

  @override
  Future<bool> authorize({required String accessToken}) => _completer.future;

  void complete(bool value) {
    if (!_completer.isCompleted) {
      _completer.complete(value);
    }
  }
}
