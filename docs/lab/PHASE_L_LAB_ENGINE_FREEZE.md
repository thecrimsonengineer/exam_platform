# CSP11 Phase L — LAB Engine and LAB1000 Studio Freeze

## Status

**FROZEN / APPROVED FOR IMPLEMENTATION**

Phase: `L`

Working branch: `phase-l-lab-engine`

Baseline branch: `ui-glassmorphism-pass`

Baseline commit at freeze: `5176cff9bab33ebc4ed8124e98397298b9b1f651`

Final target: a deterministic Safety Decision LAB engine that can accept one validated JSON package, run it through the LAB engine and LAB1000 validation pipeline, expose it in a dedicated Admin LAB Studio, publish an immutable LAB version, and execute the story on the learner side.

No Phase L implementation is to be merged to production until the three Phase L closure steps are complete.

---

## 1. Product Navigation Freeze

The learner bottom navigation shall be reorganized as follows:

1. Home
2. Learn
3. Practice
4. LAB
5. Flashcards

LAB replaces the current Flashcards bottom-navigation position.

Flashcards moves into the current Progress bottom-navigation position.

The full Progress destination moves under Settings.

The dedicated Progress screens and analytics are not deleted. Existing useful progress/readiness summaries may remain available on Home or other approved surfaces.

Target Settings path:

`Settings -> Learning & Progress -> Full Progress`

LAB is therefore a first-class learner destination.

---

## 2. Core LAB Runtime Contract

The frozen runtime sequence is:

`SCENE -> DECISION -> OPTION -> CONSEQUENCE -> STATE MUTATION -> STORY GATE -> NEXT SCENE / EVENT / ENDING`

A selected answer must never directly hard-code the next question as the only story rule.

Each of the four options must first create an authored consequence and state effect. The Story Gate engine then evaluates the complete LAB state and determines what happens next.

Exactly four options are required for every standard Decision Node.

Exactly one option is the BEST answer.

Each option must also carry an internal decision-quality classification:

- `OPTIMAL`
- `DEFENSIBLE`
- `WEAK`
- `CRITICAL`

The quality label is an engine signal. It does not have to be shown during play.

---

## 3. Irreversible Decision Rule

A learner may change an option before confirming it.

After the learner presses the final decision action, the choice is committed and is irreversible for that LAB attempt.

The committed decision, consequence, state mutation, gate result, and next node must be written idempotently.

Closing and reopening the application must never permit the learner to rewind to a committed decision.

A learner may replay the complete LAB in a new attempt.

---

## 4. LAB State Model

Each LAB uses a typed state registry. A LAB imports only the variables it needs.

Supported state families include:

### Operational state
- work status
- isolation status
- equipment condition
- atmosphere condition
- process condition
- SIMOPS status
- permit status

### Risk state
- exposure risk
- fire risk
- process risk
- injury risk
- environmental risk

### People state
- workers exposed
- workers in hazard zone
- worker injured
- worker incapacitated
- supervisor trust
- worker confidence
- team compliance

### Organizational state
- production pressure
- schedule pressure
- communication quality
- supervision quality
- permit integrity
- contractor coordination
- management support

### Emergency state
- alarm active
- evacuation started
- rescue ready
- emergency services called
- scene controlled
- secondary casualty

### Learning state
The learning state is observational and must not corrupt the simulated workplace state.

It may include:
- hazard recognition evidence
- control-selection evidence
- information-gathering evidence
- risk-judgement evidence
- emergency-decision evidence
- recovery ability
- leadership-decision evidence
- confidence evidence
- decision latency
- mistake tags
- competency evidence

State variables may be Boolean, bounded numeric, enum, string identifier, or controlled list/set types defined by the LAB schema.

Runtime state must fail closed when a state mutation violates its declared type or allowed bound.

---

## 5. Story Flags and Irreversible Events

LABs may define Boolean or enum flags such as:

- `isolationVerified`
- `hotWorkActive`
- `gasTestCompleted`
- `continuousMonitoring`
- `entrantInside`
- `rescueTeamAvailable`

A LAB may also define irreversible event flags such as:

- `workerCollapsed`
- `secondaryCasualtyOccurred`
- `majorReleaseOccurred`

An irreversible event cannot be reset within the same attempt unless the LAB schema explicitly defines a different state transition that represents a later real-world condition rather than rewriting history.

---

## 6. Story Gate Types

Phase L freezes six primary gate types.

### Decision Gate
Blocks progression until one of exactly four valid options is confirmed.

### Consequence Gate
Executes the authored consequence and state mutations for the selected option exactly once.

