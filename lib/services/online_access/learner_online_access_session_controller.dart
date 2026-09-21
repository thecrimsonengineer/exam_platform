import 'dart:async';

import 'learner_online_access_gate.dart';

enum LearnerOnlineSessionStatus { locked, validating, authorized }

enum LearnerOnlineLockReason {
  startup,
  signedOut,
  userChanged,
  noAuthenticatedUser,
  backendUnavailable,
  rejected,
  appResumed,
  connectivityLost,
  manual,
}

class LearnerOnlineAccessSessionSnapshot {
  const LearnerOnlineAccessSessionSnapshot({
    required this.status,
    required this.changedAt,
    this.userId,
    this.lockReason,
    this.authorizationCheckedAt,
  });

  final LearnerOnlineSessionStatus status;
  final String? userId;
  final LearnerOnlineLockReason? lockReason;
  final DateTime changedAt;
  final DateTime? authorizationCheckedAt;

  bool isAuthorizedFor(String userId) {
    final normalized = userId.trim();
    return normalized.isNotEmpty &&
        status == LearnerOnlineSessionStatus.authorized &&
        this.userId == normalized;
  }
}

abstract interface class LearnerProtectedCacheAccessBoundary {
  bool isAuthorizedFor(String userId);
}

typedef LearnerOnlineIdentityReader = String? Function();
typedef LearnerOnlineDelay = Future<void> Function(Duration duration);

