# CSP11 Phase M7 - Exam Readiness System
## Frozen Implementation Plan: M7A through M7F

## Status

FROZEN IMPLEMENTATION PLAN / NOT YET IMPLEMENTED

This document freezes the agreed design direction for Phase M7.

It is an implementation specification, not evidence that M7 is complete.

No M7A-M7F runtime feature may be reported as CLOSED / PASS until its own implementation, validation, test, visual-review and closure gates are completed.

## Purpose

Phase M7 turns the Learning Twin from a deterministic practice coach into an evidence-aware exam-readiness planning system.

The target product is not a static exam calendar and not a single readiness percentage.

The system must continuously answer three learner questions:

1. What should I study today?
2. Why is this the best use of my available study time?
3. How strong is the evidence that I am becoming exam-ready?

The final M7 system combines:

- exam-date planning
- realistic study-capacity calculation
- competency-level evidence aggregation
- multidimensional readiness interpretation
- adaptive daily planning
- closed-loop replanning after learner activity
- readiness trajectory
- evidence debt
- capacity pressure
- exam-phase adaptation
- DQG300 Ultra Hard evidence
- explicit uncertainty and evidence-confidence reporting

## Governing principle

CSP11 must distinguish:

- what it has directly observed
- what it has calculated from evidence
- what it suspects from incomplete evidence
- what it does not yet have enough evidence to judge

Missing evidence must never be displayed as poor performance.

0% and INSUFFICIENT EVIDENCE are not equivalent states.

## Relationship to the existing Learning Twin safety architecture

The previously planned M7 - Exam Simulator Boundaries concept is preserved as a permanent prerequisite and safety boundary rather than discarded.

The following frozen rule remains authoritative throughout M7A-M7F:

> When an active timed Exam Simulator session is running, the LearningTwinDecisionService must return no learner-facing intervention.

This is a decision-layer rule.

It must not depend only on hiding a widget.

M7A-M7F may use exam-simulation results after submission as evidence where explicitly allowed by later implementation, but must never provide hints, coaching, answer leakage, readiness prompts, adaptive suggestions or Learning Twin intervention during an active timed exam.

## M7 system architecture

The frozen high-level loop is:

~~~text
Learner profile + exam date
            |
            v
M7A Capacity Engine
            |
            v
M7B Evidence Engine
            |
            v
M7C Readiness Profile
            |
            v
M7D Priority + Daily Plan Engine
            |
            v
Learning Twin explanation layer
            |
            v
Learner studies / answers questions
            |
            v
M7E Feedback + Replanning
            |
            v
Updated evidence
            |
            v
M7F Advanced Readiness Intelligence
            |
            +---------------------> loop
~~~

The architecture must remain layered.

Evidence collection, readiness interpretation and planning must not collapse into one service.

## Frozen phase order

Implementation order is mandatory:

1. M7A - Exam Plan Foundation and Capacity Engine
2. M7B - Learner Evidence Engine
3. M7C - Multidimensional Readiness Profile
4. M7D - Adaptive Daily Planner
5. M7E - Closed Feedback Loop and Dynamic Replanning
6. M7F - Advanced Readiness Intelligence

Each phase requires its own checkpoint and closure before the next phase may be treated as authoritative.

Recommended closure labels:

~~~text
M7A-CLOSED
M7B-CLOSED
M7C-CLOSED
M7D-CLOSED
M7E-CLOSED
M7F-CLOSED
PHASE-M7-CLOSED
~~~

## Permanent M7 architectural rules

### M7-001 - Existing safety behavior remains authoritative

M7 must preserve all previously frozen Learning Twin safety constraints.

### M7-002 - Timed exam suppression

No M7 coaching, planning prompt, hint, readiness prompt or intervention may be shown during an active timed Exam Simulator session.

### M7-003 - DQG300 remains a distinct evidence source

Ultra Hard DQG300 attempts must remain identifiable separately from ordinary Hard-question attempts.

### M7-004 - Legacy H0.3 bank remains separate

The existing standard bulk importer and H0.3 question-quality lane must not be silently converted into DQG300.

### M7-005 - Missing evidence is not failure

No service may infer poor mastery from absent assessment evidence.

### M7-006 - No false precision

A readiness percentage must never be displayed where the available evidence cannot support that level of precision.

### M7-007 - Every derived result carries evidence confidence

Readiness conclusions must expose evidence quantity, breadth, recency and confidence.

### M7-008 - Every generated task is explainable

Every adaptive StudyPlanBlock must contain machine-readable reason codes.

### M7-009 - Plan generation must be reproducible

The system must be able to identify the source snapshot and algorithm version used to generate a plan.

### M7-010 - Plan history is immutable

Regeneration creates a new version. It must not erase the previous plan.

### M7-011 - Readiness is not pass probability

The product must not describe the readiness model as a probability of passing the CSP examination.

### M7-012 - Learner-facing recommendations are explainable

The learner must be able to understand the principal reasons for a recommendation.

### M7-013 - Firebase traffic must remain bounded

Heavy historical aggregation must not run from every UI rebuild.

### M7-014 - Snapshot architecture

Where practical, learner screens consume pre-aggregated snapshots instead of re-reading the full attempt history.

### M7-015 - Deterministic calculation tests

Every readiness, capacity, priority and planning calculation must have deterministic unit tests.

### M7-016 - Theme parity

Every M7 learner screen must support both light and dark mode.

### M7-017 - Mobile-first layout

Android-sized screens remain the primary layout constraint.

### M7-018 - Backward compatibility

Existing learner progress and practice flows must continue to work for users who do not configure an exam date.

### M7-019 - Versioned schemas and algorithms

Evidence, readiness and planning models must carry schema or algorithm versions.

### M7-020 - Fail soft, never invent

If required evidence is unavailable, the UI must show an insufficient-evidence state instead of inventing a score.

---

# M7A - Exam Plan Foundation and Capacity Engine

## Status

PLANNED

## Objective

M7A answers:

> How much realistic study capacity does this learner have before the exam?

M7A does not judge readiness.

It creates the scheduling envelope used by later phases.

## M7A.1 Core model

Create ExamStudyPlan.

Recommended fields:

~~~text
ExamStudyPlan
- id
- userId
- examDate
- timezone
- createdAt
- updatedAt
- active
- planVersion

schedule
- studyDaysOfWeek
- defaultMinutesPerStudyDay
- daySpecificMinutes
- preferredRestDays
- allowWeekendExtension
- maxDailyMinutes

preferences
- intensity
- preferredSessionLength
- preferredStartPeriod
- adaptiveSchedulingEnabled

metadata
- source
- schemaVersion
~~~

