# CSP11 LSP-Q8 — Learner Presentation Validation Against Technical LAB

## Status

**IMPLEMENTED / VALIDATION CHECKPOINT**

Program: LSP-Q

Checkpoint: LSP-Q8

Branch: phase-l4-scenario-population

Baseline Q7 commit: f3a000a73cadb855b63f35455f2975549d01d591

## Purpose

LSP-Q8 creates the fail-closed contract between authoritative technical LAB JSON and the separate learner-facing presentation JSON.

The technical LAB remains the sole authority for story truth and mechanics.

The learner presentation package is display and narrative only.

## Frozen presentation schema

Schema version:

csp11.lab.presentation.v1

The presentation package joins to the technical LAB using:

- labId
- versionId

It contains only:

- presentation overview
- evidencePresentation
- decisionPresentation
- consequencePresentation
- endingPresentation

The learner-facing overview may contain:

- summary
- estimatedTime
- decisionCountLabel
- role
- situation
- objective
- peopleInvolved
- knownFacts
- focusTags

Evidence display records may contain:

- title
- summary
- details

Decision display records may contain:

- title

Consequence display records may contain:

- observable
- guidedInsight

Ending display records may contain:

- title
- narrative
- keyTurningPoint

## Technical authority boundary

Presentation JSON must never define or override:

- Decision prompt
- option text
- BEST-answer index or flag
- Decision quality classification
- consequence ID selection
- state mutations
- evidence unlock mechanics
- simulated time mechanics
- Story Gate conditions
- Story Gate priority or routing
- ending family
- ending conditions or mechanics
- DQG evidence
- DQG rule truth
- technical source/reference truth
- state schema
- starting state

The presentation parser is strict-schema. Unknown fields are rejected rather than silently ignored.

That makes technical override attempts contract failures before mapping validation.

## Mapping rule

Every presentation mapping is an exact ID join against the technical package.

For one LAB/version:

- every technical Decision ID requires exactly one decisionPresentation record
- every technical consequence ID requires exactly one consequencePresentation record
- every technical evidence ID requires exactly one evidencePresentation record
- every technical ending ID requires exactly one endingPresentation record
- presentation IDs not present in the technical package are forbidden
- LAB ID and version ID must match exactly

Inline consequences referenced directly by Decision options are included in the authoritative consequence ID set.

Technical records with missing, invalid or duplicate evidence/ending IDs cause fail-closed technical mapping issues.

## Read-only rule

LabLearnerPresentationValidator never mutates LabPackage.

Validation reads authoritative technical IDs and compares them to presentation mappings.

The presentation layer therefore cannot alter story mechanics through validation.

## Implementation

LSP-Q8 adds:

lib/features/lab/lab_learner_presentation.dart

The file contains:

- typed presentation-only contract models
- strict schema parsing
- exact LAB/version identity binding
- exact ID-set mapping validation
- missing/unexpected mapping reporting
- fail-closed technical mapping diagnostics

No existing technical LAB contract is modified.

## Test coverage

Dedicated Q8 tests verify:

- complete exact-ID presentation mapping passes
- LAB/version mismatch blocks
- missing and unexpected Decision mappings block
- missing consequence, evidence and ending mappings block
- Decision prompt/options/BEST/quality override attempts are rejected
- consequence mutation/evidence/time override attempts are rejected
- Story Gate/source/DQG override attempts are rejected
- ending mechanics override attempts are rejected
- evidence truth override attempts are rejected
- validation leaves technical Decision truth, gates and endings unchanged

Q1 through Q7, frozen H0.3, DQG300-LAB, Studio and full repository regressions remain mandatory.

## Out of scope

LSP-Q8 does not:

- populate the current ten LAB presentation records
- add the scenario population manifest
- change learner runtime catalogue entries
- integrate presentation validation into LAB1000 publication
- alter technical LAB story mechanics
- alter DQG300

Those remain later checkpoints.

## Next authorized action

LSP-Q9 — Add the scenario population manifest that binds the planned technical LAB package, DQG300 evidence bundle and learner presentation record for each population entry.
