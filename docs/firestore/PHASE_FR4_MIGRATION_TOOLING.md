# CSP11 Phase FR4 Deterministic Migration Tooling

**Status:** CLOSED / FROZEN  
**Branch:** `phase-fr-firestore-read-reduction`  
**Source checkpoint:** `phase-fr3-closed` at `138f468bbeb10c15a03ec50542eeae13355ad254`  
**Date:** 2026-09-19
**Implementation validation:** GitHub Actions run `35432064574` on `139a141387ffb420b8b035d0a873a61a49d9f05e` — full FR gate green

## Purpose

FR4 builds the deterministic migration machinery required before FR5 shadow-data parity. It does not cut learner traffic over to Supabase and it does not retire Firestore.

The frozen FR4 sequence is:

```text
extract
-> decode Firestore values
-> normalize canonical source payload
-> validate required identity/lifecycle fields
-> detect duplicate target identities
-> compute canonical SHA-256 checksums
-> produce deterministic migration plan
-> optional shadow-only upsert
-> read target back
-> verify target checksum
-> record migration ledger evidence
```

Any duplicate target key, malformed record, unsupported collection or checksum mismatch fails closed.

## Scope

The first frozen FR4 migration registry supports:

- `contentVersions -> content_versions`
- `questions -> questions`

This matches FR5, whose next step is canonical production content/question shadow parity.

Learner progress, readiness history, plans, attempts, LAB attempts and Learning Twin evidence are intentionally not migrated in FR4. Their production migrations remain in their later frozen FR phases. Unknown source collections are reported as `unmapped_collection`; they are never silently skipped.

## Readiness schema correction

FR4 also applies the pre-data readiness schema correction:

- `readiness_snapshots` becomes `readiness_index_snapshots`;
- `competency_evidence_snapshots` is added;
- `competency_readiness_profiles` is added;
- both new tables retain Firebase UID ownership;
- direct `anon` and `authenticated` access remains revoked;
- explicit deny-all RLS remains in place;
- `service_role` remains server-side only.

The correction is schema-only. No learner records are inserted, updated or deleted by the migration file.

## Tooling

Core deterministic normalization:

```text
tool/fr4_migration/fr4_migration_core.dart
```

Executable migration CLI:

```text
tool/fr4_migration/fr4_migrate.dart
```

Deterministic CI fixture:

```text
test/fixtures/fr4/source_documents.json
```

Focused tests:

```text
test/tool/fr4_migration_core_test.dart
test/architecture/phase_fr4_migration_architecture_test.dart
```

## Deterministic hashing

FR4 canonicalizes JSON objects by recursively sorting map keys while preserving list order.

CSP11's reversible `csp11FirestoreNestedListV1` representation is decoded before canonical hashing. This prevents a Firestore storage workaround from becoming a false content difference in Supabase.

Every planned row records:

- source collection;
- source document ID;
- target table;
- target key;
- normalized source SHA-256;
- planned target SHA-256.

Target verification hashes only the frozen planned projection. Server-generated columns such as `created_at` and `updated_at` do not create false mismatches.

## Remote extraction

Remote Firestore extraction uses the official Firestore REST document-list endpoint and paginates until `nextPageToken` is exhausted.

Credentials are read from:

```text
GOOGLE_OAUTH_ACCESS_TOKEN
```

No Google credential is written to the repository or migration evidence.

## Supabase shadow apply

Default execution is plan-only.

Supabase writes require all of the following:

```text
--apply
--confirm=FR4_SHADOW_ONLY
SUPABASE_URL
SUPABASE_SERVICE_ROLE_KEY
```

The service-role key is read from the process environment only.

FR4 has no learner-cutover switch.

Rows are upserted by frozen primary identity:

- content: `content_id, version`
- questions: `question_id, version`
- ledger: `source_system, source_collection, source_id`

After every target upsert, FR4 reads the row back and recomputes the target checksum. The ledger becomes `matched` only after successful read-back verification.

A mismatch is preserved as evidence and fails the run.

## Evidence

Default evidence path:

```text
build/fr4/fr4_migration_evidence.json
```

The report contains:

- source counts by collection;
- target counts by table;
- row count;
- issue count;
- duplicate count;
- normalization-failure count;
- unmapped count;
- deterministic planned rows and checksums;
- per-row apply verification when `--apply` is used.

## Safety rules

FR4 does not:

- change learner runtime routing;
- enable direct Flutter service-role access;
- migrate protected learner state;
- delete Firestore data;
- delete local learner data;
- bypass the Online Access Gate;
- reopen or modify frozen Phase L behavior;
- alter DQG or LAB story semantics;
- perform Supabase primary cutover.

## CI gates

The FR workflow now requires:

1. dependency lock stability;
2. existing FR formatting gate;
3. Flutter analyze;
4. FR1 read-audit tests;
5. local learner-data preservation;
6. FR2 foundation tests;
7. FR3 schema architecture;
8. FR4 deterministic unit tests;
9. FR4 architecture guard;
10. deterministic fixture plan with `readyToApply=true` and zero issues;
11. frozen Phase L4 learner regression;
12. frozen Phase L4 quality gate regression;
13. exact frozen Phase L engine regression;
14. full repository regression;
15. diff hygiene.

## Closure evidence

FR4 implementation validation is green in GitHub Actions run `35432064574` at implementation SHA `139a141387ffb420b8b035d0a873a61a49d9f05e`.

The run passed dependency lock stability, canonical formatting, Flutter analyze, FR1, learner local-data preservation, FR2, FR3, both FR4 gates, every frozen Phase L4 regression suite, the full repository regression and diff hygiene.

The closure-document commit is metadata only. It changes no Dart, SQL, learner runtime or migration behavior and is revalidated before the `phase-fr4-closed` recovery branch is created.

A green FR4 closes tooling, not data parity. No production Firestore content or learner records have been cut over, and Firestore remains authoritative until the later frozen cutover phases.

## NEXT ACTION

After FR4 closure:

```text
FR5 Shadow Data Parity
-> export canonical production content/questions
-> run FR4 deterministic plan
-> shadow upsert to Supabase
-> compare counts, IDs and checksums
-> investigate every mismatch/unmapped record
-> require complete learner-visible structural parity
-> keep Firestore authoritative
```
