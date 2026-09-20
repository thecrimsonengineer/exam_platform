
# CSP11 Agentic PDCA System - Canonical Control Model Draft

Status: Draft  
Freeze state: NOT FROZEN

This is the cross-stage source of truth for state ownership, event identity, validation tiers, repair lineage, trusted judges, approvals, and maturity coupling.

## Authority hierarchy

1. Platform/security constraints and explicit authorized human instruction.
2. Frozen PDCA governance.
3. Frozen architecture and safety rules.
4. Frozen phase specification.
5. Approved task packet.
6. Trusted deterministic gates and architecture baselines.
7. Repository conventions.
8. Agent implementation preference.

AGENTS.md is an execution projection of governance. It is not a higher source of authority than the governance or phase specifications it summarizes.

## Four distinct objects

### PLAN Task

Defines authority and intent.

Required identity:

~~~text
task_id
phase_id
base_branch
base_sha
risk_class
allowed_paths
forbidden_paths
required_tests
stop_conditions
~~~

### DO Candidate

Represents work produced under a PLAN task.

~~~text
task_id
lineage_id
candidate_sha
parent_candidate_sha?
agent_role
agent_branch
worktree
handoff_id
~~~

### CHECK Event

Represents independent validation of one exact SHA.

~~~text
check_event_id
task_id
lineage_id
candidate_sha
validation_scope
check_state
failure_class?
risk_class
evidence_bundle_ref
workflow_run_id?
timestamp
~~~

### ACT Decision

Represents the controlled response to an authoritative event.

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

Repeated delivery of the same event must not create a second decision.

## State namespaces

Task states:

~~~text
TASK_QUEUED
TASK_READY
TASK_RUNNING
TASK_BLOCKED
TASK_HANDOFF_READY
TASK_FAILED_SAFE
TASK_CANCELLED
~~~

CHECK states:

~~~text
CHECK_NOT_READY
CHECK_RED
CHECK_REPAIRABLE
CHECK_ESCALATE
CHECK_CANDIDATE_GREEN
CHECK_REVIEW_ACCEPTED
CHECK_FINAL_GREEN
~~~

ACT states:

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

CLOSED is owned by ACT only after explicit authorized human closure.

## Ownership matrix

| Concern | PLAN | DO | CHECK | ACT |
|---|---|---|---|---|
| Scope/rules | Defines | Obeys | Verifies | May request amendment |
| Implementation | No | Owns | Never repairs | Routes repair |
| Targeted local tests | Defines minimum | Runs | Re-runs as needed | Consumes evidence |
| Full validation | Defines requirement | No authority | Owns | Routes response |
| Test-integrity verdict | Defines policy | Must preserve | Owns | Acts on finding |
| Architecture verdict | Defines boundary | Must preserve | Owns | Escalates/routes |
| Repair budget | Defines policy | Consumes authorized attempt | Reports failure | Owns central ledger |
| Exception approval | Defines non-waivable classes | No | Identifies finding | Routes human waiver |
| Quality score | Defines rubric | No authority | Calculates | Consumes |
| Closure eligibility | Defines predicate inputs | No | Supplies evidence | Computes predicate |
| Closed branch creation | Defines rule | Never | Never | Only after human approval |
| Governance learning | Allows proposals | Supplies lessons | Supplies findings | Creates proposals |
| Governance modification | Human-approved only | Never | Never | Never automatically |

## Closure ownership

CHECK does not own Closure Eligible.

CHECK owns validation facts:

~~~text
CHECK_CANDIDATE_GREEN
CHECK_REVIEW_ACCEPTED
CHECK_FINAL_GREEN
~~~

ACT computes ACT_CLOSURE_ELIGIBLE from a formal predicate using CHECK evidence, PLAN closure requirements, approved exceptions, and exact-SHA identity.

## Three validation tiers

### TASK CHECK

Validates an isolated agent task before integration.

Minimum:
- exact SHA;
- allow-list;
- targeted tests;
- relevant architecture gate;
- test-integrity delta;
- no protected-path violation.

### INTEGRATION CHECK

Validates the authoritative phase integration branch after accepted task commits are integrated.

Minimum:
- format;
- full analysis;
- current-phase suite;
- architecture suite;
- dependency/security scan;
- cross-feature regression selected by dependency map.

