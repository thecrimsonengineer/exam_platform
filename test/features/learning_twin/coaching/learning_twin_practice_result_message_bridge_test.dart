import 'package:exam_platform/features/learning_twin/coaching/learning_twin_practice_context.dart';
import 'package:exam_platform/features/learning_twin/coaching/learning_twin_practice_result_context.dart';
import 'package:exam_platform/features/learning_twin/coaching/learning_twin_practice_result_message_bridge.dart';
import 'package:exam_platform/features/learning_twin/domain/learning_twin_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const bridge = LearningTwinPracticeResultMessageBridge();

  LearningTwinMessage messageFor({
    required int score,
    required int total,
    LearningTwinPracticeMode mode = LearningTwinPracticeMode.randomQuiz,
    bool usedFallback = false,
    int? domainNumber,
  }) {
    return bridge.toCandidate(
      resultContext: LearningTwinPracticeResultContext(
        practiceContext: LearningTwinPracticeContext(
          mode: mode,
          questionCount: total,
          domainNumber: domainNumber,
          usedFallback: usedFallback,
        ),
        score: score,
        totalQuestions: total,
      ),
      screenId: 'practice-result',
    );
  }

  test('perfect result celebrates', () {
    final message = messageFor(score: 10, total: 10);

    expect(message.trigger, LearningTwinTrigger.practiceCompleted);
    expect(message.state, LearningTwinState.celebrate);
    expect(message.title, 'Clean sweep');
    expect(message.body, contains('10 of 10 correct'));
    expect(message.action, isNull);
  });

  test('80 percent result uses strong result review', () {
    final message = messageFor(score: 8, total: 10);

    expect(message.state, LearningTwinState.resultReview);
    expect(message.title, 'Strong practice result');
    expect(message.body, contains('2 missed questions'));
  });

  test('60 percent result uses targeted review guidance', () {
    final message = messageFor(score: 6, total: 10);

    expect(message.state, LearningTwinState.resultReview);
    expect(message.title, 'Review the misses');
    expect(message.body, contains('4 missed questions'));
  });

  test('below 60 percent result uses remediation guidance', () {
    final message = messageFor(score: 5, total: 10);

    expect(message.state, LearningTwinState.remediate);
    expect(message.title, 'Reinforce before moving on');
    expect(message.body, contains('5 missed questions'));
  });

  test('evidence-backed weak area keeps domain scope', () {
    final message = messageFor(
      score: 4,
      total: 10,
      mode: LearningTwinPracticeMode.weakAreas,
      domainNumber: 4,
    );

    expect(message.domainId, 'd04');
    expect(message.state, LearningTwinState.remediate);
    expect(message.body, contains('focused weak-area session'));
  });

  test('weak fallback refuses to claim a weak domain', () {
    final message = messageFor(
      score: 3,
      total: 10,
      mode: LearningTwinPracticeMode.weakAreas,
      usedFallback: true,
    );

    expect(message.domainId, isNull);
    expect(message.title, 'This result adds evidence');
    expect(message.body, contains('mixed fallback session'));
    expect(
      message.body,
      contains('not as proof that a particular Domain is weak'),
    );
  });

  test('same sanitized result produces stable candidate', () {
    final first = messageFor(score: 7, total: 10);
    final second = messageFor(score: 7, total: 10);

    expect(first.id, second.id);
    expect(first.body, second.body);
    expect(first.state, second.state);
  });
}
