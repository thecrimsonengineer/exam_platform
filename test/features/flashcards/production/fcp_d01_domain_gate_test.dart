import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/features/flashcards/io/flashcard_package_json_codec.dart';
import 'package:exam_platform/features/flashcards/validation/flashcard_duplicate_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const domainRoot = 'assets/flashcards/production/d01';

  List<File> packages() =>
      Directory(domainRoot)
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('_flashcards_v1.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('D01 contains exactly seven competency packages', () {
    final files = packages();
    expect(files.length, 7);

    final decoded = files
        .map(
          (file) =>
              const FlashcardPackageJsonCodec().decode(file.readAsStringSync()),
        )
        .toList();

    expect(decoded.map((item) => item.deck.competencyId).toList(), <String>[
      'd01_c01',
      'd01_c02',
      'd01_c03',
      'd01_c04',
      'd01_c05',
      'd01_c06',
      'd01_c07',
    ]);
  });

  test('D01 production IDs are globally unique', () {
    final decoded = packages()
        .map(
          (file) =>
              const FlashcardPackageJsonCodec().decode(file.readAsStringSync()),
        )
        .toList();

    final deckIds = decoded.map((item) => item.deck.id).toList();
    final conceptIds = decoded
        .expand((item) => item.concepts)
        .map((x) => x.id)
        .toList();
    final cardIds = decoded
        .expand((item) => item.cards)
        .map((x) => x.id)
        .toList();

    expect(deckIds.toSet().length, deckIds.length);
    expect(conceptIds.toSet().length, conceptIds.length);
    expect(cardIds.toSet().length, cardIds.length);
  });

  test('D01 canonical labels and aliases have no cross-package collision', () {
    final owners = <String, Set<String>>{};

    for (final file in packages()) {
      final package = const FlashcardPackageJsonCodec().decode(
        file.readAsStringSync(),
      );
      for (final concept in package.concepts) {
        for (final value in <String>[
          concept.canonicalLabel,
          ...concept.aliases,
        ]) {
          final normalized = FlashcardDuplicateDetector.normalize(value);
          if (normalized.isEmpty) continue;
          owners.putIfAbsent(normalized, () => <String>{}).add(concept.id);
        }
      }
    }

    final collisions = owners.entries
        .where((entry) => entry.value.length > 1)
        .map((entry) => '${entry.key}: ${entry.value.join(', ')}')
        .toList();

    expect(collisions, isEmpty, reason: collisions.join('\n'));
  });

  test('D01 inventories are fully resolved with no holds', () {
    final files =
        Directory(domainRoot)
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('_concept_inventory.v1.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    expect(files.length, 7);

    for (final file in files) {
      final json = Map<String, dynamic>.from(
        jsonDecode(file.readAsStringSync()) as Map,
      );
      expect(json['status'], 'resolved_inventory', reason: file.path);
      expect(json['holds'], isEmpty, reason: file.path);
      expect(json['acceptedConcepts'], isNotEmpty, reason: file.path);
    }
  });

  test('D01 closed competencies have complete report bundles', () {
    const requiredSuffixes = <String>[
      '_fcq100_report.json',
      '_duplicate_report.json',
      '_source_report.json',
      '_coverage_report.json',
      '_validation_summary.md',
    ];

    for (var competency = 1; competency <= 7; competency++) {
      final id = 'd01_c${competency.toString().padLeft(2, '0')}';
      final reportDir = Directory(
        'assets/flashcards/production/reports/competency/$id',
      );

      expect(reportDir.existsSync(), isTrue, reason: id);
      final names = reportDir
          .listSync()
          .whereType<File>()
          .map((file) => file.path.split(Platform.pathSeparator).last)
          .toSet();

      for (final suffix in requiredSuffixes) {
        expect(
          names.contains('$id$suffix'),
          isTrue,
          reason: '$id missing $suffix',
        );
      }
    }
  });

  test('D01 resolved card count is 78', () {
    final total = packages().fold<int>(
      0,
      (sum, file) =>
          sum +
          const FlashcardPackageJsonCodec()
              .decode(file.readAsStringSync())
              .cards
              .length,
    );
    expect(total, 78);
  });
}
