import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/data/csp11_blueprint.dart';
import 'package:exam_platform/features/flashcards/models/flashcard_source_provenance.dart';
import 'package:exam_platform/features/flashcards/registry/flashcard_source_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const manifestPath =
      'assets/flashcards/production/d01/d01_production_manifest.v1.json';
  const inventoryPath =
      'assets/flashcards/production/d01/d01_c01/'
      'd01_c01_concept_inventory.v1.json';
  const sourcePath =
      'assets/flashcards/production/sources/fcp_source_registry.v1.json';

  Map<String, dynamic> readObject(String path) {
    return Map<String, dynamic>.from(
      jsonDecode(File(path).readAsStringSync()) as Map,
    );
  }

  test('D01 production manifest mirrors the canonical blueprint exactly', () {
    final domain = domainForId('d01');
    expect(domain, isNotNull);

    final manifest = readObject(manifestPath);
    final competencies = (manifest['competencies'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    expect(manifest['domainId'], domain!.id);
    expect(manifest['title'], domain.title);
    expect(manifest['weightPercent'], domain.weightPercent);
    expect(competencies.length, domain.competencies.length);
    expect(competencies.length, 7);

    for (var index = 0; index < domain.competencies.length; index++) {
      final expected = domain.competencies[index];
      final observed = competencies[index];

      expect(observed['competencyId'], expected.id);
      expect(observed['number'], expected.number);
      expect(observed['statement'], expected.statement);
    }

    expect(competencies.first['status'], 'closed');
    expect(competencies[1]['status'], 'closed');
    expect(competencies[2]['status'], 'validating');
    expect(competencies[3]['status'], 'validating');
    expect(competencies[4]['status'], 'validating');
    expect(competencies[5]['status'], 'validating');
    expect(competencies[6]['status'], 'validating');
  });

  test('D01 C01 inventory stays at canonical competency placement', () {
    final inventory = readObject(inventoryPath);
    final placement = Map<String, dynamic>.from(inventory['placement'] as Map);

    expect(inventory['domainId'], 'd01');
    expect(inventory['competencyId'], 'd01_c01');
    expect(inventory['status'], 'resolved_inventory');
    expect(placement['domainId'], 'd01');
    expect(placement['competencyId'], 'd01_c01');
    expect(placement['topicId'], isNull);
    expect(placement['subtopicId'], isNull);
  });

  test('D01 C01 inventory resolves to eight cards with no holds', () {
    final inventory = readObject(inventoryPath);
    final accepted = (inventory['acceptedConcepts'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final merged = (inventory['mergedConcepts'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final holds = inventory['holds'] as List;

    expect(accepted.length, 8);
    expect(merged.length, 1);
    expect(holds, isEmpty);

    final slugs = accepted
        .map((item) => item['semanticSlug'] as String)
        .toList();
    final labels = accepted
        .map((item) => item['canonicalLabel'] as String)
        .toList();

    expect(slugs.toSet().length, slugs.length);
    expect(labels.toSet().length, labels.length);
    expect(accepted.every((item) => item['decision'] == 'CARD'), isTrue);
  });

  test('FCP D01 source registry is valid and resolves accepted sources', () {
    final sourceJson = readObject(sourcePath);
    final entries = (sourceJson['sources'] as List)
        .map(
          (item) => FlashcardSourceRegistryEntry.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();

    final registry = FlashcardSourceRegistry.build(entries: entries);
    expect(registry.count, greaterThanOrEqualTo(4));
    expect(
      registry.contains('csp11.source.niosh.prevention_through_design'),
      isTrue,
    );
    expect(
      registry.contains('csp11.source.niosh.hierarchy_of_controls'),
      isTrue,
    );

    final inventory = readObject(inventoryPath);
    final accepted = (inventory['acceptedConcepts'] as List).map(
      (item) => Map<String, dynamic>.from(item as Map),
    );

    for (final concept in accepted) {
      final sourceIds = (concept['sourceIds'] as List).cast<String>();
      expect(sourceIds, isNotEmpty);
      expect(sourceIds.every(registry.contains), isTrue);
    }
  });
}
