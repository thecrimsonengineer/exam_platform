import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/models/micro_learning/micro_fact.dart';
import 'package:exam_platform/services/micro_learning/micro_fact_schema_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const fixturePath =
      'test/fixtures/micro_learning/valid_micro_fact_v1.json';
  const schemaPath = 'content/micro_learning/micro_fact_schema_v1.json';

  final validator = MicroFactSchemaValidator();

  Map<String, dynamic> loadFixture() {
    return jsonDecode(File(fixturePath).readAsStringSync())
        as Map<String, dynamic>;
  }

  Map<String, dynamic> cloneFixture() {
    return jsonDecode(jsonEncode(loadFixture())) as Map<String, dynamic>;
  }

  test('valid MicroFact v1 fixture passes schema validation', () {
    final result = validator.validateMap(loadFixture());

    expect(result.issues, isEmpty, reason: result.issues.join('\n'));
  });

  test('typed MicroFact model round-trips validated JSON', () {
    final fixture = loadFixture();
    final result = validator.validateMap(fixture);

    expect(result.isValid, isTrue);

    final fact = MicroFact.fromValidatedJson(fixture);

    expect(fact.toJson(), fixture);
  });

  test('published startup-eligible fact requires all review gates to pass', () {
    final fixture = cloneFixture();
    final review = Map<String, dynamic>.from(fixture['review'] as Map);
    review['technicalStatus'] = 'pending';
    fixture['review'] = review;

    final result = validator.validateMap(fixture);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML2_PUBLISHED_REVIEW_NOT_PASS'),
    );
  });

  test('startup eligibility is blocked for non-published status', () {
    final fixture = cloneFixture();
    fixture['status'] = 'validated';

    final result = validator.validateMap(fixture);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML2_STARTUP_REQUIRES_PUBLISHED'),
    );
  });

  test('unknown root field fails closed', () {
    final fixture = cloneFixture();
    fixture['surpriseField'] = true;

    final result = validator.validateMap(fixture);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML2_UNKNOWN_FIELD'),
    );
  });

  test('missing source registry id is rejected', () {
    final fixture = cloneFixture();
    final provenance = Map<String, dynamic>.from(fixture['provenance'] as Map);
    provenance.remove('sourceRegistryId');
    fixture['provenance'] = provenance;

    final result = validator.validateMap(fixture);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML2_REQUIRED_FIELD'),
    );
  });

  test('unknown source class is rejected', () {
    final fixture = cloneFixture();
    final provenance = Map<String, dynamic>.from(fixture['provenance'] as Map);
    provenance['sourceClass'] = 'random_blog';
    fixture['provenance'] = provenance;

    final result = validator.validateMap(fixture);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML2_SOURCE_CLASS'),
    );
  });

  test('source registry id must use SRC-## shape', () {
    final fixture = cloneFixture();
    final provenance = Map<String, dynamic>.from(fixture['provenance'] as Map);
    provenance['sourceRegistryId'] = 'OSHA';
    fixture['provenance'] = provenance;

    final result = validator.validateMap(fixture);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML2_SOURCE_REGISTRY_ID'),
    );
  });

  test('official URL must be absolute HTTPS without credentials', () {
    final fixture = cloneFixture();
    final provenance = Map<String, dynamic>.from(fixture['provenance'] as Map);
    provenance['officialUrl'] = 'https://user:pass@osha.gov/example';
    fixture['provenance'] = provenance;

    final result = validator.validateMap(fixture);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML2_OFFICIAL_URL'),
    );
  });

  test('mapped curriculum requires matching canonical hierarchy prefixes', () {
    final fixture = cloneFixture();
    final curriculum = Map<String, dynamic>.from(fixture['curriculum'] as Map);
    curriculum
      ..['scope'] = 'mapped'
      ..['domainId'] = 'd02'
      ..['competencyId'] = 'd03_c01'
      ..['topicId'] = 'd03_c01_t01'
      ..['subtopicId'] = 'd03_c01_t01_s01';
    fixture['curriculum'] = curriculum;

    final result = validator.validateMap(fixture);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML2_COMPETENCY_DOMAIN_MISMATCH'),
    );
  });

  test('general curriculum scope cannot carry hierarchy placement', () {
    final fixture = cloneFixture();
    final curriculum = Map<String, dynamic>.from(fixture['curriculum'] as Map);
    curriculum['domainId'] = 'd02';
    fixture['curriculum'] = curriculum;

    final result = validator.validateMap(fixture);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML2_GENERAL_MAPPING_NOT_NULL'),
    );
  });

  test('non-none assessment sensitivity requires linked concepts', () {
    final fixture = cloneFixture();
    final assessment = Map<String, dynamic>.from(fixture['assessment'] as Map);
    assessment['sensitivity'] = 'high';
    fixture['assessment'] = assessment;

    final result = validator.validateMap(fixture);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML2_ASSESSMENT_LINK_REQUIRED'),
    );
  });

  test('assessment sensitivity none rejects linked concepts', () {
    final fixture = cloneFixture();
    final assessment = Map<String, dynamic>.from(fixture['assessment'] as Map);
    assessment['linkedQuestionConcepts'] = ['lockout_tagout'];
    fixture['assessment'] = assessment;

    final result = validator.validateMap(fixture);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML2_ASSESSMENT_NONE_WITH_LINKS'),
    );
  });

  test('review due date cannot precede review date', () {
    final fixture = cloneFixture();
    final review = Map<String, dynamic>.from(fixture['review'] as Map);
    review['nextReviewDueAt'] = '2026-09-22';
    fixture['review'] = review;

    final result = validator.validateMap(fixture);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML2_REVIEW_DATE_ORDER'),
    );
  });

  test('published review cannot predate source verification', () {
    final fixture = cloneFixture();
    final provenance = Map<String, dynamic>.from(fixture['provenance'] as Map);
    provenance['sourceVerifiedAt'] = '2026-09-24';
    fixture['provenance'] = provenance;

    final result = validator.validateMap(fixture);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML2_REVIEW_BEFORE_SOURCE_VERIFICATION'),
    );
  });

  test('invalid calendar date is rejected', () {
    final fixture = cloneFixture();
    final provenance = Map<String, dynamic>.from(fixture['provenance'] as Map);
    provenance['sourceVerifiedAt'] = '2026-02-31';
    fixture['provenance'] = provenance;

    final result = validator.validateMap(fixture);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML2_SOURCE_VERIFIED_DATE'),
    );
  });

  test('supersession cannot self-reference', () {
    final fixture = cloneFixture();
    final supersession =
        Map<String, dynamic>.from(fixture['supersession'] as Map);
    supersession['supersedesMicroFactId'] = fixture['microFactId'];
    fixture['supersession'] = supersession;

    final result = validator.validateMap(fixture);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML2_SUPERSESSION_SELF_REFERENCE'),
    );
  });

  test('superseded status requires replacement id', () {
    final fixture = cloneFixture();
    fixture['status'] = 'superseded';
    final runtime = Map<String, dynamic>.from(fixture['runtime'] as Map);
    runtime['startupEligible'] = false;
    fixture['runtime'] = runtime;

    final result = validator.validateMap(fixture);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML2_SUPERSEDED_REPLACEMENT_REQUIRED'),
    );
  });

  test('duplicate tags are rejected', () {
    final fixture = cloneFixture();
    fixture['tags'] = ['lockout_tagout', 'lockout_tagout'];

    final result = validator.validateMap(fixture);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML2_TAGS'),
    );
  });

  test('schema version other than v1 is rejected', () {
    final fixture = cloneFixture();
    fixture['schemaVersion'] = 2;

    final result = validator.validateMap(fixture);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML2_SCHEMA_VERSION'),
    );
  });

  test('formal JSON schema carries the frozen ML-2 contract marker', () {
    final schema =
        jsonDecode(File(schemaPath).readAsStringSync()) as Map<String, dynamic>;
    final extension = Map<String, dynamic>.from(schema['x-csp11'] as Map);
    final required = (schema['required'] as List).cast<String>().toSet();

    expect(schema['additionalProperties'], isFalse);
    expect(extension['phase'], 'ML-2');
    expect(extension['sourceRegistryVersion'], '1.0.0');
    expect(extension['failClosed'], isTrue);
    expect(required, containsAll(MicroFactSchemaValidator.rootKeys));
  });
}
