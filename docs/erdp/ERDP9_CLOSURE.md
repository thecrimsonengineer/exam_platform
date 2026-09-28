# ERDP-9 Closed-Loop Retention Intelligence Closure

Status: CLOSED
Phase: ERDP-9
Working branch: `phase-erdp9-closed-loop-retention-intelligence`
Base checkpoint: `phase-erdp8-daily-plan-ux-closed@75c4c61a605b679a10a61e54019020db291d02a6`
Validated implementation head before closure record: `b1a802da78138abc0e9495e5346da5f26e4e1123`

## Closure decision

ERDP-9 closes the Flashcard retention loop without replacing the existing Flashcard package delivery, DailyStudyPlan, readiness engine, or ERDP-6 evidence hierarchy.

Flashcard recall remains supporting evidence. Question, LAB, and simulation assessment evidence remains stronger. Merely opening or revealing a card still carries no readiness credit.

## Implemented contracts

### Recall event model

A persistent learner-scoped Flashcard recall event records:

- immutable event identity;
- competency and card identity;
- review source;
- DailyStudyPlan block identity when applicable;
- rating;
- attempt sequence;
- same-session repeat state;
- spacing interval;
- previous recall state;
- next review time;
- event time and schema version.

Supported ratings are `again`, `hard`, and `gotIt`.

### Retention semantics

- `Again` is a strong retention-gap signal.
- `Hard` is a moderate retention-gap signal.
- `Got It` is positive supporting evidence.
- First recall in a review session may contribute supporting retention evidence.
- Same-session repeats do not receive the same spaced-retention credit as recalls across days.
- Repeated success separated by real spacing can strengthen retention evidence.
- A single successful Flashcard cannot independently establish strong overall exam readiness.

### Review queue

The Flashcard review queue uses persisted recall state to identify due cards and maintain next-review timing without modifying the published Flashcard packages.

### Readiness integration

Flashcard recall is normalized into `LearningEvidenceEvent` with `LearningEvidenceSourceKind.flashcard` and `LearningEvidenceStrength.supporting`.

The readiness engine may use valid supporting Flashcard retention samples when delayed question-retention evidence is unavailable. It does not promote Flashcard evidence into strong question/LAB evidence.

### Daily Plan integration

Daily Plan Flashcard review targets remain first-class `flashcardReview` execution targets.

A Remember task is completed only by real qualifying rated-card evidence associated with that planned review execution. Opening the Flashcard screen, revealing a card, or leaving the screen does not complete the task.

### Closed-loop update

A qualifying Flashcard recall event can refresh competency evidence/readiness through the existing evidence aggregation path. No synthetic quiz attempt is created.

## Files added

- `lib/features/flashcards/learning/flashcard_recall_event.dart`
- `lib/features/flashcards/learning/flashcard_recall_event_repository.dart`
- `lib/features/flashcards/learning/flashcard_review_queue_service.dart`
- `lib/features/exam_readiness/services/flashcard_retention_evidence_service.dart`
- `test/features/exam_readiness/erdp/erdp9_retention_intelligence_test.dart`
- `.github/workflows/erdp9_build.yml`

## Key existing surfaces integrated

- `LearningEvidenceEvent`
- `ActivityEvidenceStats`
- `ReadinessProfileService`
- `LearningStateUpdateCoordinator`
- `StudyPlanCompletionEvidenceService`
- `StudyPlanBlockLauncher`
- `FlutterStudyPlanExecutionNavigator`
- `TodaysPlanScreen`
- `FlashcardCompetencyReviewScreen`
- `FlashcardDeckScreen`

## Validation

Strict read-only validation on implementation head `b1a802da78138abc0e9495e5346da5f26e4e1123` completed successfully in GitHub Actions run `36414071015`.

The successful gate covered:

- canonical formatting;
- ERDP-9 surface analysis;
- ERDP-0 through ERDP-9 regression suite;
- Flashcard cloud regressions;
- M7D Daily Plan regressions;
- diff hygiene;
- verification that validation did not mutate the repository.

The closure-record commit must pass the same read-only workflow before the immutable closure branch is created.

## Frozen invariants

1. Flashcards provide supporting retention evidence only.
2. Same-session repetition cannot masquerade as spaced recall.
3. Screen opening and card reveal provide zero readiness credit.
4. Daily Plan Flashcard completion requires real rated-card evidence.
5. Recall events are idempotent and immutable by identity.
6. Existing Flashcard package/catalogue delivery remains authoritative.
7. Readiness and DailyStudyPlan remain the only authoritative readiness/planning systems.
8. ERDP-9 introduces no second SRS package store and no synthetic assessment attempts.

## Next phase

ERDP-10 must start only from the immutable ERDP-9 closure SHA.

Planned branch:

`phase-erdp10-whole-system-acceptance`

Final ERDP target after acceptance:

`phase-erdp-learner-intelligence-closed`
