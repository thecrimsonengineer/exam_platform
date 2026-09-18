# CSP11 Phase M7D - Adaptive Daily Planner

## Status

IMPLEMENTED / VALIDATION PENDING

## Frozen parent

- M7C CLOSED / PASS
- M7C closure checkpoint: 649224fa43b24ba6d857cc7b85a7ee8094e52c42
- frozen M7 plan blob: b714a740b4590a48fe8efba216e8ec59a31bd9e6

## Runtime architecture

M7D converts exam capacity plus M7C readiness profiles into a deterministic,
explainable daily study plan.

Implemented:

- EvidenceDebtLevel and EvidenceDebtAssessment
- LearningPriorityScore with component-level transparency
- LearningPriorityEngine
- centralized DailyPlannerConstraints
- DailyStudyPlan
- StudyPlanBlock and frozen block-type vocabulary
- machine-readable reason codes and learner-facing reason text
- DailyStudyPlanService
- immutable UID-scoped DailyStudyPlanRepository history
- UltraHardAvailabilityService tied to published DQG300 Ultra Hard questions
- Today’s Plan learner UI
- Why This Plan explanation panel
- learner controls: Start, Skip, Tomorrow, Replace, Shorten, Unavailable
- started/completed block locking
- local-first daily-plan persistence

## Safety behavior

M7D preserves the frozen distinction between unknown evidence and weak
performance.

A competency with missing or low-confidence evidence is scheduled for
DIAGNOSTIC evidence gathering, not REPAIR.

Ultra Hard blocks are permitted only when a competency has at least five
published questions carrying the DQG300 Ultra Hard classification.

Started and completed blocks are locked and must survive regeneration exactly.

## Capacity behavior

The planner enforces:

- allocatedMinutes <= availableMinutes
- positive block durations
- centralized minimum and maximum block durations
- centralized maximum competencies and blocks per day
- deterministic candidate ordering
- no duplicate block IDs
- versioned plan generation

## Explainability

Each StudyPlanBlock stores:

- priority score
- component-level priority breakdown
- evidence debt
- reason codes
- learner-facing reason text
- planner algorithm version through the parent DailyStudyPlan
- source evidence/readiness versions through the parent DailyStudyPlan

## Local learner-data boundary

Daily plans are learner-owned local state by default.

The normal learner UI saves with syncRemote: false.

The repository retains optional remote-store infrastructure for explicit future
backup/synchronization work, but the current learner flow does not depend on
Firestore writes.

## Existing learner integration

Before Today's Plan is generated, CSP11 refreshes local readiness from the
learner's current evidence. Legacy UID-scoped question progress is bridged into
readiness conservatively where needed.

## Tests

The M7D suite currently contains 149 explicit tests across:

- model and serialization behavior
- priority scoring and evidence debt
- daily planning and capacity boundaries
- diagnostic-versus-repair behavior
- Ultra Hard availability
- manual controls
- block locking
- regeneration
- immutable repository history
- failure paths

## Validation gate

M7D closes only after:

- frozen M7 contract PASS through M7D
- M7D explicit test floor PASS
- zero skipped M7D tests
- Dart formatting PASS
- Flutter analyzer PASS
- M7D targeted suite PASS
- complete Flutter regression PASS
- production web build PASS

M7E must not be treated as authoritative until this gate passes.
