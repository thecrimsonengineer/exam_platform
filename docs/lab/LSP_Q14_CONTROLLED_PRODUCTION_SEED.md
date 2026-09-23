# CSP11 LSP-Q14 - Controlled Production Population Seed and Learner Release Verification

## Status

**IMPLEMENTED / VALIDATION CHECKPOINT**

Program: LSP-Q

Checkpoint: LSP-Q14

Branch: phase-l4-scenario-population

Baseline Q13 closure commit: fd9a808e2ce53ae06ddae67b35c54c400155a9e7

## Purpose

LSP-Q14 adds the controlled one-shot initial population path for the ten manifest-backed LABs and an independent learner-release verification pass.

Q14 reuses the frozen Q11 publication gate, Q12 learner catalogue admission contract and Q13 persistent repository boundary. It does not weaken or bypass any earlier gate.

## Seed contract

The production seed must receive exactly one candidate for every entry in:

content/lab_population/manifest.json

After confirming the initial production identities are pristine, Q14 runs the complete ten-LAB population through fresh in-memory repositories before any production write.

This preflight proves that all ten candidates still pass:

- Q9/Q10 manifest binding
- Q4-Q7 decision quality
- H0.3 normal-question quality
- DQG300 semantic validation
- L4K automated lifecycle
- L4L exhaustive route validation
- L4N publication evidence
- Q11 immutable publication admission
- Q12 learner catalogue admission
- controlled learner delivery

If any later candidate fails, production repositories remain untouched.

## Production write boundary

The initial release is deliberately one-shot and fail closed.

Before production writes:

- the learner catalogue must be empty
- none of the ten target labId/versionId published identities may exist
- none of the ten target learner catalogue identities may exist

Each successful population entry is written in this order:

Q11 immutable published version
-> Q12 immutable learner catalogue entry
-> controlled learner delivery reload

Published technical versions remain non-listable to learners under the Q13 Firestore rules. Therefore a network failure after the technical write but before catalogue admission does not expose that LAB in the learner library.

No overwrite, update or delete path is introduced.

## Learner release verification

The successful preflight produces the exact immutable Q11 published versions and Q12 catalogue entries that are then persisted to production. Q14 does not recompute the publication lifecycle for the live write, so the validated preflight artifact is the persisted artifact.

After the ten writes, Q14 independently verifies that:

- learner catalogue size equals the manifest population size
- learner catalogue identities exactly equal the manifest identities
- every catalogue record is bound to the correct manifest entry
- every exact labId/versionId loads through controlled delivery
- technical package identity matches the manifest
- learner presentation identity matches the manifest
- catalogue decision count matches the delivered package

The current population must verify as:

- 10 learner-visible LAB versions
- 50 total learner decisions

## Production execution rule

CI and unit tests never write production Firestore.

The production-capable service requires the caller to supply the Q13 persistent repositories explicitly. A credentialed admin execution must use the exact closed Q14 source revision and the exact manifest-backed candidate set.

A failed or interrupted production seed is not repaired by overwriting immutable documents. The release stays blocked until repository state is inspected and a controlled recovery decision is made.

## Files

Added:

- lib/features/lab/lab_production_population_seed.dart
- test/lab_quality/lsp_q14_production_population_seed_test.dart
- docs/lab/LSP_Q14_CONTROLLED_PRODUCTION_SEED.md

Updated:

- .github/workflows/lsp_unified_lab_question_validation.yml

## Validation

Dedicated Q14 coverage verifies:

1. all ten LABs preflight and seed successfully
2. exact learner release contains ten identities and 50 decisions
3. an invalid later candidate fails before any production write
4. a second initial seed is blocked
5. immutable published content remains unchanged after the blocked re-seed
6. release verification can be rerun independently

All Q1-Q13 tests and the full repository regression remain mandatory.

## Out of scope

LSP-Q14 does not:

- run production writes from CI
- perform staged percentage rollout
- implement entitlement groups
- add offline LAB caching
- mutate or delete immutable published versions
- add a hidden fallback to bundled population assets

## Closure condition

LSP-Q14 closes only after the dedicated Q14 tests, all prior LSP-Q tests, analyze, full repository regression, formatter and diff-hygiene gates are green on the exact implementation SHA.
