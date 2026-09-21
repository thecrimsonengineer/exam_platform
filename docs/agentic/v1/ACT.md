
# CSP11 Agentic PDCA System - ACT v1.0

Stage: ACT  
Status: FROZEN v1.0  
Freeze state: FROZEN v1.0

ACT is the controlled response, recovery, escalation, quarantine, closure-routing, autonomy-management and learning layer.

Core rule:

~~~text
CHECK decides what is true.
ACT decides what is allowed to happen next.
~~~

ACT never converts red evidence into green by changing interpretation, thresholds, tests or terminology.

This draft is governed by CANONICAL_CONTROL_MODEL.md.

## Accepted ACT inputs

ACT may consume:
- CHECK_EVENT;
- DO_STOP_EVENT;
- SECURITY_EVENT;
- HUMAN_DECISION;
- CANCEL_EVENT;
- INFRASTRUCTURE_EVENT.

Each event has a unique event ID and lineage ID.

Repeated delivery must be idempotent.

## ACT decision identity

Every decision records:

~~~text
act_decision_id
input_event_id
lineage_id
decision
reason
repair_budget_state
next_state
authorized_actor
timestamp
~~~

The same input event returns the existing decision instead of consuming budget twice.

## ACT state ownership

ACT owns:

~~~text
ACT_RETRY_AUTHORIZED
ACT_REPAIR_AUTHORIZED
ACT_RECHECK_REQUIRED
ACT_QUARANTINED
ACT_ROLLBACK_REQUIRED
ACT_ROLLBACK_COMPLETE
ACT_ESCALATED
ACT_DECISION_RECEIVED
ACT_REVIEW_PENDING
ACT_CLOSURE_PREPARATION
ACT_FINAL_CHECK_REQUIRED
ACT_CLOSURE_ELIGIBLE
ACT_HUMAN_CLOSURE_PENDING
ACT_CLOSED
ACT_FAILED_SAFE
ACT_CANCELLED
~~~

## Response families

### Recovery
Formatting, analyzer, compile, bounded implementation defects and test-harness defects.

Route:
repair/retry -> DO -> CHECK.

### Governance
Architecture conflict, scope expansion, dependency request, frozen-rule conflict and ambiguous product behavior.

Route:
stop autonomous work -> escalate -> human/PLAN decision -> new authorized task.

### Incident
Security, credential, data-integrity, unauthorized protected-branch mutation or serious governance-control failure.

Route:
quarantine -> pause affected automation -> contain -> rollback/rotate/investigate -> human control.

## Repair control

Use the class-specific matrix in the Canonical Control Model.

Budgets belong to lineage, not agent identity.

Switching agents does not reset budget.

Infrastructure retry does not consume behavioral repair budget.

Each repair records parent candidate SHA, failure class, root-cause evidence and remaining budget.

Repeated repair strategies may be halted before numeric budget exhaustion.

## Retry versus repair

Retry:
same SHA; transient environment failure.

Repair:
changed code/test/config; new SHA.

Repeated infrastructure failure escalates rather than burning unlimited resources.

## Quarantine

Suspicious candidates enter ACT_QUARANTINED.

Quarantine means:
- no integration;
- no dependent tasks;
- no closure;
- preserve evidence;
- investigate.

Triggers include:
- secret exposure;
- wrong/unknown ancestry;
- protected-path mutation;
- unexpectedly massive diff;
- corrupted generated registry;
- suspicious binary;
- compromised automation.

Quarantined SHAs are not future task bases unless explicitly cleared.

## Rollback

Rollback records:

~~~text
bad_sha
known_good_sha
reason
mechanism
post_rollback_check
~~~

Disposable bad agent branches should normally be discarded.

Shared branch recovery preserves forensic history.

Rollback is followed by validation.

## Security/data incidents

F9 failures bypass normal repair.

Potential actions:
- emergency stop;
- quarantine;
- revoke/rotate credentials;
- invalidate sessions where appropriate;
- branch containment;
- Git history inspection;
- access/log audit;
- data-integrity assessment;
- human security decision.

Deleting a secret from HEAD alone is not sufficient remediation.

## Scope and architecture failures

Material scope violation normally rejects the candidate and rebuilds from a clean authorized branch.

Small conditional-path needs require explicit task reauthorization.

Unambiguous restoration to a frozen architecture rule may receive a bounded repair.

Material redesign requires escalation.

Frozen historical tests are never automatically changed to fit a new candidate.

## Escalation classes

- E1 Task clarification.
- E2 Scope expansion.
- E3 Architecture decision.
- E4 Dependency/infrastructure approval.
- E5 Security/data incident.
- E6 Governance conflict.
- E7 Repair-budget exhaustion.