### Route Gate
Evaluates the resulting LAB state and selects the next eligible story route.

### Critical Event Gate
Interrupts normal progression when a configured high-priority state combination requires an event such as exposure, collapse, fire, loss of containment, emergency evacuation, or secondary casualty.

### Convergence Gate
Allows multiple prior paths to converge into a shared later scene while preserving all accumulated state and history.

### Completion Gate
Terminates the attempt at an authored ending.

Initial ending families:

- `SAFE_COMPLETION`
- `CONTROLLED_RECOVERY`
- `INCIDENT_CONTAINED`
- `MAJOR_INCIDENT`
- `CRITICAL_FAILURE`

These describe the story outcome. They are not simple pass/fail labels.

---

## 7. Deterministic Gate Priority

Every gate has an explicit integer priority.

When more than one gate evaluates true, the highest-priority valid gate wins.

Equal-priority gates that can both evaluate true for the same reachable state are a validation error unless the schema explicitly marks the group as mutually exclusive and the validator proves it.

The same:

- LAB version
- starting state
- committed decisions
- evidence unlocks

must always produce the same story route.

No runtime LLM may invent the next story event in Phase L.

---

## 8. Recovery Path Rule

A wrong answer must not automatically terminate the LAB.

The learner should normally continue into a consequence, deterioration, correction opportunity, recovery decision, emergency branch, investigation branch, or authored ending.

Critical choices may create irreversible negative consequences.

The learner must still receive a valid playable continuation unless an explicit Completion Gate has been reached.

Frozen authoring rule:

**A published LAB must never depend on one particular answer being chosen in order to remain playable. All four options must produce a valid learning path.**

---

## 9. Evidence and Information Decisions

LABs may include information-gathering decisions where the learner chooses what evidence to request before making a later operational decision.

Evidence objects may include:

- SDS
- permit
- P&ID
- photograph
- risk assessment
- gas-monitor trend
- maintenance log
- inspection record
- email
- witness statement
- incident report
- exposure table
- floor plan
- training record

An option may unlock one or more evidence-object IDs.

Evidence unlocks become part of persistent LAB state.

---

## 10. Time and Characters

A LAB may maintain simulated time.

Options may advance time by different authored amounts.

Characters have stable IDs and may have state such as:

- trust
- cooperation
- knowledge
- exposure status
- injury status

Dialogue variants may depend on LAB state.

No free-form generative dialogue is required for Phase L.

---

## 11. JSON-First Authoring Contract

The long-term authoring goal is:

**One valid LAB JSON package -> LAB1000 Studio import -> validation -> preview -> review -> immutable publish -> learner runtime**

The JSON package is the authoritative portable representation for a LAB version.

Proposed top-level contract:

```json
{
  "schemaVersion": "csp11.lab.v1",
  "lab": {},
  "stateSchema": {},
  "characters": [],
  "evidence": [],
  "nodes": [],
  "gates": [],
  "endings": [],
  "competencyMappings": [],
  "sources": [],
  "debrief": {},
  "learningSignals": {}
}
```

Required LAB metadata shall include at minimum:

- lab ID
- version ID
- title
- description
- lifecycle status
- supported modes
- starting node ID
- starting state
- canonical competency mappings
- source/reference metadata
- schema version

Decision Nodes must contain exactly four options.

Every option must contain:

- option ID
- option text
- `isBest`
- decision-quality class
- consequence ID or consequence payload
- state mutations or explicit no-op declaration
- optional mistake tags
- optional competency evidence
- optional evidence unlocks
- optional simulated-time effect

Arbitrary executable Dart, JavaScript, shell code, expressions, or remote code are forbidden inside LAB JSON.

Gate conditions must use a constrained declarative condition model owned by the engine.

---

## 12. Single-JSON Boundary

A complete text-only LAB must be importable with one JSON file.

For media-based LABs, the JSON may reference approved asset IDs already available in CSP11 storage or bundled assets.

Binary media shall not be embedded into the JSON by default.

The JSON import must fail closed when it references an unavailable required asset.

---

## 13. LAB1000 Studio

A dedicated Admin-side destination shall be created:

**LAB1000 Studio**

Purpose:

- import a LAB JSON file
- paste LAB JSON
- create a new LAB draft
- inspect metadata
- inspect the state registry
- inspect characters
- inspect evidence
- inspect Scene Nodes
- inspect four-option Decision Nodes
- inspect consequences
- inspect state mutations
- inspect Story Gates
- inspect graph routes
- inspect endings
- inspect canonical competency mappings
- inspect references
- run validation
- run path simulation
- preview the LAB
- review validation evidence
- move lifecycle state
- publish an immutable LAB version

