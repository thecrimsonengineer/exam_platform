import 'package:exam_platform/features/exam_readiness/models/study_plan_block.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_execution_target.dart';
import 'package:exam_platform/features/exam_readiness/screens/study_plan_practice_session_screen.dart';
import 'package:exam_platform/models/question.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HOME-R6 planned practice launches existing QuizScreen flow', (
    tester,
  ) async {
    final target = const StudyPlanExecutionTarget(
      kind: StudyPlanExecutionTargetKind.practiceSession,
      blockId: 'home-r6-practice',
      blockType: StudyPlanBlockType.standardPractice,
      domainId: 'd04',
      domainNumber: 4,
      domainTitle: 'Emergency Management',
      competencyId: 'd04_c01',
      competencyTitle: 'Emergency response planning',
      plannedMinutes: 20,
      questionCount: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StudyPlanPracticeSessionScreen(
          target: target,
          isDarkMode: false,
          questionLoader: (_) async => <Question>[_question()],
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('Planned Practice'), findsWidgets);
    expect(find.textContaining('1 questions'), findsOneWidget);
    expect(find.textContaining('D04_C01'), findsOneWidget);
  });

  testWidgets('HOME-R6 practice preparation fails visibly and can retry', (
    tester,
  ) async {
    var calls = 0;
    final target = const StudyPlanExecutionTarget(
      kind: StudyPlanExecutionTargetKind.practiceSession,
      blockId: 'home-r6-practice',
      blockType: StudyPlanBlockType.standardPractice,
      domainId: 'd04',
      domainNumber: 4,
      domainTitle: 'Emergency Management',
      competencyId: 'd04_c01',
      competencyTitle: 'Emergency response planning',
      plannedMinutes: 20,
      questionCount: 5,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StudyPlanPracticeSessionScreen(
          target: target,
          isDarkMode: false,
          questionLoader: (_) async {
            calls++;
            throw StateError('No planned questions available.');
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('Planned practice unavailable'), findsWidgets);
    expect(find.textContaining('No planned questions available.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(calls, 2);
  });
}

Question _question() {
  return Question(
    id: 1,
    domain: 4,
    competencyId: 'd04_c01',
    subtopicId: '',
    topicId: '',
    quizId: '',
    contentPackageId: '',
    question: 'Which action should be taken first?',
    options: const <String>['A', 'B', 'C', 'D'],
    correctAnswer: 0,
    explanation: 'Explanation',
    bestAnswerRationale: 'Rationale',
    reference: 'Reference',
    difficulty: 'Hard',
    cognitiveLevel: 'application',
    questionType: 'scenario_mcq',
    status: 'published',
    version: 1,
    tags: const <String>['planned-practice'],
  );
}
