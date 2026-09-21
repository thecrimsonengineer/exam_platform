# CSP11 Agentic PDCA System - CHECK v1.0

**Stage:** CHECK  
**Status:** FROZEN v1.0  
**Freeze state:** FROZEN v1.0


> Cross-PDCA consistency rule: this stage draft is governed by
> `CANONICAL_CONTROL_MODEL.md` for CHECK state ownership, TASK /
> INTEGRATION / CLOSURE CHECK tiers, Trusted Judge Set rules, exception
> semantics, and final closure evidence. CHECK supplies validation facts;
> ACT alone computes closure eligibility. Where older wording conflicts with
> the canonical model, the canonical model is the preferred interpretation
> until freeze-ready consolidation.


## Governing principle

PLAN defines what is allowed. DO produces a candidate. CHECK independently determines whether that candidate is trustworthy.

An agent's own statement that tests passed has no authoritative value.

CHECK asks:

```text
Did an independent validation system verify
the exact candidate SHA
against frozen rules
using trusted gates
without the candidate modifying the judge?
```

The validation chain is:

```text
DO candidate
     ↓
exact SHA captured
     ↓
fresh independent environment
     ↓
scope + diff inspection
     ↓
test-integrity inspection
     ↓
architecture inspection
     ↓
security/dependency inspection
     ↓
targeted verification
     ↓
historical regression
     ↓
evidence verification
     ↓
independent quality assessment
     ↓
Candidate Green
     ↓
Independent Review
     ↓
Review Accepted
     ↓
status-bearing exact SHA validation
     ↓
Closure Eligible
```

The following states are deliberately distinct:

```text
Candidate Green
!= Review Accepted
!= Closure Eligible
!= Closed
```

## 1. Independence from DO

The Builder cannot be the authoritative validator of its own work.

Local Builder tests are useful feedback but are not authoritative CHECK evidence.

Preferred flow:

```text
Builder worktree
      ↓
candidate commit SHA
      ↓
fresh GitHub Actions runner
      ↓
CHECK
```

## 2. Exact candidate SHA

CHECK validates an immutable SHA, not an abstract moving branch.

Capture:

- candidate branch;
- candidate SHA;
- approved base SHA;
- workflow run ID.

If the branch moves after validation, the previous result applies only to the previous SHA.

## 3. New SHA invalidates previous approval

Every repository mutation creates a new CHECK identity.

Even documentation-only changes produce a new SHA.

Closure eligibility always attaches to the exact final status-bearing SHA.

## 4. Clean validation environment

CHECK should use a fresh checkout and must not rely on:

- Builder worktree state;
- untracked files;
- hidden generated artifacts;
- local configuration;
- undeclared environment dependencies.

## 5. Validator ownership

Feature agents may not quietly weaken the validator.

Changes to critical workflow gates are elevated-risk and require explicit authorization and separate review.

The system under test and the test authority must remain separated.

# Part A - Candidate Identity and Diff Control

## 6. Ancestry verification

Candidate must descend from the approved base SHA.

Unexpected commits from other experiments, phases, or production branches are a hard failure.

## 7. Complete changed-file inventory

Produce:

- changed files;
- added files;
- deleted files;
- renamed files;
- generated files;
- binary artifacts;
- diff statistics.

CHECK knows what changed before evaluating whether it works.

## 8. Allow-list enforcement

Compare actual diff to PLAN allow-list.

Unexpected paths cause:

```text
CHECK-SCOPE-FAIL
```

even if tests are green.

## 9. Conditional paths

Conditionally allowed files require a specific justification showing that the change was necessary and minimal.

## 10. Protected-path scan

Unexpected changes to protected material are a hard failure.

Examples:

- freeze documents;
- closure evidence;
- Firebase/security configuration;
- signing/auth configuration;
- workflow permissions.

## 11. Deletion review

Deletions receive higher scrutiny than additions.

Deleting tests, validators, architecture guards, registries, or security policy requires explicit approved reasoning.

## 12. Large-diff detection

Unexpected scope expansion triggers review.

Examples:

```text
planned 6 files → actual 49 files
planned 300 lines → actual 2,000 lines
```

# Part B - Test Integrity

