# CSP11 Flashcard Core - FC Run 4 Status

**Phase:** FC - Flashcard Core  
**Run:** 4 of 8  
**Implementation branch:** `phase-fc4-collectibles`  
**FC3 frozen base:** `phase-fc3-closed` at `9b89db05d372f772e2cc8686f47b9f56c3d1f2fe`  
**Checkpoint name:** `FC4_COLLECTIBLES_GREEN`  
**Backend access:** Zero Firebase / zero Supabase inside the Flashcard feature by design and validation.

## Run 4 purpose

FC Run 4 turns learner-ready Flashcards into collectible learner-owned objects.

The local acquisition path is:

```text
Eligible learner-ready Flashcard
          |
          +--> Question completion
          |       |
          |       +--> correct signal
          |       +--> incorrect signal
          |
          +--> Daily Discovery
                  |
                  +--> deterministic learner/date offer
          |
          v
FlashcardUnlockService
          |
          +--> persist ownership first
          |
          +--> newlyCollected
          +--> reinforced
          +--> duplicateIgnored
          |
          v
Learner-scoped Collection
```

Ownership is distinct from memory scheduling.

FC4 records the first back/reveal view through `firstViewedAt`. FC5 may use that state to begin memory scheduling. FC4 itself does not create review intervals or due dates.

## Implemented

### 1. Learner ownership model

Run 4 adds:

```text
FlashcardOwnership
```

Ownership records include:

- Flashcard ID
- Concept ID
- acquisition timestamp
- acquisition source
- first Question outcome
- first-view timestamp
- reinforcement count
- last reinforcement timestamp
- correct signal count
- incorrect signal count
- applied event IDs

Ownership exposes:

- `isUnseen`
- `isFirstViewed`
- event-id membership

### 2. Acquisition sources

Frozen FC4 acquisition sources are:

```text
questionCompletion
dailyDiscovery
```

No other runtime acquisition source is introduced in FC4.

### 3. Question outcome signal

Question-based acquisition records:

```text
correct
incorrect
```

Daily Discovery records:

```text
notApplicable
```

A mapped learner-ready Flashcard may therefore be acquired after either a correct or incorrect MCQ completion.

This follows the frozen FC design principle that a Flashcard is a concept collectible rather than a prize reserved only for correct answers.

### 4. Ownership invariants

Persisted ownership fails closed unless:

- card ID is present
- Concept ID is present
- at least one acquisition event exists
- applied event IDs are unique
- reinforcement count equals unique applied events minus the initial acquisition
- an unreinforced card has no last-reinforced timestamp
- a reinforced card has a last-reinforced timestamp
- Question acquisition has a correct/incorrect first outcome
- Question acquisition contains at least one Question signal
- Daily Discovery acquisition has no Question outcome
- total Question signals do not exceed applied acquisition events
- first-view time does not precede acquisition
- reinforcement time does not precede acquisition

These invariants allow corrupt or duplicate local reward state to be detected from persisted data rather than only from UI behavior.

### 5. Learner-scoped Collection repository

Run 4 adds:

```text
FlashcardCollectionRepository
```

Implementations:

- `MemoryFlashcardCollectionRepository`
- `SharedPreferencesFlashcardCollectionRepository`

SharedPreferences ownership is sharded by learner and card.

Index example:

```text
csp11.student.<learnerId>.flashcards.collection.index.v1
```

Ownership example:

```text
csp11.student.<learnerId>.flashcards.ownership.v1.<cardId>
```

The repository validates ownership before persistence.

The Collection repository does not import Firebase or Supabase.

### 6. Existing learner identity boundary reused

FC4 reuses:

```text
LearnerLocalIdentity
```

The Flashcard feature does not import Firebase Auth.

Services resolve the learner through the existing local identity boundary or an explicit test override.

Learner A and Learner B therefore receive isolated local Collection namespaces even for the same Flashcard ID and event ID.

