# CSP11 LSP-Q6 — Combined Decision Quality Gate

## Status

**IMPLEMENTED / VALIDATION CHECKPOINT**

Program: LSP-Q

Checkpoint: LSP-Q6

Branch: phase-l4-scenario-population

Baseline Q5 commit: b9d633983f42809a5df678bcba0c77a30025b132

## Purpose

LSP-Q6 combines the already-frozen LAB question-quality layers into one deterministic Decision-quality report.

It does not create a new question parser, a new H0.3 validator, or a new DQG300 validator.

The combined gate orchestrates:

- LSP-Q4 canonical Decision parsing
- LSP-Q5 strict H0.3 validation
- existing DQG300 validation
- explicit DQS 100/100 verification
- explicit derived DQG-300 PASS verification

## Frozen Decision formula

For each authored LAB Decision:

DecisionQualityPass =
CanonicalParsePass &&
H0_3Errors == 0 &&
H0_3Warnings == 0 &&
DQG300Pass &&
DQS == 100

The complete LAB Decision-quality report passes only when every authored Decision satisfies that formula.

Partial Decision-quality acceptance is not allowed.

## Implementation

LSP-Q6 adds:

lib/features/lab/lab_decision_quality_gate.dart

The gate first obtains the Q5 strict report, which already contains the Q4 parse report.

If canonical parsing is invalid, DQG300 execution is not attempted. The combined report still returns one failed result for every authored Decision, preserving authored order and fail-closed behavior.

If canonical parsing is valid, the unchanged LabDqg300Validator is executed against the same LAB package and signature-pinned evidence bundle.

The results are joined by Decision Node ID.

## Per-Decision result

LabDecisionQualityResult exposes:

- Decision Node ID
- authored Decision index
- canonical parse result
- strict H0.3 result
- DQG300 result
- canonicalParsePass
- strictH03Pass
- H0.3 error count
- H0.3 warning count
- DQG300 pass
- DQS
- final combined isPass

DQG300 pass is explicitly defined as:

- underlying DQG result is publishable
- DQS == 100
- derived DQG-300 rule passes

## Aggregate report

LabDecisionQualityReport exposes:

- complete Q5 strict H0.3 report
- complete DQG300 report
- one combined result per authored Decision
- authored Decision count
- passed Decision count
- blocked Decision count
- aggregate validity

A single failed Decision blocks aggregate validity.

## Preserved boundaries

LSP-Q6 does not modify:

- CanonicalQuestionParser
- LabDecisionQuestionAdapter
- QuestionQualityValidator
- QuestionValidationReport
- Dqg300QuestionQualityValidator
- QuestionQualityValidationResult
- DQG atomic rules
- DQS category calculation
- LAB1000 publication eligibility
- learner presentation
- learner runtime
- scenario population

No quality rule is duplicated or weakened.

## Test coverage

Dedicated Q6 tests verify:

- clean parse + strict H0.3 + DQG300 + DQS 100 passes
- H0.3 warning blocks even when DQG300 passes
- DQG300 atomic-rule failure blocks even when H0.3 passes
- DQS below 100 explicitly blocks
- Q4 parse failure prevents DQG execution and blocks all Decisions
- authored Decision order is preserved
- combined results are deterministic

Q1 through Q5, frozen H0.3, DQG300-LAB, Studio and full repository regressions remain mandatory.

## Out of scope

LSP-Q6 does not yet:

- add new DQG300 semantic requirements
- redesign or weaken DQG300
- integrate the combined gate into LAB1000 publication
- validate learner presentation
- populate the ten current LAB scenarios
- expose scenarios to learners

Those remain later LSP-Q checkpoints.

## Next authorized action

LSP-Q7 — Preserve DQG300 as the stronger semantic layer and prove that the combined gate cannot bypass or dilute its evidence-backed requirements.
