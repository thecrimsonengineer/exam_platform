# CSP11 Flashcard Core (FC) - Frozen Implementation Plan

## Status

**FROZEN / APPROVED FOR IMPLEMENTATION**

Working branch: `phase-fc-flashcard-core`

Frozen base branch: `phase-mot-closed`

Frozen base SHA: `6e5a0fd4e6fc6e66696e7bc03ba31542252f60ee`

Local-core closure branch: `phase-fc-closed`

Future cloud phase: `FCC - Flashcard Cloud & Publishing`

## 1. Product definition

CSP11 Flashcards are collectible concept cards and a long-term memory layer.

They are not miniature Quiz questions.

The learner-facing front of a Flashcard contains only a concept object such as a:

- term
- phrase
- acronym
- principle
- formula name
- threshold name
- process name
- classification
- control
- hazard
- model

The front must not contain an MCQ, question stem, answer options or a question-mark prompt.

The back contains the learning meaning and provenance.

The standard back is:

```text
DEFINITION / MEANING

WHY IT MATTERS

OPTIONAL KEY POINT

SOURCE
```

Source provenance is mandatory for factual learner cards before final FC closure. Detailed authority, copyright and verification rules are introduced in FC Run 2.

## 2. Core learning loop

The frozen learner loop is:

```text
Study / Quiz / Daily activity
        |
        v
Question completed or Daily Discovery claimed
        |
        v
Concept ID resolved
        |
        v
Canonical Flashcard resolved
        |
        +--> not owned -> UNLOCK
        |
        +--> already owned -> REINFORCE
        |
        v
Collection
        |
        v
First reveal of the card back
        |
        v
Memory scheduler becomes active
        |
        v
Later spaced review
```

Correct and incorrect MCQ completions may both unlock the mapped concept card.

An incorrect answer must not withhold a useful learning card.

Incorrect MCQ evidence may later raise review priority, but the Quiz engine must not directly calculate Flashcard due dates.

## 3. Frozen architecture: Question -> Concept -> Flashcard

The architectural relationship is:

```text
Question
   |
   v
Concept ID
   |
   v
Canonical Flashcard
```

Direct Question -> embedded Flashcard content is forbidden.

The Question model remains independent of Flashcard content.

A separate mapping boundary links Question IDs to Concept IDs.

Many questions may map to one Concept ID.

One canonical Concept maps to one canonical collectible Flashcard in FC V1.

Example:

```text
Q1001 ----+
Q1264 ----+--> csp11.concept.hierarchy_of_controls
Q2810 ----+              |
                          v
              csp11.flashcard.hierarchy_of_controls
```

This prevents thousands of duplicate cards when multiple MCQs test the same underlying concept.

## 4. Concept identity

Concept IDs are semantic and independent of visual placement.

Frozen format:

```text
csp11.concept.<semantic_slug>
```

Examples:

```text
csp11.concept.hierarchy_of_controls
csp11.concept.idlh
csp11.concept.local_exhaust_ventilation
csp11.concept.series_reliability
```

The semantic slug uses lowercase ASCII letters, digits and underscores.

A concept keeps a canonical CSP11 placement for collection grouping and may later gain additional placements if required.

## 5. Flashcard identity

Frozen format:

```text
csp11.flashcard.<semantic_slug>
```

The Flashcard slug must match the Concept slug in FC V1.

Therefore:

```text
csp11.concept.idlh
        |
        v
csp11.flashcard.idlh
```

Card identity is stable across wording improvements.

Material semantic change requires a new Concept/Card identity.

Wording-only improvement increments `version`.

## 6. Canonical placement

Every Concept and Flashcard carries CSP11 placement.

Required:

- domainId
- competencyId

Optional until real content integration in FC Run 7:

- topicId
- subtopicId

Domain and competency must resolve against the existing canonical CSP11 blueprint.

Topic and subtopic IDs must use canonical shapes when present.

Existence against real StudyContent is validated during FC Run 7.

## 7. Local deck identity

Competency deck format:

```text
dNN_cNN_flashcards_vN
```

Example:

```text
d03_c02_flashcards_v1
```

Decks are organizational packages.

Card identity does not depend on deck order.

## 8. Card lifecycle

FC local lifecycle is frozen as:

```text
candidate -> review -> validated -> bundled
```

The word `published` is reserved for future FCC cloud publishing.

A bundled card is packaged with the local application or local validated content package.

