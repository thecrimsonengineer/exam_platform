
# CSP11 Agentic PDCA System - Phase Autopilot Contract v1.0

Status: FROZEN v1.0  
Freeze state: FROZEN v1.0  
Purpose: Make the **phase**, not the individual task, the primary hands-off execution unit.

## 1. User intent

The target operating experience is:

~~~text
Human:
"Start/continue Phase X."

System:
recover the correct frozen base and current phase state
→ understand the frozen phase specification
→ inventory everything that already exists
→ build the phase task graph
→ dispatch isolated agents
→ validate each task
→ integrate accepted work
→ repair bounded failures automatically
→ continue to the next eligible work without another user prompt
→ run current + historical regression gates
→ prepare final evidence/status
→ validate the exact final SHA
→ stop at ACT_HUMAN_CLOSURE_PENDING
~~~

The user should not need to manually prompt the system after every agent task, CI result, formatter fix, or ordinary repair.

Human intervention remains mandatory for the protected decisions defined by governance, such as material architecture changes, security/data incidents, unapproved dependencies, ambiguous product decisions, waivers, and final phase closure.

## 2. Phase Mission object

A phase begins from one authoritative Phase Mission:

~~~text
phase_mission_id
phase_id
human_goal
governance_version
phase_specification_refs
base_closed_branch
base_closed_sha
phase_integration_branch
current_phase_state
preservation_manifest_ref
trusted_judge_manifest_ref
phase_objective
phase_acceptance_criteria
phase_metrics
phase_risk_profile
phase_task_graph_ref
human_approval_policy
~~~

A vague phase prompt is converted into this structured mission before autonomous DO-3/DO-4 execution begins.

## 3. Phase Recovery before new work

When the user says "continue Phase X", the orchestrator must first recover authoritative state rather than start again.

Recover:

- current phase integration branch;
- exact current HEAD;
- last TASK/INTEGRATION CHECK results;
- latest Candidate Green/Review Accepted checkpoint;
- open task graph;
- completed tasks;
- blocked tasks;
- active/expired writer leases;
- repair budgets;
- unresolved escalations;
- current PLAN revision;
- evidence bundle references.

If an active valid phase already exists, continue it.

Do not rebuild or duplicate already accepted work.

## 4. Frozen Capability Preservation Manifest

Before implementing the new phase, create or load a **Frozen Capability Preservation Manifest** derived from the latest approved closed checkpoint and its frozen ancestors.

The manifest should cover, where applicable:

~~~text
closed_base_branch
closed_base_sha
governance_version
architecture_invariants
canonical_identity_contracts
existing_feature_inventory
existing_navigation_contracts
existing_state_lifecycles
persistence_contracts
stored_data_compatibility
public/internal API contracts
trusted_historical_tests
architecture_tests
supported_platforms
build_gates
security_boundaries
backend_usage_boundaries
performance/resource budgets
generated_registry_sources
dependencies_and_lock_state
known_approved_exceptions
known_deferred_items
~~~

This is the formal meaning of "everything already made before".

## 5. Preservation rule

For capabilities outside the new phase's explicitly approved change scope:

~~~text
existing behavior is PRESERVE BY DEFAULT
~~~

A new phase may extend existing capability.

It may not silently remove, weaken, rename, bypass, invalidate, or make incompatible an existing frozen capability.

A deliberate breaking change requires an explicitly approved migration task with impact analysis, compatibility strategy, updated judges, and human approval where governance requires it.

## 6. Historical regression inheritance

Every new phase automatically inherits relevant frozen regression gates from all previously closed phases.

Example:

~~~text
phase-fc8
inherits
FC1 + FC2 + FC3 + FC4 + FC5 + FC6 + FC7
plus frozen shared MOT/HAP/architecture gates
~~~

The new phase cannot mark itself complete merely because its new FC8 tests pass.

## 7. Existing-feature differential protection

Where feasible, CHECK should compare the candidate against the latest closed baseline for unchanged capabilities.

Potential techniques:

- trusted historical tests;
- snapshot/golden comparisons where appropriate;
- API/schema comparison;
- navigation contract checks;
- persisted-state reload tests;
- generated registry/hash comparison;
- dependency diff;
- configuration diff;
- behavior-specific regression suites.

Unexpected changes outside approved scope become findings even if new-phase tests are green.

## 8. Stored-data and learner-state preservation

If earlier phases created persisted learner/admin state, the new phase must explicitly preserve compatibility unless a migration is approved.

CHECK should consider, where relevant:

- existing SharedPreferences keys;
- local persisted models;
- Firestore document/collection shapes;
- content package schemas;
- lifecycle values;
- learner progress;
- ownership/review state;
- authentication/session continuity.

A new phase may not declare closure while silently making existing legitimate stored state unreadable or semantically invalid.

## 9. Phase task graph

The Phase Orchestrator converts the frozen phase specification into a dependency-aware task DAG.

Each node has:

~~~text
task_id
goal
dependencies
risk_class
allowed_paths
forbidden_paths
required_context
required_targeted_tests
required_check_tier
expected_outputs
completion_criteria
~~~

The graph must cover the complete phase acceptance scope.

Every phase requirement maps to one or more graph nodes or to an explicit non-code validation item.

## 10. Requirement coverage ledger

Maintain:

~~~text
phase_requirement_id
mapped_task_ids
status
evidence
disposition
~~~

Allowed final dispositions:

~~~text
COMPLETED
VALIDATED_NO_CHANGE_REQUIRED
HUMAN_APPROVED_DEFERRED
HUMAN_APPROVED_WAIVER
NOT_APPLICABLE_WITH_EVIDENCE
~~~

No phase requirement may disappear silently.

