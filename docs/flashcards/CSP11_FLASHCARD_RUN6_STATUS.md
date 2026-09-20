# CSP11 Flashcard Core - FC Run 6 Status

**Phase:** FC - Flashcard Core  
**Run:** 6 of 8  
**Implementation branch:** `phase-fc6-learner-ui`  
**FC5 frozen base:** `phase-fc5-closed` at `b1e951052e1109b7d4c97c8eaccdb0f3bee56bc3`  
**Checkpoint name:** `FC6_LEARNER_UI_GREEN`  
**Backend access:** Zero Firebase / zero Supabase inside the Flashcard learner experience.

## Run 6 purpose

FC Run 6 turns the frozen FC1-FC5 Flashcard foundations into the complete local learner-facing collectible and memory-review experience.

The learner path is now:

```text
Flashcards tab
   |
   v
My Collection
   |
   +--> Daily Discovery
   |      |
   |      +--> collect local validated card
   |      +--> open collectible
   |      +--> reveal meaning
   |              |
   |              v
   |         memory activates
   |
   +--> Newly Collected
   |      |
   |      +--> reveal unseen cards
   |
   +--> Collection by Domain
   |
   +--> My Collection grid
   |      |
   |      +--> open concept card
   |      +--> inspect visible source provenance
   |
   +--> Memory Review
          |
          +--> resume saved session
          +--> reveal meaning
          +--> Again / Hard / Got It
          +--> optional swipe shortcuts
          +--> completion summary
```

Run 6 consumes the frozen collectible and memory services. It does not duplicate their business rules in widgets.

## Implemented

### 1. Learner experience orchestration boundary

Run 6 adds:

```text
FlashcardLearnerExperienceController
FlashcardLearnerSnapshot
FlashcardDomainCollectionSummary
```

The controller aggregates local learner-ready Flashcard data from the existing FC repositories and services.

The snapshot contains:

- FCQ100-valid local packages
- canonical cards indexed by card ID
- learner ownership indexed by card ID
- memory state indexed by card ID
- Source Registry
- Domain collection summaries
- collection statistics
- memory statistics
- Daily Discovery state
- most recent active review session

The controller fails closed if separate learner-ready packages contain conflicting canonical Flashcard or source identities.

### 2. Repository and service boundaries remain frozen

The learner UI does not:

- write SharedPreferences directly
- calculate review intervals
- calculate due dates
- mutate ownership directly
- invent Daily Discovery selections
- create runtime Flashcard content

Learner mutations continue through the frozen FC4 and FC5 services:

```text
FlashcardUnlockService
DailyDiscoveryService
FlashcardMemoryService
FlashcardReviewSessionService
```

### 3. My Collection home

The former Flashcards placeholder is replaced with the learner Collection home.

The dashboard includes:

- collection progress
- collected / total count
- unseen count
- due-now count
- total memory review events
- Daily Discovery
- Memory Review CTA
- Newly Collected inbox
- Domain collection summaries
- owned-card collection grid
- learner-ready-content empty state
- empty-collection state
- pull-to-refresh
- explicit refresh action

### 4. Domain collection summaries

Each Domain summary exposes:

- total available cards
- owned cards
- collection progress
- unseen cards
- due cards

The layout adapts from one column on narrow phone widths to multiple columns on wider phone/tablet layouts.

### 5. Newly Collected inbox

Unseen owned cards appear in a dedicated horizontal Newly Collected section.

Opening a card routes to the collectible reveal experience.

The memory schedule remains inactive until the card back is first revealed.

### 6. Daily Discovery learner UI

The Collection home renders all frozen Daily Discovery states:

```text
no learner-ready package
empty
offered
claimed
unavailable
```

For an offered card, the learner can collect the deterministic Daily Discovery card.

For a claimed card, the learner can reopen the collected card.

The UI does not perform the deterministic selection itself.

### 7. Collectible reveal

Run 6 adds:

