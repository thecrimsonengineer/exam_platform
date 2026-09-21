# Agentic PDCA M0 Observation-Only Control Plane

Status: IMPLEMENTATION SPIKE
Maturity: M0 Observation
Governance: v1.0
Frozen governance SHA: `43b2b3cc99839ae9de4092b4e2b7058d1964bff7`
Implementation branch: `agentic-pdca-m0-control-plane`

## Purpose

This M0 slice implements the Central Control Plane only at the maturity permitted by the frozen Governance v1.0 model:

```text
M0 Observation = DO-0 + CHECK-0 + ACT-0
```

It records and validates observed control state. It does not execute application work.

## Hard boundary

M0 cannot:

- dispatch a writing agent;
- mutate Git/repository state on behalf of a task;
- issue an active writer lease;
- route or authorize a repair;
- approve a waiver;
- compute or execute phase closure;
- judge code quality;
- modify application feature code.

The implementation exposes these forbidden capabilities through `ControlPlaneCapability` and returns `false` for every one.

## Implemented observation registries

The in-memory M0 model records:

- PLAN task snapshots;
- TASK state observations;
- lineage identity and candidate ordering;
- authoritative events;
- semantic and exact-ID event deduplication;
- repair-budget observations;
- expected and observed branch HEADs;
- writer-lease observations;
- cancellation observations;
- evidence references and content hashes;
- human approval observations;
- pinned governance version and governance SHA.

## Adversarial controls represented in M0

The observation layer implements or reports:

1. trusted issuer allow-listing;
2. governance-version pinning;
3. exact event-ID deduplication;
4. semantic CHECK-event deduplication using the Governance v1.0 key material;
5. lineage generation and candidate sequence ordering;
6. stale-event preservation as evidence without allowing stale state to replace current observed lineage;
7. canonical CHECK-state namespace validation;
8. expected-HEAD drift diagnostics;
9. expired approval diagnostics using a trusted Control Plane clock;
10. explicit observation-only capability denial.

## Evidence semantics

Every delivered authoritative event is retained in `eventEvidence`, including rejected or stale deliveries.

Only trusted, canonical, non-duplicate, current events enter `authoritativeEvents`.

This keeps forensic evidence without pretending rejected evidence became authoritative state.

## Files

```text
tool/agentic_pdca/m0_models.dart
tool/agentic_pdca/m0_control_plane.dart
test/agentic_pdca/m0_control_plane_test.dart
docs/agentic/implementation/M0_CONTROL_PLANE.md
```

No application feature file is part of the M0 implementation.

## M0 validation target

The focused test suite verifies:

- all protected capabilities remain disabled;
- observation-only metadata is exported;
- trusted CHECK events are observed;
- untrusted events are rejected and retained as evidence;
- governance drift is rejected;
- duplicate event IDs are idempotent;
- semantic duplicates are idempotent;
- stale events cannot replace newer lineage state;
- invalid CHECK state namespaces are rejected;
- unknown task/lineage events are rejected;
- expected HEAD drift is visible;
- expired approval is visible;
- budget, lease, cancellation and evidence observations are serializable.

## Deliberately deferred to later maturity

M0 does not implement:

- writer dispatch;
- active lease acquisition or fencing enforcement on Git writes;
- automatic CHECK execution;
- automatic ACT routing;
- repair-budget consumption;
- persistent database storage;
- restart reconciliation;
- branch mutation;
- protected transition execution;
- automated review;
- autonomous closure preparation.

Those belong to later maturity levels and must not be smuggled into M0.

## Promotion rule

M0 should be considered ready for a later M1 proposal only after its focused tests pass and an independent diff review confirms:

- zero application feature-code changes;
- exact ancestry from the frozen Governance v1.0 checkpoint;
- no governance document modification;
- no hidden write path;
- no capability that can turn an observation into a protected mutation.
