# CSP11 LSP-Q0 — Unified LAB Question Quality Contract Freeze

## Status

**FROZEN / APPROVED FOR IMPLEMENTATION**

Program: `LSP-Q` — LAB Scenario Population + Unified Question Quality

Checkpoint: `LSP-Q0`

Working branch: `phase-l4-scenario-population`

Baseline branch: `phase-l4-closed`

Baseline commit: `56cf3031709ca2ff9da81d48d8ede47bb589ee51`

This freeze extends the closed Phase L4 publication boundary without redesigning the deterministic LAB engine, learner Decision LAB experience, DQG300 contract, Story Gate rules, route-validation rules, published-version immutability, or Learning Twin isolation boundary.

The purpose of LSP-Q is to ensure that every authored LAB Decision Node is also a first-class CSP11 question for authoring and quality validation, while remaining a decision simulation rather than a quiz in the learner UI.

---

## 1. Frozen Core Rule

**No LAB Decision Node may be published unless its canonical question representation passes the normal CSP11 question parsing and quality path in addition to DQG300 and LAB1000.**

The frozen publication sequence is:

`LAB DECISION -> CANONICAL QUESTION PARSER -> QUESTION MODEL -> STRICT H0.3 QUESTION QUALITY -> DQG300 -> LAB1000 STRUCTURAL/ROUTE/EVIDENCE GATES -> PUBLISH`

All gates fail closed.

There is no manual override.

---

## 2. One Question Standard Across CSP11

Study, Practice, Ultra Hard and LAB Decision content shall use one canonical CSP11 question language.

A LAB Decision remains authored and executed as a deterministic LAB node, but before publication it must be convertible into the normal `Question` model.

The shared question requirements are:

- `questionType = scenario_mcq`
- `difficulty = Hard`
- cognitive level is `Application` or `Analysis`
- exactly four non-empty distinct options
- exactly one valid BEST answer
- meaningful scenario stem
- explanation required
- BEST-answer rationale required for LAB
- authoritative reference/source required
- at least two useful tags
- answer wording must not reveal the BEST answer through length bias
- option lengths must remain reasonably balanced

The LAB system must not maintain an easier parallel question standard.

---

## 3. Strict LAB Interpretation of H0.3

The existing normal question quality validator distinguishes errors and warnings.

For ordinary Studio authoring, some warnings may remain non-blocking.

For LAB publication, the frozen rule is stricter:

`H0.3 error -> BLOCK`

`H0.3 warning -> BLOCK`

Therefore a LAB Decision cannot publish with any of the following:

- missing or weak scenario stem
- wrong question type
- wrong cognitive level
- non-Hard difficulty
- fewer or more than four options
- empty options
- duplicate options
- missing or invalid BEST answer
- missing explanation
- weak explanation
- missing reference
- insufficient tags
- uniquely longest BEST answer
- excessive option-length imbalance

LAB publication requires zero normal-question errors and zero normal-question warnings.

---

## 4. Canonical Parser Architecture

The long-term parser architecture is frozen as:

`CanonicalQuestionParser`

with thin context adapters:

`CanonicalQuestionParser -> StudioQuestionImportService`

`CanonicalQuestionParser -> LabDecisionQuestionAdapter`

The canonical parser owns question field parsing and normalization.

It must not depend on:

- StudyContent
- StudyTopic
- StudySubtopic
- LAB runtime state
- Firebase
- Supabase
- UI state

Context-specific services attach placement and identity after canonical parsing.

This avoids maintaining separate parsing rules for Study questions and LAB questions.

---

## 5. LAB Decision Question Adapter

A dedicated `LabDecisionQuestionAdapter` shall convert one authored LAB Decision Node into a canonical CSP11 `Question`.

The representation shall include:

- deterministic internal question ID
- CSP domain
- canonical competency ID
- LAB-scoped quiz ID
- LAB content package ID
- decision prompt as question stem
- four option texts
- zero-based BEST answer index
- scenario-specific explanation
- scenario-specific BEST-answer rationale
- authoritative source/reference
- `Hard` difficulty
- `Application` or `Analysis` cognitive level
- `scenario_mcq` question type
- version
- useful tags

LAB decisions do not need fake Study Topic/Subtopic records merely to satisfy question parsing.

