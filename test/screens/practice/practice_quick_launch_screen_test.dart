import 'dart:async';

import 'package:exam_platform/models/question.dart';
import 'package:exam_platform/screens/practice/practice_quick_launch_screen.dart';
import 'package:exam_platform/services/practice/practice_mode_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Question _question() {
  return Question(
    id: 1,
    domain: 1,
    competencyId: 'd01_c01',
    subtopicId: 'd01_c01_st01',
    topicId: 'd01_c01_t01',
    quizId: 'quiz_01',
    contentPackageId: 'content_01',
    question:
        'A safety professional reviews a workplace scenario and selects the strongest practical control.',
    options: const [
      'Control the hazard at source.',
      'Rely only on worker attention.',
      'Delay action.',
      'Use a weaker administrative option.',
    ],
    correctAnswer: 0,
    explanation: 'Source control provides the strongest practical protection.',
    reference: 'CSP11 reference',
    difficulty: 'Hard',
    cognitiveLevel: 'Application',
    questionType: 'scenario_mcq',
    status: 'published',
    version: 1,
    tags: const ['practice', 'control'],
  );
}

PracticeSessionPlan _plan(PracticeMode mode) {
  return PracticeSessionPlan(
    mode: mode,
    title: mode == PracticeMode.dailyChallenge
        ? 'Daily Challenge'
        : 'Random Quiz',
    questions: [_question()],
    domainNumber: 0,
    notice: 'Published practice session.',
    usedFallback: false,
  );
}

void main() {
  testWidgets('quick launch loading surface renders in dark mode', (
    tester,
  ) async {
    final completer = Completer<PracticeSessionPlan>();

    await tester.pumpWidget(
      MaterialApp(
        home: PracticeQuickLaunchScreen(
          mode: PracticeMode.dailyChallenge,
          isDarkMode: true,
          planBuilder: (_) => completer.future,
          sessionBuilder: (plan) =>
              Scaffold(body: Center(child: Text(plan.title))),
        ),
      ),
    );

    await tester.pump();

    expect(
      find.byKey(const ValueKey('practice-quick-loading')),
      findsOneWidget,
    );
    expect(find.text('Daily Challenge'), findsWidgets);
    expect(tester.takeException(), isNull);

    completer.complete(_plan(PracticeMode.dailyChallenge));
    await tester.pumpAndSettle();

    expect(find.text('Daily Challenge'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('quick launch session handoff renders in light mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PracticeQuickLaunchScreen(
          mode: PracticeMode.randomQuiz,
          isDarkMode: false,
          planBuilder: (_) async => _plan(PracticeMode.randomQuiz),
          sessionBuilder: (plan) => Scaffold(
            body: Center(
              child: Text(
                '${plan.title}:${plan.questionCount}',
                key: const ValueKey('test-practice-session'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('test-practice-session')), findsOneWidget);
    expect(find.text('Random Quiz:1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
