import 'dart:convert';

import 'authority_registry_validator.dart';
import 'micro_fact_schema_validator.dart';

class MicroFactSourceGateIssue {
  const MicroFactSourceGateIssue({
    required this.code,
    required this.path,
    required this.message,
  });

  final String code;
  final String path;
  final String message;

  @override
  String toString() => code + ' at ' + path + ': ' + message;
}

class MicroFactSourceGateResult {
  const MicroFactSourceGateResult(this.issues);

  final List<MicroFactSourceGateIssue> issues;

  bool get isValid => issues.isEmpty;
}

class MicroFactSourceGateValidator {
  static const String requiredRegistryVersion = '1.0.0';

  const MicroFactSourceGateValidator();

  MicroFactSourceGateResult validateJson({
    required String microFactJson,
    required String authorityRegistryJson,
  }) {
    dynamic factDecoded;
    dynamic registryDecoded;

    try {
      factDecoded = jsonDecode(microFactJson);
    } on FormatException catch (error) {
      return MicroFactSourceGateResult([
        MicroFactSourceGateIssue(
          code: 'ML3_FACT_JSON_INVALID',
          path: r'$',
          message: error.message,
        ),
      ]);
    }

    try {
      registryDecoded = jsonDecode(authorityRegistryJson);
    } on FormatException catch (error) {
      return MicroFactSourceGateResult([
        MicroFactSourceGateIssue(
          code: 'ML3_REGISTRY_JSON_INVALID',
          path: r'$registry',
          message: error.message,
        ),
      ]);
    }

    if (factDecoded is! Map<String, dynamic>) {
      return const MicroFactSourceGateResult([
        MicroFactSourceGateIssue(
          code: 'ML3_FACT_ROOT_INVALID',
          path: r'$',
          message: 'MicroFact root must be a JSON object.',
        ),
      ]);
    }

    if (registryDecoded is! Map<String, dynamic>) {
      return const MicroFactSourceGateResult([
        MicroFactSourceGateIssue(
          code: 'ML3_REGISTRY_ROOT_INVALID',
          path: r'$registry',
          message: 'Authority registry root must be a JSON object.',
        ),
      ]);
    }

    return validateMaps(
      microFact: factDecoded,
      authorityRegistry: registryDecoded,
    );
  }