The Admin home shall expose LAB1000 Studio as a dedicated studio destination.

LAB1000 Studio is not the learner LAB player.

---

## 14. LAB1000 Import Pipeline

A JSON package shall travel through this pipeline:

1. Intake
2. UTF-8 / JSON decode
3. schema-version check
4. structural schema validation
5. canonical ID validation
6. state-schema validation
7. node-reference validation
8. four-option validation
9. BEST-answer uniqueness validation
10. consequence validation
11. mutation type/bound validation
12. gate-condition validation
13. gate-priority ambiguity validation
14. graph reachability analysis
15. orphan-node detection
16. dead-end detection
17. unsafe-cycle/infinite-loop detection
18. ending reachability validation
19. critical-event prerequisite validation
20. evidence/asset reference validation
21. competency mapping validation
22. source/reference validation
23. deterministic path simulation
24. preview creation
25. reviewer approval
26. publish gate

Any blocking failure prevents publish.

Warnings may be permitted only for explicitly non-blocking rules.

---

## 15. LAB1000 Path Simulation

The validator must combine static graph analysis with deterministic runtime simulation.

Static analysis is mandatory because a finite number of sampled runs alone cannot prove graph correctness.

For a normal LAB package, LAB1000 validation shall execute up to **1,000 deterministic path simulations** derived from:

- each option at each reachable Decision Node
- critical option combinations
- boundary state values
- route-gate boundary conditions
- convergence paths
- ending routes
- recovery routes
- known high-risk decision sequences
- seeded deterministic permutations for remaining coverage

If the complete reachable path space contains fewer than 1,000 unique meaningful traversals, the validator shall run the complete available matrix and report the exact number.

If the path space exceeds 1,000, static reachability validation remains exhaustive while the runtime traversal matrix is capped at 1,000 deterministic representative runs for the standard LAB1000 profile.

Future higher validation profiles may increase this cap without changing the LAB JSON contract.

---

## 16. Lifecycle and Immutability

LAB lifecycle:

`DRAFT -> REVIEW -> VALIDATED -> PUBLISHED`

A published LAB version is immutable.

Changing any runtime-significant field requires a new version.

Existing learner attempts retain the exact version ID used when the attempt began.

A published version must be reconstructible from its stored JSON package and version metadata.

---

## 17. Session Event Model

Each learner attempt creates a session containing at minimum:

- session ID
- user ID
- LAB ID
- LAB version ID
- mode
- started-at timestamp
- current node ID
- committed LAB state
- decision history
- evidence unlocked
- simulated time
- status
- ending ID when completed

Each committed decision creates an append-style event containing:

- node ID
- selected option
- optional confidence
- response time
- state before
- state delta
- state after
- consequence ID
- gate triggered
- next node ID
- simulated time
- event timestamp

The event model supports deterministic reconstruction.

---

## 18. Firebase Traffic Rule

Published LAB packages should be loaded in a coarse-grained manner rather than requiring a Firestore read for every Scene Node.

The preferred runtime model is:

1. load the published LAB package/version
2. run state mutations and Story Gates locally
3. persist compact session checkpoints/events
4. write completion and permitted Learning Twin evidence

This preserves the project's goal of reducing unnecessary Firebase traffic.

---

## 19. LAB Modes

The engine shall be capable of supporting:

### Guided LAB
May provide hints, learning feedback, concept reminders, and optional teaching material.

### Professional LAB
Default immersive mode. No live correct/incorrect signal. Consequences occur first. Full analysis appears in debrief.

### Assessment LAB
Controlled benchmarking mode with defined attempt and timing policies.

The same core engine must serve all modes.

Mode differences belong to presentation and feedback policy rather than separate story engines.

---

## 20. Learning Twin Boundary

The LAB Story Engine and the Learning Engine are separate systems.

The Story Engine determines what happens in the simulated world.

The Learning Engine interprets sanitized learner-behaviour evidence.

LAB may emit structured evidence such as:

- hazard recognition
- risk evaluation
- control selection
- information gathering
- emergency response
- recovery ability
- SIMOPS reasoning
- confidence calibration
- mistake DNA tags
- competency evidence
- response-time evidence

Learning Twin integration must not be allowed to modify authored story truth or gate selection.

---

## 21. Debrief Contract

The LAB debrief shall eventually support:

- chronological decision timeline
- consequence timeline
- gate/event timeline
- incident reconstruction
- key causal chain
- critical decisions
- recovery decisions
- competency evidence
- Mistake DNA signals
- source-backed explanations
- alternate authored timeline for selected decision points

Alternate timelines must be derived from authored graph logic and not invented after the event.

---

# 22. EXACT 1,000-TEST PHASE L BUDGET

The Phase L closure target is **exactly 1,000 automated tests attributable to LAB-0 through LAB-9**.

This is a source-code validation target for the engine and studio.

It is separate from the per-import LAB1000 path-simulation matrix described above.

## LAB-0 — Architecture, contracts and JSON schema
**50 tests**

Primary coverage:
- schema versioning
- canonical IDs
- node type contracts
- enums
- state variable definitions
- lifecycle definitions
- immutable version rules
- invalid contract rejection

## LAB-1 — Navigation and learner/Admin shells
**50 tests**

Primary coverage:
- LAB replaces Flashcards in bottom navigation
- Flashcards replaces Progress
- Progress moves under Settings
- learner LAB library/player routes
- Admin LAB1000 Studio route
- role boundaries
- light mode
- dark mode
- glass surface compatibility
- accessibility/navigation contracts

## LAB-2 — Core state and consequence engine
**150 tests**

Primary coverage:
- Boolean mutations
- bounded numeric mutations
- enum mutations
- set/list mutations
- invalid mutation rejection
- consequences
- evidence unlocks
- simulated time
- irreversible flags
- state snapshots
- idempotent mutation application
- state before/delta/after correctness

## LAB-3 — Story Gate evaluator
**170 tests**

Primary coverage:
- Decision Gates
- Consequence Gates
- Route Gates
- Critical Event Gates
- Convergence Gates
- Completion Gates
- Boolean predicates
- numeric comparisons
- enum predicates
- compound AND/OR rules
- priority resolution
- ambiguous-gate detection
- critical interruption
- deterministic replay
- convergence correctness
- ending selection

## LAB-4 — Session engine and persistence
**110 tests**

Primary coverage:
- new attempt
- commit decision
- irreversible choice
- duplicate submission protection
- checkpoint
- app close/resume
- session completion
- replay as new attempt
- version pinning
- event order
- offline interruption handling
- stale write handling
- idempotent transaction behaviour

## LAB-5 — LAB validation engine
**170 tests**

Primary coverage:
- exactly four options
- exactly one BEST answer
- every option has a consequence
- valid state references
- valid node references
- graph reachability
- orphan detection
- dead-end detection
- loop detection
- ending reachability
- gate ambiguity
- gate priority
- critical-event prerequisites
- unavailable evidence/assets
- invalid competency mapping
- invalid references
- fail-closed behaviour
- deterministic simulation preparation

## LAB-6 — LAB1000 Studio and JSON pipeline
**110 tests**

Primary coverage:
- file import
- paste import
- JSON decode
- schema errors
- validation report
- graph inspection
- Decision Node editing
- four-option editing
- consequence editing
- gate editing
- preview
- lifecycle transitions
- reviewer boundary
- publish gate
- immutable publish
- version creation
- Admin-only access
- valid single-JSON round trip

## LAB-7 — Learning Twin and analytics bridge
**60 tests**

Primary coverage:
- sanitized Decision Events
- competency evidence
- Mistake DNA tags
- confidence evidence
- recovery evidence
- response latency
- Story Engine isolation
- no reverse influence from Learning Twin
- failed/partial session rules
- event privacy boundaries

## LAB-8 — Debrief and reconstruction engine
**50 tests**

Primary coverage:
- timeline ordering
- consequence reconstruction
- gate reconstruction
- causal-chain rendering data
- alternate authored timeline
- critical-decision identification
- recovery-decision identification
- source/reference links
- incomplete-session behaviour
- deterministic reconstruction

## LAB-9 — Reference LAB and full end-to-end closure
**80 tests**

Primary coverage:
- one complete reference Safety Decision LAB
- JSON import -> LAB1000 validation -> publish
- published package -> learner load
- four-option decisions
- safe route
- weak route
- critical route
- recovery route
- convergence route
- all authored endings
- session resume
- debrief
- Learning Twin evidence
- light/dark learner UI
- Admin/learner boundary
- deterministic golden replay

### Total

`50 + 50 + 150 + 170 + 110 + 170 + 110 + 60 + 50 + 80 = 1,000 tests`

This allocation is FROZEN unless an implementation defect proves that a safety-critical area requires rebalancing. Rebalancing must preserve the final total of 1,000 Phase L tests or explicitly revise this freeze document.

