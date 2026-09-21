# CSP11 Agentic PDCA System - DO Draft

**Stage:** DO  
**Status:** Expanded draft  
**Freeze state:** NOT FROZEN


> Cross-PDCA consistency rule: this stage draft is governed by
> `PDCA_CANONICAL_CONTROL_MODEL_DRAFT.md` for task-state namespaces,
> DO_STOP_EVENT routing, repair lineage, branch ownership, integration tiers,
> and maturity coupling. Where older draft wording conflicts with the canonical
> model, the canonical model is the preferred interpretation until freeze-ready
> consolidation.


## Governing principle

PLAN defines authority. DO executes inside that authority.

DO may implement, run targeted validation, commit candidates, and produce evidence.

DO may not redefine scope, declare itself correct, declare a phase closed, bypass frozen rules, or broaden into architecture/security work without approval.

The execution chain is:

```text
Approved PLAN task
      ↓
Task packet
      ↓
Agent assignment
      ↓
Exact base SHA verification
      ↓
Isolated branch/worktree
      ↓
Pre-flight
      ↓
Implementation
      ↓
Targeted validation
      ↓
Atomic commit
      ↓
Self-check
      ↓
Handoff package
      ↓
CHECK
```

## 1. Executable task packet

DO starts only from an approved task packet containing at least:

- Task ID.
- Phase.
- Task title.
- Base branch.
- Exact base SHA.
- Goal.
- In-scope requirements.
- Out-of-scope requirements.
- Allowed paths.
- Forbidden paths.
- Risk classification.
- Required targeted tests.
- Required handoff evidence.
- Dependencies.
- Expected outputs.
- Stop conditions.

Vague instructions such as "continue FC8" are not sufficient for autonomous execution.

## 2. Exact SHA rule

Branches move. Every task therefore uses:

```text
base branch + exact base SHA
```

Before editing, verify branch, HEAD, clean status, and expected ancestry.

If the expected SHA is stale, stop or regenerate the task packet. Do not silently move to a newer base.

## 3. Closed branches are read-only

Never edit directly on `phase-*-closed`.

Use a closed branch only as a branch/worktree base.

## 4. Isolated agent branches

Recommended naming:

```text
agent/<phase>/<role>/<task-id>
```

Examples:

- `agent/fc8/builder/diag-01`
- `agent/fc8/repair/diag-01-r1`
- `agent/fc8/reviewer/diag-01`
- `agent/fc8/docs/status-01`

## 5. Isolated worktrees

Every writing agent receives a separate filesystem worktree.

Example:

```text
worktrees/
  fc8-diag-builder/
  fc8-tests-builder/
  fc8-review/
```

Agents do not repeatedly switch branches inside the same working directory.

## 6. Worktree pre-flight

Before editing:

```text
git branch --show-current
git rev-parse HEAD
git status --short
git log -1 --oneline
```

Expected:

- correct agent branch;
- exact approved base SHA;
- clean worktree;
- no unexpected staged/untracked inherited files.

A dirty startup worktree is a stop condition.

## 7. Permissions by role

### Builder

Read + scoped write + targeted tests.

### Repairer

Read + bounded repair write + targeted tests.

### Reviewer

Read + diff + tests. Read-only by default.

### Closer

Read + status/evidence document write.

No role receives broader permissions merely for convenience.

## 8. Bounded reconnaissance

Inspect only what the task requires:

- relevant files;
- interfaces;
- nearby tests;
- frozen documents;
- dependency boundaries;
- similar established implementations.

Start narrow and expand only for a documented reason.

## 9. Reuse before invention

Prefer established repositories, services, navigation, HAP/MOT primitives, canonical registries, and existing architecture boundaries.

Do not build parallel systems where frozen abstractions already solve the problem.

## 10. Pre-edit implementation intent

Before code changes, record:

- expected changed files;
- planned approach;
- expected tests;
- whether architecture change is expected.

Large divergence between predicted and actual scope triggers review.

## 11. Smallest complete change

Complete only the approved task.

Do not opportunistically refactor unrelated code, upgrade dependencies, rename adjacent APIs, or alter visual systems outside scope.

Log adjacent improvements separately.

## 12. Determinism

Prefer:

- canonical IDs;
- stable sorting;
- explicit timestamps;
- explicit seeds;
- deterministic fixtures.

Avoid hidden randomness, runtime AI decisions, timing-dependent behavior, and network-dependent tests unless explicitly required.

## 13. Product code vs test harness

Classify whether failure comes from implementation or harness.

Avoid changing production behavior and expectations simultaneously unless the task genuinely requires both.

Where useful, keep implementation and harness correction in separate atomic commits.