Calculated values such as days remaining and hours remaining must not be stored as immutable source-of-truth values.

They must be derived from the active plan and current date.

## M7A.2 Study-day representation

Do not store only 5 days/week.

Store actual selected days.

Example:

~~~text
Monday     60
Tuesday    60
Wednesday  45
Friday     60
Saturday   90
~~~

This permits exact capacity calculations.

## M7A.3 Schedule exceptions

Define StudyScheduleException.

Supported future exception types should include:

- unavailable
- extraStudyDay
- overrideMinutes
- travel
- leave
- holiday
- intensiveRevisionDay

Example:

~~~text
date: 2026-10-21
type: unavailable
reason: travel
~~~

## M7A.4 Capacity service

Create ExamStudyCapacityService.

Input:

- active ExamStudyPlan
- current local date
- schedule exceptions

Output:

StudyCapacitySnapshot.

Recommended fields:

~~~text
StudyCapacitySnapshot
- generatedAt
- examDate
- calendarDaysRemaining
- plannedStudyDaysRemaining
- plannedMinutesRemaining
- plannedHoursRemaining
- studyDaysThisWeek
- minutesThisWeek
- averageMinutesPerStudyDay
- weeksRemaining
- examPhaseHint
- schemaVersion
~~~

## M7A.5 Required calculations

The service must calculate at minimum:

- exam date
- calendar days remaining
- study days remaining
- study minutes remaining
- study hours remaining
- current-week planned study days
- current-week planned minutes
- weeks remaining

Example:

~~~text
Exam date                 15 December 2026
Calendar days remaining   88
Study days remaining      63
Study minutes remaining   3,780
Study hours remaining     63.0
Weeks remaining           12.6
~~~

## M7A.6 Date safety

M7A must correctly handle:

- exam date today
- exam date tomorrow
- exam date in the past
- leap years
- timezone boundary changes
- plan edited late at night
- local date changes while app remains open
- DST-safe logic for supported regions
- no active exam plan

## M7A.7 Exam plan setup UX

Recommended setup flow:

### Step 1 - Exam date

~~~text
WHEN IS YOUR CSP EXAM?
15 December 2026
~~~

### Step 2 - Study days

~~~text
HOW OFTEN CAN YOU STUDY?

M  T  W  T  F  S  S
Y  Y  Y     Y  Y
~~~

### Step 3 - Time capacity

~~~text
HOW MUCH TIME DO YOU HAVE?

60 min / study day
~~~

Optional advanced controls may later allow day-specific minutes.

### Step 4 - Capacity preview

~~~text
YOUR STUDY CAPACITY

88 days remaining
63 planned study days
approximately 63 study hours available
~~~

### Step 5 - Create plan

~~~text
CREATE MY PLAN
~~~

## M7A.8 Exam Readiness Plan screen

Create the first version of Exam Readiness Plan.

M7A top section:

~~~text
CSP EXAM
15 DECEMBER 2026

88 DAYS
until exam
~~~

Capacity panel:

~~~text
63
study days remaining

63h
planned study capacity

5
study days this week
~~~

No readiness percentage is added during M7A.

## M7A.9 Persistence

Recommended Firestore structure:

~~~text
users/{uid}/examPlans/{planId}
~~~

Only one plan is normally active.

Use active: true rather than overwriting historical plans.

## M7A.10 Local cache

Cache the active plan and latest capacity snapshot using the same low-traffic principles used elsewhere in CSP11.

Opening Home or Exam Readiness must not require repeated Firestore reads where valid local state already exists.

## M7A.11 Repository/service split

Recommended files:

~~~text
lib/features/exam_readiness/models/exam_study_plan.dart
lib/features/exam_readiness/models/study_schedule_exception.dart
lib/features/exam_readiness/models/study_capacity_snapshot.dart
lib/features/exam_readiness/repositories/exam_study_plan_repository.dart
lib/features/exam_readiness/services/exam_study_capacity_service.dart
lib/features/exam_readiness/screens/exam_plan_setup_screen.dart
lib/features/exam_readiness/screens/exam_readiness_plan_screen.dart
~~~

## M7A.12 Tests

Minimum M7A test matrix:

- exam tomorrow
- exam today
- exam in past
- leap year
- one study day per week
- five study days per week
- seven study days per week
- day-specific minute override
- unavailable exception
- extra-study-day exception
- exam-date edit
- schedule edit
- no active plan
- cache restoration
- repository round trip
- timezone-local date handling
- light UI
- dark UI
- narrow Android viewport
- wide Android viewport
- web layout
- accessibility semantics

## M7A closure gate

M7A closes only when CSP11 can reliably display:

- exam date
- calendar days remaining
- planned study days remaining
- planned study hours remaining
- current-week capacity

with deterministic tests and without readiness inference.

---

# M7B - Learner Evidence Engine

## Status

PLANNED AFTER M7A

## Objective

M7B answers:

> What evidence does CSP11 actually possess about this learner?

It must not yet answer:

> How ready is the learner?

Evidence gathering and readiness interpretation remain separate layers.

## M7B.1 Evidence taxonomy

The system must distinguish at least:

- knowledge evidence
- application evidence
- analysis evidence
- retention evidence
- difficulty evidence
- blueprint-coverage evidence
- confidence evidence
- recency evidence
- evidence-volume evidence
- evidence-breadth evidence
- stability evidence

## M7B.2 Competency evidence snapshot

Create CompetencyEvidenceSnapshot.

Recommended structure:

~~~text
CompetencyEvidenceSnapshot
- competencyId
- generatedAt
- schemaVersion
- sourceAttemptCount

coverage
- topicsAvailable
- topicsAssessed
- subtopicsAvailable
- subtopicsAssessed
- coverageRatio

attempts
- total
- correct
- incorrect
- uniqueQuestions

cognition
- recallAttempts
- applicationAttempts
- analysisAttempts
- applicationAccuracy
- analysisAccuracy

difficulty
- standardAttempts
- hardAttempts
- ultraHardAttempts
- standardAccuracy
- hardAccuracy
- ultraHardAccuracy

retention
- delayedAttempts
- delayedAccuracy
- lastReviewedAt
- daysSinceReview

confidence
- confidenceSamples
- calibrationError
- overconfidenceRate
- underconfidenceRate

recency
- attempts7d
- attempts30d
- lastAttemptAt

evidenceQuality
- quantity
- breadth
- recency
- diversity
- confidenceLevel
~~~

## M7B.3 Evidence confidence

Create:

~~~text
EvidenceConfidence
- none
- veryLow
- low
- moderate
- high
- veryHigh
~~~

Evidence confidence must not be calculated from question count alone.