Escalation packages contain a concise decision question, evidence, options, impact and recommended default where appropriate.

Human answers create new PLAN/task authority before DO resumes.

## Dependency-aware blocking

If task A is required by B and C, and A escalates:

~~~text
B = TASK_BLOCKED
C = TASK_BLOCKED
~~~

Independent tasks may continue.

No downstream agent builds on unresolved candidate ancestry.

## Candidate Green

On CHECK_CANDIDATE_GREEN:

1. preserve exact SHA/evidence;
2. lock candidate mutation temporarily;
3. enter ACT_REVIEW_PENDING;
4. dispatch independent Reviewer.

Any review-requested code change returns to DO and requires a new CHECK.

## Review Accepted

On CHECK_REVIEW_ACCEPTED:

1. lock feature implementation;
2. authorize closure/evidence preparation only;
3. narrow Closer permissions;
4. enter ACT_CLOSURE_PREPARATION.

If closure preparation discovers implementation defects, stop closure and return to a new DO task.

## Closure preparation and final check

Status/evidence documents contain factual evidence only.

The status commit creates a new SHA.

ACT enters ACT_FINAL_CHECK_REQUIRED and requests CLOSURE CHECK for that exact status-bearing SHA.

CHECK may return CHECK_FINAL_GREEN.

## Closure eligibility

ACT alone computes ACT_CLOSURE_ELIGIBLE using the Canonical Control Model predicate.

Hard-gate failures cannot be overridden by score.

Valid approved waivers may coexist only when PLAN permits them.

## Human closure

After eligibility:

~~~text
ACT_HUMAN_CLOSURE_PENDING
~~~

Automation stops and presents:
- phase;
- exact SHA;
- final CHECK run;
- Review Accepted status;
- valid waivers;
- remaining observations.

Human approval binds to that exact SHA.

A changed SHA invalidates approval.

## Closure operation

After explicit approval:

~~~text
create phase-*-closed at validated SHA
verify pointer
record metadata
protect checkpoint
~~~

No implementation edit occurs during freeze.

Then ACT records ACT_CLOSED.

## Waivers

ACT routes waivers.

Record:

~~~text
waiver_id
finding_id
scope
reason
approver
created_at
expires_at_or_review_phase
mitigation
~~~

Categories:
- observation;
- temporary waiver;
- blocking exception.

Agents may recommend but not approve meaningful waivers.

Expired waivers become blocking until reviewed.

## Cancellation and resume

Support soft stop and emergency stop.

Soft stop finishes the current atomic operation and prevents new dispatch.

Emergency stop is used for destructive/security/data-risk conditions.

Resume validates branch, expected HEAD, worktree state, resolved blockers, remaining budget and current task authority.

## Autonomy management

Autonomy is capability-specific.

Promotion uses evidence such as successful tasks, policy-violation rate, rollback rate, scope compliance and Review Accepted rate.

During governance v1, promotion requires human approval.

Objective severe violations may cause immediate demotion.

## Evidence-integrity incidents

False claims such as "workflow green" when CI is red are evidence-integrity incidents.

Authoritative repository/CI state always wins.

Serious evidence-integrity failures reduce autonomy.

## Learning loop

ACT creates:
- task lessons;
- system lessons.

System lessons enter a Governance Proposal Queue and never directly rewrite frozen governance.

Distinguish:
- correction;
- corrective action;
- preventive action.

Repeated repair should lead to preventive controls.

## Governance proposals

Record:
- proposal ID;
- observations;
- occurrence count;
- affected tasks;
- time/cost impact;
- proposed rule;
- risk/downside;
- evidence.

Governance changes require human review and a new governance version.

## Severity

- S0 Information.
- S1 Routine engineering failure.
- S2 Significant/repeated regression.
- S3 Governance/architecture incident.
- S4 Security/data-integrity incident.

Severity determines pause breadth and human involvement.

## Single ACT controller

One lineage has one active ACT controller.

Decision writes use optimistic concurrency:

~~~text
expected_lineage_state == actual_lineage_state
~~~

Parallel repair hypotheses require explicit authorization and share budget.

## Resource control

ACT prevents irrational loops.

After repeated identical targeted failures, another full CI run should require targeted reproduction first.

Do not increase model cost when infrastructure is the real problem.

## Metrics

Track:
- first-repair success;
- average attempts;
- budget exhaustion;
- escalation count/class;
- rollback/quarantine count;
- failed-safe count;
- policy violations;
- evidence-integrity incidents;
- Candidate Green to Review Accepted time;
- Review Accepted to Closure Eligible time;
- Closure Eligible to Closed time;
- governance proposals;
- repeat-incident rate after corrective action.

