import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/features/flashcards/models/flashcard_source_provenance.dart';
import 'package:exam_platform/features/flashcards/registry/flashcard_source_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const inventoryPath =
      'assets/flashcards/production/d01/d01_c02/'
      'd01_c02_concept_inventory.v1.json';
  const sourcePath =
      'assets/flashcards/production/sources/fcp_source_registry.v1.json';

  Map<String, dynamic> readObject(String path) {
    return Map<String, dynamic>.from(
      jsonDecode(File(path).readAsStringSync()) as Map,
    );
  }

  test('D01 C02 starts as a candidate inventory at competency placement', () {
    final inventory = readObject(inventoryPath);
    final placement = Map<String, dynamic>.from(inventory['placement'] as Map);

    expect(inventory['phase'], 'FCP-1B');
    expect(inventory['status'], 'candidate_inventory');
    expect(inventory['domainId'], 'd01');
    expect(inventory['competencyId'], 'd01_c02');
    expect(placement['domainId'], 'd01');
    expect(placement['competencyId'], 'd01_c02');
    expect(placement['topicId'], isNull);
    expect(placement['subtopicId'], isNull);
  });

  test('D01 C02 candidate concepts are unique and source-backed', () {
    final inventory = readObject(inventoryPath);
    final candidates = (inventory['candidateConcepts'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    final slugs =
        candidates.map((item) => item['semanticSlug'] as String).toList();
    final labels =
        candidates.map((item) => item['canonicalLabel'] as String).toList();

    expect(candidates.length, 11);
    expect(slugs.toSet().length, slugs.length);
    expect(labels.toSet().length, labels.length);
    expect(candidates.every((item) => item['decision'] == 'CANDIDATE'), isTrue);

    final sourceJson = readObject(sourcePath);
    final entries = (sourceJson['sources'] as List)
        .map(
          (item) => FlashcardSourceRegistryEntry.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
    final registry = FlashcardSourceRegistry.build(entries: entries);

    for (final candidate in candidates) {
      final sourceIds = (candidate['sourceIds'] as List).cast<String>();
      expect(sourceIds, isNotEmpty);
      expect(sourceIds.every(registry.contains), isTrue);
    }
  });

  test('D01 C02 defers the canonical MOC card to d02_c05', () {
    final inventory = readObject(inventoryPath);
    final references = (inventory['crossCompetencyReferences'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    expect(references.length, 1);
    expect(references.single['semanticSlug'], 'management_of_change');
    expect(
      references.single['decision'],
      'DEFER_TO_CANONICAL_COMPETENCY',
    );
    expect(references.single['targetCompetencyId'], 'd02_c05');
  });
}
