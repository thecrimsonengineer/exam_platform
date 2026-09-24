import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/features/flashcards/models/flashcard_source_provenance.dart';
import 'package:exam_platform/features/flashcards/registry/flashcard_source_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const inventoryPath =
      'assets/flashcards/production/d02/d02_c06/'
      'd02_c06_concept_inventory.v1.json';
  const sourcePath =
      'assets/flashcards/production/sources/fcp_source_registry.v1.json';

  Map<String, dynamic> readObject(String path) => Map<String, dynamic>.from(
    jsonDecode(File(path).readAsStringSync()) as Map,
  );

  test('D02 C06 starts at canonical competency placement', () {
    final inventory = readObject(inventoryPath);
    final placement = Map<String, dynamic>.from(inventory['placement'] as Map);

    expect(inventory['phase'], 'FCP-2F');
    expect(inventory['status'], 'resolved_inventory');
    expect(inventory['domainId'], 'd02');
    expect(inventory['competencyId'], 'd02_c06');
    expect(placement['domainId'], 'd02');
    expect(placement['competencyId'], 'd02_c06');
    expect(placement['topicId'], isNull);
    expect(placement['subtopicId'], isNull);
  });

  test('D02 C06 candidates are unique and source-backed', () {
    final inventory = readObject(inventoryPath);
    final candidates = (inventory['acceptedConcepts'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    expect(candidates.length, 12);
    expect(inventory['holds'], isEmpty);
    final slugs = candidates
        .map((item) => item['semanticSlug'] as String)
        .toList();
    final labels = candidates
        .map((item) => item['canonicalLabel'] as String)
        .toList();
    expect(slugs.toSet().length, slugs.length);
    expect(labels.toSet().length, labels.length);
    expect(slugs, contains('event_tree'));

    final sourceJson = readObject(sourcePath);
    final registry = FlashcardSourceRegistry.build(
      entries: (sourceJson['sources'] as List)
          .map(
            (item) => FlashcardSourceRegistryEntry.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );

    for (final concept in candidates) {
      final sourceIds = (concept['sourceIds'] as List).cast<String>();
      expect(sourceIds, isNotEmpty);
      expect(sourceIds.every(registry.contains), isTrue);
    }
  });

  test('D02 C06 preserves prior canonical boundaries', () {
    final inventory = readObject(inventoryPath);
    final refs = (inventory['crossCompetencyReferences'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    expect(refs.length, 3);
    expect(refs.map((item) => item['targetCompetencyId']).toSet(), <String>{
      'd01_c02',
      'd02_c04',
    });
  });
}
