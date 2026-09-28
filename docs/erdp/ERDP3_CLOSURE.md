# ERDP-3 Balanced Planner Closure

Status: CLOSED
Phase: ERDP-3
Base checkpoint: `phase-erdp2-flashcard-execution-closed@7ad030a7b6ad6ae675441df595b58742d061e5c1`
Validated implementation head: `ee7fbf5ed5ffeb7d2d87096d5a9162cf9cfb800f`
Validation run: `36391677963`

## 1. Scope closed

ERDP-3 upgrades the existing authoritative `DailyStudyPlanService` into a balanced daily portfolio planner. It does not create a second planner, a second readiness score, or a second learner plan source.

The authoritative flow remains:

`Readiness evidence -> LearningPriorityEngine -> DailyStudyPlanService -> DailyStudyPlan`

Home and Daily Plan continue to consume the same `DailyStudyPlan`.

## 2. Balanced portfolio contract

When daily capacity can safely support it, the planner protects representation for the existing learner-facing families:

- Learn;
- Practice;
- Remember.

The baseline portfolio floor is:

- Learn: 15 minutes;
- Practice: 5 minutes;
- Remember: 5 minutes.

The floor is a reservation, not a second plan. Remaining capacity is still allocated by the existing readiness, priority, retention, difficulty, recency and exam-proximity logic.

If the remaining daily capacity cannot satisfy the missing portfolio families, the planner does not fabricate an impossible schedule or exceed the learner's available minutes.

## 3. Priority and evidence behavior preserved

ERDP-3 preserves the existing M7D safety semantics:

- insufficient evidence routes to Diagnostic rather than Repair;
- genuine performance gaps may route to Repair;
- stale evidence may route to Recheck;
- coverage gaps may route to Learn;
- retention gaps may route to spaced review;
- justified published Ultra Hard work remains schedulable;
- recent-study penalty remains active;
- exam proximity remains active;
- started and completed blocks remain locked and are preserved exactly during regeneration.

The planner still uses readiness evidence as an input. It does not award readiness credit itself.

## 4. Phase-aware planning integration

`PhaseAwareDailyPlanService` continues to apply exam-phase context and metadata.

ERDP-3 portfolio-floor blocks carrying `BALANCED_PORTFOLIO` are protected from cross-family phase rewrites. This prevents a valid Learn / Practice / Remember portfolio from being silently collapsed into one or two families near the exam.

Non-floor blocks remain eligible for the existing phase-aware adaptation rules.

## 5. Six-block capacity contract

The existing maximum of six Daily Plan blocks is preserved.

To reserve space for the balanced portfolio plus justified assessment work, the default daily competency breadth is two competencies. This preserves a free assessment slot for work such as Ultra Hard practice while avoiding an increase in the six-block ceiling.

`maxCompetenciesPerDay` remains configurable for explicit planner configurations.

## 6. Focused ERDP-3 tests

Added and validated:

- `test/features/exam_readiness/erdp/erdp3_balanced_portfolio_policy_test.dart`
- `test/features/exam_readiness/erdp/erdp3_balanced_planner_integration_test.dart`
- `test/features/exam_readiness/erdp/erdp3_daily_constraints_test.dart`

Coverage includes:

1. 60-minute plans protect Learn, Practice and Remember.
2. Already represented families are not unnecessarily reserved again.
3. Insufficient capacity fails safely without over-allocation.
4. Balanced reservations are visible through `BALANCED_PORTFOLIO` reason codes.
5. Phase-aware readiness planning preserves all three families.
6. Started blocks remain byte-for-byte equivalent through regeneration.
7. The six-block ceiling remains intact.
8. The default two-competency breadth is frozen while custom breadth remains configurable.

## 7. Regression evidence

GitHub Actions run `36391677963` completed successfully on implementation head `ee7fbf5ed5ffeb7d2d87096d5a9162cf9cfb800f`.

The successful gate included:

- ERDP-3 source parse / formatting surface;
- targeted ERDP-3 analysis;
- all ERDP-3 targeted tests;
- complete `test/features/exam_readiness/m7d` regression suite;
- ERDP-2 Flashcard execution regression;
- diff hygiene.

An earlier whole-repository analyzer attempt exposed pre-existing repository-wide lint debt. ERDP-3 therefore uses a phase-scoped analyzer gate while retaining the full relevant behavioral regressions. No ERDP-3 error or warning was accepted into closure.

## 8. Frozen invariants carried forward

ERDP-3 does not change the earlier ERDP invariants:

1. `DailyStudyPlan` is the only authoritative learner daily plan.
2. The existing Exam Readiness engine remains the only authoritative readiness calculation.
3. Home is a projection of the plan, not another planner.
4. Opening content does not complete a task.
5. Navigation gives no readiness credit.
6. Micro-learning exposure gives no direct readiness credit.
7. Questions and LAB/applied outcomes remain stronger evidence than passive activity.
8. Flashcards remain supporting retention evidence.

## 9. Closure rule

Frozen checkpoint:

`phase-erdp3-balanced-planner-closed`

ERDP-4 must begin strictly from the commit containing this closure record after its closure validation run is green.

Next working branch:

`phase-erdp4-universal-execution-router`
