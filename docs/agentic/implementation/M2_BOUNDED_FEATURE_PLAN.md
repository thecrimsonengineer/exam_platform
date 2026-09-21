# Agentic PDCA M2 Bounded Feature Plan

Status: PLAN_READY_FOR_HUMAN_FREEZE
Maturity target: M2 = DO-2 + CHECK-2/3 + ACT-2
Base branch: `agentic-pdca-m1-closed`
Exact base SHA: `d6a20c988027bdc25aeddc041cc16849bc259ad6`
Governance anchor: `43b2b3cc99839ae9de4092b4e2b7058d1964bff7`

## 1. Purpose

M2 proves that one authorized agent can implement a real bounded feature inside an explicit allow-list, validate the exact candidate independently, perform only budgeted bounded repairs, and stop before human-controlled phase closure.

M2 does not introduce phase-level autonomy, parallel writing agents, production deployment, autonomous merge, or autonomous closure.

## 2. Frozen maturity boundary

M2 may use:

- DO-2: feature code inside an approved allow-listed scope.
- CHECK-2: deterministic diff and integrity automation.
- CHECK-3: independent read-only agent review.
- ACT-2: bounded repair routing with lineage-owned budgets.

M2 must not use:

- DO-3 phase-task execution across several autonomous tasks.
- DO-4 parallel writing agents.
- CHECK-4 full autonomous evidence pipeline as a closure authority.
- ACT-3 quarantine/autonomy promotion as a general capability.
- autonomous production merge.
- autonomous phase closure.

Overall autonomy is capped at the weakest required control layer.

## 3. M1 capabilities inherited without redesign

M2 reuses the closed M1 controls:

- trusted repository adapter;
- canonical repository-relative path guard;
- exact base/candidate SHA binding;
- branch/lineage/lease/fencing validation;
- trusted fixed CHECK commands;
- analyzer policy: infos advisory, warnings/errors fatal;
- CHECK-2 protected-path, test-integrity, dependency and secret checks;
- fixed architecture gate;
- structured FORMAT execution;
- central process-lifetime repair budget semantics;
- retry versus repair distinction;
- human-controlled closure.

M2 must extend these controls rather than build parallel substitutes.

## 4. M2 success definition

M2 is successful only when all of the following are demonstrated:

1. A bounded feature task packet is machine-readable and exact-SHA bound.
2. A Builder can make feature-code changes only inside the packet allow-list.
3. Builder authority fails closed on scope expansion or protected-path access.
4. DO produces a complete clean handoff.
5. CHECK-2 derives repository facts independently.
6. CHECK-3 performs a separate read-only review of scope, architecture, test integrity, maintainability and evidence.
7. ACT-2 can route a bounded repair using the lineage budget.
8. Repair changes create a new candidate SHA and return through CHECK.
9. Exhausted or zero-budget classes escalate rather than self-expand scope.
10. At least one isolated governance-feature pilot completes end-to-end.
11. At least one real application bounded-feature pilot completes end-to-end under a separately approved task packet.
12. M0 and M1 regression suites remain green.
13. Final closure still stops at ACT_HUMAN_CLOSURE_PENDING.

## 5. M2 task packet

Introduce a canonical machine-readable M2 task packet.

Minimum fields:

- task_id
- lineage_id
- maturity
- governance_sha
- phase_base_sha
- task_base_sha
- branch
- feature_objective
- acceptance_criteria
- in_scope_requirements
- out_of_scope_requirements
- allowed_paths
- forbidden_paths
- protected_paths
- risk_class
- expected_changed_paths
- required_targeted_tests
- required_architecture_gates
- required_check_gates
- permitted_repair_classes
- repair_budgets
- dependencies
- stop_conditions
- expected_handoff
- human_approval_reference where required

Task packets are immutable once DO starts. Any scope expansion requires a new authorized packet/revision.

## 6. Token-minimal agent contract

Long governance text must not be repeated in normal Codex prompts.

Normal execution prompt should be reducible to:

