import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const migrationPath =
      'supabase/migrations/20260919075500_fr3_schema_foundation.sql';

  late String sql;

  setUpAll(() {
    sql = _readNormalized(migrationPath);
  });

  test('FR3 schema migration is schema-only', () {
    expect(
      RegExp(
        r'^\s*(insert|copy)\b',
        caseSensitive: false,
        multiLine: true,
      ).hasMatch(sql),
      isFalse,
    );
  });

  test('FR3 keeps Firebase UID as the learner ownership key', () {
    expect(sql, contains('firebase_uid text primary key'));
    expect(
      RegExp(r'firebase_uid\s+uuid', caseSensitive: false).hasMatch(sql),
      isFalse,
    );

    for (final table in _learnerTables) {
      expect(
        sql,
        contains(
          'create table public.$table (\n'
          '  firebase_uid text not null references public.app_users(firebase_uid)',
        ),
        reason: '$table must remain Firebase-UID scoped.',
      );
    }
  });

  test('FR3 enables RLS and denies direct learner Data API roles', () {
    for (final table in _allTables) {
      expect(
        sql,
        contains('alter table public.$table enable row level security;'),
        reason: '$table must have RLS enabled.',
      );
      expect(
        sql,
        contains('revoke all on table public.$table from anon, authenticated;'),
        reason: '$table must remain inaccessible to direct learner roles.',
      );
      expect(
        sql,
        contains(
          'on public.$table for all to anon, authenticated\n'
          '  using (false) with check (false);',
        ),
        reason: '$table must retain the explicit fail-closed RLS policy.',
      );
    }

    expect(
      sql,
      contains(
        'revoke execute on function public.fr_touch_updated_at() '
        'from public, anon, authenticated;',
      ),
    );
  });

  test('FR3 preserves immutable version and rollback constraints', () {
    expect(sql, contains('primary key (content_id, version)'));
    expect(sql, contains('primary key (question_id, version)'));
    expect(sql, contains('published_packages_one_current_uidx'));
    expect(
      sql,
      contains('create unique index exam_study_plans_one_active_uidx'),
    );
    expect(
      sql,
      contains('create unique index daily_study_plans_one_active_per_day_uidx'),
    );
  });

  test('FR3 includes bounded-history query indexes', () {
    for (final indexName in <String>[
      'published_packages_competency_current_idx',
      'learner_question_progress_recent_idx',
      'learner_assessment_attempts_recent_idx',
      'learner_assessment_attempts_competency_idx',
      'readiness_snapshots_recent_idx',
      'exam_study_plans_recent_idx',
      'daily_study_plans_recent_idx',
      'study_plan_block_outcomes_plan_idx',
      'lab_attempts_recent_idx',
      'lab_attempts_lab_idx',
      'learning_twin_evidence_recent_idx',
    ]) {
      expect(sql, contains(indexName), reason: 'Missing $indexName.');
    }
  });

  test('FR3 includes deterministic migration verification ledger', () {
    expect(sql, contains('create table public.fr_migration_ledger'));
    expect(sql, contains('source_checksum_sha256'));
    expect(sql, contains('target_checksum_sha256'));
    expect(
      sql,
      contains(
        "check (validation_status in "
        "('pending', 'matched', 'mismatch', 'failed', 'excluded'))",
      ),
    );
  });

  test('FR3 does not embed Supabase secret credentials', () {
    expect(sql, isNot(contains('sb_secret_')));
    expect(sql, isNot(contains('SUPABASE_SERVICE_ROLE_KEY')));
  });
}

String _readNormalized(String path) => File(path)
    .readAsStringSync()
    .replaceAll('\r\n', '\n')
    .replaceAll('\r', '\n');

const _allTables = <String>[
  'app_users',
  'content_versions',
  'questions',
  'published_packages',
  'learner_subtopic_progress',
  'learner_question_progress',
  'learner_assessment_attempts',
  'readiness_snapshots',
  'exam_study_plans',
  'daily_study_plans',
  'study_plan_block_outcomes',
  'lab_attempts',
  'learning_twin_evidence',
  'fr_migration_ledger',
];

const _learnerTables = <String>[
  'learner_subtopic_progress',
  'learner_question_progress',
  'learner_assessment_attempts',
  'readiness_snapshots',
  'exam_study_plans',
  'daily_study_plans',
  'study_plan_block_outcomes',
  'lab_attempts',
  'learning_twin_evidence',
];
