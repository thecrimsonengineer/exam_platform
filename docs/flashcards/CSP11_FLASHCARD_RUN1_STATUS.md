# CSP11 Flashcard Core - FC Run 1 Status

**Phase:** FC - Flashcard Core  
**Run:** 1 of 8  
**Branch:** `phase-fc-flashcard-core`  
**Frozen base:** `phase-mot-closed` at `6e5a0fd4e6fc6e66696e7bc03ba31542252f60ee`  
**Checkpoint name:** `FC1_ARCHITECTURE_GREEN`  
**Backend access:** Zero Firebase / zero Supabase by design and validation.

## Run 1 purpose

Run 1 establishes the semantic layer that separates Quiz questions from collectible Flashcards.

The frozen relationship is:

```text
Question ID
    |
    v
Concept ID
    |
    v
Canonical Flashcard
```

Questions do not embed Flashcard content.

Many questions may map to one Concept.

One Concept owns one canonical collectible Flashcard in FC V1.

## Implemented

### Semantic identities

Concept IDs:

```text
csp11.concept.<semantic_slug>
```

Flashcard IDs:

```text
csp11.flashcard.<semantic_slug>
```

FC V1 requires the semantic slug to match.

Deck IDs:

```text
dNN_cNN_flashcards_vN
```

### Models

Run 1 adds:

- `Flashcard`
- `FlashcardConcept`
- `FlashcardDeck`
- `FlashcardPlacement`
- `FlashcardSourceRef`
- `QuestionConceptMapping`
- `FlashcardType`
- `FlashcardLifecycle`

The local lifecycle is:

```text
candidate -> review -> validated -> bundled
```

Cloud `published` state is intentionally excluded from FC.

### Front-face contract

Flashcard fronts are concept objects, not learner questions.

Allowed types include:

- concept
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

The Run 1 catalog rejects question-mark front labels.

Full linguistic/card-quality validation is reserved for FCQ in Run 3.

### Canonical placement

Domain and Competency IDs are validated against the existing generated CSP11 blueprint.

Topic/Subtopic IDs are shape-validated when present.

Real StudyContent existence validation is reserved for FC Run 7 integration.

### Concept catalog

`FlashcardConceptCatalog` fails closed on:

- duplicate Concept IDs
- duplicate Flashcard IDs
- duplicate Question mappings
- dangling Question -> Concept references
- dangling Concept -> Flashcard references
- dangling Flashcard -> Concept references
- mismatched Concept/Card semantic slugs
- invalid card versions
- invalid deck identities
- deck/version mismatch
- missing cards in decks
- cards placed in the wrong competency deck
- unknown canonical Domain/Competency IDs
- non-canonical Topic/Subtopic ID shapes
- question-like front labels

### Source schema reservation

Run 1 includes structured `FlashcardSourceRef` fields so Run 2 can add authoritative provenance without redesigning the card schema.

Run 1 does not yet claim source authority validation.

### Local fixture

Added:

```text
assets/flashcards/run1/fc_reference_registry.v1.json
```

The fixture proves that two independent Question IDs can map to the same Concept and therefore the same collectible Flashcard.

## Validation evidence

Initial green workflow:

```text
35507678747
```

Passed:

- package resolution
- canonical formatting
- full Flutter analyze
- FC identity tests
- FC model round-trip tests
- Concept Registry tests
- local JSON fixture test
- zero-backend architecture test
- frozen MOT FlipCard regression
- frozen HAP architecture regression

## Backend boundary

Run 1 feature code is permanently guarded against direct imports from:

- Cloud Firestore
- Firebase Core
- Firebase Auth
- Supabase

The FC Run 1 tests do not launch the production app and do not initialize Firebase.

## Explicitly deferred to later FC runs

Run 1 does not implement:

- authoritative Source Registry
- OSHA/NIOSH/etc. authority rules
- FCQ100
- collection ownership
- Daily Discovery
- review scheduling
- learner Flashcard UI
- Quiz completion hook
- Learning Twin integration
- cloud publishing or sync

These remain assigned to Runs 2-8 and future FCC exactly as frozen in `CSP11_FLASHCARD_CORE_FREEZE.md`.