## 13. Tests are controlled safety equipment

Passing tests are not meaningful if the candidate weakened the suite.

CHECK independently inspects test changes.

## 14. Test-delta report

Generate:

- tests added;
- tests modified;
- tests deleted;
- tests skipped;
- assertions added;
- assertions removed;
- thresholds changed.

## 15. Test deletion

Deleting tests is a high-risk event and normally produces:

```text
CHECK-TEST-INTEGRITY-FAIL
```

unless independently approved.

## 16. Skipped tests

Detect new skips, ignored tests, and bypass conditions.

Unapproved new skips are hard failures.

## 17. Assertion weakening

Flag transformations such as:

```text
exact equality → merely non-null
specific exception → throws anything
exact count → loose minimum
ordered result → unordered containment
```

## 18. Threshold reduction

Reducing quality thresholds to obtain green is test weakening.

This includes mapping coverage, FCQ/DQG scores, minimum counts, or validation severity.

## 19. Tolerance expansion

Large timeout, numerical tolerance, or allowed-failure increases require explicit justification.

## 20. Test-only fixes

If production code is unchanged while a test changes, CHECK requires:

- why production behavior is correct;
- why the harness/assertion was wrong;
- independent evidence;
- confirmation that behavioral strength was not reduced.

## 21. Harness correction preserves intent

Correcting a finder, viewport, Scrollable, timing primitive, or mock setup is acceptable only when the same behavior remains asserted.

## 22. Test/implementation correlation

Tests should exercise the behavior changed by the candidate.

Unrelated test edits are suspicious.

## 23. New behavior requires coverage

R3/R4 production behavior with no new or updated tests should normally fail review.

## 24. Negative paths

CHECK expects invalid-input/fail-closed coverage when relevant.

Examples:

- canonical ID conflict;
- missing source;
- orphan state;
- duplicate event;
- wrong learner identity;
- unauthorized lifecycle transition.

## 25. Idempotency tests

Event/retry/session/reward features require duplicate-delivery tests where appropriate.

## 26. Persistence reload tests

Persistence behavior should be tested across save/reload boundaries, not only in-memory execution.

## 27. Interruption tests

Crash/retry-safe workflows should simulate interruption between ordered persistence steps.

# Part C - Architecture Validation

## 28. Architecture gates are first-class

Dependency direction, ownership, isolation, lifecycle, and backend boundaries are correctness requirements.

Architecture violation is a hard failure.

## 29. Forbidden-import scanning

CHECK scans for imports forbidden by frozen architecture.

## 30. Persistence ownership

Enforce paths such as:

```text
UI → service → repository
```

and reject direct UI persistence when prohibited.

## 31. Business-rule ownership

Rules owned by one phase/service may not leak into another layer.

For example, UI may not recalculate FC5 review intervals.

## 32. Learning Twin sanitization

Twin-facing Flashcard integration must remain sanitized if frozen contract permits only counts/scope.

Raw definitions, question answers, source URLs, or detailed histories must not leak.

## 33. Canonical identity

Validate frozen identity schemes for Domain, Competency, Topic, Subtopic, Concept, Flashcard, Question, and Source.

## 34. Generated registry integrity

Generated output must correspond to authoritative source data.

## 35. Generator determinism

Critical generators may be run twice and compared byte-for-byte.

## 36. State-machine validation

Validate lifecycle transitions and reject forbidden jumps.

## 37. Immutability

Published/frozen objects remain immutable where required.

# Part D - Security, Dependencies and Infrastructure

## 38. Dependency manifest inspection

Unapproved dependency or workflow changes are hard failures.

Inspect:

- pubspec;
- lockfiles;
- Gradle/package manifests;
- GitHub Actions.

## 39. New dependency review

Independently assess necessity, existing alternatives, license, maintenance, security, platform impact, and bundle/resource impact.

## 40. Lockfile integrity

Manifest and lockfile changes must agree.

## 41. Secret scanning

Scan for API keys, tokens, passwords, private keys, service-account material, and credentials.

Any committed secret is a hard security failure.

## 42. Firebase resource boundary

Detect new Firestore/Firebase reads, listeners, queries, writes, or initialization.

