import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const migrationPath =
      'supabase/migrations/20260921114000_fr6_published_catalog.sql';
  const fr3MigrationPath =
      'supabase/migrations/20260919075500_fr3_schema_foundation.sql';
  const workflowPath =
      '.github/workflows/phase_fr_firestore_read_reduction.yml';

  late String sql;
  late String fr3Sql;
  late String workflow;

  setUpAll(() {
    sql = File(migrationPath).readAsStringSync();
    fr3Sql = File(fr3MigrationPath).readAsStringSync();
    workflow = File(workflowPath).readAsStringSync();
  });

  test('FR6 catalogue migration is schema-only', () {
    expect(
      RegExp(
        r'^\s*(insert|copy)\b',
        caseSensitive: false,
        multiLine: true,
      ).hasMatch(sql),
      isFalse,
    );
  });

  test('FR6 creates one competency-scoped current catalogue pointer', () {
    expect(sql, contains('create table public.published_catalog'));
    expect(sql, contains('competency_id text primary key'));
    expect(
      RegExp(r'catalog_version', caseSensitive: false).hasMatch(sql),
      isFalse,
      reason:
          'Package history belongs in published_packages; FR6 is the current pointer.',
    );
  });

  test('FR6 carries the frozen content and question package metadata', () {
    for (final field in <String>[
      'content_version',
      'content_checksum_sha256',
      'content_object_path',
      'content_size_bytes',
      'question_version',
      'question_checksum_sha256',
      'question_object_path',
      'question_size_bytes',
      'published_question_count',
      'published_at',
      'active',
    ]) {
      expect(sql, contains(field), reason: 'Missing catalogue field $field.');
    }

    expect(
      sql,
      contains("check (content_checksum_sha256 ~ '^[0-9a-f]{64}\$')"),
    );
    expect(
      sql,
      contains("check (question_checksum_sha256 ~ '^[0-9a-f]{64}\$')"),
    );
    expect(sql, contains('check (content_size_bytes >= 0)'));
    expect(sql, contains('check (question_size_bytes >= 0)'));
    expect(sql, contains('check (published_question_count >= 0)'));
  });

  test('FR6 keeps direct learner Data API access fail-closed', () {
    expect(
      sql,
      contains('alter table public.published_catalog enable row level security;'),
    );
    expect(
      sql,
      contains(
        'revoke all on table public.published_catalog from anon, authenticated;',
      ),
    );
    expect(
      sql,
      contains('grant all on table public.published_catalog to service_role;'),
    );
    expect(
      sql,
      contains(
        'on public.published_catalog for all to anon, authenticated\n'
        '  using (false) with check (false);',
      ),
    );
    expect(
      sql,
      isNot(
        contains('grant select on table public.published_catalog to anon'),
      ),
    );
    expect(
      sql,
      isNot(
        contains(
          'grant select on table public.published_catalog to authenticated',
        ),
      ),
    );
  });

  test('FR6 reuses immutable package history instead of duplicating it', () {
    expect(fr3Sql, contains('create table public.published_packages'));
    expect(
      fr3Sql,
      contains('primary key (package_kind, package_key, version)'),
    );
    expect(fr3Sql, contains('published_packages_one_current_uidx'));
    expect(sql, isNot(contains('create table public.published_packages')));
  });

  test('FR6 is wired into the normal FR and frozen L4 validation path', () {
    expect(workflow, contains('phase-fr6-published-catalogue'));
    expect(workflow, contains('FR6 published catalogue architecture gate'));
    expect(workflow, contains('phase_fr6_published_catalogue_test.dart'));
    expect(workflow, contains('Preserve frozen Phase L4 learner regressions'));
    expect(workflow, contains('Preserve frozen Phase L4 quality gates'));
    expect(workflow, contains('Preserve exact frozen Phase L engine suite'));
    expect(workflow, contains('Full repository regression'));
    expect(workflow, contains('Diff hygiene'));
  });

  test('FR6 does not change learner runtime routing', () {
    expect(
      sql,
      isNot(contains('firebase_uid')),
      reason: 'The catalogue is publication metadata, not learner-owned state.',
    );
    expect(sql, isNot(contains('auth.uid()')));
  });
}