  MicroFactSourceGateResult validateMaps({
    required Map<String, dynamic> microFact,
    required Map<String, dynamic> authorityRegistry,
  }) {
    final issues = <MicroFactSourceGateIssue>[];

    final registryValidation = AuthorityRegistryValidator().validateJson(
      jsonEncode(authorityRegistry),
    );
    if (!registryValidation.isValid) {
      for (final issue in registryValidation.issues) {
        _add(
          issues,
          'ML3_REGISTRY_PREREQUISITE_INVALID',
          r'$registry' + issue.path.substring(1),
          issue.code + ': ' + issue.message,
        );
      }
    }

    final factValidation = MicroFactSchemaValidator().validateMap(microFact);
    if (!factValidation.isValid) {
      for (final issue in factValidation.issues) {
        _add(
          issues,
          'ML3_FACT_PREREQUISITE_INVALID',
          issue.path,
          issue.code + ': ' + issue.message,
        );
      }
    }

    if (issues.isNotEmpty) {
      return MicroFactSourceGateResult(List.unmodifiable(issues));
    }

    final registryVersion = authorityRegistry['registryVersion'];
    if (registryVersion != requiredRegistryVersion) {
      _add(
        issues,
        'ML3_REGISTRY_VERSION_MISMATCH',
        r'$registry.registryVersion',
        'MicroFact v1 source gates require authority registry version ' +
            requiredRegistryVersion +
            '.',
      );
      return MicroFactSourceGateResult(List.unmodifiable(issues));
    }

    final policy = authorityRegistry['policy'] as Map<String, dynamic>;
    if (policy['failClosed'] != true ||
        policy['firstPartyOnly'] != true ||
        policy['unlistedAuthorityDisposition'] != 'block' ||
        policy['secondarySummaryAsPrimarySource'] != false ||
        policy['aiIsAuthority'] != false) {
      _add(
        issues,
        'ML3_REGISTRY_POLICY_WEAKENED',
        r'$registry.policy',
        'Frozen fail-closed source policy is not intact.',
      );
      return MicroFactSourceGateResult(List.unmodifiable(issues));
    }

    final provenance = Map<String, dynamic>.from(
      microFact['provenance'] as Map,
    );
    final sourceRegistryId = provenance['sourceRegistryId'] as String;
    final sourceClass = provenance['sourceClass'] as String;
    final officialUrl = provenance['officialUrl'] as String;
    final sourceVerifiedAt = provenance['sourceVerifiedAt'] as String;
    final sourcePublishedAt = provenance['sourcePublishedAt'] as String?;

    final authorities = (authorityRegistry['authorities'] as List)
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .toList(growable: false);

    Map<String, dynamic>? authority;
    for (final candidate in authorities) {
      if (candidate['id'] == sourceRegistryId) {
        authority = candidate;
        break;
      }
    }

    if (authority == null) {
      _add(
        issues,
        'ML3_UNAPPROVED_AUTHORITY',
        r'$.provenance.sourceRegistryId',
        'sourceRegistryId is not present in the frozen ML-1 authority registry.',
      );
      return MicroFactSourceGateResult(List.unmodifiable(issues));
    }

    if (authority['status'] != 'active') {
      _add(
        issues,
        'ML3_AUTHORITY_INACTIVE',
        r'$.provenance.sourceRegistryId',
        'Referenced authority is not active.',
      );
    }

    if (authority['firstPartyRequired'] != true) {
      _add(
        issues,
        'ML3_FIRST_PARTY_POLICY_MISSING',
        r'$registry.authorities',
        'Referenced authority does not require first-party sourcing.',
      );
    }

    final permittedSourceClasses = (authority['permittedSourceClasses'] as List)
        .whereType<String>()
        .toSet();

    if (!permittedSourceClasses.contains(sourceClass)) {
      _add(
        issues,
        'ML3_SOURCE_CLASS_NOT_PERMITTED',
        r'$.provenance.sourceClass',
        'Source class is not permitted for ' + sourceRegistryId + '.',
      );
    }

    final uri = Uri.tryParse(officialUrl);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      _add(
        issues,
        'ML3_OFFICIAL_URL_INVALID',
        r'$.provenance.officialUrl',
        'Source URL must be an absolute credential-free HTTPS URL.',
      );
    } else {
      final allowedHosts = (authority['officialHosts'] as List)
          .whereType<String>()
          .map((host) => host.toLowerCase())
          .toSet();

      final actualHost = uri.host.toLowerCase();
      final isFirstParty = allowedHosts.any(
        (allowedHost) =>
            actualHost == allowedHost ||
            actualHost.endsWith('.' + allowedHost),
      );

      if (!isFirstParty) {
        _add(
          issues,
          'ML3_NOT_FIRST_PARTY_HOST',
          r'$.provenance.officialUrl',
          'URL host ' +
              actualHost +
              ' is outside the official hosts registered for ' +
              sourceRegistryId +
              '.',
        );
      }
    }

    final registryVerifiedAt = authority['verifiedAt'] as String;
    final registryVerifiedDate = _parseStrictDate(registryVerifiedAt);
    final sourceVerifiedDate = _parseStrictDate(sourceVerifiedAt);

    if (registryVerifiedDate == null || sourceVerifiedDate == null) {
      _add(
        issues,
        'ML3_SOURCE_VERIFICATION_DATE_INVALID',
        r'$.provenance.sourceVerifiedAt',
        'Source verification dates must remain valid ISO dates.',
      );
    } else if (sourceVerifiedDate.isBefore(registryVerifiedDate)) {
      _add(
        issues,
        'ML3_SOURCE_VERIFIED_BEFORE_REGISTRY',
        r'$.provenance.sourceVerifiedAt',
        'Fact source verification cannot predate the authority registry verification date.',
      );
    }

    if (sourcePublishedAt != null) {
      final publishedDate = _parseStrictDate(sourcePublishedAt);
      if (publishedDate == null || sourceVerifiedDate == null) {
        _add(
          issues,
          'ML3_SOURCE_PUBLICATION_DATE_INVALID',
          r'$.provenance.sourcePublishedAt',
          'Source publication date must be a valid ISO date.',
        );
      } else if (publishedDate.isAfter(sourceVerifiedDate)) {
        _add(
          issues,
          'ML3_SOURCE_PUBLISHED_AFTER_VERIFICATION',
          r'$.provenance.sourcePublishedAt',
          'A source cannot be verified before its stated publication date.',
        );
      }
    }

    return MicroFactSourceGateResult(List.unmodifiable(issues));
  }

  static DateTime? _parseStrictDate(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return null;
    }

    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return null;
    }

    final normalized =
        parsed.year.toString().padLeft(4, '0') +
        '-' +
        parsed.month.toString().padLeft(2, '0') +
        '-' +
        parsed.day.toString().padLeft(2, '0');

    return normalized == value ? parsed : null;
  }

  static void _add(
    List<MicroFactSourceGateIssue> issues,
    String code,
    String path,
    String message,
  ) {
    issues.add(
      MicroFactSourceGateIssue(code: code, path: path, message: message),
    );
  }
}