### CLOSURE CHECK

Validates the exact status-bearing phase SHA.

Minimum:
- all phase acceptance gates;
- frozen historical regressions;
- required builds/device evidence;
- final status/evidence integrity;
- final ancestry;
- approved exception state.

Possible result: CHECK_FINAL_GREEN.

## Trusted Judge Set

The validator must have a protected baseline called the Trusted Judge Set.

It includes, where applicable:
- frozen historical tests;
- architecture tests;
- security/dependency scan logic;
- critical GitHub workflows;
- governance policies;
- closure predicates.

A normal candidate may add tests but may not silently weaken the Trusted Judge Set.

Legitimate judge changes require a separate approved Judge Change Task.

## Judge Change Task

Required fields:

~~~text
judge_change_id
old_judge_reference
proposed_change
reason
affected_gates
migration_evidence
human_approval
~~~

The feature change and judge change should remain separately reviewable wherever practical.

## Risk and autonomy are different

R0-R5 describes change risk.

DO-0 through DO-4 describes permitted autonomy in a capability.

High autonomy in formatting does not grant autonomy for security rules or architecture changes.

## Canonical repair matrix

| Failure | Autonomous repair budget |
|---|---:|
| F1 Formatting | 5 mechanical |
| F2 Analyzer/lint | 5 mechanical/bounded |
| F3 Compile | 3 behavioral |
| F4 Unit/product logic | 3 behavioral |
| F5 Test harness | 3 behavioral plus test-integrity review |
| F6 Architecture | 0 unless restoring an unambiguous frozen rule is explicitly authorized |
| F7 Frozen regression | 2 only when cause is clearly inside current candidate |
| F8 Dependency/config | 0 unless pre-authorized |
| F9 Security/data | 0 normal repair; incident path |
| F10 Ambiguous product behavior | 0; human decision |

ACT owns the central repair ledger. Replacing the agent does not reset the lineage budget.

Infrastructure retry is separate from repair and uses the same SHA.

## DO safe-stop routing

DO may stop before a CHECK candidate exists.

A DO stop emits:

~~~text
do_stop_event_id
task_id
lineage_id
current_sha
stop_class
evidence
timestamp
~~~

Routes:

- STOP-SCOPE -> ACT escalation.
- STOP-ARCH -> ACT escalation.
- STOP-DEPENDENCY -> ACT escalation.
- STOP-SECURITY -> ACT incident path.
- STOP-AMBIGUOUS -> ACT escalation.
- STOP-BASE -> ACT stale-base/replan.
- STOP-CONFLICT -> ACT reconciliation/escalation.
- STOP-TEST -> ACT test-policy escalation.
- STOP-BUDGET -> ACT escalation.
- Human cancellation -> ACT cancellation.

ACT therefore accepts CHECK events and structured control events such as DO_STOP_EVENT, SECURITY_EVENT, HUMAN_DECISION, and CANCEL_EVENT.

## Exception lifecycle

CHECK identifies findings and whether they are potentially waivable under PLAN.

ACT owns the waiver workflow.

An approved waiver records:

~~~text
waiver_id
finding_id
scope
reason
approver
created_at
expires_at_or_review_phase
mitigation
blocking=false
~~~

Closure requires:
- no unapproved findings;
- no blocking exceptions;
- all active waivers valid and documented.

Valid approved waivers may coexist with closure only when PLAN allows them.

Non-waivable examples include active credential exposure, unknown final ancestry, unauthorized closed-branch mutation, critical data-integrity failure, and unreviewed R5 security change.

## Human approval binding

Human approval binds to a specific object.

Examples:
- architecture decision -> task ID and plan revision;
- waiver -> finding ID;
- dependency approval -> dependency/version/scope;
- closure authorization -> phase ID and exact SHA.

Approval does not automatically transfer to a changed SHA or broadened task.

## Integration terminology

### Phase integration
Controlled integration of TASK-CHECK-green commits into the phase integration branch. May be automated only when PLAN authorizes it.

### Production merge
Merge into production/release/mainline. Not automatically authorized by normal feature agents.

### Closed branch creation
Creation of phase-*-closed at the exact validated SHA. Requires explicit human closure authorization.

