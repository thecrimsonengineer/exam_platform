import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const migrationPath =
      'supabase/migrations/20260919154500_fr5_authoring_workspace.sql';
  const hardeningPath =
      'supabase/migrations/20260919155200_fr5_authoring_rls_hardening.sql';

  late String sql;
  late String hardeningSql;

  setUpAll(() {
    sql = File(migrationPath).readAsStringSync();
    hardeningSql = File(hardeningPath).readAsStringSync();
  });

  test('FR5 authoring workspace is separate from public production tables', () {
    expect(sql, contains('create schema if not exists authoring;'));
    expect(sql, contains('authoring.content_drafts'));
    expect(sql, contains('authoring.question_drafts'));
    expect(sql, contains("check (status in ('draft', 'review', 'validated'))"));
    expect(sql, contains("check (status in ('published', 'archived'))"));
  });

  test('FR5 authoring workspace is denied to learner Data API roles', () {
    expect(
      sql,
      contains('revoke all on schema authoring from anon, authenticated;'),
    );
    expect(
      sql,
      contains(
        'alter table authoring.content_drafts enable row level security;',
      ),
    );
    expect(
      sql,
      contains(
        'alter table authoring.question_drafts enable row level security;',
      ),
    );
    expect(
      sql,
      contains(
        'revoke all on table authoring.content_drafts from anon, authenticated;',
      ),
    );
    expect(
      sql,
      contains(
        'revoke all on table authoring.question_drafts from anon, authenticated;',
      ),
    );
  });

  test('FR5 authoring workspace has explicit fail-closed learner policies', () {
    expect(
      hardeningSql,
      contains('authoring_content_drafts_deny_learner_direct_access'),
    );
    expect(
      hardeningSql,
      contains('authoring_question_drafts_deny_learner_direct_access'),
    );
    expect(hardeningSql, contains('to anon, authenticated'));
    expect(hardeningSql, contains('using (false)'));
    expect(hardeningSql, contains('with check (false)'));
  });

  test('FR5 authoring workspace remains schema-only and secret-free', () {
    expect(
      RegExp(
        r'^\s*(insert|copy)\b',
        caseSensitive: false,
        multiLine: true,
      ).hasMatch(sql),
      isFalse,
    );
    expect(sql, isNot(contains('sb_secret_')));
    expect(sql, isNot(contains('SUPABASE_SECRET_KEY')));
    expect(
      RegExp(
        r'^\s*(insert|copy)\b',
        caseSensitive: false,
        multiLine: true,
      ).hasMatch(hardeningSql),
      isFalse,
    );
    expect(hardeningSql, isNot(contains('sb_secret_')));
    expect(hardeningSql, isNot(contains('SUPABASE_SECRET_KEY')));
  });
}
