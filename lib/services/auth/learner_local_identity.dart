/// In-memory identity boundary for learner-owned local persistence.
///
/// AuthGate activates the verified student Firebase UID before the learner
/// shell is built. Local learner repositories resolve their storage namespace
/// through this boundary rather than using a device-global SharedPreferences
/// key.
///
/// The UID is intentionally not persisted here. Firebase Auth remains the
/// source of truth for the signed-in account on every app start.
class LearnerLocalIdentity {
  LearnerLocalIdentity._();

  static String? _currentUserId;

  static String? get currentUserId => _currentUserId;

  static void activate(String userId) {
    final normalized = userId.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(
        userId,
        'userId',
        'Firebase UID cannot be empty.',
      );
    }

    _currentUserId = normalized;
  }

  static void clear() {
    _currentUserId = null;
  }

  static String requireCurrentUserId({String? userIdOverride}) {
    final override = userIdOverride?.trim();

    if (override != null && override.isNotEmpty) {
      return override;
    }

    final active = _currentUserId?.trim();

    if (active == null || active.isEmpty) {
      throw StateError(
        'No active learner Firebase UID is available for local persistence.',
      );
    }

    return active;
  }
}
