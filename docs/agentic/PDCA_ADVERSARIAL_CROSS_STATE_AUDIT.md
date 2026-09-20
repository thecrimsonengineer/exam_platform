
# CSP11 Agentic PDCA System - Adversarial Cross-State Audit

Status: Final design stress-test draft completed  
Freeze state: NOT FROZEN  
Target: PLAN + DO + CHECK + ACT + Canonical Control Model

## Audit objective

The audit deliberately attempts to break the proposed governance system.

A scenario passes only when the design either:

1. prevents the unsafe action technically; or
2. fails closed into a deterministic state with preserved evidence.

"An agent is instructed not to do that" is not considered a sufficient defense for protected operations.

## Overall result

Thirty adversarial scenarios were exercised conceptually.

Initial result before hardening:

~~~text
PASS        13
PARTIAL     14
FAIL         3
~~~

After adding the adversarial hardening controls to the Canonical Control Model:

~~~text
PASS        30
PARTIAL      0
FAIL         0
~~~

This is a design-level result. It does not prove the future implementation is correct. The later agentic spike must convert these scenarios into executable adversarial tests.

## Scenario A01 - Duplicate CHECK event, same ID

Attack:
The same CHECK event is delivered twice because of webhook/retry behavior.

Risk:
ACT creates two repair tasks or consumes repair budget twice.

Existing defense:
Exact event-ID idempotency.

Result:
PASS.

Required invariant:
Same input event returns the original ACT decision.

## Scenario A02 - Duplicate CHECK result with different event IDs

Attack:
The same workflow/check result is emitted twice under two event IDs.

Risk:
Exact-ID dedupe is bypassed.

Initial result:
FAIL.

Improvement:
Semantic event deduplication key derived from source, task, lineage, candidate SHA, validation scope and workflow attempt.

Final result:
PASS.

## Scenario A03 - Out-of-order CHECK event

Attack:
Candidate B is current, but an old red/green event for candidate A arrives later.

Risk:
Old event rewinds or advances current lineage incorrectly.

Initial result:
PARTIAL.

Improvement:
Lineage generation and candidate sequence. Older events remain evidence but cannot mutate newer state.

Final result:
PASS.

## Scenario A04 - Two agents race to write the same branch

Attack:
Two writers both read HEAD X and attempt different commits.

Risk:
Lost update or branch overwrite.

Existing defense:
Single writer lease plus expected HEAD.

Improvement:
Add lease fencing token and serialized integration lease.

Final result:
PASS.

## Scenario A05 - Stale writer continues after lease expiry

Attack:
Agent A's lease expires. Agent B receives a new lease. Agent A still has local credentials and attempts another write.

Initial result:
FAIL.

Improvement:
Monotonic fencing tokens. Old token is rejected even if credentials remain valid.

Final result:
PASS.

## Scenario A06 - Simultaneous repairs spend the same last budget slot

Attack:
Two Repairers see one remaining attempt and both launch.

Initial result:
FAIL.

Improvement:
Atomic ACT repair-slot reservation and centralized lineage ledger.

Final result:
PASS.

## Scenario A07 - Two parallel repair hypotheses both become green

Attack:
Both branches pass targeted CHECK and each tries to enter integration.

Risk:
Conflicting "winners" or accidental double integration.

Improvement:
ACT selects one accepted lineage. Losing repair becomes superseded. Integration lease permits one integration mutation.

Result:
PASS.

## Scenario A08 - Candidate modifies the workflow that judges it

Attack:
Feature agent removes a failing CI step.

Existing defense:
Trusted Judge Set and Judge Change Task.

Improvement:
Trusted Judge Manifest anchored to a protected reference.

Result:
PASS.

## Scenario A09 - Candidate weakens a historical test but CI remains green

Attack:
A strict assertion is replaced with a loose assertion.

Existing defense:
Test-integrity scan.

Remaining risk:
If validator executes only the candidate-modified test, baseline behavior may disappear.

Improvement:
Trusted Judge Overlay runs trusted baseline judges against candidate production code in addition to integrity review of candidate tests.

Final result:
PASS.

