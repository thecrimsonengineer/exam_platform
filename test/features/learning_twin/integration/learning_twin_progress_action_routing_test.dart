import 'package:exam_platform/features/learning_twin/integration/learning_twin_progress_guidance.dart';
import 'package:exam_platform/models/progress_analytics_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('weak-domain action delegates target to Progress host once', (
    tester,
  ) async {
    String? openedDomain;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LearningTwinProgressGuidance(
            snapshot: _weakDomainSnapshot(),
            onOpenDomain: (domainId) {
              openedDomain = domainId;
            },
          ),
        ),
      ),
    );

    expect(find.text('Review domain'), findsOneWidget);

    await tester.tap(find.text('Review domain'));
    await tester.pump();

    expect(openedDomain, 'd03');

    // Action is consumed for this mounted Progress visit.
    expect(find.text('Review domain'), findsNothing);
  });

  testWidgets('active-domain continue action delegates target once', (
    tester,
  ) async {
    String? openedDomain;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LearningTwinProgressGuidance(
            snapshot: _activeDomainSnapshot(),
            onOpenDomain: (domainId) {
              openedDomain = domainId;
            },
          ),
        ),
      ),
    );

    expect(find.text('Continue learning'), findsOneWidget);

    await tester.tap(find.text('Continue learning'));
    await tester.pump();

    expect(openedDomain, 'd04');
    expect(find.text('Continue learning'), findsNothing);
  });

  testWidgets('no callback means no action button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LearningTwinProgressGuidance(snapshot: _weakDomainSnapshot()),
        ),
      ),
    );

    expect(find.text('Review domain'), findsNothing);
  });
}

ProgressAnalyticsSnapshot _weakDomainSnapshot() {
  return ProgressAnalyticsSnapshot(
    generatedAt: DateTime.utc(2026, 9, 16),
    completedDomains: 0,
    totalDomains: 7,
    completedTopics: 1,
    totalTopics: 10,
    completedSubtopics: 2,
    totalSubtopics: 20,
    answeredQuestions: 8,
    correctQuestions: 3,
    latestActivity: null,
    dailyActivity: const <ProgressDailyActivity>[],
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
  );
}

ProgressAnalyticsSnapshot _activeDomainSnapshot() {
  return ProgressAnalyticsSnapshot(
    generatedAt: DateTime.utc(2026, 9, 16),
    completedDomains: 0,
    totalDomains: 7,
    completedTopics: 0,
    totalTopics: 10,
    completedSubtopics: 1,
    totalSubtopics: 20,
    answeredQuestions: 0,
    correctQuestions: 0,
    latestActivity: null,
    dailyActivity: const <ProgressDailyActivity>[],
    domains: const [
      ProgressDomainAnalyticsSummary(
        domainId: 'd04',
        domainNumber: 4,
        title: 'Emergency Management',
        completedTopics: 0,
        totalTopics: 4,
        completedSubtopics: 1,
        totalSubtopics: 10,
        answeredQuestions: 0,
        correctQuestions: 0,
      ),
    ],
  );
}
