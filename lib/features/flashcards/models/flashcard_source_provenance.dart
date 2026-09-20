enum SourceAuthorityTier {
  federalLawRegulation,
  federalAgencyPrimary,
  federalTechnical,
  nationalConsensus,
  scholarlySupporting,
  otherSupporting,
  blocked,
}

extension SourceAuthorityTierRules on SourceAuthorityTier {
  int get rank {
    switch (this) {
      case SourceAuthorityTier.federalLawRegulation:
        return 1;
      case SourceAuthorityTier.federalAgencyPrimary:
        return 2;
      case SourceAuthorityTier.federalTechnical:
        return 3;
      case SourceAuthorityTier.nationalConsensus:
        return 4;
      case SourceAuthorityTier.scholarlySupporting:
        return 5;
      case SourceAuthorityTier.otherSupporting:
        return 6;
      case SourceAuthorityTier.blocked:
        return 99;
    }
  }

  bool get requiresOfficialUsGovernmentDomain {
    return this == SourceAuthorityTier.federalLawRegulation ||
        this == SourceAuthorityTier.federalAgencyPrimary ||
        this == SourceAuthorityTier.federalTechnical;
  }
}

enum SourceType {
  statute,
  regulation,
  agencyStandard,
  agencyGuidance,
  technicalPublication,
  officialGlossary,
  consensusStandard,
  peerReviewedPublication,
  other,
}

enum SourceDefinitionMode {
  officialDefinition,
  faithfulParaphrase,
  educationalParaphrase,
  verbatimExcerpt,
}

enum SourceCopyrightMode {
  federalGovernmentWork,
  openLicensed,
  permissionGranted,
  proprietaryParaphraseOnly,
  unknownBlocked,
}

enum SourceVerificationStatus {
  verified,
  needsReview,
  stale,
  blocked,
}

SourceAuthorityTier sourceAuthorityTierFromJson(dynamic value) {
  final raw = value?.toString() ?? '';
  return SourceAuthorityTier.values.firstWhere(
    (item) => item.name == raw,
    orElse: () => SourceAuthorityTier.blocked,
  );
}

SourceType sourceTypeFromJson(dynamic value) {
  final raw = value?.toString() ?? '';
  return SourceType.values.firstWhere(
    (item) => item.name == raw,
    orElse: () => SourceType.other,
  );
}

SourceDefinitionMode sourceDefinitionModeFromJson(dynamic value) {
  final raw = value?.toString() ?? '';
  return SourceDefinitionMode.values.firstWhere(
    (item) => item.name == raw,
    orElse: () => SourceDefinitionMode.educationalParaphrase,
  );
}

SourceCopyrightMode sourceCopyrightModeFromJson(dynamic value) {
  final raw = value?.toString() ?? '';
  return SourceCopyrightMode.values.firstWhere(
    (item) => item.name == raw,
    orElse: () => SourceCopyrightMode.unknownBlocked,
  );
}

SourceVerificationStatus sourceVerificationStatusFromJson(dynamic value) {
  final raw = value?.toString() ?? '';
  return SourceVerificationStatus.values.firstWhere(
    (item) => item.name == raw,
    orElse: () => SourceVerificationStatus.blocked,
  );
}

class FlashcardSourceRegistryEntry {
  const FlashcardSourceRegistryEntry({
    required this.id,
    required this.organization,
    required this.title,
    required this.canonicalUrl,
    required this.allowedDomains,
    required this.authorityTier,
    required this.sourceType,
    required this.copyrightMode,
    required this.verificationStatus,
    required this.verifiedOn,
    required this.primaryEligible,
    this.notes = '',
  });

  final String id;
  final String organization;
  final String title;
  final String canonicalUrl;
  final List<String> allowedDomains;
  final SourceAuthorityTier authorityTier;
  final SourceType sourceType;
  final SourceCopyrightMode copyrightMode;
  final SourceVerificationStatus verificationStatus;
  final String verifiedOn;
  final bool primaryEligible;
  final String notes;

  factory FlashcardSourceRegistryEntry.fromJson(Map<String, dynamic> json) {
    final rawDomains = json['allowedDomains'];

    return FlashcardSourceRegistryEntry(
      id: json['id']?.toString() ?? '',
      organization: json['organization']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      canonicalUrl: json['canonicalUrl']?.toString() ?? '',
      allowedDomains: rawDomains is List
          ? rawDomains
                .map((item) => item?.toString().trim().toLowerCase() ?? '')
                .where((item) => item.isNotEmpty)
                .toList()
          : const <String>[],
      authorityTier: sourceAuthorityTierFromJson(json['authorityTier']),
      sourceType: sourceTypeFromJson(json['sourceType']),
      copyrightMode: sourceCopyrightModeFromJson(json['copyrightMode']),
      verificationStatus: sourceVerificationStatusFromJson(
        json['verificationStatus'],
      ),
      verifiedOn: json['verifiedOn']?.toString() ?? '',
      primaryEligible: json['primaryEligible'] == true,
      notes: json['notes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization': organization,
      'title': title,
      'canonicalUrl': canonicalUrl,
      'allowedDomains': allowedDomains,
      'authorityTier': authorityTier.name,
      'sourceType': sourceType.name,
      'copyrightMode': copyrightMode.name,
      'verificationStatus': verificationStatus.name,
      'verifiedOn': verifiedOn,
      'primaryEligible': primaryEligible,
      if (notes.isNotEmpty) 'notes': notes,
    };
  }

  bool allowsUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme.toLowerCase() != 'https') {
      return false;
    }

    final host = uri.host.toLowerCase();
    if (host.isEmpty) {
      return false;
    }

    return allowedDomains.any(
      (domain) => host == domain || host.endsWith('.$domain'),
    );
  }

  bool get usesOfficialUsGovernmentDomain {
    final uri = Uri.tryParse(canonicalUrl);
    final host = uri?.host.toLowerCase() ?? '';
    return host == 'gov' || host.endsWith('.gov');
  }
}

class FlashcardSourceFooter {
  const FlashcardSourceFooter({
    required this.sourceId,
    required this.label,
    required this.organization,
    required this.locator,
    required this.url,
  });

  final String sourceId;
  final String label;
  final String organization;
  final String locator;
  final String url;
}

class FlashcardSourceDetails {
  const FlashcardSourceDetails({
    required this.sourceId,
    required this.organization,
    required this.title,
    required this.url,
    required this.locator,
    required this.authorityTier,
    required this.sourceType,
    required this.definitionMode,
    required this.copyrightMode,
    required this.verificationStatus,
    required this.verifiedOn,
    required this.primary,
  });

  final String sourceId;
  final String organization;
  final String title;
  final String url;
  final String locator;
  final SourceAuthorityTier authorityTier;
  final SourceType sourceType;
  final SourceDefinitionMode definitionMode;
  final SourceCopyrightMode copyrightMode;
  final SourceVerificationStatus verificationStatus;
  final String verifiedOn;
  final bool primary;
}
