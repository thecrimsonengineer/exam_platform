# CSP11 Phase L4M — Reachable-Route Exploration

## Status

**FROZEN / CLOSED**

Phase: `L4M`

Working branch: `phase-l4-learner-decision-lab`

Closed predecessor: `phase-l4l-closed` at `40a32bcaf1b94adcac2675a49ffe24226de2c4f9`

L4M closure was validated by GitHub Actions run `35424550700`.

Formatter-normalized L4M recovery checkpoint:

- branch: `phase-l4m-closed`
- commit: `25431d0693e609acffa78483b25295b16209e13c`

The closure run passed formatting, Flutter analyze, learner regressions, L4K, closed L4L, L4M including the 1,024-route scale case, the frozen Phase L suite, full repository regression, Android debug build, production web build and diff hygiene.

The frozen Phase L4 direction defines L4M as:

> Automated simulated learners exercise all reachable authored paths where practical and deterministic representative coverage where exhaustive traversal is not practical.

L4M must not weaken or reinterpret the closed L4L exact route proof.

## 1. Boundary between L4L and L4M

L4L answers:

**Can the authored reachable route space be proven internally coherent, deterministic and complete under the exact proof guard?**

L4M answers:

**Which complete proven routes should automated simulated learners execute when the reachable route population is larger than the standard exploration budget?**

L4M never samples a route that L4L did not first complete successfully.

## 2. Exploration modes

`LabReachableRouteExplorer` exposes three modes.

### Exhaustive

Used when the discovered complete route population is less than or equal to the route budget.

Every complete route is selected.

Default route budget:

**1,000 routes**

### Representative

Used when the discovered complete route population exceeds the route budget but remains inside the separate hard route guard.

The selected set must preserve all mandatory reachable coverage and must be deterministic.

### Blocked

Used when the underlying exact route proof is invalid or exceeds the hard route guard.

No representative routes are accepted and the report fails closed.

Default hard route guard:

**10,000 routes**

The 10,000 guard is separate from the 1,000 standard exploration budget.

## 3. Mandatory representative coverage

A representative set is valid only when it preserves all coverage discovered by the exact route proof for:

- Decision option keys;
- authored consequences;
- Story Gate IDs;
- Story Gate types;
- authored endings.

If the configured budget is too small to preserve all mandatory coverage, L4M returns an invalid report rather than silently dropping coverage.

## 4. Deterministic route selection

Representative selection is deterministic.

The algorithm:

1. sorts all complete routes by their deterministic L4L route fingerprint;
2. starts with every mandatory coverage item marked uncovered;
3. repeatedly selects the route that covers the greatest number of still-uncovered items;
4. resolves equal scores by the canonical fingerprint ordering;
5. removes the newly covered items from the uncovered sets;
6. after mandatory coverage is complete, fills remaining budget slots using a deterministic spread across the remaining fingerprint-sorted routes;
7. sorts the final selected set canonically;
8. reruns selection and requires the same selected fingerprint.

No random seed, runtime LLM or author-order accident determines the representative set.

## 5. L4M evidence

`LabReachableRouteExplorationReport.toEvidenceJson()` emits:

`csp11.lab.l4m.exploration.v1`

The evidence includes:

- exploration mode;
- standard route budget;
- hard route limit;
- discovered complete-route count;
- selected-route count;
- selected option coverage;
- selected consequence coverage;
- selected Story Gate coverage;
- selected Story Gate type coverage;
- selected ending coverage;
- selected complete-route fingerprints;
- underlying exact L4L proof fingerprint;
- representative selection fingerprint;
- mandatory-coverage result;
- deterministic result;
- issues;
- final validity.

## 6. Scale proof

A dedicated L4M scale fixture creates five sequential four-option decisions.

Complete route population:

`4 × 4 × 4 × 4 × 4 = 1,024`

With the default route budget of 1,000:

- discovered routes = 1,024;
- selected routes = 1,000;
- mode = representative;
- all 20 Decision options remain covered;
- all 20 consequences remain covered;
- all five Story Gates remain covered;
- the authored ending remains covered;
- repeated selection must be byte-stable.

This proves representative mode is entered through the real default budget boundary rather than only by artificially lowering the budget on the 196-route reference LAB.

## 7. Fail-closed cases

L4M must fail closed when:

- route budget is zero or negative;
- hard route guard is smaller than the route budget;
- the exact L4L route proof is invalid;
- exact discovery exceeds the hard route guard;
- representative selection cannot preserve mandatory coverage;
- repeated representative selection changes the selected fingerprint.

## 8. Publish boundary

L4M is an internal validation/exploration component.

It does **not** replace the current publish condition during this slice.

The frozen L4N phase owns the final automated publish-gate integration across structural validation, DQG300-LAB, consequence/state proof, Story Gates, L4M route exploration, endings, deterministic replay, debrief validation and Learning Twin evidence.

Keeping this boundary explicit prevents L4M implementation from silently changing publish semantics before L4N.

## 9. L4M acceptance gate

Before L4M is frozen, confirm:

1. formatter is clean;
2. Flutter analyze passes;
3. closed L4L tests remain green;
4. L4M exhaustive-mode tests pass;
5. L4M representative-mode tests pass;
6. 1,024-route scale test passes with the default 1,000 budget;
7. too-small representative budget fails closed;
8. hard-guard overflow fails closed;
9. repeated selection is deterministic;
10. frozen Phase L suite remains green;
11. full repository regression passes;
12. Android debug build passes;
13. production web build passes;
14. diff hygiene passes.

All L4M closure gates passed in run `35424550700`. L4M is closed at the recovery checkpoint recorded above.
