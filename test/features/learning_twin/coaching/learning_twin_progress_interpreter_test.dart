import 'package:exam_platform/features/learning_twin/coaching/learning_twin_coaching.dart';
import 'package:exam_platform/models/progress_analytics_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const interpreter = DeterministicLearningTwinProgressInterpreter();

  test('empty progress produces start-learning guidance', () {
    final insight = interpreter.interpret(_snapshot());
    expect(insight.type, LearningTwinProgressInsightType.startLearning);
    expect(insight.priority, 40);
  });

  test('study without enough practice produces add-practice guidance', () {
    final insight = interpreter.interpret(
      _snapshot(completedSubtopics: 4, totalSubtopics: 20),
    );
    expect(insight.type, LearningTwinProgressInsightType.addPractice);
    expect(insight.priority, 80);
  });

  test('weak domain uses evidence floor and deterministic selection', () {
    final insight = interpreter.interpret(
      _snapshot(
        completedSubtopics: 8,
        totalSubtopics: 40,
        answeredQuestions: 14,
        correctQuestions: 8,
        domains: const [
          ProgressDomainAnalyticsSummary(
            domainId: 'd01',
            domainNumber: 1,
            title: 'Advanced Application of Safety Principles',
            completedTopics: 1,
            totalTopics: 4,
            completedSubtopics: 3,
            totalSubtopics: 10,
            answeredQuestions: 6,
            correctQuestions: 3,
          ),
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
    );

    expect(insight.type, LearningTwinProgressInsightType.weakDomainRemediation);
    expect(insight.domainId, 'd03');
  });

  test('weak accuracy is suppressed below five answered questions', () {
    final insight = interpreter.interpret(
      _snapshot(
        completedSubtopics: 1,
        totalSubtopics: 10,
        answeredQuestions: 4,
        correctQuestions: 1,
        domains: const [
          ProgressDomainAnalyticsSummary(
            domainId: 'd02',
            domainNumber: 2,
            title: 'Program Management',
            completedTopics: 0,
            totalTopics: 2,
            completedSubtopics: 1,
            totalSubtopics: 10,
            answeredQuestions: 4,
            correctQuestions: 1,
          ),
        ],
      ),
    );

    expect(insight.type, LearningTwinProgressInsightType.continueLearning);
  });

  test('mastery pattern has highest priority', () {
    final insight = interpreter.interpret(
      _snapshot(
        completedSubtopics: 19,
        totalSubtopics: 20,
        answeredQuestions: 20,
        correctQuestions: 17,
      ),
    );

    expect(
      insight.type,
      LearningTwinProgressInsightType.masteryAcknowledgement,
    );
    expect(insight.priority, 100);
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