```text
FlashcardCollectibleRevealScreen
```

The reveal flow supports:

- concept-only front
- explicit Reveal card button
- tap-to-reveal on the card front
- first-view persistence through FC4
- memory activation through FC5
- visible confirmation that memory review is active after reveal
- source access after reveal

### 8. Concept-only card presentation

Run 6 adds:

```text
FlashcardCardView
```

The front displays:

- the canonical concept label
- Concept card identity
- reveal affordance

It does not display:

- an MCQ
- a question stem
- answer options
- a learner question prompt

This preserves the frozen FC product definition.

### 9. Card back

The learner-facing back displays:

```text
DEFINITION / MEANING

WHY IT MATTERS

OPTIONAL KEY POINT

SOURCE
```

The source footer remains visible at the bottom of the card back.

### 10. Persistent source footer

The card back resolves its primary source through the frozen Source Registry.

The footer shows the authority organization and source locator.

Example shape:

```text
Source: NIOSH | Hierarchy of Controls > Overview
```

Source provenance is not hidden behind a separate menu.

### 11. Source Details sheet

Run 6 adds:

```text
showFlashcardSourceDetailsSheet(...)
```

Source Details can display:

- organization
- title
- primary/supporting status
- locator
- authority tier
- source type
- definition mode
- verification status
- verification date
- official source action

The official source action uses the existing URL launcher boundary and opens the registered canonical source externally.

### 12. Review player

Run 6 adds:

```text
FlashcardReviewPlayerScreen
```

The player consumes persisted FC5 review sessions.

The player displays:

- current-card progress
- canonical concept front
- reveal action
- sourced card back
- Again
- Hard
- Got It
- optional swipe shortcuts
- source details
- completion state

The review player does not calculate the next interval.

### 13. Rating controls

The frozen FC5 ratings are preserved exactly:

```text
Again
Hard
Got It
```

Button alternatives are always present after reveal.

No rating depends on swipe gestures.

### 14. Optional swipe controls

Horizontal swipe shortcuts are optional:

```text
swipe left  -> Again
swipe right -> Got It
```

The learner can disable swipe shortcuts from the review player.

Hard remains explicitly available through its button.

### 15. Saved-session resume

The Collection home detects the most recently updated incomplete review session.

If one exists, the Memory Review card changes to:

```text
Resume memory session
```

The existing FC5 queue is reused unchanged.

The queue is not rebuilt or reshuffled by FC6.

### 16. Completion summary

A completed session displays a dedicated completion surface with:

- completion icon
- Memory session complete
- reviewed-card count
- Back to collection action

Completion uses the frozen MOT completion primitive.

### 17. HAP integration

FC6 uses the frozen semantic haptic service:

```text
Csp11Haptics.selection()
Csp11Haptics.navigation()
Csp11Haptics.confirm()
Csp11Haptics.success()
Csp11Haptics.warning()
Csp11Haptics.completion()
```

Examples:

- navigation into card/review flows
- card reveal selection feedback
- Got It success
- Again warning
- Hard confirmation
- session completion

Haptic driver details remain outside FC6.

### 18. MOT integration

FC6 uses the frozen motion primitives rather than creating a parallel animation system.

Used primitives include:

```text
Csp11FlipCard
Csp11CompletionReveal
Csp11StaggeredReveal
Csp11StatusReveal
Csp11Route
```

### 19. Reduced motion

The FC6 card flip and completion/reveal motion inherit the frozen MOT reduced-motion behavior.

When reduced motion is enabled:

- the FlipCard swaps faces without the 3D flip
- frozen MOT reveal primitives suppress or simplify motion
- route behavior uses the frozen reduced-motion route contract

FC6 does not maintain a separate reduced-motion preference.

### 20. Light/dark parity

The same learner experience is used in light and dark themes.

The legacy `DarkFlashcardsScreen` remains only as a compatibility wrapper around the unified FC6 screen.

The learner UI uses:

