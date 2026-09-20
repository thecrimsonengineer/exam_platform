import '../models/flashcard_source_provenance.dart';
import '../models/flashcard_source_ref.dart';

class FlashcardSourceRegistry {
  FlashcardSourceRegistry._(this._entriesById);

  final Map<String, FlashcardSourceRegistryEntry> _entriesById;

  static final RegExp _sourceIdPattern = RegExp(
    r'^csp11\.source\.[a-z0-9._-]+$',
  );

  static FlashcardSourceRegistry build({
    required Iterable<FlashcardSourceRegistryEntry> entries,
  }) {
    final map = <String, FlashcardSourceRegistryEntry>{};

    for (final entry in entries) {
      _validateEntry(entry);

      if (map.containsKey(entry.id)) {
        throw FormatException('Duplicate Flashcard source ID: ${entry.id}');
      }
      map[entry.id] = entry;
    }

    return FlashcardSourceRegistry._(Map.unmodifiable(map));
  }

  int get count => _entriesById.length;

  bool contains(String sourceId) => _entriesById.containsKey(sourceId);

  FlashcardSourceRegistryEntry? sourceForId(String sourceId) {
    return _entriesById[sourceId];
  }

  FlashcardSourceRegistryEntry requireSource(String sourceId) {
    final source = _entriesById[sourceId];
    if (source == null) {
      throw FormatException('Unknown Flashcard source ID: $sourceId');
    }
    return source;
  }

  FlashcardSourceFooter footerFor(FlashcardSourceRef ref) {
    final source = requireSource(ref.sourceId);
    final locator = ref.locator.trim();
    final suffix = locator.isEmpty ? '' : ' | $locator';

    return FlashcardSourceFooter(
      sourceId: source.id,
      label: 'Source: ${source.organization}$suffix',
      organization: source.organization,
      locator: locator,
      url: source.canonicalUrl,
    );
  }

  FlashcardSourceDetails detailsFor(FlashcardSourceRef ref) {
    final source = requireSource(ref.sourceId);

    return FlashcardSourceDetails(
      sourceId: source.id,
      organization: source.organization,
      title: source.title,
      url: source.canonicalUrl,
      locator: ref.locator.trim(),
      authorityTier: source.authorityTier,
      sourceType: source.sourceType,
      definitionMode: ref.definitionMode,
      copyrightMode: source.copyrightMode,
      verificationStatus: source.verificationStatus,
      verifiedOn: source.verifiedOn,
      primary: ref.primary,
    );
  }

  static void _validateEntry(FlashcardSourceRegistryEntry entry) {
    if (!_sourceIdPattern.hasMatch(entry.id)) {
      throw FormatException('Invalid Flashcard source ID: ${entry.id}');
    }

    if (entry.organization.trim().isEmpty) {
      throw FormatException('Source organization is required: ${entry.id}');
    }

    if (entry.title.trim().isEmpty) {
      throw FormatException('Source title is required: ${entry.id}');
    }

    if (entry.allowedDomains.isEmpty) {
      throw FormatException('Allowed source domains are required: ${entry.id}');
    }

    for (final domain in entry.allowedDomains) {
      final normalized = domain.trim().toLowerCase();
      if (normalized.isEmpty ||
          normalized.contains('://') ||
          normalized.contains('/') ||
          normalized.startsWith('.')) {
        throw FormatException(
          'Invalid allowed source domain for ${entry.id}: $domain',
        );
      }
    }

    if (!entry.allowsUrl(entry.canonicalUrl)) {
      throw FormatException(
        'Canonical URL is not HTTPS or outside allowed domains: ${entry.id}',
      );
    }

    if (entry.authorityTier.requiresOfficialUsGovernmentDomain &&
        !entry.usesOfficialUsGovernmentDomain) {
      throw FormatException(
        'Federal source tier requires an official .gov domain: ${entry.id}',
      );
    }

    if (entry.verificationStatus == SourceVerificationStatus.verified) {
      final date = DateTime.tryParse(entry.verifiedOn);
      if (date == null) {
        throw FormatException(
          'Verified source requires a valid verifiedOn date: ${entry.id}',
        );
      }
    }

    if (entry.verificationStatus == SourceVerificationStatus.blocked &&
        entry.primaryEligible) {
      throw FormatException(
        'Blocked source cannot be primary eligible: ${entry.id}',
      );
    }

    if (entry.copyrightMode == SourceCopyrightMode.unknownBlocked &&
        entry.primaryEligible) {
      throw FormatException(
        'Unknown copyright source cannot be primary eligible: ${entry.id}',
      );
    }

    if (entry.authorityTier == SourceAuthorityTier.blocked &&
        entry.primaryEligible) {
      throw FormatException(
        'Blocked authority tier cannot be primary eligible: ${entry.id}',
      );
    }

    if (entry.authorityTier == SourceAuthorityTier.federalLawRegulation) {
      final allowedType =
          entry.sourceType == SourceType.statute ||
          entry.sourceType == SourceType.regulation ||
          entry.sourceType == SourceType.agencyStandard;
      if (!allowedType) {
        throw FormatException(
          'Federal law/regulation tier has incompatible source type: '
          '${entry.id}',
        );
      }
    }
  }
}
