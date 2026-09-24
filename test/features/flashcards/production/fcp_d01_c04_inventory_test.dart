import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/features/flashcards/models/flashcard_source_provenance.dart';
import 'package:exam_platform/features/flashcards/registry/flashcard_source_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const inventoryPath =
      'assets/flashcards/production/d01/d01_c04/'
      'd01_c04_concept_inventory.v1.json';
  const sourcePath =
      'assets/flashcards/production/sources/fcp_source_registry.v1.json';

  Map<String, dynamic> readObject(String path) => Map<String, dynamic>.from(
    jsonDecode(File(path).readAsStringSync()) as Map,
  );

  test('D01 C04 starts at canonical competency placement', () {
    final inventory = readObject(inventoryPath);
    final placement = Map<String, dynamic>.from(inventory['placement'] as Map);
    expect(inventory['phase'], 'FCP-1D');
    expect(inventory['status'], 'candidate_inventory');
    expect(inventory['domainId'], 'd01');
    expect(inventory['competencyId'], 'd01_c04');
    expect(placement['domainId'], 'd01');
    expect(placement['competencyId'], 'd01_c04');
    expect(placement['topicId'], isNull);
    expect(placement['subtopicId'], isNull);
  });

  test('D01 C04 candidate concepts are unique and source-backed', () {
    final inventory = readObject(inventoryPath);
    final candidates = (inventory['candidateConcepts'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    expect(candidates.length, 9);
    final slugs = candidates
        .map((item) => item['semanticSlug'] as String)
        .toList();
    final labels = candidates
        .map((item) => item['canonicalLabel'] as String)
        .toList();
    expect(slugs.toSet().length, slugs.length);
    expect(labels.toSet().length, labels.length);

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

  test('D01 C04 defers emergency planning to d04_c01', () {
    final inventory = readObject(inventoryPath);
    final references = (inventory['crossCompetencyReferences'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    expect(references.length, 1);
    expect(references.single['semanticSlug'], 'emergency_action_plan');
    expect(references.single['targetCompetencyId'], 'd04_c01');
  });
}
