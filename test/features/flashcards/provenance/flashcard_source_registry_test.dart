import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/features/flashcards/flashcards.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlashcardSourceRegistry', () {
    test('Run 2 source registry fixture parses and validates', () {
      final json =
          jsonDecode(
                File(
                  'assets/flashcards/run2/fc_source_registry.v1.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;

      final rawSources = json['sources'] as List<dynamic>;
      final entries = rawSources
          .map(
            (item) => FlashcardSourceRegistryEntry.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();

      final registry = FlashcardSourceRegistry.build(entries: entries);

      expect(registry.count, 4);
      expect(
        registry
            .requireSource('csp11.source.niosh.hierarchy_of_controls')
            .verificationStatus,
        SourceVerificationStatus.verified,
      );
      expect(
        registry.requireSource('csp11.source.osha.1910_134').authorityTier,
        SourceAuthorityTier.federalLawRegulation,
      );
    });

    test('federal source tiers fail closed outside official .gov domains', () {
      const entry = FlashcardSourceRegistryEntry(
        id: 'csp11.source.example.not_gov',
        organization: 'Example',
        title: 'Invalid federal source',
        canonicalUrl: 'https://example.org/source',
        allowedDomains: <String>['example.org'],
        authorityTier: SourceAuthorityTier.federalTechnical,
        sourceType: SourceType.technicalPublication,
        copyrightMode: SourceCopyrightMode.federalGovernmentWork,
        verificationStatus: SourceVerificationStatus.verified,
        verifiedOn: '2026-09-20',
        primaryEligible: true,
      );

      expect(
        () => FlashcardSourceRegistry.build(entries: const [entry]),
        throwsFormatException,
      );
    });

    test('canonical URL must stay inside the source allow-list', () {
      const entry = FlashcardSourceRegistryEntry(
        id: 'csp11.source.example.domain_mismatch',
        organization: 'Example',
        title: 'Domain mismatch',
        canonicalUrl: 'https://wrong.example/source',
        allowedDomains: <String>['example.org'],
        authorityTier: SourceAuthorityTier.otherSupporting,
        sourceType: SourceType.other,
        copyrightMode: SourceCopyrightMode.openLicensed,
        verificationStatus: SourceVerificationStatus.verified,
        verifiedOn: '2026-09-20',
        primaryEligible: true,
      );

      expect(
        () => FlashcardSourceRegistry.build(entries: const [entry]),
        throwsFormatException,
      );
    });

    test('source footer exposes organization and exact locator', () {
      final registry = _run2Registry();
      const ref = FlashcardSourceRef(
        sourceId: 'csp11.source.niosh.hierarchy_of_controls',
        locator: 'Hierarchy of Controls > Overview',
        primary: true,
      );

      final footer = registry.footerFor(ref);

      expect(footer.label, contains('NIOSH'));
      expect(footer.label, contains('Hierarchy of Controls > Overview'));
      expect(
        footer.url,
        'https://www.cdc.gov/niosh/hierarchy-of-controls/about/index.html',
      );
    });
  });
}

FlashcardSourceRegistry _run2Registry() {
  final json =
      jsonDecode(
            File(
              'assets/flashcards/run2/fc_source_registry.v1.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;

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
