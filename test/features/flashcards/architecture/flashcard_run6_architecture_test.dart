import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FC6 learner UI remains backend and persistence clean', () {
    final violations = <String>[];
    final roots = <Directory>[
      Directory('lib/features/flashcards/learner'),
      Directory('lib/screens/flashcards'),
    ];

    for (final root in roots) {
      for (final entity in root.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) {
          continue;
        }

        final source = entity.readAsStringSync();
        for (final forbidden in <String>[
          'package:cloud_firestore',
          'package:firebase_core',
          'package:firebase_auth',
          'package:supabase',
          'package:shared_preferences',
        ]) {
          if (source.contains(forbidden)) {
            violations.add('${entity.path}: $forbidden');
          }
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'FC6 UI must use frozen service/repository boundaries: '
          '${violations.join(', ')}',
    );
  });

  test('FC6 UI does not own review interval calculations', () {
    final root = Directory('lib/screens/flashcards');
    final violations = <String>[];

    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }

      final source = entity.readAsStringSync();
      for (final forbidden in <String>[
        'FlashcardIntervalPolicy',
        'intervalMinutes:',
        'dueAt:',
        'relearningIntervalMinutes',
      ]) {
        if (source.contains(forbidden)) {
          violations.add('${entity.path}: $forbidden');
        }
      }
    }

    expect(violations, isEmpty);
  });

  test('FC6 uses frozen HAP and MOT primitives', () {
    final reveal = File(
      'lib/screens/flashcards/widgets/flashcard_collectible_reveal_screen.dart',
    ).readAsStringSync();
    final card = File(
      'lib/screens/flashcards/widgets/flashcard_card_view.dart',
    ).readAsStringSync();
    final review = File(
      'lib/screens/flashcards/widgets/flashcard_review_player_screen.dart',
    ).readAsStringSync();

    expect(reveal, contains('Csp11Haptics'));
    expect(card, contains('Csp11FlipCard'));
    expect(review, contains('Csp11CompletionReveal'));
    expect(review, contains('Csp11Haptics'));
  });
}
