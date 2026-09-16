import 'package:exam_platform/features/learning_twin/integration/learning_twin_progress_guidance.dart';
import 'package:exam_platform/models/progress_analytics_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('empty progress shows deterministic start-learning guidance', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LearningTwinProgressGuidance(snapshot: _snapshot()),
        ),
      ),
    );

    expect(find.text('Start with one domain'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('learning-twin-progress-guidance')),
      findsOneWidget,
    );
  });

  testWidgets('weak domain shows remediation guidance', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LearningTwinProgressGuidance(
            snapshot: _snapshot(
              completedSubtopics: 4,
              totalSubtopics: 20,
              answeredQuestions: 8,
              correctQuestions: 3,
              domains: const [
                ProgressDomainAnalyticsSummary(
                  domainId: 'd03',
                  domainNumber: 3,
                  title: 'Risk Management',
                  completedTopics: 1,
                  totalTopics: 4,
                  completedSubtopics: 2,
                  totalSubtopics: 10,
                  answeredQuestions: 8,
                  correctQuestions: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Revisit Domain 03'), findsOneWidget);
    expect(find.textContaining('Risk Management'), findsOneWidget);

    // M5.2 is presentation-only. Action routing is intentionally deferred.
    expect(find.text('Review domain'), findsNothing);
  });

  testWidgets('mastery insight uses celebration copy', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LearningTwinProgressGuidance(
            snapshot: _snapshot(
              completedSubtopics: 19,
              totalSubtopics: 20,
              answeredQuestions: 20,
              correctQuestions: 17,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Strong progress pattern'), findsOneWidget);
  });

  testWidgets('dismiss removes adaptive guidance for the visit', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LearningTwinProgressGuidance(snapshot: _snapshot()),
        ),
      ),
    );

    expect(find.text('Start with one domain'), findsOneWidget);

    await tester.tap(find.byTooltip('Dismiss guidance'));
    await tester.pump();

    expect(find.text('Start with one domain'), findsNothing);
  });
}

ProgressAnalyticsSnapshot _snapshot({
  int completedSubtopics = 0,
  int totalSubtopics = 0,
  int answeredQuestions = 0,
  int correctQuestions = 0,
  List<ProgressDomainAnalyticsSummary> domains =
      const <ProgressDomainAnalyticsSummary>[],
}) {
  return ProgressAnalyticsSnapshot(
    generatedAt: DateTime.utc(2026, 9, 16),
    completedDomains: 0,
    totalDomains: 7,
    completedTopics: 0,
    totalTopics: 0,
    completedSubtopics: completedSubtopics,
    totalSubtopics: totalSubtopics,
    answeredQuestions: answeredQuestions,
    correctQuestions: correctQuestions,
    latestActivity: null,
    dailyActivity: const <ProgressDailyActivity>[],
    domains: domains,
  );
}