## 43. Resource-impact inspection

Flag N+1 reads, listener-per-item designs, unbounded collection scans, and avoidable full reloads.

## 44. Local-only boundary

Introducing network/backend access into a frozen local-only feature is an architecture failure unless PLAN explicitly authorizes it.

## 45. Security-rule changes

Firebase/storage/auth rule changes require an elevated independent validation path.

## 46. Workflow permission changes

Detect increases in GitHub workflow permissions and require explicit approval.

# Part E - Agent Output Verification

## 47. Handoff vs Git

Never trust the handoff file list without independently comparing BASE..HEAD.

## 48. Claimed tests

Rerun required commands or use trusted recorded CI evidence.

Agent prose is not test evidence.

## 49. Claimed base

Verify ancestry proves the reported base SHA.

## 50. Risk classification

CHECK may override an agent's proposed risk level.

## 51. Governance compliance

If an agent continued after a mandatory stop condition, the candidate may fail governance even if technically correct.

## 52. Fresh-checkout dependency

Fresh CHECK must expose hidden reliance on untracked files, local config, or cached artifacts.

# Part F - Validation Ladder

## 53. Formatting

Canonical formatter must produce zero diff.

## 54. Static analysis

Run the frozen analyzer policy.

Agents may not lower analyzer standards to obtain green.

## 55. Targeted task tests

Run exact tests mapped to the task.

## 56. Feature/phase tests

Run all current feature/phase gates.

## 57. Architecture tests

Run architecture tests for affected modules.

## 58. Frozen historical regressions

For a later FC phase, run all frozen prior FC gates plus shared frozen systems such as MOT/HAP where relevant.

## 59. Cross-feature regression

Shared-file changes expand regression scope.

Example:

```text
QuizController change
→ Quiz tests
→ Quiz widgets
→ FC Quiz bridge tests
```

## 60. Build validation

Run Android/Web/Windows builds where the phase/risk matrix requires them.

## 61. Real-device validation

Require physical-device evidence for platform APIs, haptics, package behavior, or other device-specific concerns when necessary.

# Part G - Regression Strategy

## 62. Risk-based breadth

Not every low-risk documentation change needs every build, but minimum closure gates remain mandatory.

## 63. Shared-file expansion

Changes to shared components automatically widen regression scope.

## 64. Regression dependency map

Maintain a machine-readable relationship between shared files/modules and affected test suites.

## 65. Closed-phase baselines

Active phases may not modify frozen historical acceptance expectations without a separately approved migration.

## 66. Flaky-test detection

Alternating PASS/FAIL is not green.

Suspected flaky tests may require repeated targeted runs such as three consecutive passes.

## 67. Random seed evidence

Randomized tests should record/reuse seeds so failures are reproducible.

## 68. Timing tests

Prefer deterministic state completion, mock clocks, and pump-and-settle patterns over arbitrary long waits.

# Part H - Independent Quality Assessment

## 69. Quality score does not override hard gates

A 98/100 candidate with a security or architecture failure remains red.

The score is evaluated only after mandatory gates.

## 70. Proposed Independent Quality Index

| Category | Points |
|---|---:|
| Functional correctness | 25 |
| Test quality and integrity | 20 |
| Architecture compliance | 15 |
| Scope discipline | 10 |
| Security/dependency hygiene | 10 |
| Maintainability/readability | 10 |
| Determinism/reversibility | 5 |
| Evidence/audit quality | 5 |
| Total | 100 |

## 71. Functional correctness - 25

Evaluate requirement traceability, targeted tests, edge cases, failure paths, persistence, retry/idempotency, and state behavior.

## 72. Test quality and integrity - 20

Evaluate meaningful coverage, no weakening, no hidden skips, negative paths, reproducibility, and harness quality.

## 73. Architecture compliance - 15

Evaluate dependency direction, ownership, canonical IDs, backend boundaries, and lifecycle invariants.

Major architecture failure is a hard fail regardless of score.

## 74. Scope discipline - 10

Evaluate changed paths, unrelated refactors, churn, and PLAN compliance.

## 75. Security/dependency hygiene - 10

