# CSP11 HOME-R Implementation Plan

Status: FROZEN AT HOME-R0  
Base branch: `phase-fr10-closed`  
Base SHA: `b54740c394e8c0b0cdc6d7c2acd165f6a3ba1123`  
Working branch: `phase-home-r`

## 1. Purpose

Redesign learner Home around:

**Hero → Search CSP Content → Continue CSP → Today’s Plan: Learn / Practice / Remember → Progress Intelligence + Exam Readiness**

Home is a read-and-launch surface. It is not a second planner.

## 2. Frozen product contract

Home must answer four learner questions:

1. What am I looking for?
2. Where did I stop?
3. What should I do today?
4. How am I progressing toward exam readiness?

The authoritative daily plan remains the existing `DailyStudyPlan` used by the planner and `TodaysPlanScreen`.

## 3. Frozen Home information architecture

Order:

1. Hero
2. Search CSP Content
3. Continue CSP
4. Today’s Plan
   - Learn
   - Practice
   - Remember
5. Progress Intelligence
6. Exam Readiness

## 4. Preserve

Do not remove:

- CSP11 Hero
- `StudyContentSearchPanel`
- `StudentLearningPositionService`
- Continue CSP
- learning-position loading
- progress loading
- Progress Intelligence
- Exam Readiness
- light/dark parity

## 5. Remove from Home

Remove Home entry points for:

- generic Study
- generic Practice
- generic Flashcards
- generic Bookmarks
- old four-card workspace
- Quick Practice
- Train with Intent
- Daily Challenge
- Random Quiz
- Weak Areas
- Ultra Hard quick launch
- direct Home bookmark shortcut

Underlying features are not deleted.

## 6. Continue CSP contract

Continue CSP answers:

> Take me back exactly where I stopped.

Today’s Plan Learn answers:

> Take me to what the adaptive planner says I should study today.

These are intentionally independent.

Continue CSP uses `StudentLearningPositionService` and existing Study Content deep-link capability.

Resolution priority:

`subtopic → topic → competency → safe curriculum destination`

If no learner position exists, show START CSP and begin at Domain 1.

Today’s Plan must not overwrite the resume position merely because a task was scheduled.

## 7. Search contract

Search remains on Home and remains independent from Learn navigation.

Search represents direct retrieval intent.

Reuse `StudyContentSearchPanel`.

## 8. Today’s Plan summary

Replace the current generic workspace with:

**TODAY’S PLAN**  
**Learn, Practice & Remember**

Home renders three live category cards derived from the authoritative `DailyStudyPlan`.

No static task counts or fixed question counts may be hardcoded.

Recommended shared types:

- `TodayPlanTaskCategory`
- `TodayPlanTaskCategoryPolicy`
- `TodayPlanSummary`
- `TodayPlanCategorySummary`
- `TodayPlanSummaryService`

## 9. Frozen category policy

### Learn

- `learn`
- `continueLearning`
- `repair`

### Practice

- `diagnostic`
- `standardPractice`
- `ultraHardPractice`
- `mixedRetrieval`
- `competencyRecheck`
- `confidenceCalibration`
- `examSimulation`

### Remember

- `spacedReview`
- supported review-oriented `recovery` blocks

Classification must live in one shared policy.

A new `StudyPlanBlockType` must not be silently classified.

## 10. Critical planner invariant

> **Home is a projection and execution gateway for the authoritative learner state. Home must never generate an independent Daily Study Plan, independently classify plan blocks, independently determine learning completion, or duplicate the planner's task lifecycle.**

Home may load and summarize the authoritative plan. It may not create an independent plan.

Desired data flow:

`Authoritative planner/store → DailyStudyPlan → TodayPlanSummaryService → Home`

and:

`Authoritative planner/store → DailyStudyPlan → TodaysPlanScreen`

## 11. Today card behaviour

### Learn

Example:

`2 tasks · 35 min`

`Next: D04 C01`

Tap:

`TodaysPlanScreen(initialCategory: learn)`

### Practice

Example:

`1 task · 20 min`

`8 questions`

Tap:

`TodaysPlanScreen(initialCategory: practice)`

### Remember

Example:

`1 review · 10 min`

Tap:

`TodaysPlanScreen(initialCategory: remember)`

If a category has no work:

`Nothing scheduled today`

Completed state must be shown truthfully.

## 12. Full-plan entry

Below the category cards show an aggregate summary such as:

`3 of 4 tasks complete · 55 of 65 min`

Add:

`View full plan →`

This opens unfiltered `TodaysPlanScreen`.

## 13. Filtered Today’s Plan

Extend `TodaysPlanScreen` with an optional initial category.

Filtering is presentation only.

It must not:

- generate a new plan
- duplicate plan blocks
- change plan IDs
- fork lifecycle state

## 14. Execution architecture

Introduce one shared execution layer.

Preferred name:

`StudyPlanBlockLauncher`

Optional target abstraction:

`StudyPlanExecutionTarget`

Target families may include:

- studyContent
- practiceSession
- review
- examSimulation

The launcher receives a `StudyPlanBlock` and resolves the real learner activity.

