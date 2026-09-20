import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/features/flashcards/flashcards.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const placement = FlashcardPlacement(
    domainId: 'd03',
    competencyId: 'd03_c02',
  );

  group('FlashcardProvenanceValidator', () {
    test('Run 2 learner-ready fixture passes provenance validation', () {
      final registry = _run2Registry();
      final json = jsonDecode(
        File(
          'assets/flashcards/run2/fc_sourced_cards.v1.json',
        ).readAsStringSync(),
      ) as Map<String, dynamic>;
      final rawCards = json['cards'] as List<dynamic>;
      final card = Flashcard.fromJson(
        Map<String, dynamic>.from(rawCards.single as Map),
      );

      expect(
        () => FlashcardProvenanceValidator.validateCard(
          card: card,
          sourceRegistry: registry,
        ),
        returnsNormally,
      );

      final footer = FlashcardProvenanceValidator.primaryFooter(
        card: card,
        sourceRegistry: registry,
      );
      expect(footer.organization, 'NIOSH');

      final details = FlashcardProvenanceValidator.sourceDetails(
        card: card,
        sourceRegistry: registry,
      );
      expect(details.single.definitionMode, SourceDefinitionMode.educationalParaphrase);
      expect(details.single.verificationStatus, SourceVerificationStatus.verified);
    });

    test('candidate card may exist before source review', () {
      const card = Flashcard(
        id: 'csp11.flashcard.hierarchy_of_controls',
        conceptId: 'csp11.concept.hierarchy_of_controls',
        version: 1,
        type: FlashcardType.concept,
        frontLabel: 'Hierarchy of Controls',
        backDefinition: 'Draft local meaning.',
        primaryPlacement: placement,
        lifecycle: FlashcardLifecycle.candidate,
      );

      expect(
        () => FlashcardProvenanceValidator.validateCard(
          card: card,
          sourceRegistry: _run2Registry(),
        ),
        returnsNormally,
      );
    });

    test('validated card without provenance fails closed', () {
      const card = Flashcard(
        id: 'csp11.flashcard.hierarchy_of_controls',
        conceptId: 'csp11.concept.hierarchy_of_controls',
        version: 1,
        type: FlashcardType.concept,
        frontLabel: 'Hierarchy of Controls',
        backDefinition: 'Learner-ready meaning.',
        primaryPlacement: placement,
        lifecycle: FlashcardLifecycle.validated,
      );

      expect(
        () => FlashcardProvenanceValidator.validateCard(
          card: card,
          sourceRegistry: _run2Registry(),
        ),
        throwsFormatException,
      );
    });

    test('validated card requires exactly one primary source', () {
      const card = Flashcard(
        id: 'csp11.flashcard.hierarchy_of_controls',
        conceptId: 'csp11.concept.hierarchy_of_controls',
        version: 1,
        type: FlashcardType.concept,
        frontLabel: 'Hierarchy of Controls',
        backDefinition: 'Learner-ready meaning.',
        primaryPlacement: placement,
        lifecycle: FlashcardLifecycle.validated,
        sourceRefs: <FlashcardSourceRef>[
          FlashcardSourceRef(
            sourceId: 'csp11.source.niosh.hierarchy_of_controls',
            locator: 'Overview',
          ),
        ],
      );

      expect(
        () => FlashcardProvenanceValidator.validateCard(
          card: card,
          sourceRegistry: _run2Registry(),
        ),
        throwsFormatException,
      );
    });

    test('unverified source cannot support a learner-ready card', () {
      const card = Flashcard(
        id: 'csp11.flashcard.consensus_example',
        conceptId: 'csp11.concept.consensus_example',
        version: 1,
        type: FlashcardType.concept,
        frontLabel: 'Consensus Example',
        backDefinition: 'Learner-ready meaning.',
        primaryPlacement: placement,
        lifecycle: FlashcardLifecycle.validated,
        sourceRefs: <FlashcardSourceRef>[
          FlashcardSourceRef(
            sourceId: 'csp11.source.ansi.example',
            locator: 'Example clause',
            primary: true,
          ),
        ],
      );

      expect(
        () => FlashcardProvenanceValidator.validateCard(
          card: card,
          sourceRegistry: _run2Registry(),
        ),
        throwsFormatException,
      );
    });

    test('weaker primary cannot outrank stronger supporting authority', () {
      final registry = FlashcardSourceRegistry.build(
        entries: const <FlashcardSourceRegistryEntry>[
          FlashcardSourceRegistryEntry(
            id: 'csp11.source.primary.technical',
            organization: 'NIOSH',
            title: 'Technical source',
            canonicalUrl: 'https://www.cdc.gov/niosh/example',
            allowedDomains: <String>['cdc.gov'],
            authorityTier: SourceAuthorityTier.federalTechnical,
            sourceType: SourceType.technicalPublication,
            copyrightMode: SourceCopyrightMode.federalGovernmentWork,
            verificationStatus: SourceVerificationStatus.verified,
            verifiedOn: '2026-09-20',
            primaryEligible: true,
          ),
          FlashcardSourceRegistryEntry(
            id: 'csp11.source.supporting.regulation',
            organization: 'OSHA',
            title: 'Regulatory source',
            canonicalUrl: 'https://www.osha.gov/laws-regs/example',
            allowedDomains: <String>['osha.gov'],
            authorityTier: SourceAuthorityTier.federalLawRegulation,
            sourceType: SourceType.regulation,
            copyrightMode: SourceCopyrightMode.federalGovernmentWork,
            verificationStatus: SourceVerificationStatus.verified,
            verifiedOn: '2026-09-20',
            primaryEligible: true,
          ),
        ],
      );

      const card = Flashcard(
        id: 'csp11.flashcard.example',
        conceptId: 'csp11.concept.example',
        version: 1,
        type: FlashcardType.concept,
        frontLabel: 'Example',
        backDefinition: 'Learner-ready meaning.',
        primaryPlacement: placement,
        lifecycle: FlashcardLifecycle.validated,
        sourceRefs: <FlashcardSourceRef>[
          FlashcardSourceRef(
            sourceId: 'csp11.source.primary.technical',
            locator: 'Section A',
            primary: true,
          ),
          FlashcardSourceRef(
            sourceId: 'csp11.source.supporting.regulation',
            locator: 'Section B',
          ),
        ],
      );

      expect(
        () => FlashcardProvenanceValidator.validateCard(
          card: card,
          sourceRegistry: registry,
        ),
        throwsFormatException,
      );
    });

    test('proprietary paraphrase-only source rejects verbatim mode', () {
      final registry = FlashcardSourceRegistry.build(
        entries: const <FlashcardSourceRegistryEntry>[
          FlashcardSourceRegistryEntry(
            id: 'csp11.source.proprietary.example',
            organization: 'Consensus Publisher',
            title: 'Licensed standard',
            canonicalUrl: 'https://example.org/standard',
            allowedDomains: <String>['example.org'],
            authorityTier: SourceAuthorityTier.nationalConsensus,
            sourceType: SourceType.consensusStandard,
            copyrightMode: SourceCopyrightMode.proprietaryParaphraseOnly,
            verificationStatus: SourceVerificationStatus.verified,
            verifiedOn: '2026-09-20',
            primaryEligible: true,
          ),
        ],
      );

      const card = Flashcard(
        id: 'csp11.flashcard.proprietary_example',
        conceptId: 'csp11.concept.proprietary_example',
        version: 1,
        type: FlashcardType.concept,
        frontLabel: 'Proprietary Example',
        backDefinition: 'Learner-ready meaning.',
        primaryPlacement: placement,
        lifecycle: FlashcardLifecycle.validated,
        sourceRefs: <FlashcardSourceRef>[
          FlashcardSourceRef(
            sourceId: 'csp11.source.proprietary.example',
            locator: 'Clause 1',
            primary: true,
            definitionMode: SourceDefinitionMode.verbatimExcerpt,
          ),
        ],
      );

      expect(
        () => FlashcardProvenanceValidator.validateCard(
          card: card,
          sourceRegistry: registry,
        ),
        throwsFormatException,
      );
    });
  });
}

FlashcardSourceRegistry _run2Registry() {
  final json = jsonDecode(
    File(
      'assets/flashcards/run2/fc_source_registry.v1.json',
    ).readAsStringSync(),
  ) as Map<String, dynamic>;

  final rawSources = json['sources'] as List<dynamic>;
  final entries = rawSources
      .map(
        (item) => FlashcardSourceRegistryEntry.fromJson(
          Map<String, dynamic>.from(item as Map),
        ),
      )
      .toList();

  return FlashcardSourceRegistry.build(entries: entries);
}