## Scenario A10 - Candidate deletes a frozen architecture test

Attack:
Architecture guard disappears and all remaining tests pass.

Improvement:
Trusted Judge Manifest/Overlay plus deletion scan.

Result:
PASS.

## Scenario A11 - Compromised judge file without known provenance

Attack:
The validator sees a test/workflow but cannot prove which protected version it came from.

Initial result:
PARTIAL.

Improvement:
Judge provenance failure causes CHECK escalation/fail-closed.

Final result:
PASS.

## Scenario A12 - Wrong ancestry passes every test

Attack:
Candidate accidentally or deliberately contains unrelated commits, but code happens to pass.

Existing defense:
Approved base ancestry.

Remaining risk:
A malicious merge can still include approved base as an ancestor.

Improvement:
Verify expected merge-base, allowed parent graph and commit provenance for all commits between base and candidate.

Final result:
PASS.

## Scenario A13 - Stale human closure approval after candidate changes

Attack:
Human approves SHA A. Closer produces SHA B and reuses approval.

Existing defense:
Exact-SHA binding.

Result:
PASS.

## Scenario A14 - Approval revoked or expired before use

Attack:
Approval was valid when created but is revoked/expired before branch freeze.

Initial result:
PARTIAL.

Improvement:
Approval lifecycle with status/expiry/revocation checked at time of protected action.

Final result:
PASS.

## Scenario A15 - Approval from old PLAN/governance revision reused

Attack:
Architecture or governance assumptions changed after approval.

Initial result:
PARTIAL.

Improvement:
Bind approval to PLAN revision and governance version.

Final result:
PASS.

## Scenario A16 - Secret committed into candidate

Attack:
Agent accidentally commits active API credential.

Existing defense:
Secret scan, F9 incident path, quarantine.

Improvement:
Explicit secret-contaminated evidence handling and separate security storage.

Result:
PASS.

## Scenario A17 - Secret appears in CI log/artifact

Attack:
Even after source is fixed, logs keep redistributing the secret.

Initial result:
PARTIAL.

Improvement:
Do not forward raw contaminated logs to ordinary agents; rotate/revoke; sanitize normal evidence; quarantine contaminated artifacts.

Final result:
PASS.

## Scenario A18 - Malicious test weakening passes candidate tests

Attack:
Builder modifies both implementation and test to agree on weaker behavior.

Improvement:
Independent test-integrity analysis plus Trusted Judge Overlay.

Result:
PASS.

## Scenario A19 - Reviewer is secretly the same writer

Attack:
Builder opens a new session labelled "Reviewer" and self-approves.

Initial result:
PARTIAL.

Improvement:
Reviewer principal/session separation. Reviewer is read-only and distinct from active writer principal.

Final result:
PASS.

## Scenario A20 - Agent attempts to create phase-fc8-closed itself

Attack:
Agent bypasses ACT and creates closure branch.

Existing policy:
Human closure required.

Remaining risk:
Policy alone is insufficient if credentials permit the action.

Improvement:
Closure capability separation. Normal agents lack branch/tag closure permission. Protected closure principal requires exact-SHA human authorization.

Final result:
PASS.

## Scenario A21 - Rollback while Builder is still running

Attack:
ACT rolls integration back to known-good SHA while a Builder/Repairer from the old lineage finishes later.

Initial result:
PARTIAL.

Improvement:
Lineage epoch increment revokes stale leases, queued tasks, pending approvals and old candidate results.

Final result:
PASS.

## Scenario A22 - Stale repair arrives after rollback

Attack:
Old repair branch becomes green after rollback and attempts integration.

Improvement:
Old epoch candidate cannot mutate current lineage. It remains evidence only.

Result:
PASS.

## Scenario A23 - Cancellation arrives during an atomic Git mutation

Attack:
Stop is requested after mutation starts but before result is reported.

Initial result:
PARTIAL.

Improvement:
Soft stop finishes current atomic operation then revokes lease. Emergency stop revokes epoch immediately; late result fails fencing/epoch check before integration.

Final result:
PASS.

## Scenario A24 - Waiver expires after Review Accepted but before closure