---

# 23. THREE-STEP IMPLEMENTATION PLAN

Phase L shall be completed in three implementation/closure steps.

## STEP L1 — Foundation and deterministic runtime
Covers:

- LAB-0
- LAB-1
- LAB-2
- LAB-3

Test target:

**420 tests**

Deliverables:

- Phase L contracts
- LAB JSON v1 models
- navigation reorganization
- learner LAB shell
- Admin LAB1000 shell
- typed LAB state
- consequence engine
- all six Story Gate types
- deterministic priority resolution
- critical events
- convergence
- endings
- initial focused validation
- no runtime LLM

Closure checkpoint:

`phase-l1-closed`

No work on LAB-4 through LAB-9 is considered final until L1 is closed.

---

## STEP L2 — Sessions, validation and LAB1000 Studio
Covers:

- LAB-4
- LAB-5
- LAB-6

Test target:

**390 tests**

Deliverables:

- session engine
- irreversible committed decisions
- checkpoint/resume
- append-style Decision Events
- immutable version pinning
- complete LAB validation engine
- graph validation
- deterministic path simulation
- LAB1000 JSON import
- Admin Studio inspection/editing
- preview
- DRAFT -> REVIEW -> VALIDATED -> PUBLISHED
- immutable publish
- version creation

Closure checkpoint:

`phase-l2-closed`

At L2 closure, a valid single JSON file must be able to enter LAB1000 Studio and become a validated runnable LAB without hand-editing Dart code.

---

## STEP L3 — Intelligence, debrief and reference LAB
Covers:

- LAB-7
- LAB-8
- LAB-9

Test target:

**190 tests**

Deliverables:

- Learning Twin evidence bridge
- Mistake DNA signals
- recovery and confidence evidence
- deterministic debrief
- incident reconstruction
- alternate authored timeline
- first complete reference Safety Decision LAB
- end-to-end JSON -> Studio -> publish -> learner -> consequence -> gates -> ending -> debrief flow
- full 1,000-test closure suite

Closure checkpoint:

`phase-l3-closed`

Final Phase L recovery tag:

`phase-l-closed`

---

# 24. Reference LAB for LAB-9

The first reference implementation should be a high-quality confined-space / H2S / contractor / SIMOPS / emergency-response LAB because it exercises nearly every engine capability:

- permit review
- isolation
- evidence gathering
- atmospheric testing
- changing conditions
- hierarchy of controls
- contractor pressure
- SIMOPS
- alarm response
- evacuation
- rescue decision
- possible secondary casualty
- emergency management
- incident investigation
- corrective action
- recovery path
- multiple endings

The reference LAB must be implemented through the generic engine.

Scenario-specific Dart branching is forbidden.

---

# 25. Phase L Publish Gate

A Phase L implementation is not complete merely because `flutter test` passes.

Final closure must include, at minimum:

- exact Phase L branch ancestry check
- frozen-contract checks
- all 1,000 Phase L automated tests PASS
- existing repository tests PASS
- `flutter analyze --no-fatal-infos` PASS
- Android debug build PASS
- production web build PASS
- JSON golden import PASS
- LAB1000 validation PASS
- deterministic replay PASS
- learner/Admin permission boundary PASS
- no accidental production merge
- no runtime LLM dependency
- no executable code accepted from LAB JSON
- git diff/check hygiene
- frozen published-version immutability test PASS

Any failure blocks Phase L closure.

---

# 26. Non-Goals for Phase L

Phase L does not require:

- free-form AI-generated story branches
- voice actors
- 3D simulation
- multiplayer LABs
- live instructor intervention
- VR/AR
- automatic media generation
- arbitrary scripting inside JSON
- a second independent story engine
- replacement of the existing Quiz Engine
- merging Phase L to production before closure

These can be considered later without changing the Phase L core contract.

---

# 27. Frozen Architectural Sentence

Phase L shall preserve this architectural rule:

**A LAB is a deterministic, JSON-authored, four-option safety decision simulation in which each confirmed option creates an authored consequence and state mutation, the highest-priority valid Story Gate determines the next scene, every path remains playable until an authored ending, LAB1000 Studio validates and publishes immutable versions, and learner behaviour emits separate Learning Twin evidence without controlling story truth.**

---

# 28. Next Action

Begin **STEP L1** only.

Implement LAB-0 through LAB-3 against this frozen document.

Do not redesign LAB-4 through LAB-9 while L1 is in progress.

L1 must close with **420 Phase L tests** before moving to L2.

