# CSP11 Phase M7B - Learner Evidence Engine

## Status

IMPLEMENTED / VALIDATION PENDING

## Frozen parent

- M7A CLOSED / PASS
- frozen M7 plan blob: b714a740b4590a48fe8efba216e8ec59a31bd9e6

## Runtime architecture

M7B adds an append-only learner assessment-attempt ledger without changing the
existing per-question progress contract.

Each attempt snapshots:

- question ID and version
- domain / competency / topic / subtopic placement
- correctness
- answer timestamp
- cognitive level
- question type
- Standard / Hard / Ultra Hard lane
- publication state at attempt time
- optional learner confidence
- session kind

The attempt ledger is UID-scoped local data.

## Evidence aggregation

LearnerEvidenceAggregationService produces CompetencyEvidenceSnapshot records.

It:

- excludes unpublished evidence
- rejects malformed competency placement
- deduplicates duplicate attempt event IDs
- preserves repeated-question concentration
- preserves Standard / Hard / Ultra Hard as separate lanes
- separates Application and Analysis evidence
- measures topic and subtopic breadth
- measures 7-day and 30-day recency
- classifies stale evidence
- evaluates confidence calibration
- calculates delayed retrieval evidence
- emits structured evidence-confidence breakdowns
- emits traceability statements
- does not create readiness recommendations

## Retention

RetentionEvidenceService uses repeat retrieval for the same question.

Initial windows:

- under 24 hours: immediate
- 1-7 days: short delay
- 8-30 days: medium delay
- over 30 days: long delay

Immediate retrieval is not counted as delayed retention evidence.

No delayed evidence means delayed accuracy remains unavailable, never 0%.

## Incremental and rebuild paths

M7B supports:

- one-competency incremental refresh
- all-competency rebuild for migration/debugging

A competency refresh does not require recomputing unrelated competencies.

## Snapshot persistence

Evidence snapshots are stored local-first and may synchronize to:

users/{uid}/evidenceSnapshots/{competencyId}

Firestore uses:

- UID ownership
- self/admin read boundary
- field allowlisting
- competency/document-ID binding
- global recursive deny fallback

## Automatic capture

StudentQuestionProgressService now also appends the immutable M7B attempt after
normal question-progress persistence. Failure of M7B evidence capture cannot
interrupt the active quiz.

## Explicit non-goals

M7B does not calculate:

- readiness state
- a Readiness Index
- exam pass probability
- adaptive daily plans
- learning priorities
- recommendations

## Validation gate

M7B may close only after:

- frozen M7 contract PASS
- at least 100 explicit M7B tests
- zero skipped M7B tests
- canonical Dart formatting PASS
- Flutter analyzer PASS
- M7B targeted suite PASS
- complete Flutter regression PASS
- production web build PASS

Android debug/APK building is not an M7 phase gate.

M7C implementation must not be treated as authoritative until this gate passes.