Attack:
A temporary waiver was valid during review but expires before final freeze.

Initial result:
PARTIAL.

Improvement:
Waiver time-of-use validation at review, closure CHECK, closure predicate and immediate pre-freeze action.

Final result:
PASS.

## Scenario A25 - Agent changes its local clock to extend a waiver/lease

Attack:
Malicious/stale client timestamps claim validity.

Initial result:
PARTIAL.

Improvement:
Trusted server/control-plane time governs expiry.

Final result:
PASS.

## Scenario A26 - Control Plane is unavailable during protected mutation

Attack:
Writer cannot read lease/budget/approval state but tries "best effort" write.

Initial result:
PARTIAL.

Improvement:
Fail-closed invariant. Protected writes require authoritative control state.

Final result:
PASS.

## Scenario A27 - Control Plane restarts with stale state

Attack:
Old leases or workflow state are accidentally restored.

Improvement:
Recovery reconciliation with GitHub HEADs, workflow runs, lineage epochs and lease revocation before writers are re-enabled.

Result:
PASS.

## Scenario A28 - Integration race between two individually green tasks

Attack:
Task A and B are each TASK-CHECK-green from the same base and both try to update phase branch.

Existing defense:
Expected HEAD/CAS.

Improvement:
Dedicated integration lease serializes integration; second candidate is rebased/rechecked as required.

Result:
PASS.

## Scenario A29 - Branch protection or required checks are weakened externally

Attack:
A human/tool disables protection and an agent then performs an otherwise forbidden write.

Initial result:
PARTIAL.

Improvement:
Protection drift is a governance/security incident. Closure blocked until protection reconciled.

Final result:
PASS.

## Scenario A30 - Evidence artifact replaced after CHECK

Attack:
ACT references evidence that is later modified or overwritten.

Initial result:
PARTIAL.

Improvement:
Evidence hashes and immutable references. Mismatch invalidates evidence and forces revalidation/escalation.

Final result:
PASS.

# Cross-state illegal-transition probes

The following transitions must be rejected by the future Control Plane:

~~~text
CHECK_RED -> ACT_CLOSED
CHECK_REPAIRABLE -> ACT_CLOSURE_ELIGIBLE
TASK_RUNNING -> ACT_CLOSED
CHECK_CANDIDATE_GREEN -> ACT_CLOSED
CHECK_REVIEW_ACCEPTED -> ACT_CLOSED
ACT_CLOSURE_PREPARATION -> ACT_CLOSED
ACT_QUARANTINED -> phase integration
ACT_CANCELLED -> phase integration
old lineage epoch -> current integration
expired approval -> ACT_CLOSED
untrusted judge -> CHECK_FINAL_GREEN
~~~

# Required executable adversarial tests for the future spike

The future implementation should encode, at minimum:

1. duplicate event exact-ID replay;
2. duplicate semantic event with different IDs;
3. out-of-order event delivery;
4. writer lease race;
5. stale fencing token;
6. atomic repair-budget reservation;
7. dual green repair winner selection;
8. candidate workflow/test weakening;
9. trusted judge overlay;
10. wrong ancestry with passing tests;
11. approval expiry/revocation;
12. old governance-version approval replay;
13. secret in source;
14. secret in logs/artifacts;
15. same-principal self-review;
16. unauthorized close-branch attempt;
17. rollback invalidates active lineage;
18. late stale repair after rollback;
19. cancellation during mutation;
20. waiver expiry before freeze;
21. agent-clock manipulation;
22. Control Plane outage fail-closed;
23. Control Plane restart reconciliation;
24. concurrent phase integration;
25. branch-protection drift;
26. evidence artifact tampering.

# Stress-test conclusion

After the added hardening controls, the design has no known adversarial cross-state path that can legitimately transition an untrusted, stale, unreviewed, or unauthorized candidate into ACT_CLOSED.

This is still a design claim, not an implementation guarantee.

The next governance step is:

~~~text
consolidate freeze-ready PDCA Governance v1.0
→ human review
→ freeze governance
→ build M0 observation-only agentic spike
→ implement these adversarial scenarios as executable control-plane tests
~~~
