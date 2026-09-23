import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/services/micro_learning/micro_fact_source_gate_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const fixturePath = 'test/fixtures/micro_learning/valid_micro_fact_v1.json';
  const registryPath = 'content/micro_learning/authority_registry_v1.json';

  const validator = MicroFactSourceGateValidator();

  Map<String, dynamic> loadFact() {
    return jsonDecode(File(fixturePath).readAsStringSync())
        as Map<String, dynamic>;
  }

  Map<String, dynamic> loadRegistry() {
    return jsonDecode(File(registryPath).readAsStringSync())
        as Map<String, dynamic>;
  }

  Map<String, dynamic> cloneMap(Map<String, dynamic> value) {
    return jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
  }

  Map<String, dynamic> cloneFact() => cloneMap(loadFact());

  Map<String, dynamic> cloneRegistry() => cloneMap(loadRegistry());

  test('valid ML-2 fixture passes ML-3 source gates', () {
    final result = validator.validateMaps(
      microFact: loadFact(),
      authorityRegistry: loadRegistry(),
    );

    expect(result.issues, isEmpty, reason: result.issues.join('\n'));
  });

  test(
    'all 15 frozen authority families pass with their own first-party source',
    () {
      final registry = loadRegistry();
      final authorities = (registry['authorities'] as List)
          .cast<Map<String, dynamic>>();

      for (final authority in authorities) {
        final fact = cloneFact();
        final provenance = Map<String, dynamic>.from(fact['provenance'] as Map);

        provenance
          ..['sourceRegistryId'] = authority['id']
          ..['sourceClass'] =
              (authority['permittedSourceClasses'] as List).first as String
          ..['officialUrl'] =
              (authority['officialEntryPoints'] as List).first as String
          ..['sourceTitle'] = authority['displayName'].toString()
          ..['sourceLocator'] = 'ML-3 registry-driven source gate fixture'
          ..['sourceVerifiedAt'] = authority['verifiedAt'].toString()
          ..['sourcePublishedAt'] = null;

        fact['provenance'] = provenance;

        final review = Map<String, dynamic>.from(fact['review'] as Map);
        review['reviewedAt'] = authority['verifiedAt'].toString();
        review['nextReviewDueAt'] = '2027-09-23';
        fact['review'] = review;

        final result = validator.validateMaps(
          microFact: fact,
          authorityRegistry: registry,
        );

        expect(
          result.issues,
          isEmpty,
          reason: authority['id'].toString() + ': ' + result.issues.join('\n'),
        );
      }
    },
  );

  test('unknown but well-shaped source registry id is blocked', () {
    final fact = cloneFact();
    final provenance = Map<String, dynamic>.from(fact['provenance'] as Map);
    provenance['sourceRegistryId'] = 'SRC-99';
    fact['provenance'] = provenance;

    final result = validator.validateMaps(
      microFact: fact,
      authorityRegistry: loadRegistry(),
    );

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML3_UNAPPROVED_AUTHORITY'),
    );
  });

  test('source class must be permitted by referenced authority', () {
    final fact = cloneFact();
    final provenance = Map<String, dynamic>.from(fact['provenance'] as Map);
    provenance['sourceClass'] = 'professional_guideline';
    fact['provenance'] = provenance;

    final result = validator.validateMaps(
      microFact: fact,
      authorityRegistry: loadRegistry(),
    );

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML3_SOURCE_CLASS_NOT_PERMITTED'),
    );
  });

  test('secondary source host is blocked even with valid OSHA source id', () {
    final fact = cloneFact();
    final provenance = Map<String, dynamic>.from(fact['provenance'] as Map);
    provenance['officialUrl'] =
        'https://example.com/summary-of-osha-lockout-tagout';
    fact['provenance'] = provenance;

    final result = validator.validateMaps(
      microFact: fact,
      authorityRegistry: loadRegistry(),
    );

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML3_NOT_FIRST_PARTY_HOST'),
    );
  });

  test('lookalike suffix host cannot impersonate OSHA', () {
    final fact = cloneFact();
    final provenance = Map<String, dynamic>.from(fact['provenance'] as Map);
    provenance['officialUrl'] = 'https://osha.gov.evil.example/1910/1910.147';
    fact['provenance'] = provenance;

    final result = validator.validateMaps(
      microFact: fact,
      authorityRegistry: loadRegistry(),
    );

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML3_NOT_FIRST_PARTY_HOST'),
    );
  });

  test('lookalike prefix host cannot impersonate OSHA', () {
    final fact = cloneFact();
    final provenance = Map<String, dynamic>.from(fact['provenance'] as Map);
    provenance['officialUrl'] = 'https://osha.gov-example.com/1910/1910.147';
    fact['provenance'] = provenance;

    final result = validator.validateMaps(
      microFact: fact,
      authorityRegistry: loadRegistry(),
    );

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML3_NOT_FIRST_PARTY_HOST'),
    );
  });

  test('NIOSH source cannot use an unrelated CDC path', () {
    final fact = cloneFact();
    final provenance = Map<String, dynamic>.from(fact['provenance'] as Map);
    provenance
      ..['sourceRegistryId'] = 'SRC-02'
      ..['sourceClass'] = 'research_or_prevention_guidance'
      ..['sourceTitle'] = 'Unrelated CDC page'
      ..['officialUrl'] = 'https://www.cdc.gov/flu/'
      ..['sourceLocator'] = 'Unrelated CDC path'
      ..['sourceVerifiedAt'] = '2026-09-23';
    fact['provenance'] = provenance;

    final result = validator.validateMaps(
      microFact: fact,
      authorityRegistry: loadRegistry(),
    );

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML3_SOURCE_PATH_OUTSIDE_REGISTERED_SCOPE'),
    );
  });

  test('registered first-party subdomain is accepted', () {
    final fact = cloneFact();
    final provenance = Map<String, dynamic>.from(fact['provenance'] as Map);
    provenance['officialUrl'] =
        'https://www.osha.gov/laws-regs/regulations/standardnumber/1910/1910.147';
    fact['provenance'] = provenance;

    final result = validator.validateMaps(
      microFact: fact,
      authorityRegistry: loadRegistry(),
    );

    expect(result.issues, isEmpty, reason: result.issues.join('\n'));
  });

  test('embedded URL credentials fail before source trust is granted', () {
    final fact = cloneFact();
    final provenance = Map<String, dynamic>.from(fact['provenance'] as Map);
    provenance['officialUrl'] = 'https://osha.gov@evil.example/1910/1910.147';
    fact['provenance'] = provenance;

    final result = validator.validateMaps(
      microFact: fact,
      authorityRegistry: loadRegistry(),
    );

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML3_FACT_PREREQUISITE_INVALID'),
    );
  });

  test('tampered registry fails closed before fact source evaluation', () {
    final registry = cloneRegistry();
    final policy = Map<String, dynamic>.from(registry['policy'] as Map);
    policy['firstPartyOnly'] = false;
    registry['policy'] = policy;

    final result = validator.validateMaps(
      microFact: loadFact(),
      authorityRegistry: registry,
    );

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML3_REGISTRY_PREREQUISITE_INVALID'),
    );
  });

  test('registry version must match frozen ML-2 binding', () {
    final registry = cloneRegistry();
    registry['registryVersion'] = '2.0.0';

    final result = validator.validateMaps(
      microFact: loadFact(),
      authorityRegistry: registry,
    );

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML3_REGISTRY_VERSION_MISMATCH'),
    );
  });

  test('source verification cannot predate registry verification', () {
    final fact = cloneFact();
    final provenance = Map<String, dynamic>.from(fact['provenance'] as Map);
    provenance['sourceVerifiedAt'] = '2026-09-22';
    fact['provenance'] = provenance;

    final review = Map<String, dynamic>.from(fact['review'] as Map);
    review['reviewedAt'] = '2026-09-23';
    fact['review'] = review;

    final result = validator.validateMaps(
      microFact: fact,
      authorityRegistry: loadRegistry(),
    );

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML3_SOURCE_VERIFIED_BEFORE_REGISTRY'),
    );
  });

  test('source publication date cannot be after source verification date', () {
    final fact = cloneFact();
    final provenance = Map<String, dynamic>.from(fact['provenance'] as Map);
    provenance['sourcePublishedAt'] = '2026-09-24';
    fact['provenance'] = provenance;

    final result = validator.validateMaps(
      microFact: fact,
      authorityRegistry: loadRegistry(),
    );

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML3_SOURCE_PUBLISHED_AFTER_VERIFICATION'),
    );
  });

  test('structurally invalid fact never reaches source trust evaluation', () {
    final fact = cloneFact();
    fact['schemaVersion'] = 99;

    final result = validator.validateMaps(
      microFact: fact,
      authorityRegistry: loadRegistry(),
    );

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML3_FACT_PREREQUISITE_INVALID'),
    );
  });

  test('malformed registry JSON fails closed', () {
    final result = validator.validateJson(
      microFactJson: jsonEncode(loadFact()),
      authorityRegistryJson: '{bad-json',
    );

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML3_REGISTRY_JSON_INVALID'),
    );
  });
}
