import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('L4A learner scenario model does not expose difficulty', () {
    final source = File(
      'lib/screens/lab/lab_scenario_catalog.dart',
    ).readAsStringSync();

    expect(source, contains('estimatedTime'));
    expect(source, contains('decisionCountLabel'));
    expect(source, contains('focusTags'));
    expect(source, isNot(contains('final String difficulty')));
    expect(source, isNot(contains("difficulty:")));
  });

  test('L4B briefing route exists between library and mode selection', () {
    final library = File(
      'lib/screens/lab/lab_library_screen.dart',
    ).readAsStringSync();
    final briefing = File(
      'lib/screens/lab/lab_scenario_briefing_screen.dart',
    ).readAsStringSync();

    expect(library, contains('LabScenarioBriefingScreen'));
    expect(briefing, contains('LabPlayerShellScreen'));
    expect(briefing, contains('lab-briefing-continue'));
  });

  test('L4D player uses learner decision hierarchy', () {
    final source = File(
      'lib/screens/lab/lab_reference_player_screen.dart',
    ).readAsStringSync();

    expect(source, contains('What is happening now'));
    expect(source, contains('What would you do?'));
    expect(source, contains('CONFIRM DECISION'));
  });

  test('L4E consequence is a separate presentation step', () {
    final source = File(
      'lib/screens/lab/lab_reference_player_screen.dart',
    ).readAsStringSync();

    expect(source, contains('lab-consequence-screen'));
    expect(source, contains('What happened next'));
    expect(source, contains('_pendingConsequence'));
    expect(source, contains('_continueAfterConsequence'));
  });

  test('L4E coaching is gated to Guided mode only', () {
    final source = File(
      'lib/screens/lab/lab_reference_player_screen.dart',
    ).readAsStringSync();

    expect(source, contains('if (widget.mode == LabMode.guided)'));
    expect(source, contains('Why this mattered'));
  });

  test('learner player does not render internal option quality', () {
    final source = File(
      'lib/screens/lab/lab_reference_player_screen.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('option.quality.name')));
    expect(source, isNot(contains('selectedOption.quality')));
  });
}
