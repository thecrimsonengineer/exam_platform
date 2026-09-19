# CSP11 Phase L4 — Learner Decision LAB Experience Freeze

## Status

**FROZEN / APPROVED FOR IMPLEMENTATION**

Phase: `L4`

Working branch: `phase-l4-learner-decision-lab`

Baseline branch: `fix-lab-player-mode-navigation`

Baseline commit: `5835ac14cf32f3283bea080299c1339b801df452`

This freeze defines the learner-facing Decision LAB experience and the future automated LAB quality/publish boundary.

The closed Phase L engine contract remains authoritative. Phase L4 must not redesign the deterministic LAB runtime, Story Gate priority rules, four-option decision contract, published-version immutability, or Learning Twin isolation boundary.

---

## 1. Learner Experience Principle

The learner experience shall remain simple and story-driven.

Target navigation:

`LAB -> Choose Scenario -> Scenario Briefing -> Choose Mode -> Decision -> Consequence -> Next Situation -> Ending -> Debrief -> Replay / Next LAB`

Engine concepts such as Story Gate IDs, internal state variables, route IDs, quality classifications, DQG300 status, validation coverage, or publish-gate internals are not learner-facing content.

---

## 2. Hidden Difficulty and Internal Quality Metadata

Difficulty is an internal authoring and validation property only.

Learners must not see:
- Easy / Medium / Hard / Ultra Hard labels
- DQG300 labels or scores
- internal decision-quality labels such as OPTIMAL / DEFENSIBLE / WEAK / CRITICAL
- internal route/gate names
- internal risk scores
- validation coverage or test status

Scenario cards may show learner-useful metadata such as:
- title
- short situation preview
- topic/hazard tags
- estimated duration
- decision count
- completion status when available

---

## 3. Phase L4A — Scenario Library

The Safety Decision LAB home becomes a learner-first scenario library.

Required behaviour:
- short plain-language explanation of the LAB
- compact expandable “How LAB works” guidance
- Available Scenarios presented prominently
- each scenario shown as a selectable card
- no difficulty field in learner UI
- scenario card opens that specific scenario
- architecture supports additional scenarios without new player logic

Scenario card learner fields:
- title
- short situation preview
- focus tags
- estimated duration
- decision count
- start/continue action when persistence exists

---

## 4. Phase L4B — Scenario Briefing

Selecting a scenario opens a briefing before mode selection.

Briefing shall explain:
- Your role
- Situation
- Your objective
- People involved
- What you know so far

The briefing must be short enough to scan on a phone.

Primary action:
`CONTINUE`

The learner shall not enter Decision 1 before passing through the briefing.

---

## 5. Phase L4C — Mode Selection After Briefing

Mode selection follows the briefing.

### Guided LAB
Plain-language description:
Learn while you practise. Feedback may be provided during the scenario.

### Professional LAB
Plain-language description:
Make decisions with limited guidance. Detailed feedback comes later.

### Assessment LAB
Plain-language description:
Complete the scenario independently. Feedback is provided after completion.

All three modes use the same deterministic authored scenario.

Mode changes presentation and feedback policy only. It must not create a separate story engine.

---

## 6. Phase L4D — Consistent Decision Screen

Every decision screen shall use the same learner-facing hierarchy:

1. `Decision X` or `Decision X of Y` when a reliable total is available
2. `What is happening now`
3. current authored situation text
4. optional `Current information`
5. `What would you do?`
6. exactly four actions
7. `CONFIRM DECISION`

Rules:
- learner may change the selected option before confirm
- confirmed decisions remain irreversible for that attempt
- no quality label is shown before or after selection in Professional or Assessment mode
- the screen must not reveal the internal Story Gate or route
- no learner-facing difficulty label

---

## 7. Phase L4E — Consequence Screen

A committed decision shall not jump invisibly to the next decision.

After commit, show a learner-facing consequence screen before continuing.

Required sections:
- `You decided`
- selected action text
- `What happened next`
- authored observable consequence
- `CONTINUE`