### 7. Unlock event model

Run 4 adds:

```text
FlashcardUnlockRequest
FlashcardUnlockEvent
```

Unlock results are:

```text
newlyCollected
reinforced
duplicateIgnored
```

An event carries:

- stable event ID
- card ID
- Concept ID
- acquisition source
- Question outcome
- optional Question ID
- occurrence timestamp
- resulting ownership state

### 8. Idempotent unlock engine

Run 4 adds:

```text
FlashcardUnlockService
```

Core behavior:

- first unique event for an unowned card creates ownership
- later unique events reinforce the existing ownership
- repeated event IDs return `duplicateIgnored`
- repeated event IDs do not increment reinforcement
- repeated event IDs do not duplicate correct/incorrect signals
- ownership remains one record per learner/card

### 9. Concurrent duplicate protection

Same learner/card mutations are serialized by the unlock service.

The concurrency test submits the same event concurrently and proves:

- one result is `newlyCollected`
- one result is `duplicateIgnored`
- one ownership record exists
- reinforcement remains zero
- only one applied event ID is persisted

This protects against double taps and duplicate completion callbacks within the local runtime.

### 10. Persistence-first reward semantics

The unlock service persists ownership before returning a successful:

```text
newlyCollected
```

or:

```text
reinforced
```

result.

A simulated persistence failure causes the unlock Future to fail.

No successful collectible reward event is returned when local persistence fails.

### 11. Reinforcement

Existing ownership receives reinforcement only from a new unique acquisition event.

Reinforcement updates:

- reinforcement count
- last reinforcement timestamp
- correct/incorrect signal counts when applicable
- unique applied-event ledger

Reinforcement does not create duplicate ownership.

### 12. First-view state

Run 4 adds the explicit transition:

```text
unseen -> firstViewed
```

through:

```text
FlashcardUnlockService.markFirstViewed(...)
```

The transition is one-way and idempotent.

A second reveal does not replace the original `firstViewedAt`.

An unowned card cannot be marked first-viewed.

A first-view timestamp cannot precede acquisition.

### 13. FC5 memory-scheduling handoff

FC4 does not schedule review.

The FC5 eligibility gate is now representable as:

```text
ownership.firstViewedAt != null
```

Therefore collection alone cannot start memory scheduling.

A newly collected but unopened card remains:

```text
isUnseen == true
```

until the learner reveals/views it.

### 14. Collection statistics

Run 4 adds:

```text
FlashcardCollectionStatistics
```

It reports:

- total owned
- unseen count
- first-viewed count
- total reinforcements
- Question-acquired count
- Daily-Discovery-acquired count
- correct signal count
- incorrect signal count

Ownership, viewing and reinforcement remain distinct metrics.

### 15. Deterministic Daily Discovery

Run 4 adds:

```text
DailyDiscoveryService
```

Daily selection is deterministic from:

```text
csp11.daily.v1 | learnerId | local YYYY-MM-DD
```

using SHA-256 and a stable sorted candidate set.

The same learner, local date and eligible candidate universe therefore produce the same selection.

### 16. Daily Discovery eligibility

Daily Discovery considers only packages that pass:

```text
FCQ100 == 100/100
```

It then removes Flashcards already owned by the learner.

This means Daily Discovery cannot use:

- structurally invalid packages
- provenance-invalid packages
- non-FCQ100 content
- already owned cards

Conflicting canonical card identities fail closed.

### 17. Daily Discovery state

Run 4 adds:

```text
DailyDiscoveryState
DailyDiscoveryRepository
```

States:

```text
offered
claimed
empty
```

State records include:

- local date key
- status
- offer timestamp
- offered card ID
- offered Concept ID
- deterministic unlock event ID
- claimed timestamp

### 18. Daily Discovery persistence

Implementations:

- `MemoryDailyDiscoveryRepository`
- `SharedPreferencesDailyDiscoveryRepository`

