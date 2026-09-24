# CSP11 LSP-Q11 - Population Publication Gate and Repository Admission

## Status

**IMPLEMENTED / EXACT-SHA CLOSURE CANDIDATE**

Program: LSP-Q

Checkpoint: LSP-Q11

Branch: phase-l4-scenario-population

Baseline Q10 closure commit: ee333b714e6ac33f7768dd18e69d216d22850d52

## Purpose

LSP-Q11 converts the Q10 population from repository-backed source artifacts into versions that are eligible for immutable published-repository admission.

Q11 does not create a second publication model. It composes the existing frozen LAB publication machinery.

The admission chain is:

Q10 manifest membership
AND Q9 three-artifact binding
AND Q4-Q7 Decision quality
AND strict H0.3
AND DQG300 semantic authority
AND structural LAB validation
AND exhaustive route proof
AND reachable route exploration
AND publish/debrief/Learning Twin evidence validation
AND immutable published-repository acceptance

Only after every layer passes may the version enter LabPublishedRepository.

## Manifest membership boundary

Q11 accepts the complete LabScenarioPopulationManifest plus one entryId.

Callers cannot admit an arbitrary free-floating manifest entry.

The entry ID must resolve from the Q10 population manifest before any repository write can occur.

## Three-artifact boundary

The Q9 validator remains mandatory.

Before publication Q11 verifies that the technical LAB, DQG300 evidence bundle and learner presentation package all belong to the exact manifest LAB/version and retain complete mapping coverage.

A presentation identity mismatch or stale DQG binding therefore blocks admission before publication.

## Decision-quality boundary

Q11 runs LabDecisionQualityGate before the automated lifecycle service.

This preserves the complete Q4-Q7 chain, including strict H0.3, rather than relying only on structural validity or DQG evidence.

All Decisions must remain canonical, H0.3-clean and DQG300 semantic passes with DQS 100.

## Automated publication boundary

After population and Decision-quality checks pass, Q11 delegates lifecycle publication to the existing LabAutomatedLifecycleService.

That service must independently pass the existing automated publication gate and produce:

- DQG300 evidence certificate
- L4L exhaustive-route certificate
- L4M/L4N route and publish-evidence certificate
- one validation authority
- one validation timestamp
- immutable snapshot fingerprint
- PUBLISHED lifecycle JSON

Q11 uses validation authority:

LSP-Q11-POPULATION-AUTO

## Immutable repository admission

The existing LabPublishedRepository remains authoritative for published technical LAB versions.

Q11 refuses to overwrite an existing LAB/version.

After save, Q11 reloads the immutable repository record and verifies:

- LAB ID
- version ID
- PUBLISHED lifecycle
- validation authority
- DQG300 certificate
- L4L certificate
- L4N certificate
- snapshot fingerprint

A missing or incomplete stored record is treated as admission failure.

## Population source lifecycle

Q10 source packages remain DRAFT.

Q11 performs lifecycle transitions only in the immutable publication snapshot:

DRAFT -> REVIEW -> VALIDATED -> PUBLISHED

The Q10 source artifact is not rewritten to PUBLISHED.

This preserves the source population as the reproducible authoring input.

## Learner exposure boundary

Repository admission is not learner catalogue admission.

Q11 does not:

- add the ten LABs to the learner scenario catalogue
- change the learner LAB navigation
- make the ten LABs discoverable in the learner UI
- alter runtime catalogue ordering
- replace the Q10 manifest with a learner-facing index

An admitted version can be loaded explicitly from the published repository by exact LAB/version identity. Discoverability and learner delivery remain a later checkpoint.

## Implementation

Q11 adds:

lib/features/lab/lab_scenario_population_publication.dart

The service composes the existing validators and publication lifecycle without weakening them.

## Test coverage

test/lab_quality/lsp_q11_population_publication_gate_test.dart verifies:

- all ten Q10 population entries pass the complete publication/admission chain
- all ten immutable published versions are retrievable by exact identity
- all 50 Decisions survive repository admission
- explicit published loading succeeds after admission
- non-manifest entry IDs are rejected
- learner-presentation identity drift blocks before repository write
- non-DRAFT source packages are rejected
- duplicate immutable LAB/version admission cannot overwrite the original

All previous Q1-Q10, H0.3, DQG300, Studio and full-repository regressions remain mandatory.

## Out of scope

LSP-Q11 does not:

- modify Q10 technical source files
- modify DQG300 evidence
- modify learner presentation content
- alter the Q10 manifest
- create learner catalogue entries
- expose scenarios in learner navigation
- change immutable repository semantics
- weaken any L4 or LSP quality gate

## Next authorized action

LSP-Q12 - Learner Catalogue Admission and Controlled Delivery.


## Closure candidate

Initial Q11 implementation commit: `a832e9f2d6c4738d0105f6ce1b9835710a5fb3ce`

Successful validation run for the implementation commit: `35892319980`

Canonical formatter output commit: `6ce5e3cf038a158aa8f7d39c43ac2760e4f15949`

The formatter commit changes Q11 implementation/test formatting only.

This documentation-only closure commit is the exact-SHA validation target for LSP-Q11. No technical LAB source content, DQG300 evidence, learner presentation content, population manifest binding, publication gate semantics, immutable repository behavior, learner catalogue or runtime navigation is changed by the closure step.