## 14. Targeted validation first

Run the smallest relevant gate after editing.

Typical sequence:

```text
dart format changed files
git diff --check
targeted analyze
targeted unit/widget test
targeted architecture test
```

Only a targeted-green candidate proceeds to broad CHECK.

## 15. Local formatting before CI

Canonical formatting happens before candidate handoff.

Formatter-only failures should rarely consume a full GitHub workflow once the agentic system is mature.

## 16. Static analysis before handoff

Run Flutter/Dart analysis appropriate to the task before producing a candidate.

Do not knowingly hand CHECK code with compile/analyzer errors.

## 17. Architecture tests before handoff

Map feature areas to required architecture gates.

Examples:

- Flashcards -> FC architecture tests.
- Learning Twin -> Twin isolation tests.
- LAB -> LAB architecture tests.
- Auth -> auth boundary tests.

## 18. Atomic commits

One commit represents one coherent engineering action.

Recommended pattern:

```text
AGENT-BUILD FC8: add diagnostics model
AGENT-BUILD FC8: add diagnostics validator
AGENT-TEST FC8: cover orphan review state
```

Avoid mixed unrelated commits.

## 19. Commit provenance

Commit body may include:

- Task ID.
- Base SHA.
- Risk level.
- Targeted tests.

This supports later audit and rollback.

## 20. No casual history rewriting

No force-push to shared phase/integration branches.

No destructive reset unless the task is explicitly a recovery operation.

Agent branches are disposable; integration branches are append-only by default.

## 21. Checkpoint commits

Long tasks should create meaningful stable checkpoints at significant milestones.

Examples:

- model complete;
- service complete;
- tests complete;
- integration complete.

## 22. Checkpoint before risky transformation

Before mass rename, schema migration, repository-wide generator change, or architecture refactor, create a clean checkpoint commit.

## 23. Parallelism uses write-set independence

Parallel work is allowed only when expected changed paths are materially independent.

If write sets overlap, run sequentially or explicitly reconcile.

## 24. Shared frozen base for independent tasks

Independent agents should branch from the same approved base SHA.

Dependent tasks must branch from accepted predecessor results rather than pretending to be parallel.

## 25. No blind merges

Agent results are compared before integration.

Semantic conflicts are never resolved using "latest wins."

## 26. Prefer accepted atomic cherry-picks

Accepted agent commits are normally cherry-picked into the phase integration branch.

Exploratory/failed branch history should not automatically enter the canonical phase branch.

## 27. Hard scope-change rule

If completion requires architecture changes, new backend behavior, or files outside the approved envelope, stop with:

```text
STOP-SCOPE
```

or the appropriate stop class.

DO does not broaden its own authority.

## 28. New dependency stop rule

A new Flutter/npm/GitHub Action/backend dependency requires explicit approval unless already authorized in PLAN.

Do not silently edit dependency manifests.

## 29. Security-sensitive stop rule

Normal feature agents may not change:

- Firebase rules/config;
- signing;
- OAuth configuration;
- secrets;
- workflow permissions;
- auth/security boundaries.

Use:

```text
STOP-SECURITY
```

and create a dedicated approved task.

## 30. Standard stop reasons

Use predictable categories:

- STOP-SCOPE.
- STOP-ARCH.
- STOP-DEPENDENCY.
- STOP-SECURITY.
- STOP-AMBIGUOUS.
- STOP-BASE.
- STOP-CONFLICT.
- STOP-TEST.
- STOP-BUDGET.

Correct safe stopping is a successful behavior.

## 31. Unexpected repository movement

If the authoritative branch moves during a task, do not silently rebase.

Finish the isolated candidate against its known base or stop for intentional reconciliation.

## 32. Architecture ambiguity

If two materially different valid designs require an architecture decision, stop and escalate.

DO agents implement approved architecture; they do not become the architecture authority.

## 33. Timeout behavior

On timeout, report:

- completed work;
- remaining work;
- blocker;
- current branch/SHA;
- tests run;
- dirty files if any.

Never claim completion for partial work.

## 34. Clean official handoff

Official handoff should normally require:

```text
git status --short
```

to be empty and all meaningful work committed.

## 35. Builder handoff schema

Include:

- Task ID.
- Base SHA.
- Result SHA.
- Changed files.
- Requirements completed.
- Tests.
- Architecture gates.
- Unresolved issues.
- Risk notes.
- Suggested CHECK scope.

## 36. Repairer handoff schema

Include:

- original Task ID;
- failed candidate SHA;
- workflow ID;
- failed job;
- failure class;
- log excerpt;
- previous attempts;
- remaining repair budget;
- protected paths.

