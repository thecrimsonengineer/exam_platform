# CSP11 Phase FR3 PostgreSQL Schema Foundation

**Status:** IMPLEMENTED, VALIDATION IN PROGRESS  
**Branch:** `phase-fr-firestore-read-reduction`  
**Supabase project:** `csp11-supabase`  
**Project ref:** `esfycnmfywxczfillioj`  
**Region:** `ap-south-1`  
**PostgreSQL:** 17  
**Date:** 2026-09-19

## Purpose

FR3 establishes the PostgreSQL schema, access boundary, integrity constraints and query indexes needed before any Firestore-to-Supabase data migration.

This phase is schema-only. No production learner, content, question, readiness, LAB or Learning Twin records are copied in FR3.

## Access architecture

Protected CSP11 data is not exposed directly to Flutter through PostgREST.

The current FR boundary is:

```text
Flutter
  -> Firebase Auth ID token
  -> Supabase Edge authorization gateway
  -> reviewed server-side data operation
  -> PostgreSQL / Storage
```

All FR3 public tables have RLS enabled. Direct `anon` and `authenticated` table privileges are revoked. Each table also has an explicit fail-closed `FOR ALL` RLS policy for those client roles using `false` for both `USING` and `WITH CHECK`. Server-side access remains available to `service_role`, which must never be embedded in Flutter.

The shared trigger function also revokes direct execution from `PUBLIC`, `anon` and `authenticated`.

## Canonical tables

FR3 creates:

- `app_users`
- `content_versions`
- `questions`
- `published_packages`
- `learner_subtopic_progress`
- `learner_question_progress`
- `learner_assessment_attempts`
- `readiness_snapshots`
- `exam_study_plans`
- `daily_study_plans`
- `study_plan_block_outcomes`
- `lab_attempts`
- `learning_twin_evidence`
- `fr_migration_ledger`

Firebase UID remains the learner ownership identifier. It is stored as `text`, not converted to a Supabase Auth UUID.

## Version and rollback rules

Content and questions are versioned by composite keys.

Published package metadata is immutable by version and allows only one `is_current` package for each package kind/key.

Exam plans retain plan versions and allow only one active plan per learner.

Daily plans retain versions and allow only one active plan for a learner/date.

The FR migration ledger records source and target checksums plus validation status so FR4 can prove deterministic parity before cutover.

## Query-index evidence

Representative PostgreSQL `EXPLAIN` checks were run after schema creation.

| Query shape | Index selected |
|---|---|
| current competency package | `published_packages_competency_current_idx` |
| recent readiness snapshots | `readiness_snapshots_recent_idx` |
| active exam plan | `exam_study_plans_one_active_uidx` |
| active daily plan | `daily_study_plans_one_active_per_day_uidx` |
| recent attempts for competency | `learner_assessment_attempts_competency_idx` |

The empty-database readiness plan used a bitmap index scan followed by a small sort. The index was still selected. This will be re-measured with realistic shadow data before production cutover.

## Advisor result

Immediately after schema creation:

- Security advisor: **zero lints** after explicit deny-all client RLS policies were added.
- Performance advisor: unused-index informational findings only. This is expected because every FR3 table still contains zero rows. Representative `EXPLAIN` checks nevertheless select the intended FR3 indexes.

## Data-preservation result

Verified row counts remain zero for the new Supabase data tables after FR3 schema creation.

No existing Firebase or on-device learner data has been deleted, renamed or migrated.

## FR3 closure gates

FR3 may close only when:

1. schema architecture tests are green;
2. full Flutter regression and frozen Phase L suites are green;
3. all FR3 tables have RLS enabled;
4. direct `anon` and `authenticated` access remains denied;
5. representative query plans use the intended indexes;
6. security and performance advisors show no unresolved warning/error finding;
7. the Supabase production tables still contain no migrated learner/content records;
8. the final schema file is frozen before FR4 migration tooling starts.

## NEXT ACTION

Complete FR3 CI, re-run advisors, freeze the FR3 recovery point, then begin **FR4 deterministic Firestore-to-Supabase migration tooling**.

FR4 builds repeatable extraction, normalization, upsert, checksum, count, duplicate, failure and unmapped-record verification. It must not cut learners over to Supabase.
