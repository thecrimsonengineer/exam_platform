import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const schemaPath =
      'supabase/migrations/20260919081800_fr4_readiness_remote_schema.sql';
  const corePath = 'tool/fr4_migration/fr4_migration_core.dart';
  const cliPath = 'tool/fr4_migration/fr4_migrate.dart';
  const workflowPath =
      '.github/workflows/phase_fr_firestore_read_reduction.yml';

  late String schema;
  late String core;
  late String cli;
  late String workflow;

  setUpAll(() {
    schema = File(schemaPath).readAsStringSync();
    core = File(corePath).readAsStringSync();
    cli = File(cliPath).readAsStringSync();
    workflow = File(workflowPath).readAsStringSync();
  });

  test('FR4 readiness correction is schema-only and fail-closed', () {
    expect(
      RegExp(
        r'^\s*(insert|copy|update|delete)\b',
        caseSensitive: false,
        multiLine: true,
      ).hasMatch(schema),
      isFalse,
    );
    expect(
      schema,
      contains(
        'alter table public.readiness_snapshots\n'
        '  rename to readiness_index_snapshots;',
      ),
    );

    for (final table in <String>[
      'competency_evidence_snapshots',
      'competency_readiness_profiles',
    ]) {
      expect(
        schema,
        contains('alter table public.$table enable row level security;'),
      );
      expect(
        schema,
        contains('revoke all on table public.$table from anon, authenticated;'),
      );
      expect(
        schema,
        contains(
          'on public.$table for all to anon, authenticated\n'
          '  using (false) with check (false);',
        ),
      );
    }
  });

  test('FR4 tooling stays out of learner runtime', () {
    expect(core, isNot(contains('package:flutter/')));
    expect(cli, isNot(contains('package:flutter/')));
    expect(cli, isNot(contains('firebase_core')));
    expect(cli, isNot(contains('supabase_flutter')));
    expect(cli, contains('FR4_SHADOW_ONLY'));
    expect(cli, contains('SUPABASE_SERVICE_ROLE_KEY'));
    expect(cli, contains('GOOGLE_OAUTH_ACCESS_TOKEN'));
  });

  test('FR4 supported source collections are explicit and bounded', () {
    expect(core, contains("'contentVersions'"));
    expect(core, contains("'questions'"));
    expect(core, contains("'unmapped_collection'"));
    expect(core, contains("'duplicate_target_key'"));
    expect(core, contains("'normalization_failure'"));
    expect(core, contains('source_checksum_sha256'));
    expect(core, contains('target_checksum_sha256'));
  });

  test('FR4 CI preserves frozen L4 and full repository regression', () {
    expect(workflow, contains('FR4 deterministic migration unit tests'));
    expect(workflow, contains('FR4 deterministic fixture plan gate'));
    expect(
      workflow,
      contains('Preserve frozen Phase L4 learner regressions'),
    );
    expect(workflow, contains('Preserve frozen Phase L4 quality gates'));
    expect(workflow, contains('Preserve exact frozen Phase L engine suite'));
    expect(workflow, contains('Full repository regression'));
  });
}
