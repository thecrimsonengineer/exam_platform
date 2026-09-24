# CSP11 LSP-Q5 — Strict H0.3 Normal-Question Gate

## Status

**IMPLEMENTED / EXACT-SHA CLOSURE CANDIDATE**

Program: LSP-Q

Checkpoint: LSP-Q5

Branch: phase-l4-scenario-population

Baseline Q4 commit: 34e4c9f0f4ad58f573770538d224e869c2989abe

## Purpose

LSP-Q5 applies the frozen normal CSP11 H0.3 question-quality validator to every LAB Decision after the LSP-Q4 canonical parse boundary.

The existing H0.3 validator is not changed.

Normal CSP11 authoring preserves its frozen behavior:

- H0.3 error -> normal question BLOCKED
- H0.3 warning only -> normal question PASSED

LAB publication quality uses the stricter frozen LSP-Q interpretation:

- H0.3 error -> LAB Decision BLOCKED
- H0.3 warning -> LAB Decision BLOCKED
- zero errors and zero warnings -> LAB Decision H0.3 PASS

## Strict formula

For one parsed LAB Decision:

StrictH03Pass = errorCount == 0 && warningCount == 0

For one LAB version:

AllStrictH03Pass =
Q4CanonicalParsePass &&
every authored Decision satisfies StrictH03Pass

There is no warning waiver and no manual override.

## Implementation

LSP-Q5 adds:

lib/features/lab/lab_h0_3_strict_gate.dart

The strict LAB gate:

1. executes the LSP-Q4 canonical batch parser
2. refuses to continue if the Q4 parse report is invalid
3. converts each successfully parsed Decision into the normal Question model
4. runs the unchanged QuestionQualityValidator
5. preserves the original QuestionValidationReport
6. applies the LAB-only zero-error / zero-warning interpretation
7. returns one ordered strict result per authored Decision

## Preserved H0.3 contract

QuestionQualityValidator and QuestionValidationReport retain their frozen semantics.

In particular, a warning-only normal H0.3 report still has:

- passed == true
- blocked == false
- errorCount == 0
- warningCount > 0

LSP-Q5 does not rewrite those values.

The LAB wrapper independently marks that Decision as not strict-pass because warningCount is non-zero.

## Blocking H0.3 warning families

Under the strict LAB interpretation, these existing H0.3 warnings are publication-blocking:

- weak_question_stem
- best_answer_length_bias
- option_length_imbalance
- weak_explanation
- insufficient_tags

Existing H0.3 errors remain blocking as before.

No new H0.3 issue code is introduced.

## Q5 report

LabH03StrictReport exposes:

- the complete Q4 canonical parse report
- one strict H0.3 result per Decision
- total H0.3 error count
- total H0.3 warning count
- blocked Decision count
- aggregate strict validity

A Q4 parse failure blocks the strict gate before H0.3 execution.

## Test coverage

Dedicated Q5 tests verify:

- a zero-issue Decision batch passes
- warning-only normal H0.3 reports are blocked by the LAB strict wrapper
- normal H0.3 errors are blocked
- answer-length warnings are blocking
- invalid Q4 parse prerequisites stop H0.3 execution
- strict validation is deterministic

The existing H0.3 validator regression remains mandatory to prove normal question semantics were not altered.

Q1 through Q4, DQG300-LAB, Studio and full repository regressions also remain mandatory.

## Out of scope

LSP-Q5 does not:

- alter DQG300 rules or DQS
- combine H0.3 and DQG300 into one Decision-quality result
- alter LAB1000 publication eligibility
- modify learner presentation validation
- populate the ten scenario packages
- expose scenarios to learners

## Next authorized action

LSP-Q6 — Combine canonical parse + strict H0.3 + DQG300 into one Decision-quality gate.


## Closure candidate

Q5 implementation commit: `9c48fe0bfd8d90270bc0466dcb5f8df7df97b937`

CI formatter-staging hardening commit: `89c3295a471750aa1d37101b8b59654eb926bcf6`

Canonical formatter output commit: `924e570ff114da879260167577d5ffa46afd3d6a`

The formatter commit changes presentation formatting only. This documentation-only closure commit is the exact-SHA validation target for LSP-Q5. No runtime, validator, publication, learner, or evidence behavior is changed by the closure step.