It must consider:

- number of attempts
- unique question count
- subtopic breadth
- topic breadth
- cognitive-level diversity
- difficulty diversity
- recency
- delayed retention evidence
- repeated-attempt concentration

## M7B.4 Evidence-confidence breakdown

Create a structured breakdown.

Example:

~~~text
Quantity        HIGH
Breadth         LOW
Recency         HIGH
Difficulty      MODERATE
Retention       NONE

Overall evidence confidence: LOW
~~~

This breakdown must be available for explanation and debugging.

## M7B.5 Evidence state

Define evidence sufficiency states independently from readiness:

~~~text
UNASSESSED
INSUFFICIENT
EMERGING
ADEQUATE
ROBUST
STALE
~~~

A learner may have:

~~~text
Performance: HIGH
Evidence: LOW
~~~

or:

~~~text
Performance: LOW
Evidence: HIGH
~~~

These must never be treated as equivalent cases.

## M7B.6 DQG300 Ultra Hard integration

The existing Ultra Hard classification ultra-hard-dqg300 must remain a distinct evidence lane.

Do not silently merge Ultra Hard attempts into ordinary Hard-question metrics.

At minimum preserve:

~~~text
Standard accuracy
Hard accuracy
Ultra Hard accuracy
~~~

Ultra Hard may later carry stronger importance in application and readiness reasoning, but it must not dominate the evidence model without validation.

## M7B.7 Retention evidence

Immediate correctness is not equivalent to retention.

Define initial delay windows:

~~~text
less than 24 hours    immediate
1-7 days              short-delay
8-30 days             medium-delay
more than 30 days     long-delay
~~~

Create RetentionEvidenceService.

Retention calculation must use delayed retrieval evidence.

If delayed evidence does not exist, retention must remain insufficient rather than display 0%.

## M7B.8 Recency bands

Initial bands:

~~~text
0-7 days      very recent
8-30 days     recent
31-60 days    aging
61-90 days    stale
more than 90  very stale
~~~

M7F may later replace these with a validated continuous decay model.

## M7B.9 Confidence calibration

Confidence collection should initially be used selectively.

Preferred early surfaces:

- diagnostic assessments
- Ultra Hard Exam Readiness
- readiness checkpoints

Suggested learner input:

~~~text
Low
Medium
High
~~~

Important patterns:

- high confidence + correct
- high confidence + incorrect
- low confidence + correct
- low confidence + incorrect

Repeated high-confidence incorrect responses must become an identifiable misconception/calibration signal.

## M7B.10 Aggregation service

Create LearnerEvidenceAggregationService.

Responsibilities:

- load relevant attempt records
- classify attempt type
- group by competency
- aggregate correctness
- aggregate cognitive evidence
- aggregate difficulty evidence
- aggregate retention evidence
- calculate breadth
- calculate recency
- calculate evidence confidence
- emit CompetencyEvidenceSnapshot

It must not generate learner recommendations.

## M7B.11 Aggregated persistence

Recommended snapshot storage:

~~~text
users/{uid}/evidenceSnapshots/{competencyId}
~~~

Recommended metadata:

~~~text
generatedAt
sourceAttemptCount
evidenceSchemaVersion
algorithmVersion
~~~

The learner UI should normally read snapshots, not the entire attempt history.

## M7B.12 Incremental update requirement

A new attempt in D03 C02 should update the relevant competency and aggregate views without recomputing every competency in the blueprint.

A full rebuild path must still exist for migration and debugging.

## M7B.13 Evidence traceability

A snapshot must be able to answer questions such as:

~~~text
Why is Application Evidence MODERATE?
~~~

Example explanation:

~~~text
27 Application/Analysis attempts
6 subtopics represented
18 attempts in the last 30 days
4 Ultra Hard attempts
~~~

## M7B.14 M7B tests

Required categories include:

- no attempts
- one attempt
- repeated same question
- duplicate attempt events
- mixed difficulty
- Ultra Hard attempts
- mixed cognitive levels
- one-subtopic concentration
- broad competency coverage
- very old evidence
- recent evidence
- delayed retention
- confidence data
- missing confidence data
- unpublished-question exclusion
- malformed competency identifiers
- source question removed after attempt
- mixed standard/Hard/Ultra Hard evidence

Frozen invariants:

~~~text
no evidence != 0% mastery
coverage cannot exceed 100%
high evidence confidence cannot exist with zero breadth
Ultra Hard evidence cannot exist without the classification
retention cannot be scored without delayed evidence
~~~

## M7B closure gate

For every competency, CSP11 must be able to explain:

- what evidence exists
- how much evidence exists
- how broad it is
- how recent it is
- what kind of evidence it is
- how trustworthy the evidence is

No daily planning begins before this layer is stable.

---

# M7C - Multidimensional Readiness Profile

## Status

PLANNED AFTER M7B

## Objective

M7C turns evidence into interpretable readiness dimensions.

It must not pretend to predict examination outcome.

## M7C.1 Competency readiness model

Create CompetencyReadinessProfile.

Recommended fields:

~~~text
CompetencyReadinessProfile
- competencyId
- generatedAt
- readinessAlgorithmVersion
- knowledgeMastery
- applicationAbility
- retention
- difficultyPerformance
- blueprintCoverage
- confidenceCalibration
- recentPerformance
- stability
- evidenceConfidence
- readinessState
- limitingFactors
- explanationCodes
~~~

## M7C.2 Primary readiness dimensions

Initial learner-facing dimensions:

1. Knowledge Mastery
2. Application Ability
3. Retention
4. Blueprint Coverage
5. Difficulty Performance
6. Confidence Calibration

Evidence breadth and quantity support the evidence-confidence indicator.

## M7C.3 Readiness state

Create:

~~~text
ReadinessState
- unknown
- insufficientEvidence
- learning
- developing
- provisional
- strong
- stable
- atRisk
- stale
~~~

## M7C.4 Critical distinction

Example 1:

~~~text
D02 C06
Application: 42%
Evidence: HIGH
State: AT RISK
~~~

Example 2:

~~~text
D06 C05
Application: unavailable
Evidence: LOW
State: INSUFFICIENT EVIDENCE
~~~

These must produce different learner guidance and different planner behavior.

## M7C.5 Knowledge mastery

Initial deterministic calculation may consider:

- correctness
- unique-question diversity
- subtopic breadth
- recency
- repeat consistency

Do not introduce an opaque ML model in M7C.

## M7C.6 Application ability

Application ability should primarily use:

- Application questions
- Analysis questions
- scenario MCQs
- Ultra Hard DQG300 evidence
- breadth across subtopics

