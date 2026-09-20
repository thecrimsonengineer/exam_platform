# CSP11 Flashcard Core - FC Run 7 Status

**Phase:** FC - Flashcard Core  
**Run:** 7 of 8  
**Implementation branch:** `phase-fc7-integration`  
**FC6 frozen base:** `phase-fc6-closed` at `4637e677f87b816994156db58c2fddfe836e9d9b`  
**Checkpoint name:** `FC7_INTEGRATION_GREEN`  
**Backend scope:** Flashcard integration remains local-first. FC7 adds no Flashcard cloud synchronization or Flashcard Firebase collections.

## Run 7 purpose

FC Run 7 connects the frozen Flashcard Core to existing CSP11 product surfaces without moving Flashcard business rules into those surfaces.

The integration path is:

```text
Question completion
   |
   v
Question -> Concept mapping
   |
   +--> no mapping --------> Quiz continues, no Flashcard side effect
   |
   +--> one mapping
          |
          v
      canonical Flashcard
          |
          v
      FC4 unlock/reinforcement commit
          |
          v
      learner reward presentation

StudyContent / Domain / Subtopic
   |
   v
scoped Flashcard review summary
   |
   v
existing FC5 review session

Flashcard state
   |
   +--> sanitized counts/scope --> Learning Twin guidance
   |
   +--> quality reports --------> Admin Diagnostics
   |
   +--> local package JSON -----> Flashcard Studio
```

FC7 is an integration phase. It does not replace the FC1-FC6 domain, validation, collection, memory, provenance, or learner-experience layers.

## Implemented

### 1. Integration façade

Run 7 adds:

```text
FlashcardIntegrationCatalog
FlashcardIntegrationService
```

The integration façade is the boundary used by Quiz, StudyContent, Learning Twin, and Admin integrations.

It owns:

- learner-ready local package aggregation
- canonical Question -> Concept mapping resolution
- canonical Concept -> Flashcard resolution
- Question completion reward mutation
- aggregate mapping coverage
- scoped review summaries
- scoped review-session creation/resume
- StudyContent placement validation
- source-quality reporting
- collection/memory-quality reporting
- sanitized Learning Twin summaries
- combined Flashcard diagnostics

External product surfaces do not reach directly into FC4/FC5 persistence internals.

### 2. Canonical integration catalog

`FlashcardIntegrationCatalog` loads FCQ100-valid local Flashcard packages through the existing package repository abstraction.

The catalog indexes:

- Flashcards by card ID
- Concepts by Concept ID
- sources by source ID
- Question -> Concept candidates

The catalog fails closed when separate packages expose conflicting canonical identities.

### 3. Question completion integration

Run 7 adds:

```text
FlashcardIntegrationService.recordQuestionCompletion(...)
```

Inputs include:

- Question ID
- correct / incorrect outcome
- deterministic event ID
- optional occurrence timestamp

Resolution is:

```text
Question ID
  -> exactly one Concept ID
  -> canonical Concept
  -> canonical Flashcard
  -> FC4 FlashcardUnlockService
```

The integration does not duplicate collection mutation rules.

### 4. Unmapped Questions

A Question with no Flashcard mapping returns:

```text
FlashcardQuestionCompletionStatus.noMapping
```

The Quiz continues normally.

An unmapped Question:

- does not fail the Quiz
- does not create learner ownership
- does not invent a Concept
- does not invent a Flashcard

### 5. Mapping conflicts fail closed

If one Question ID resolves to more than one Concept across learner-ready packages, FC7 treats the mapping as conflicting.

Conflicting mappings:

- appear in mapping diagnostics
- are excluded from normal reward resolution
- cause direct reward resolution for that Question to fail closed

FC7 never chooses one conflicting Concept heuristically.

### 6. Reward persistence ordering

Quiz reward presentation occurs only after the FC4 ownership/reinforcement mutation returns successfully.

The frozen order is:

```text
Question submitted
   |
   v
integration service resolves mapping
   |
   v
FC4 ownership/reinforcement is persisted
   |
   v
FlashcardUnlockEvent returned
   |
   v
Quiz reward card may render
```

The learner does not see a successful reward before the underlying mutation is committed.

### 7. New collection reward

A first mapped completion produces:

```text
NEW CONCEPT COLLECTED
```

The reward surface shows the canonical Flashcard concept label.

The card remains unseen until the learner reveals it through the FC6 collectible flow.

### 8. Reinforcement reward

A mapped completion for an already owned card produces:

```text
CONCEPT REINFORCED
```

Correct and incorrect Question outcomes continue to feed the frozen FC4 reinforcement evidence.

The reward UI does not calculate memory intervals.

### 9. Quiz reward event idempotency

The Quiz integration uses a stable attempt-scoped event identity for each Question completion.

