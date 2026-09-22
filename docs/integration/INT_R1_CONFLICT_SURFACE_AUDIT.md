# INT-R1 — Home R + Startup Motion Conflict / Surface Audit

Status: CLOSED AUDIT CANDIDATE  
Working branch: `phase-home-startup-integration`  
INT-R0 base checkpoint: `949c12ceb0ce314fc9ab7c6673f046d8f36c7b6e`

## 1. Inputs audited

Home R closed input:

- branch: `phase-home-r-closed`
- SHA: `243d9fdf93c55775321468eb17ce85cd3b7c557f`

Startup Motion closed input:

- branch: `phase-startup-motion-closed`
- SHA: `9c1697b1d01c8db85fe535bc77ea6b6aa6f39565`

Integration audit branch before this document:

- branch: `phase-home-startup-integration`
- SHA: `949c12ceb0ce314fc9ab7c6673f046d8f36c7b6e`

True common ancestor used for the two-sided change audit:

`bf01d8fd2776cc7e741f6811d1640105e4496f35`

## 2. Git-level result

The branches remain intentionally divergent before structural merge.

From the true common ancestor:

- Home/integration side changed files: **43**
- Startup Motion side changed files: **22**
- Files changed by both sides: **0**
- Direct overlapping paths: **none**

### Finding

No textual/content-path conflict is currently predicted from the two-sided file map.

This does **not** mean integration is risk-free. Startup Motion changes application bootstrap and dependency/asset registration on files that Home R itself did not modify after the common ancestor. Those are semantic integration surfaces and must still be reviewed deliberately.

## 3. Primary semantic integration surfaces

### 3.1 `lib/main.dart` — HIGH semantic importance

Startup Motion adds:

- `screens/startup/csp11_startup_screen.dart`
- `home: const Csp11StartupScreen(child: AuthGate())`

Home R does not modify `lib/main.dart` on its side of the common ancestor, so Git should be able to apply this change without a textual conflict.

Architectural observation:

`Csp11StartupScreen` returns a `Stack` containing `widget.child` underneath the startup overlay. Therefore `AuthGate` is mounted while Startup Motion is visible.

This is **not** a duplicate MaterialApp or duplicate app shell. It is an overlay around the existing child.

INT-R3 must nevertheless validate the intended handoff contract:

```text
MaterialApp
  ↓
Csp11StartupScreen
  ├─ existing AuthGate/application child
  └─ temporary startup overlay
       ↓ dismissed
existing child remains
```

The integration must explicitly test that this creates one application root, one navigator/application shell, and one Home destination.

### 3.2 `pubspec.yaml` — MEDIUM/HIGH packaging importance

Startup Motion adds:

- `lottie: ^3.6.1`
- `flutter_animate: ^4.5.2`
- `assets/startup/`

Home R does not modify `pubspec.yaml` on its side of the common ancestor.

INT-R4 must verify dependency resolution and confirm that the startup asset is packaged exactly once.

`flutter_animate` is retained as part of the closed Startup Motion dependency contract unless later validation proves it is unnecessary and a separately approved cleanup is made. INT-R1 performs no dependency cleanup.

### 3.3 Startup personalization — READ-ONLY cross-system seam

`lib/screens/startup/startup_personalization_service.dart` reads:

- `StudentLearningPositionService`
- `DailyStudyPlanRepository`
- current plan block statuses

The default plan load is:

`loadLatestForDate(date, refreshRemote: false)`

The service:

- does not generate a plan
- does not refresh remote state
- does not classify blocks into Home Learn/Practice/Remember categories
- does not update plan lifecycle state
- does not update learner position
- does not mark work complete

Therefore it is compatible with the frozen HOME-R planner invariant at audit time.

INT-R5 should lock this with integration tests.

## 4. Navigation and shell findings

Home R changes navigation and Home behavior downstream of `AuthGate`, including Home, Today’s Plan, Settings, quiz/study flows and related contracts.

Startup Motion does not modify:

- Home screens
- bottom navigation
- Settings screens
- Today’s Plan screens
- Study Content screens
- quiz screens
- planner services

Home R does not modify Startup Motion files.

This separation makes the expected integration seam narrow:

```text
main.dart / MaterialApp
        ↓
Csp11StartupScreen
        ↓
AuthGate
        ↓
existing role routing
        ↓
existing learner shell
        ↓
HOME-R
```

## 5. Workflow / CI coexistence

Home R adds:

- `.github/workflows/home_r_final_closure.yml`

