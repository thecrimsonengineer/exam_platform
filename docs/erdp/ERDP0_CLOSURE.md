# ERDP-0 Architecture and Contract Freeze Closure

Status: CLOSED
Phase: ERDP-0
Base checkpoint: `phase-loading-microlearning-integration@675254a4b7825765102f22d9a1a0acbcbd30d395`
Plan freeze commit: `2a977f35d80f7ae5b5197c4d22d3645274300058`

## 1. Closure decision

ERDP-0 closes as a contract/inventory phase only. No learner-facing runtime behavior is changed by this closure.

The existing CSP11 Exam Readiness and DailyStudyPlan architecture remains authoritative and is extended, not replaced, by ERDP-1 onward.

## 2. Authoritative runtime inventory

### Exam Readiness

Authoritative package: `lib/features/exam_readiness/`

Confirmed core contracts include:

- `models/competency_readiness_profile.dart`
- `models/advanced_readiness_snapshot.dart`
- `models/readiness_index_snapshot.dart`
- `models/readiness_gap.dart`
- `services/advanced_readiness_service.dart`
- `services/readiness_index_service.dart`
- `services/learner_evidence_aggregation_service.dart`
- `services/learning_priority_engine.dart`
- `services/evidence_debt_service.dart`
- `repositories/evidence_snapshot_repository.dart`
- `repositories/readiness_snapshot_repository.dart`
- `repositories/readiness_history_repository.dart`

The current readiness dashboard already distinguishes:

- knowledge mastery;
- application ability;
- retention;
- blueprint coverage;
- difficulty performance;
- confidence calibration;
- recent performance;
- stability;
- overall evidence confidence.

The readiness index remains evidence-gated. Insufficient evidence may suppress the composite score rather than being treated as low mastery.

### DailyStudyPlan

Confirmed authoritative contracts include:

- `models/daily_study_plan.dart`
- `models/study_plan_block.dart`
- `models/study_plan_block_outcome.dart`
- `models/study_plan_execution_target.dart`
- `repositories/daily_study_plan_repository.dart`
- `services/daily_study_plan_service.dart`
- `navigation/study_plan_block_launcher.dart`
- `screens/todays_plan_screen.dart`

`StudyPlanBlockType` currently contains exactly 12 types:

1. `learn`
2. `continueLearning`
3. `repair`
4. `diagnostic`
5. `spacedReview`
6. `standardPractice`
7. `ultraHardPractice`
8. `mixedRetrieval`
9. `competencyRecheck`
10. `confidenceCalibration`
11. `examSimulation`
12. `recovery`

Current persisted block states are:

- `planned`
- `started`
- `completed`
- `skipped`
- `movedToTomorrow`
- `replaced`
- `shortened`
- `unavailable`

Current manual actions are:

- `start`
- `complete`
- `skip`
- `moveToTomorrow`
- `replace`
- `shorten`
- `markUnavailable`

### Execution target contract

The current `StudyPlanExecutionTargetKind` values are exactly:

- `studyContent`
- `practiceSession`
- `review`
- `examSimulation`

A dedicated Flashcard target does not yet exist. That migration is reserved for ERDP-2.

## 3. Frozen evidence hierarchy

### Strong readiness evidence

- Question performance.
- LAB / applied scenario performance.
- Simulation assessment outcomes.

### Supporting readiness evidence

- Repeated spaced flashcard recall.
- Confidence-calibration evidence.
- Recheck outcomes.

### Coverage/context evidence

- Study-content completion.
- Content coverage.
- Recency of study exposure.

### Zero direct readiness credit

- Micro-learning fact exposure.
- Opening a screen.
- Starting a task.
- Scrolling content.
- Merely viewing or revealing a flashcard.

Activities must not write readiness directly. They emit evidence; aggregation updates learner state; readiness interprets learner state; planning converts that intelligence into actions.

## 4. Frozen readiness contract for ERDP-1

ERDP-1 must preserve the existing readiness algorithms and add an explainable/actionable intelligence projection.

Required dimensions are:

- Knowledge.
- Application.
- Retention.
- Blueprint coverage.
- Difficulty coverage/performance.
- Recency.
- Confidence calibration.
- Evidence sufficiency.

Required learner-facing concepts are:

- overall readiness state;
- overall readiness score when the current evidence gate allows it;
- strong competencies;
- weak competencies;
- evidence-gap competencies;
- due flashcards;
- weak competency count;
- next best action;
- explainable reasons for recommendations.

Invariant: insufficient evidence is not equivalent to weakness.

## 5. Dependency map

`Learning Activity -> Evidence Event / Attempt -> Evidence Aggregation -> Competency Readiness Profiles -> Exam Readiness Dashboard -> Readiness Index / Advanced Readiness -> Learning Priority Engine -> DailyStudyPlan -> Execution Target -> Learner Activity`

Home and learner surfaces must project from these authoritative contracts rather than creating parallel readiness or planning state.

## 6. State-transition contract

Allowed learner-plan lifecycle remains centered on persisted state transitions:

`planned -> started -> completed`

Alternative persisted transitions include:

`planned -> skipped`

`planned -> movedToTomorrow`

`planned -> replaced`

`planned -> shortened`

`planned -> unavailable`

Starting or navigating to an activity does not constitute completion.

## 7. ERDP-0 acceptance matrix

| Contract | Baseline result | ERDP owner |
| --- | --- | --- |
| Existing readiness engine remains authoritative | CONFIRMED | ERDP-1 |
| Knowledge/Application/Retention dimensions exist | CONFIRMED | ERDP-1 |
| Blueprint and difficulty evidence exist | CONFIRMED | ERDP-1 |
| Confidence calibration exists | CONFIRMED | ERDP-1 |
| Evidence sufficiency is explicit | CONFIRMED | ERDP-1 |
| DailyStudyPlan remains authoritative | CONFIRMED | ERDP-3 onward |
| 12 plan block types inventoried | CONFIRMED | ERDP-3 onward |
| Persisted plan statuses/actions inventoried | CONFIRMED | ERDP-5 |
| Execution target has 4 current kinds | CONFIRMED | ERDP-2/4 |
| Dedicated Flashcard execution target absent | CONFIRMED GAP | ERDP-2 |
| Micro-learning direct readiness credit prohibited | FROZEN | ERDP-1 onward |
| Opening/starting does not equal completion | FROZEN | ERDP-4/5 |

## 8. Validation boundary

This closure records source-level architecture and contract evidence only. No claim is made here that a new local Flutter analyze/test suite ran from this documentation-only ERDP-0 closure commit.

Existing readiness regression coverage is present under `test/features/exam_readiness/`, including the established M7A-M7F suites. ERDP-1 must add focused tests for the new intelligence projection before closure.

## 9. ERDP-0 closure rule

ERDP-1 may begin only from the commit containing this closure record.

Closure branch:

`phase-erdp0-plan-contract-closed`

Next working branch:

`phase-erdp1-readiness-intelligence`