Mode policy:
- Guided may additionally show a short `Why this mattered` explanation
- Professional shows observable consequence without correct/incorrect signalling
- Assessment shows observable consequence without coaching or quality labels

The underlying engine still commits:
`Decision -> Option -> Consequence -> State Mutation -> Story Gate -> Next Node / Ending`

The consequence screen is a presentation layer over the already committed deterministic event. It must not change story truth.

---

## 8. Later L4 Scope — Frozen Direction, Not Part of L4A–L4E Implementation

### L4F — Observable scenario status
Learner-safe state only. Never show internal route/risk variables.

### L4G — Evidence inspection
Permit, gas test, isolation record, rescue plan and similar authored evidence.

### L4H — Playable poor decisions
Weak/critical choices continue into authored deterioration, recovery or emergency paths rather than quiz-style wrong-answer screens.

### L4I — Story endings
Narrative outcome, key turning point, journey summary and replay/debrief actions.

### L4J — Learner debrief
Outcome, decision timeline, turning points, strengths, risk-increasing decisions, recovery, patterns, competencies and next practice.

### L4K — DQG300-LAB
Internal publish-time decision-quality gate. Never learner-facing.

### L4L — Automated Decision LAB simulation tests
Every option must execute consequence, state mutation and Story Gate validation.

### L4M — Reachable-route exploration
Automated simulated learners exercise all reachable authored paths where practical and deterministic representative coverage where exhaustive traversal is not practical.

### L4N — Automated publish gate
Publish remains blocked until required structural, DQG300-LAB, consequence/state, Story Gate, route, ending, determinism, debrief and Learning Twin evidence tests pass.

Mandatory human approval is not required for publication. Manual preview remains available as a convenience.

### L4O — Published immutability
Runtime-significant changes create a new LAB version.

### L4P — Learning Twin evidence
LAB emits permitted learning evidence after decisions/completion. Learning Twin cannot change authored story truth.

---

## 9. Future Automated Publish Pipeline

Frozen target:

`AUTHOR -> CONTRACT VALIDATION -> DQG300-LAB -> CONSEQUENCE/STATE TESTS -> STORY GATE TESTS -> ROUTE EXPLORATION -> DETERMINISTIC REPLAY -> DEBRIEF VALIDATION -> LEARNING TWIN EVIDENCE VALIDATION -> PUBLISH`

Human review is not a mandatory gate.

All automated gates fail closed.

---

## 10. L4A–L4E Acceptance Criteria

L4A–L4E may be closed only when:

- Safety Decision LAB home is learner-facing
- scenario library is scenario-driven rather than hard-coded to a single player route
- learner difficulty text is absent
- scenario briefing exists before mode selection
- all three modes remain selectable
- Decision 1 cannot be reached without briefing and mode choice
- decision screen follows the frozen hierarchy
- exactly four options remain enforced by the Phase L engine
- learner can change selection before confirm
- confirmed decision remains irreversible
- a consequence screen appears after commit
- consequence screen continues to the engine-selected next node or ending
- Guided / Professional / Assessment consequence presentation follows the frozen mode policy
- current H2S reference LAB remains playable through the corrected v2 graph
- existing frozen Phase L tests remain green
- learner UI regression tests cover L4A–L4E
- Flutter analyze passes
- full repository regression passes
- Android debug build passes
- production web build passes
- diff hygiene passes

---

## 11. Out of Scope for This Checkpoint

The L4A–L4E checkpoint does not implement:
- DQG300-LAB itself
- exhaustive route exploration beyond existing Phase L validation
- new persistence/resume infrastructure
- Learning Twin evidence UI
- full L4J debrief redesign
- admin analytics
- scenario filtering/search
- cloud-published multi-scenario repository loading

Those remain later frozen L4 work and must not be silently pulled into L4A–L4E.

---

## 12. Frozen Learner Rule

**Keep the learner experience simple and story-driven. Keep DQG300, state mutation, Story Gates, route exploration, deterministic replay and validation complexity behind the curtain.**