## Reviewer independence

Independent review means:
- separate session/context from Builder;
- read-only permissions by default;
- no ability to modify the candidate under review;
- access to raw diff/evidence;
- no reliance on Builder self-score.

A different model family is optional. A different reviewer session/agent is required.

## Evidence store

Disposable branches are not authoritative evidence storage.

Authoritative evidence belongs in:
- GitHub workflow/check metadata;
- canonical phase status documents;
- protected evidence artifacts;
- immutable commit history.

## Context redaction

Context packs and handoffs must exclude secrets and unnecessary production/personal data.

Logs should be redacted before being sent to general-purpose agents when they may contain sensitive values.

## Maturity coupling

| System maturity | DO | CHECK | ACT |
|---|---|---|---|
| M0 Observation | DO-0 | CHECK-0 | ACT-0 |
| M1 Mechanical | DO-1 | CHECK-1/2 | ACT-1 |
| M2 Bounded feature | DO-2 | CHECK-2/3 | ACT-2 |
| M3 Phase task | DO-3 | CHECK-3 | ACT-2/3 |
| M4 Multi-agent | DO-4 | CHECK-4 | ACT-3/4 |

Overall operating maturity is limited by the weakest required control layer.

DO-4 multi-agent writing cannot run while CHECK/ACT remain at low maturity.

## Central Control Plane

The future implementation should maintain:
- task registry;
- lineage registry;
- event deduplication;
- state transition validation;
- repair-budget ledger;
- branch ownership/expected HEAD;
- active writer leases;
- cancellation;
- evidence references;
- human approval records.

The Control Plane does not judge code quality. CHECK remains the judge.

## Single active writer lease

For one task lineage and branch, only one writing agent lease may be active unless ACT explicitly authorizes parallel repair hypotheses.

Before mutation:

~~~text
expected_head == actual_head
active_writer_lease == current_agent
~~~

Otherwise stop for conflict.

## Parallel repair hypotheses

Parallel repairs are exceptional and explicitly authorized.

Each receives:
- isolated branch/worktree;
- shared failed parent SHA;
- unique repair ID;
- shared repair-budget accounting.

CHECK evaluates them. ACT selects one accepted lineage. Latest does not win automatically.

## Quality score calibration

Hard gates always override score.

During the initial pilot, the Independent Quality Index is recorded as advisory calibration evidence.

Provisional target: 90 or higher.

Before autonomous closure preparation is enabled, the threshold must be confirmed or adjusted using pilot data.

## Canonical closure predicate

ACT may compute ACT_CLOSURE_ELIGIBLE only when:

~~~text
check_final_green == true
review_accepted == true
status_document_present == true
status_bearing_sha == final_checked_sha
ancestry_valid == true
hard_findings == 0
unapproved_findings == 0
blocking_exceptions == 0
active_waivers_valid == true
phase_acceptance_complete == true
quality_requirement_satisfied == true
~~~

Then ACT enters ACT_HUMAN_CLOSURE_PENDING.

Only explicit human approval bound to the exact SHA permits ACT_CLOSED.

## Governance change control

Once governance is frozen, governance files join the Trusted Judge Set.

Changes require:
- governance proposal ID;
- reason;
- evidence;
- affected clauses;
- risk;
- review;
- human approval;
- new governance version.

Agents may propose governance changes. They may not apply them because a current task is inconvenient.

## Canonical cycle

~~~text
PLAN TASK
   ↓
DO isolated implementation
   ↓
TASK CHECK
   ↓
ACT integrate / repair / escalate
   ↓
phase integration branch
   ↓
INTEGRATION CHECK
   ↓
ACT review routing
   ↓
CHECK_REVIEW_ACCEPTED
   ↓
ACT closure preparation
   ↓
status-bearing SHA
   ↓
CLOSURE CHECK
   ↓
CHECK_FINAL_GREEN
   ↓
ACT closure predicate
   ↓
ACT_CLOSURE_ELIGIBLE
   ↓
ACT_HUMAN_CLOSURE_PENDING
   ↓
explicit human approval
   ↓
ACT_CLOSED
   ↓
retrospective and governance proposals
~~~

This document remains draft until the full governance freeze.
