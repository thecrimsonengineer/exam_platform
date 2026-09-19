import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test(
    'Quiz haptics follow selection, validation, result and navigation states',
    () {
      final source = read('lib/screens/courses/csp/quiz/quiz_screen.dart');

    expect(source, contains('Csp11Haptics.selection()'));
    expect(source, contains('quizController.selectedAnswer == index'));
    expect(source, contains('quizController.selectedAnswer == null'));
    expect(source, contains('Csp11Haptics.error()'));
    expect(source, contains('_emitQuizResultHaptics(correct)'));
    expect(source, contains('Csp11Haptics.confirm()'));
    expect(source, contains('Csp11Haptics.success()'));
    expect(source, contains('Csp11Haptics.warning()'));
    expect(source, contains('Csp11Haptics.navigation()'));
      expect(source, contains('Csp11Haptics.completion()'));
    },
  );

  test('LAB haptics fire only around accepted deterministic decisions', () {
    final source = read('lib/screens/lab/lab_reference_player_screen.dart');

    final commitIndex = source.indexOf('await _engine.commitDecision(');
    final acceptedHapticIndex = source.indexOf(
      '_emitAcceptedDecisionHaptics(selectedOption.quality)',
    );

    expect(commitIndex, greaterThanOrEqualTo(0));
    expect(acceptedHapticIndex, greaterThan(commitIndex));

    expect(source, contains('_selectDecisionOption'));
    expect(source, contains('Csp11Haptics.selection()'));
    expect(source, contains('Csp11Haptics.criticalDecision()'));

    expect(source, contains('case LabDecisionQuality.optimal:'));
    expect(source, contains('Csp11Haptics.success()'));
    expect(source, contains('case LabDecisionQuality.defensible:'));
    expect(source, contains('case LabDecisionQuality.weak:'));
    expect(source, contains('Csp11Haptics.warning()'));
    expect(source, contains('case LabDecisionQuality.critical:'));
    expect(source, contains('Csp11Haptics.error()'));

    expect(source, contains('LabSessionStatus.completed'));
    expect(source, contains('Csp11Haptics.completion()'));
  });

  test(
    'Subtopic completion emits completion feedback after local persistence',
    () {
      for (final path in <String>[
      'lib/screens/courses/csp/study_subtopic_screen.dart',
      'lib/screens/courses/csp/study_subtopic_screen_dark.dart',
    ]) {
      final source = read(path);
      final persistenceIndex = source.indexOf(
        'await _progressService.completeSubtopic(',
      );
      final hapticIndex = source.indexOf('await Csp11Haptics.completion();');

      expect(persistenceIndex, greaterThanOrEqualTo(0));
        expect(hapticIndex, greaterThan(persistenceIndex));
      }
    },
  );

  test('Flashcards remain silent until a real review engine exists', () {
    for (final path in <String>[
      'lib/screens/flashcards/flashcards_screen.dart',
      'lib/screens/flashcards/flashcards_screen_dark.dart',
    ]) {
      final source = read(path);

      expect(source, contains('No flashcard decks are published yet.'));
      expect(source, isNot(contains('Csp11Haptics.')));
      expect(source, isNot(contains('HapticFeedback.')));
    }
  });
}
