# CSP11 LSP-Q3 — Evidence-Backed LAB Explanation and BEST Rationale

## Status

**IMPLEMENTED / VALIDATION CHECKPOINT**

Program: `LSP-Q`

Checkpoint: `LSP-Q3`

Branch: `phase-l4-scenario-population`

Baseline Q2 commit: `e0df4b572894782dfdd0e48eef820efe181e6920`

## Purpose

LSP-Q3 removes the generic DQG300-LAB explanation and BEST-answer rationale placeholders introduced for backward-compatible Q2 extraction.

Every LAB Decision converted into a canonical CSP11 question must now derive both fields deterministically from its pinned `QuestionQualityEvidence`.

No generic fallback remains.

## Frozen evidence inputs

The canonical LAB explanation is derived from:

- `decisiveScenarioFacts`
- `keySatisfiedCriteria`

The canonical BEST-answer rationale is derived from:

- `keySuperiorityProof`

These fields are part of the DQG300 evidence bundle that is pinned to:

- LAB ID
- LAB version ID
- Decision Node ID
- Decision signature

Therefore Q3 does not introduce a second authoring source or runtime LLM generation.

## Conversion sequence

`LabPackage + LabDecisionNode + pinned QuestionQualityEvidence`

`-> LabDecisionQuestionAdapter`

`-> scenario-specific explanation`

`-> scenario-specific BEST-answer rationale`

`-> canonical payload`

`-> CanonicalQuestionParser`

`-> CanonicalQuestionDraft`

`-> Question`

`-> DQG300`

## Fail-closed rules

Canonical question conversion now blocks when any of these are absent:

- decisive scenario facts
- BEST-answer satisfied criteria
- BEST-answer superiority proof

A missing evidence field raises `LabContractException`.

The adapter must not substitute generic explanatory text.

## Explanation contract

The explanation must identify the decisive authored scenario facts and the material criteria satisfied by the BEST action.

It is deterministic and traceable to the reviewed DQG evidence.

## BEST-rationale contract

The rationale must explain why the BEST action is superior to the expert near-miss alternatives using the reviewed `keySuperiorityProof`.

Internal proof tokens are normalized for the canonical question text:

- `KEY` becomes `the BEST action`
- `D1`, `D2`, etc. become `alternative 1`, `alternative 2`, etc.

This normalization changes presentation wording only. It does not change the underlying DQG evidence or rule result.

## DQG300 integration

`LabDqg300Validator` now supplies the exact pinned `QuestionQualityEvidence` to `LabDecisionQuestionAdapter`.

The adapter cannot produce a DQG validation Question without evidence.

Decision signatures, evidence pinning, DQG rules, DQS calculation and publishability semantics remain unchanged.

## Q3 test coverage

Dedicated Q3 tests verify:

- decisive scenario facts appear in the canonical explanation
- BEST satisfied criteria appear in the canonical explanation
- superiority proof appears in the BEST-answer rationale
- internal KEY/Dn proof labels are normalized
- generic compatibility wording is absent
- conversion is deterministic
- missing decisive scenario facts fail closed
- missing BEST criteria fail closed
- missing superiority proof fails closed

Existing Q1, Q2, Studio and DQG300-LAB regression suites remain mandatory.

## Out of scope

LSP-Q3 does not yet:

- make normal H0.3 warnings publication-blocking
- create the all-Decision parse report
- combine H0.3 and DQG300 into one publication report
- change LAB1000 publication eligibility
- populate the ten new LAB scenarios
- expose new learner scenarios
- alter learner consequence or ending narration

Those remain later LSP-Q checkpoints.

## Next authorized action

**LSP-Q4 — Run every LAB Decision through the canonical parser and add the batch parse report.**