## Retrospective

Every major phase closure produces a lightweight retrospective covering tasks, failed workflows, root causes, repairs, escalations, rollbacks, exceptions, violations, escaped defects, time/cost and governance proposals.

Retrospective does not reopen a closed phase.

## Maturity levels

ACT-0: human routes all outcomes.

ACT-1: automatic mechanical routing for objective low-risk events.

ACT-2: bounded repair routing with central budgets.

ACT-3: quarantine and capability-specific autonomy management.

ACT-4: adaptive routing, cost optimization and governance-proposal generation.

No level grants autonomous phase closure.

## ACT entry

ACT requires an authoritative event with:
- event ID;
- lineage ID;
- current/candidate SHA;
- state/failure class;
- evidence;
- risk class;
- budget state.

Missing input means ACT_NOT_READY.

## Canonical ACT flow

~~~text
AUTHORITATIVE EVENT
      ↓
deduplicate / verify lineage
      ↓
classify RECOVERY / GOVERNANCE / INCIDENT
      ↓
RECOVERY:
  retry or bounded repair
  → DO
  → CHECK

GOVERNANCE:
  escalate
  → human/PLAN decision
  → authorized task
  → DO

INCIDENT:
  quarantine
  → contain/rollback/security response
  → human control

CHECK_CANDIDATE_GREEN
  → ACT_REVIEW_PENDING
  → independent review

CHECK_REVIEW_ACCEPTED
  → ACT_CLOSURE_PREPARATION
  → status-bearing SHA

status-bearing SHA
  → ACT_FINAL_CHECK_REQUIRED
  → CLOSURE CHECK

CHECK_FINAL_GREEN
  → canonical closure predicate
  → ACT_CLOSURE_ELIGIBLE
  → ACT_HUMAN_CLOSURE_PENDING
  → explicit exact-SHA approval
  → ACT_CLOSED
  → retrospective
  → Governance Proposal Queue
~~~

## Safety principle

Automation may recover from evidence. It may never recover by redefining success.

## Learning principle

Repeated repair is evidence that PLAN, DO or CHECK should improve.

This document is frozen as part of CSP11 Agentic PDCA Governance v1.0.

## PDCA disposition and standardization

ACT closes the PDCA learning loop.

It does more than route failures. It decides what to do with the verified result and what should become the next standard.

### Four primary PDCA dispositions

After CHECK evidence is available, ACT selects one of these high-level dispositions where applicable:

~~~text
ADOPT_AND_STANDARDIZE
ADJUST_AND_REPLAN
ABANDON_AND_ROLLBACK
CONTAIN_AND_ESCALATE
~~~

These dispositions coexist with the more detailed ACT operational states.

### ADOPT_AND_STANDARDIZE

Use when CHECK shows the planned change is effective, safe and acceptable.

ACT may:

- retain the successful method;
- standardize approved operating steps;
- update future task templates/context packs through governance-approved changes;
- preserve new controls/tests;
- document the new baseline;
- create governance proposals where global rules should change.

Successful learning does not automatically edit frozen governance. Standardization follows the governance change-control process.

### ADJUST_AND_REPLAN

Use when the idea remains viable but CHECK shows targets were not fully met, assumptions were wrong, or controls need adjustment.

ACT:

1. preserves the evidence;
2. records root cause;
3. creates a PLAN revision/proposal;
4. establishes the new baseline/target where needed;
5. begins a new PDCA cycle.

### ABANDON_AND_ROLLBACK

Use when the change is ineffective, unsafe, excessively costly or no longer justified.

ACT restores or retains the known-good state, preserves evidence, and records why the attempted change should not become standard.

### CONTAIN_AND_ESCALATE

Use for security, data-integrity, governance, architecture or other issues requiring containment and human decision.

### New baseline after adoption

When a successful improvement is adopted, its measured actual state becomes the reference baseline for the next relevant PLAN cycle.

This makes continuous improvement cumulative rather than repeatedly comparing against an obsolete manual baseline.

### Standardize success, not only failure

A PDCA cycle is incomplete if ACT only fixes red outcomes.

ACT also asks:

~~~text
What worked well enough to become the new standard?
What should be retained?
What should be taught to future agents/tasks?
What should become a preventive control?
~~~

### Feed the next PLAN

ACT produces approved lessons/proposals for the next PLAN.

This closes the loop:

~~~text
PLAN → DO → CHECK → ACT
 ↑                  ↓
 └──── learning ────┘
~~~


---

Governance version: **v1.0**  
Frozen source design SHA: `e938d777551166cc72a3627af5523706fafcc272`  
Normative closed branch: `agentic-pdca-governance-v1-closed`  
