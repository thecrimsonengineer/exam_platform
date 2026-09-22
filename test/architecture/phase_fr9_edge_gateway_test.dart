import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const sourcePath = 'supabase/functions/learner-question-packages/index.ts';
  const configPath = 'supabase/config.toml';
  const workflowPath =
      '.github/workflows/phase_fr_firestore_read_reduction.yml';

  late String source;
  late String config;
  late String workflow;

  setUpAll(() {
    source = File(sourcePath).readAsStringSync();
    config = File(configPath).readAsStringSync();
    workflow = File(workflowPath).readAsStringSync();
  });

  test('FR9C gateway verifies only the CSP11 Firebase project', () {
    expect(source, contains('csp11-exam-platform'));
    expect(source, contains('securetoken.google.com'));
    expect(source, contains('service_accounts/v1/jwk'));
    expect(source, contains('jwtVerify'));
    expect(source, contains('algorithms: ["RS256"]'));
    expect(source, contains('audience: firebaseProjectId'));
    expect(source, contains('issuer: firebaseIssuer'));
  });

  test('FR9C custom Firebase gateway disables platform Supabase JWT check', () {
    expect(config, contains('[functions.learner-question-packages]'));
    expect(
      config,
      contains('[functions.learner-question-packages]\nverify_jwt = false'),
    );
  });

  test('FR9C authenticates before creating privileged Supabase client', () {
    final handler = source.substring(source.indexOf('Deno.serve'));
    final verifyIndex = handler.indexOf(
      'const uid = await verifyFirebaseUid(req);',
    );
    final unauthorizedIndex = handler.indexOf(
      'return jsonResponse(401, { error: "invalid_firebase_token" });',
    );
    final clientIndex = handler.indexOf('supabase = serverClient();');

    expect(verifyIndex, greaterThanOrEqualTo(0));
    expect(unauthorizedIndex, greaterThan(verifyIndex));
    expect(clientIndex, greaterThan(unauthorizedIndex));
  });

  test(
    'FR9C privileged client uses server-only modern secret key environment',
    () {
      expect(source, contains('Deno.env.get("SUPABASE_SECRET_KEYS")'));
      expect(source, contains('secretKey.startsWith("sb_secret_")'));
      expect(source, isNot(contains('SUPABASE_SERVICE_ROLE_KEY')));
    },
  );

  test('FR9C source contains no literal privileged secret value', () {
    final literalSecretPattern = RegExp(r'sb_secret_[A-Za-z0-9_-]{12,}');
    expect(literalSecretPattern.hasMatch(source), isFalse);
    expect(source, isNot(contains('service_role')));
  });

  test('FR9C competency lookup reads one active catalogue row only', () {
    expect(source, contains('.from("published_catalog")'));
    expect(source, contains('.eq("competency_id", competencyId)'));
    expect(source, contains('.eq("active", true)'));
    expect(source, contains('.maybeSingle()'));
    expect(source, isNot(contains('.select("*")')));
  });

  test('FR9C validates canonical immutable question package paths', () {
    expect(source, contains(r'questions/${competencyId}/v${version}.json.gz'));
    expect(source, contains('row.question_object_path !== expectedPath'));
    expect(source, contains('catalog_integrity_error'));
  });

  test('FR9C signs only the private published package bucket for 60 seconds', () {
    expect(source, contains('csp11-published-packages'));
    expect(source, contains('signedUrlTtlSeconds = 60'));
    expect(source, contains('.createSignedUrl('));
    expect(
      source,
      contains(
        r'questions/${descriptor.competencyId}/v${descriptor.questionVersion}.json.gz',
      ),
    );
  });

  test('FR9C returns no signed URL when the cached version is current', () {
    final currentBranch = source.indexOf('if (current) {');
    final signedUrlCreation = source.indexOf('.createSignedUrl(');

    expect(currentBranch, greaterThanOrEqualTo(0));
    expect(signedUrlCreation, greaterThan(currentBranch));

    final currentBlock = source.substring(currentBranch, signedUrlCreation);
    expect(currentBlock, contains('current: true'));
    expect(currentBlock, isNot(contains('signedUrl')));
  });

  test('FR9C catalog discovery exposes only compact Ultra Hard metadata', () {
    expect(source, contains('.from("questions")'));
    expect(source, contains('.select("competency_id")'));
    expect(source, contains('.eq("status", "published")'));
    expect(source, contains('.contains("tags", [ultraHardTag])'));
    expect(source, contains('ultraHardCount'));
    expect(source, isNot(contains('"stem"')));
    expect(source, isNot(contains('"options"')));
    expect(source, isNot(contains('"explanation"')));
    expect(source, isNot(contains('"reference_text"')));
  });

  test('FR9C responses are explicitly non-cacheable', () {
    expect(source, contains('"Cache-Control": "no-store"'));
  });

  test('FR9C security guard remains in the main FR workflow', () {
    expect(workflow, contains('FR9 Edge gateway security tests'));
    expect(
      workflow,
      contains(
        'flutter test test/architecture/phase_fr9_edge_gateway_test.dart',
      ),
    );
  });
}