```text
StudentGlassScaffold
StudentGlassSurface
Theme.of(context)
ColorScheme
```

rather than maintaining independent feature logic for light and dark modes.

### 21. Phone/tablet responsiveness

The FC6 Collection layout adapts to available width.

Validated layouts include:

- narrow phone width
- tablet width
- light theme
- dark theme

Collection sections use constrained maximum widths and responsive Wrap/Row/Column behavior rather than fixed phone-only geometry.

### 22. Learner accessibility foundations

FC6 includes:

- semantic labels on Flashcard faces
- button alternatives for swipe actions
- explicit tooltips for swipe toggle and refresh
- scrollable review/player content
- source details accessible through a normal tappable control
- Material buttons for primary actions

### 23. Local-only learner package loading

The controller reads packages through the existing local package repository abstraction.

Only packages that pass FCQ100 are exposed to the learner experience.

Invalid local packages are excluded from learner-ready data.

### 24. Canonical identity conflict protection

If two distinct learner-ready packages expose the same canonical Flashcard ID with different serialized card content, FC6 fails closed.

The same rule applies to conflicting source identities.

This prevents silent learner-facing identity drift when multiple local packages are installed.

## Validation evidence

First fully green FC6 implementation workflow:

```text
35520162426
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
- FC Run 5 memory-engine regression
- FC6 learner snapshot aggregation
- FC6 Domain summary aggregation
- FC6 Daily Discovery snapshot
- FC6 claim flow
- FC6 first-reveal memory activation
- FC6 due-review/session resume path
- FC6 conflicting-package fail-closed test
- Collection home phone-width light-mode test
- Collection home tablet-width dark-mode test
- review reveal test
- persistent source-footer test
- Source Details test
- Again / Hard / Got It control presence
- viewport-safe Got It completion path
- FC6 backend/persistence architecture test
- FC6 no-interval-calculation UI architecture test
- FC6 frozen HAP/MOT usage test
- frozen FlipCard regression
- frozen HAP architecture regression

## Backend boundary

FC Run 6 remains local-first and backend-independent.

Inside the FC learner feature and learner Flashcard screens there are no direct imports of:

- Cloud Firestore
- Firebase Core
- Firebase Auth
- Supabase
- SharedPreferences

Persistent operations are accessed only through the frozen FC repository/service boundaries.

The broader app may still use Firebase authentication to establish the learner identity namespace. FC6 does not initialize or query Firebase itself.

## Explicitly deferred

FC Run 6 does not implement:

- Quiz completion runtime hook
- Question completion reward presentation in Quiz
- StudyContent Flashcard entry points
- Domain / Competency / Subtopic review entry integration
- Learning Twin Flashcard summary
- source-quality dashboard
- collection-quality dashboard
- Flashcard Diagnostics
- Admin authoring/preview integration
- cloud package publishing
- cloud collection synchronization
- cloud review synchronization
- Firebase security rules for Flashcards

Those remain assigned to FC Run 7, FC Run 8 and future FCC.

## Run 6 acceptance result

Frozen Run 6 deliverables:

- My Collection home: PASS
- Domain collection summaries: PASS
- Newly Collected inbox: PASS
- Daily Discovery UI: PASS
- collectible reveal: PASS
- concept-only front: PASS
- learner card back: PASS
- persistent source footer: PASS
- Source Details sheet: PASS
- review player: PASS
- Again / Hard / Got It controls: PASS
- optional swipe controls: PASS
- button alternatives to swipe: PASS
- HAP integration: PASS
- MOT integration: PASS
- reduced-motion inheritance: PASS
- completion summary: PASS
- light/dark parity: PASS
- phone/tablet responsiveness: PASS
- local repository/service boundary: PASS
- zero Firebase/Supabase direct learner access: PASS

Checkpoint candidate:

```text
FC6_LEARNER_UI_GREEN
```

The checkpoint becomes frozen after this status-bearing commit itself passes the Phase FC validation workflow.