Topic and subtopic placement may remain empty unless an explicit future canonical LAB mapping is approved.

---

## 6. Scenario-Specific Explanation Rule

Generic placeholder explanations are not sufficient for publication.

The current internal fallback wording such as:

`Internal DQG300-LAB evidence supports the uniquely defensible BEST action.`

may remain useful for backward compatibility during migration, but it must not satisfy the final LSP-Q publication contract.

Every published LAB Decision must have:

1. a scenario-specific explanation explaining the technical reasoning, and
2. a scenario-specific BEST-answer rationale explaining why the BEST action is superior to the three expert near-miss alternatives.

The explanation and rationale must remain consistent with the authored Decision Node and pinned DQG300 evidence.

---

## 7. DQG300 Remains Mandatory

LSP-Q does not replace or weaken DQG300.

The two quality layers answer different questions:

**Normal CSP11 question gate**

`Is this a valid high-quality CSP scenario question?`

**DQG300**

`Is this an exceptionally difficult, evidence-backed decision question whose BEST-answer superiority is proved?`

A LAB Decision is publishable only if both pass.

Required DQG result per Decision Node:

- DQG-001 through DQG-299 pass
- derived DQG-300 passes
- DQS = 100/100
- zero unresolved blocks
- zero unresolved failures
- zero unresolved warnings
- no manual override
- decision signature matches the authored node
- evidence bundle is pinned to the same LAB ID/version

---

## 8. Unified Decision Quality Formula

For each LAB Decision:

`DecisionQualityPass = CanonicalParsePass && H0_3Errors == 0 && H0_3Warnings == 0 && DQG300Pass && DQS == 100`

For a LAB version:

`AllDecisionQualityPass = every authored Decision Node satisfies DecisionQualityPass`

Any failed Decision Node blocks the complete LAB version.

Partial publication is forbidden.

---

## 9. LAB1000 Publication Formula

The permanent target publication formula is:

`LAB_PUBLISHABLE =`

- technical contract valid
- learner presentation contract valid
- every Decision parsed by the normal canonical parser
- every Decision has zero H0.3 errors
- every Decision has zero H0.3 warnings
- every Decision passes DQG300 300/300
- every Decision has DQS 100/100
- DQG evidence is current and signature-pinned
- structural LAB validation passes
- exhaustive route validation passes
- reachable-route validation passes
- required ending coverage passes
- publish-evidence validation passes
- no manual override

All conditions are conjunctive.

---

## 10. Learner UI Boundary

Sharing the canonical question model is an authoring and publication-quality contract.

It does **not** turn the LAB learner experience into the normal MCQ screen.

The learner runtime remains:

`SCENARIO BRIEFING -> MODE -> DECISION -> CONSEQUENCE -> STATE MUTATION -> STORY GATE -> NEXT SITUATION / ENDING -> DEBRIEF`

The learner must not see:

- H0.3 labels
- DQG300 labels
- DQS
- OPTIMAL / DEFENSIBLE / WEAK / CRITICAL classifications
- parser status
- route IDs
- validation scores

The LAB remains a decision simulation.

---

## 11. Learner Presentation Contract

The separate presentation package remains presentation-only.

It may provide:

- role
- situation
- objective
- people involved
- known facts
- focus tags
- evidence display titles
- decision display titles
- observable consequence narration
- guided insight
- ending title
- ending narrative
- key turning point

It must never modify:

- Decision prompt
- option text
- BEST answer
- decision-quality classification
- consequence mechanics
- state mutation
- Story Gate logic
- ending mechanics
- DQG evidence
- authoritative source truth

Technical LAB content remains authoritative for story mechanics.

---

## 12. Current 10-LAB Batch Acceptance Target

The current scenario-population batch contains:

- 10 LAB packages
- 5 Decision Nodes per LAB
- 50 total LAB Decisions
- 200 total answer options
- 50 BEST answers
- 10 DQG300 evidence bundles
- 10 learner presentation records

Before publication the batch must reach:

### Normal question path

- 50/50 canonical parser PASS
- 50/50 `scenario_mcq`
- 50/50 Hard
- 50/50 Application/Analysis
- 50/50 exactly four options
- 50/50 exactly one BEST
- 50/50 explanation present and strong
- 50/50 BEST rationale present
- 50/50 reference present
- 50/50 tag coverage
- 50/50 answer-length checks PASS
- 0 H0.3 errors
- 0 H0.3 warnings

