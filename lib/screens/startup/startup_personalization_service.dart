import '../../features/exam_readiness/models/daily_study_plan.dart';
import '../../features/exam_readiness/models/study_plan_block.dart';
import '../../features/exam_readiness/repositories/daily_study_plan_repository.dart';
import '../../services/student_learning_position_service.dart';

typedef StartupPositionLoader =
    Future<StudentLearningPosition?> Function(String userId);
typedef StartupPlanLoader =
    Future<DailyStudyPlan?> Function(String userId, DateTime date);

class StartupPersonalizationSnapshot {
  const StartupPersonalizationSnapshot({
    this.resumeCode,
    this.resumeTitle,
    this.todayRemainingActivities,
    this.todayRemainingMinutes,
    this.todayCompletedActivities,
    this.todayTotalActivities,
  });

  const StartupPersonalizationSnapshot.empty()
    : resumeCode = null,
      resumeTitle = null,
      todayRemainingActivities = null,
      todayRemainingMinutes = null,
      todayCompletedActivities = null,
      todayTotalActivities = null;

  final String? resumeCode;
  final String? resumeTitle;
  final int? todayRemainingActivities;
  final int? todayRemainingMinutes;
  final int? todayCompletedActivities;
  final int? todayTotalActivities;

  bool get hasResume => resumeCode != null && resumeCode!.trim().isNotEmpty;

  bool get hasTodayPlan => todayTotalActivities != null;

  bool get hasAnyData => hasResume || hasTodayPlan;

  String? get todaySummary {
    if (!hasTodayPlan) {
      return null;
    }

    final remaining = todayRemainingActivities ?? 0;
    final minutes = todayRemainingMinutes ?? 0;
    final completed = todayCompletedActivities ?? 0;

    if (remaining == 0 && completed > 0) {
      return 'Today\'s plan complete';
    }

    if (remaining == 0) {
      return 'No activities remaining today';
    }

    final noun = remaining == 1 ? 'activity' : 'activities';
    return '$remaining $noun · $minutes min remaining';
  }
}

/// Builds startup-only context from UID-scoped local caches.
///
/// The default loaders never refresh remote state.
class StartupPersonalizationService {
  StartupPersonalizationService({
    StartupPositionLoader? positionLoader,
    StartupPlanLoader? planLoader,
  }) : _positionLoader = positionLoader ?? _loadPositionLocally,
       _planLoader = planLoader ?? _loadPlanLocally;

  final StartupPositionLoader _positionLoader;
  final StartupPlanLoader _planLoader;

  Future<StartupPersonalizationSnapshot> loadForUser(
    String userId, {
    DateTime? now,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return const StartupPersonalizationSnapshot.empty();
    }

    final today = now ?? DateTime.now();

    StudentLearningPosition? position;
    DailyStudyPlan? plan;

    try {
      position = await _positionLoader(normalizedUserId);
    } catch (_) {
      position = null;
    }

    try {
      plan = await _planLoader(normalizedUserId, today);
    } catch (_) {
      plan = null;
    }

    return StartupPersonalizationSnapshot(
      resumeCode: _resumeCode(position),
      resumeTitle: _resumeTitle(position),
      todayRemainingActivities: plan?.blocks.where(_isOutstanding).length,
      todayRemainingMinutes: plan?.blocks
          .where(_isOutstanding)
          .fold<int>(0, (sum, block) => sum + block.plannedMinutes),
      todayCompletedActivities: plan?.blocks
          .where((block) => block.status == StudyPlanBlockStatus.completed)
          .length,
      todayTotalActivities: plan?.blocks.length,
    );
  }

  static Future<StudentLearningPosition?> _loadPositionLocally(String userId) {
    return StudentLearningPositionService(
      userIdOverride: userId,
    ).loadPosition();
  }

  static Future<DailyStudyPlan?> _loadPlanLocally(
    String userId,
    DateTime date,
  ) {
    return DailyStudyPlanRepository(
      userIdOverride: userId,
    ).loadLatestForDate(date, refreshRemote: false);
  }

  static bool _isOutstanding(StudyPlanBlock block) {
    switch (block.status) {
      case StudyPlanBlockStatus.planned:
      case StudyPlanBlockStatus.started:
      case StudyPlanBlockStatus.shortened:
        return true;
      case StudyPlanBlockStatus.completed:
      case StudyPlanBlockStatus.skipped:
      case StudyPlanBlockStatus.movedToTomorrow:
      case StudyPlanBlockStatus.replaced:
      case StudyPlanBlockStatus.unavailable:
        return false;
    }
  }

  static String? _resumeCode(StudentLearningPosition? position) {
    if (position == null) {
      return null;
    }

    final competencyId = position.competencyId.trim().toUpperCase();
    if (competencyId.isNotEmpty) {
      return competencyId.replaceAll('_', ' · ');
    }

    return 'D${position.domainNumber.toString().padLeft(2, '0')}';
  }

  static String? _resumeTitle(StudentLearningPosition? position) {
    if (position == null) {
      return null;
    }

    final subtopic = position.subtopicTitle?.trim();
    if (subtopic != null && subtopic.isNotEmpty) {
      return _shorten(subtopic);
    }

    final competency = position.competencyTitle.trim();
    if (competency.isEmpty) {
      return null;
    }

    return _shorten(competency);
  }

  static String _shorten(String value) {
    const maxCharacters = 72;
    if (value.length <= maxCharacters) {
      return value;
    }

    return '${value.substring(0, maxCharacters - 1).trimRight()}…';
  }
}