Repeated handling of the same event is ignored by the FC4 idempotency boundary.

This protects ownership and reinforcement counters from duplicate async delivery.

### 10. Quiz integration is non-blocking

Flashcard integration errors are isolated from the active Quiz.

A Flashcard mapping, repository, or integration error does not interrupt:

- Question submission
- Quiz feedback
- score calculation
- Question progress recording
- navigation to the next Question/result

The Flashcard side effect is supplementary to Quiz completion.

### 11. Custom/retry Quiz path no longer constructs Firebase

FC7 identified and removed a hidden cloud dependency in:

```text
QuizController.review(...)
```

Previously, review/custom-question sessions constructed `QuizService()` even though the supplied Question list was already complete.

`QuizService` eagerly constructs Firebase-backed repositories.

Run 7 replaces that unused fallback with an inert `QuizServiceInterface` implementation for review/custom-question sessions.

Therefore:

- retry/custom-question Quiz sessions do not construct Firestore-backed Quiz repositories
- supplied Questions remain sufficient to run the session
- production cloud-backed Quiz loading remains unchanged for normal catalogue-based Quiz entry

### 12. Question mapping coverage

Run 7 adds:

```text
FlashcardQuestionMappingCoverage
```

For an eligible Question population it reports:

- eligible Question IDs
- mapped Question IDs
- unmapped Question IDs
- conflicting Question IDs
- mapped count
- coverage ratio
- pass/fail status

Coverage passes only when there are no unmapped or conflicting eligible Questions.

### 13. Scoped Flashcard review

Run 7 adds:

```text
FlashcardReviewScope
FlashcardScopedReviewSummary
```

Scope may include:

- Domain
- Competency
- Topic
- Subtopic

The integration service can summarize:

- total cards in scope
- owned cards
- unseen cards
- due cards
- active scoped review session

### 14. Scoped review-session creation

Run 7 adds:

```text
startOrResumeScopedReview(...)
```

It:

- filters canonical cards by placement
- filters ownership and review state to the same scope
- reuses the frozen FC5 session builder
- persists the scoped session through the frozen session repository
- resumes an existing incomplete session for the same scope

It does not calculate review intervals.

### 15. Review entry integration

Scoped Flashcard review entry cards are wired into existing learner surfaces.

FC7 integration points include:

- Flashcards Collection
- Domain screens
- StudyContent rendering
- Study Subtopic screens

Light and dark learner variants receive equivalent integration where those variants already exist.

These entry points expose review availability without moving Flashcard scheduling logic into StudyContent.

### 16. StudyContent placement validation

Run 7 adds:

```text
FlashcardStudyContentPlacementReport
```

Each learner-ready Flashcard placement is checked against canonical StudyContent hierarchy.

Validation checks:

- Domain
- Competency
- Topic when present
- Subtopic when present

Invalid placement produces an explicit issue with:

- card ID
- hierarchy level
- identifier
- message

FC7 does not silently remap an invalid placement.

### 17. Learning Twin sanitized summary

Run 7 adds:

```text
FlashcardLearningTwinSummary
```

The summary is deliberately narrow.

It contains:

- owned count
- unseen count
- due count
- weak-card count
- total review-event count
- Domain IDs that currently contain due review

It does not expose:

- Flashcard definition text
- card IDs
- Concept IDs
- Question text
- Question IDs
- source URLs
- source locators
- learner answer details

### 18. Learning Twin Flashcard guidance

Run 7 adds:

```text
LearningTwinFlashcardGuidance
```

The guidance consumes only the sanitized Flashcard summary.

Examples of learner-safe guidance include:

- due Flashcard review exists
- unseen collected concepts still need first reveal
- the learner can return to Flashcards for review

The guidance does not receive or reconstruct Flashcard content.

### 19. Learning Twin summary is off the Collection critical path

FC7 keeps Learning Twin summary generation supplementary to the core Collection experience.

A Twin summary issue does not block the learner from using the FC6 Collection and review surfaces.

### 20. Source-quality report

Run 7 adds:

```text
FlashcardSourceQualityReport
```

Current source metrics include:

- package count
- learner-ready card count
- source count
- cards with a primary source
- cards with a verified primary source
- verified source count
- needs-review source count
- stale source count
- blocked source count
- verified-primary coverage

The report passes only when all learner-ready cards have a verified primary source and no source is blocked.

### 21. Collection-quality report

Run 7 adds:

```text
FlashcardCollectionQualityReport
```

Current learner-state checks include:

- owned count
- unseen count
- memory-state count
- due count
- orphan ownership
- Concept identity mismatch
- orphan review state
- review state before first reveal

These checks are learner-scoped.

### 22. Flashcard Diagnostics

Run 7 adds the Admin-facing:

```text
FlashcardDiagnosticsScreen
```

