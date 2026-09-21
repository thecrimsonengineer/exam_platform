import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const corePath =
      'tool/fr7_package_publish/fr7_package_publish_core.dart';
  const cliPath =
      'tool/fr7_package_publish/fr7_package_publish.dart';
  const workflowPath =
      '.github/workflows/phase_fr_firestore_read_reduction.yml';
  const productionWorkflowPath =
      '.github/workflows/phase_fr7_production_package_publish.yml';

  late String core;
  late String cli;
  late String workflow;
  late String productionWorkflow;

  setUpAll(() {
    core = File(corePath).readAsStringSync();
    cli = File(cliPath).readAsStringSync();
    workflow = File(workflowPath).readAsStringSync();
    productionWorkflow = File(productionWorkflowPath).readAsStringSync();
  });

  test('FR7 publisher stays out of Flutter learner runtime', () {
    expect(core, isNot(contains('package:flutter/')));
    expect(cli, isNot(contains('package:flutter/')));
    expect(cli, isNot(contains('supabase_flutter')));
    expect(cli, contains('SUPABASE_SECRET_KEY'));
    expect(cli, contains('SUPABASE_SERVICE_ROLE_KEY'));
  });

  test('FR7 uses a private immutable package bucket', () {
    expect(core, contains("fr7BucketId = 'csp11-published-packages'"));
    expect(cli, contains("'public': false"));
    expect(cli, contains("'x-upsert': 'false'"));
    expect(cli, contains("'object', 'authenticated'"));
    expect(cli, isNot(contains("'DELETE'")));
    expect(cli, isNot(contains('"DELETE"')));
  });

  test('FR7 package bytes are deterministic and checksum-addressed', () {
    expect(core, contains('fr4CanonicalJson(envelope)'));
    expect(core, contains('gzip.encode(uncompressed)'));
    expect(core, contains('sha256.convert(compressed)'));
    expect(core, contains('fr7StoragePath'));
    expect(core, contains('reusesExistingPackage'));
  });

  test('FR7 keeps catalogue mutation after object and package readiness', () {
    final ensureObject = cli.indexOf('ensureImmutableObject(package)');
    final registration = cli.indexOf('insertPackageRegistration(');
    final currentSelection = cli.indexOf('selectCurrentPackage(package)');
    final catalogue = cli.indexOf('upsertCatalogRows(catalogUpserts)');

    expect(ensureObject, greaterThan(0));
    expect(registration, greaterThan(ensureObject));
    expect(currentSelection, greaterThan(registration));
    expect(catalogue, greaterThan(currentSelection));
  });

  test('FR7 production workflow is manual and explicitly confirmed', () {
    expect(productionWorkflow, contains('workflow_dispatch:'));
    expect(
      productionWorkflow,
      contains("github.ref == 'refs/heads/phase-fr7-storage-publishing'"),
    );
    expect(productionWorkflow, contains('SUPABASE_SECRET_KEY'));
    expect(productionWorkflow, contains('FR7_PUBLISH_PACKAGES'));
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
