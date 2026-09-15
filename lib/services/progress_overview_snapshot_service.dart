import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/progress_analytics_snapshot.dart';
import '../models/student_learning_progress.dart';
import '../models/student_progress_dashboard.dart';
import '../models/student_question_progress.dart';
import '../models/study_content.dart';
import 'auth/learner_local_identity.dart';
import 'learning_activity_tracker.dart';
import 'progress_analytics_event_bus.dart';
import 'student_learning_progress_service.dart';
import 'student_progress_dashboard_service.dart';
import 'student_question_progress_service.dart';
import 'study_content/student_content_cache_repository.dart';

class ProgressOverviewSnapshotService {
  const ProgressOverviewSnapshotService();

  static final Map<String, ProgressAnalyticsSnapshot> _memory =
      <String, ProgressAnalyticsSnapshot>{};

  static final Map<String, Future<ProgressAnalyticsSnapshot?>>
  _prewarmInFlight = <String, Future<ProgressAnalyticsSnapshot?>>{};

  static String storageKeyForUser(String userId) =>
      'csp11.student.$userId.progress_overview.v2';

  ProgressAnalyticsSnapshot? peek() {
    final userId = LearnerLocalIdentity.currentUserId?.trim();

    if (userId == null || userId.isEmpty) {
      return null;
    }

    return _memory[userId];
  }

  Future<ProgressAnalyticsSnapshot?> loadCached() async {
    final userId = LearnerLocalIdentity.requireCurrentUserId();

    final memory = _memory[userId];
    if (memory != null) {
      final dailySeconds = await LearningActivityTracker.instance
          .loadDailySeconds();
      final refreshed = _withDailyActivity(memory, dailySeconds);
      _memory[userId] = refreshed;
      return refreshed;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKeyForUser(userId));

    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! Map) {
        return null;
      }

      final snapshot = ProgressAnalyticsSnapshot.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      final dailySeconds = await LearningActivityTracker.instance
          .loadDailySeconds();
      final refreshed = _withDailyActivity(snapshot, dailySeconds);

      _memory[userId] = refreshed;
      return refreshed;
    } catch (_) {
      return null;
    }
  }

  /// Starts local-only prewarming without requiring a Firestore request.
  Future<ProgressAnalyticsSnapshot?> prewarm() {
    final userId = LearnerLocalIdentity.requireCurrentUserId();

    final existing = _prewarmInFlight[userId];
    if (existing != null) {
      return existing;
    }

    final future = _prewarmInternal(userId);
    _prewarmInFlight[userId] = future;

    return future.whenComplete(() {
      _prewarmInFlight.remove(userId);
    });
  }

  Future<ProgressAnalyticsSnapshot?> _prewarmInternal(String userId) async {
    final cached = await loadCached();

    if (cached != null && !ProgressAnalyticsEventBus.isDirty) {
      return cached;
    }

    return bootstrapLocal();
  }

  Future<ProgressAnalyticsSnapshot?> bootstrapLocal() async {
    final userId = LearnerLocalIdentity.requireCurrentUserId();
    final prefs = await SharedPreferences.getInstance();

    final results = await Future.wait<dynamic>([
      StudentContentCacheRepository(preferences: prefs).loadAll(),
      const StudentLearningProgressService().loadAllProgress(),
      const StudentQuestionProgressService().loadAllProgress(),
      LearningActivityTracker.instance.loadDailySeconds(),
    ]);

    final contents = results[0] as List<StudyContent>;
    final subtopicProgress = results[1] as Map<String, StudentSubtopicProgress>;
    final questionProgress = results[2] as Map<int, StudentQuestionProgress>;
    final dailySeconds = results[3] as Map<String, int>;

    if (contents.isEmpty) {
      return loadCached();
    }

    final dashboard = StudentProgressDashboardService.buildDashboard(
      contents: contents,
      subtopicProgress: subtopicProgress,
      questionProgress: questionProgress,
    );

    final snapshot = fromDashboard(dashboard, dailySeconds: dailySeconds);

    await _save(userId, snapshot);
    ProgressAnalyticsEventBus.markReconciled();

    return snapshot;
  }

  Future<ProgressAnalyticsSnapshot> refreshAuthoritative({
    Future<StudentProgressDashboard> Function()? dashboardLoader,
  }) async {
    final userId = LearnerLocalIdentity.requireCurrentUserId();

    final results = await Future.wait<dynamic>([
      dashboardLoader != null
          ? dashboardLoader()
          : const StudentProgressDashboardService().loadDashboard(),
      LearningActivityTracker.instance.loadDailySeconds(),
    ]);

    final dashboard = results[0] as StudentProgressDashboard;
    final dailySeconds = results[1] as Map<String, int>;

    final snapshot = fromDashboard(dashboard, dailySeconds: dailySeconds);

    await _save(userId, snapshot);
    ProgressAnalyticsEventBus.markReconciled();

    return snapshot;
  }

  ProgressAnalyticsSnapshot _withDailyActivity(
    ProgressAnalyticsSnapshot snapshot,
    Map<String, int> dailySeconds,
  ) {
    final daily = dailySeconds.entries
        .map(
          (entry) =>
              ProgressDailyActivity(dateKey: entry.key, seconds: entry.value),
        )
        .toList(growable: false);

    return snapshot.copyWith(dailyActivity: daily);
  }

  ProgressAnalyticsSnapshot fromDashboard(
    StudentProgressDashboard dashboard, {
    required Map<String, int> dailySeconds,
  }) {
    final daily = dailySeconds.entries
        .map(
          (entry) =>
              ProgressDailyActivity(dateKey: entry.key, seconds: entry.value),
        )
        .toList(growable: false);

    final domains = dashboard.domains
        .map(
          (domain) => ProgressDomainAnalyticsSummary(
            domainId: domain.domainId,
            domainNumber: domain.domainNumber,
            title: domain.title,
            completedTopics: domain.completedTopics,
            totalTopics: domain.topicCount,
            completedSubtopics: domain.completedSubtopics,
            totalSubtopics: domain.subtopicCount,
            answeredQuestions: domain.answeredQuestions,
            correctQuestions: domain.correctQuestions,
          ),
        )
        .toList(growable: false);

    return ProgressAnalyticsSnapshot(
      generatedAt: DateTime.now(),
      completedDomains: dashboard.completedDomains,
      totalDomains: dashboard.domains.length,
      completedTopics: dashboard.completedTopics,
      totalTopics: dashboard.totalTopics,
      completedSubtopics: dashboard.completedSubtopics,
      totalSubtopics: dashboard.totalSubtopics,
      answeredQuestions: dashboard.answeredQuestions,
      correctQuestions: dashboard.correctQuestions,
      latestActivity: dashboard.latestActivity,
      dailyActivity: daily,
      domains: domains,
    );
  }

  Future<void> _save(String userId, ProgressAnalyticsSnapshot snapshot) async {
    _memory[userId] = snapshot;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      storageKeyForUser(userId),
      jsonEncode(snapshot.toJson()),
    );
  }

  static void clearMemoryForTest() {
    _memory.clear();
    _prewarmInFlight.clear();
  }
}