```text
Task: <task_id>
Packet: <repo path>
Base: <exact SHA>
Role: Builder|Repairer|Reviewer
Execute packet exactly.
Stop on packet/governance conflict.
Return: candidate SHA + gates + evidence refs.
```

Agents read the canonical packet and referenced frozen governance from the repository.

If repository access is unavailable, the prompt must expand enough to preserve all safety-critical constraints and the user must be told token use is higher.

## 7. Risk classes for M2

Initial M2 autonomous feature execution is limited to bounded low/moderate engineering risk.

Allowed only when pre-authorized:

- isolated UI/state behavior with clear acceptance tests;
- deterministic local service/model behavior;
- non-security learning-flow logic;
- bounded diagnostics/tooling features;
- testable bug fixes with unambiguous expected behavior.

Automatically escalate:

- authentication or authorization;
- secrets;
- Firebase/Supabase rules or backend security;
- payment/billing;
- destructive data migrations;
- dependency/version changes unless explicitly pre-authorized;
- frozen architecture redesign;
- privacy/security controls;
- ambiguous product behavior;
- deployment/release;
- broad cross-feature refactor.

## 8. DO-2 Builder

Builder receives one approved task packet and one active writer lease.

Before mutation:

- exact base and branch must match;
- trusted repository facts must be clean;
- lineage and lease must match;
- fencing token must be current;
- task packet hash/revision must match;
- requested paths must be canonical and allowed.

Builder may:

- inspect bounded relevant context;
- edit allow-listed feature files;
- add/update task-specific tests within allow-list;
- run targeted tests;
- run M1 mechanical formatter;
- produce a candidate commit and clean handoff.

Builder may not:

- edit tests solely to make incorrect behavior pass;
- widen allowed paths;
- change dependency manifests unless packet explicitly allows it;
- modify frozen governance;
- merge to production;
- close M2.

## 9. Handoff contract

DO-2 handoff must contain:

- task ID;
- lineage ID;
- packet hash/revision;
- base SHA;
- candidate SHA;
- branch;
- commit list;
- changed-file inventory;
- diff statistics;
- targeted test commands/results;
- architecture gate results;
- known limitations;
- expected versus actual changed paths;
- clean worktree confirmation;
- evidence references.

Missing handoff fields result in CHECK_NOT_READY.

## 10. CHECK-2 reuse and extension

M2 keeps the trusted M1 CHECK-2 implementation.

Required automated facts:

- exact candidate HEAD;
- exact approved base;
- merge-base/ancestry;
- actual diff;
- canonical allow-list;
- protected paths;
- dirty paths;
- test additions/modifications/deletions/skips;
- assertion weakening indicators;
- dependency/config changes;
- secret-like material;
- unexpected binary/generated files;
- change-size/scope anomalies.

The Builder cannot supply authoritative repository facts.

## 11. CHECK-3 independent reviewer

Add a separate read-only reviewer contract.

Reviewer must not use Builder worktree state as authority.

Reviewer consumes:

- task packet;
- exact candidate SHA;
- trusted CHECK-2 evidence;
- diff;
- relevant architecture/specification;
- targeted/full gate evidence.

Reviewer evaluates:

- scope compliance;
- acceptance criteria;
- architecture consistency;
- test quality and integrity;
- regression risk;
- maintainability;
- evidence completeness;
- whether behavior change matches the task;
- whether any finding requires repair versus escalation.

Reviewer outputs structured findings and one state:

- REVIEW_ACCEPTED
- REVIEW_REPAIRABLE
- REVIEW_ESCALATE

Reviewer never edits code.

## 12. ACT-2 bounded repairs

ACT-2 owns the authoritative lineage repair budget.

Canonical v1 budgets remain authoritative:

- F1 Formatting: 5 mechanical
- F2 Analyzer/lint: 5 mechanical/bounded
- F3 Compile: 3 behavioral
- F4 Unit/product logic: 3 behavioral
- F5 Test harness: 3 behavioral plus test-integrity review
- F6 Architecture: 0 unless restoring an unambiguous frozen rule is explicitly authorized
- F7 Frozen regression: 2 only when cause is clearly inside current candidate
- F8 Dependency/config: 0 unless pre-authorized
- F9 Security/data: 0 normal repair
- F10 Ambiguous product behavior: 0

