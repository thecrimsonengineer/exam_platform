import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/data/csp11_blueprint.dart';
import 'package:exam_platform/features/flashcards/models/flashcard_source_provenance.dart';
import 'package:exam_platform/features/flashcards/registry/flashcard_source_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const manifestPath =
      'assets/flashcards/production/d02/d02_production_manifest.v1.json';
  const inventoryPath =
      'assets/flashcards/production/d02/d02_c01/'
      'd02_c01_concept_inventory.v1.json';
  const sourcePath =
      'assets/flashcards/production/sources/fcp_source_registry.v1.json';

  Map<String, dynamic> readObject(String path) => Map<String, dynamic>.from(
    jsonDecode(File(path).readAsStringSync()) as Map,
  );

  test('D02 production manifest mirrors the canonical blueprint exactly', () {
    final domain = domainForId('d02');
    expect(domain, isNotNull);

    final manifest = readObject(manifestPath);
    final competencies = (manifest['competencies'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    expect(manifest['domainId'], domain!.id);
    expect(manifest['title'], domain.title);
    expect(manifest['weightPercent'], domain.weightPercent);
    expect(competencies.length, 14);
    expect(competencies.length, domain.competencies.length);

    for (var index = 0; index < domain.competencies.length; index++) {
      final expected = domain.competencies[index];
      final observed = competencies[index];
      expect(observed['competencyId'], expected.id);
      expect(observed['number'], expected.number);
      expect(observed['statement'], expected.statement);
    }

    expect(competencies.first['status'], 'validating');
    expect(
      competencies.skip(1).every((item) => item['status'] == 'not_started'),
      isTrue,
    );
  });

  test('D02 C01 candidate inventory is unique and source-backed', () {
    final inventory = readObject(inventoryPath);
    expect(inventory['phase'], 'FCP-2A');
    expect(inventory['status'], 'resolved_inventory');
    expect(inventory['domainId'], 'd02');
    expect(inventory['competencyId'], 'd02_c01');

    final candidates = (inventory['acceptedConcepts'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    expect(candidates.length, 8);
    expect(inventory['holds'], isEmpty);

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
}