Ultra Hard is a stronger readiness signal but remains only one evidence source.

## M7C.7 Retention

Retention uses delayed retrieval evidence only.

If delayed evidence is unavailable:

~~~text
Retention
INSUFFICIENT EVIDENCE
~~~

not:

~~~text
Retention
0%
~~~

## M7C.8 Blueprint coverage

Coverage must be available at:

- Domain
- Competency
- Subtopic
- Topic

Potential learner display:

~~~text
Blueprint Coverage
83%

39/47 competencies assessed
176/218 subtopics assessed
~~~

Exact counts must come from the canonical blueprint/content architecture.

## M7C.9 Difficulty profile

Keep lanes visible:

~~~text
Standard       81%
Hard           70%
Ultra Hard     56%
~~~

Then derive an interpretable state such as:

~~~text
Difficulty readiness: DEVELOPING
~~~

## M7C.10 Confidence calibration

Potential internal measures:

- calibration error
- overconfidence frequency
- underconfidence frequency
- high-confidence incorrect rate

Learner display may use state language.

Example:

~~~text
Confidence calibration
NEEDS ATTENTION

You were highly confident on 7 recent incorrect answers.
~~~

## M7C.11 Readiness summary

Initial screen:

~~~text
EXAM READINESS PROFILE

Evidence confidence
MODERATE

Knowledge mastery      71%
Application ability    64%
Retention              78%
Blueprint coverage     83%
Difficulty readiness   61%
Confidence calibration GOOD
~~~

Numeric values must be hidden where evidence confidence is insufficient.

## M7C.12 ReadinessGap model

Create ReadinessGap.

Gap types:

~~~text
masteryGap
applicationGap
retentionGap
coverageGap
evidenceGap
difficultyGap
confidenceGap
stalenessGap
~~~

Severity:

~~~text
low
moderate
high
critical
~~~

## M7C.13 Limitation explanations

The system must be able to state:

~~~text
Your readiness estimate is currently limited because:

- D02 C06 has insufficient assessment evidence.
- D06 C05 has no recent Application-level evidence.
- D04 C03 has not been reviewed for 41 days.
~~~

These explanations must originate from structured reason codes.

## M7C.14 No composite Readiness Index yet

M7C must not introduce a single overall score such as:

~~~text
You are 72% exam ready.
~~~

M7C launches as a multidimensional Readiness Profile.

A composite index is deferred to M7F after component behavior has been validated.

## M7C.15 Readiness screen

Recommended hierarchy:

~~~text
EXAM READINESS

Evidence confidence
MODERATE
~~~

Then primary readiness dimensions.

Then:

~~~text
AREAS REQUIRING ATTENTION

Critical gaps        2
Weak competencies    6
Evidence gaps        5
Stale competencies   3
~~~

Then competency matrix/heatmap.

## M7C.16 Competency matrix

Example:

~~~text
D01 C01   STRONG
D01 C02   DEVELOPING
D01 C03   STALE

D02 C01   STRONG
D02 C02   LEARNING
D02 C06   INSUFFICIENT EVIDENCE
~~~

Tapping a competency opens its evidence and readiness explanation.

## M7C.17 M7C tests

Required scenarios:

- strong score + low evidence
- poor score + high evidence
- no retention evidence
- stale evidence
- strong Ultra Hard performance
- weak Ultra Hard performance
- high coverage + weak performance
- low coverage + strong performance
- confidence miscalibration
- critical gaps
- limitation explanations
- insufficient evidence hides inappropriate percentage
- stable state transitions

## M7C closure gate

M7C closes when the system can provide a trustworthy, explainable, multidimensional readiness profile without generating the adaptive daily plan.

---

# M7D - Adaptive Daily Planner

## Status

PLANNED AFTER M7C

## Objective

M7D answers:

> Given the learner's remaining time and current evidence, what is the best use of today's available study minutes?

## M7D.1 DailyStudyPlan model

Create DailyStudyPlan.

Recommended fields:

~~~text
DailyStudyPlan
- planId
- userId
- date
- generatedAt
- planVersion
- plannerAlgorithmVersion
- availableMinutes
- allocatedMinutes
- generationReason
- sourceEvidenceVersion
- sourceReadinessVersion
- blocks[]
- status
~~~

## M7D.2 StudyPlanBlock model

Create StudyPlanBlock.

Recommended fields:

~~~text
blockId
type
domainId
competencyId
subtopicId
topicId
plannedMinutes
questionCount
priorityScore
priorityBreakdown
reasonCodes
reasonText
status
createdAt
startedAt
completedAt
~~~

## M7D.3 Block types

Freeze the supported planning vocabulary:

~~~text
learn
continueLearning
repair
diagnostic
spacedReview
standardPractice
ultraHardPractice
mixedRetrieval
competencyRecheck
confidenceCalibration
examSimulation
recovery
~~~

## M7D.4 Priority engine

Create LearningPriorityEngine.

Output LearningPriorityScore.

Potential components:

- blueprint importance
- mastery gap
- application gap
- retention risk
- coverage gap
- evidence debt
- staleness
- difficulty weakness
- exam proximity
- prerequisite/dependency importance
- recent-study penalty

## M7D.5 Priority transparency

Never store only a final score.

Store component values.

Example:

~~~text
masteryGap      0.72
retentionRisk   0.44
coverageGap     0.68
evidenceDebt    0.95
examUrgency     0.61
recentPenalty   0.20
~~~

This enables deterministic explanation.

## M7D.6 Evidence debt

Create:

~~~text
EvidenceDebtLevel
- none
- low
- moderate
- high
- critical
~~~

Evidence debt may arise from:

- no assessment evidence
- inadequate subtopic breadth
- no Application evidence
- no delayed retention evidence
- stale evidence
- no Hard evidence
- no Ultra Hard evidence where required for readiness validation

Evidence debt means unknown, not necessarily weak.

## M7D.7 Planner allocation

Given 60 minutes available, a plan may allocate:

~~~text
25 min   Learn
15 min   Repair
10 min   Spaced Review
10 min   Adaptive Questions
~~~

Planner constraints must be centralized and testable.

Potential initial constraints:

~~~text
Learn block minimum          15 min
Learn block maximum          30 min
Review block                  5-15 min
Practice block                5-20 min
Maximum competencies/day      3
~~~

## M7D.8 Daily balance

Avoid assigning the entire day to one weak competency unless a critical reason exists.

Initial target categories may be:

~~~text
40% forward learning
25% repair
20% retention
15% assessment
~~~

These are configurable starting assumptions, not immutable pedagogical truth.

M7F later adapts them by exam phase.

## M7D.9 Diagnostic versus repair

