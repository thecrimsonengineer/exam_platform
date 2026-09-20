import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('LAB motion follows deterministic runtime state', () {
    final source = read('lib/screens/lab/lab_reference_player_screen.dart');

    expect(source, contains('Csp11StateSwitcher('));
    expect(source, contains('_motionStateKey'));
    expect(source, contains('lab-motion-decision-'));
    expect(source, contains('lab-motion-consequence-'));
    expect(source, contains('lab-motion-completion-'));

    final commitIndex = source.indexOf('await _engine.commitDecision(');
    final consequenceStateIndex = source.indexOf(
      '_pendingConsequence = _PendingConsequence(',
    );
    expect(commitIndex, greaterThanOrEqualTo(0));
    expect(consequenceStateIndex, greaterThan(commitIndex));
  });

  test('LAB selection and accepted-decision lock use central motion tokens', () {
    final source = read('lib/screens/lab/lab_reference_player_screen.dart');

    expect(source, contains('final lockedOut = _busy && !selected;'));
    expect(source, contains('AnimatedOpacity('));
    expect(source, contains('opacity: lockedOut ? 0.48 : 1'));
    expect(source, contains('AnimatedScale('));
    expect(source, contains('Csp11MotionDuration.quick'));
    expect(source, contains('Csp11MotionCurve.standard'));
    expect(source, contains('Csp11MotionPreferences.reduced(context)'));
  });

  test('LAB endings celebrate only safe completion and keep debrief centralized', () {
    final source = read('lib/screens/lab/lab_reference_player_screen.dart');

    expect(
      source,
      contains("final celebratory = session.endingId == 'safe_completion';"),
    );
    expect(source, contains('Csp11CompletionReveal('));
    expect(source, contains('celebratory: celebratory'));
    expect(source, contains('Csp11Route.detail<void>('));
    expect(source, isNot(contains("session.endingId == 'critical_failure'")));
  });

  test('LAB mode entry uses the central route system', () {
    final source = read('lib/screens/lab/lab_player_shell_screen.dart');

    expect(source, contains('Csp11Route.forward<void>('));
    expect(source, isNot(contains('MaterialPageRoute<void>(')));
  });

  test('Learning Twin motion is keyed to deterministic message identity', () {
    for (final path in <String>[
      'lib/features/learning_twin/integration/learning_twin_progress_guidance.dart',
      'lib/features/learning_twin/integration/learning_twin_post_practice_guidance.dart',
      'lib/features/learning_twin/integration/learning_twin_pre_practice_guidance.dart',
      'lib/features/learning_twin/integration/learning_twin_study_hub_guidance.dart',
    ]) {
      final source = read(path);
      expect(source, contains('LearningTwinMotionReveal('));
      expect(source, contains('motionKey: message.id'));
      expect(
        source,
        contains('message.state == LearningTwinState.celebrate'),
      );
    }
  });

  test('future Flashcard motion foundation does not invent review behavior', () {
    final flip = read('lib/widgets/motion/csp11_flip_card.dart');

    expect(flip, contains('class Csp11FlipCard'));
    expect(flip, contains('Matrix4.rotationY'));
    expect(flip, contains('Csp11MotionPreferences.reduced(context)'));

    for (final path in <String>[
      'lib/screens/flashcards/flashcards_screen.dart',
      'lib/screens/flashcards/flashcards_screen_dark.dart',
    ]) {
      final source = read(path);
      expect(source, contains('No flashcard decks are published yet.'));
      expect(source, isNot(contains('Csp11FlipCard')));
    }
  });

  test('Run 3 motion foundation remains Firebase and Supabase free', () {
    for (final path in <String>[
      'lib/widgets/motion/csp11_completion_reveal.dart',
      'lib/widgets/motion/csp11_flip_card.dart',
      'lib/features/learning_twin/ui/learning_twin_motion_reveal.dart',
    ]) {
      final source = read(path);
      expect(source, isNot(contains('cloud_firestore')));
      expect(source, isNot(contains('firebase_')));
      expect(source, isNot(contains('supabase')));
    }
  });
}
