# CSP11 LSP-Q15 - Production Seed Execution Evidence and Release Closure

## Status

**IMPLEMENTED / VALIDATION CHECKPOINT**

Program: LSP-Q

Checkpoint: LSP-Q15

Branch: phase-l4-scenario-population

Frozen Q14 recovery branch: phase-lsp-q14-closed

Frozen Q14 closure SHA: 5beee3db89a43267a4cc5b2956b117a344afe648

Q14 exact-SHA validation run: 35918656487

## Purpose

LSP-Q15 closes the initial LAB population release with immutable execution evidence after the Q14 seed has produced the exact learner-visible release.

Q15 does not trust a transient seed receipt as closure evidence. It reconstructs the release from the repositories that learners actually use.

## Execution chain

The Q15 execution service composes:

Q14 controlled initial seed
-> Q14 exact learner release verification
-> live repository reconstruction
-> Q15 evidence fingerprint
-> immutable release-evidence persistence
-> independent closure verification

If the production population was already seeded successfully but evidence persistence was interrupted, the Q15 closure service can certify that existing immutable release without rerunning the Q14 seed.

## Frozen Q14 binding

Every Q15 release certificate is pinned to:

- Q14 closure SHA: 5beee3db89a43267a4cc5b2956b117a344afe648
- Q14 validation run: 35918656487
- Q11 automated publication authority: LSP-Q11-POPULATION-AUTO

A Q15 certificate using a different Q14 source checkpoint is rejected.

## Evidence reconstructed from live repositories

For every manifest entry, Q15 reloads:

- exact labId and versionId
- immutable Q11 published version
- immutable snapshot fingerprint
- publication timestamp
- Q12 learner catalogue entry
- manifest entry binding
- delivered decision count

The published JSON fingerprint is recomputed before evidence is accepted.

The release-wide evidence also records:

- release ID
- manifest ID
- deterministic manifest fingerprint
- execution environment identifier
- execution actor identifier
- execution timestamp
- learner catalogue identity set
- LAB count
- total decision count
- per-LAB immutable snapshot fingerprints
- release evidence fingerprint

The current frozen population must close as exactly 10 learner-visible LAB versions and 50 learner decisions.

## Tamper-evident release certificate

Schema:

csp11.lab.production_release.v1

Fingerprint:

csp11.lab.production_release.sha256.v1:<sha256>

The fingerprint binds all release fields except the fingerprint itself. Lists are sorted before hashing so the certificate is deterministic.

The population manifest is independently fingerprinted as:

csp11.lab.population_manifest.sha256.v1:<sha256>

This means Q15 binds both the exact release state and the exact manifest contract that defined it.

## Persistent evidence collection

Q15 adds the Firestore collection:

labProductionReleaseEvidence

Document ID:

releaseId

For the initial population the deterministic release ID is:

phase_l_population_v1_q15_release_v1

The collection is internal operational evidence:

- only admins may GET or LIST
- only admins may CREATE
- UPDATE and DELETE are denied
- the Q14 closure SHA and validation run are pinned in Firestore rules
- the initial release is pinned to 10 LABs and 50 decisions

Learners never need direct access to this collection.

## Failure and recovery semantics

A failed Q14 seed is not converted into release evidence.

If seeding is interrupted before the complete learner release exists, Q15 closure fails closed.

If all Q14 immutable production records exist and learner delivery verifies but Q15 evidence persistence was interrupted, rerun only Q15 closure. Do not rerun or overwrite the Q14 seed.

Once Q15 evidence exists, a second closure write is refused.

## Production execution boundary

CI uses in-memory repositories and fake Firestore only.

CI never writes production Firestore and never claims that a simulated test release is the live production release.

A real production execution must compose the Q14/Q15 services with the Q13 Firestore repositories under an authenticated admin context. The environment identifier and execution actor must describe that real execution.

## Files

Added:

- lib/features/lab/lab_production_release_closure.dart
- test/lab_quality/lsp_q15_production_release_closure_test.dart
- docs/lab/LSP_Q15_PRODUCTION_RELEASE_CLOSURE.md

Updated:

- lib/features/lab/lab_firestore_repositories.dart
- firestore.rules
- .github/workflows/lsp_unified_lab_question_validation.yml

## Validation

Dedicated Q15 coverage verifies:

1. Q14 seed plus Q15 closure produces a 10-LAB / 50-decision certificate
2. all ten immutable snapshot fingerprints are included
3. the certificate is pinned to the frozen Q14 SHA and validation run
4. independent closure verification reconstructs the same live release
5. closure before Q14 release is refused
6. certificate tampering is rejected
7. Firestore release evidence is create-once
8. Firestore release evidence round-trips without fingerprint drift
9. Firestore rules keep evidence admin-only and immutable

All Q1-Q14 gates and the full repository regression remain mandatory.

## Closure condition

LSP-Q15 closes only after the dedicated Q15 tests, all prior LSP-Q gates, static analysis, full repository regression, diff hygiene and canonical formatting are green on the exact Q15 closure SHA.
