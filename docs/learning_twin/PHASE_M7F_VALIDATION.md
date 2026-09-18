# CSP11 Phase M7F Validation

## Status

CLOSED / PASS

## Parent

M7E CLOSED / PASS at learner-integrated runtime checkpoint
`9f6c00268f719db8bc6921861d99aced525e5a0d`.

## Frozen runtime checkpoint

- branch: `phase-m7-exam-readiness`
- tested M7F runtime checkpoint:
  `3800f45697d044fc952252f046506ed07e1052cc`
- workflow: `M7F Advanced Readiness`
- workflow run: `35341126127`
- job: `105587029002`
- Flutter: stable 3.44.9

## Gate results

- frozen M7 contract through M7F: PASS
- diff and whitespace audit: PASS
- canonical Dart formatting: PASS
- Flutter analyzer: PASS
- M7F targeted suite: 149 / 149 PASS
- M7A regressions: 93 PASS
- M7B regressions: 159 PASS
- M7C regressions: 154 PASS
- M7D regressions: 149 PASS
- M7E regressions: 60 PASS
- complete Flutter regression suite: 1283 / 1283 PASS
- production web release build: PASS
- skipped M7F tests in required gate: 0

## Phase boundary validation

Automated tests prove the configured phase boundaries:

- Foundation: 61+ days
- Integration: 31-60 days
- Readiness: 15-30 days
- Consolidation: 14 days or fewer

Phase allocation values remain versioned and sum to 1.0.

## Phase-aware planning validation

The M7F phase-aware service is layered on top of the frozen M7D planner.

Validated behavior includes:

- phase reason codes on generated blocks
- allocation configuration traceability
- daily capacity never exceeded
- increased retrieval/review emphasis as the exam approaches
- Ultra Hard remains gated by published availability and readiness need
- started blocks remain byte-equivalent through phase-aware replanning
- phase/configuration lineage is written into the plan input snapshot

## Capacity-pressure validation

Capacity pressure exposes a range rather than a false single-number estimate.

The learner UI may surface intervention choices when demand exceeds capacity,
but no service silently changes the learner's declared study time.

## Readiness trajectory validation

The trajectory contract proves:

- short windows are not treated as meaningful trends
- a minimum meaningful window is required
- small deltas remain stable rather than noisy improvement/decline claims
- missing dimensions remain unavailable
- evidence confidence remains independently traceable
- local daily history is UID-scoped and upserts one point per date

## Safe projection validation

Coverage projection is withheld without meaningful history.

When available, it projects blueprint coverage only and carries:

```text
PROCESS_VARIABLE_NOT_EXAM_OUTCOME
```

No pass probability or expected exam score is produced.

## Readiness Index validation

The CSP11 Readiness Index:

- uses the versioned weight configuration
- remains unavailable when the evidence gate fails
- keeps `score == null` when unavailable
- never substitutes missing dimensions with numeric zero
- keeps evidence confidence separate
- becomes available only after coverage / attempt / application / retention /
  blind-spot / evidence-confidence gates are satisfied
- is described in learner UI as a study-readiness construct, not an exam
  outcome prediction

## Checkpoint validation

The checkpoint service validates milestones at:

- 90 days
- 60 days
- 30 days
- 14 days
- 7 days

Checkpoint composition remains phase-aware.

Ultra Hard is included only where the phase supports it and an eligible
published bank is available.

## Recovery validation

Automated tests prove:

- no recovery recommendation after normal history
- two consecutive missed study days can offer reduced intensity
- three or more can offer a recovery day
- a completed study day breaks the missed-day streak
- suggested minutes never exceed declared minutes
- reason codes explicitly include `NO_BACKLOG_DUMPING`

## Dependency validation

Root-gap reasoning requires explicit curated dependencies.

Missing dependent profiles, evidence-limited prerequisite gaps and absent
dependency maps do not create invented causal relationships.

## Timed Exam Simulator safety

The M7F suppression policy proves that an active timed simulation suppresses:

- Learning Twin interventions
- hints
- readiness prompts

Timed-simulation evidence cannot be committed before submission. Aggregate
post-submission evidence may be used only after submission.

The earlier Learning Twin decision-layer timed-exam suppression remains part
of the frozen M7 contract.

## M7C compatibility regression

During validation, the first Advanced Readiness integration shifted a frozen
M7C UI row and altered exact disclaimer strings. The regression gate caught
both issues.

The final checkpoint restores:

- the original M7C competency-row interaction position
- the exact `single exam-readiness percentage` disclaimer contract
- the exact `pass the exam` disclaimer contract

The M7F entry is placed after the frozen M7C competency matrix.

## Closure decision

All M7F implementation and validation gates are satisfied.

**M7F is CLOSED / PASS.**

Authoritative tested runtime checkpoint:

`3800f45697d044fc952252f046506ed07e1052cc`
