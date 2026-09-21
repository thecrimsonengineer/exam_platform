# CSP11 Agentic PDCA System - PLAN v1.0

**Stage:** PLAN  
**Status:** FROZEN v1.0  
**Freeze state:** FROZEN v1.0


> Cross-PDCA consistency rule: this stage draft is governed by
> `CANONICAL_CONTROL_MODEL.md` for authority hierarchy, state
> ownership, repair budgets, approvals, validation tiers, and closure semantics.
> Where older draft wording conflicts with the canonical model, the canonical
> model is the preferred interpretation until freeze-ready consolidation.


## 1. Purpose

The agentic system exists to reduce repetitive engineering work in `thecrimsonengineer/exam_platform` while preserving or improving the reliability currently obtained through manual supervision.

Automation is introduced **inside existing controls**, not instead of controls.

The operating relationship is:

```text
Human architecture decision
        ↓
Frozen phase specification
        ↓
Agents execute
        ↓
Deterministic gates judge
        ↓
Agents repair bounded failures
        ↓
Independent review
        ↓
Human-controlled closure
```

Humans remain authoritative over architecture, scope, freezes, production merges, destructive actions, security-sensitive changes, and ambiguous product decisions.

## 2. Optimization order

The system optimizes for:

1. Preserve frozen rules.
2. Preserve correctness.
3. Preserve test integrity.
4. Preserve reversibility.
5. Preserve auditability.
6. Reduce human repetition.
7. Reduce CI cycles.
8. Reduce elapsed time.

Speed never outranks frozen rules, correctness, or validation integrity.

## 3. Authority hierarchy

When instructions conflict, use this precedence:

1. Frozen architecture and safety rules.
2. Frozen phase specification.
3. Global `AGENTS.md` policy.
4. Current approved task specification.
5. Existing deterministic tests and validation gates.
6. Repository conventions.
7. Agent implementation preference.

An agent may not reinterpret a higher-level rule to satisfy a lower-level preference.

## 4. Immutable and protected assets

Protected material includes:

- `phase-*-closed` branches
- frozen recovery tags
- approved freeze documents
- historical validation evidence
- architecture safety gates
- production branches
- security-sensitive configuration

Closed branches are read-only bases. Agents may inspect and branch from them but never mutate them.

## 5. Branch topology

Each phase has one authoritative integration branch and isolated agent branches.

Example:

```text
phase-fc8-hardening
        │
        ├── agent/fc8/builder/diag-01
        ├── agent/fc8/repair/diag-01-r1
        ├── agent/fc8/reviewer/diag-01
        └── agent/fc8/docs/status-01
```

No two writing agents should concurrently own the same working tree.

## 6. Agent roles

### Builder

Implements an approved frozen task inside an allow-listed scope.

### CI Repairer

Diagnoses and repairs bounded failures. It may not redefine requirements.

### Reviewer

Inspects diff, architecture, test integrity, and evidence. Read-only by default.

### Closer

Assembles status/evidence documents and closure candidates. It may not declare a phase closed.

Separation of roles is intentional.

## 7. Traceability

Every autonomous action must be reconstructable.

Required evidence should make it possible to answer:

- who/which agent produced the change;
- from which base SHA;
- for which task;
- why the change was made;
- which workflow/test triggered a repair;
- what validation was run;
- whether the action was autonomous or human-directed.

Recommended commit pattern:

```text
AGENT-BUILD FC8: ...
AGENT-REPAIR FC8: ...
AGENT-TEST FC8: ...
AGENT-DOC FC8: ...
```

## 8. Per-task change allow-list

Every task defines:

- allowed paths;
- conditionally allowed paths;
- forbidden paths.

Example:

```text
Allowed:
lib/features/flashcards/diagnostics/**
test/features/flashcards/diagnostics/**

Conditionally allowed:
lib/features/flashcards/flashcards.dart

Forbidden:
firebase/**
lib/features/lab/**
docs/*FREEZE*
phase-*-closed
```

Unexpected changed paths trigger review or rejection.

## 9. Risk classification

Use these planned risk levels:

- **R0 Read only** - inspection and diagnosis.
- **R1 Mechanical** - formatting, imports, deterministic generated output.
- **R2 Test harness** - viewport/timing/finder corrections without reducing behavior requirements.
- **R3 Feature implementation** - bounded production implementation.
- **R4 Architecture** - dependency direction, schemas, lifecycle, canonical boundaries.
- **R5 Security/data/infrastructure** - security rules, credentials, auth, deployment, backend infrastructure.