Startup Motion adds:

- `.github/workflows/startup_motion_autofmt.yml`
- `.github/workflows/startup_motion_platform_closure.yml`
- `.github/workflows/startup_motion_validation.yml`

The workflow filenames do not collide.

INT-R6 through INT-R8 should preserve both focused validation families and add integration-specific validation rather than replacing either family.

## 6. Platform surface findings

Startup Motion does not modify Android, Web, or Windows project files directly relative to the common ancestor.

Its platform-facing changes are:

- startup Lottie asset
- pubspec dependency registration
- pubspec asset registration
- multi-platform validation workflows

Therefore no platform project-file merge conflict is predicted.

Platform risk remains packaging/rendering risk, which belongs to INT-R4 and INT-R8.

## 7. Full file classification

Classification meanings:

- **HOME ONLY**: production/docs change unique to Home/integration side
- **STARTUP ONLY**: production/docs change unique to Startup side
- **SHARED**: directly edited on both sides
- **POTENTIAL CONFLICT**: semantic integration hot spot requiring deliberate review even without a textual overlap
- **PLATFORM**: asset or platform packaging surface
- **TEST/CI**: tests, tooling, or workflow validation

| Side | File | Git status | Changes | Classification | Audit note |
|---|---|---:|---:|---|---|
| Home R / integration | `.github/workflows/home_r_final_closure.yml` | added | 80 | TEST/CI | Home closure workflow; should coexist with Startup workflows. |
| Home R / integration | `docs/integration/HOME_STARTUP_INTEGRATION_PLAN.md` | added | 299 | HOME ONLY |  |
| Home R / integration | `lib/features/exam_readiness/models/study_plan_execution_target.dart` | added | 38 | HOME ONLY |  |
| Home R / integration | `lib/features/exam_readiness/models/today_plan_summary.dart` | added | 90 | HOME ONLY |  |
| Home R / integration | `lib/features/exam_readiness/models/today_plan_task_category.dart` | added | 1 | HOME ONLY |  |
| Home R / integration | `lib/features/exam_readiness/navigation/study_plan_block_launcher.dart` | added | 128 | HOME ONLY |  |
| Home R / integration | `lib/features/exam_readiness/screens/study_plan_practice_session_screen.dart` | added | 295 | HOME ONLY |  |
| Home R / integration | `lib/features/exam_readiness/screens/todays_plan_screen.dart` | modified | 568 | HOME ONLY |  |
| Home R / integration | `lib/features/exam_readiness/services/study_plan_completion_evidence_service.dart` | added | 198 | HOME ONLY |  |
| Home R / integration | `lib/features/exam_readiness/services/study_plan_outcome_service.dart` | modified | 3 | HOME ONLY |  |
| Home R / integration | `lib/features/exam_readiness/services/today_plan_presentation_filter.dart` | added | 26 | HOME ONLY |  |
| Home R / integration | `lib/features/exam_readiness/services/today_plan_summary_service.dart` | added | 104 | HOME ONLY |  |
| Home R / integration | `lib/features/exam_readiness/services/today_plan_task_category_policy.dart` | added | 49 | HOME ONLY |  |
| Home R / integration | `lib/models/student_learning_progress.dart` | modified | 32 | HOME ONLY |  |
| Home R / integration | `lib/screens/courses/csp/quiz/quiz_screen.dart` | modified | 27 | HOME ONLY |  |
| Home R / integration | `lib/screens/courses/csp/study_subtopic_screen_dark.dart` | modified | 29 | HOME ONLY |  |
| Home R / integration | `lib/screens/courses/csp/study_subtopic_screen.dart` | modified | 29 | HOME ONLY |  |
| Home R / integration | `lib/screens/home/home_screen_dark.dart` | modified | 72 | HOME ONLY |  |
| Home R / integration | `lib/screens/home/home_screen.dart` | modified | 72 | HOME ONLY |  |
| Home R / integration | `lib/screens/settings/settings_screen_dark.dart` | modified | 25 | HOME ONLY |  |
| Home R / integration | `lib/screens/settings/settings_screen.dart` | modified | 25 | HOME ONLY |  |
| Home R / integration | `lib/services/student_learning_progress_service.dart` | modified | 1 | HOME ONLY |  |
| Home R / integration | `lib/widgets/csp/home/today_plan_home_section.dart` | added | 473 | HOME ONLY |  |
| Home R / integration | `test/features/exam_readiness/home_r/home_r2_task_category_policy_test.dart` | added | 126 | TEST/CI |  |
| Home R / integration | `test/features/exam_readiness/home_r/home_r3_today_plan_summary_service_test.dart` | added | 358 | TEST/CI |  |
| Home R / integration | `test/features/exam_readiness/home_r/home_r5_today_plan_presentation_filter_test.dart` | added | 129 | TEST/CI |  |
| Home R / integration | `test/features/exam_readiness/home_r/home_r6_planned_practice_screen_test.dart` | added | 110 | TEST/CI |  |
| Home R / integration | `test/features/exam_readiness/home_r/home_r6_study_plan_block_launcher_test.dart` | added | 175 | TEST/CI |  |
| Home R / integration | `test/features/exam_readiness/home_r/home_r7_completion_evidence_service_test.dart` | added | 317 | TEST/CI |  |
| Home R / integration | `test/features/exam_readiness/home_r/home_r7_student_progress_review_timestamp_test.dart` | added | 55 | TEST/CI |  |
| Home R / integration | `test/features/exam_readiness/m7e/m7e_runtime_integration_test.dart` | modified | 39 | TEST/CI |  |
| Home R / integration | `test/features/lab/lab1_shells_test.dart` | modified | 2 | TEST/CI |  |
| Home R / integration | `test/features/learning_twin/integration/m6_1_practice_modes_architecture_test.dart` | modified | 15 | TEST/CI |  |
| Home R / integration | `test/screens/courses/csp/csp11_p6_3_remaining_dark_mode_contract_test.dart` | modified | 9 | TEST/CI |  |
| Home R / integration | `test/screens/home/home_r1_cleanup_contract_test.dart` | modified | 6 | TEST/CI |  |
| Home R / integration | `test/screens/home/home_r4_live_plan_contract_test.dart` | added | 51 | TEST/CI |  |
| Home R / integration | `test/screens/home/home_r4_today_plan_home_section_test.dart` | added | 211 | TEST/CI |  |
| Home R / integration | `test/screens/home/home_r5_filtered_today_plan_contract_test.dart` | added | 44 | TEST/CI |  |
| Home R / integration | `test/screens/home/home_r6_execution_router_contract_test.dart` | added | 97 | TEST/CI |  |
| Home R / integration | `test/screens/home/home_r7_completion_integration_contract_test.dart` | added | 122 | TEST/CI |  |
| Home R / integration | `test/screens/home/home_r9_closure_contract_test.dart` | added | 130 | TEST/CI |  |
| Home R / integration | `test/screens/settings/home_r8_bookmark_relocation_contract_test.dart` | added | 93 | TEST/CI |  |
| Home R / integration | `tools/verify_home_r_contract.py` | added | 206 | TEST/CI |  |
| Startup Motion | `.github/workflows/startup_motion_autofmt.yml` | added | 54 | TEST/CI | Startup validation/closure workflow; should coexist with Home workflow. |
| Startup Motion | `.github/workflows/startup_motion_platform_closure.yml` | added | 236 | TEST/CI | Startup validation/closure workflow; should coexist with Home workflow. |
| Startup Motion | `.github/workflows/startup_motion_validation.yml` | added | 77 | TEST/CI | Startup validation/closure workflow; should coexist with Home workflow. |
| Startup Motion | `assets/startup/csp11_startup_master.json` | added | 1 | PLATFORM | Startup asset. Must remain packaged on Android/Web/Windows. |
| Startup Motion | `docs/startup/CSP11_STARTUP_MOTION_FREE_STACK_FREEZE.md` | added | 301 | STARTUP ONLY |  |
| Startup Motion | `docs/startup/SM1_GLAXNIMATE_MASTER_ARTWORK.md` | added | 75 | STARTUP ONLY |  |
| Startup Motion | `docs/startup/SM2_CHOREOGRAPHY.md` | added | 128 | STARTUP ONLY |  |
| Startup Motion | `docs/startup/SM3_PERSONALIZATION.md` | added | 195 | STARTUP ONLY |  |
| Startup Motion | `docs/startup/SM4_ACCESSIBILITY_PERFORMANCE.md` | added | 200 | STARTUP ONLY |  |
| Startup Motion | `docs/startup/SM5_PLATFORM_CLOSURE.md` | added | 204 | STARTUP ONLY |  |
| Startup Motion | `lib/main.dart` | modified | 3 | POTENTIAL CONFLICT | Bootstrap seam. Startup adds Csp11StartupScreen(child: AuthGate()). No Home-side textual edit, but requires INT-R3 semantic review. |
| Startup Motion | `lib/screens/startup/csp11_startup_screen.dart` | added | 986 | STARTUP ONLY |  |
| Startup Motion | `lib/screens/startup/startup_motion_policy.dart` | added | 74 | STARTUP ONLY | Startup validation/closure workflow; should coexist with Home workflow. |
| Startup Motion | `lib/screens/startup/startup_personalization_service.dart` | added | 186 | STARTUP ONLY | Read-only cross-system seam: reads local learning position and DailyStudyPlan with refreshRemote:false; no plan writes or classification. |
| Startup Motion | `lib/screens/startup/startup_timeline.dart` | added | 70 | STARTUP ONLY |  |
| Startup Motion | `pubspec.yaml` | modified | 3 | POTENTIAL CONFLICT | Dependency/asset seam. Startup adds lottie, flutter_animate and assets/startup/. No Home-side textual edit. |
| Startup Motion | `test/startup/csp11_startup_asset_contract_test.dart` | added | 55 | TEST/CI |  |
| Startup Motion | `test/startup/startup_motion_policy_test.dart` | added | 74 | TEST/CI | Startup validation/closure workflow; should coexist with Home workflow. |
| Startup Motion | `test/startup/startup_personalization_service_test.dart` | added | 190 | TEST/CI |  |
| Startup Motion | `test/startup/startup_release_render_smoke_test.dart` | added | 79 | TEST/CI |  |
| Startup Motion | `test/startup/startup_screen_hardening_test.dart` | added | 97 | TEST/CI |  |
| Startup Motion | `test/startup/startup_timeline_test.dart` | added | 33 | TEST/CI |  |

