# CSP11 ERDP Implementation Plan

Status: FROZEN
Phase: ERDP-0
Program: Exam Readiness + Daily Plan Learner Intelligence
Base checkpoint: `phase-loading-microlearning-integration@675254a4b7825765102f22d9a1a0acbcbd30d395`

## 1. Purpose

ERDP upgrades the existing CSP11 Exam Readiness and DailyStudyPlan systems into one closed-loop learner-intelligence system. It does not create a second planner and does not replace the existing readiness engine.

The learner-facing questions are:

1. How ready am I?
2. Why?
3. What is holding me back?
4. What should I do next?

The runtime loop is:

`Learner Activity -> Evidence -> Readiness Profile -> Learning Priority Engine -> DailyStudyPlan -> Execution Router -> Real Learning Activity -> Outcome -> Evidence + Replanning`

## 2. Frozen architectural invariants

The following invariants are authoritative for the whole ERDP program:

- `DailyStudyPlan` remains the single authoritative daily plan.
- The existing Exam Readiness engine remains the single authoritative readiness calculation.
- Home is a projection of the authoritative DailyStudyPlan, not a second planner.
- Daily Plan is the execution surface of the authoritative DailyStudyPlan.
- Activities never write readiness directly.
- Activities emit evidence. Evidence aggregation updates learner state. Readiness interprets that state. The planner converts that intelligence into actions.
- Opening a destination never counts as completing a task.
- Starting a task never counts as completing a task.
- Study completion is coverage/context evidence only.
- Micro-learning produces no direct readiness credit.
- Flashcard outcomes are supporting retention evidence, not a substitute for question or applied evidence.
- Question performance and LAB/application evidence remain stronger readiness evidence than passive study or single-card success.
- No learner can become exam ready merely by opening content, finishing passive study blocks, or flipping cards.
- No Daily Plan primary control may be decorative.

## 3. Evidence hierarchy

### Strong readiness evidence

- Question performance.
- LAB / applied scenario performance.
- Simulation assessment outcomes.

### Supporting readiness evidence

- Repeated spaced flashcard recall.
- Confidence calibration evidence.
- Recheck outcomes.

### Coverage/context evidence

- Study content completion.
- Content coverage.
- Recency of study exposure.

### Zero direct readiness credit

- Micro-learning fact exposure.
- Opening a screen.
- Starting a task.
- Scrolling content.
- Merely viewing or revealing a flashcard.

## 4. Program checkpoints

ERDP is implemented and frozen sequentially:

- ERDP-0: Architecture and Contract Freeze.
- ERDP-1: Exam Readiness Intelligence Upgrade.
- ERDP-2: Flashcards as First-Class Daily Plan Tasks.
- ERDP-3: Balanced Daily Plan Generator.
- ERDP-4: Universal Study Plan Execution Router.
- ERDP-5: Fully Functional Start / Skip / Tomorrow / Replace Controls.
- ERDP-6: Adaptive Replanning Engine.
- ERDP-7: Readiness-to-Action Integration.
- ERDP-8: Daily Plan UX and State Presentation.
- ERDP-9: Closed-Loop Flashcard + Learning Twin Intelligence.
- ERDP-10: Whole-System Acceptance and Production Freeze.

Every checkpoint is independently testable and frozen before the next stage begins.

## 5. ERDP-0 - Architecture and Contract Freeze

### Goal

Inventory the current implementation and freeze the exact contracts ERDP will extend.

### Required inventory

Inspect and document:

- `DailyStudyPlan` model and repository.
- Existing study-plan block types and states.
- Learn / Practice / Remember categorization.
- Existing Exam Readiness engine.
- Evidence aggregation and learner-state inputs.
- Daily Plan screen.
- Home Today's Plan projection.
- Existing Start / Complete / Skip / Tomorrow / Replace / Shorten semantics.
- Flashcards runtime and cloud package binding.
- Study Content launcher.
- Question session launcher.
- LAB launcher.
- Simulation flow.
- Learning Twin state model.
- Persistence boundaries.
- Cloud/local repositories.
- Existing focused and whole-repository validation gates.

### ERDP-0 deliverables

- This frozen implementation plan.
- Architecture inventory.
- Dependency map.
- State-transition contract.
- Evidence hierarchy contract.
- Execution-target contract.
- Acceptance-test matrix.
- Baseline regression evidence.

### Closure checkpoint

`phase-erdp0-plan-contract-closed`

## 6. ERDP-1 - Exam Readiness Intelligence Upgrade

