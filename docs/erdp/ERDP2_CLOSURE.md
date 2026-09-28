# ERDP-2 First-Class Flashcard Execution Closure

Status: CLOSED
Phase: ERDP-2
Base checkpoint: `phase-erdp1-readiness-intelligence-closed@67d4259fc1ce0a8573d4e865824250c8943a6baf`
Implementation start head: `8e8ba5abb2ceebd44a28d65efeeaaf4b68ae875e`

## 1. Scope closed

ERDP-2 makes retention-oriented DailyStudyPlan work a first-class Flashcard execution target. Remember tasks no longer resolve to generic Study Content. The phase reuses the existing authenticated CSP11 Flashcard package runtime and does not introduce a second Flashcard planner, catalogue, repository or deck player.

## 2. Execution target added

`StudyPlanExecutionTargetKind.flashcardReview` is now a dedicated execution family.

The target contract carries Flashcard-oriented scope metadata:

- competency IDs through the authoritative competency target;
- optional card IDs;
- due-only filtering intent;
- weak-only filtering intent;
- source evidence IDs;
- optional target card count;
- target minutes from the authoritative plan block;
- review reason.

The current DailyStudyPlan launcher marks Flashcard review work as due-only and preserves the block reason as the review reason. Additional card-level filtering becomes active only when the learner SRS state can satisfy it safely.

## 3. Remember routing corrected

The shared Today Plan category policy remains authoritative.

The execution mapping is now:

- Learn -> Study Content;
- Practice -> targeted question session;
- Remember -> Flashcard review;
- Exam Simulation -> simulation execution family.

`spacedReview` and review-oriented `recovery` blocks therefore route to `flashcardReview` instead of the legacy generic `review` path.

Ambiguous recovery work still fails closed through the existing category policy.

## 4. Existing Flashcard runtime reused

Added:

`lib/screens/flashcards/flashcard_competency_review_screen.dart`

The direct review screen:

1. receives the exact planned competency ID;
2. loads that competency through the existing `FlashcardPackageRepository`;
3. defaults to `CloudFlashcardPackageRepository` for authenticated learner delivery;
4. opens the existing `FlashcardDeckScreen`;
5. exposes a visible retryable failure state when the package cannot be loaded.

No parallel Flashcard content source or learner catalogue was created.

## 5. Evidence safeguards preserved

ERDP-2 preserves the frozen ERDP evidence hierarchy:

- opening a Flashcard screen gives zero readiness credit;
- loading a Flashcard package gives zero readiness credit;
- starting Remember work does not complete the task;
- Flashcards remain supporting retention evidence only;
- question and applied/LAB outcomes remain stronger readiness evidence;
- micro-learning remains zero direct readiness credit.

ERDP-2 does not introduce direct readiness writes from the Flashcard UI.

## 6. Focused test contracts

Updated:

`test/features/exam_readiness/home_r/home_r6_study_plan_block_launcher_test.dart`

The launcher contract now asserts:

- spaced review resolves to `flashcardReview`;
- retention recovery resolves to `flashcardReview`;
- Learn, Practice and Simulation routing remain unchanged;
- invalid curriculum targets and ambiguous recovery continue to fail closed.

Added:

`test/features/exam_readiness/erdp/erdp2_flashcard_execution_test.dart`

The direct execution suite covers:

1. the assigned competency is requested directly from the existing Flashcard repository;
2. the existing `FlashcardDeckScreen` is used as the learner runtime;
3. package-load failure remains visible and retryable instead of falling through to unrelated content.

## 7. Closure gate

Added:

`.github/workflows/erdp2_flashcard_execution_closure.yml`

The gate contains:

- ERDP-2 formatting checks;
- Flutter analysis;
- launcher contract tests;
- direct Flashcard execution tests;
- Flashcard package regressions;
- M7D planner regressions;
- complete Flutter regression suite;
- diff hygiene.

The workflow is committed as the canonical executable closure gate for a GitHub runner or later release admission run.

## 8. Validation boundary

Source-level inspection confirms the Flashcard execution path reuses the existing production package repository and existing deck runtime.

The focused tests and closure workflow are committed as part of this closure. The connected GitHub integration did not spawn an Actions run for the ERDP-2 working branch, and this session has no attached executable Flutter/Codex environment. This closure therefore does not falsely claim `flutter test`, `flutter analyze`, or workflow success.

Executable release admission must run the ERDP-2 closure workflow or its equivalent before production release.

## 9. Deferred scope

Again/Hard/Got It scoring, spaced-success weighting, same-session repeat suppression and closed-loop retention evidence remain reserved for ERDP-9. ERDP-2 only establishes correct first-class plan targeting and execution.

## 10. Closure rule

Frozen checkpoint:

`phase-erdp2-flashcard-execution-closed`

ERDP-3 must begin strictly from the commit containing this closure record, the focused ERDP-2 tests and the ERDP-2 executable closure gate.

Next working branch:

`phase-erdp3-balanced-planner`
