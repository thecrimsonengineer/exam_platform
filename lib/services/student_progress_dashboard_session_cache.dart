import '../models/student_progress_dashboard.dart';

/// UID-scoped process-memory cache for the already-built progress dashboard.
///
/// Persistent progress and Firebase published content remain authoritative.
/// This cache exists only so revisiting the Progress tab can paint immediately.
class StudentProgressDashboardSessionCache {
  StudentProgressDashboardSessionCache._();

  static final Map<String, StudentProgressDashboard> _dashboardByUser =
      <String, StudentProgressDashboard>{};

  static StudentProgressDashboard? peek(String userId) {
    final normalized = userId.trim();

    if (normalized.isEmpty) {
      return null;
    }

    return _dashboardByUser[normalized];
  }

  static void put(String userId, StudentProgressDashboard dashboard) {
    final normalized = userId.trim();

    if (normalized.isEmpty) {
      return;
    }

    _dashboardByUser[normalized] = dashboard;
  }

  static void invalidate(String userId) {
    final normalized = userId.trim();

    if (normalized.isEmpty) {
      return;
    }

    _dashboardByUser.remove(normalized);
  }

  static void clearAll() {
    _dashboardByUser.clear();
  }
}
