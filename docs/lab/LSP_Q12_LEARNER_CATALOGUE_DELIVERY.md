# CSP11 LSP-Q12 - Learner Catalogue Admission and Controlled Delivery

## Status

**IMPLEMENTED / VALIDATION CHECKPOINT**

Program: LSP-Q

Checkpoint: LSP-Q12

Branch: phase-l4-scenario-population

Baseline Q11 closure commit: c344e318e23364a4807ece241146ee2d0aae9471

## Purpose

LSP-Q12 creates the controlled learner catalogue boundary above Q11.

Q11 proves that a manifest-backed LAB version is eligible for immutable published-repository admission.

Q12 proves that a learner may discover and load only an explicitly catalogued version that already exists as a complete Q11 automated publication.

The Q10 manifest itself is not a learner catalogue.

## Catalogue admission chain

A learner catalogue entry may be created only when:

- the entry ID exists in the Q10 population manifest
- the exact LAB/version exists in LabPublishedRepository
- the stored package is PUBLISHED
- stored LAB/version identity matches the manifest
- validation authority is LSP-Q11-POPULATION-AUTO
- reviewer authority matches
- snapshot fingerprint matches the immutable published JSON
- DQG300 certificate is present, pinned and passing
- L4L exhaustive-route certificate is present, pinned and passing
- L4M/L4N route and publish-evidence certificate is present, pinned and passing
- all publication certificates share one validation timestamp
- DQG300 Decision signatures still match the published Decisions
- L4N route exploration remains bound to the L4L exhaustive proof
- the Q8 learner presentation still maps exactly to the published technical package

Any failure blocks catalogue admission.

## Learner-safe catalogue record

The learner catalogue stores only information needed for discovery and presentation:

- manifest entry ID
- LAB ID
- version ID
- title
- learner summary
- focus tags
- estimated time
- decision count label
- actual Decision count
- supported learner modes
- validated Q8 learner presentation package

It does not expose:

- DQG300 scores
- Decision quality labels
- Story Gate IDs
- internal state variables
- route fingerprints
- validation certificates
- source paths
- draft JSON
- publication internals

## Controlled delivery

Learner delivery is exact-version only.

A learner launch request must provide:

labId + versionId

The controlled delivery service first requires that exact identity to exist in the learner catalogue.

It then reloads the technical package through LabLearnerPackageLoader from the immutable published repository.

Delivery fails closed when:

- the LAB/version is not catalogued
- the published version is missing
- the stored package is not PUBLISHED
- published identity differs from requested identity
- learner presentation mapping has drifted
- learner catalogue title, Decision count or supported modes drift from the published technical package

The player therefore receives the immutable published technical package plus the matching learner presentation.

## Explicit admission

The ten Q10 manifest entries are candidates, not automatically visible learner entries.

Q12 requires explicit catalogue admission.

This preserves a release-control seam for later staged delivery, rollout policy or platform-specific availability without weakening Q11 publication.

## Repository boundary

Q12 adds a LabLearnerCatalogueRepository interface and an in-memory reference implementation.

No fake cloud persistence is introduced.

The existing LabPublishedRepository remains authoritative for playable technical LAB content.

A production persistent learner catalogue implementation can be added later against the same contract.

## Existing learner UI

The current single reference scenario UI remains unchanged at this checkpoint.

Q12 establishes the trusted catalogue and delivery seam first.

Replacing the hard-coded LabScenarioCatalog with the controlled catalogue requires a production repository binding and is deliberately deferred rather than silently wiring learner navigation to an in-memory store.

## Implementation

Q12 adds:

lib/features/lab/lab_learner_catalogue.dart

It contains:

- learner-safe catalogue entry model
- immutable catalogue repository contract
- in-memory reference catalogue repository
- Q11 publication-certificate verification
- catalogue admission service
- exact-version controlled delivery service

## Test coverage

test/lab_quality/lsp_q12_learner_catalogue_delivery_test.dart verifies:

- a Q11-published population entry can enter the learner catalogue
- learner-safe metadata is derived from the exact published package and Q8 presentation
- exact immutable version delivery succeeds
- unpublished population entries cannot enter the catalogue
- Q8 presentation drift blocks catalogue admission
- catalogue entries cannot overwrite an admitted LAB/version
- published but non-catalogued versions cannot be delivered
- ten manifest candidates do not become learner-visible automatically
- explicit admission adds only the selected identity

All Q1-Q11, H0.3, DQG300, Studio and full-repository regressions remain mandatory.

## Out of scope

LSP-Q12 does not:

- create a cloud learner catalogue repository
- modify Q10 source packages
- modify Q11 immutable publication records
- auto-admit all ten LABs
- change the existing learner library UI
- replace the current reference scenario
- implement staged rollout percentages
- implement learner entitlements
- add offline LAB delivery

## Next authorized action

LSP-Q13 - Persistent Learner Catalogue Repository and Runtime Binding.


## Closure candidate

Initial Q12 implementation commit: `ff34cd62428da1d5af28a1beb9feed64e97fa559`

Successful validation run for the implementation commit: `35904550711`

Canonical formatter output commit: `9e24563cfa2864a2e6d0dc80039b65d2f4d197cb`

The formatter commit changes Q12 implementation/test formatting only.

This documentation-only closure commit is the exact-SHA validation target for LSP-Q12. No Q10 source package, Q11 immutable publication record, learner presentation content, catalogue admission semantics, controlled-delivery semantics, existing learner UI, or runtime navigation is changed by the closure step.