The diagnostics surface contains four integration panels:

```text
Question -> Concept mapping
Source quality
StudyContent placement integrity
Collection and memory quality
```

A healthy snapshot reports:

```text
FC7 integration health is green
```

Collection diagnostics can report an Admin-session learner-scope limitation without blocking the other three diagnostic panels.

### 23. Flashcard Studio

Run 7 adds the Admin-facing:

```text
FlashcardStudioScreen
```

The Studio supports local:

- package JSON paste/import
- FCQ100 validation preview
- package metadata preview
- card preview
- source footer preview
- local save through `FlashcardStudioService`
- local package-index summary

The Studio uses the frozen FC3 authoring and validation service instead of implementing a second validation path.

### 24. Admin navigation

Flashcard Studio and Flashcard Diagnostics are wired into the existing Admin surface.

FC7 does not add Flashcard cloud publishing.

### 25. Integration architecture boundary

Run 7 architecture tests protect the integration direction.

The intended dependency shape is:

```text
Quiz / StudyContent / Learning Twin / Admin
          |
          v
FC7 integration façade / FC7 learner entry widgets
          |
          v
frozen FC1-FC6 Flashcard services and repositories
```

External product surfaces should not reach directly into low-level Flashcard collection/memory persistence.

### 26. Backend boundary

FC7 does not add Firebase or Supabase imports to the Flashcard integration core.

The broader CSP11 application continues to use its existing Firebase-backed services where already designed, such as normal production Quiz catalogue loading.

Flashcard packages, ownership, memory, review sessions, Studio preview/save, diagnostics data, and FC7 integration remain on the frozen local repository/service path.

### 27. FC7 validation gate

The Phase FC workflow now includes:

```text
FC Run 7 integration tests
```

The gate covers:

- integration service contracts
- Question mapping and conflict behavior
- Quiz reward integration
- Learning Twin sanitized guidance
- Admin Studio
- Admin Diagnostics
- FC7 architecture boundaries

## Validation evidence

First fully green FC7 implementation workflow:

```text
35523246256
```

Green gates include:

- package resolution
- canonical Dart formatting
- full Flutter analyze
- FC Run 1 identity/model regression
- FC Run 1 Concept Registry regression
- FC Run 1 architecture regression
- FC Run 2 provenance regression
- FC Run 3 content-system regression
- FC Run 4 collectible-engine regression
- FC Run 5 memory-engine regression
- FC Run 6 learner-experience regression
- Question completion collection test
- Question reinforcement/idempotency test
- unmapped Question no-op test
- aggregate mapping coverage test
- conflicting cross-package mapping fail-closed test
- StudyContent hierarchy placement test
- scoped due-review test
- source-quality test
- collection-quality test
- sanitized Learning Twin summary test
- Quiz reward-after-persistence widget test
- Learning Twin due-review guidance test
- Learning Twin unseen/reveal guidance test
- Flashcard Studio import/preview/local-save widget test
- Flashcard Diagnostics four-panel widget test
- FC7 architecture tests
- frozen MOT FlipCard regression
- frozen HAP architecture regression

## Explicitly deferred

FC Run 7 does not implement:

- Flashcard cloud package publishing
- cloud learner collection synchronization
- cloud review synchronization
- Flashcard Firebase security rules
- offline/cloud reconciliation
- multi-device learner Flashcard conflict resolution
- production migration from local Flashcard storage
- FC8 final hardening/closure tasks assigned by the frozen plan
- future FCC cloud work

## Run 7 acceptance result

Frozen Run 7 deliverables:

- integration façade: PASS
- canonical multi-package integration catalog: PASS
- Quiz completion hook: PASS
- reward-after-persistence contract: PASS
- new collection reward: PASS
- reinforcement reward: PASS
- idempotent Question completion: PASS
- unmapped Question no-op: PASS
- mapping conflict fail-closed behavior: PASS
- aggregate mapping coverage: PASS
- custom/retry Quiz cloud-construction removal: PASS
- scoped review summaries: PASS
- scoped review session entry: PASS
- Domain integration: PASS
- StudyContent integration: PASS
- Subtopic integration: PASS
- StudyContent placement validation: PASS
- Learning Twin sanitized summary: PASS
- Learning Twin guidance: PASS
- source-quality report: PASS
- collection-quality report: PASS
- Flashcard Diagnostics: PASS
- Flashcard Studio local import/preview/save: PASS
- Admin integration: PASS
- FC7 architecture boundary: PASS
- zero new Flashcard cloud dependency: PASS
- frozen FC1-FC6 regressions: PASS
- frozen MOT/HAP regressions: PASS

Checkpoint candidate:

```text
FC7_INTEGRATION_GREEN
```

The checkpoint becomes frozen after this status-bearing commit itself passes the Phase FC validation workflow.
