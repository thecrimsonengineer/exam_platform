import 'dart:convert';

import '../models/flashcard.dart';
import '../models/flashcard_concept.dart';
import '../models/flashcard_content_package.dart';
import '../models/flashcard_source_provenance.dart';
import '../repository/flashcard_package_repository.dart';
import '../validation/fcq100_validator.dart';

class FlashcardIntegrationCatalog {
  const FlashcardIntegrationCatalog({
    required this.packages,
    required this.cardsById,
    required this.conceptsById,
    required this.sourcesById,
    required this.questionConceptCandidates,
  });

  final List<FlashcardContentPackage> packages;
  final Map<String, Flashcard> cardsById;
  final Map<String, FlashcardConcept> conceptsById;
  final Map<String, FlashcardSourceRegistryEntry> sourcesById;
  final Map<int, Set<String>> questionConceptCandidates;

  String? singleConceptForQuestion(int questionId) {
    final candidates = questionConceptCandidates[questionId];
    if (candidates == null || candidates.isEmpty) {
      return null;
    }
    if (candidates.length != 1) {
      throw FormatException(
        'Question $questionId maps to multiple Flashcard Concepts: '
        '${candidates.toList()..sort()}',
      );
    }
    return candidates.single;
  }

  Flashcard requireCardForConcept(String conceptId) {
    final concept = conceptsById[conceptId];
    if (concept == null) {
      throw FormatException(
        'Flashcard Concept is missing from integration catalog: $conceptId',
      );
    }

    final card = cardsById[concept.flashcardId];
    if (card == null || card.conceptId != concept.id) {
      throw FormatException(
        'Concept/Card integration identity is invalid for $conceptId.',
      );
    }
    return card;
  }

  static Future<FlashcardIntegrationCatalog> load({
    required FlashcardPackageRepository repository,
    Fcq100Validator fcq100 = const Fcq100Validator(),
  }) async {
    final packageIds = await repository.listPackageIds();
    final packages = <FlashcardContentPackage>[];
    final cardsById = <String, Flashcard>{};
    final conceptsById = <String, FlashcardConcept>{};
    final sourcesById = <String, FlashcardSourceRegistryEntry>{};
    final questionConceptCandidates = <int, Set<String>>{};

    for (final packageId in packageIds) {
      final contentPackage = await repository.loadPackage(packageId);
      if (contentPackage == null) {
        throw FormatException(
          'Flashcard package index references missing package: $packageId',
        );
      }

      if (!fcq100.validate(contentPackage).passed) {
        continue;
      }

      packages.add(contentPackage);

      for (final card in contentPackage.cards) {
        _mergeExact(
          target: cardsById,
          key: card.id,
          value: card,
          encode: (item) => jsonEncode(item.toJson()),
          label: 'Flashcard',
        );
      }

      for (final concept in contentPackage.concepts) {
        _mergeExact(
          target: conceptsById,
          key: concept.id,
          value: concept,
          encode: (item) => jsonEncode(item.toJson()),
          label: 'Flashcard Concept',
        );
      }

      for (final source in contentPackage.sources) {
        _mergeExact(
          target: sourcesById,
          key: source.id,
          value: source,
          encode: (item) => jsonEncode(item.toJson()),
          label: 'Flashcard source',
        );
      }

      for (final mapping in contentPackage.questionMappings) {
        questionConceptCandidates
            .putIfAbsent(mapping.questionId, () => <String>{})
            .add(mapping.conceptId);
      }
    }

    packages.sort((a, b) => a.packageId.compareTo(b.packageId));

    return FlashcardIntegrationCatalog(
      packages: List.unmodifiable(packages),
      cardsById: Map.unmodifiable(cardsById),
      conceptsById: Map.unmodifiable(conceptsById),
      sourcesById: Map.unmodifiable(sourcesById),
      questionConceptCandidates: Map.unmodifiable(
        questionConceptCandidates.map(
          (key, value) => MapEntry(key, Set<String>.unmodifiable(value)),
        ),
      ),
    );
  }

  static void _mergeExact<T>({
    required Map<String, T> target,
    required String key,
    required T value,
    required String Function(T value) encode,
    required String label,
  }) {
    final existing = target[key];
    if (existing != null && encode(existing) != encode(value)) {
      throw FormatException('Conflicting $label identity: $key');
    }
    target[key] = value;
  }
}
