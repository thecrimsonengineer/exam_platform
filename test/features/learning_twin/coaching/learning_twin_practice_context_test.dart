import 'package:exam_platform/features/learning_twin/coaching/learning_twin_practice_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('practice context exposes only sanitized session metadata', () {
    const context = LearningTwinPracticeContext(
      mode: LearningTwinPracticeMode.weakAreas,
      questionCount: 10,
      domainNumber: 4,
      competencyId: 'd04_c02',
      subtopicId: 'd04_c02_s01',
    );

    expect(context.questionCount, 10);
    expect(context.domainNumber, 4);
    expect(context.domainId, 'd04');
    expect(context.competencyId, 'd04_c02');
    expect(context.subtopicId, 'd04_c02_s01');
    expect(context.hasFocusedWeakArea, isTrue);
  });

  test('weak fallback never claims a focused weak area', () {
    const context = LearningTwinPracticeContext(
      mode: LearningTwinPracticeMode.weakAreas,
      questionCount: 10,
      usedFallback: true,
    );

    expect(context.domainId, isNull);
    expect(context.hasFocusedWeakArea, isFalse);
  });

  test('invalid question count fails closed', () {
    expect(
      () => LearningTwinPracticeContext(
        mode: LearningTwinPracticeMode.randomQuiz,
        questionCount: 0,
      ),
      throwsA(isA<AssertionError>()),
    );
  });
}
