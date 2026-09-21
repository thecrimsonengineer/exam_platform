import 'dart:io';

import 'package:exam_platform/features/flashcards/flashcards.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FlashcardContentPackage package;

  setUpAll(() {
    package = const FlashcardPackageJsonCodec().decode(
      File(
        'assets/flashcards/run3/fc_reference_package.v1.json',
      ).readAsStringSync(),
    );
  });

  test('learner-ready package closes source and identity integrity matrix', () {
    final validation = const Fcq100Validator().validate(package);
    expect(
      validation.passed,
      isTrue,
      reason: validation.failedRules.map((rule) => rule.message).join('\n'),
    );

    final sourceIds = package.sources.map((source) => source.id).toSet();
    expect(sourceIds.length, package.sources.length);

    final conceptIds = package.concepts.map((concept) => concept.id).toList();
    final cardIds = package.cards.map((card) => card.id).toList();
    final cardConceptIds = package.cards.map((card) => card.conceptId).toList();

    expect(conceptIds.toSet().length, conceptIds.length);
    expect(cardIds.toSet().length, cardIds.length);
    expect(cardConceptIds.toSet().length, cardConceptIds.length);
    expect(cardConceptIds.toSet(), conceptIds.toSet());

    final registry = FlashcardSourceRegistry.build(entries: package.sources);
    for (final card in package.cards) {
      expect(
        () => FlashcardProvenanceValidator.validateCard(
          card: card,
          sourceRegistry: registry,
        ),
        returnsNormally,
      );
      final primary = card.sourceRefs
          .where((source) => source.primary)
          .toList();
      expect(primary, hasLength(1));
      expect(sourceIds, contains(primary.single.sourceId));
    }

    for (final mapping in package.questionMappings) {
      expect(conceptIds, contains(mapping.conceptId));
    }
    expect(
      package.questionMappings
          .map((mapping) => mapping.questionId)
          .toSet()
          .length,
      package.questionMappings.length,
    );
  });

  test('all FC runtime and validation roots remain Firebase Supabase free', () {
    final violations = <String>[];
    final roots = <Directory>[
      Directory('lib/features/flashcards'),
      Directory('lib/screens/flashcards'),
      Directory('lib/screens/admin/flashcards'),
    ];
    const forbidden = <String>[
      'package:cloud_firestore',
      'package:firebase_core',
      'package:firebase_auth',
      'package:firebase_storage',
      'package:supabase',
      'FirebaseFirestore',
      'FirebaseAuth.instance',
      'Supabase.instance',
    ];

    for (final root in roots) {
      expect(
        root.existsSync(),
        isTrue,
        reason: 'Missing FC root: ${root.path}',
      );
      for (final entity in root.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) {
          continue;
        }
        final source = entity.readAsStringSync();
        for (final token in forbidden) {
          if (source.contains(token)) {
            violations.add('${entity.path}: $token');
          }
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'FC must remain backend-independent: ${violations.join(', ')}',
    );
  });

  test('FC learner UI owns neither persistence nor scheduling policy', () {
    final violations = <String>[];
    final root = Directory('lib/screens/flashcards');

    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final source = entity.readAsStringSync();
      for (final token in const <String>[
        'package:shared_preferences',
        'FlashcardIntervalPolicy',
        'relearningIntervalMinutes',
        'intervalMinutes:',
        'dueAt:',
      ]) {
        if (source.contains(token)) {
          violations.add('${entity.path}: $token');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'FC UI must use frozen service/repository boundaries.',
    );
  });

  test('FC runtime contains no runtime LLM card-generation dependency', () {
    final violations = <String>[];
    final root = Directory('lib/features/flashcards');

    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final source = entity.readAsStringSync().toLowerCase();
      for (final token in const <String>[
        'package:openai',
        'generativemodel(',
        'generatecontent(',
        'chatcompletion',
      ]) {
        if (source.contains(token)) {
          violations.add('${entity.path}: $token');
        }
      }
    }

    expect(violations, isEmpty);
  });
}
