import 'package:firebase_auth/firebase_auth.dart';

import '../models/student_learning_progress.dart';

/// UID-scoped in-memory cache for decoded learner progress.
///
/// Persistent storage remains authoritative. This cache only avoids repeatedly
/// resolving SharedPreferences and decoding the same progress JSON while the
/// signed-in learner moves through study screens.
///
/// Any progress write/reset must invalidate the current learner's entry.
class StudentLearningProgressSessionCache {
  StudentLearningProgressSessionCache._();

  static final Map<String, Map<String, StudentSubtopicProgress>>
  _progressByScope = <String, Map<String, StudentSubtopicProgress>>{};

  static final Map<String, Future<Map<String, StudentSubtopicProgress>>>
  _inFlightByScope = <String, Future<Map<String, StudentSubtopicProgress>>>{};

  static String _currentScope() {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid.trim();

      if (uid != null && uid.isNotEmpty) {
        return 'uid:$uid';
      }
    } catch (_) {
      // Firebase may not be initialized in isolated unit tests.
    }

    return 'signed-out';
  }

  /// Returns already-decoded progress for this learner without scheduling a
  /// Future or touching SharedPreferences.
  ///
  /// Null means this scope has not been loaded yet or was invalidated.
  static Map<String, StudentSubtopicProgress>? peek({String? scopeKey}) {
    final scope = scopeKey ?? _currentScope();
    final cached = _progressByScope[scope];

    if (cached == null) {
      return null;
    }

    return Map<String, StudentSubtopicProgress>.unmodifiable(cached);
  }

  static Future<Map<String, StudentSubtopicProgress>> load({
    required Future<Map<String, StudentSubtopicProgress>> Function() loader,
    String? scopeKey,
  }) async {
    final scope = scopeKey ?? _currentScope();
    final cached = _progressByScope[scope];

    if (cached != null) {
      return Map<String, StudentSubtopicProgress>.unmodifiable(cached);
    }

    final existingLoad = _inFlightByScope[scope];

    if (existingLoad != null) {
      return Map<String, StudentSubtopicProgress>.unmodifiable(
        await existingLoad,
      );
    }

    final loadFuture = loader();
    _inFlightByScope[scope] = loadFuture;

    try {
      final loaded = await loadFuture;
      final snapshot = Map<String, StudentSubtopicProgress>.from(loaded);
      _progressByScope[scope] = snapshot;

      return Map<String, StudentSubtopicProgress>.unmodifiable(snapshot);
    } finally {
      _inFlightByScope.remove(scope);
    }
  }

  static void invalidateCurrentUser() {
    invalidateScope(_currentScope());
  }

  static void invalidateScope(String scopeKey) {
    _progressByScope.remove(scopeKey);
    _inFlightByScope.remove(scopeKey);
  }

  static void clearAllScopes() {
    _progressByScope.clear();
    _inFlightByScope.clear();
  }
}
