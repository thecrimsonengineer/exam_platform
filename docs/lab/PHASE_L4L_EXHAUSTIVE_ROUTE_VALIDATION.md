# CSP11 Phase L4L — Exhaustive Consequence / State / Story-Gate Validation

## Status

**IMPLEMENTED / CI VALIDATION PENDING**

Branch: `phase-l4-learner-decision-lab`

L4L extends the automated LAB publish path with exact deterministic route verification. It does not replace the standard LAB1000 simulation matrix. The LAB1000 simulation cap remains a separate validation mechanism. L4L is a stronger exact proof for the reachable authored route space subject to its independent hard guard.

Do not mark L4L frozen or closed until the Phase L4 workflow is green after these changes.

## Purpose

L4L proves that authored LAB decisions do not merely pass schema validation. It verifies that complete decision paths can execute through:

`Decision -> Consequence -> State Mutation -> Story Gate -> Next Node / Ending`

The validator fails closed when an authored branch cannot be completed deterministically.

## Publish-blocking proof

A valid L4L report requires all of the following:

- at least one complete route;
- no exhaustive-validation issues;
- exhaustive route guard not exceeded;
- every authored Decision option appears on at least one completed route;
- every consequence used by an authored option appears on at least one completed route;
- every authored Story Gate wins on at least one completed route;
- every authored ending is reached;
- all route continuity invariants hold;
- two independent exhaustive runs produce the same deterministic fingerprint and coverage evidence.

The automated publish gate consumes `LabExhaustiveRouteReport.isValid`. Therefore an incomplete L4L proof blocks automated publication even when DQG300-LAB passes.

## Route invariants

Every completed trace is checked against the original LAB package.

For each Decision transition L4L verifies:

- selected option has an authored consequence;
- consequence ID matches the authored consequence;
- state delta agrees with before / after snapshots;
- simulated time advances by exactly the authored consequence amount;
- evidence after the consequence equals previous evidence plus authored evidence unlocks;
- evidence never disappears;
- simulated time never moves backwards.

For each Story Gate transition L4L verifies:

- gate ID exists in the authored package;
- gate source matches the current node when a source is specified;
- gate type matches;
- priority matches;
- target node matches;
- ending ID matches.

For route continuity L4L verifies:

- first step begins from the package starting state with no unlocked evidence and zero simulated minutes;
- each non-terminal target node equals the next trace node;
- state after one step equals state before the next;
- evidence after one step equals evidence before the next;
- simulated time after one step equals simulated time before the next;
- terminal steps use a Completion Gate;
- terminal ending is an authored ending;
- no step has both a target and an ending;
- no step has neither a target nor an ending.

## Coverage semantics

Coverage is derived **only from completed routes**.

Attempting an option does not count as coverage when that branch later:

- has no Story Gate;
- reaches an unknown node;
- becomes ambiguous;
- enters a repeated-state cycle;
- exceeds the depth guard;
- fails consequence execution;
- otherwise cannot reach an authored ending.

The report exposes:

- `optionCoverageKeys`;
- `consequenceCoverageIds`;
- `gateCoverageIds`;
- `gateTypeCoverage`;
- `endingIds`;
- uncovered option / consequence / gate / ending sets.

## Deterministic closure evidence

`LabExhaustiveRouteReport.toEvidenceJson()` emits schema:

`csp11.lab.l4l.exhaustive.v1`

The evidence contains:

- complete route count;
- option coverage;
- consequence coverage;
- Story Gate coverage;
- Story Gate type coverage;
- ending coverage;
- ending route distribution;
- consequence application counts;
- Story Gate win counts by ID and type;
- uncovered coverage sets;
- limit status;
- coverage booleans;
- route invariant status;
- deterministic status;
- validation issues;
- exact route fingerprint;
- final L4L validity.

All unordered sets are serialized in deterministic sorted form.

## Frozen reference LAB matrix candidate

Reference package:

`content/lab_reference_confined_space_h2s_v2.json`

Expected complete route count:

**196**

Expected ending distribution:

| Ending | Routes |
| --- | ---: |
| safe_completion | 48 |
| controlled_recovery | 48 |
| incident_contained | 48 |
| major_incident | 39 |
| critical_failure | 13 |

Expected Story Gate type wins:

| Gate type | Wins |
| --- | ---: |
| route | 183 |
| criticalEvent | 169 |
| convergence | 300 |
| completion | 196 |

Total Story Gate transitions across all completed routes:

**848**

Expected individual critical / convergence gate wins include:

| Gate | Wins |
| --- | ---: |
| permit_critical_event | 13 |
| gas_critical_event | 39 |
| simops_critical_event | 117 |
| gas_work_convergence | 144 |
| emergency_convergence | 156 |
| emergency_critical_failure | 13 |

## Failure cases covered

L4L tests now include:

- route-cap exhaustion;
- unreachable authored Story Gate;
- option branch with no Story Gate;
- repeated-state route cycle;
- state-changing cycle caught by depth guard;
- reachable equal-priority gate ambiguity;
- unauthored terminal ending;
- inline authored consequence;
- evidence persistence through convergence;
- critical-event priority interruption;
- critical chain to critical failure;
- recovery and contained endings;
- exact consequence/state/time/evidence trace fingerprints;
- deterministic repeated-run fingerprints.

## Validation-limit separation

The standard LAB1000 deterministic simulation matrix remains capped independently by `simulationLimit`, normally 1,000.

The L4L exact route proof uses the separate `exhaustiveRouteLimit`. Its automated publish default is 10,000 so the 1,000-run LAB1000 profile is not accidentally reused as the exhaustive-route hard guard.

A LAB that exceeds the L4L hard guard fails closed until its route-proof strategy is intentionally extended. The validator must never silently label a truncated route set exhaustive.

## L4L closure gate

Before creating an L4L frozen checkpoint, confirm the current Phase L4 workflow passes:

1. Dart formatting.
2. Flutter analyze.
3. Learner LAB regressions.
4. L4K DQG300-LAB automated publish tests.
5. L4L exhaustive route tests.
6. Frozen Phase L engine suite.
7. Full repository tests.
8. Android debug build.
9. Production web build.
10. Diff hygiene.

Only after those gates are green should L4L be tagged or checkpointed as closed.
