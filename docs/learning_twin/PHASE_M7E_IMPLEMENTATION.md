# CSP11 Phase M7E - Closed Feedback Loop and Dynamic Replanning

## Status

IMPLEMENTED CORE / VALIDATION PENDING

## Frozen parent

- M7D CLOSED / PASS
- M7D runtime closure checkpoint: 910def967bcde96d887f6e8b0edef20caff86b0d
- M7D validation run: 35333834441
- frozen M7 plan blob: b714a740b4590a48fe8efba216e8ec59a31bd9e6

## Implemented M7E core

M7E now adds:

- immutable StudyPlanBlockOutcome
- UID-scoped local outcome history
- PlanRegenerationReason frozen vocabulary
- MisconceptionSignal and detection service
- LearningStateUpdateCoordinator
- one-competency evidence refresh
- one-competency readiness recalculation
- future-plan stale versioning
- controlled PlanReplanningService
- previousPlanId plan lineage
- inputSnapshotVersion lineage
- UID-scoped local learning-state audit trail
- weekly readiness review data model and service

## Evidence safety

Block completion does not manufacture assessment evidence.

The coordinator consumes the real M7B assessment-attempt ledger. Outcome
metrics are audit/context data. A learner completing time or content is never
converted into fake mastery, retention or confidence evidence.

## Incremental update boundary

A normal M7E outcome updates only the affected competency:

outcome
-> existing real attempts
-> affected competency evidence
-> affected competency readiness
-> misconception signals
-> future-plan staleness
-> controlled replanning checkpoint

M7E does not run buildAllSnapshots or buildDashboard after every outcome.

## Plan history

Historical DailyStudyPlan versions remain immutable.

A future plan becoming stale creates a new version with:

- incremented planVersion
- previousPlanId
- generationReason
- inputSnapshotVersion
- original historical version preserved

## Local learner-data boundary

M7E outcome, audit, evidence, readiness and daily-plan updates are local-first
and UID-scoped. Normal M7E state transitions do not require Firestore writes.

## Validation target

M7E must prove at least 40 explicit tests and the frozen sequences:

A. poor diagnostic -> evidence update -> targeted repair
B. excellent performance -> lower repetition need
C. missed day -> capacity-safe replan
D. poor Ultra Hard -> difficulty response / recheck
E. high-confidence incorrect -> calibration/misconception response

The defining closure proof remains:

same learner baseline + new evidence = different justified next-day plan.
