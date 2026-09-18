# CSP11 Phase M7 - Pre-Implementation Contract

## Status

PRE-M7 CONTRACT FROZEN

## Frozen source

Authoritative plan:

docs/learning_twin/PHASE_M7_EXAM_READINESS_FROZEN_IMPLEMENTATION_PLAN.md

Pinned Git blob:

b714a740b4590a48fe8efba216e8ec59a31bd9e6

Base implementation checkpoint:

1169059fc15d3f9b8c66c6958e4bccae8ce3ca5d

## Purpose

This contract prevents M7A-M7F from being closed through shortcutting,
requirement deletion, test suppression, warning tolerance, evidence fabrication,
or replacement of the frozen architecture with a weaker implementation.

## Mandatory execution order

M7A must close before M7B is treated as authoritative.

M7B must close before M7C is treated as authoritative.

M7C must close before M7D implementation may be treated as authoritative.

The same sequential rule applies through M7F.

## Minimum phase test gate

Every M7 phase requires at least 40 explicit automated test cases.

A generated loop that merely repeats the same assertion with different labels
does not satisfy this requirement by itself.

Tests must include positive, negative, boundary, serialization, architecture,
and failure-path coverage appropriate to the phase.

Skipped or disabled tests do not count.

## Frozen anti-shortcut rules

1. The frozen M7 implementation-plan blob may not change during M7A-M7C.
2. M7-001 through M7-020 must remain present.
3. Timed Exam Simulator suppression must remain in the decision service.
4. Missing evidence may never be coerced to zero mastery.
5. DQG300 Ultra Hard remains a distinct evidence lane.
6. The legacy H0.3 bulk importer must not import the DQG300 validator.
7. M7A may calculate capacity but may not invent readiness.
8. M7B may aggregate evidence but may not generate learner recommendations.
9. M7C may interpret evidence but may not introduce the composite Readiness Index.
10. No pass-probability language is allowed.
11. No manual quality override or bypass switch may be added.
12. No phase closure may rely on warnings being ignored.
13. Firebase access remains UID-scoped and fail-closed.
14. Heavy historical aggregation must not run from widget build methods.
15. Durable derived records must carry schema/algorithm version metadata.
16. Learners without an exam plan must retain existing Study/Practice behavior.
17. Light and dark surfaces must remain supported.
18. Runtime code must not depend on test-only fixtures.
19. Test count gates must be machine checked.
20. Full Flutter regression must pass before phase closure.

## Pre-M7 acceptance

Pre-M7 is considered PASS only when the executable verifier confirms:

- frozen plan blob unchanged
- all permanent rules present
- roadmap points to the frozen plan
- timed exam suppression remains fail-closed
- H0.3 / DQG300 separation remains intact
- no M7 runtime phase is falsely marked CLOSED before implementation

## Phase closure evidence

Each M7A-M7C closure document must record:

- exact branch
- exact commit SHA
- frozen-plan blob
- targeted test count
- targeted test result
- analyzer result
- full regression result
- relevant architecture verifier result
- known limitations
- statement that the next phase did not begin before the current phase gate passed

This contract is part of the M7 recovery and audit trail.