## 37. Repair branches start from failed candidate

Repair branch bases on the failed candidate SHA, preserving already-accepted implementation work.

## 38. Reproduce failed test first

A Repairer first runs the exact failing targeted test/command.

It does not begin with the entire repository suite.

## 39. Repair root-cause statement

Every repair commit states the diagnosed root cause.

This is mandatory for test-only corrections.

## 40. Additional test-only repair check

Before handoff, answer:

- Why is production behavior correct?
- Why was the harness/assertion wrong?
- What evidence supports this?
- Did the repair reduce assertion strength?

If this cannot be answered, do not hand the repair to CHECK.

## 41. Preserve original failure evidence

Keep workflow ID, failed job, and relevant error in the repair record.

Do not overwrite the history of why a repair was necessary.

## 42. Prefer Git commits over patch files

When connected to GitHub, atomic commits are the primary artifact.

Patch files are reserved for offline/manual-transfer situations.

## 43. Follow repository structure

New code should follow established models/repositories/services/screens/tests organization.

Avoid dumping logic into vague utility files without an existing architectural pattern.

## 44. Maximum-change-size warning

If actual change scope materially exceeds the task prediction, trigger review.

Examples:

- expected 5 files, actual 30;
- expected 300 lines, actual 2,000.

## 45. Diff statistics before handoff

Report:

```text
git diff --stat BASE..HEAD
```

This gives CHECK immediate scale awareness.

## 46. Generated-file boundaries

Know which files are authoritative, generated, derived, frozen, or fixture-only.

Prefer modifying authoritative sources and regenerating rather than manually editing generated output.

## 47. Generator workflow

If a generator exists:

```text
modify authoritative source
→ run generator
→ validate generated result
→ run generator tests
```

## 48. Generator determinism

For critical generators, run twice and compare hashes/bytes when appropriate.

## 49. Backend minimization

Non-backend tasks use fixtures, mocks, in-memory repositories, and local deterministic tests.

Live backend calls require explicit task authority.

## 50. No ordinary testing with real user data

Use synthetic learner IDs, fixtures, and test packages.

Do not use production user data as routine agent test data.

## 51. Observation-only agents

Complex failures may first go to a read-only Diagnosis Agent.

Diagnosis can report root cause, affected files, recommended repair, and confidence before any writer is dispatched.

## 52. Dry-run mode

Support a mode where the agent may inspect, plan, identify files, and propose commands without writing.

Useful during early deployment and high-risk work.

## 53. Graduated DO autonomy

### DO-0 Observe
Read-only diagnosis.

### DO-1 Mechanical
Formatting/imports/simple analyzer and safe harness corrections.

### DO-2 Bounded implementation
Feature code inside allow-listed scope.

### DO-3 Phase task execution
Several approved tasks and structured handoffs.

### DO-4 Parallel orchestration
Multiple isolated agents and controlled integration.

Do not start deployment at DO-4.

## 54. Conservative initial concurrency

Start with at most:

```text
2 writing agents
+ 1 read-only reviewer
```

Increase only after conflict metrics show it is safe.

## 55. Dependency graph

The orchestrator maintains explicit task dependencies.

Example:

```text
A model
 ↓
B service
 ↓
C UI

D architecture tests ─┐
E docs ───────────────┴→ final integration
```

## 56. Explicit task states

Use:

- QUEUED.
- READY.
- RUNNING.
- BLOCKED.
- HANDOFF_READY.
- FAILED_SAFE.
- CANCELLED.

## 57. One authoritative integration branch

Each phase has one canonical integration branch.

Agent branches feed candidates into it.

## 58. Controlled integration

Only targeted-green, reviewed atomic commits enter the phase branch.

## 59. Lightweight smoke gate after integration

After each accepted cherry-pick, run a lightweight gate:

- format;
- analyze;
- current-phase targeted tests;
- relevant architecture tests.

Full historical validation belongs to CHECK.

## 60. Integration checkpoints

Record meaningful phase integration SHAs such as:

```text
FC8-A_COMPLETE
FC8-B_COMPLETE
FC8_INTEGRATION_CANDIDATE
```

These need not all be permanent tags, but they must be recoverable.

## 61. Conflict handling

Text conflicts may be reconciled only when semantics are clear.

Architectural conflicts use `STOP-CONFLICT`.

## 62. Safe cancellation

On cancellation:

- stop new task dispatch;
- finish current atomic operation safely;
- record current SHA;
- capture git status;
- preserve unfinished worktree;
- record remaining tasks.

## 63. Resume support

Resume from:

- Task ID;
- agent branch;
- last clean SHA;
- remaining work;
- last test result.

