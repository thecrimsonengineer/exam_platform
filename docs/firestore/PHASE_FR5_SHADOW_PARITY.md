# CSP11 Phase FR5 Shadow Data Parity

Status: IMPLEMENTATION IN PROGRESS
Branch: phase-fr5-shadow-data-parity
Source checkpoint: phase-fr4-closed at bce142b3a337dfc8e93e1a57a47faac1a6a207cd
Date: 2026-09-19

## Purpose

FR5 copies canonical production contentVersions and questions into Supabase shadow tables and proves complete structural and learner-visible parity before any learner cutover.

Firestore remains authoritative throughout FR5. FR5 does not modify learner runtime routing.

## Frozen FR5 data scope

FR5 migrates only the canonical source collections already frozen by FR4:

- contentVersions to content_versions
- questions to questions

Learner progress, attempts, readiness history, plans, LAB attempts and Learning Twin evidence remain outside FR5.

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

## FR5 architecture

Firestore authoritative
-> FR4 deterministic extraction and normalization
-> frozen FR4 evidence manifest
-> FR5 guarded Supabase shadow upsert
-> exact target IDs, counts and checksums
-> learner-visible projection parity
-> migration-ledger parity
-> FR5 complete only when every check matches

The FR4 evidence file is the migration manifest. FR5 does not independently reinterpret Firestore documents.

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

## Current live-source blocker

The repository currently contains no configured Firebase service-account or GitHub workload-identity path for server-side Firestore extraction.

FR5 implementation and deterministic CI can proceed without that credential.

FR5 must not be frozen as complete until the real production Firestore source is extracted through an explicitly authorized server-side credential and the live Supabase shadow parity report is completely green.

## Runtime invariant

Even after FR5 succeeds, learner runtime remains on Firestore. Supabase remains shadow-only.

No learner cutover occurs until later frozen FR phases.

## NEXT ACTION

Complete FR5 implementation CI first. Then use an authorized server-side Firestore reader credential path, run the production FR4 extraction, apply the frozen manifest to Supabase shadow tables, and close FR5 only after exact live parity plus the full FR/L4 regression gate are green.
