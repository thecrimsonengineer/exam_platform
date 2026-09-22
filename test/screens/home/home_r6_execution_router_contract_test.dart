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
      'widget.blockLauncher.resolve(block);',
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

    final resolveIndex = launchBody.indexOf(
      'widget.blockLauncher.resolve(block);',
    );
    final startIndex = launchBody.indexOf('widget.planService.startBlock(');
    expect(resolveIndex, greaterThanOrEqualTo(0));
    expect(startIndex, greaterThan(resolveIndex));
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

  test('HOME-R6 execution target model does not depend on navigation', () {
    final source = File(
      'lib/features/exam_readiness/models/study_plan_execution_target.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('package:flutter/')));
    expect(source, isNot(contains('/screens/')));
    expect(source, isNot(contains('/navigation/')));
  });

  test('HOME-R6 planned practice screen does not import the launcher', () {
    final source = File(
      'lib/features/exam_readiness/screens/study_plan_practice_session_screen.dart',
    ).readAsStringSync();

    expect(
      source,
      isNot(contains('navigation/study_plan_block_launcher.dart')),
      reason: 'Execution target must break the former launcher/screen cycle.',
    );
    expect(source, contains('models/study_plan_execution_target.dart'));
  });
}
