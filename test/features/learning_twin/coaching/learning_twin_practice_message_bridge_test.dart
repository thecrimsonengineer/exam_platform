import 'package:exam_platform/features/learning_twin/coaching/learning_twin_practice_context.dart';
import 'package:exam_platform/features/learning_twin/coaching/learning_twin_practice_message_bridge.dart';
import 'package:exam_platform/features/learning_twin/domain/learning_twin_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const bridge = LearningTwinPracticeMessageBridge();

  test('daily challenge creates deterministic screen-visit guidance', () {
    const context = LearningTwinPracticeContext(
      mode: LearningTwinPracticeMode.dailyChallenge,
      questionCount: 5,
    );

    final first = bridge.toCandidate(
      practiceContext: context,
      screenId: 'practice-quiz',
    );
    final second = bridge.toCandidate(
      practiceContext: context,
      screenId: 'practice-quiz',
    );

    expect(first.id, second.id);
    expect(first.body, second.body);
    expect(first.trigger, LearningTwinTrigger.screenVisit);
    expect(first.state, LearningTwinState.encourage);
    expect(first.body, contains('5 published questions'));
  });

  test('random quiz guidance remains mixed and non-targeted', () {
    final message = bridge.toCandidate(
      practiceContext: const LearningTwinPracticeContext(
        mode: LearningTwinPracticeMode.randomQuiz,
        questionCount: 10,
      ),
      screenId: 'practice-quiz',
    );

    expect(message.domainId, isNull);
    expect(message.body, contains('mixed set'));
    expect(message.action, isNull);
  });

  test('evidence-backed weak mode targets the sanitized domain only', () {
    final message = bridge.toCandidate(
      practiceContext: const LearningTwinPracticeContext(
        mode: LearningTwinPracticeMode.weakAreas,
        questionCount: 10,
        domainNumber: 4,
      ),
      screenId: 'practice-quiz',
    );

    expect(message.state, LearningTwinState.remediate);
    expect(message.domainId, 'd04');
    expect(message.title, 'Reinforce Domain 04');
    expect(message.body, contains('weak-area evidence threshold'));
  });

  test('weak fallback explicitly says evidence is insufficient', () {
    final message = bridge.toCandidate(
      practiceContext: const LearningTwinPracticeContext(
        mode: LearningTwinPracticeMode.weakAreas,
        questionCount: 10,
        usedFallback: true,
      ),
      screenId: 'practice-quiz',
    );

    expect(message.domainId, isNull);
    expect(message.body, contains('not enough reliable performance evidence'));
    expect(message.body, contains('mixed published-question set'));
  });

  test('custom quiz reports learner-selected scope without an action', () {
    final message = bridge.toCandidate(
      practiceContext: const LearningTwinPracticeContext(
        mode: LearningTwinPracticeMode.customQuiz,
        questionCount: 20,
        domainNumber: 7,
        competencyId: 'd07_c01',
        subtopicId: 'd07_c01_s02',
      ),
      screenId: 'practice-quiz',
    );

    expect(message.domainId, 'd07');
    expect(message.competencyId, 'd07_c01');
    expect(message.subtopicId, 'd07_c01_s02');
    expect(message.body, contains('20-question session for Domain 07'));
    expect(message.action, isNull);
  });
}
