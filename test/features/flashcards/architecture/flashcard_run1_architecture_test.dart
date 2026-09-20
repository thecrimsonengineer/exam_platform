import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FC foundation has no Firebase or Supabase imports', () {
    final violations = <String>[];
    final root = Directory('lib/features/flashcards');

    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }

      final source = entity.readAsStringSync();
      for (final forbidden in <String>[
        "package:cloud_firestore",
        "package:firebase_core",
        "package:firebase_auth",
        "package:supabase",
      ]) {
        if (source.contains(forbidden)) {
          violations.add('${entity.path}: $forbidden');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'FC Run 1 must remain zero-backend: ${violations.join(', ')}',
    );
  });

  test('Question model does not embed Flashcard content', () {
    final source = File('lib/models/question.dart').readAsStringSync();

    expect(source, isNot(contains('Flashcard')));
    expect(source, isNot(contains('flashcardId')));
  });

  test('Run 1 lifecycle deliberately excludes cloud published state', () {
    final source = File(
      'lib/features/flashcards/models/flashcard_lifecycle.dart',
    ).readAsStringSync();

    expect(source, contains('candidate'));
    expect(source, contains('review'));
    expect(source, contains('validated'));
    expect(source, contains('bundled'));
    expect(source, isNot(contains('published')));
  });

  test('front-facing contract exposes no question card type', () {
    final source = File(
      'lib/features/flashcards/models/flashcard_type.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('question')));
    expect(source, isNot(contains('mcq')));
  });
}
