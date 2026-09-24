# CSP11 LSP-Q9 - Scenario Population Manifest

## Status

**IMPLEMENTED / VALIDATION CHECKPOINT**

Program: LSP-Q

Checkpoint: LSP-Q9

Branch: phase-l4-scenario-population

Baseline Q8 closure commit: 4a447e38f038368296e35a2041f8f16433692b23

## Purpose

LSP-Q9 creates the deterministic registry that binds each scenario population entry to exactly three artifacts:

- authoritative technical LAB JSON
- authoritative DQG300-LAB evidence JSON
- learner presentation JSON validated by LSP-Q8

The manifest contains references and identity pins only. It does not duplicate technical truth, Decision truth, DQG300 evidence, Story Gate logic, learner narrative, or publication state.

## Frozen manifest schema

Schema version:

csp11.lab.population_manifest.v1

Root fields:

- schemaVersion
- manifestId
- entries

Each entry contains only:

- entryId
- labId
- versionId
- technicalLabPath
- dqg300EvidencePath
- learnerPresentationPath

Unknown root or entry fields are rejected.

## Identity contract

Every entry pins one exact LAB/version pair.

The manifest rejects:

- duplicate entry IDs
- duplicate LAB/version bindings
- reuse of any artifact path by another manifest entry
- reuse of one artifact path for more than one artifact inside the same entry
- absolute paths
- URL paths
- traversal paths
- non-JSON artifact paths

Artifact paths must be normalized relative JSON paths.

## Three-artifact binding rule

LabScenarioPopulationBindingValidator validates a loaded manifest entry against:

1. LabPackage
2. LabDqg300EvidenceBundle
3. LabLearnerPresentationPackage

The binding is valid only when:

- technical LAB ID and version match the manifest entry
- DQG300 evidence LAB ID and version match the manifest entry
- learner presentation LAB ID and version match the manifest entry
- every technical Decision has one DQG300 evidence record
- no unknown DQG300 Decision evidence record exists
- every DQG300 Decision signature matches the current technical Decision
- the complete frozen LSP-Q8 learner presentation validation report passes

This prevents a valid-looking path from binding stale or unrelated content.

## Authority boundary

The manifest is not a source of scenario truth.

It must never define or override:

- technical prompts or options
- BEST-answer truth
- Decision quality
- consequences
- state mutations
- evidence mechanics
- Story Gates
- endings
- technical sources
- DQG300 rule evidence
- learner presentation prose
- lifecycle or publication status

LSP-Q7 remains the stronger semantic DQG300 layer. Q9 checks DQG artifact identity, Decision coverage and Decision signatures. It does not weaken or replace the full DQG300 semantic gate.

LSP-Q8 remains the learner-presentation authority boundary. Q9 composes that validator rather than recreating presentation rules.

## Implementation

LSP-Q9 adds:

lib/features/lab/lab_scenario_population_manifest.dart

The file contains:

- strict manifest schema parsing
- safe artifact path validation
- unique population-entry validation
- exact LAB/version binding
- DQG300 Decision coverage checks
- stale DQG300 Decision signature detection
- composition with LSP-Q8 learner presentation validation

## Test coverage

Dedicated Q9 tests verify:

- a strict one-entry manifest parses and resolves correctly
- unknown manifest fields fail
- unknown entry fields fail
- duplicate LAB/version bindings fail
- shared artifact paths fail
- traversal, URL and non-JSON paths fail
- an exact three-artifact binding passes
- DQG identity mismatch blocks
- missing DQG Decision evidence blocks
- unexpected DQG Decision evidence blocks
- stale DQG Decision signatures block
- a failing Q8 presentation mapping blocks the population binding

Q1 through Q8, frozen H0.3, DQG300-LAB, Studio and full repository regressions remain mandatory.

## Population data rule

Q9 does not invent scenario packages that are not present in the repository.

At this checkpoint the repository has the existing confined-space learner runtime reference scenario, but the planned population set does not yet contain complete technical + DQG300 evidence + learner presentation triplets. Therefore Q9 adds the manifest contract and binding gate without fabricating manifest entries that would point to nonexistent artifacts.

Actual population records must be added only when all three bound artifacts exist.

## Out of scope

LSP-Q9 does not:

- author the future scenario population
- create placeholder DQG300 evidence
- create placeholder learner presentation files
- change the current learner scenario catalogue
- change LAB1000 publication behavior
- change runtime loading behavior
- alter Q7 or Q8 authority rules

## Next authorized action

LSP-Q10 - begin manifest-backed scenario population only from complete technical, DQG300 evidence and learner presentation artifact triplets.
