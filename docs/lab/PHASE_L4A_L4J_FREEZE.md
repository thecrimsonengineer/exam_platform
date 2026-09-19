# CSP11 Phase L4A-L4J Learner Decision LAB Freeze

## Status

**CLOSED / PASS**

Recovery branch: `phase-l4a-l4j-closed`

Frozen tested source SHA: `7449b2b4a75116d0c918ecb3dabd4bba4b8f990a`

Validation workflow: `Phase L4 Learner Decision LAB Validation`

Successful run: `35421635019`

Working branch after this freeze remains `phase-l4-learner-decision-lab`.

This checkpoint preserves the learner-facing Decision LAB experience completed through L4J. Phase L engine contracts remain frozen and authoritative.

## Validation evidence

The frozen tested source SHA passed:

- Flutter package resolution
- canonical Dart formatting
- `flutter analyze --no-fatal-infos`
- Phase L4 learner-experience regressions
- the unchanged frozen Phase L engine test directory containing the exact 1,000 Phase L tests
- full repository regression
- Android debug build
- production web build
- diff hygiene

No main-branch merge is part of this freeze.

## Frozen learner flow

`LAB -> Choose Scenario -> Scenario Briefing -> Choose Mode -> Decision -> Consequence -> Next Situation -> Ending -> Debrief -> Replay / Back`

## L4A — Scenario Library

Frozen learner-facing behaviour:

- Safety Decision LAB home is a scenario library.
- Scenario cards show title, short situation preview, learner-useful focus tags, estimated time and decision-count range.
- Learner-facing difficulty is prohibited.
- DQG300 status, DQ level, quality labels, route IDs, gate IDs and validation metadata are prohibited in learner UI.
- Architecture supports additional scenario definitions without a new player implementation.

## L4B — Scenario Briefing

Before mode selection the learner receives:

- Your role
- Situation
- Your objective
- People involved
- What you know so far

The briefing is part of the required learner route.

## L4C — Mode Selection

Mode selection occurs after the briefing.

- Guided LAB: feedback may be provided during the scenario.
- Professional LAB: observable consequences with limited guidance.
- Assessment LAB: independent attempt with feedback after completion.

All modes use the same deterministic authored story truth.

## L4D — Decision Screen

Frozen hierarchy:

1. Decision number
2. What is happening now
3. authored situation prompt
4. learner-safe contextual information
5. What would you do?
6. exactly four authored actions
7. CONFIRM DECISION

Selection may change before confirmation.

Confirmed decisions remain irreversible for the current attempt.

## L4E — Consequence Screen

Every committed decision pauses on a learner-facing consequence presentation.

Required learner content:

- You decided
- selected action
- What happened next
- authored observable consequence
- CONTINUE / SEE OUTCOME

Only Guided mode may show `Why this mattered`.

Professional and Assessment modes do not reveal option quality.

## L4F — Learner-Safe Situation Status

The player may expose observable status such as:

- permit verification
- isolation verification
- atmospheric-test verification
- rescue readiness
- scenario time

Internal values such as `risk`, `route`, Story Gate state and engine classifications are not learner-facing.

## L4G — Evidence Inspection

Unlocked authored evidence may be inspected in the scenario.

Reference scenario evidence includes:

- confined-space permit
- isolation record
- atmospheric test
- rescue plan

Evidence inspection is presentation-only. It does not alter deterministic story truth.

## L4H — Playable Poor Decisions

Weak or critical decisions do not become quiz-style WRONG screens.

They remain playable through authored consequences, deterioration, emergency, recovery or ending routes.

Engine-level regression proves the critical first decision can enter the authored emergency route without terminating the attempt incorrectly.

## L4I — Learner Endings

Reference ending families now have learner-facing narratives and key turning points:

- Safe completion
- Controlled recovery
- Incident contained
- Major incident
- Critical failure

The learner can see a human-readable decision journey without route IDs or internal quality labels.

## L4J — Learner Debrief

Frozen debrief sections include:

- Your outcome
- Your decision journey
- Important turning points
- What you handled well
- Where risk increased
- How you recovered
- Patterns noticed
- Competencies demonstrated
- References
- Explore another path / replay

The learner debrief must not display:

- OPTIMAL / DEFENSIBLE / WEAK / CRITICAL
- consequence IDs
- Story Gate IDs
- internal route IDs
- canonical competency codes such as `d07_c01`
- DQG300 or internal difficulty classification

## Hidden-quality rule

**Difficulty and DQG300 are internal authoring, validation and publishing concerns only. Learners never see them.**

## Next authorized work

Continue on `phase-l4-learner-decision-lab` from the frozen tested source SHA.

Next scope begins with:

- L4K: DQG300-LAB quality gate
- automated publish eligibility tests
- fail-closed decision-evidence coverage
- evidence pinning to immutable LAB version and exact decision content

Do not redesign L4A-L4J while implementing L4K.

Do not change the closed Phase L engine recovery points.

Do not merge to main.