Planned autonomy:

- R0/R1: autonomous.
- R2: autonomous with evidence.
- R3: bounded autonomous.
- R4: human approval before implementation.
- R5: explicit human approval plus separate validation.

## 10. Failure taxonomy

Classify failures before repair:

- F1 Formatting.
- F2 Analyzer/lint.
- F3 Compile.
- F4 Unit-test logic.
- F5 Widget/test harness.
- F6 Architecture violation.
- F7 Frozen regression.
- F8 Dependency/configuration.
- F9 Security/data boundary.
- F10 Ambiguous product behavior.

Repair authority depends on failure class.

Typical policy:

- F1: fully autonomous.
- F2: usually autonomous.
- F3: autonomous if inside task scope.
- F4: bounded.
- F5: bounded and must justify why the harness is wrong.
- F6: stop and escalate.
- F7: stop unless clearly caused by current scoped implementation.
- F8: restricted.
- F9: human approval.
- F10: human decision.

## 11. Never weaken the gate

An agent may modify a test only when it can demonstrate that production behavior is correct and the test is asserting the wrong behavior or cannot reliably exercise the correct behavior.

High-scrutiny changes include:

- removing assertions;
- reducing expected values;
- deleting tests;
- skipping tests;
- increasing tolerances;
- removing architecture checks;
- changing expected exceptions;
- lowering quality thresholds;
- bypassing validation.

Green achieved by weakening a gate is a failure.

## 12. Retry budgets

Initial planned budgets:

- mechanical repair loops: up to 5;
- behavioral repair loops: up to 3;
- architecture repairs: 0 without approval.

Each repair must use new evidence. Repeating the same failed approach does not count as meaningful progress.

## 13. Targeted-first validation strategy

Repair and implementation should validate narrowly first:

```text
changed-area test
     ↓
format/analyze
     ↓
current-phase targeted gate
     ↓
full historical gate in CHECK
```

This avoids running the entire FC1→FCN suite for every trivial edit.

## 14. Dependency map

The system must preserve explicit dependency direction.

Example:

```text
FC7 integration layer
        ↓
FC4 collection services
        ↓
FC5 memory services

FC7 UI
        ↓
FC7 integration façade

Learning Twin
        ↓
sanitized Flashcard summary only
```

Forbidden shortcuts should be encoded as architecture tests where possible.

## 15. Agent Context Pack

Every task should receive a compact context pack containing:

- task ID;
- phase;
- current base SHA;
- goal;
- frozen rules;
- allowed paths;
- forbidden paths;
- relevant architecture;
- required tests;
- dependencies;
- next action;
- recent relevant failures;
- relevant documents/files.

Start narrow. Expand context only with evidence.

## 16. Handoff contracts

Builder handoff includes:

- base SHA;
- result SHA;
- changed files;
- requirements completed;
- tests run;
- known limitations;
- risks;
- recommended next gate.

Repair handoff includes:

- failed candidate SHA;
- workflow/job ID;
- failure class;
- log excerpt;
- repairs attempted;
- repair budget remaining.

Reviewer handoff includes:

- base vs candidate diff;
- validation evidence;
- architecture scan;
- test modifications;
- agent justifications.

## 17. Observability

Track from the first spike:

- task count;
- success count;
- failure class;
- repair attempts;
- targeted-test duration;
- full-CI duration;
- changed files/lines;
- test modifications;
- human escalations;
- rollbacks;
- policy violations.

The value of the agentic system should be measured, not assumed.

## 18. Cost controls

Track and limit:

- model usage;
- GitHub Actions minutes;
- backend calls;
- API requests;
- storage;
- number of concurrent agents;
- number of full CI reruns.

Prefer local deterministic tests, fixtures, in-memory repositories, and mocks before backend-connected validation.

## 19. Concurrency policy

Parallelize only tasks with independent write sets.

Safe example:

```text
Agent A -> diagnostics service
Agent B -> architecture tests
Agent C -> documentation
```

Unsafe example:

```text
Agent A -> quiz_screen.dart
Agent B -> quiz_screen.dart
```

Overlapping write sets should normally run sequentially or require explicit reconciliation.

## 20. Conflict resolution

Do not select a result merely because it is newer.

Compare candidates using:

- requirement satisfaction;
- tests;
- architecture impact;
- scope size;
- dependency additions;
- regression behavior;
- complexity.