Home must not construct quiz sessions directly.

## 15. Learn execution

Learn blocks launch Study Content using the most specific available identifiers.

Do not invent missing topic/subtopic targets.

## 16. Practice execution

Practice blocks launch the existing real practice/quiz flow while preserving supported plan intent such as:

- competency
- practice type
- question count
- planned duration

Home and Today’s Plan must not create a second quiz engine.

## 17. Remember execution

HOME-R must not pretend competency Flashcards already exist.

Remember uses the real review route currently available.

If a review task cannot be safely executed, fail closed with a clear unavailable state.

Future Flashcards integration should plug into the launcher only.

## 18. Task lifecycle

Reuse existing `StudyPlanBlockStatus`.

Core flow:

`planned → started → completed`

Starting a task must not equal completing it.

Existing Skip / Move / Replace / Shorten / Unavailable behaviour remains owned by the planner lifecycle.

## 19. Completion evidence

### Practice

Prefer automatic completion after a qualifying planned practice session genuinely finishes.

Completion must be idempotent.

### Study

Opening Study Content alone must not complete a task.

Initial HOME-R may use explicit Finish Planned Task behaviour until stronger content-completion evidence exists.

### Remember

Completion must use genuine review evidence.

## 20. Bookmarks relocation

Move learner bookmark navigation to:

**Settings → Learning & Progress**

Keep:

- Full Progress
- Bookmarked Questions

Reuse:

- `BookmarkedQuestionsScreen`
- `BookmarkService`

No bookmark data migration is part of HOME-R.

## 21. Responsive contract

Wide:

`[ Learn ] [ Practice ] [ Remember ]`

Phone:

stacked cards.

Use width-based responsive logic.

Preserve glassmorphism and light/dark parity.

## 22. Loading and failure behaviour

A loading plan is not an empty plan.

Do not show “Nothing scheduled today” before loading finishes.

Home components degrade independently.

Failure to load Today’s Plan must not remove Search or Continue CSP.

Summary failure must not trigger plan regeneration merely as a retry mechanism.

## 23. Phase plan

### HOME-R0 — Freeze and architecture contract

- branch from `phase-fr10-closed`
- freeze this document
- no production behaviour changes
- verify ancestry and exact SHA

### HOME-R1 — Home cleanup

Remove obsolete Home-only actions and dead helpers/imports while preserving Search, Continue CSP, Progress Intelligence and Exam Readiness.

### HOME-R2 — Shared category policy

Implement one exhaustive category policy for all current `StudyPlanBlockType` values.

### HOME-R3 — Summary layer

Implement read-only Today plan summary models/service.

It may summarize the authoritative plan but may not independently generate one.

### HOME-R4 — Live Home cards

Replace generic workspace with Learn / Practice / Remember live cards plus full-plan summary.

### HOME-R5 — Filtered Today’s Plan

Add optional category entry to `TodaysPlanScreen`.

### HOME-R6 — Plan execution router

Implement shared `StudyPlanBlockLauncher`.

### HOME-R7 — Completion integration

Connect genuine activity evidence back to the authoritative plan lifecycle.

### HOME-R8 — Bookmark relocation

Move Bookmarked Questions to Settings → Learning & Progress in light and dark mode.

### HOME-R9 — Polish and closure

Responsive polish, regression, exact-SHA CI and final closed checkpoint.

## 24. Key regression expectations

Verify:

- Search exists on Home
- Continue CSP exists on Home
- Today’s Plan exists on Home
- Learn/Practice/Remember derive from the real plan
- Quick Practice absent from Home
- Train with Intent absent from Home
- generic Study/Practice/Flashcards absent from Home
- Bookmarks absent from Home
- Bookmarked Questions present in Settings
- Progress Intelligence remains
- Exam Readiness remains
- Home does not independently generate a plan
- light/dark routes remain synchronized

## 25. Required final validation

Final HOME-R closure should include:

- `flutter analyze`
- Home tests
- Today’s Plan tests
- category policy tests
- summary-service tests
- launcher tests
- navigation tests
- Settings/bookmark tests
- M7D/M7E planner regressions
- Exam Readiness regressions
- Study Content navigation regressions
- practice/quiz regressions
- full Flutter test suite
- Android build validation where applicable
- Web build validation where applicable
- exact-SHA CI
- frozen-rule / architecture checks

## 26. Non-goals

HOME-R must not:

- redesign the adaptive planning algorithm
- modify closed FR1–FR10 behaviour
- create a second plan store
- migrate bookmark data
- implement full Flashcards
- rewrite Exam Readiness
- alter canonical curriculum architecture
- invent missing content targets
- count route-open as learning completion
- restore learner Firestore read paths removed by FR work

## 27. HOME-R0 closure definition

HOME-R0 is complete when:

1. `phase-home-r` exists from exact FR10 base SHA.
2. This implementation contract is committed.
3. No production Dart behaviour is changed.
4. FR10 ancestry is verified.
5. The exact R0 commit SHA is recorded.
6. The branch is clean at that committed state.

No HOME-R1 implementation begins before HOME-R0 is frozen.