## 64. Tool failure safety

After a failed GitHub mutation call, verify whether the commit/branch update actually landed before retrying.

Never assume tool failure means repository state is unchanged.

## 65. Re-read head after mutation

After commit/push/branch update, read the authoritative branch head again.

This is mandatory in concurrent workflows.

## 66. Branch ownership verification

Before every branch mutation:

```text
expected HEAD == actual HEAD
```

If not, use `STOP-CONFLICT` or intentionally reconcile.

## 67. Compare-and-swap behavior

Prefer branch updates that are conditional on the expected current SHA, or emulate this with immediate head verification before mutation.

## 68. DO produces a candidate, not a verdict

Final DO statement is:

```text
Candidate produced.
Ready for CHECK.
```

not "phase passed" or "phase closed."

## 69. DO entry criteria

DO starts only when all exist:

- approved PLAN task;
- exact base SHA;
- allowed/forbidden paths;
- risk level;
- required tests;
- stop conditions;
- assigned role;
- clean isolated worktree;
- branch isolation.

## 70. DO exit criteria

A task becomes `HANDOFF_READY` only when:

- implementation is complete within scope;
- formatting passes;
- targeted analysis passes;
- required targeted tests pass;
- relevant architecture tests pass;
- worktree is clean;
- commits are atomic;
- result SHA is recorded;
- diff statistics are recorded;
- handoff package exists;
- known risks are documented.

## 71. Execution ledger

Record per task:

- Task ID;
- start time;
- role;
- base SHA;
- branch;
- worktree;
- commands;
- files changed;
- commits;
- tests;
- stop/retry events;
- final SHA;
- handoff status.

## 72. Canonical DO flow

```text
APPROVED PLAN TASK
        ↓
validate task packet
        ↓
verify exact base SHA
        ↓
isolated branch/worktree
        ↓
pre-flight
        ↓
bounded context
        ↓
implementation
        ↓
format
        ↓
targeted analysis
        ↓
targeted tests
      ┌─┴─┐
    green red
      │    │
      │    ├─ inside authority → repair → retest
      │    └─ outside authority → safe stop
      ↓
atomic commit
      ↓
self-check diff
      ↓
clean worktree
      ↓
handoff package
      ↓
CHECK
```

## 73. Safety philosophy

An agent stopping safely is better than an agent completing incorrectly.

Appropriate escalation is a quality signal, not a failure.

## 74. Speed philosophy

Speed comes from:

- isolated worktrees;
- narrow task packets;
- local formatting;
- targeted tests;
- parallel independent work;
- precomputed context;
- atomic commits;
- automated handoffs.

Speed does **not** come from skipping gates, weakening validation, or giving agents unrestricted write access.

## 75. DO acceptance gate

DO is ready for future freeze only when the following are settled:

- task packet schema;
- SHA rules;
- branch naming;
- worktree strategy;
- roles and permissions;
- context behavior;
- pre-flight;
- local validation;
- commit rules;
- checkpoint behavior;
- parallelism;
- dependency graph;
- integration strategy;
- repair entry;
- stop reasons;
- conflict handling;
- cancellation/resume;
- concurrent Git protection;
- handoff schema;
- execution ledger;
- entry criteria;
- exit criteria.

This document is currently **draft only**.

## PDCA execution and evidence discipline

DO executes the approved PLAN baseline. It does not redefine the objective or success criteria.

### Execute the planned intervention

DO performs only work authorized by the active PLAN revision/task packet.

If execution shows the plan is materially wrong, DO stops and routes the issue through ACT/PLAN revision rather than improvising a new objective.

### Collect execution data

In addition to code/test evidence, DO records process data needed for later PDCA comparison:

~~~text
start_time
end_time
agent_role
model/tool used where relevant
manual interventions
repair attempts
targeted test count/duration
full CI requests triggered
Actions minutes where available
files/lines changed
deviations_from_plan
resource/cost observations
unexpected effects
~~~

### Record deviations, do not normalize them

A deviation from PLAN is evidence.

DO records it explicitly.

DO may not silently treat the deviation as the new normal or retroactively rewrite PLAN.

### Verification inside DO is not CHECK

Formatting, targeted tests and local analysis inside DO are execution verification used for fast feedback.

They do not replace independent CHECK.

### Preserve the baseline

DO must retain enough evidence to compare:

~~~text
planned method
vs
actual method
~~~

and:

~~~text
planned resource/effort
vs
actual resource/effort
~~~

### DO output

DO answers:

~~~text
Did we execute the plan as authorized?
What actually happened during execution?
What data and deviations must CHECK evaluate?
~~~