### DQG300

- 50/50 DQG decision reports PASS
- 14,950/14,950 atomic DQG rules PASS
- 50/50 derived DQG-300 PASS
- 50/50 DQS = 100/100
- 0 missing evidence
- 0 stale evidence
- 0 unexpected evidence

### LAB1000

- structural errors = 0
- structural warnings = 0
- unreachable required nodes = 0
- unreachable required endings = 0
- route failures = 0
- ambiguous Story Gates = 0
- publish-evidence failures = 0

### Presentation

- 10/10 LAB mappings
- 50/50 Decision mappings
- 200/200 consequence mappings
- 50/50 ending mappings
- required evidence mappings complete

Only then may the batch be marked publishable.

---

## 13. Duplicate and Identity Rules

Before publication the population batch must reject:

- duplicate LAB IDs
- duplicate LAB/version identities
- duplicate Decision IDs within one LAB
- duplicate option IDs within one Decision
- exact duplicate normalized Decision prompts where unintended
- exact duplicate option sets where unintended
- duplicate consequence IDs
- duplicate presentation mappings
- presentation IDs that do not exist in the technical LAB
- technical IDs without required presentation entries

Exact duplicates are blocking.

Semantic/near duplicates shall be surfaced for review. They do not silently pass.

---

## 14. Fail-Closed Migration Rule

Existing closed Phase L4 behavior remains valid until the LSP-Q implementation is complete.

During migration:

- do not weaken existing DQG300 rules
- do not weaken existing LAB1000 rules
- do not alter published-version immutability
- do not create a second runtime Question model
- do not create a second question-quality validator
- do not fabricate StudyContent hierarchy solely for LAB
- do not publish a LAB using a compatibility fallback that fails the new unified contract
- do not expose the 10 new LABs to learners until the complete LSP-Q acceptance boundary is green

---

## 15. Implementation Sequence

The approved implementation sequence is:

1. **LSP-Q0** — Freeze unified LAB question contract
2. **LSP-Q1** — Extract canonical question parser
3. **LSP-Q2** — Build LAB Decision Question Adapter
4. **LSP-Q3** — Replace generic explanation/rationale fallback
5. **LSP-Q4** — Run every LAB Decision through canonical parser
6. **LSP-Q5** — Add strict H0.3 normal-question gate
7. **LSP-Q6** — Combine normal gate + DQG300 into one decision-quality gate
8. **LSP-Q7** — Preserve DQG300 as stronger semantic layer
9. **LSP-Q8** — Validate learner presentation against technical LAB
10. **LSP-Q9** — Add scenario population manifest
11. **LSP-Q10** — Populate the ten current LABs
12. **LSP-Q11** — Cross-LAB duplicate audit
13. **LSP-Q12** — Integrate combined gate into LAB1000 publication
14. **LSP-Q13** — Update LAB1000 Admin status UI
15. **LSP-Q14** — Integrate learner runtime catalogue
16. **LSP-Q15** — Complete unified test matrix
17. **LSP-Q16** — Pass current 10-LAB batch acceptance gate
18. **LSP-Q17** — Platform and full regression closure
19. **LSP-Q18** — Freeze scenario-population checkpoint

Implementation must proceed in this order unless a later freeze explicitly changes the dependency graph.

---

## 16. LSP-Q0 Acceptance Criteria

LSP-Q0 is complete only when:

- `phase-l4-scenario-population` exists
- it was created from exact `phase-l4-closed` commit `56cf3031709ca2ff9da81d48d8ede47bb589ee51`
- this freeze document is committed on the population branch
- `phase-l4-closed` remains unchanged
- no runtime source file is modified by LSP-Q0
- no technical LAB package is published by LSP-Q0
- no learner catalogue entry is added by LSP-Q0
- the next authorized implementation action is LSP-Q1

---

## 17. Frozen Rule

**Every LAB Decision is both a deterministic story decision and a canonical CSP11 question for authoring quality. It must pass the normal CSP11 parser, zero-warning H0.3 validation, DQG300 and LAB1000 before publication. The learner still experiences a decision simulation, not a quiz.**
