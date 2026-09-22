import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HOME-R6 Today Plan launches through one shared block launcher', () {
    final source = File(
      'lib/features/exam_readiness/screens/todays_plan_screen.dart',
    ).readAsStringSync();

    for (final required in <String>[
      'final StudyPlanBlockLauncher blockLauncher;',
      'Future<void> _launchBlock(StudyPlanBlock block)',
      'await widget.blockLauncher.launch(',
      'onLaunch: () => _launchBlock(block)',
      'Continue task',
      'Finish planned task',
      'Start task',
    ]) {
      expect(source, contains(required));
    }

    expect(
      source,
      isNot(contains('FlashcardsScreen(')),
      reason: 'R6 must not pretend competency Flashcards exist.',
    );
  });

  test('HOME-R6 route-open cannot complete a planned task', () {
    final source = File(
      'lib/features/exam_readiness/screens/todays_plan_screen.dart',
    ).readAsStringSync();

    final launchStart = source.indexOf(
      'Future<void> _launchBlock(StudyPlanBlock block)',
    );
    final completionStart = source.indexOf(
      'Future<void> _complete(String blockId)',
    );

    expect(launchStart, greaterThanOrEqualTo(0));
    expect(completionStart, greaterThan(launchStart));

    final launchBody = source.substring(launchStart, completionStart);
    expect(launchBody, isNot(contains('completeBlock(')));
    expect(launchBody, isNot(contains('_complete(')));
  });

  test('HOME-R6 practice uses protected quiz scope, not global initialization', () {
    final source = File(
      'lib/features/exam_readiness/screens/study_plan_practice_session_screen.dart',
    ).readAsStringSync();

    expect(source, contains('await service.prepareScope('));
    expect(source, contains('service.buildQuiz('));
    expect(source, contains('UltraHardQuestionContract.classificationTag'));
    expect(source, isNot(contains('service.initialize(')));
    expect(source, isNot(contains('StudentQuizBuilder')));
  });
}