### Goal

Make readiness immediately explainable and actionable without replacing the existing readiness engine.

### Required readiness dimensions

Readiness must distinguish at least:

- Knowledge.
- Application.
- Retention.
- Blueprint coverage.
- Difficulty coverage.
- Recency.
- Confidence calibration.
- Evidence sufficiency.

### Required output concepts

A readiness result must expose:

- Overall readiness state.
- Overall readiness score where currently supported.
- Strong competencies.
- Weak competencies.
- Evidence-gap competencies.
- Due flashcards.
- Weak competency count.
- Next best action.
- Explainable reasons for each recommendation.

### Evidence sufficiency rule

Insufficient evidence is not equivalent to weakness.

Example:

`D02: low performance + high evidence sufficiency -> genuine weakness`

`D06: sparse evidence + low evidence sufficiency -> diagnostic needed`

### Readiness presentation target

The screen should be able to present information such as:

- `Readiness: Building`
- `Strong: D01, D04`
- `Needs attention: D02`
- `Evidence needed: D06`
- `27 flashcards due`
- `3 weak competencies`
- `Next best action: 15 min D02 targeted practice`

### Closure checkpoint

`phase-erdp1-readiness-intelligence-closed`

## 7. ERDP-2 - Flashcards as First-Class Daily Plan Tasks

### Goal

Route Remember / spaced-review work into the real Flashcards runtime rather than generic Study Content.

### Required execution target

Add a dedicated target equivalent to:

`StudyPlanExecutionTargetKind.flashcardReview`

A flashcard execution target must be capable of preserving:

- competency IDs;
- optional card IDs;
- due-only filtering;
- weak-only filtering;
- source evidence identifiers;
- target card count;
- target minutes;
- review reason.

### Required mapping

`spacedReview / retentionRecovery / weakRecall / overdueRecall -> flashcardReview -> Flashcards runtime`

### Prioritization inputs

Flashcards should consider:

- overdue state;
- spaced-repetition state;
- weak concepts;
- recent question errors;
- recent LAB/application weakness;
- domain/competency weighting;
- learner-state weakness.

### Completion outcome

A completed flashcard plan task should be able to report:

- cards presented;
- cards rated;
- Again count;
- Hard count;
- Got It count;
- competencies covered;
- elapsed duration;
- completion timestamp.

Opening Flashcards alone must not complete the Daily Plan task.

### Closure checkpoint

`phase-erdp2-flashcard-execution-closed`

## 8. ERDP-3 - Balanced Daily Plan Generator

### Goal

Generate an intentional learning mixture instead of repeatedly selecting the same highest-scoring activity class.

### Authoritative category contract

The existing Learn / Practice / Remember categorization remains authoritative unless a separately frozen migration explicitly changes it.

Baseline mapping:

- Learn: Learn, Continue, Repair.
- Practice: Diagnostic, Standard Practice, Ultra Hard, Mixed Retrieval, Recheck, Confidence Calibration, Simulation, Recovery and other assessment-oriented blocks already defined by the current model.
- Remember: Spaced Review and retention-recovery work.

### Planning inputs

The planner should consider:

- available minutes;
- exam proximity;
- weakness/remediation pressure;
- retention debt;
- evidence gaps;
- blueprint coverage;
- recent learning;
- recent assessment;
- application/LAB weakness;
- carry-forward tasks;
- task fatigue;
- maintenance of stronger areas.

### Baseline mix

Use approximately:

- 70% weakness/remediation;
- 20% retention;
- 10% maintenance.

This is a baseline policy, not a permanently hard-coded invariant. The planner may adapt the mix as the exam approaches or evidence changes.

### Example 60-minute plan

- Learn: 15 min.
- Targeted Practice: 20 min.
- Remember / Flashcards: 10 min.
- Apply / LAB: 10 min when appropriate.
- Repair: 5 min.

### Closure checkpoint

`phase-erdp3-balanced-planner-closed`

## 9. ERDP-4 - Universal Study Plan Execution Router

### Goal

Create one authoritative routing layer between DailyStudyPlan blocks and real learner activities.

### Required flow

`DailyStudyPlanBlock -> StudyPlanExecutionRouter -> StudyPlanExecutionTarget -> learner activity`

### Required routing semantics