If D06 C05 has LOW evidence confidence, the planner must schedule DIAGNOSTIC rather than automatically assuming REPAIR.

This is a critical safety rule.

## M7D.10 Machine-readable reason codes

Every block must contain at least one reason.

Examples:

~~~text
HIGH_BLUEPRINT_PRIORITY
APPLICATION_GAP
RETENTION_DUE
EVIDENCE_DEBT
ULTRA_HARD_GAP
STALE_EVIDENCE
COVERAGE_GAP
EXAM_PROXIMITY
CONFIDENCE_MISALIGNMENT
~~~

## M7D.11 Learner explanation

The Learning Twin may translate reason codes into:

> Scheduled because this competency has high blueprint importance, weak application evidence and has not been reviewed for 18 days.

## M7D.12 Today's Plan UI

Example:

~~~text
TODAY
60 MIN

25 MIN
LEARN
D03 C02 Risk Management Strategies

15 MIN
REPAIR
Hierarchy of Controls

10 MIN
SPACED REVIEW
Process Safety

10 MIN
ULTRA HARD
5 Exam Readiness Questions
~~~

## M7D.13 Why This Plan

Add WHY THIS PLAN?

Example explanation:

~~~text
1. D03 C02 has high blueprint priority.
2. Your application evidence is weaker than your knowledge evidence.
3. Process Safety is due for retention review.
4. Recent Ultra Hard evidence remains limited.
~~~

## M7D.14 Learner controls

Permitted actions:

- Start
- Skip
- Move to tomorrow
- Replace
- Shorten
- Mark unavailable

All manual modifications must be recorded.

## M7D.15 Plan locking

Once a block starts, it must not be silently replaced by regeneration.

Only unstarted future blocks may be recalculated.

## M7D.16 Ultra Hard scheduling

Ultra Hard blocks may be generated only when:

- Ultra Hard questions exist
- they are published
- they carry the DQG300 Ultra Hard classification
- the learner context justifies Ultra Hard evidence or readiness stress testing

Ordinary Hard questions must not silently substitute for an Ultra Hard block.

## M7D.17 M7D tests

Required scenarios:

- 30-minute day
- 60-minute day
- 120-minute day
- no known weak competency
- many weak competencies
- high evidence debt
- retention-heavy learner
- new learner
- exam tomorrow
- exam 90 days away
- Ultra Hard unavailable
- Ultra Hard available
- manual skipped block
- partial completion
- plan regeneration while one block is active

Frozen invariants:

~~~text
allocatedMinutes <= availableMinutes
no duplicate block IDs
every block has reasonCodes
no repair task for unknown evidence
no Ultra Hard block without Ultra Hard bank
no started block silently replaced
~~~

## M7D closure gate

M7D closes when CSP11 can deterministically generate a daily plan from:

- exam capacity
- evidence snapshots
- readiness profile
- planner configuration

and explain why each block exists.

---

# M7E - Closed Feedback Loop and Dynamic Replanning

## Status

PLANNED AFTER M7D

## Objective

M7E makes the plan genuinely adaptive.

Tomorrow must be able to change because of what happened today.

## M7E.1 Outcome model

Create StudyPlanBlockOutcome.

Recommended fields:

~~~text
blockId
completedAt
minutesSpent
questionsAttempted
questionsCorrect
applicationAccuracy
analysisAccuracy
ultraHardAccuracy
confidenceSamples
contentCompleted
learnerRating
abandoned
~~~

## M7E.2 Event-driven update flow

Frozen flow:

~~~text
block completion
      |
      v
progress update
      |
      v
question/evidence update
      |
      v
competency snapshot update
      |
      v
readiness recalculation
      |
      v
priority recalculation
      |
      v
future plan adjustment
~~~

Heavy recalculation must not block the learner-facing UI unnecessarily.

## M7E.3 Update coordinator

Create LearningStateUpdateCoordinator.

Responsibilities:

- identify affected competency
- update evidence snapshot
- update readiness profile
- update Domain summary where required
- mark future plan stale where appropriate
- request replanning at controlled checkpoints

Do not recalculate all 47 competencies after every answer unless an explicit full rebuild is required.

## M7E.4 Plan regeneration reasons

Create PlanRegenerationReason.

Recommended values:

~~~text
dailyRollover
assessmentCompleted
majorPerformanceShift
examDateChanged
studyScheduleChanged
criticalGapDetected
manualRequest
missedStudyDay
capacityChanged
~~~

## M7E.5 Plan staleness

Future plan can become STALE without immediate regeneration after every event.

Regenerate at controlled points such as:

- end of the day's final planned task
- next application start on a new day
- explicit learner refresh
- critical-gap event
- exam-date or capacity change

## M7E.6 Weak application response

Example:

~~~text
D03 C02
Knowledge       5/5
Application     2/4
Ultra Hard      1/3
~~~

Tomorrow should not necessarily repeat foundational content.

Potential response:

~~~text
REPAIR
D03 C02 application reasoning
15 min

ULTRA HARD
3 scenario questions
~~~

## M7E.7 Strong performance response

If Knowledge, Application and Retention are strong and Evidence is high, priority should decrease and the next review may be deferred.

## M7E.8 Misconception signal

Create MisconceptionSignal.

Potential inputs:

- repeated wrong tags
- repeated distractor family
- repeated concept failure
- high-confidence incorrect pattern

This may generate targeted repair rather than generic drilling.

## M7E.9 Confidence response

Repeated incorrect + high confidence must be treated differently from incorrect + low confidence.

Potential Twin explanation:

> You appear confident in this concept, but recent assessment evidence disagrees. I added a short concept-repair block before the next question set.

## M7E.10 Missed-study-day handling

A missed study day must trigger capacity recalculation.

The planner must not blindly push all missed blocks one day later.

It may:

- reprioritize
- defer low-value work
- reduce lower-priority repetition
- preserve critical gaps
- surface capacity pressure

## M7E.11 Exam-date change

Changing the exam date must recalculate:

- remaining capacity
- exam phase
- plan pressure
- review cadence
- future plan

Historical evidence and previous plans must remain preserved.

## M7E.12 Weekly review

Generate a weekly summary such as:

~~~text
THIS WEEK

Planned       300 min
Completed     265 min

Knowledge     +4 points
Application   +7 points
Retention     stable

Competencies improved    5
New evidence gaps        1
Critical gaps remaining  2
~~~

Then generate next-week focus from structured reasons.

## M7E.13 Plan versioning

Every regenerated plan stores:

~~~text
planVersion
previousPlanId
generationReason
inputSnapshotVersion
plannerAlgorithmVersion
generatedAt
~~~

