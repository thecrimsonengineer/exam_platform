import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const corePath = 'tool/fr7_package_publish/fr7_package_publish_core.dart';
  const cliPath = 'tool/fr7_package_publish/fr7_package_publish.dart';
  const workflowPath =
      '.github/workflows/phase_fr_firestore_read_reduction.yml';
  const productionWorkflowPath =
      '.github/workflows/phase_fr7_production_package_publish.yml';
  const atomicSqlPath = 'supabase/fr7/fr7_atomic_publication.sql';

  late String core;
  late String cli;
  late String workflow;
  late String productionWorkflow;
  late String atomicSql;

  setUpAll(() {
    core = File(corePath).readAsStringSync();
    cli = File(cliPath).readAsStringSync();
    workflow = File(workflowPath).readAsStringSync();
    productionWorkflow = File(productionWorkflowPath).readAsStringSync();
    atomicSql = File(atomicSqlPath).readAsStringSync();
  });

  test('FR7 publisher stays out of Flutter learner runtime', () {
    expect(core, isNot(contains('package:flutter/')));
    expect(cli, isNot(contains('package:flutter/')));
    expect(cli, isNot(contains('supabase_flutter')));
    expect(cli, contains('SUPABASE_SECRET_KEY'));
    expect(cli, contains('SUPABASE_SERVICE_ROLE_KEY'));
    expect(cli, contains("uri.path.contains('/storage/v1/')"));
    expect(cli, contains('HttpHeaders.authorizationHeader'));
    expect(cli, contains("'NoSuchBucket'"));
    expect(
      cli,
      contains("_isStorageNotFound(response, expectedCode: 'NoSuchBucket')"),
    );
  });

  test('FR7 uses a private immutable package bucket', () {
    expect(core, contains("fr7BucketId = 'csp11-published-packages'"));
    expect(cli, contains("'public': false"));
    expect(cli, contains("'x-upsert': 'false'"));
    expect(cli, contains('Future<_ByteHttpResult> downloadObject('));
    expect(cli, contains("'authenticated'"));
    expect(cli, isNot(contains("'DELETE'")));
    expect(cli, isNot(contains('"DELETE"')));
  });

  test('FR7 recognizes only explicit legacy-wrapped Storage 404s', () {
    expect(
      cli,
      contains("_isStorageNotFound(response, expectedCode: 'NoSuchBucket')"),
    );
    expect(
      cli,
      contains("_isStorageNotFound(existing, expectedCode: 'NoSuchKey')"),
    );
    expect(cli, contains("decoded['statusCode']?.toString() == '404'"));
    expect(cli, contains("decoded['code']?.toString() == expectedCode"));
  });

  test('FR7 package bytes are deterministic and checksum-addressed', () {
    expect(core, contains('fr4CanonicalJson(envelope)'));
    expect(core, contains('gzip.encode(uncompressed)'));
    expect(core, contains('sha256.convert(compressed)'));
    expect(core, contains('fr7StoragePath'));
    expect(core, contains('reusesExistingPackage'));
  });

  test('FR7 commits package current state and catalogue atomically', () {
    final ensureObject = cli.indexOf('ensureImmutableObject(package)');
    final verifyObjects = cli.indexOf('await _verifyObjects(client, plan)');
    final atomicCommit = cli.indexOf('commitCompetencyPublication(');

    expect(ensureObject, greaterThan(0));
    expect(verifyObjects, greaterThan(ensureObject));
    expect(atomicCommit, greaterThan(verifyObjects));
    expect(cli, isNot(contains('selectCurrentPackage(package)')));
    expect(cli, isNot(contains('upsertCatalogRows(catalogUpserts)')));

    expect(
      atomicSql,
      contains('function public.fr7_commit_competency_publication'),
    );
    expect(atomicSql, contains('security invoker'));
    expect(atomicSql, contains('pg_advisory_xact_lock'));
    expect(atomicSql, contains('Catalogue switch is deliberately last'));
    expect(
      atomicSql,
      contains(
        'revoke execute on function '
        'public.fr7_commit_competency_publication(jsonb)',
      ),
    );
    expect(
      atomicSql,
      contains(
        'grant execute on function '
        'public.fr7_commit_competency_publication(jsonb) to service_role;',
      ),
    );
  });

  test('FR7 rollback is an atomic pointer switch with no object deletion', () {
    expect(
      atomicSql,
      contains('function public.fr7_rollback_competency_publication'),
    );
    expect(atomicSql, contains('p_content_version integer'));
    expect(atomicSql, contains('p_question_version integer'));
    expect(atomicSql, isNot(contains('delete from storage.objects')));
    expect(atomicSql, isNot(contains('delete from public.published_packages')));
  });

  test('FR7 production workflow is manual and explicitly confirmed', () {
    expect(productionWorkflow, contains('workflow_dispatch:'));
    expect(
      productionWorkflow,
      contains("github.ref == 'refs/heads/phase-fr7-storage-publishing'"),
    );
    expect(productionWorkflow, contains('SUPABASE_SECRET_KEY'));
    expect(productionWorkflow, contains('FR7_PUBLISH_PACKAGES'));
    expect(
      productionWorkflow,
      contains('FR7: authorized one-shot production package publish'),
    );
    expect(productionWorkflow, contains('.github/fr7_publish_trigger'));
    expect(productionWorkflow, contains('--preflight'));
    expect(productionWorkflow, contains('--publish'));
    expect(productionWorkflow, isNot(contains('upload-artifact')));
  });

  test('FR7 is wired into FR and frozen L4/full-repository gates', () {
    expect(workflow, contains('phase-fr7-storage-publishing'));
    expect(workflow, contains('FR7 package publishing unit tests'));
    expect(workflow, contains('FR7 deterministic fixture packaging gate'));
    expect(workflow, contains('Preserve frozen Phase L4 learner regressions'));
    expect(workflow, contains('Preserve frozen Phase L4 quality gates'));
    expect(workflow, contains('Preserve exact frozen Phase L engine suite'));
    expect(workflow, contains('Full repository regression'));
    expect(workflow, contains('Diff hygiene'));
  });
}