## 8. Conflict matrix

| Surface | Textual conflict predicted? | Semantic risk | Required handling |
|---|---|---|---|
| `lib/main.dart` | No | High | Review merge result in INT-R3. Preserve single MaterialApp, Startup overlay and AuthGate handoff. |
| `pubspec.yaml` | No | Medium/High | Preserve Startup dependencies and asset registration. Validate in INT-R4. |
| Startup personalization | No | Medium | Preserve local/read-only behavior. Add state-isolation contracts in INT-R5. |
| Home screens | No | Low | Startup does not edit them. Regress in INT-R6. |
| Today’s Plan/planner | No | Medium | Startup reads local plan summary only. Prove no writes/regeneration in INT-R5/R6. |
| Bottom navigation | No | Low/Medium | Startup does not edit it. Verify one shell after overlay dismissal. |
| Startup asset | No | Medium | Validate pubspec registration and release packaging. |
| Android/Web/Windows project files | No | Low textual / Medium runtime | No direct Startup project-file edits. Validate release builds in INT-R8. |
| CI workflows | No | Low | Unique filenames. Preserve both validation families. |

## 9. INT-R2 merge expectation

Based on the audited two-sided file map, the structural merge is expected to be Git-clean.

Expected merge behavior:

1. Startup-only files are added.
2. `lib/main.dart` receives the Startup wrapper change.
3. `pubspec.yaml` receives the Startup dependencies and asset path.
4. Home R production files remain unchanged by the merge.
5. Both validation workflow families coexist.

This is an expectation, not permission to skip inspection.

Immediately after INT-R2 merge, inspect:

- `lib/main.dart`
- `pubspec.yaml`
- `Csp11StartupScreen`
- Startup personalization service
- Home R Home
- bottom navigation
- integration ancestry

## 10. R1 non-actions

INT-R1 intentionally performs no:

- Startup merge
- production Dart edit
- dependency edit
- asset edit
- conflict resolution
- test weakening
- Home redesign
- Startup redesign
- main-branch integration

## 11. INT-R1 closure definition

INT-R1 is complete when:

1. both source closed SHAs remain unchanged
2. the true common ancestor is recorded
3. all changed files on both sides are inventoried
4. every changed file is classified
5. direct overlap count is recorded
6. semantic integration surfaces are documented
7. expected merge behavior is documented
8. no production code has changed
9. no merge has occurred
10. the audit document is committed and frozen as an INT-R1 recovery checkpoint

## 12. Next action

Proceed to **INT-R2 — Structural Merge** from the exact frozen INT-R1 checkpoint.

INT-R2 must merge `phase-startup-motion-closed` into `phase-home-startup-integration`, then inspect the resulting shared/runtime surfaces before any further integration changes.