Material architecture disagreement must escalate.

## 21. Rollback architecture

Every task starts from a known SHA. Agent branches are disposable.

If an agent branch becomes unsafe, discard it and return to the last accepted SHA.

Agents do not work directly on immutable checkpoints.

## 22. Closure conditions are defined at phase start

Before a phase starts, define:

- required tests;
- architecture gates;
- status document;
- ancestry requirements;
- regression suite;
- build/platform gates;
- exact-SHA validation.

The definition of closure is not invented near the end.

## 23. Green is not closed

```text
GREEN != CLOSED
```

Green means deterministic gates passed.

Closed requires:

```text
green
+ scope accepted
+ architecture accepted
+ evidence recorded
+ exact SHA identified
+ human freeze decision
```

Agents may produce green candidates. Agents may not autonomously declare a phase closed.

## 24. Adversarial validation before deployment

Before agents operate on a real active phase, deliberately test:

- formatter failure;
- missing import;
- widget below viewport;
- incorrect test expectation;
- real implementation defect;
- architecture violation;
- attempted closed-branch edit;
- prohibited Firebase import;
- temptation to weaken an assertion;
- two agents touching the same file.

Correct refusal/escalation is a successful outcome.

## 25. PLAN entry-to-DO gate

PLAN is ready only when the following are explicitly settled:

- purpose;
- authority hierarchy;
- roles;
- branch model;
- protected assets;
- allowed and forbidden actions;
- risk levels;
- failure taxonomy;
- repair authority;
- retry budgets;
- test strategy;
- dependency boundaries;
- concurrency;
- rollback;
- audit requirements;
- metrics;
- cost controls;
- escalation conditions;
- closure conditions.

PLAN is frozen under CSP11 Agentic PDCA Governance v1.0.

This document is frozen as part of CSP11 Agentic PDCA Governance v1.0.

## PDCA planning baseline and objective discipline

To conform fully to PDCA, PLAN must define not only authority but also the improvement objective and the basis for later comparison.

Every phase/task PLAN must include, where applicable:

~~~text
problem_statement
current_baseline
improvement_hypothesis
objective
target_metrics
acceptance_criteria
non_goals
risks
opportunities
resources
responsible_owner
dependencies
measurement_method
timebox_or_review_point
rollback_or_recovery_strategy
plan_revision
~~~

### Baseline

The current state is recorded before DO begins.

For the agentic system this may include:

- manual interventions per engineering task;
- full CI runs per task/phase;
- average repair loops;
- elapsed engineering time;
- GitHub Actions minutes;
- model/tool cost;
- regression/rollback rate;
- test-integrity findings;
- escaped defects;
- policy violations.

A PLAN without a meaningful baseline cannot later prove improvement.

### Improvement hypothesis

Where useful, express the change as:

~~~text
If <planned intervention>,
then <measurable outcome should improve>,
because <reason/mechanism>.
~~~

Example:

~~~text
If formatter/analyzer/targeted tests run inside DO before full CI,
then full CI cycles per repair should decrease,
because mechanical failures are removed before expensive regression gates.
~~~

### Objectives and targets

Objectives must be measurable where practical.

Examples:

- reduce manual CI polling;
- reduce formatter-only GitHub runs;
- preserve zero test weakening;
- preserve zero unauthorized closed-branch writes;
- reduce median repair cycles without increasing escaped defects.

### Risk and opportunity register

PLAN records both:

- risks that could make the change unsafe or ineffective; and
- opportunities that may improve speed, quality or maintainability.

Risks receive controls/owners where material.

### Resources and responsibilities

PLAN identifies the human/agent roles, required tools, expected compute/CI resources, and accountable human owner for approvals.

### Fixed criteria per PLAN revision

Success criteria are frozen for the active PLAN revision.

DO, CHECK and ACT may not move the goalposts mid-cycle.

If objectives, thresholds, scope or acceptance criteria materially change, create a new PLAN revision and re-baseline affected approvals/evidence as required by the Canonical Control Model.

### PLAN output

The authoritative PLAN output is a versioned baseline against which CHECK later compares actual performance.

PLAN therefore answers:

~~~text
What problem are we solving?
What result do we expect?
How will we measure it?
What could go wrong?
What resources and controls are required?
What will count as success?
~~~


---

Governance version: **v1.0**  
Frozen source design SHA: `e938d777551166cc72a3627af5523706fafcc272`  
Normative closed branch: `agentic-pdca-governance-v1-closed`  
