
# CSP11 Agentic PDCA System - Cross-Consistency Audit

Status: Draft audit completed  
Freeze state: NOT FROZEN

Audited inputs:
- PLAN Draft
- DO Draft
- CHECK Draft
- refined ACT design

## Executive result

The design is strong but was not ready to freeze without cross-stage normalization.

Twenty material consistency issues were found and resolved in the Canonical Control Model.

## Findings and improvements

### A1 - Authority hierarchy incomplete
PLAN did not explicitly include future frozen PDCA governance.

Improvement:
Frozen PDCA governance is now an explicit authority tier. AGENTS.md is a derived execution projection.

### A2 - Closure eligibility duplicated
CHECK and ACT both appeared to own Closure Eligible.

Improvement:
CHECK owns CHECK_FINAL_GREEN and review evidence. ACT alone computes ACT_CLOSURE_ELIGIBLE.

### A3 - Safe stops before CHECK had no owner
DO can stop for architecture, security, conflict, ambiguity, stale base or budget exhaustion before a candidate reaches CHECK.

Improvement:
DO emits a structured DO_STOP_EVENT. ACT accepts authoritative control events as well as CHECK events.

### A4 - Validation/integration circularity
DO suggested reviewed candidates enter integration, while CHECK appeared to validate only integrated code.

Improvement:
Introduce TASK CHECK, INTEGRATION CHECK and CLOSURE CHECK.

### A5 - Merge terminology ambiguous
"No autonomous merge" conflicted with controlled phase integration.

Improvement:
Separate phase integration, production merge and closed-branch creation.

### A6 - Repair policy inconsistent
PLAN generic budgets conflicted with refined ACT class-specific budgets.

Improvement:
Use one class-specific canonical repair matrix.

### A7 - Retry and repair conflated
Infrastructure retries could consume behavioral repair budget.

Improvement:
Retry means same SHA. Repair means new SHA.

### A8 - Exceptions inconsistent
CHECK said no pending exceptions while ACT allowed approved temporary waivers.

Improvement:
Closure requires no unapproved/blocking findings and only valid documented waivers.

### A9 - Risk vs autonomy collision
R0-R5 and DO-0-DO-4 could be mistaken for the same scale.

Improvement:
Risk describes the change. Autonomy describes the agent's permitted capability.

### A10 - Validator self-modification loophole
A candidate could theoretically weaken the judge assessing it.

Improvement:
Create a Trusted Judge Set and separate Judge Change Task protocol.

### A11 - State naming collision
READY, GREEN and CLOSED were used across different stages.

Improvement:
Namespace states as TASK_*, CHECK_* and ACT_*.

### A12 - Reviewer isolation ambiguity
Reviewer branches were listed while Reviewer is read-only.

Improvement:
Reviewer uses a separate read-only checkout/session by default. A branch is needed only for separately approved review artifacts.

### A13 - Quality threshold premature
A 90-point threshold was proposed before calibration.

Improvement:
During pilot the score is advisory evidence. Hard gates remain authoritative. Threshold becomes binding only after calibration.

### A14 - Human approval scope ambiguous
Approval could be interpreted as generic.

Improvement:
Bind approvals to exact task revisions, findings, dependencies, waivers or closure SHA.

### A15 - Evidence retention gap
Deleting disposable branches could remove important evidence.

Improvement:
Persist authoritative evidence in GitHub checks/artifacts and canonical history before cleanup.

### A16 - Concurrent writer race
Expected-HEAD checks lacked a central branch ownership registry.

Improvement:
Control Plane with single writer lease and optimistic concurrency.

### A17 - Repair budget race
Multiple repairers could each believe budget remained.

Improvement:
Central lineage repair ledger.

### A18 - Maturity mismatch
DO-4 could theoretically operate while CHECK/ACT were still immature.

Improvement:
Couple system maturity. Overall maturity is limited by the weakest required control layer.

### A19 - Judge changes lacked a safe lane
Legitimate workflow/test-gate evolution had no separate approval path.

Improvement:
Dedicated Judge Change Task with elevated review.

### A20 - Closure predicate fragmented
PLAN, CHECK and ACT each described closure in overlapping prose.

Improvement:
PLAN defines required inputs, CHECK supplies independent evidence, ACT owns one canonical predicate.

## Additional improvements from refined ACT

The refined ACT design also adds:
- idempotent ACT decisions;
- recovery/governance/incident response separation;
- quarantine;
- capability-specific autonomy;
- correction vs corrective action vs preventive action;
- escalation classes;
- exact-SHA human approval binding;
- dependency-aware task blocking;
- single authoritative ACT controller per lineage;
- evidence-integrity incidents;
- governance proposal queue;
- incident severity levels;
- resource-aware retry control.

## Recommended sequence before freeze

1. Keep existing stage drafts for traceability.
2. Reference the Canonical Control Model from all four stages.
3. Commit the refined ACT draft.
4. Run an adversarial cross-state audit against illegal transitions and governance bypasses.
5. Consolidate into freeze-ready governance v1 documents.
6. Human review.
7. Freeze governance.
8. Only then build the observation-only/bounded agentic spike.

## Audit result

~~~text
PLAN      sound; needs canonical-control reference
DO        sound; needs TASK CHECK/control-event normalization
CHECK     sound; needs closure ownership correction
ACT       refined; response/recovery model now consistent
CONTROL   canonical cross-stage model added

FREEZE    NOT READY YET
NEXT      adversarial cross-state audit and final consolidation
~~~
