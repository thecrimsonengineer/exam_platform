import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FC7 external surfaces depend on integration contracts only', () {
    final files = <File>[
      File('lib/screens/courses/csp/quiz/quiz_screen.dart'),
      File('lib/screens/courses/csp/domain_screen.dart'),
      File('lib/screens/courses/csp/domain_screen_dark.dart'),
      File('lib/widgets/csp/study_content/study_content_renderer.dart'),
      File('lib/widgets/csp/study_content/study_content_renderer_dark.dart'),
      File('lib/screens/courses/csp/study_subtopic_screen.dart'),
      File('lib/screens/courses/csp/study_subtopic_screen_dark.dart'),
    ];
    final violations = <String>[];

    for (final file in files) {
      final source = file.readAsStringSync();
      for (final forbidden in <String>[
        'flashcard_collection_repository.dart',
        'flashcard_unlock_service.dart',
        'flashcard_review_repository.dart',
        'flashcard_interval_policy.dart',
        'flashcard_review_session_builder.dart',
        'package:shared_preferences',
        'package:cloud_firestore',
        'package:firebase_core',
        'package:supabase',
      ]) {
        if (source.contains(forbidden)) {
          violations.add('${file.path}: $forbidden');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'FC7 integrations must use the façade/UI entry contracts only: '
          '${violations.join(', ')}',
    );
  });

  test('Learning Twin Flashcard guidance consumes sanitized DTO only', () {
    final source = File(
      'lib/features/learning_twin/integration/'
      'learning_twin_flashcard_guidance.dart',
    ).readAsStringSync();

    expect(source, contains('flashcard_integration_models.dart'));
    expect(source, isNot(contains('flashcard_integration_service.dart')));
    expect(source, isNot(contains('flashcard_package_repository.dart')));
    expect(source, isNot(contains('FlashcardOwnership')));
    expect(source, isNot(contains('FlashcardReviewState')));
    expect(source, isNot(contains('Question')));
    expect(source, isNot(contains('canonicalUrl')));
  });

  test('Quiz reward is rendered only from committed integration result', () {
    final quiz = File(
      'lib/screens/courses/csp/quiz/quiz_screen.dart',
    ).readAsStringSync();

    expect(quiz, contains('recordQuestionCompletion('));
    expect(quiz, contains('result.hasReward'));
    expect(quiz, contains('FlashcardQuizRewardCard'));
    expect(quiz, contains('Flashcard integration must never interrupt'));
  });

  test('StudyContent exposes Domain Competency and Subtopic review scopes', () {
    final domain = File(
      'lib/screens/courses/csp/domain_screen.dart',
    ).readAsStringSync();
    final competency = File(
      'lib/widgets/csp/study_content/study_content_renderer.dart',
    ).readAsStringSync();
    final subtopic = File(
      'lib/screens/courses/csp/study_subtopic_screen.dart',
    ).readAsStringSync();

    expect(domain, contains('FlashcardReviewScope(domainId: _domain.id)'));
    expect(competency, contains('competencyId: widget.content.competencyId'));
    expect(subtopic, contains('subtopicId: subtopic.id'));
  });

  test('FC7 Flashcard integration core remains Firebase/Supabase free', () {
    final root = Directory('lib/features/flashcards/integration');
    final violations = <String>[];

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
      ]) {
        if (source.contains(forbidden)) {
          violations.add('${entity.path}: $forbidden');
        }
      }
    }

    expect(violations, isEmpty);
  });
}
