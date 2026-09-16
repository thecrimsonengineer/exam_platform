import 'package:exam_platform/features/learning_twin/coaching/learning_twin_practice_context.dart';
import 'package:exam_platform/features/learning_twin/coaching/learning_twin_practice_result_context.dart';
import 'package:exam_platform/features/learning_twin/integration/learning_twin_post_practice_guidance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const resultContext = LearningTwinPracticeResultContext(
    practiceContext: LearningTwinPracticeContext(
      mode: LearningTwinPracticeMode.randomQuiz,
      questionCount: 10,
    ),
    score: 8,
    totalQuestions: 10,
  );

  testWidgets('post-practice guidance renders deterministic result review', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LearningTwinPostPracticeGuidance(resultContext: resultContext),
        ),
      ),
    );

    expect(
      find.byKey(
        const ValueKey<String>('learning-twin-post-practice-guidance'),
      ),
      findsOneWidget,
    );
    expect(find.text('Strong practice result'), findsOneWidget);
  });

  testWidgets('post-practice guidance can be dismissed', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LearningTwinPostPracticeGuidance(resultContext: resultContext),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Dismiss guidance'));
    await tester.pump();

    expect(
      find.byKey(
        const ValueKey<String>('learning-twin-post-practice-guidance'),
      ),
      findsNothing,
    );
  });

  testWidgets('timed exam suppression remains fail-closed at M3', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LearningTwinPostPracticeGuidance(
            resultContext: resultContext,
            isTimedExamActive: true,
          ),
        ),
      ),
    );

    expect(
      find.byKey(
        const ValueKey<String>('learning-twin-post-practice-guidance'),
      ),
      findsNothing,
    );
  });

  testWidgets('guidance inherits a supplied dark theme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: Theme(
          data: ThemeData.dark(),
          child: const Scaffold(
            body: LearningTwinPostPracticeGuidance(
              resultContext: resultContext,
            ),
          ),
        ),
      ),
    );

    final cardContext = tester.element(
      find.byKey(
        const ValueKey<String>('learning-twin-post-practice-guidance'),
      ),
    );

    expect(Theme.of(cardContext).brightness, Brightness.dark);
  });
}