SharedPreferences key:

```text
csp11.student.<learnerId>.flashcards.daily.v1.<YYYY-MM-DD>
```

Daily state is learner-scoped.

Reopening the same local day returns the persisted state rather than rerolling another card.

### 19. Daily claim idempotency

Daily Discovery uses a deterministic unlock event ID:

```text
daily:<YYYY-MM-DD>:<cardId>
```

Claiming the same Daily Discovery twice therefore produces:

- first claim: `newlyCollected`
- repeated claim: `duplicateIgnored`

The repeated claim does not create reinforcement or duplicate ownership.

### 20. Empty Daily Discovery day

If every eligible Flashcard is already owned, Run 4 persists:

```text
DailyDiscoveryStatus.empty
```

The same day continues returning that empty state.

No streak, punishment or negative progression state is introduced.

### 21. Daily/Unlock learner identity alignment

Daily Discovery verifies that its learner identity is the same identity used by the unlock service.

A mismatched identity fails closed.

This prevents an offer from one learner namespace from being persisted into another learner's Collection.

## Validation evidence

First full green FC4 implementation workflow:

```text
35510927149
```

Green gates:

- package resolution
- canonical Dart formatting
- full Flutter analyze
- FC Run 1 identity/model regression
- FC Run 1 Concept Registry regression
- FC Run 1 zero-backend architecture regression
- FC Run 2 Source Registry regression
- FC Run 2 provenance regression
- FC Run 3 FCQ100/content-system regression
- learner-scoped SharedPreferences Collection tests
- ownership serialization/invariant tests
- correct MCQ acquisition test
- incorrect MCQ acquisition test
- unique-event reinforcement test
- repeated-event idempotency test
- concurrent duplicate-callback test
- first-view state/idempotency test
- collection statistics test
- persistence-failure reward test
- learner-isolation test
- deterministic Daily Discovery test
- same-day persisted-offer test
- unowned-only Daily Discovery test
- FCQ100 Daily Discovery eligibility test
- Daily/Unlock learner identity alignment test
- idempotent Daily claim test
- all-owned empty-day test
- learner-scoped Daily state persistence test
- frozen MOT FlipCard regression
- frozen HAP architecture regression

## Backend boundary

FC Run 4 remains local-only.

The frozen FC architecture gate scans the complete:

```text
lib/features/flashcards
```

tree for forbidden Firebase and Supabase imports.

Run 4 uses:

- local domain models
- SharedPreferences behind repositories
- crypto SHA-256 for deterministic Daily selection
- the existing `LearnerLocalIdentity` boundary

No Firebase or Supabase operation is required by FC4.

## Explicitly deferred

Run 4 does not implement:

- SM-2 or other spaced-repetition scheduling
- due dates
- review intervals
- ease-factor updates
- Again/Hard/Good/Easy review actions
- learner Collection UI
- learner Review Player
- MCQ runtime hook into the existing Quiz screen
- unlock sheet UI
- FlipCard learner UI integration
- Learning Twin Collection summary
- cloud publishing
- cross-device Collection synchronization

These remain assigned to FC Runs 5-8 and future FCC exactly as frozen.

## Run 4 acceptance result

Frozen Run 4 deliverables:

- collection ownership model: PASS
- local collection repository: PASS
- unlock event model: PASS
- FlashcardUnlockService: PASS
- idempotent unlock: PASS
- new/unseen state: PASS
- first-view state: PASS
- Concept reinforcement: PASS
- correct/incorrect reward signal: PASS
- deterministic Daily Discovery: PASS
- Daily Discovery state: PASS
- collection statistics: PASS
- learner isolation: PASS
- persistence-first reward semantics: PASS
- zero-backend preservation: PASS

Checkpoint candidate:

```text
FC4_COLLECTIBLES_GREEN
```

The checkpoint becomes frozen after this status-bearing commit itself passes the Phase FC validation workflow.