## 11. Autonomous orchestration loop

For each READY node:

1. acquire task/branch/worktree lease;
2. dispatch suitable Builder/Diagnosis agent;
3. execute DO;
4. run TASK CHECK;
5. if green, ACT authorizes integration;
6. acquire integration lease;
7. integrate with expected-HEAD compare-and-swap;
8. run required smoke/integration gate;
9. mark dependent nodes READY;
10. immediately dispatch the next eligible work.

The orchestrator continues without requiring another user prompt.

## 12. Bounded automatic repair loop

For repairable failures:

~~~text
CHECK_REPAIRABLE
→ ACT_REPAIR_AUTHORIZED
→ Repairer
→ targeted DO validation
→ TASK/INTEGRATION CHECK
→ continue
~~~

Use canonical lineage repair budgets.

Ordinary formatter, analyzer, compile, bounded logic, and approved harness failures should not require the user to manually say "continue".

## 13. Automatic infrastructure retry

Transient runner/API/package-download failures use the same-SHA retry policy.

They should not stop the phase unless the infrastructure retry budget is exhausted.

## 14. Parallelism

At DO-4 maturity, independent graph nodes may run in parallel when:

- write sets are independent;
- dependencies are satisfied;
- control-plane writer leases are valid;
- CHECK/ACT maturity permits it.

The user should not need to coordinate agents manually.

## 15. Human-intervention boundary

The orchestrator pauses only the affected lineage/task when governance requires a human decision.

Typical mandatory human decisions:

- material R4 architecture choice;
- R5 security/data/infrastructure change;
- unapproved dependency;
- ambiguous product requirement;
- meaningful exception/waiver;
- governance change;
- final exact-SHA phase closure.

Independent tasks may continue if they do not depend on the blocked decision.

## 16. No premature "phase complete"

The system may not call a phase complete because:

- all Builder agents finished;
- current-phase tests passed;
- an implementation SHA is green;
- the status document was written.

A phase is closure-ready only through the canonical closure predicate.

## 17. Phase completeness predicate

Before closure preparation, require:

~~~text
all_phase_requirements_have_disposition == true
all_mandatory_tasks_integrated == true
all_blocking_escalations_resolved == true
all_required_task_checks_green == true
integration_check_green == true
frozen_capability_preservation_check_green == true
historical_regressions_green == true
current_phase_tests_green == true
architecture_checks_green == true
security_dependency_checks_green == true
stored_data_compatibility_satisfied == true
required_builds_green == true
required_device_evidence_present == true
unapproved_findings == 0
blocking_exceptions == 0
~~~

The exact set is specialized by the phase PLAN.

## 18. Closure preparation

Once Review Accepted:

- freeze feature mutation;
- generate/update phase status evidence;
- record completed/deferred/waived items;
- record first implementation-green SHA/run;
- record preservation/regression evidence;
- create the status-bearing SHA;
- request CLOSURE CHECK.

## 19. Final phase validation

CLOSURE CHECK validates the exact status-bearing SHA against:

1. current phase acceptance;
2. Frozen Capability Preservation Manifest;
3. Trusted Judge Set;
4. all mandatory inherited historical regressions;
5. ancestry/commit provenance;
6. approved waiver state;
7. required platform/build/device gates;
8. PDCA plan-to-result evidence.

Only CHECK_FINAL_GREEN can feed ACT closure eligibility.

## 20. Phase Autopilot stop state

The normal hands-off target is:

~~~text
ACT_HUMAN_CLOSURE_PENDING
~~~

The system then presents the user:

~~~text
Phase:
Base frozen SHA:
Final status-bearing SHA:
Final CHECK run:
Review Accepted:
Historical regressions:
Preservation manifest:
Open observations:
Approved waivers:
Deferred items:
PDCA outcome:
Ready for exact-SHA closure approval: YES/NO
~~~

No additional implementation work should be required in the normal successful path.

## 21. Human closure

The user approves the exact SHA.

ACT uses the protected closure capability to create:

~~~text
phase-<id>-closed
~~~

at that exact validated SHA.

Then verify the branch/tag pointer and protect it.

## 22. Resume after interruption

Phase Autopilot must be resumable.

On restart/reconnect:

~~~text
recover Phase Mission
→ reconcile integration HEAD
→ reconcile task graph
→ reconcile workflows
→ revoke stale leases
→ recover budgets/events
→ continue from next legal state
~~~

It must not require the user to reconstruct what happened manually.

## 23. Phase progress reporting

Agents may emit concise progress updates, but reporting must not become a control dependency.

The system continues automatically unless:

- governance requires human input;
- the user cancels/pauses;
- safety/security requires stop;
- control state is unavailable.

## 24. Preservation priority

If there is tension between adding the new phase and preserving frozen existing behavior:

~~~text
preserve the frozen baseline
→ escalate the conflict
→ never silently sacrifice old functionality to make new work pass
~~~

## 25. End-to-end phase success definition

The desired result is not "agents wrote all code".

The desired result is:

~~~text
new phase requirements satisfied
+ all previous frozen capabilities preserved or explicitly migrated
+ current and inherited gates green
+ no hidden regressions
+ exact status-bearing SHA independently validated
+ evidence complete
+ PDCA learning recorded
+ ACT_HUMAN_CLOSURE_PENDING reached
~~~

This is the strongest governable equivalent of "finish the phase perfectly".

Absolute defect-free software cannot be guaranteed, so operational proof remains dependent on the executable pilot and real validation evidence.


---

Governance version: **v1.0**  
Frozen source design SHA: `e938d777551166cc72a3627af5523706fafcc272`  
Normative closed branch: `agentic-pdca-governance-v1-closed`  
