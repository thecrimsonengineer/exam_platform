enum LearnerOnlineAccessStatus {
  authorized,
  noAuthenticatedUser,
  backendUnavailable,
  rejected,
}

class LearnerOnlineAccessResult {
  const LearnerOnlineAccessResult({
    required this.status,
    required this.checkedAt,
  });

  final LearnerOnlineAccessStatus status;
  final DateTime checkedAt;

  bool get isAuthorized => status == LearnerOnlineAccessStatus.authorized;
}

abstract interface class LearnerOnlineAccessValidator {
  Future<LearnerOnlineAccessResult> validate({bool forceRefreshToken = false});
}

abstract interface class LearnerAccessTokenProvider {
  Future<String?> currentToken({bool forceRefresh = false});
}

abstract interface class LearnerRemoteAuthorizationProbe {
  Future<bool> authorize({required String accessToken});
}

class LearnerOnlineAccessGate implements LearnerOnlineAccessValidator {
  LearnerOnlineAccessGate({
    required LearnerAccessTokenProvider tokenProvider,
    required LearnerRemoteAuthorizationProbe authorizationProbe,
    DateTime Function()? clock,
  }) : _tokenProvider = tokenProvider,
       _authorizationProbe = authorizationProbe,
       _clock = clock ?? DateTime.now;

  final LearnerAccessTokenProvider _tokenProvider;
  final LearnerRemoteAuthorizationProbe _authorizationProbe;
  final DateTime Function() _clock;

  @override
  Future<LearnerOnlineAccessResult> validate({
    bool forceRefreshToken = false,
  }) async {
    String? token;

    try {
      token = await _tokenProvider.currentToken(
        forceRefresh: forceRefreshToken,
      );
    } catch (_) {
      return _result(LearnerOnlineAccessStatus.backendUnavailable);
    }

    final normalizedToken = token?.trim();
    if (normalizedToken == null || normalizedToken.isEmpty) {
      return _result(LearnerOnlineAccessStatus.noAuthenticatedUser);
    }

    try {
      final authorized = await _authorizationProbe.authorize(
        accessToken: normalizedToken,
      );

      return _result(
        authorized
            ? LearnerOnlineAccessStatus.authorized
            : LearnerOnlineAccessStatus.rejected,
      );
    } catch (_) {
      return _result(LearnerOnlineAccessStatus.backendUnavailable);
    }
  }

  LearnerOnlineAccessResult _result(LearnerOnlineAccessStatus status) {
    return LearnerOnlineAccessResult(status: status, checkedAt: _clock());
  }
}