## M7E.14 Audit trail

A debug/admin view must eventually answer:

~~~text
Why did CSP11 schedule D06 C05?
~~~

Example:

~~~text
Priority              0.82
Evidence debt         HIGH
Application evidence  NONE
Blueprint importance  HIGH
Days to exam          28
~~~

## M7E.15 M7E tests

Required sequence tests:

### Sequence A

~~~text
Day 1 diagnostic poor
-> evidence update
-> tomorrow contains repair
~~~

### Sequence B

~~~text
Day 1 excellent
-> priority decreases
-> tomorrow does not repeat unnecessarily
~~~

### Sequence C

~~~text
missed study day
-> capacity decreases
-> plan remains within remaining capacity
~~~

### Sequence D

~~~text
poor Ultra Hard
-> application/difficulty readiness changes
-> targeted Ultra Hard recheck may be scheduled
~~~

### Sequence E

~~~text
high-confidence incorrect pattern
-> misconception/calibration signal
-> repair/calibration task scheduled
~~~

## M7E closure gate

M7E must demonstrate in automated tests:

~~~text
same learner baseline
+ new evidence
=
different justified next-day plan
~~~

This is the defining adaptive milestone.

---

# M7F - Advanced Readiness Intelligence

## Status

PLANNED AFTER M7E

## Objective

M7F combines capacity, readiness, trajectory, evidence quality and exam proximity into advanced exam-preparation intelligence.

M7F must be built only after M7A-M7E behavior is stable and measurable.

## M7F.1 Exam preparation phases

Create ExamPreparationPhase:

~~~text
foundation
integration
readiness
consolidation
~~~

Initial date-based guidance may begin as:

~~~text
more than 60 days   FOUNDATION
31-60 days          INTEGRATION
15-30 days          READINESS
14 days or less     CONSOLIDATION
~~~

These bands are initial configuration, not permanent truth.

Later they may incorporate capacity and coverage.

## M7F.2 Phase-specific allocation

### Foundation

Emphasize:

- blueprint coverage
- concept learning
- introductory application

Possible initial allocation:

~~~text
55% learning
20% practice
15% review
10% diagnostics
~~~

### Integration

Emphasize:

- application
- cross-topic reasoning
- repair
- mixed practice

### Readiness

Emphasize:

- Ultra Hard
- mixed retrieval
- competency recheck
- weak-area closure
- readiness checkpoints

### Consolidation

Emphasize:

- retention
- critical gaps
- targeted review
- exam simulation
- reduced unnecessary novelty

## M7F.3 Capacity Pressure

Create CapacityPressureSnapshot.

Potential inputs:

- remaining study hours
- number/severity of high-priority gaps
- blueprint coverage gap
- exam phase
- historical learning velocity
- scheduled review debt

Output state:

~~~text
LOW
MANAGEABLE
ELEVATED
HIGH
CRITICAL
~~~

The learner must not be shown false precision.

Prefer:

~~~text
Estimated priority workload:
72-88 hours

Available planned capacity:
63 hours
~~~

over an unsupported exact requirement.

## M7F.4 Learning velocity

Track learner-specific history where possible:

~~~text
competencies stabilized/week
subtopics covered/week
minutes per stabilized competency
minutes per retained competency
~~~

This may improve capacity estimates.

## M7F.5 Readiness trajectory

Create ReadinessTrajectoryPoint.

Recommended fields:

~~~text
date
knowledge
application
retention
coverage
difficulty
evidenceConfidence
algorithmVersion
~~~

## M7F.6 Trend interpretation

Avoid noisy day-to-day movement.

Use meaningful windows.

Example:

~~~text
Application
+8 points over 21 days

Retention
stable

Coverage
+14 points

Ultra Hard
no meaningful change
~~~

## M7F.7 Safe projection

The system may project measurable process variables.

Example:

~~~text
At current study pace:
Estimated blueprint coverage by exam date: 92%
~~~

This predicts coverage, not pass/fail outcome.

## M7F.8 Competency dependencies

Create CompetencyDependency.

Recommended fields:

~~~text
prerequisiteCompetencyId
dependentCompetencyId
strength
rationale
source
version
~~~

Early dependency maps should be curated.

Do not infer causal prerequisite relationships from tiny learner datasets.

## M7F.9 Root-gap reasoning

If several weak competencies share a prerequisite, the system may prioritize the root concept instead of repeatedly drilling symptoms.

Example:

~~~text
D03 C02
  |
  +--> D03 C05
  +--> D03 C06
~~~

Any root-gap explanation must remain grounded in an explicit dependency map and observed evidence.

## M7F.10 Advanced retention urgency

Potential future deterministic model:

~~~text
Review urgency =
time since successful retrieval
x historical forgetting tendency
x competency importance
x evidence confidence modifier
~~~

The initial implementation must remain inspectable and testable.

## M7F.11 Composite CSP11 Readiness Index

Only M7F may introduce an overall index.

Name:

~~~text
CSP11 Readiness Index
~~~

It must never be described as pass probability.

Example:

~~~text
READINESS INDEX
72 / 100

Evidence confidence
MODERATE
~~~

## M7F.12 Experimental component weights

Initial experimental configuration may use:

| Dimension | Initial weight |
| --- | ---: |
| Knowledge Mastery | 20% |
| Application Ability | 20% |
| Retention | 15% |
| Blueprint Coverage | 15% |
| Difficulty Performance | 10% |
| Competency Breadth | 10% |
| Recent Performance | 5% |
| Confidence Calibration | 5% |

These values must live in a versioned ReadinessWeightConfiguration.

They must not be scattered as hardcoded constants throughout the codebase.

## M7F.13 Evidence confidence remains separate

Always preserve score and evidence confidence as separate concepts.

## M7F.14 Readiness Index availability gate

The composite index must be withheld until minimum evidence conditions are met.

Candidate initial conditions:

- minimum competency coverage
- minimum total assessment evidence
- minimum Application evidence
- minimum delayed retention evidence
- no unresolved critical evidence blind spots above configured threshold

Before the gate is met:

~~~text
READINESS INDEX

Not yet available

More evidence is required before CSP11 can produce a trustworthy composite readiness estimate.
~~~

## M7F.15 Readiness checkpoints

Schedule checkpoints at meaningful milestones.

Possible initial milestones:

~~~text
90 days
60 days
30 days
14 days
7 days
~~~

Checkpoint composition may include:

- mixed blueprint sample
- Hard questions
- Ultra Hard questions
- confidence prompts
- delayed-retrieval items

## M7F.16 Exam Simulator integration

During an active timed simulation:

~~~text
Learning Twin = suppressed
M7 guidance = suppressed
hints = suppressed
readiness prompts = suppressed
~~~

After submission, aggregate simulation outcomes may update evidence under an explicitly validated integration path.

## M7F.17 Critical readiness warning

Example:

~~~text
CRITICAL GAP

D06 C05

Application evidence: LOW
Retention evidence: NONE
Last assessment: 43 days ago
Blueprint importance: HIGH
~~~

## M7F.18 Capacity intervention

If plan demand exceeds realistic capacity:

~~~text
CAPACITY PRESSURE: HIGH

Available time:
23 hours

Estimated priority workload:
31-38 hours
~~~

Offer choices:

- increase weekly minutes
- add an additional study day
- reduce low-priority review
- prioritize critical competencies

The learner decides.

The planner must not silently increase the learner's declared workload.

## M7F.19 Recovery protection

An adaptive planner must not become punitive.

If the learner repeatedly misses targets, allow:

~~~text
recoveryDay
reducedIntensityDay
~~~

The system should reprioritize rather than continuously accumulate an impossible backlog.

## M7F.20 Validation before index freeze

Before freezing the composite Readiness Index, evaluate:

- stability over time
- sensitivity to new evidence
- susceptibility to one competency dominating the score
- influence of Ultra Hard evidence
- handling of missing evidence
- short-term score inflation
- retention sensitivity
- breadth sensitivity
- recalibration after stale evidence
- effect of repeated questions

## M7F closure gate

M7F closes only when CSP11 can truthfully produce an output similar to:

~~~text
27 days until exam

Available study capacity:
23.5 hours

Evidence confidence:
HIGH

Strong competencies:
31

Developing:
8

Critical gaps:
2

Insufficient evidence:
3

Today's plan:
60 minutes

The plan changed because yesterday's Ultra Hard performance improved D03 C02,
while D06 C05 still lacks sufficient Application-level evidence.
~~~

Every statement must be traceable to current evidence or declared learner capacity.

---

# Shared M7 data architecture

Recommended package:

~~~text
lib/features/exam_readiness/
|
+-- models/
|   +-- exam_study_plan.dart
|   +-- study_schedule_exception.dart
|   +-- study_capacity_snapshot.dart
|   +-- competency_evidence_snapshot.dart
|   +-- evidence_confidence.dart
|   +-- competency_readiness_profile.dart
|   +-- readiness_gap.dart
|   +-- daily_study_plan.dart
|   +-- study_plan_block.dart
|   +-- learning_priority_score.dart
|   +-- study_plan_block_outcome.dart
|   +-- readiness_trajectory_point.dart
|   +-- capacity_pressure_snapshot.dart
|   +-- competency_dependency.dart
|   +-- readiness_weight_configuration.dart
|
+-- repositories/
|   +-- exam_study_plan_repository.dart
|   +-- evidence_snapshot_repository.dart
|   +-- readiness_snapshot_repository.dart
|   +-- daily_plan_repository.dart
|   +-- readiness_history_repository.dart
|
+-- services/
|   +-- exam_study_capacity_service.dart
|   +-- learner_evidence_aggregation_service.dart
|   +-- evidence_confidence_service.dart
|   +-- retention_evidence_service.dart
|   +-- readiness_profile_service.dart
|   +-- readiness_gap_service.dart
|   +-- learning_priority_engine.dart
|   +-- adaptive_daily_plan_service.dart
|   +-- learning_state_update_coordinator.dart
|   +-- readiness_trajectory_service.dart
|   +-- capacity_pressure_service.dart
|   +-- readiness_index_service.dart
|
+-- screens/
    +-- exam_plan_setup_screen.dart
    +-- exam_readiness_plan_screen.dart
    +-- readiness_profile_screen.dart
    +-- competency_readiness_screen.dart
    +-- todays_plan_screen.dart
    +-- readiness_trajectory_screen.dart
~~~

This is a target structure.

Exact file boundaries may be refined during implementation if a cleaner architecture is demonstrated, but the separation of capacity, evidence, readiness and planning responsibilities is frozen.

---

# Shared Firestore direction

Recommended user-scoped collections:

~~~text
users/{uid}/examPlans/{planId}
users/{uid}/evidenceSnapshots/{competencyId}
users/{uid}/readinessSnapshots/{competencyId}
users/{uid}/dailyPlans/{yyyy-mm-dd}
users/{uid}/planOutcomes/{outcomeId}
users/{uid}/readinessHistory/{snapshotId}
users/{uid}/readinessSummary/current
~~~

Do not place the entire M7 state in one giant user document.

Security rules must remain least-privilege and user-scoped.

Deployment of Firebase rules remains an explicit operational action and must not be assumed from a repository commit alone.

---

# Versioning requirements

Every durable M7 derived object should carry relevant version metadata.

Examples:

~~~text
schemaVersion
evidenceAlgorithmVersion
readinessAlgorithmVersion
plannerAlgorithmVersion
generatedAt
sourceSnapshotVersion
~~~

Versioning is mandatory because readiness algorithms will evolve.

---

# Shared UI direction

M7 screens should inherit the premium learner visual system already being developed in CSP11.

Preferred design language:

- responsive glassmorphism where appropriate
- restrained gradients
- strong visual hierarchy
- light/dark parity
- accessible contrast
- clear evidence-confidence labels
- no pseudo-scientific gauges
- no decorative precision unsupported by evidence
- mobile-first cards
- readable explanation panels
- clear distinction between score and confidence

The Learning Twin should explain decisions but must not dominate the screen.

---

# Home integration target

A future Home card may show:

~~~text
27 days until CSP exam

TODAY
60 min planned
4 learning blocks

READINESS
Evidence: HIGH
2 critical gaps