## 9. Collectible ownership versus review state

These are separate systems.

```text
COLLECTION
Do I own the card?

MEMORY
When should I see the card again?
```

A card may be:

- unowned
- owned but unseen
- owned and first-viewed
- due for review

The memory schedule must not begin until the learner has revealed the card back at least once.

## 10. MCQ reward behavior

Every eligible completed MCQ resolves through Concept mapping.

If the mapped card is not owned:

```text
NEW CONCEPT COLLECTED
```

If already owned:

```text
CONCEPT REINFORCED
```

No duplicate ownership record is created.

Unlock must be idempotent.

The reward presentation occurs only after ownership is safely committed locally.

## 11. Daily Discovery

FC includes a future local Daily Discovery channel.

Rules:

- deterministic for a learner and local calendar date
- selects only validated and eligible unowned cards
- never uses paid randomness
- no streak punishment
- reopening the same day produces the same offered card
- the card joins memory scheduling only after its back is first revealed

Daily Discovery implementation begins in FC Run 4.

## 12. Source provenance boundary

Run 1 reserves structured source references in the Flashcard schema.

Run 2 implements authoritative provenance.

Final FC rule:

**No factual learner card may reach the final validated/bundled state without at least one valid source.**

The learner must see the primary source on the card back.

Run 2 will freeze:

- authoritative U.S. source hierarchy
- Source Registry
- primary versus supporting source
- source locators
- regulatory versus agency versus technical definitions
- educational paraphrase labeling
- copyright mode
- source verification date/status
- source footer
- source details contract

## 13. Backend boundary

FC is a zero-backend implementation phase.

The following are forbidden from FC runtime/validation architecture:

- Firestore reads
- Firestore writes
- Firebase Storage access
- Firebase Auth initialization from FC tests
- Supabase reads
- Supabase writes
- network-driven runtime card generation
- runtime LLM card generation

FC may use the existing learner-local identity abstraction without importing Firebase into the FC feature.

## 14. Future FCC boundary

The following are deliberately deferred:

- cloud deck publishing
- remote Flashcard source registry
- remote Question/Concept mapping delivery
- immutable cloud package delivery
- cross-device collection synchronization
- cross-device review synchronization
- Firebase security rules
- remote authoring lifecycle
- cloud migration
- package manifest/version checks

These belong to `FCC - Flashcard Cloud & Publishing`.

FC models and repository interfaces must be designed so FCC can be added later without rewriting the scheduler or learner UI.

# 15. Eight implementation runs

## FC Run 1 - Architecture + Concept Registry

Purpose:

Freeze and implement the local semantic foundation.

Deliverables:

- frozen FC architecture
- Concept ID contract
- Flashcard ID contract
- Deck ID contract
- Flashcard type enum
- front-face non-question contract
- local lifecycle enum
- canonical placement model
- structured source-reference placeholder
- Flashcard model
- FlashcardDeck model
- FlashcardConcept model
- QuestionConceptMapping model
- Question -> Concept -> Flashcard catalog
- fail-closed duplicate/reference validation
- canonical Domain/Competency validation
- local JSON contract/fixture
- Run 1 architecture tests
- zero-backend enforcement

Checkpoint:

```text
FC1_ARCHITECTURE_GREEN
```

## FC Run 2 - Authoritative Sources + Provenance

Purpose:

Make sourcing a first-class content contract.

Deliverables:

- Source Registry
- source authority tiers
- source types
- definition modes
- copyright modes
- official-domain rules
- source verification status/date
- primary/supporting source rules
- source locator requirements
- federal/regulatory sourcing rules
- proprietary-source paraphrase rules
- visible source-footer model
- Source Details model
- provenance validator
- source fixture set

Checkpoint:

```text
FC2_PROVENANCE_GREEN
```

## FC Run 3 - FCQ + Local Content System

Purpose:

Create the deterministic local card/deck quality and repository system.

Deliverables:

- FCQ100 validator
- deck validator
- source validator integration
- duplicate card detection
- duplicate concept detection
- question/concept mapping validation
- JSON import
- JSON export
- local deck repository
- deck index
- local Flashcard Studio foundation
- reference deck
- mapping coverage reports

Checkpoint:

```text
FC3_CONTENT_GREEN
```

## FC Run 4 - Collectible Engine

Purpose:

Implement ownership and acquisition.

Deliverables:

