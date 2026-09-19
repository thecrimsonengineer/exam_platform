import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('Learning Twin destination action emits navigation haptic once', () {
    final source = read(
      'lib/features/learning_twin/integration/'
      'learning_twin_progress_guidance.dart',
    );

    expect(source, contains('Csp11Haptics.navigation()'));
    expect(source, contains('if (_actionConsumed || openDomain == null)'));
    expect(source, contains('_actionConsumed = true'));
    expect(source, contains('openDomain(binding.targetDomainId)'));

    final hapticIndex = source.indexOf('Csp11Haptics.navigation()');
    final openIndex = source.indexOf('openDomain(binding.targetDomainId)');
    expect(hapticIndex, greaterThanOrEqualTo(0));
    expect(openIndex, greaterThan(hapticIndex));
  });

  test('duplicate protection is centralized and bounded by event strength', () {
    final source = read('lib/services/haptics/csp11_haptic_service.dart');

    expect(source, contains('_lastEmittedAt'));
    expect(source, contains('_suppressionWindow(event)'));
    expect(source, contains('Duration(milliseconds: 80)'));
    expect(source, contains('Duration(milliseconds: 160)'));
    expect(source, contains('Duration(milliseconds: 260)'));
  });

  test('production driver is restricted to Android and iOS', () {
    final source = read('lib/services/haptics/csp11_haptic_driver.dart');

    expect(source, contains('if (kIsWeb)'));
    expect(source, contains('TargetPlatform.android'));
    expect(source, contains('TargetPlatform.iOS'));
    expect(source, contains('TargetPlatform.windows'));
    expect(source, contains('Future<void>.value()'));
  });

  test('diagnostics exist without joining normal learner navigation', () {
    final diagnostics = read(
      'lib/screens/admin/haptic_diagnostics_screen.dart',
    );
    final navigation = read('lib/screens/navigation/bottom_navigation.dart');

    expect(diagnostics, contains('Haptic diagnostics'));
    expect(diagnostics, contains('Csp11HapticEvent.values'));
    expect(diagnostics, contains('Csp11Haptics.trigger(event)'));
    expect(navigation, isNot(contains('HapticDiagnosticsScreen')));
    expect(navigation, isNot(contains('/admin/haptic-diagnostics')));
  });

  test('Flashcards remain intentionally silent without a review engine', () {
    for (final path in <String>[
      'lib/screens/flashcards/flashcards_screen.dart',
      'lib/screens/flashcards/flashcards_screen_dark.dart',
    ]) {
      final source = read(path);
      expect(source, contains('No flashcard decks are published yet.'));
      expect(source, isNot(contains('Csp11Haptics.')));
    }
  });
}
