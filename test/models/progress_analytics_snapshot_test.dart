import 'package:exam_platform/models/progress_analytics_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('analytics snapshot round-trips and computes weekly metrics', () {
    final snapshot = ProgressAnalyticsSnapshot(
      generatedAt: DateTime.utc(2026, 9, 15, 12),
      completedDomains: 1,
      totalDomains: 7,
      completedTopics: 4,
      totalTopics: 10,
      completedSubtopics: 8,
      totalSubtopics: 20,
      answeredQuestions: 30,
      correctQuestions: 24,
      latestActivity: DateTime.utc(2026, 9, 15, 11),
      dailyActivity: const [
        ProgressDailyActivity(dateKey: '2026-09-09', seconds: 600),
        ProgressDailyActivity(dateKey: '2026-09-10', seconds: 1200),
        ProgressDailyActivity(dateKey: '2026-09-11', seconds: 0),
        ProgressDailyActivity(dateKey: '2026-09-12', seconds: 1800),
        ProgressDailyActivity(dateKey: '2026-09-13', seconds: 600),
        ProgressDailyActivity(dateKey: '2026-09-14', seconds: 600),
        ProgressDailyActivity(dateKey: '2026-09-15', seconds: 600),
      ],
      domains: const [],
    );

    final restored = ProgressAnalyticsSnapshot.fromJson(snapshot.toJson());

    expect(restored.completedSubtopics, 8);
    expect(restored.overallProgress, 0.4);
    expect(restored.accuracy, 0.8);
    expect(restored.weeklyMinutes, 90);
    expect(restored.activeDays, 6);
    expect(restored.studyStreakDays, 4);
  });
}