- Learn -> exact Study Content destination.
- Continue -> exact prior content position when available.
- Practice -> targeted question session.
- Diagnostic -> diagnostic question session.
- Remember -> filtered Flashcard review.
- LAB / Apply -> appropriate LAB scenario.
- Simulation -> exam simulation.
- Repair -> weakest pedagogically appropriate activity.
- Recheck -> targeted reassessment.

### Execution target specificity

Execution targets should carry sufficient context to reproduce the assigned objective. A target should not merely say `Open Practice` when the plan knows the competency, mode, question count, difficulty policy, reason and source block.

### Start transaction order

Start must follow this order:

1. validate plan block;
2. resolve execution target;
3. persist `planned -> started`;
4. create or bind an execution attempt;
5. navigate.

Navigation must not occur first and then retroactively pretend the task started.

### Closure checkpoint

`phase-erdp4-universal-execution-router-closed`

## 10. ERDP-5 - Fully Functional Daily Plan Controls

### Goal

Make Start task, Skip, Tomorrow and Replace fully persisted behaviors.

This is the first major learner-facing milestone.

### Start task

`planned -> started -> real activity -> actual outcome -> completed`

Starting is not completing.

### Skip

`planned -> skipped`

Skip must:

- persist the state change;
- free today's allocated time;
- record intentional non-completion;
- not reduce mastery by itself;
- not create negative readiness evidence;
- not masquerade as completion;
- be available to the planner as context for replanning.

### Tomorrow

Introduce persistent carry-forward semantics equivalent to:

- original plan ID;
- original block ID;
- competency ID;
- task type;
- execution target;
- minutes;
- reason;
- created-at timestamp;
- due date.

Tomorrow must consume carry-forward work before ordinary next-day recommendations, subject to valid planner constraints.

Tomorrow must be idempotent. Repeated taps must not create duplicate carry-forward tasks.

### Replace

Replace changes the learning method while preserving the learning objective wherever pedagogically valid.

Examples:

- targeted practice -> flashcards;
- targeted practice -> study review;
- flashcards -> targeted practice;
- study review -> targeted practice.

Persist original block, replacement block and replacement reason for auditability and future learner-preference analysis.

### Critical acceptance rule

`No Daily Plan button is decorative.`

If Start task, Skip, Tomorrow or Replace is visible, pressing it must produce the promised persisted behavior.

### Closure checkpoint

`phase-erdp5-executable-daily-plan-closed`

## 11. ERDP-6 - Adaptive Replanning Engine

### Goal

Make meaningful learner outcomes change the next plan through the common evidence pipeline.

### Required flow

`QuestionOutcome / FlashcardOutcome / LabOutcome / StudyOutcome / SimulationOutcome -> LearningEvidenceEvent -> Evidence Aggregator -> Readiness -> Learning Priority Engine -> Daily Planner`

### Behavioral examples

- Repeated D03 question errors increase D03 priority.
- Repeated Again ratings on related cards increase retention pressure.
- Strong question performance plus stale recall produces a short Remember intervention rather than another large question session.
- Sparse evidence produces Diagnostic rather than automatically labelling the learner weak.
- Study completion increases coverage/context but does not cause a large readiness jump by itself.

### Replanning triggers

Replanning may occur after:

- meaningful task completion;
- diagnostic completion;
- practice-session completion;
- flashcard-session completion;
- LAB completion;
- simulation completion;
- carry-forward action;
- replacement action;
- significant evidence change;
- new-day generation.

Do not replan on every UI tap.

### Closure checkpoint

`phase-erdp6-adaptive-replanning-closed`

## 12. ERDP-7 - Readiness-to-Action Integration

### Goal

Turn Readiness findings into executable actions through the same execution router used by Daily Plan.

### Required mapping

- knowledge weakness -> targeted Practice;
- retention weakness -> Flashcards;
- insufficient evidence -> Diagnostic;
- coverage gap -> Study;
- application weakness -> LAB;
- confidence mismatch -> Confidence Calibration;
- exam-proximity need -> Simulation.

Readiness must not build a separate navigation stack or execution system.

### Home contract

Home remains conceptually:

- Continue CSP.
- Today's Plan: Learn / Practice / Remember.
- Progress Intelligence.
- Exam Readiness.

Home reads from the authoritative DailyStudyPlan and does not generate another plan.

### Closure checkpoint

`phase-erdp7-readiness-action-integration-closed`

## 13. ERDP-8 - Daily Plan UX and State Presentation

### Goal

Make plan state, rationale and execution status obvious while preserving the behavior frozen in ERDP-5 through ERDP-7.

### Planned task presentation

A card should be able to show:

- category;
- minutes;
- domain/competency;
- specific assignment;
- `Why this?` rationale;
- Start task;
- Skip;
- Tomorrow;
- Replace.

### Started state

Show `IN PROGRESS` and a real `Resume task` action bound to the execution attempt.

### Completed state

Show completion metrics relevant to the task and indicate that evidence has been updated only when a qualifying activity actually produced evidence.

### Historical visibility

Skipped, moved and replaced tasks remain visible in a subdued state during the day so the learner can understand what happened to the plan.

### UX regression coverage

Validate:

- light mode;
- dark mode;
- small screens;
- long competency names;
- text scaling;
- navigation motion on/off;
- reduced motion where supported;
- accessibility semantics.

### Closure checkpoint

`phase-erdp8-daily-plan-ux-closed`

## 14. ERDP-9 - Closed-Loop Flashcard + Learning Twin Intelligence

### Goal

Make repeated spaced recall an explicit retention signal within the Learning Twin/readiness state without allowing flashcards to dominate exam readiness.

### Rating interpretation

- Again -> strong retention-gap signal.
- Hard -> moderate retention-gap signal.
- Got It -> positive supporting recall signal.

### Spacing rule

Repeated successful recall across increasing time intervals is stronger retention evidence than repeated success in one sitting.

The system should preserve enough state to reason about:

- recall outcome;
- spacing interval;
- previous card state;
- competency/concept;
- evidence source;
- attempt sequence;
- recency.

### Desired learner-state distinctions

The Learning Twin/readiness model should be able to distinguish cases such as:

- knowledge strong, retention stale;
- knowledge weak, retention weak, application unknown;
- application strong, retention due;
- evidence insufficient.

Micro-learning remains outside direct readiness scoring.

### Closure checkpoint

`phase-erdp9-closed-loop-retention-intelligence-closed`

## 15. ERDP-10 - Whole-System Acceptance and Production Freeze

### Goal

Prove the complete learner-intelligence loop survives realistic user journeys, persistence, restart and failure behavior.

### Primary end-to-end journey

1. Generate plan.
2. Start Learn.
3. Complete Learn.
4. Persist outcome.
5. Start Practice.
6. Complete Practice.
7. Persist assessment evidence.
8. Start Remember.
9. Open correctly filtered Flashcards.
10. Complete flashcard review.
11. Persist retention evidence.
12. Skip a task.
13. Move a task to Tomorrow.
14. Replace a task.
15. Close the app.
16. Restart.
17. Verify all states survive.
18. Advance to next day.
19. Verify carry-forward appears exactly once.
20. Complete carried task.
21. Recalculate readiness.
22. Verify next plan adapts.

### Replacement-path coverage

Where pedagogically valid, test:

- Learn -> Practice.
- Learn -> Flashcards.
- Practice -> Learn.
- Practice -> Flashcards.
- Flashcards -> Learn.
- Flashcards -> Practice.

### Failure and concurrency coverage

Test at least:

- double-tap Start;
- double-tap Tomorrow;
- double-tap Replace;
- navigation failure;
- persistence failure;
- cloud timeout;
- stale plan;
- missing/retired content;
- missing flashcard package;
- missing LAB;
- authentication loss;
- offline startup;
- reconnect;
- app termination during activity;
- app termination during persistence;
- cross-device state recovery where supported.

### Platform and presentation matrix

Validate:

- Android;
- Web;
- Windows;
- light mode;
- dark mode;
- motion on;
- motion off;
- authenticated cloud state;
- offline/failure state.

### Final closure invariants

ERDP cannot close with any known instance of:

- decorative Daily Plan controls;
- duplicate carry-forward tasks;
- false completions;
- passive readiness inflation;
- orphan execution attempts;
- competing DailyStudyPlan sources;
- competing readiness sources;
- known persistence divergence.

### Final checkpoint

`phase-erdp-learner-intelligence-closed`

## 16. Implementation sequencing rule

ERDP-1 must not begin until ERDP-0 is closed and frozen.

ERDP-2 through ERDP-5 must remain independently closable. They must not be collapsed into one uncontrolled implementation because they cross persistence, routing and learner-state boundaries.

ERDP-5 is the first major functional milestone because Daily Plan becomes an executable learning controller at that point.

## 17. Change-control rule

This document is frozen at ERDP-0. Any later architectural change that violates an invariant above requires an explicit ERDP contract amendment with rationale, migration impact and regression coverage. Silent drift is not permitted.
