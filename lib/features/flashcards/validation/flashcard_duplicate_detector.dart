import '../models/flashcard_content_package.dart';

enum FlashcardDuplicateKind {
  conceptLabel,
  conceptAlias,
  cardFront,
  cardContent,
}

class FlashcardDuplicateFinding {
  const FlashcardDuplicateFinding({
    required this.kind,
    required this.normalizedValue,
    required this.ids,
  });

  final FlashcardDuplicateKind kind;
  final String normalizedValue;
  final List<String> ids;
}

class FlashcardDuplicateReport {
  const FlashcardDuplicateReport(this.findings);

  final List<FlashcardDuplicateFinding> findings;

  bool get hasBlockingDuplicates => findings.isNotEmpty;
}

class FlashcardDuplicateDetector {
  const FlashcardDuplicateDetector();

  FlashcardDuplicateReport inspect(FlashcardContentPackage package) {
    final findings = <FlashcardDuplicateFinding>[];

    _collectDuplicates(
      kind: FlashcardDuplicateKind.conceptLabel,
      values: {
        for (final concept in package.concepts)
          concept.id: concept.canonicalLabel,
      },
      findings: findings,
    );

    final aliases = <String, Set<String>>{};
    for (final concept in package.concepts) {
      for (final value in <String>[
        concept.canonicalLabel,
        ...concept.aliases,
      ]) {
        final normalized = normalize(value);
        if (normalized.isEmpty) {
          continue;
        }
        aliases.putIfAbsent(normalized, () => <String>{}).add(concept.id);
      }
    }
    for (final entry in aliases.entries) {
      if (entry.value.length > 1) {
        findings.add(
          FlashcardDuplicateFinding(
            kind: FlashcardDuplicateKind.conceptAlias,
            normalizedValue: entry.key,
            ids: entry.value.toList()..sort(),
          ),
        );
      }
    }

    _collectDuplicates(
      kind: FlashcardDuplicateKind.cardFront,
      values: {for (final card in package.cards) card.id: card.frontLabel},
      findings: findings,
    );

    _collectDuplicates(
      kind: FlashcardDuplicateKind.cardContent,
      values: {
        for (final card in package.cards)
          card.id: '${card.frontLabel}\n${card.backDefinition}',
      },
      findings: findings,
    );

    findings.sort((a, b) {
      final kind = a.kind.index.compareTo(b.kind.index);
      if (kind != 0) {
        return kind;
      }
      return a.normalizedValue.compareTo(b.normalizedValue);
    });

    return FlashcardDuplicateReport(List.unmodifiable(findings));
  }

  static String normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static void _collectDuplicates({
    required FlashcardDuplicateKind kind,
    required Map<String, String> values,
    required List<FlashcardDuplicateFinding> findings,
  }) {
    final ownersByValue = <String, List<String>>{};

    for (final entry in values.entries) {
      final normalized = normalize(entry.value);
      if (normalized.isEmpty) {
        continue;
      }
      ownersByValue.putIfAbsent(normalized, () => <String>[]).add(entry.key);
    }

    for (final entry in ownersByValue.entries) {
      if (entry.value.length > 1) {
        final ids = entry.value..sort();
        findings.add(
          FlashcardDuplicateFinding(
            kind: kind,
            normalizedValue: entry.key,
            ids: List.unmodifiable(ids),
          ),
        );
      }
    }
  }
}
