import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/services/micro_learning/authority_registry_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const registryPath = 'content/micro_learning/authority_registry_v1.json';
  final validator = AuthorityRegistryValidator();

  String loadRegistry() => File(registryPath).readAsStringSync();

  test('frozen ML-1 authority registry passes validation', () {
    final result = validator.validateJson(loadRegistry());

    expect(result.issues, isEmpty, reason: result.issues.join('\n'));
  });

  test('registry contains exactly the frozen 15 authority families', () {
    final root = jsonDecode(loadRegistry()) as Map<String, dynamic>;
    final authorities = root['authorities'] as List<dynamic>;
    final ids = authorities
        .cast<Map<String, dynamic>>()
        .map((authority) => authority['id'])
        .toSet();

    expect(ids, AuthorityRegistryValidator.requiredAuthorityIds);
    expect(authorities, hasLength(15));
  });

  test('unlisted authority fails closed', () {
    final root = jsonDecode(loadRegistry()) as Map<String, dynamic>;
    final authorities = List<Map<String, dynamic>>.from(
      (root['authorities'] as List<dynamic>).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );

    authorities.removeLast();
    authorities.add({
      ...authorities.first,
      'id': 'SRC-99',
      'canonicalName': 'Unapproved Source',
      'displayName': 'Unapproved Source',
    });
    root['authorities'] = authorities;

    final result = validator.validateJson(jsonEncode(root));

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML1_UNAPPROVED_AUTHORITY'),
    );
  });

  test('duplicate authority id is rejected', () {
    final root = jsonDecode(loadRegistry()) as Map<String, dynamic>;
    final authorities = List<Map<String, dynamic>>.from(
      (root['authorities'] as List<dynamic>).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );

    authorities[1]['id'] = authorities[0]['id'];
    root['authorities'] = authorities;

    final result = validator.validateJson(jsonEncode(root));

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML1_DUPLICATE_AUTHORITY_ID'),
    );
  });

  test('non-first-party authority policy is rejected', () {
    final root = jsonDecode(loadRegistry()) as Map<String, dynamic>;
    final authorities = List<Map<String, dynamic>>.from(
      (root['authorities'] as List<dynamic>).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );

    authorities.first['firstPartyRequired'] = false;
    root['authorities'] = authorities;

    final result = validator.validateJson(jsonEncode(root));

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML1_FIRST_PARTY_REQUIRED'),
    );
  });

  test('entry point outside approved official hosts is rejected', () {
    final root = jsonDecode(loadRegistry()) as Map<String, dynamic>;
    final authorities = List<Map<String, dynamic>>.from(
      (root['authorities'] as List<dynamic>).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );

    authorities.first['officialEntryPoints'] = [
      'https://example.com/safety-summary',
    ];
    root['authorities'] = authorities;

    final result = validator.validateJson(jsonEncode(root));

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML1_ENTRY_POINT_HOST'),
    );
  });

  test('AI cannot be promoted to authority', () {
    final root = jsonDecode(loadRegistry()) as Map<String, dynamic>;
    final policy = Map<String, dynamic>.from(root['policy'] as Map);
    policy['aiIsAuthority'] = true;
    root['policy'] = policy;

    final result = validator.validateJson(jsonEncode(root));

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML1_AI_AUTHORITY'),
    );
  });

  test('unknown source class is rejected', () {
    final root = jsonDecode(loadRegistry()) as Map<String, dynamic>;
    final authorities = List<Map<String, dynamic>>.from(
      (root['authorities'] as List<dynamic>).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );

    authorities.first['permittedSourceClasses'] = ['random_blog'];
    root['authorities'] = authorities;

    final result = validator.validateJson(jsonEncode(root));

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML1_SOURCE_CLASS_UNKNOWN'),
    );
  });

  test('official host must be a hostname rather than a URL', () {
    final root = jsonDecode(loadRegistry()) as Map<String, dynamic>;
    final authorities = List<Map<String, dynamic>>.from(
      (root['authorities'] as List<dynamic>).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );

    authorities.first['officialHosts'] = ['https://www.osha.gov/'];
    root['authorities'] = authorities;

    final result = validator.validateJson(jsonEncode(root));

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML1_HOST_FORMAT'),
    );
  });
}