- collection ownership model
- local collection repository
- unlock event model
- FlashcardUnlockService
- idempotent unlock
- new/unseen state
- first-view state
- concept reinforcement
- correct/incorrect reward signal
- deterministic Daily Discovery
- Daily Discovery state
- collection statistics

Checkpoint:

```text
FC4_COLLECTIBLES_GREEN
```

## FC Run 5 - Memory / Review Engine

Purpose:

Implement local long-term review.

Deliverables:

- review model
- review states
- Again / Hard / Got It
- deterministic interval policy
- due calculation
- first-view activation
- relearning
- weak-card policy
- session builder
- sibling/concept interleaving
- local sharded persistence
- interruption recovery
- memory statistics

Checkpoint:

```text
FC5_MEMORY_GREEN
```

## FC Run 6 - Learner Experience

Purpose:

Build the complete learner-facing collectible/review experience.

Deliverables:

- My Collection home
- Domain collection summaries
- Newly Collected inbox
- Daily Discovery UI
- collectible reveal
- concept-only card front
- card back
- persistent visible source footer
- Source Details sheet
- review player
- rating controls
- optional swipe controls with button alternatives
- HAP integration
- MOT integration
- reduced motion
- completion summary
- light/dark parity
- phone/tablet responsiveness

Checkpoint:

```text
FC6_LEARNER_UI_GREEN
```

## FC Run 7 - CSP11 Integration

Purpose:

Connect FC to existing CSP11 systems without making them dependent on FC internals.

Deliverables:

- Quiz completion hook
- Question -> Concept mapping coverage
- new-card/reinforcement presentation
- StudyContent entry points
- Domain/Competency/Subtopic review entry
- Learning Twin sanitized summary
- source-quality dashboard
- collection-quality dashboard
- Flashcard Diagnostics
- Admin local authoring/preview integration

Checkpoint:

```text
FC7_INTEGRATION_GREEN
```

## FC Run 8 - Hardening + Closure

Purpose:

Prove FC is stable and backend-independent.

Required closure matrix:

- source coverage
- source-reference integrity
- Question -> Concept mapping integrity
- Concept -> Flashcard integrity
- duplicate Concept prevention
- duplicate Flashcard prevention
- unlock idempotency
- Daily Discovery determinism
- no owned-card re-award
- scheduler determinism
- learner UID isolation
- app interruption recovery
- large deck behavior
- 360/390/412/430 px widths
- tablet behavior
- light/dark parity
- accessibility
- text scaling
- reduced motion
- HAP regressions
- MOT regressions
- full FC architecture enforcement
- full repository regression
- zero Firebase/Supabase proof

Final checkpoint:

```text
phase-fc-closed
```

# 16. Permanent architecture rules

1. Flashcard fronts are concepts/phrases, never learner questions.
2. Quiz and Flashcards communicate through Concept identity.
3. Question content does not embed Flashcard content.
4. Many questions may map to one Concept.
5. One Concept maps to one canonical collectible Flashcard in FC V1.
6. Collection ownership and memory scheduling remain separate.
7. Review scheduling is owned by FC, not Quiz, Learning Twin or UI.
8. UI does not write SharedPreferences directly.
9. UI does not calculate intervals.
10. HAP uses the frozen semantic haptic service.
11. MOT uses frozen MOT primitives.
12. FC feature code contains no Firebase or Supabase imports.
13. No runtime LLM invents Flashcard content.
14. Source provenance is mandatory before final learner-ready validation.
15. Future FCC adds cloud repositories behind interfaces rather than rewriting FC domain logic.

# 17. FC Run 1 acceptance criteria

Run 1 is complete only when:

- the freeze document exists on the FC branch
- Concept, Flashcard and Deck IDs have deterministic parsers/validators
- the Concept/Flashcard slug relationship is enforced
- card front types exclude question/MCQ types
- question-like front text is rejected by the Run 1 catalog boundary
- Domain and Competency placement resolve against the canonical CSP11 blueprint
- duplicate concepts fail closed
- duplicate cards fail closed
- duplicate Question mapping fails closed
- dangling Concept mapping fails closed
- dangling Concept -> Flashcard mapping fails closed
- a valid many-questions -> one-concept -> one-card case passes
- JSON round trips preserve the Run 1 contract
- Run 1 fixture parses successfully
- FC architecture tests prove no Firebase/Supabase import in the FC foundation
- no production Firebase/Supabase operation is executed
