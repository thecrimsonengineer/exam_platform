# CSP11 HOME-R Closure Record

Status: CLOSED CANDIDATE VALIDATED  
Date: 22 September 2026  
Working branch: `phase-home-r`  
Frozen base branch: `phase-fr10-closed`  
Frozen base SHA: `b54740c394e8c0b0cdc6d7c2acd165f6a3ba1123`  
HOME-R0 architecture SHA: `c27772a315489c6493077dc75d950937d8d8f517`  
Validated implementation SHA: `243d9fdf93c55775321468eb17ce85cd3b7c557f`  
Validation workflow: `HOME-R Final Closure`  
Green workflow run: `35735054680`

## 1. Final Home contract

Learner Home now follows the frozen HOME-R information architecture:

1. Hero
2. Search CSP Content
3. Continue CSP
4. Today’s Plan
   - Learn
   - Practice
   - Remember
5. Progress Intelligence
6. Exam Readiness

Home remains a read-and-launch surface. It does not independently generate or persist a second daily plan.

## 2. Completed HOME-R phases

- HOME-R0 froze the implementation contract on the exact FR10 base.
- HOME-R1 removed obsolete Home launch surfaces and dead callback plumbing.
- HOME-R2 introduced one shared Learn / Practice / Remember category policy.
- HOME-R3 added the read-only Today’s Plan summary layer.
- HOME-R4 added live Home cards backed by the authoritative daily plan.
- HOME-R5 added filtered Today’s Plan entry without forking the plan.
- HOME-R6 added the shared plan execution router.
- HOME-R7 connected genuine activity evidence to planner completion.
- HOME-R8 relocated Bookmarked Questions to Settings → Learning & Progress.
- HOME-R9 added cross-phase closure validation, canonical formatting, regression hardening, and exact-SHA CI.

## 3. Important final behavior

### Search and continuity

Search CSP Content remains on Home.

Continue CSP remains independent from Today’s Plan and resumes through the existing learner-position service.

### Today’s Plan

Learn, Practice, and Remember cards are projections of the existing authoritative `DailyStudyPlan`.

Home does not create, clone, or regenerate a separate plan.

Filtered Today’s Plan views preserve the same plan and block identities.

### Execution

`StudyPlanBlockLauncher` is the shared execution boundary.

Learn routes to structured Study Content.

Practice routes through the protected published-question path and existing quiz runtime.

Remember uses real Study Content review until the separate Flashcards integration is merged later.

### Completion

Opening a route does not complete a task.

Planned Practice completion requires block-scoped assessment evidence.

Remember requires explicit post-start completion or re-completion evidence.

Learn retains the frozen explicit learner-finish fallback.

The completion path remains idempotent and feeds the existing M7E outcome/readiness pipeline.

### Bookmarks

Bookmarked Questions is available under Settings → Learning & Progress.

The existing bookmark screen and persistence keys are reused unchanged.

Home contains no bookmark destination or bookmark-shaped navigation affordance.

## 4. Final validation evidence

Exact implementation SHA `243d9fdf93c55775321468eb17ce85cd3b7c557f` passed GitHub Actions run `35735054680`.

Successful gates:

- exact SHA checkout and FR10 ancestry verification
- HOME-R frozen architecture verifier
- canonical Dart formatting check
- `flutter analyze --no-fatal-infos`
- HOME-R targeted tests
- M7D adaptive planner regressions
- M7E feedback/replanning regressions
- complete Flutter regression suite
- production web release build
- Android debug APK build

Observed results:

- HOME-R test group: 38 tests passed
- Home screen contract group: 30 tests passed
- Settings bookmark contract group: 4 tests passed
- M7D regressions: 149 tests passed
- M7E regressions: 61 tests passed
- full Flutter suite: 2746 tests passed, 1 skipped
- web: `build/web` produced successfully
- Android: `build/app/outputs/flutter-apk/app-debug.apk` produced successfully

The analyzer completed successfully. It reported 371 info-level lint notices; no analyzer error or warning caused the gate to fail.

## 5. Full-suite compatibility corrections made during closure

HOME-R9 identified and corrected stale tests that still described pre-HOME-R navigation.

The corrections did not restore removed features.

They updated legacy expectations so that:

- Practice is reached through the bottom-navigation `PracticeHubScreen`, not a generic Home Practice shortcut.
- Flashcards remain a bottom-navigation destination without requiring the removed Home callback.
- Quick Practice modes remain inside Practice Hub and are explicitly absent from Home.

## 6. Frozen non-goals preserved

HOME-R did not:

- redesign the adaptive planning algorithm
- create a second daily-plan store
- restore removed learner Firestore read paths
- migrate bookmark data
- implement the separate Flashcards phase
- rewrite Exam Readiness
- alter the canonical curriculum architecture
- invent missing content targets
- count route-open as completion
- merge the Startup Motion branch
- merge the separate Flashcard Core branch

## 7. Closure checkpoint

After this closure record is committed and its exact SHA passes the same `HOME-R Final Closure` workflow, create `phase-home-r-closed` from that exact green SHA.

That branch is the HOME-R recovery and later-integration checkpoint.
