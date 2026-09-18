# CSP11 Phase M7A - Exam Plan Foundation and Capacity Engine

## Status

IMPLEMENTED / VALIDATION PENDING

## Frozen parent contract

- PHASE_M7_EXAM_READINESS_FROZEN_IMPLEMENTATION_PLAN.md
- PHASE_M7_PRE_IMPLEMENTATION_CONTRACT.md
- pinned M7 plan blob: b714a740b4590a48fe8efba216e8ec59a31bd9e6

## Scope implemented

M7A introduces only exam planning and realistic study-capacity calculation.

It does not calculate knowledge mastery, application ability, retention,
readiness, pass probability, weakness, or adaptive priorities.

## Runtime implementation

Models:
- ExamStudyPlan
- StudyScheduleException
- StudyCapacitySnapshot
- ExamTimeHorizon

Service:
- ExamStudyCapacityService

Persistence:
- UID-scoped SharedPreferences cache
- optional Firebase user-subcollection synchronization
- explicit remote refresh
- local-first normal load
- active-plan version history

Firestore:
- users/{uid}/examPlans/{planId}
- self/admin read boundary
- field allowlist
- immutable learner ownership fields
- global fail-closed fallback preserved

Learner UI:
- ExamPlanSetupScreen
- ExamReadinessPlanScreen
- light/dark ThemeData compatibility
- narrow Android layout coverage
- no readiness score in M7A

## Capacity semantics

The exam day itself is excluded from available study capacity.

Capacity is calculated from local calendar dates.

Schedule precedence:
1. unavailable/travel/leave/holiday removes the day
2. explicit override/extra-study-day minutes
3. intensive revision override or daily maximum
4. normal selected weekday schedule

Preferred rest days override normal selected study days.

## Validation gate

M7A may close only after:

- frozen M7 contract PASS
- 40+ explicit M7A tests
- zero skipped M7A tests
- formatter PASS
- Flutter analyzer PASS
- targeted M7A tests PASS
- complete Flutter regression PASS
- web build PASS
- Android debug build PASS
- git diff --check PASS

M7B implementation must not be committed before the M7A gate passes.