ACT-2 requirements:

- budgets belong to lineage;
- replacing the agent does not reset budget;
- retry uses same SHA and no behavioral budget;
- repair creates a new SHA;
- every repair records parent SHA, failure class, root cause, evidence, remaining budget and repair strategy;
- repeated identical failed strategies may escalate early;
- zero-budget classes escalate immediately;
- scope expansion always requires reauthorization.

## 13. Repairer

Repairer is a separate capability from Builder.

Repairer receives:

- exact failed candidate SHA;
- exact finding/failure class;
- remaining central budget;
- bounded allowed paths;
- authorized repair objective.

Repairer may only change what is necessary to resolve the finding.

It must not redesign the feature, broaden scope, weaken tests, or reset lineage.

## 14. M2 Pilot A: isolated governance feature

Before touching application feature code, prove DO-2/CHECK-3/ACT-2 using a bounded feature inside the Agentic PDCA subsystem.

Pilot A feature:

**M2 Task Packet Validator + Handoff Builder**

Scope:

- parse/validate canonical M2 task packets;
- validate required fields and exact SHA syntax;
- validate allow-list and forbidden-path consistency;
- generate deterministic handoff objects;
- reject scope contradictions;
- provide deterministic JSON serialization.

Initial allowed implementation paths:

- `tool/agentic_pdca/m2_*.dart`
- `test/agentic_pdca/m2_*.dart`
- `docs/agentic/implementation/m2/**`

No app code.

Pilot A must intentionally exercise at least one bounded repair loop before acceptance, using a controlled fixture/finding rather than manufacturing a false production defect.

## 15. M2 Pilot B: real application bounded feature

M2 cannot close on governance tooling alone.

After Pilot A passes, create one separate human-approved application task packet from an existing CSP11 requirement/backlog item.

Pilot B selection rules:

- small, independently testable;
- no auth/backend/security/database/dependency changes;
- no broad architecture redesign;
- narrow `lib/**` allow-list;
- clear acceptance criteria;
- existing or easily added targeted tests;
- reversible;
- no production deployment required.

Pilot B must demonstrate:

PLAN packet
→ DO-2 feature implementation
→ targeted tests
→ candidate SHA
→ trusted CHECK-2
→ independent CHECK-3
→ if needed ACT-2 bounded repair
→ REVIEW_ACCEPTED

Pilot B must stop before integration/production closure.

## 16. Branch/worktree model

One M2 task lineage has one writing branch/worktree and one active writer lease.

CHECK-3 uses a fresh read-only checkout or detached worktree at the exact candidate SHA.

Repair starts from the failed candidate SHA on the same authorized lineage unless ACT explicitly creates a bounded repair branch.

No parallel writing agents at M2.

## 17. Evidence and state machine

Canonical task flow:

```text
PLAN_APPROVED
→ DO_READY
→ DO_RUNNING
→ DO_HANDOFF
→ CHECK_NOT_READY | CHECK_RUNNING
→ CHECK_RED | CANDIDATE_GREEN
→ REVIEW_REPAIRABLE | REVIEW_ESCALATE | REVIEW_ACCEPTED
→ ACT_RETRY | ACT_REPAIR | ACT_ESCALATE
→ DO/CHECK loop
→ M2_REVIEW_READY
→ CHECK_FINAL_GREEN
→ ACT_CLOSURE_ELIGIBLE
→ ACT_HUMAN_CLOSURE_PENDING
→ HUMAN APPROVAL
→ ACT_CLOSED
```

No autonomous transition to ACT_CLOSED.

## 18. Proposed implementation runs

### M2-P0 — PLAN freeze

- freeze this plan after human approval;
- record exact plan SHA;
- no implementation.

### M2-1 — Task packet and manifest

Implement machine-readable packet model, validation and deterministic hashing.

### M2-2 — DO-2 bounded authority