Evaluate secrets, workflow permissions, dependencies, backend/resource impact, and infrastructure changes.

Critical security issues are hard failures.

## 76. Maintainability - 10

Evaluate naming, cohesion, readability, duplication, repository conventions, and unnecessary abstractions.

## 77. Determinism/reversibility - 5

Evaluate deterministic behavior, stable generation/order, atomic commits, and rollback safety.

## 78. Evidence quality - 5

Evaluate SHA records, workflow IDs, test evidence, diff stats, handoff completeness, and root-cause records.

## 79. Authoritative scorer

Builder self-assessment is non-authoritative.

Authoritative assessment comes from automated CHECK collectors plus an independent Reviewer.

## 80. Evidence-driven scoring

Where possible, score constraints derive from machine evidence.

Example:

- test deletion caps test-integrity score;
- forbidden path is a hard scope fail;
- architecture-test failure is a hard architecture fail.

## 81. Initial thresholds

Proposed pilot thresholds:

```text
90-100  high-quality candidate
85-89   acceptable only with documented minor observations
<85     review not accepted
```

For closure eligibility:

```text
score >= 90
+ no hard-gate failure
+ no unresolved high-risk finding
```

Thresholds may be tuned using pilot data before freeze.

# Part I - Critical Validation States

## 82. Candidate Green

Candidate Green means the exact candidate SHA passed the required deterministic CI gates.

Typical requirements:

- formatting;
- analysis;
- targeted tests;
- current phase;
- architecture gates;
- required historical regressions.

Candidate Green does not mean independent scope/test/security review is accepted.

## 83. Review Accepted

Review Accepted means:

```text
Candidate Green
+ diff matches PLAN
+ test integrity accepted
+ architecture accepted
+ security/dependencies accepted
+ handoff verified
+ quality threshold met
+ no unresolved significant findings
```

## 84. Closure Eligible

Closure Eligible means:

```text
Review Accepted
+ phase acceptance complete
+ status/evidence document complete
+ correct ancestry
+ status-bearing SHA created
+ exact status-bearing SHA passes full final validation
+ no pending exceptions
```

The system may state:

```text
ELIGIBLE FOR HUMAN CLOSURE
```

but may not declare CLOSED.

## 85. Closed

Closed occurs only after authorized human freeze action creates/authorizes the immutable closure checkpoint.

# Part J - Exceptions and Waivers

## 86. Warning disposition

Every warning ends as:

- resolved;
- accepted observation;
- approved exception.

Never silently ignored.

## 87. Human authorization

Agents cannot grant themselves exceptions.

Exceptions require recorded human authorization.

## 88. Expiring waivers

Prefer scoped/expiring waivers such as "valid for FC8; revisit in FC9" over permanent ignores.

# Part K - Evidence Bundle

## 89. Structured evidence bundle

CHECK should eventually produce artifacts such as:

```text
candidate.json
diff_summary.json
test_integrity.json
architecture.json
security.json
regression.json
quality_score.json
review.json
```

Initial implementation may use Markdown/JSON.

## 90. Candidate evidence

Contains base/candidate SHA, branch, commits, changed files, and diff statistics.

## 91. CI evidence

Contains workflow IDs, job IDs, commands, results, and timestamps.

## 92. Test-integrity evidence

Contains test additions/modifications/deletions/skips/assertion/threshold changes.

## 93. Architecture evidence

Contains boundary, identity, lifecycle, forbidden-import, and generator checks.

## 94. Security evidence

Contains dependency, secret, workflow-permission, and backend-boundary checks.

## 95. Reviewer evidence

Contains reviewer identity, findings, quality score, exceptions, and Review Accepted result.

# Part L - Reviewer Independence

## 96. No self-review

Builder Agent A cannot be Reviewer Agent A for authoritative acceptance.

Reviewer is read-only by default.

## 97. High-risk human review

R4/R5 architecture/security/auth/backend changes require human review even if automated checks are green.

## 98. Reduce reviewer anchoring

Possible review sequence:

1. inspect raw diff and test evidence;
2. form preliminary findings;
3. read Builder rationale;
4. reconcile.

# Part M - Anti-Gaming Controls

## 99. Builder cannot write authoritative CHECK outcomes

