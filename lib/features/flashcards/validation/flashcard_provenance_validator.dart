import '../models/flashcard.dart';
import '../models/flashcard_lifecycle.dart';
import '../models/flashcard_source_provenance.dart';
import '../models/flashcard_source_ref.dart';
import '../registry/flashcard_source_registry.dart';

class FlashcardProvenanceValidator {
  const FlashcardProvenanceValidator._();

  static void validateCard({
    required Flashcard card,
    required FlashcardSourceRegistry sourceRegistry,
  }) {
    final learnerReady =
        card.lifecycle == FlashcardLifecycle.validated ||
        card.lifecycle == FlashcardLifecycle.bundled;

    final seenRefs = <String>{};
    final primaryRefs = <FlashcardSourceRef>[];

    for (final ref in card.sourceRefs) {
      final locator = ref.locator.trim();
      final duplicateKey = '${ref.sourceId}|$locator';
      if (!seenRefs.add(duplicateKey)) {
        throw FormatException(
          'Duplicate Flashcard source reference: $duplicateKey',
        );
      }

      final source = sourceRegistry.requireSource(ref.sourceId);

      if (source.verificationStatus == SourceVerificationStatus.blocked) {
        throw FormatException('Blocked source reference: ${ref.sourceId}');
      }

      if (source.copyrightMode == SourceCopyrightMode.unknownBlocked) {
        throw FormatException(
          'Source copyright status is unresolved: ${ref.sourceId}',
        );
      }

      if (ref.primary) {
        primaryRefs.add(ref);

        if (!source.primaryEligible) {
          throw FormatException(
            'Source is not eligible to be primary: ${ref.sourceId}',
          );
        }

        if (locator.isEmpty) {
          throw FormatException(
            'Primary source locator is required: ${ref.sourceId}',
          );
        }
      }

      if (learnerReady) {
        if (locator.isEmpty) {
          throw FormatException(
            'Learner-ready source locator is required: ${ref.sourceId}',
          );
        }

        if (source.verificationStatus != SourceVerificationStatus.verified) {
          throw FormatException(
            'Learner-ready card uses an unverified source: ${ref.sourceId}',
          );
        }
      }

      if (ref.definitionMode == SourceDefinitionMode.verbatimExcerpt) {
        final copyrightModeAllowsVerbatim =
            source.copyrightMode ==
                SourceCopyrightMode.federalGovernmentWork ||
            source.copyrightMode == SourceCopyrightMode.openLicensed ||
            source.copyrightMode == SourceCopyrightMode.permissionGranted;

        if (!copyrightModeAllowsVerbatim || !source.verbatimEligible) {
          throw FormatException(
            'Verbatim source use is not explicitly permitted: '
            '${ref.sourceId}',
          );
        }
      }

      if (source.copyrightMode ==
              SourceCopyrightMode.proprietaryParaphraseOnly &&
          ref.definitionMode == SourceDefinitionMode.officialDefinition) {
        throw FormatException(
          'Proprietary source must be paraphrased: ${ref.sourceId}',
        );
      }
    }

    if (primaryRefs.length > 1) {
      throw const FormatException(
        'A Flashcard may have only one primary source reference.',
      );
    }

    if (learnerReady) {
      if (card.sourceRefs.isEmpty) {
        throw const FormatException(
          'Learner-ready Flashcard requires source provenance.',
        );
      }

      if (primaryRefs.length != 1) {
        throw const FormatException(
          'Learner-ready Flashcard requires exactly one primary source.',
        );
      }

      final primarySource = sourceRegistry.requireSource(
        primaryRefs.single.sourceId,
      );
      final strongerSupportingExists = card.sourceRefs
          .where((ref) => !ref.primary)
          .map((ref) => sourceRegistry.requireSource(ref.sourceId))
          .any(
            (source) =>
                source.authorityTier.rank < primarySource.authorityTier.rank,
          );

      if (strongerSupportingExists) {
        throw const FormatException(
          'Primary source cannot be weaker than a supporting source.',
        );
      }
    }
  }

  static FlashcardSourceFooter primaryFooter({
    required Flashcard card,
    required FlashcardSourceRegistry sourceRegistry,
  }) {
    validateCard(card: card, sourceRegistry: sourceRegistry);

    final primary = card.sourceRefs.where((ref) => ref.primary).toList();
    if (primary.length != 1) {
      throw const FormatException(
        'Exactly one primary source is required to build the source footer.',
      );
    }

    return sourceRegistry.footerFor(primary.single);
  }

  static List<FlashcardSourceDetails> sourceDetails({
    required Flashcard card,
    required FlashcardSourceRegistry sourceRegistry,
  }) {
    validateCard(card: card, sourceRegistry: sourceRegistry);

    return List<FlashcardSourceDetails>.unmodifiable(
      card.sourceRefs.map(sourceRegistry.detailsFor),
    );
  }
}
