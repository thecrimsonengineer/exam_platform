# CSP11 Phase FR5 Shadow Data Parity

Status: IMPLEMENTATION GREEN / LIVE PRODUCTION PARITY PENDING
Branch: phase-fr5-shadow-data-parity
Source checkpoint: phase-fr4-closed at bce142b3a337dfc8e93e1a57a47faac1a6a207cd
Date: 2026-09-19
Implementation validation: GitHub Actions run 35433210098 is fully green

## Purpose

FR5 copies canonical production contentVersions and questions into Supabase shadow tables and proves complete structural and learner-visible parity before any learner cutover.

Firestore remains authoritative throughout FR5. FR5 does not modify learner runtime routing.

## Frozen FR5 data scope

FR5 migrates only the canonical source collections already frozen by FR4:

- published contentVersions to content_versions
- published questions to questions

Draft, review and validated authoring records are explicitly outside the FR5 production migration. Learner progress, attempts, readiness history, plans, LAB attempts and Learning Twin evidence remain outside FR5.

## Starting live Supabase state

At FR5 start, the connected csp11-supabase project in ap-south-1 was inspected directly.

The following row counts were all zero:

- content_versions
- questions
- fr_migration_ledger
- readiness_index_snapshots
- competency_evidence_snapshots
- competency_readiness_profiles

The Supabase security advisor returned zero findings.

The performance advisor returned only unused-index informational notices. That is expected on the empty shadow database and is not treated as a defect.

## Authoring workspace separation

Legacy draft content has been removed from the production Firestore source before the live FR5 retry.

FR5 now treats the Supabase public schema as production-only. A separate authoring schema is reserved for future admin work:

- authoring.content_drafts
- authoring.question_drafts

The authoring schema is not learner-facing. Anonymous and authenticated Data API roles are denied access. Future admin authoring cutover will write working copies there, while only published records move into public.content_versions and public.questions.

This separation is schema preparation only. FR5 does not route the current Flutter admin authoring runtime to Supabase, and Firestore remains authoritative until a later explicit cutover phase.

## FR5 architecture

Firestore authoritative
-> FR5 published-only source selection
-> non-published authoring records excluded
-> FR4 deterministic extraction and normalization
-> frozen FR4 evidence manifest
-> FR5 guarded Supabase shadow upsert
-> exact target IDs, counts and checksums
-> learner-visible projection parity
-> migration-ledger parity
-> FR5 complete only when every check matches

The FR4 evidence file remains the migration manifest. Before FR4 normalization, FR5 performs one narrow classification step so only published production content and questions enter that manifest. Non-published lifecycle records are reported as excluded authoring rows rather than migrated into public production tables.

## Required parity

FR5 is complete only when all of the following are true:

1. FR4 evidence has readyToApply=true.
2. FR4 evidence has zero issues.
3. Every expected target identity exists exactly once.
4. No extra supported target row exists.
5. Every planned target checksum matches the Supabase row.
6. Every content learner payload matches the normalized Firestore content payload.
7. Every question reconstructed from Supabase relational columns matches the Firestore learner-visible question payload.
8. Every expected migration-ledger row exists.
9. Every ledger row proves the exact source checksum and target checksum pair.
10. No extra supported-source ledger evidence exists.
11. Frozen L4 regression suites remain green.
12. The full repository regression remains green.

## Non-destructive rule

FR5 never deletes unexpected Supabase rows.

If an unexpected row exists, FR5 fails before shadow apply. This prevents an automated parity run from turning a data anomaly into silent destructive cleanup.

## Credentials

Firestore extraction requires a Google OAuth access token with permission to read the CSP11 Firestore database. The token is supplied only through GOOGLE_OAUTH_ACCESS_TOKEN.

Supabase shadow operations prefer the current server-side SUPABASE_SECRET_KEY. The legacy SUPABASE_SERVICE_ROLE_KEY is accepted only for migration compatibility.

No Google or Supabase privileged credential is stored in the repository.

## Production sequence

### 1. Extract and freeze Firestore plan

Run the FR4 migration tool in read-only mode against Firebase project csp11-exam-platform and write the evidence file to build/fr5/production_fr4_plan.json.

The extraction must finish with readyToApply=true and zero duplicate, failure and unmapped counts.

### 2. Validate current Supabase shadow target before write

Run the FR5 shadow-parity tool with the frozen FR4 evidence file and server-side Supabase credentials.

An empty target will correctly report missing rows at this stage. Any extra target identity is a blocker.

### 3. Apply shadow data and verify

Run the FR5 tool with --apply-shadow and --confirm=FR5_SHADOW_ONLY.

The tool upserts only the frozen expected rows. It then re-reads target rows and validates exact checksums plus learner-visible parity before it writes matched migration-ledger evidence.

The final report must have completeParity=true and zero missing, checksum mismatch, learner-visible mismatch, extra, duplicate and ledger mismatch counts.

## Live production execution status

FR5 implementation CI is green. Run 35433210098 passed formatting, analyze, FR1 through FR5, all frozen L4 suites, the full repository regression and diff hygiene.

After that validation, the live Supabase shadow target was rechecked and remains untouched:

- content_versions = 0
- questions = 0
- fr_migration_ledger = 0

The Supabase security advisor still reports zero findings.

A manual production workflow now exists at .github/workflows/phase_fr5_production_shadow_parity.yml.

The preferred Google authentication path is Workload Identity Federation using repository variables GCP_WIF_PROVIDER and GCP_FIRESTORE_READER_SERVICE_ACCOUNT.

A service-account JSON fallback is supported through the FIREBASE_SERVICE_ACCOUNT_JSON repository secret.

Supabase production shadow access requires the SUPABASE_SECRET_KEY repository secret.

Workload Identity Federation is now configured and production Firestore read permission has been proven by GitHub Actions. Earlier live preflight attempts exposed legacy draft/published source collisions. Those draft records have since been removed, and the production source selector has been changed to published-only migration semantics.

FR5 must not be frozen as complete until the real production Firestore source is extracted through that authorized server-side path and the live Supabase shadow parity report is completely green.

## Runtime invariant

Even after FR5 succeeds, learner runtime remains on Firestore. Supabase remains shadow-only.

No learner cutover occurs until later frozen FR phases.

## NEXT ACTION

Run Phase FR5 Production Shadow Parity from branch phase-fr5-shadow-data-parity with apply_shadow=false after the published-only source-selection change is green.

If extraction and preflight are green, run it again with apply_shadow=true and confirmation FR5_SHADOW_ONLY.

Only after the live report has completeParity=true and the final FR/L4/full-repository gate remains green should phase-fr5-closed be created.
