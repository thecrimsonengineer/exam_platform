import '../auth/learner_local_identity.dart';
import '../quiz_service.dart';
import '../student_progress_dashboard_session_cache.dart';
import '../study_content/student_study_content_session_cache.dart';
import '../supabase/supabase_bootstrap_service.dart';
import '../supabase/supabase_learner_remote_authorization_probe.dart';
import 'firebase_learner_access_token_provider.dart';
import 'learner_online_access_gate.dart';
import 'learner_online_access_session_controller.dart';

class LearnerOnlineAccessRuntime {
  LearnerOnlineAccessRuntime._();

  static LearnerOnlineAccessSessionController? _controller;
  static String? _userId;

  static LearnerOnlineAccessSessionController createDefaultController() {
    final LearnerRemoteAuthorizationProbe probe =
        SupabaseBootstrapService.isInitialized
        ? SupabaseLearnerRemoteAuthorizationProbe()
        : _UnavailableLearnerRemoteAuthorizationProbe();

    return LearnerOnlineAccessSessionController(
      validator: LearnerOnlineAccessGate(
        tokenProvider: FirebaseLearnerAccessTokenProvider(),
        authorizationProbe: probe,
      ),
      currentUserId: () => LearnerLocalIdentity.currentUserId,
    );
  }

  static void bind({
    required String userId,
    required LearnerOnlineAccessSessionController controller,
  }) {
    final normalized = _normalizeUserId(userId);
    final replacingSession =
        !identical(_controller, controller) || _userId != normalized;

    if (replacingSession) {
      _controller?.lock(reason: LearnerOnlineLockReason.userChanged);
      clearProtectedProcessMemory();
    }

    _userId = normalized;
    _controller = controller;
  }

  static void unbind(LearnerOnlineAccessSessionController controller) {
    if (!identical(_controller, controller)) {
      return;
    }

    clearProtectedProcessMemory();
    _controller = null;
    _userId = null;
  }

  static void handleAuthUserChanged(String? userId) {
    final normalized = _normalizeOptionalUserId(userId);
    final boundUserId = _userId;

    if (boundUserId == null || normalized == boundUserId) {
      return;
    }

    _controller?.handleAuthUserChanged(normalized);
    clearProtectedProcessMemory();
  }

  static void lockCurrentSession({
    LearnerOnlineLockReason reason = LearnerOnlineLockReason.manual,
  }) {
    _controller?.lock(reason: reason);
    clearProtectedProcessMemory();
  }

  static LearnerProtectedCacheAccessBoundary requireBoundaryFor(String userId) {
    final normalized = _normalizeUserId(userId);
    final controller = _controller;

    if (controller == null || _userId != normalized) {
      throw StateError(
        'No FR8 online authorization session is bound to Firebase UID '
        '"$normalized".',
      );
    }

    return controller;
  }

  static bool isAuthorizedFor(String userId) {
    final normalized = _normalizeOptionalUserId(userId);
    final controller = _controller;

    return normalized != null &&
        normalized == _userId &&
        controller != null &&
        controller.isAuthorizedFor(normalized);
  }

  static void clearProtectedProcessMemory() {
    StudentStudyContentSessionCache.clear();
    StudentProgressDashboardSessionCache.clearAll();
    QuizService.shared.clearProtectedSession();
  }

  static String _normalizeUserId(String userId) {
    final normalized = userId.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(
        userId,
        'userId',
        'Firebase UID cannot be empty.',
      );
    }

    return normalized;
  }

  static String? _normalizeOptionalUserId(String? userId) {
    final normalized = userId?.trim();

    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return normalized;
  }
}

class _UnavailableLearnerRemoteAuthorizationProbe
    implements LearnerRemoteAuthorizationProbe {
  @override
  Future<bool> authorize({required String accessToken}) {
    throw StateError(
      'Supabase is not configured, so protected learner access remains locked.',
    );
  }
}