Feature agents may not set their own quality score, Review Accepted state, or closure eligibility.

## 100. Protected CHECK status

Eventually authoritative CHECK states should be GitHub Checks/protected workflow metadata rather than editable feature-branch text.

## 101. PASS files are not evidence

A repository file named `PASS.md` or similar has no authoritative validation meaning.

# Part N - Failure Results

## 102. Standard CHECK failure classes

Use at least:

- CHECK-SCOPE-FAIL.
- CHECK-TEST-INTEGRITY-FAIL.
- CHECK-ARCH-FAIL.
- CHECK-SECURITY-FAIL.
- CHECK-REGRESSION-FAIL.
- CHECK-EVIDENCE-FAIL.
- CHECK-QUALITY-FAIL.

## 103. Repairability classification

CHECK classifies whether a failure appears repairable, escalatory, security-sensitive, flaky, or ambiguous.

ACT decides the subsequent response.

## 104. CHECK never repairs

CHECK identifies and records failures.

Repair returns to DO.

This preserves:

```text
CHECK identifies
→ DO repairs
→ CHECK revalidates
```

# Part O - Status-Bearing SHA Validation

## 105. Implementation green run

First implementation SHA may pass full validation.

This is evidence, not final closure evidence.

## 106. Status document creates a new SHA

Adding status/evidence documents creates a new repository state and therefore requires new validation.

## 107. Final closure evidence refers to final SHA

The closure record must reference the exact status-bearing SHA rather than only an earlier implementation SHA.

## 108. Final run ID

Record the final workflow run ID that validated the exact closure-eligible SHA.

# Part P - Performance and Resource Quality

## 109. Obvious performance regression

CHECK may inspect query count, read count, listener lifetime, cache behavior, loop complexity, and avoidable reloads for high-scale code.

## 110. Resource budgets

Where measurable, enforce rules such as:

- no N+1 query;
- no listener per Flashcard;
- no unbounded collection read;
- no full reload for single-item mutation without justification.

## 111. UI performance

Inspect rebuild storms, uncontrolled animation/controllers, and heavy synchronous work inside build methods where relevant.

# Part Q - CHECK Metrics

## 112. Effectiveness metrics

Track:

- candidates checked;
- Candidate Green rate;
- review rejection rate;
- test-integrity findings;
- architecture findings;
- security findings;
- false positives;
- flaky tests;
- average validation time.

## 113. Escaped defect metric

Track defects discovered after Review Accepted.

This is a critical long-term CHECK quality metric.

## 114. Agent-specific patterns

Repeated scope/test/architecture violations by a particular agent/model should reduce its future autonomy level.

# Part R - CHECK Rollout Levels

## 115. CHECK-0 Manual evidence

Human diff/tests/workflow review.

## 116. CHECK-1 Deterministic CI

Automate format, analysis, tests, and architecture gates.

## 117. CHECK-2 Diff and integrity automation

Add allow-list, protected-path, test-deletion, assertion, dependency, and secret scans.

## 118. CHECK-3 Independent agent review

Read-only reviewer analyzes scope, architecture, test integrity, maintainability, and evidence.

## 119. CHECK-4 Full evidence pipeline

Structured evidence bundle, independent scoring, and closure-eligibility support.

Do not deploy directly at CHECK-4.

# Part S - CHECK Entry Criteria

## 120. CHECK-NOT-READY

CHECK begins only when DO provides:

- Task ID;
- base SHA;
- candidate SHA;
- clean handoff;
- changed-file report;
- targeted tests;
- handoff evidence.

Missing required handoff produces CHECK-NOT-READY rather than a technical failure.

# Part T - CHECK Exit States

## 121. Allowed CHECK exit states

Use:

```text
CHECK_RED
CHECK_REPAIRABLE
CHECK_ESCALATE
CANDIDATE_GREEN
REVIEW_ACCEPTED
CLOSURE_ELIGIBLE
```

CLOSED is deliberately absent.

# Part U - Canonical CHECK Flow

