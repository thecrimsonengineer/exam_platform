import 'package:exam_platform/features/learning_twin/coaching/learning_twin_practice_context.dart';
import 'package:exam_platform/features/learning_twin/integration/learning_twin_pre_practice_guidance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'pre-practice guidance is non-blocking and quiz remains mounted',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LearningTwinPracticeSessionHost(
            practiceContext: LearningTwinPracticeContext(
              mode: LearningTwinPracticeMode.dailyChallenge,
              questionCount: 5,
            ),
            child: Scaffold(body: Center(child: Text('QUIZ BODY'))),
          ),
        ),
      );

      expect(
        find.byKey(
          const ValueKey<String>('learning-twin-pre-practice-guidance'),
        ),
        findsOneWidget,
      );
      expect(find.text('Today’s practice cue'), findsOneWidget);
      expect(find.text('QUIZ BODY'), findsOneWidget);
    },
  );

  testWidgets('dismiss removes guidance but leaves practice session mounted', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LearningTwinPracticeSessionHost(
          practiceContext: LearningTwinPracticeContext(
            mode: LearningTwinPracticeMode.randomQuiz,
            questionCount: 10,
          ),
          child: Scaffold(body: Center(child: Text('QUIZ BODY'))),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Dismiss guidance'));
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('learning-twin-pre-practice-guidance')),
      findsNothing,
    );
    expect(find.text('QUIZ BODY'), findsOneWidget);
  });

  testWidgets('timed exam suppression remains owned by M3 decision layer', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LearningTwinPracticeSessionHost(
          practiceContext: LearningTwinPracticeContext(
            mode: LearningTwinPracticeMode.dailyChallenge,
            questionCount: 5,
          ),
          isTimedExamActive: true,
          child: Scaffold(body: Center(child: Text('QUIZ BODY'))),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('learning-twin-pre-practice-guidance')),
      findsNothing,
    );
    expect(find.text('QUIZ BODY'), findsOneWidget);
  });

  testWidgets('explicit session theme reaches Custom Quiz Twin route', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: LearningTwinPracticeSessionHost(
          theme: ThemeData.dark(),
          practiceContext: const LearningTwinPracticeContext(
            mode: LearningTwinPracticeMode.customQuiz,
            questionCount: 5,
          ),
          child: Builder(
            builder: (context) => Scaffold(
              body: Text('CHILD THEME: ' + Theme.of(context).brightness.name),
            ),
          ),
        ),
      ),
    );

    final twinCardContext = tester.element(
      find.byKey(const ValueKey<String>('learning-twin-pre-practice-guidance')),
    );

    expect(Theme.of(twinCardContext).brightness, Brightness.dark);
    expect(find.text('CHILD THEME: dark'), findsOneWidget);
  });
}