class LearnerOnlineAccessSessionController
    implements LearnerProtectedCacheAccessBoundary {
  LearnerOnlineAccessSessionController({
    required LearnerOnlineAccessValidator validator,
    required LearnerOnlineIdentityReader currentUserId,
    DateTime Function()? clock,
    LearnerOnlineDelay? delay,
    this.reconnectGrace = const Duration(seconds: 2),
  }) : _validator = validator,
       _currentUserId = currentUserId,
       _clock = clock ?? DateTime.now,
       _delay = delay ?? Future<void>.delayed {
    _snapshot = LearnerOnlineAccessSessionSnapshot(
      status: LearnerOnlineSessionStatus.locked,
      changedAt: _clock(),
      lockReason: LearnerOnlineLockReason.startup,
    );
  }

  final LearnerOnlineAccessValidator _validator;
  final LearnerOnlineIdentityReader _currentUserId;
  final DateTime Function() _clock;
  final LearnerOnlineDelay _delay;
  final Duration reconnectGrace;

  final StreamController<LearnerOnlineAccessSessionSnapshot> _changes =
      StreamController<LearnerOnlineAccessSessionSnapshot>.broadcast(
        sync: true,
      );

  late LearnerOnlineAccessSessionSnapshot _snapshot;
  int _generation = 0;
  bool _disposed = false;

  LearnerOnlineAccessSessionSnapshot get snapshot => _snapshot;

  Stream<LearnerOnlineAccessSessionSnapshot> get changes => _changes.stream;

  @override
  bool isAuthorizedFor(String userId) => _snapshot.isAuthorizedFor(userId);

  Future<LearnerOnlineAccessSessionSnapshot> authorizeCurrentUser({
    bool forceRefreshToken = false,
  }) async {
    final userId = _normalizeUserId(_currentUserId());
    if (userId == null) {
      return _lock(LearnerOnlineLockReason.signedOut);
    }

    return authorizeForUser(
      userId,
      forceRefreshToken: forceRefreshToken,
    );
  }

  Future<LearnerOnlineAccessSessionSnapshot> authorizeForUser(
    String userId, {
    bool forceRefreshToken = false,
  }) async {
    final expectedUserId = _normalizeUserId(userId);
    if (expectedUserId == null) {
      throw ArgumentError.value(
        userId,
        'userId',
        'Learner Firebase UID cannot be empty.',
      );
    }

    final generation = ++_generation;
    if (_normalizeUserId(_currentUserId()) != expectedUserId) {
      return _lock(
        LearnerOnlineLockReason.userChanged,
        invalidateGeneration: false,
      );
    }

    _publish(
      LearnerOnlineAccessSessionSnapshot(
        status: LearnerOnlineSessionStatus.validating,
        userId: expectedUserId,
        changedAt: _clock(),
      ),
    );

    final result = await _validator.validate(
      forceRefreshToken: forceRefreshToken,
    );

    if (generation != _generation) {
      return _snapshot;
    }

    if (_normalizeUserId(_currentUserId()) != expectedUserId) {
      return _lock(
        LearnerOnlineLockReason.userChanged,
        invalidateGeneration: false,
      );
    }

    if (result.isAuthorized) {
      _publish(
        LearnerOnlineAccessSessionSnapshot(
          status: LearnerOnlineSessionStatus.authorized,
          userId: expectedUserId,
          changedAt: _clock(),
          authorizationCheckedAt: result.checkedAt,
        ),
      );
      return _snapshot;
    }

    return _lock(
      _lockReasonFor(result.status),
      invalidateGeneration: false,
    );
  }

  void handleAuthUserChanged(String? userId) {
    final normalized = _normalizeUserId(userId);
    if (normalized == null) {
      _lock(LearnerOnlineLockReason.signedOut);
      return;
    }

    final boundUser = _snapshot.userId;
    if (boundUser != null && boundUser != normalized) {
      _lock(LearnerOnlineLockReason.userChanged);
    }
  }

  Future<LearnerOnlineAccessSessionSnapshot> revalidateOnResume() async {
    final userId = _normalizeUserId(_currentUserId());
    _lock(LearnerOnlineLockReason.appResumed);

    if (userId == null) {
      return _snapshot;
    }

    return authorizeForUser(userId, forceRefreshToken: true);
  }

  Future<LearnerOnlineAccessSessionSnapshot>
  handleTransientConnectivityLoss() async {
    final userId = _normalizeUserId(_currentUserId());
    if (userId == null) {
      return _lock(LearnerOnlineLockReason.signedOut);
    }

    final generation = ++_generation;
    await _delay(reconnectGrace);

    if (generation != _generation) {
      return _snapshot;
    }

    if (_normalizeUserId(_currentUserId()) != userId) {
      return _lock(
        LearnerOnlineLockReason.userChanged,
        invalidateGeneration: false,
      );
    }

    return authorizeForUser(userId, forceRefreshToken: true);
  }

  Future<LearnerOnlineAccessSessionSnapshot>
  handleConnectivityRestored() async {
    return authorizeCurrentUser(forceRefreshToken: true);
  }

  void handleConfirmedNetworkLoss() {
    _lock(LearnerOnlineLockReason.connectivityLost);
  }

  void lock({LearnerOnlineLockReason reason = LearnerOnlineLockReason.manual}) {
    _lock(reason);
  }

  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;
    _generation++;
    _changes.close();
  }

  LearnerOnlineAccessSessionSnapshot _lock(
    LearnerOnlineLockReason reason, {
    bool invalidateGeneration = true,
  }) {
    if (invalidateGeneration) {
      _generation++;
    }

    _publish(
      LearnerOnlineAccessSessionSnapshot(
        status: LearnerOnlineSessionStatus.locked,
        changedAt: _clock(),
        lockReason: reason,
      ),
    );
    return _snapshot;
  }

  void _publish(LearnerOnlineAccessSessionSnapshot next) {
    _snapshot = next;
    if (!_disposed) {
      _changes.add(next);
    }
  }

  LearnerOnlineLockReason _lockReasonFor(
    LearnerOnlineAccessStatus status,
  ) {
    return switch (status) {
      LearnerOnlineAccessStatus.authorized => LearnerOnlineLockReason.manual,
      LearnerOnlineAccessStatus.noAuthenticatedUser =>
        LearnerOnlineLockReason.noAuthenticatedUser,
      LearnerOnlineAccessStatus.backendUnavailable =>
        LearnerOnlineLockReason.backendUnavailable,
      LearnerOnlineAccessStatus.rejected => LearnerOnlineLockReason.rejected,
    };
  }

  String? _normalizeUserId(String? userId) {
    final normalized = userId?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}