```text
DO HANDOFF
    ↓
verify task/base/candidate SHA
    ↓
fresh checkout
    ↓
ancestry
    ↓
diff inventory
    ↓
allow-list / protected-path scan
    ↓
test-integrity scan
    ↓
dependency/security scan
    ↓
architecture checks
    ↓
targeted tests
    ↓
phase tests
    ↓
historical regressions
    ↓
build/device gates when required
    ↓
handoff verification
    ↓
independent quality assessment
    ↓
hard failure?
  ┌─────────────┐
 yes            no
  ↓              ↓
RED/ESCALATE   CANDIDATE_GREEN
                  ↓
           independent review
                  ↓
            REVIEW_ACCEPTED
                  ↓
          status/evidence commit
                  ↓
          exact SHA revalidation
                  ↓
           CLOSURE_ELIGIBLE
                  ↓
            human decision
```

# Part V - Adversarial Validation

Before trusting CHECK, deliberately test candidates where:

- all tests pass because a test was weakened;
- forbidden path changed;
- Firebase import added;
- dependency added;
- secret introduced;
- architecture violated;
- test deleted;
- test skipped;
- generated file manually altered;
- wrong ancestry used;
- Builder reports wrong base SHA;
- implementation SHA passes but later status SHA is unvalidated.

CHECK should catch every case before freeze.

# Part W - CHECK Acceptance Gate

CHECK is ready for future freeze only when these are settled:

- exact-SHA identity;
- fresh environment;
- validator independence;
- ancestry;
- diff allow-list;
- protected paths;
- change-size monitoring;
- test delta/integrity;
- assertion weakening;
- skip/deletion detection;
- architecture gates;
- identity/generator validation;
- dependency/security scanning;
- backend/resource boundaries;
- handoff verification;
- validation ladder;
- regression strategy;
- flaky-test policy;
- build/device gates;
- independent score;
- hard-gate overrides;
- Candidate Green definition;
- Review Accepted definition;
- Closure Eligible definition;
- exception/waiver policy;
- evidence bundle;
- reviewer independence;
- final status-bearing SHA rerun;
- CHECK metrics;
- failure taxonomy;
- entry criteria;
- exit states.

This document is frozen as part of CSP11 Agentic PDCA Governance v1.0.

## PDCA plan-to-result comparison

CHECK must evaluate both conformance and effectiveness.

Passing CI alone is not sufficient to prove the PDCA objective was achieved.

### Plan-to-evidence traceability

For every material PLAN objective/acceptance criterion, CHECK produces a traceability entry:

~~~text
plan_requirement_id
planned_objective_or_criterion
baseline
target
actual_result
evidence_reference
result: PASS / FAIL / NOT_MEASURED
finding
~~~

No material PLAN criterion should disappear between PLAN and CHECK.

### Three CHECK questions

CHECK evaluates:

1. **Conformance** - Did DO follow the approved PLAN, governance and technical rules?
2. **Effectiveness** - Did the intervention achieve the intended outcome?
3. **Efficiency** - Did it improve the process without disproportionate cost, churn or resource use?

### Compare actual performance to baseline

For the agentic system, CHECK may compare:

- manual interventions before vs after;
- full CI runs before vs after;
- repair-loop count;
- elapsed time;
- Actions minutes;
- model/tool cost;
- rollback/rework rate;
- escaped defects;
- policy violations;
- review rejection rate.

### Unintended consequences

CHECK explicitly looks for side effects that were not part of the target.

Examples:

- faster CI but more escaped defects;
- fewer manual steps but more scope violations;
- fewer Actions runs but much higher model cost;
- faster implementation but weaker maintainability.

A target is not considered successful if unacceptable unintended effects outweigh the improvement.

### Missing measurement

If a planned metric cannot be measured, CHECK records NOT_MEASURED.

It must not silently infer success.

ACT then decides whether more evidence is needed, the metric should be revised in the next PLAN, or the cycle can proceed with an approved limitation.

### CHECK output

CHECK answers:

~~~text
Did we do what we planned?
Did it work?
Did it work safely?
Did it work efficiently?
What evidence supports that conclusion?
~~~


---

Governance version: **v1.0**  
Frozen source design SHA: `e938d777551166cc72a3627af5523706fafcc272`  
Normative closed branch: `agentic-pdca-governance-v1-closed`  
