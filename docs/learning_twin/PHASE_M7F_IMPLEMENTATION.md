# CSP11 Phase M7F - Advanced Readiness Intelligence

## Status

CLOSED / PASS

## Frozen parent

- M7E CLOSED / PASS
- revised learner-integrated M7E checkpoint:
  `9f6c00268f719db8bc6921861d99aced525e5a0d`
- M7E validation run: `35338819708`
- M7E validation job: `105579795785`

## Authoritative M7F runtime checkpoint

`3800f45697d044fc952252f046506ed07e1052cc`

Validation workflow:

- workflow: `M7F Advanced Readiness`
- run: `35341126127`
- job: `105587029002`
- Flutter: stable 3.44.9

## Implemented M7F scope

M7F now includes deterministic and inspectable support for:

- exam preparation phases:
  - Foundation
  - Integration
  - Readiness
  - Consolidation
- versioned phase allocation profiles
- a phase-aware daily-plan wrapper layered on the frozen M7D planner
- locked-block preservation during phase-aware replanning
- capacity pressure expressed as a workload range and categorical state
- readiness trajectory points with a minimum meaningful window
- UID-scoped local daily trajectory history
- safe projection of blueprint coverage only
- curated competency dependency primitives
- root-gap reasoning only from explicit dependency maps and observed evidence
- a versioned Readiness Index weight configuration
- a fail-closed Readiness Index evidence gate
- evidence confidence kept separate from the composite index
- 90 / 60 / 30 / 14 / 7 day readiness checkpoints
- Hard / Ultra Hard / confidence / delayed-retrieval checkpoint composition
- recovery and reduced-intensity recommendations after repeated missed study days
- explicit no-backlog-dumping protection
- timed Exam Simulator suppression policy for Twin guidance, hints and
  readiness prompts
- post-submission-only evidence permission for timed simulations
- a learner-facing Advanced Readiness screen
- light and dark theme compatibility through the existing theme contract
- current exam phase and days remaining
- capacity-pressure range and learner-controlled intervention choices
- strong / developing / critical / insufficient-evidence counts
- trajectory and safe blueprint-coverage projection
- checkpoint visibility
- optional recovery guidance
- auditable "why today's plan looks this way" explanation
- Readiness Index display only when its evidence gate is satisfied

## Phase-aware planner safety

M7F does not replace or rewrite the frozen M7D planner.

`PhaseAwareDailyPlanService` wraps `DailyStudyPlanService`, then adapts only
unstarted blocks according to exam phase. Started and completed blocks remain
historically locked.

The phase layer adds explicit machine-readable reason codes such as:

```text
EXAM_PHASE_FOUNDATION
EXAM_PHASE_INTEGRATION
EXAM_PHASE_READINESS
EXAM_PHASE_CONSOLIDATION
PHASE_ALLOCATION_...
```

## Readiness Index safety

The CSP11 Readiness Index remains unavailable when its versioned evidence gate
is not satisfied.

The learner-facing UI displays:

```text
Not yet available
```

rather than converting missing evidence into zero.

When available, the index remains a study-readiness construct. It is not an
exam outcome prediction. Evidence confidence remains separately visible.

## Projection boundary

M7F may project a process variable such as blueprint coverage when at least a
meaningful trajectory window exists.

It does not project:

- CSP pass probability
- expected exam score
- guaranteed exam outcome

The projection is explicitly tagged:

```text
PROCESS_VARIABLE_NOT_EXAM_OUTCOME
```

## Dependency safety

M7F does not infer prerequisite relationships from learner mistakes.

Root-gap reasoning remains empty unless a dependency is explicitly supplied
with:

- canonical prerequisite competency
- canonical dependent competency
- rationale
- source
- version
- strength

This preserves a fail-closed causal model.

## Capacity and recovery safety

Capacity pressure compares available study capacity against an estimated
priority-work range.

CSP11 may surface options such as:

- add a study day
- increase declared minutes
- reduce low-priority review
- prioritize critical competencies

It never silently increases the learner's declared workload.

Repeated missed study days may produce a reduced-intensity or recovery-day
recommendation. Suggested minutes never exceed declared minutes and missed
work is not blindly accumulated into an impossible backlog.

## Closure evidence

Final M7F validation passed:

- frozen M7 contract through M7F: PASS
- canonical Dart formatting: PASS
- Flutter analyzer: PASS
- M7F targeted suite: 149 / 149 PASS
- M7A regression suite: 93 PASS
- M7B regression suite: 159 PASS
- M7C regression suite: 154 PASS
- M7D regression suite: 149 PASS
- M7E regression suite: 60 PASS
- complete Flutter regression suite: 1283 / 1283 PASS
- production web release build: PASS
- zero skipped M7F tests in the required gate
- frozen M7C architecture and UI compatibility: PASS

## Closure statement

M7F is CLOSED / PASS.

The tested runtime checkpoint is
`3800f45697d044fc952252f046506ed07e1052cc`.

Any later change to M7F behavior must be treated as an explicit reviewed
regression fix and must rerun the M7F validation workflow.
