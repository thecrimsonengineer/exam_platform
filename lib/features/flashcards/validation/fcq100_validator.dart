import '../models/fcq_validation_result.dart';
import '../models/flashcard.dart';
import '../models/flashcard_content_package.dart';
import '../models/flashcard_lifecycle.dart';
import '../registry/flashcard_ids.dart';
import '../registry/flashcard_source_registry.dart';
import 'flashcard_deck_validator.dart';
import 'flashcard_duplicate_detector.dart';
import 'flashcard_provenance_validator.dart';

class Fcq100Validator {
  const Fcq100Validator();

  static const String contractVersion = 'FCQ100-V1';

  FcqValidationResult validate(FlashcardContentPackage contentPackage) {
    FlashcardSourceRegistry? sourceRegistry;
    var sourceRegistryValid = true;
    try {
      sourceRegistry = FlashcardSourceRegistry.build(
        entries: contentPackage.sources,
      );
    } on FormatException {
      sourceRegistryValid = false;
    }

    final deckValidation = const FlashcardDeckValidator().validate(
      contentPackage,
    );
    final duplicateReport = const FlashcardDuplicateDetector().inspect(
      contentPackage,
    );

    var provenanceValid = sourceRegistryValid;
    if (sourceRegistry != null) {
      for (final card in contentPackage.cards) {
        try {
          FlashcardProvenanceValidator.validateCard(
            card: card,
            sourceRegistry: sourceRegistry,
          );
        } on FormatException {
          provenanceValid = false;
          break;
        }
      }
    }

    final conceptIds = contentPackage.concepts.map((item) => item.id).toList();
    final cardIds = contentPackage.cards.map((item) => item.id).toList();
    final questionIds = contentPackage.questionMappings
        .map((item) => item.questionId)
        .toList();
    final sourceIds = contentPackage.sources.map((item) => item.id).toList();

    final placementsMatch = contentPackage.cards.every((card) {
      final concepts = contentPackage.concepts.where(
        (concept) => concept.id == card.conceptId,
      );
      if (concepts.length != 1) {
        return false;
      }
      final concept = concepts.single;
      final left = concept.primaryPlacement;
      final right = card.primaryPlacement;
      return left.domainId == right.domainId &&
          left.competencyId == right.competencyId &&
          left.topicId == right.topicId &&
          left.subtopicId == right.subtopicId;
    });

    final rules = <FcqRuleResult>[
      _rule(
        'FCQ-001',
        contentPackage.schemaVersion ==
            FlashcardContentPackage.currentSchemaVersion,
        'Package schema must be the frozen FC V1 schema.',
      ),
      _rule(
        'FCQ-002',
        FlashcardIds.isValidDeckId(contentPackage.deck.id),
        'Deck ID must be canonical.',
      ),
      _rule(
        'FCQ-003',
        _deckVersionMatches(contentPackage),
        'Deck version must match its deck ID.',
      ),
      _rule(
        'FCQ-004',
        _lengthBetween(contentPackage.deck.title, 3, 120),
        'Deck title must be 3-120 characters.',
      ),
      _rule(
        'FCQ-005',
        contentPackage.concepts.isNotEmpty,
        'Package must contain at least one Concept.',
      ),
      _rule(
        'FCQ-006',
        contentPackage.cards.isNotEmpty,
        'Package must contain at least one Flashcard.',
      ),
      _rule(
        'FCQ-007',
        contentPackage.concepts.length == contentPackage.cards.length,
        'FC V1 requires one canonical Flashcard per Concept.',
      ),
      _rule(
        'FCQ-008',
        conceptIds.toSet().length == conceptIds.length,
        'Concept IDs must be unique.',
      ),
      _rule(
        'FCQ-009',
        cardIds.toSet().length == cardIds.length,
        'Flashcard IDs must be unique.',
      ),
      _rule(
        'FCQ-010',
        questionIds.toSet().length == questionIds.length,
        'Question mappings must be unique by Question ID.',
      ),
      _rule(
        'FCQ-011',
        sourceIds.toSet().length == sourceIds.length && sourceRegistryValid,
        'Source Registry entries must be unique and valid.',
      ),
      _rule(
        'FCQ-012',
        deckValidation.passed,
        'Deck, Concept, Flashcard and mapping integrity must pass.',
      ),
      _rule(
        'FCQ-013',
        contentPackage.deck.cardIds.toSet().length ==
                contentPackage.cards.length &&
            contentPackage.deck.cardIds.toSet().containsAll(cardIds),
        'Deck must contain the packaged Flashcard set exactly once.',
      ),
      _rule(
        'FCQ-014',
        contentPackage.cards.every(
          (card) =>
              card.lifecycle == FlashcardLifecycle.validated ||
              card.lifecycle == FlashcardLifecycle.bundled,
        ),
        'Every FCQ100 card must be validated or bundled.',
      ),
      _rule(
        'FCQ-015',
        contentPackage.deck.lifecycle == FlashcardLifecycle.validated ||
            contentPackage.deck.lifecycle == FlashcardLifecycle.bundled,
        'FCQ100 deck must be validated or bundled.',
      ),
      _rule(
        'FCQ-016',
        contentPackage.cards.every(
          (card) =>
              _lengthBetween(card.frontLabel, 2, 80) &&
              !card.frontLabel.contains('?') &&
              !card.frontLabel.contains('\n'),
        ),
        'Card fronts must be concise concept labels, not questions.',
      ),
      _rule(
        'FCQ-017',
        contentPackage.cards.every(
          (card) => _lengthBetween(card.backDefinition, 20, 600),
        ),
        'Definitions must be 20-600 characters.',
      ),
      _rule(
        'FCQ-018',
        contentPackage.cards.every(
          (card) => _lengthBetween(card.whyItMatters, 20, 500),
        ),
        'Every learner-ready card requires a meaningful Why It Matters.',
      ),
      _rule(
        'FCQ-019',
        contentPackage.cards.every(
          (card) => card.keyPoint.isEmpty || card.keyPoint.trim().length <= 300,
        ),
        'Optional key points must not exceed 300 characters.',
      ),
      _rule(
        'FCQ-020',
        contentPackage.cards.every(_validTags),
        'Cards require 2-8 concise unique tags.',
      ),
      _rule(
        'FCQ-021',
        provenanceValid,
        'All cards must pass the FC2 provenance validator.',
      ),
      _rule(
        'FCQ-022',
        contentPackage.cards.every(
          (card) =>
              card.sourceRefs.where((ref) => ref.primary).length == 1 &&
              card.sourceRefs.every((ref) => ref.locator.trim().isNotEmpty),
        ),
        'Every card requires one primary source and exact source locators.',
      ),
      _rule(
        'FCQ-023',
        duplicateReport.findings.every(
          (finding) =>
              finding.kind != FlashcardDuplicateKind.conceptLabel &&
              finding.kind != FlashcardDuplicateKind.conceptAlias,
        ),
        'Concept labels and aliases must not collide across Concepts.',
      ),
      _rule(
        'FCQ-024',
        duplicateReport.findings.every(
          (finding) =>
              finding.kind != FlashcardDuplicateKind.cardFront &&
              finding.kind != FlashcardDuplicateKind.cardContent,
        ),
        'Flashcard fronts and content must not be semantic duplicates.',
      ),
      _rule(
        'FCQ-025',
        placementsMatch,
        'Each Concept and canonical Flashcard must share one placement.',
      ),
    ];

    return FcqValidationResult(rules: List.unmodifiable(rules));
  }

  static FcqRuleResult _rule(String id, bool passed, String message) {
    return FcqRuleResult(
      id: id,
      points: 4,
      passed: passed,
      message: passed ? '$id PASS' : '$id BLOCK: $message',
    );
  }

  static bool _deckVersionMatches(FlashcardContentPackage contentPackage) {
    try {
      return contentPackage.deck.version >= 1 &&
          FlashcardIds.deckVersion(contentPackage.deck.id) ==
              contentPackage.deck.version;
    } on FormatException {
      return false;
    }
  }

  static bool _lengthBetween(String value, int min, int max) {
    final length = value.trim().length;
    return length >= min && length <= max;
  }

  static bool _validTags(Flashcard card) {
    final tags = card.tags
        .map((tag) => tag.trim().toLowerCase())
        .where((tag) => tag.isNotEmpty)
        .toList();

    if (tags.length < 2 ||
        tags.length > 8 ||
        tags.toSet().length != tags.length) {
      return false;
    }

    return tags.every(
      (tag) =>
          tag.length <= 40 &&
          RegExp(r'^[a-z0-9]+(?:[-_][a-z0-9]+)*$').hasMatch(tag),
    );
  }
}