[Continue today's plan]
~~~

The exact final Home integration belongs to the relevant M7 implementation slice and must not precede reliable evidence/readiness services.

---

# Ultra Hard / DQG300 relationship

The Ultra Hard DQG300 lane is strategically important to M7 but is not the entire readiness model.

DQG300 evidence may strongly inform:

- Application Ability
- Difficulty Performance
- Exam Readiness stress testing
- readiness checkpoints
- targeted rechecks

However:

- standard questions remain useful
- Hard questions remain useful
- retention evidence remains independent
- coverage evidence remains independent
- evidence quantity and breadth remain independent

A learner cannot become ready only by performing well on a small Ultra Hard sample.

---

# Legacy question-bank relationship

The existing standard bulk uploader remains the standard H0.3 path.

M7 must not require old standard questions to pass DQG300 retroactively.

The learner readiness system may classify attempts by source/difficulty but must preserve compatibility with both question-quality lanes.

---

# Performance requirements

M7 must avoid repeated high-cost reads.

Preferred pattern:

~~~text
attempt created
    ->
incremental snapshot update
    ->
cached readiness snapshot
    ->
learner screen
~~~

Avoid:

~~~text
screen rebuild
    ->
download full history
    ->
recalculate all competencies
~~~

Full rebuild tooling remains available for migration/debugging.

---

# Offline and cache direction

CSP11 remains internet-oriented.

M7 may use limited local cache for:

- active exam plan
- latest capacity snapshot
- latest readiness summary
- today's plan
- recent evidence snapshots

The cache must not become a separate conflicting source of truth.

---

# Algorithm configuration

Configurable weights and thresholds must live in centralized, versioned configuration objects.

Do not scatter values such as 60 days, 30 attempts, confidence thresholds or readiness weights through multiple widgets and services.

Possible configuration objects:

~~~text
EvidenceThresholdConfiguration
ReadinessWeightConfiguration
PlannerAllocationConfiguration
RetentionWindowConfiguration
CapacityPressureConfiguration
~~~

---

# Explainability contract

Any learner-facing statement of the form:

~~~text
You should study X
X is weak
X is at risk
Your retention is low
Your readiness estimate is limited
~~~

must be traceable to:

- evidence snapshot
- rule/threshold
- priority component
- reason code
- algorithm version

The Learning Twin must translate structured reasons, not invent causes.

---

# Readiness terminology contract

Permitted language:

- evidence suggests
- current evidence indicates
- insufficient evidence
- developing
- strong
- stale
- at risk
- current readiness profile
- readiness estimate
- blueprint coverage
- application performance
- retention evidence

Avoid unsupported language such as:

- guaranteed to pass
- pass probability
- definitely ready
- definitely not ready

---

# Testing strategy across M7

Every phase must include:

## Unit tests

For pure calculation and deterministic services.

## Repository tests

For serialization, cache, migration and persistence boundaries.

## Widget tests

For light/dark parity, Android-sized layouts and learner flows.

## Integration tests

For cross-service flows.

## Regression tests

To protect existing Practice, Quiz, Learning Twin and progress features.

## Failure-path tests

Especially:

- missing data
- malformed data
- stale snapshot
- no Ultra Hard bank
- no exam date
- insufficient evidence
- partial sync
- past exam date
- interrupted plan update

## Architecture tests

Protect:

- timed Exam Simulator suppression
- no question/answer leakage into inappropriate Twin decision paths
- H0.3 and DQG300 separation
- no readiness service embedded inside UI widgets
- no uncontrolled Firestore aggregation from screen build methods

---

# M7 closure strategy

Each phase follows:

~~~text
IMPLEMENT
    ->
TARGETED TESTS
    ->
ANALYZE
    ->
FULL REGRESSION
    ->
VISUAL REVIEW
    ->
DIFF AUDIT
    ->
CLOSURE DOCUMENT
    ->
CLOSURE CHECKPOINT
~~~

Do not mark a phase CLOSED because code merely compiles.

---

# Phase-by-phase minimum deliverables

## M7A

Must deliver:

- ExamStudyPlan
- capacity service
- persistence/cache
- setup flow
- initial Exam Readiness Plan screen
- capacity tests

## M7B

Must deliver:

- evidence taxonomy
- CompetencyEvidenceSnapshot
- evidence confidence
- retention evidence
- Ultra Hard lane
- incremental aggregation
- evidence tests

## M7C

Must deliver:

- multidimensional readiness profile
- ReadinessState
- ReadinessGap
- limitation explanations
- competency readiness UI
- no composite index yet

## M7D

Must deliver:

- priority engine
- evidence debt
- daily planner
- StudyPlanBlock
- reason codes
- Today's Plan UI
- Why This Plan explanation

## M7E

Must deliver:

- StudyPlanBlockOutcome
- incremental state-update coordinator
- future-plan invalidation
- dynamic replanning
- weekly review
- plan versioning
- audit trail

## M7F

Must deliver:

- exam phases
- phase-aware planning
- capacity pressure
- trajectory
- dependency graph
- root-gap reasoning
- readiness checkpoints
- validated composite index gate
- final M7 quality validation

---

# Explicitly deferred / out of scope until justified

M7 does not automatically approve:

- LLM-generated readiness scoring
- opaque ML models
- pass-probability prediction
- automatic mental-state inference
- voice coaching
- microphone access
- hidden workload increases
- dynamic rewriting of authoritative learning content
- weakening the DQG300 contract
- retroactively requiring H0.3 questions to pass DQG300
- coaching during timed Exam Simulator sessions

Any such capability requires a separate explicit decision.

---

# Frozen implementation sequence

~~~text
M7A
Exam Plan + Study Capacity
        |
        v
FREEZE / CLOSE M7A

M7B
Evidence Engine
        |
        v
FREEZE / CLOSE M7B

M7C
Readiness Profile
        |
        v
FREEZE / CLOSE M7C

M7D
Priority + Daily Planner
        |
        v
FREEZE / CLOSE M7D

M7E
Adaptive Feedback Loop
        |
        v
FREEZE / CLOSE M7E

M7F
Advanced Readiness Intelligence
        |
        v
FREEZE / CLOSE M7F

PHASE M7
FINAL CLOSURE
~~~

No phase should be skipped merely to reach the final Readiness Index faster.

---

# Final product target

When M7 is complete, CSP11 should be able to truthfully say something similar to:

~~~text
EXAM
15 December 2026

27 days remaining

STUDY CAPACITY
23.5 hours available

EVIDENCE CONFIDENCE
HIGH

KNOWLEDGE
71%

APPLICATION
64%

RETENTION
78%

BLUEPRINT COVERAGE
83%

STRONG COMPETENCIES
31

DEVELOPING
8

CRITICAL GAPS
2

INSUFFICIENT EVIDENCE
3

TODAY
60 minutes

25 min
Learn
D03 C02 Risk Management Strategies

15 min
Repair
Hierarchy of Controls

10 min
Spaced Review
Process Safety

10 min
Ultra Hard
5 Exam Readiness questions
~~~

The Learning Twin should then be able to explain:

> Today's plan changed because yesterday's Ultra Hard performance improved D03 C02, while D06 C05 still lacks sufficient Application-level evidence.

That explanation must be grounded in auditable M7 evidence.

---

# Final frozen principle

The defining M7 quality standard is:

> CSP11 must never manufacture certainty. It must distinguish strong evidence, weak evidence, missing evidence and actual performance, then use those distinctions to build an explainable study plan that adapts as the learner produces new evidence.

This document is the frozen implementation direction for M7A-M7F.
