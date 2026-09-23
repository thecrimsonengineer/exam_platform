# CSP11 LSP-Q2 — LAB Decision Question Adapter

## Status

**IMPLEMENTED / VALIDATION CHECKPOINT**

Program: `LSP-Q`

Checkpoint: `LSP-Q2`

Branch: `phase-l4-scenario-population`

Baseline Q1 commit: `9058c96a1851e2034a17692ef66a6d7f9157b68e`

## Implemented boundary

LSP-Q2 introduces:

`lib/features/lab/lab_decision_question_adapter.dart`

The adapter converts one deterministic `LabDecisionNode` into the canonical CSP11 question representation extracted in LSP-Q1.

The conversion path is:

`LabPackage + LabDecisionNode -> canonical payload -> CanonicalQuestionParser -> CanonicalQuestionDraft -> Question`

## Preserved LAB identity semantics

The adapter preserves the existing DQG300-LAB question identity contract:

- question ID is `decisionIndex + 1`
- domain is derived from the first canonical competency mapping
- competency ID uses the first package competency mapping
- Study topic ID remains empty
- Study subtopic ID remains empty
- quiz ID is `labId_nodeId`
- content package ID is `labId-versionId`
- Decision prompt becomes the question stem
- authored option order is preserved
- the unique authored BEST option becomes the zero-based correct-answer index
- package sources become the question reference
- difficulty remains `Hard`
- cognitive level remains `analysis`
- question type remains `scenario_mcq`
- status remains `validated` for the DQG300 compatibility path
- version remains 1
- tags remain `lab-dqg300` plus the Decision Node ID

## Q2 compatibility boundary

LSP-Q2 deliberately preserves the existing generic DQG300 compatibility explanation and BEST-answer rationale.

Those placeholders are now isolated behind `LabDecisionQuestionAdapter` and are explicitly temporary.

They are replaced in:

**LSP-Q3 — Replace generic explanation/rationale fallback**

Q2 does not claim that the compatibility text satisfies the final strict H0.3 LAB publication contract.

## DQG300 integration

`LabDqg300Validator` no longer constructs a `Question` directly.

It now delegates question construction to `LabDecisionQuestionAdapter`.

DQG300 rule logic, decision signatures, evidence pinning, DQS scoring and publication semantics are unchanged.

## Q2 test coverage

Dedicated Q2 tests verify:

- Decision prompt and four authored options reach the canonical parser
- unique BEST index is preserved
- a BEST answer outside option A is preserved correctly
- first competency mapping determines canonical competency identity
- domain is derived from the competency mapping
- LAB quiz ID remains deterministic
- LAB content-package ID remains deterministic
- package sources propagate into the canonical question reference
- topic/subtopic IDs remain empty rather than fabricating Study hierarchy
- absent competency mappings preserve the previous compatibility behavior
- negative Decision indexes fail fast

Existing DQG300-LAB tests remain mandatory and prove that the 300-rule semantic layer remains green after delegation.

## Out of scope

LSP-Q2 does not yet:

- replace generic explanation/rationale placeholders
- create a strict zero-warning H0.3 LAB gate
- add a batch parse report for all Decision Nodes
- change LAB1000 publication eligibility
- populate the ten new LAB scenarios
- alter learner LAB presentation
- publish any new LAB version

## Next authorized action

**LSP-Q3 — Replace generic explanation/rationale fallback.**
