# CSP11 LSP-Q4 — Canonical LAB Decision Batch Parse

## Status

**IMPLEMENTED / VALIDATION CHECKPOINT**

Program: LSP-Q

Checkpoint: LSP-Q4

Branch: phase-l4-scenario-population

Baseline Q3 commit: c6f08dff2be5776930a0ec71180d90a885529146

## Purpose

LSP-Q4 adds the package-level parse boundary required by the frozen unified LAB question-quality contract.

Every authored LAB Decision is now visited in authored order and converted through LabDecisionQuestionAdapter into CanonicalQuestionParser output.

The batch report is read-only. It does not publish content or alter learner runtime behavior.

## Evidence dependency

Q3 made scenario-specific explanation and BEST-answer rationale depend on pinned QuestionQualityEvidence.

Q4 therefore requires the matching DQG300 evidence bundle before a Decision can enter the canonical parser.

The parse report fails closed for:

- LAB/version evidence bundle mismatch
- missing Decision evidence
- stale Decision signature
- canonical conversion failure
- unexpected evidence IDs

No generic explanation or rationale fallback is restored.

## Batch report contract

LabCanonicalDecisionBatchReport exposes:

- LAB ID
- version ID
- authored Decision count
- one ordered result per Decision
- canonical parsed draft when successful
- failure reason when blocked
- missing evidence IDs
- stale evidence IDs
- unexpected evidence IDs
- pinned-version status
- parsed Decision count
- blocked Decision count
- aggregate validity

The report is valid only when every authored Decision parses successfully and the evidence set exactly matches the package.

## Preserved boundaries

LSP-Q4 does not:

- execute the normal H0.3 question-quality validator
- convert H0.3 warnings into blockers
- change DQG300 scoring or DQS
- combine H0.3 and DQG300 results
- alter LAB1000 publication eligibility
- alter Studio import semantics
- mutate LAB packages or evidence
- change learner Decision LAB rendering
- populate or expose the ten new LAB scenarios

Those remain later LSP-Q checkpoints.

## Q4 test coverage

Dedicated tests verify:

- every authored Decision is parsed
- authored Decision order is preserved
- canonical question fields are produced
- missing evidence fails closed
- stale evidence fails closed
- LAB/version pin mismatch blocks the batch
- per-Decision canonical conversion failures are captured
- unexpected evidence IDs invalidate the report

The existing Q1, Q2, Q3, DQG300-LAB, Studio and full repository regressions remain mandatory.

## Next authorized action

LSP-Q5 — Add the strict H0.3 normal-question gate with zero errors and zero warnings for LAB publication quality.
