import 'dart:convert';

class AuthorityRegistryIssue {
  const AuthorityRegistryIssue({
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

class AuthorityRegistryValidationResult {
  const AuthorityRegistryValidationResult(this.issues);

  final List<AuthorityRegistryIssue> issues;

  bool get isValid => issues.isEmpty;
}

class AuthorityRegistryValidator {
  static const Set<String> requiredAuthorityIds = {
    'SRC-01',
    'SRC-02',
    'SRC-03',
    'SRC-04',
    'SRC-05',
    'SRC-06',
    'SRC-07',
    'SRC-08',
    'SRC-09',
    'SRC-10',
    'SRC-11',
    'SRC-12',
    'SRC-13',
    'SRC-14',
    'SRC-15',
  };

  static const Set<String> allowedStatuses = {'active'};

  static const Set<String> allowedEditionPolicies = {
    'continuous_regulatory_check',
    'revision_tracked',
    'annual_or_revision_check',
    'publication_specific',
  };

  static const Set<String> allowedSourceClasses = {
    'federal_regulation',
    'regulatory_interpretation',
    'enforcement_or_compliance_guidance',
    'government_recommendation',
    'research_or_prevention_guidance',
    'consensus_standard',
    'international_standard',
    'professional_guideline',
    'professional_framework',
    'environmental_regulation',
    'transportation_regulation',
    'emergency_management_framework',
    'process_safety_framework',
    'loss_prevention_guidance',
    'testing_or_certification_standard',
  };

  AuthorityRegistryValidationResult validateJson(String rawJson) {
    final issues = <AuthorityRegistryIssue>[];
    dynamic decoded;

    try {
      decoded = jsonDecode(rawJson);
    } on FormatException catch (error) {
      return AuthorityRegistryValidationResult([
        AuthorityRegistryIssue(
          code: 'ML1_JSON_INVALID',
          path: r'$',
          message: error.message,
        ),
      ]);
    }

    if (decoded is! Map<String, dynamic>) {
      return const AuthorityRegistryValidationResult([
        AuthorityRegistryIssue(
          code: 'ML1_ROOT_NOT_OBJECT',
          path: r'$',
          message: 'Registry root must be a JSON object.',
        ),
      ]);
    }

    _validateRoot(decoded, issues);
    return AuthorityRegistryValidationResult(List.unmodifiable(issues));
  }

  void _validateRoot(
    Map<String, dynamic> root,
    List<AuthorityRegistryIssue> issues,
  ) {
    if (root['schemaVersion'] != 1) {
      _add(
        issues,
        'ML1_SCHEMA_VERSION',
        r'$.schemaVersion',
        'schemaVersion must be 1 for the ML-1 registry.',
      );
    }

    if (!_nonEmptyString(root['registryVersion'])) {
      _add(
        issues,
        'ML1_REGISTRY_VERSION',
        r'$.registryVersion',
        'registryVersion is required.',
      );
    }

    if (root['status'] != 'frozen') {
      _add(
        issues,
        'ML1_REGISTRY_STATUS',
        r'$.status',
        'ML-1 registry status must be frozen.',
      );
    }

    if (!_isIsoDate(root['frozenAt'])) {
      _add(
        issues,
        'ML1_FROZEN_DATE',
        r'$.frozenAt',
        'frozenAt must be an ISO YYYY-MM-DD date.',
      );
    }

    final policy = root['policy'];
    if (policy is! Map<String, dynamic>) {
      _add(
        issues,
        'ML1_POLICY_MISSING',
        r'$.policy',
        'Registry policy object is required.',
      );
    } else {
      const requiredTrue = {
        'failClosed',
        'firstPartyOnly',
        'requireAuthorityType',
        'requireClaimClass',
        'requireJurisdictionWhenMaterial',
        'requireEditionOrRevisionWhenApplicable',
        'requireSourceVerificationDate',
      };
      for (final field in requiredTrue) {
        if (policy[field] != true) {
          _add(
            issues,
            'ML1_POLICY_WEAKENED',
            r'$.policy.' + field,
            field + ' must remain true.',
          );
        }
      }
      if (policy['aiIsAuthority'] != false) {
        _add(
          issues,
          'ML1_AI_AUTHORITY',
          r'$.policy.aiIsAuthority',
          'AI must never be treated as an authority.',
        );
      }
      if (policy['unlistedAuthorityDisposition'] != 'block') {
        _add(
          issues,
          'ML1_UNLISTED_AUTHORITY',
          r'$.policy.unlistedAuthorityDisposition',
          'Unlisted authorities must fail closed with block.',
        );
      }
      if (policy['secondarySummaryAsPrimarySource'] != false) {
        _add(
          issues,
          'ML1_SECONDARY_AS_PRIMARY',
          r'$.policy.secondarySummaryAsPrimarySource',
          'Secondary summaries may not substitute for a primary authority.',
        );
      }
    }

    final declaredClasses = _stringSet(root['allowedSourceClasses']);
    if (!declaredClasses.containsAll(allowedSourceClasses) ||
        !allowedSourceClasses.containsAll(declaredClasses)) {
      _add(
        issues,
        'ML1_SOURCE_CLASS_SET',
        r'$.allowedSourceClasses',
        'Allowed source classes must exactly match the ML-1 frozen set.',
      );
    }

    final declaredEditionPolicies = _stringSet(root['allowedEditionPolicies']);
    if (!declaredEditionPolicies.containsAll(allowedEditionPolicies) ||
        !allowedEditionPolicies.containsAll(declaredEditionPolicies)) {
      _add(
        issues,
        'ML1_EDITION_POLICY_SET',
        r'$.allowedEditionPolicies',
        'Allowed edition policies must exactly match the ML-1 frozen set.',
      );
    }

    final authorities = root['authorities'];
    if (authorities is! List) {
      _add(
        issues,
        'ML1_AUTHORITIES_MISSING',
        r'$.authorities',
        'authorities must be a list.',
      );
      return;
    }

    if (authorities.length != requiredAuthorityIds.length) {
      _add(
        issues,
        'ML1_AUTHORITY_COUNT',
        r'$.authorities',
        'Expected exactly ' +
            requiredAuthorityIds.length.toString() +
            ' authority families.',
      );
    }

    final seenIds = <String>{};

    for (var index = 0; index < authorities.length; index++) {
      final item = authorities[index];
      final path = r'$.authorities[' + index.toString() + ']';

      if (item is! Map<String, dynamic>) {
        _add(
          issues,
          'ML1_AUTHORITY_NOT_OBJECT',
          path,
          'Authority entry must be an object.',
        );
        continue;
      }

      _validateAuthority(item, path, issues, seenIds);
    }

    final missing = requiredAuthorityIds.difference(seenIds).toList()..sort();
    if (missing.isNotEmpty) {
      _add(
        issues,
        'ML1_REQUIRED_AUTHORITY_MISSING',
        r'$.authorities',
        'Missing required authority IDs: ' + missing.join(', ') + '.',
      );
    }

    final unexpected = seenIds.difference(requiredAuthorityIds).toList()..sort();
    if (unexpected.isNotEmpty) {
      _add(
        issues,
        'ML1_UNAPPROVED_AUTHORITY',
        r'$.authorities',
        'Unapproved authority IDs present: ' + unexpected.join(', ') + '.',
      );
    }
  }

  void _validateAuthority(
    Map<String, dynamic> authority,
    String path,
    List<AuthorityRegistryIssue> issues,
    Set<String> seenIds,
  ) {
    final id = authority['id'];

    if (id is! String || !RegExp(r'^SRC-\d{2}$').hasMatch(id)) {
      _add(
        issues,
        'ML1_AUTHORITY_ID',
        path + '.id',
        'Authority id must match SRC-##.',
      );
    } else if (!seenIds.add(id)) {
      _add(
        issues,
        'ML1_DUPLICATE_AUTHORITY_ID',
        path + '.id',
        'Duplicate authority id ' + id + '.',
      );
    }

    for (final field in ['canonicalName', 'displayName', 'authorityKind']) {
      if (!_nonEmptyString(authority[field])) {
        _add(
          issues,
          'ML1_REQUIRED_TEXT',
          path + '.' + field,
          field + ' is required.',
        );
      }
    }

    if (authority['regulatoryAuthority'] is! bool) {
      _add(
        issues,
        'ML1_REGULATORY_FLAG',
        path + '.regulatoryAuthority',
        'regulatoryAuthority must be boolean.',
      );
    }

    _requireNonEmptyStringList(
      authority['jurisdictionScopes'],
      path + '.jurisdictionScopes',
      'ML1_JURISDICTION_SCOPE',
      issues,
    );

    final hosts = authority['officialHosts'];
    if (hosts is! List || hosts.isEmpty) {
      _add(
        issues,
        'ML1_OFFICIAL_HOSTS',
        path + '.officialHosts',
        'At least one first-party official host is required.',
      );
    } else {
      final seenHosts = <String>{};
      for (var i = 0; i < hosts.length; i++) {
        final host = hosts[i];
        final hostPath = path + '.officialHosts[' + i.toString() + ']';
        if (host is! String || !_isHostOnly(host)) {
          _add(
            issues,
            'ML1_HOST_FORMAT',
            hostPath,
            'Host must be lowercase hostname only, with no scheme, path, query, fragment, or port.',
          );
          continue;
        }
        if (!seenHosts.add(host)) {
          _add(
            issues,
            'ML1_DUPLICATE_HOST',
            hostPath,
            'Duplicate official host within authority entry.',
          );
        }
      }
    }

    final entryPoints = authority['officialEntryPoints'];
    if (entryPoints is! List || entryPoints.isEmpty) {
      _add(
        issues,
        'ML1_ENTRY_POINTS',
        path + '.officialEntryPoints',
        'At least one official HTTPS entry point is required.',
      );
    } else {
      final allowedHosts = _stringSet(hosts);
      for (var i = 0; i < entryPoints.length; i++) {
        final value = entryPoints[i];
        final entryPath = path + '.officialEntryPoints[' + i.toString() + ']';
        if (value is! String) {
          _add(
            issues,
            'ML1_ENTRY_POINT_FORMAT',
            entryPath,
            'Official entry point must be a string URL.',
          );
          continue;
        }
        final uri = Uri.tryParse(value);
        if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
          _add(
            issues,
            'ML1_ENTRY_POINT_FORMAT',
            entryPath,
            'Official entry point must be an absolute HTTPS URL.',
          );
          continue;
        }
        final hostAllowed = allowedHosts.any(
          (allowed) => uri.host == allowed || uri.host.endsWith('.' + allowed),
        );
        if (!hostAllowed) {
          _add(
            issues,
            'ML1_ENTRY_POINT_HOST',
            entryPath,
            'Entry-point host must be covered by officialHosts.',
          );
        }
      }
    }

    final sourceClasses = _stringSet(authority['permittedSourceClasses']);
    if (sourceClasses.isEmpty) {
      _add(
        issues,
        'ML1_SOURCE_CLASSES_EMPTY',
        path + '.permittedSourceClasses',
        'At least one permitted source class is required.',
      );
    }
    for (final value in sourceClasses) {
      if (!allowedSourceClasses.contains(value)) {
        _add(
          issues,
          'ML1_SOURCE_CLASS_UNKNOWN',
          path + '.permittedSourceClasses',
          'Unknown source class: ' + value + '.',
        );
      }
    }

    _requireNonEmptyStringList(
      authority['permittedSubjects'],
      path + '.permittedSubjects',
      'ML1_PERMITTED_SUBJECTS',
      issues,
    );

    final editionPolicy = authority['editionPolicy'];
    if (editionPolicy is! String ||
        !allowedEditionPolicies.contains(editionPolicy)) {
      _add(
        issues,
        'ML1_EDITION_POLICY',
        path + '.editionPolicy',
        'editionPolicy must be one of the frozen ML-1 policies.',
      );
    }

    final cadence = authority['reviewCadenceDays'];
    if (cadence is! int || cadence <= 0 || cadence > 366) {
      _add(
        issues,
        'ML1_REVIEW_CADENCE',
        path + '.reviewCadenceDays',
        'reviewCadenceDays must be an integer from 1 to 366.',
      );
    }

    if (authority['firstPartyRequired'] != true) {
      _add(
        issues,
        'ML1_FIRST_PARTY_REQUIRED',
        path + '.firstPartyRequired',
        'Every authority entry must require first-party sourcing.',
      );
    }

    if (!allowedStatuses.contains(authority['status'])) {
      _add(
        issues,
        'ML1_AUTHORITY_STATUS',
        path + '.status',
        'Authority status must be active in the ML-1 registry.',
      );
    }

    if (!_isIsoDate(authority['verifiedAt'])) {
      _add(
        issues,
        'ML1_VERIFIED_DATE',
        path + '.verifiedAt',
        'verifiedAt must be an ISO YYYY-MM-DD date.',
      );
    }

    _requireNonEmptyStringList(
      authority['prohibitedAttributions'],
      path + '.prohibitedAttributions',
      'ML1_PROHIBITED_ATTRIBUTIONS',
      issues,
    );
  }

  static bool _nonEmptyString(dynamic value) =>
      value is String && value.trim().isNotEmpty;

  static bool _isIsoDate(dynamic value) {
    if (value is! String ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return false;
    }
    return DateTime.tryParse(value) != null;
  }

  static bool _isHostOnly(String value) {
    if (value != value.toLowerCase()) return false;
    if (value.contains('://') ||
        value.contains('/') ||
        value.contains('?') ||
        value.contains('#') ||
        value.contains(':')) {
      return false;
    }
    return RegExp(
      r'^(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z]{2,}$',
    ).hasMatch(value);
  }

  static Set<String> _stringSet(dynamic value) {
    if (value is! List) return <String>{};
    return value.whereType<String>().toSet();
  }

  static void _requireNonEmptyStringList(
    dynamic value,
    String path,
    String code,
    List<AuthorityRegistryIssue> issues,
  ) {
    if (value is! List ||
        value.isEmpty ||
        value.any((item) => item is! String || item.trim().isEmpty)) {
      _add(
        issues,
        code,
        path,
        'A non-empty list of non-empty strings is required.',
      );
    }
  }

  static void _add(
    List<AuthorityRegistryIssue> issues,
    String code,
    String path,
    String message,
  ) {
    issues.add(
      AuthorityRegistryIssue(code: code, path: path, message: message),
    );
  }
}
