# CSP11 Phase M7F - Advanced Readiness Intelligence

## Status

CORE IMPLEMENTATION IN PROGRESS

## Frozen parent

- M7E CLOSED / PASS
- M7E tested runtime checkpoint: `298e793dec6a128b698635382c728dd7b687524c`
- M7E closure branch: `phase-m7e-closed`
- M7E validation run: `35336913234`
- M7E validation job: `105573746939`

## Scope of the first M7F slice

The first implementation slice adds deterministic, inspectable primitives for:

- exam preparation phases
- phase allocation profiles
- capacity pressure as a range and categorical state
- readiness trajectory points and windowed trends
- curated competency dependencies
- root-gap reasoning from explicit dependencies plus observed evidence
- versioned Readiness Index weights
- an evidence-gated CSP11 Readiness Index

## Safety boundaries

M7F preserves every frozen M7A-M7E rule.

In particular:

- missing evidence is not failure
- readiness is not pass probability
- evidence confidence remains separate from any composite index
- the index is withheld when evidence is insufficient
- capacity pressure never silently increases declared learner workload
- dependency relationships are curated inputs, not inferred from small learner datasets
- active timed Exam Simulator sessions remain intervention-free
- M7F services remain deterministic and explainable
- M7F does not modify the frozen DQG300 or legacy H0.3 publication contracts

## Implementation order

1. deterministic model and service primitives
2. focused unit tests
3. phase-aware planning integration
4. readiness checkpoints
5. learner-facing trajectory/capacity-pressure UI
6. Readiness Index gate validation and sensitivity checks
7. full M7F closure validation

M7F is not CLOSED until the final validation document records a passing
workflow, full regression suite and production build.
