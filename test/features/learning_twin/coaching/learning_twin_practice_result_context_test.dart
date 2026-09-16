import 'package:exam_platform/features/learning_twin/coaching/learning_twin_practice_context.dart';
import 'package:exam_platform/features/learning_twin/coaching/learning_twin_practice_result_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('result context exposes aggregate practice outcome only', () {
    const result = LearningTwinPracticeResultContext(
      practiceContext: LearningTwinPracticeContext(
        mode: LearningTwinPracticeMode.randomQuiz,
        questionCount: 10,
      ),
      score: 8,
      totalQuestions: 10,
    );

    expect(result.score, 8);
    expect(result.totalQuestions, 10);
    expect(result.incorrectCount, 2);
    expect(result.accuracy, 0.8);
    expect(result.accuracyPercent, 80);
    expect(result.isPerfect, isFalse);
  });

  test('perfect result is identified deterministically', () {
    const result = LearningTwinPracticeResultContext(
      practiceContext: LearningTwinPracticeContext(
        mode: LearningTwinPracticeMode.dailyChallenge,
        questionCount: 5,
      ),
      score: 5,
      totalQuestions: 5,
    );

    expect(result.isPerfect, isTrue);
    expect(result.incorrectCount, 0);
    expect(result.accuracyPercent, 100);
  });

  test('invalid aggregate result fails closed', () {
    expect(
      () => LearningTwinPracticeResultContext(
        practiceContext: const LearningTwinPracticeContext(
          mode: LearningTwinPracticeMode.randomQuiz,
          questionCount: 10,
        ),
        score: 11,
        totalQuestions: 10,
      ),
      throwsA(isA<AssertionError>()),
    );
  });
}
