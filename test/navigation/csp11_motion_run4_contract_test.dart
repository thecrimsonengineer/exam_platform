import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('root theme transition uses central MOT tokens', () {
    final source = read('lib/main.dart');

    expect(
      source,
      contains('themeAnimationDuration: Csp11MotionDuration.quick'),
    );
    expect(source, contains('themeAnimationCurve: Csp11MotionCurve.standard'));
  });

  test(
    'Quiz passive loading empty and error states use status reveal only',
    () {
      final source = read('lib/screens/courses/csp/quiz/quiz_screen.dart');

      expect(source, contains('Csp11StatusKind.loading'));
      expect(source, contains('Csp11StatusKind.empty'));
      expect(source, contains('Csp11StatusKind.error'));

      final passiveStart = source.indexOf('if (_isInitializing)');
      final activeStart = source.indexOf(
        'final Question question = quizController.currentQuestionData;',
      );
      final passiveSection = source.substring(passiveStart, activeStart);

      expect(passiveSection, isNot(contains('Csp11Haptics.')));
    },
  );

  test('LAB passive loading and errors remain haptically silent', () {
    final source = read('lib/screens/lab/lab_reference_player_screen.dart');

    expect(source, contains('Csp11StatusKind.loading'));
    expect(source, contains('Csp11StatusKind.error'));

    final buildStart = source.indexOf('Widget build(BuildContext context)');
    final motionKeyStart = source.indexOf('String _motionStateKey');
    final buildSection = source.substring(buildStart, motionKeyStart);

    expect(buildSection, isNot(contains('Csp11Haptics.')));
  });

  test('Flashcards motion follows implemented FC learner states', () {
    final source = read('lib/screens/flashcards/flashcards_screen.dart');
    final dark = read('lib/screens/flashcards/flashcards_screen_dark.dart');

    expect(source, contains('Csp11StatusKind.loading'));
    expect(source, contains('Csp11StatusKind.error'));
    expect(source, contains('Csp11StaggeredReveal('));
    expect(source, contains('FlashcardReviewPlayerScreen('));
    expect(source, isNot(contains('Csp11FlipCard')));

    expect(dark, contains('return FlashcardsScreen(controller: controller);'));
    expect(dark, isNot(contains('Csp11FlipCard')));
  });

  test('motion and haptics share the same semantic learner transitions', () {
    final navigation = read('lib/screens/navigation/bottom_navigation.dart');
    final navHandlerStart = navigation.indexOf(
      'void _selectBottomNavigationTab(int index)',
    );
    final navHandlerEnd = navigation.indexOf(
      '@override\n  Widget build',
      navHandlerStart,
    );
    final navHandler = navigation.substring(navHandlerStart, navHandlerEnd);

    expect(
      navHandler.indexOf('Csp11Haptics.navigation()'),
      lessThan(navHandler.indexOf('_selectTab(index)')),
    );

    final quiz = read('lib/screens/courses/csp/quiz/quiz_screen.dart');
    final selectStart = quiz.indexOf('void _selectAnswer(int index)');
    final submitStart = quiz.indexOf('void _submitAnswer()', selectStart);
    final selectSection = quiz.substring(selectStart, submitStart);

    expect(selectSection, contains('setState(()'));
    expect(selectSection, contains('Csp11Haptics.selection()'));

    final submitEnd = quiz.indexOf(
      'Future<void> _emitQuizResultHaptics',
      submitStart,
    );
    final submitSection = quiz.substring(submitStart, submitEnd);
    expect(submitSection, contains('quizController.submitAnswer()'));
    expect(submitSection, contains('_emitQuizResultHaptics(correct)'));

    final lab = read('lib/screens/lab/lab_reference_player_screen.dart');
    final commitIndex = lab.indexOf('await _engine.commitDecision(');
    final stateIndex = lab.indexOf(
      '_pendingConsequence = _PendingConsequence(',
      commitIndex,
    );
    final hapticIndex = lab.indexOf(
      '_emitAcceptedDecisionHaptics(selectedOption.quality)',
      stateIndex,
    );

    expect(commitIndex, greaterThanOrEqualTo(0));
    expect(stateIndex, greaterThan(commitIndex));
    expect(hapticIndex, greaterThan(stateIndex));
  });

  test('state owners remain outside motion wrappers', () {
    final navigation = read('lib/screens/navigation/bottom_navigation.dart');
    expect(navigation, contains('final Map<int, Widget> _lightScreens'));
    expect(navigation, contains('final Map<int, Widget> _darkScreens'));
    expect(navigation, contains('IndexedStack('));

    final lab = read('lib/screens/lab/lab_reference_player_screen.dart');
    expect(lab, contains('LabSession? _session;'));
    expect(lab, contains('Csp11SlideFade('));

    final twin = read(
      'lib/features/learning_twin/integration/learning_twin_progress_guidance.dart',
    );
    expect(twin, contains('late LearningTwinSessionState _sessionState;'));
    expect(twin, contains('motionKey: message.id'));
  });

  test('Motion Diagnostics is admin-only and locally routed', () {
    final admin = read('lib/screens/admin/admin_home_screen.dart');

    expect(admin, contains('Motion Diagnostics'));
    expect(admin, contains('MotionDiagnosticsScreen'));
    expect(admin, contains('Csp11Route.detail<void>('));

    final learnerNav = read('lib/screens/navigation/bottom_navigation.dart');
    expect(learnerNav, isNot(contains('MotionDiagnosticsScreen')));
  });
}
