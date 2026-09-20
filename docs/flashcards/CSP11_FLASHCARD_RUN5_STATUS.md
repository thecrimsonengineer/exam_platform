# CSP11 Flashcard Core - FC Run 5 Status

**Phase:** FC - Flashcard Core  
**Run:** 5 of 8  
**Implementation branch:** `phase-fc5-memory`  
**FC4 frozen base:** `phase-fc4-closed` at `85e20a60f2efa1a9a310ccfdc2f3dfd4af54f15c`  
**Checkpoint name:** `FC5_MEMORY_GREEN`  
**Backend access:** Zero Firebase / zero Supabase inside the Flashcard feature.

## Run 5 purpose

FC Run 5 implements the local long-term memory and review engine.

The frozen path is:

```text
owned card
   |
   +--> unseen ----------------------> no memory schedule
   |
   +--> first reveal
           |
           v
      learning state
           |
           v
      due review
           |
           +--> Again  -> relearning
           +--> Hard   -> review
           +--> Got It -> review
           |
           v
      deterministic next due time
```

Collection ownership remains separate from memory scheduling.

Quiz, Learning Twin and learner UI do not calculate Flashcard due dates.

## Implemented

### 1. Review model

Run 5 adds:

```text
FlashcardReviewState
```

Review state contains:

- card ID
- Concept ID
- activation timestamp
- review stage
- next due timestamp
- current interval in minutes
- total review count
- lapse count
- Again count
- Hard count
- Got It count
- Got It streak
- last review timestamp
- last rating
- unique applied review event IDs

### 2. Review states

Frozen FC5 stages are:

```text
learning
review
relearning
```

The state model fails closed on invalid timing, rating counts, duplicate review event IDs and inconsistent review counters.

### 3. Review controls

Frozen FC5 learner ratings are exactly:

```text
Again
Hard
Got It
```

The scheduler does not introduce Good/Easy or Quiz-style answer scoring.

### 4. Deterministic interval policy

Run 5 adds:

```text
FlashcardIntervalPolicy
```

Frozen V1 intervals:

```text
First-view activation -> first review in 1 day

Again
  -> relearning
  -> 10 minutes

Hard from learning/relearning
  -> review
  -> 1 day

Hard from review
  -> current interval x 1.5

Got It from learning/relearning
  -> review
  -> 3 days

Got It from review
  -> current interval x 2.5
```

Maximum interval:

```text
365 days
```

The policy is deterministic and contains no randomness, network lookup or runtime AI decision.

### 5. First-view activation

Run 5 adds memory activation through:

```text
FlashcardMemoryService.activateFromOwnership(...)
```

Rules:

- unowned state is outside FC5
- owned but unseen cards do not activate memory
- first-viewed ownership may activate memory
- activation timestamp must match the FC4 first-view timestamp
- activation is idempotent
- existing memory with conflicting Concept or activation identity fails closed

Initial state:

```text
stage = learning
interval = 1 day
due = firstViewedAt + 1 day
```

### 6. Idempotent review events

Run 5 adds:

```text
FlashcardReviewEventResult
```

Review event results are:

```text
applied
duplicateIgnored
```

A review event ID can mutate one card only once.

Repeated delivery of the same event does not:

- increment review count
- increment lapse count
- increment rating counters
- change interval
- move due date again

Same-card mutations are serialized locally.

### 7. Relearning

Again always sends the card to:

```text
relearning
```

with a deterministic 10-minute interval.

Again increments the lapse count.

Hard or Got It moves the card back to the normal review stage.

### 8. Weak-card policy

Run 5 adds:

```text
FlashcardWeakCardPolicy
```

Weak-card priority may be raised by:

- relearning state
- repeated lapses
- last rating of Again
- incorrect MCQ evidence exceeding correct MCQ evidence

Incorrect MCQ evidence affects review-session priority only.

It does not calculate or directly modify a Flashcard due date.

This preserves the frozen Question/Concept/Flashcard boundary.

### 9. Local review persistence

Run 5 adds:

```text
FlashcardReviewRepository
```

Implementations:

- `MemoryFlashcardReviewRepository`
- `SharedPreferencesFlashcardReviewRepository`

Persistent review state is learner-scoped and card-sharded.

Index key:

```text
csp11.student.<learnerId>.flashcards.memory.index.v1
```

Card memory key:

```text
csp11.student.<learnerId>.flashcards.memory.v1.<cardId>
```

### 10. Session builder

Run 5 adds:

```text
FlashcardReviewSessionBuilder
```

The builder:

- selects only due cards
- requires an existing canonical Flashcard
- requires matching Concept identity
- requires learner ownership
- requires first-view activation
- orders weak cards ahead of lower-priority cards
- then uses due time and stable card ID ordering
- supports a maximum session size

