# ERDP-10 Whole-System Acceptance Closure

Status: CLOSED
Phase: ERDP-10
Program: Exam Readiness + Daily Plan Learner Intelligence
Working branch: `phase-erdp10-whole-system-acceptance`
Required base: `phase-erdp9-closed-loop-retention-intelligence-closed@a2b4b2289e5a932d1a478c129e30b7816022119b`
Validated implementation head before closure record: `4725c4bf5648a1765e19df30a181da80c0f5de43`
Successful whole-system acceptance run: `37429778541`

## Closure decision

ERDP-10 is accepted for production freeze.

The complete learner-intelligence loop passed the authoritative whole-system acceptance workflow on the clean implementation checkpoint after diagnostic scaffolding was removed.

No ERDP-11 is defined by the frozen implementation plan. ERDP-10 is the terminal ERDP stage.

## Corrected acceptance blocker

During ERDP-10 acceptance, INT-R7 exposed a Home startup integration defect.

The Home study-content search panel constructed the remote search token provider during widget initialization. That constructor immediately resolved `FirebaseAuth.instance`, which required a default Firebase app even though no learner search had been initiated. In the widget acceptance environment this caused `[core/no-app]`, prevented the Home search surface from rendering, and produced cascading widget cleanup assertions.

The correction defers creation of the Firebase learner access token provider until an actual protected remote search is performed. Rendering Home no longer requires Firebase Auth initialization solely because the search panel exists.

The diagnostic INT-R7 trace instrumentation was removed before final acceptance.

## Successful acceptance evidence

GitHub Actions run `37429778541` completed the authoritative ERDP-10 workflow successfully on `4725c4bf5648a1765e19df30a181da80c0f5de43`.

Validation passed:

- canonical ERDP-10 formatting;
- ERDP-10 surface analysis;
- ERDP-0 through ERDP-10 regressions;
- Flashcard cloud regressions;
- M7D Daily Plan regressions;
- Home/Startup INT-R3;
- Home/Startup INT-R4;
- Home/Startup INT-R5;
- Home/Startup INT-R7;
- Home/Startup INT-R9A3;
- Home/Startup INT-R9A4;
- LAB regressions;
- LAB quality regressions;
- learner online-access regressions;
- authentication regressions;
- startup regressions;
- security contract regressions;
- diff hygiene;
- repository non-mutation verification.

Platform gates passed on the same checkpoint:

- Web release build;
- Android debug APK build;
- Windows debug build.

## Frozen ERDP invariants

1. `DailyStudyPlan` remains the single authoritative daily plan.
2. The existing Exam Readiness engine remains the single authoritative readiness calculation.
3. Home projects the authoritative DailyStudyPlan and does not create a second planner.
4. Activities emit evidence and do not write readiness directly.
5. Starting or opening an activity never counts as completion.
6. Flashcard recall remains supporting retention evidence and cannot independently establish strong readiness.
7. Question, LAB and simulation evidence remain stronger readiness evidence.
8. Skip, Tomorrow and Replace remain persisted, auditable and non-decorative.
9. Tomorrow carry-forward remains idempotent and cannot duplicate work.
10. Replacement preserves the learner objective where pedagogically valid.
11. Execution attempts remain persisted before navigation and cannot be orphaned by successful flow.
12. No known persistence divergence is accepted at closure.
13. Protected learner search initializes Firebase token access only when a protected search is actually executed.
14. ERDP-10 is the terminal ERDP phase. There is no ERDP-11.

## Final checkpoint

The immutable ERDP program checkpoint is:

`phase-erdp-learner-intelligence-closed`

That branch must be created only after this closure-record commit passes the same read-only ERDP-10 acceptance workflow.