Extend M1 authority from mechanical-only mutation to approved bounded feature paths and task packet binding.

### M2-3 — DO handoff

Implement deterministic handoff model and clean candidate requirements.

### M2-4 — CHECK-3 reviewer

Implement read-only reviewer packet, finding schema and reviewer state machine.

### M2-5 — ACT-2 repair controller

Implement authoritative bounded repair routing, budget consumption, repair lineage and fail-closed escalation.

### M2-6 — adversarial governance tests

Attack scope expansion, forged packet, stale approval, stale lease, budget reset, reviewer mutation, test weakening, wrong ancestry, branch races and evidence forgery.

### M2-7 — Pilot A

Run Task Packet Validator + Handoff Builder through complete M2 lifecycle.

### M2-8 — Pilot B authorization

Create and human-approve one real CSP11 application bounded-feature task packet.

### M2-9 — Pilot B execution

Run the real bounded feature through DO-2/CHECK-2/CHECK-3/ACT-2.

### M2-10 — phase finalization

Cross-state audit, fresh exact-SHA final validation, independent review, status-bearing SHA and human closure boundary.

## 19. Mandatory adversarial cases

M2 tests must include:

- forged task packet;
- packet changed after DO starts;
- wrong plan revision;
- wrong base/candidate SHA;
- unexpected ancestry;
- scope expansion;
- canonical-path traversal;
- protected path;
- unauthorized dependency change;
- deleted/skipped/weakened test;
- Builder attempting to mark its own review accepted;
- Reviewer attempting to mutate;
- stale lease/fencing token;
- branch race;
- retry incorrectly consuming repair budget;
- repair failing to consume budget;
- agent replacement attempting budget reset;
- zero-budget failure attempting repair;
- repeated failed repair strategy;
- repair changing unrelated files;
- candidate branch moving after CHECK;
- stale human approval;
- attempt to close without human approval.

## 20. Validation policy

Every candidate runs targeted validation first.

M2 final gates include:

```text
dart format --output=none --set-exit-if-changed <M2 changed Dart paths>
flutter test <targeted tests>
flutter test test/agentic_pdca/
flutter analyze --no-fatal-infos --fatal-warnings
fixed architecture gates
git diff --check
trusted CHECK-2 integrity scan
CHECK-3 independent review
```

For a real application Pilot B, the packet additionally lists feature-specific architecture and regression gates.

## 21. M2 closure predicate

M2 may reach ACT_HUMAN_CLOSURE_PENDING only when:

- all planned M2 control capabilities are implemented;
- Pilot A accepted;
- Pilot B accepted;
- CHECK-2 green;
- CHECK-3 REVIEW_ACCEPTED;
- ACT-2 repair ledger validated;
- M0/M1 regressions green;
- exact status-bearing SHA passes fresh final validation;
- ancestry valid;
- no unresolved hard finding;
- no unapproved finding;
- no blocking exception;
- no M3/M4 capability introduced;
- human closure approval is still pending.

Only explicit human approval bound to the exact final SHA permits creation/protection of `agentic-pdca-m2-closed`.

## 22. Stop conditions

Stop autonomous work immediately on:

- scope ambiguity;
- unexpected architecture requirement;
- dependency/config request not in packet;
- auth/security/backend/data mutation;
- protected/frozen path mutation;
- inability to obtain trusted repository facts;
- active writer conflict;
- stale/expired/revoked lease;
- repair-budget exhaustion;
- repeated failed repair strategy;
- test weakening;
- evidence-integrity incident;
- need for M3/M4 autonomy.

## 23. M2 output

The completed M2 maturity layer must leave:

- frozen M2 phase plan;
- canonical task packet format;
- DO-2 bounded feature authority;
- deterministic handoff;
- retained CHECK-2 trusted integrity;
- CHECK-3 independent read-only reviewer;
- ACT-2 central bounded repair controller;
- adversarial test suite;
- accepted isolated Pilot A;
- accepted real application Pilot B;
- exact final status-bearing SHA;
- human-controlled closed checkpoint.

No production merge is implied by M2 closure.