### 11. Sibling / Concept interleaving

Session construction avoids adjacent cards from the same Concept or sibling placement when alternatives exist.

Sibling grouping preference is:

```text
subtopic
  else topic
  else competency
```

When no alternative exists, the builder falls back deterministically rather than dropping a due card.

### 12. Review session state

Run 5 adds:

```text
FlashcardReviewSessionState
```

Session state records:

- session ID
- creation timestamp
- update timestamp
- ordered card IDs
- next index
- active/completed state

The current card and remaining count are derived from persisted state.

### 13. Sharded session persistence

Run 5 adds:

```text
FlashcardReviewSessionRepository
```

Implementations:

- `MemoryFlashcardReviewSessionRepository`
- `SharedPreferencesFlashcardReviewSessionRepository`

Session index key:

```text
csp11.student.<learnerId>.flashcards.review_sessions.index.v1
```

Session state key:

```text
csp11.student.<learnerId>.flashcards.review_session.v1.<sessionId>
```

### 14. Interruption recovery

Run 5 adds:

```text
FlashcardReviewSessionService
```

Each session step uses a deterministic event ID:

```text
review:<sessionId>:<sessionIndex>:<cardId>
```

Write order:

```text
1. persist card memory mutation
2. persist session advancement
```

If the app stops after step 1 but before step 2:

- the session remains on the same card
- the memory event is already recorded
- retry uses the same deterministic event ID
- the memory mutation is returned as duplicateIgnored
- session advancement can then complete
- review count is not duplicated

The interruption-recovery test explicitly simulates this failure.

### 15. Session resume

`startOrResume(...)` returns an existing persisted session unchanged when the same session ID already exists.

A resumed session does not rebuild or reshuffle the queue.

### 16. Memory statistics

Run 5 adds:

```text
FlashcardMemoryStatistics
```

Current statistics include:

- active memory cards
- due count
- learning count
- review-stage count
- relearning count
- weak-card count
- total review events
- total lapses
- average current interval

### 17. Learner isolation

Memory state and review sessions use the existing:

```text
LearnerLocalIdentity
```

FC5 imports no Firebase Auth SDK.

The session service also verifies that its learner identity matches the memory service learner identity.

## Validation evidence

First full green FC5 implementation workflow:

```text
35511817897
```

Green gates include:

- package resolution
- canonical Dart formatting
- full Flutter analyze
- FC Run 1 identity/model regression
- FC Run 1 Concept Registry regression
- FC Run 1 zero-backend architecture regression
- FC Run 2 provenance regression
- FC Run 3 content-system regression
- FC Run 4 collectible-engine regression
- deterministic interval-policy tests
- 365-day interval cap test
- learner-scoped sharded memory repository test
- persisted session repository test
- malformed review-state fail-closed test
- no activation before first reveal
- first-view activation/idempotency test
- Again/Hard/Got It scheduling tests
- duplicate review-event idempotency test
- relearning test
- weak-card policy test
- memory-statistics test
- sibling interleaving test
- interrupted-session recovery test
- session resume stability test
- frozen MOT FlipCard regression
- frozen HAP architecture regression

## Backend boundary

FC Run 5 remains local-only.

Inside:

```text
lib/features/flashcards
```

there are no Firebase or Supabase imports.

FC5 uses:

- deterministic Dart domain logic
- SharedPreferences behind repository interfaces
- the existing learner-local identity abstraction

No backend access is needed for review scheduling or recovery.

## Explicitly deferred

FC Run 5 does not implement:

- My Collection UI
- review-player UI
- rating buttons/swipes
- collectible reveal UI
- Daily Discovery UI
- source-details UI
- HAP review feedback wiring
- MOT learner animation wiring
- Quiz completion runtime hook
- StudyContent review entry points
- Learning Twin review summary
- cloud review synchronization

Those remain assigned to FC Runs 6-8 and future FCC.

## Run 5 acceptance result

Frozen Run 5 deliverables:

- review model: PASS
- review states: PASS
- Again / Hard / Got It: PASS
- deterministic interval policy: PASS
- due calculation: PASS
- first-view activation: PASS
- relearning: PASS
- weak-card policy: PASS
- session builder: PASS
- sibling/Concept interleaving: PASS
- local sharded persistence: PASS
- interruption recovery: PASS
- memory statistics: PASS
- learner isolation: PASS
- zero-backend preservation: PASS

Checkpoint candidate:

```text
FC5_MEMORY_GREEN
```

The checkpoint becomes frozen after this status-bearing commit itself passes the Phase FC validation workflow.
