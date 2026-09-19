import 'package:exam_platform/services/online_access/learner_online_access_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final checkedAt = DateTime.utc(2026, 9, 19, 12);

  test(
    'FR2 authorizes only after token and remote authorization succeed',
    () async {
      final tokenProvider = _FakeTokenProvider(token: 'firebase-token');
      final probe = _FakeProbe(authorized: true);
      final gate = LearnerOnlineAccessGate(
        tokenProvider: tokenProvider,
        authorizationProbe: probe,
        clock: () => checkedAt,
      );

      final result = await gate.validate();

      expect(result.status, LearnerOnlineAccessStatus.authorized);
      expect(result.isAuthorized, isTrue);
      expect(result.checkedAt, checkedAt);
      expect(probe.calls, 1);
      expect(probe.lastToken, 'firebase-token');
    },
  );

  test(
    'FR2 does not call backend when there is no Firebase user token',
    () async {
      final probe = _FakeProbe(authorized: true);
      final gate = LearnerOnlineAccessGate(
        tokenProvider: _FakeTokenProvider(token: null),
        authorizationProbe: probe,
      );

      final result = await gate.validate();

      expect(result.status, LearnerOnlineAccessStatus.noAuthenticatedUser);
      expect(result.isAuthorized, isFalse);
      expect(probe.calls, 0);
    },
  );

  test('FR2 blocks protected access when backend rejects the token', () async {
    final gate = LearnerOnlineAccessGate(
      tokenProvider: _FakeTokenProvider(token: 'firebase-token'),
      authorizationProbe: _FakeProbe(authorized: false),
    );

    final result = await gate.validate();

    expect(result.status, LearnerOnlineAccessStatus.rejected);
    expect(result.isAuthorized, isFalse);
  });

  test('FR2 fails closed when backend authorization is unavailable', () async {
    final gate = LearnerOnlineAccessGate(
      tokenProvider: _FakeTokenProvider(token: 'firebase-token'),
      authorizationProbe: _FakeProbe(error: StateError('offline')),
    );

    final result = await gate.validate();

    expect(result.status, LearnerOnlineAccessStatus.backendUnavailable);
    expect(result.isAuthorized, isFalse);
  });

  test('FR2 fails closed when Firebase token retrieval throws', () async {
    final probe = _FakeProbe(authorized: true);
    final gate = LearnerOnlineAccessGate(
      tokenProvider: _FakeTokenProvider(error: StateError('token failure')),
      authorizationProbe: probe,
    );

    final result = await gate.validate();

    expect(result.status, LearnerOnlineAccessStatus.backendUnavailable);
    expect(probe.calls, 0);
  });

  test('FR2 forwards forced token refresh requests', () async {
    final tokenProvider = _FakeTokenProvider(token: 'firebase-token');
    final gate = LearnerOnlineAccessGate(
      tokenProvider: tokenProvider,
      authorizationProbe: _FakeProbe(authorized: true),
    );

    await gate.validate(forceRefreshToken: true);

    expect(tokenProvider.lastForceRefresh, isTrue);
  });
}

class _FakeTokenProvider implements LearnerAccessTokenProvider {
  _FakeTokenProvider({this.token, this.error});

  final String? token;
  final Object? error;
  bool? lastForceRefresh;

  @override
  Future<String?> currentToken({bool forceRefresh = false}) async {
    lastForceRefresh = forceRefresh;
    if (error != null) {
      throw error!;
    }
    return token;
  }
}

class _FakeProbe implements LearnerRemoteAuthorizationProbe {
  _FakeProbe({this.authorized = false, this.error});

  final bool authorized;
  final Object? error;
  int calls = 0;
  String? lastToken;

  @override
  Future<bool> authorize({required String accessToken}) async {
    calls += 1;
    lastToken = accessToken;
    if (error != null) {
      throw error!;
    }
    return authorized;
  }
}
