import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const sourcePath = 'supabase/functions/learner-question-packages/index.ts';
  const workflowPath =
      '.github/workflows/phase_fr_firestore_read_reduction.yml';

  late String source;
  late String workflow;

  setUpAll(() {
    source = File(sourcePath).readAsStringSync();
    workflow = File(workflowPath).readAsStringSync();
  });

  test('FR10C preserves exact Firebase project authentication gate', () {
    expect(source, contains('csp11-exam-platform'));
    expect(source, contains('issuer: firebaseIssuer'));
    expect(source, contains('audience: firebaseProjectId'));
    expect(source, contains('algorithms: ["RS256"]'));
    expect(source, contains('const uid = await verifyFirebaseUid(req);'));
  });

  test('FR10C adds separate content catalog and competency operations', () {
    expect(source, contains('operation === "content_catalog"'));
    expect(source, contains('operation === "content_competency"'));
    expect(source, contains('handleContentCatalog'));
    expect(source, contains('handleContentCompetency'));
    expect(source, contains('knownContentVersion'));
    expect(source, contains('knownContentChecksumSha256'));
  });

  test('FR10C reads compact content catalogue columns only', () {
    expect(
      source,
      contains(
        '"competency_id,content_version,content_checksum_sha256,'
        'content_object_path,content_size_bytes"',
      ),
    );
    expect(source, contains('ContentCatalogDescriptor'));
    expect(source, contains('contentVersion'));
    expect(source, contains('contentChecksumSha256'));
    expect(source, contains('contentSizeBytes'));
  });

  test('FR10C validates immutable content package object paths', () {
    expect(
      source,
      contains(r'content/${competencyId}/v${version}.json.gz'),
    );
    expect(source, contains('row.content_object_path !== expectedPath'));
  });

  test('FR10C signs content only from the private package bucket', () {
    expect(source, contains('csp11-published-packages'));
    expect(source, contains('signedUrlTtlSeconds = 60'));
    expect(
      source,
      contains(
        r'content/${descriptor.competencyId}/'
        r'v${descriptor.contentVersion}.json.gz',
      ),
    );
  });

  test('FR10C unchanged content response is URL-free', () {
    final handlerStart = source.indexOf('async function handleContentCompetency');
    final catalogStart = source.indexOf('async function handleContentCatalog');
    expect(handlerStart, greaterThanOrEqualTo(0));
    expect(catalogStart, greaterThan(handlerStart));

    final handler = source.substring(handlerStart, catalogStart);
    final currentBranch = handler.indexOf('if (current) {');
    final signedUrlCreation = handler.indexOf('.createSignedUrl(');

    expect(currentBranch, greaterThanOrEqualTo(0));
    expect(signedUrlCreation, greaterThan(currentBranch));

    final currentBlock = handler.substring(currentBranch, signedUrlCreation);
    expect(currentBlock, contains('current: true'));
    expect(currentBlock, isNot(contains('signedUrl')));
  });

  test('FR10C content responses never expose object paths', () {
    final handlerStart = source.indexOf('async function handleContentCompetency');
    final handlerEnd = source.indexOf('async function handleContentCatalog');
    final contentHandler = source.substring(handlerStart, handlerEnd);

    expect(contentHandler, isNot(contains('contentObjectPath')));
    expect(contentHandler, isNot(contains('content_object_path:')));
  });

  test('FR10C preserves the existing FR9 question operations', () {
    expect(source, contains('operation === "competency"'));
    expect(source, contains('operation === "catalog"'));
    expect(
      source,
      contains(
        r'questions/${descriptor.competencyId}/'
        r'v${descriptor.questionVersion}.json.gz',
      ),
    );
  });

  test('FR10C gateway security gate remains in main FR CI', () {
    expect(workflow, contains('FR10 content gateway security tests'));
    expect(
      workflow,
      contains(
        'flutter test test/architecture/'
        'phase_fr10_content_gateway_test.dart',
      ),
    );
  });
}
