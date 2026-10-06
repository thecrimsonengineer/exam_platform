# ERDP-10 Whole-System Acceptance Matrix

Status: CLOSED
Phase: ERDP-10
Required base: `phase-erdp9-closed-loop-retention-intelligence-closed@a2b4b2289e5a932d1a478c129e30b7816022119b`
Validated implementation head: `4725c4bf5648a1765e19df30a181da80c0f5de43`
Successful whole-system acceptance run: `37429778541`

## Primary journey

1. Generate DailyStudyPlan.
2. Start Learn through the universal execution router.
3. Complete Learn with qualifying study evidence.
4. Persist outcome and evidence.
5. Start Practice.
6. Complete Practice with qualifying assessment attempts.
7. Persist assessment evidence.
8. Start Remember.
9. Open the exact filtered Flashcard review target.
10. Rate cards and complete the review with qualifying recall evidence.
11. Persist retention evidence.
12. Skip a task.
13. Move a task to Tomorrow.
14. Replace a task.
15. Simulate app close/restart.
16. Verify all plan/action/evidence state survives.
17. Advance to the next day.
18. Verify carry-forward appears exactly once.
19. Complete the carried task.
20. Recalculate readiness.
21. Verify the next plan adapts to the new evidence state.

## Replacement paths

Where pedagogically valid, acceptance coverage must include:

- Learn -> Practice
- Learn -> Flashcards
- Practice -> Learn
- Practice -> Flashcards
- Flashcards -> Learn
- Flashcards -> Practice

## Failure and concurrency coverage

- double-tap Start
- double-tap Tomorrow
- double-tap Replace
- navigation failure
- persistence failure
- cloud timeout
- stale plan
- missing or retired content
- missing Flashcard package
- missing LAB
- authentication loss
- offline startup
- reconnect
- app termination during activity
- app termination during persistence
- cross-device recovery where supported

## Platform and presentation matrix

- Android
- Web
- Windows
- light mode
- dark mode
- motion on
- motion off
- authenticated cloud state
- offline/failure state

## Non-negotiable closure invariants

ERDP-10 must not close with any known instance of:

- decorative Daily Plan controls
- duplicate carry-forward tasks
- false completions
- passive readiness inflation
- orphan execution attempts
- competing DailyStudyPlan sources
- competing readiness sources
- known persistence divergence

## Validation strategy

ERDP-10 uses layered evidence:

1. deterministic service-level integration tests for the complete learner loop;
2. persistence/restart tests using the real local repositories;
3. failure-injection tests at execution and persistence boundaries;
4. regression suites from ERDP-0 through ERDP-9;
5. Flashcard cloud, M7D Daily Plan, LAB runtime and relevant startup/auth regressions;
6. platform build/compile gates where repository CI supports them;
7. final read-only diff hygiene and repository non-mutation checks.

No acceptance result may claim coverage for a platform, cloud failure, or cross-device condition that was not actually exercised.

## Final checkpoint

`phase-erdp-learner-intelligence-closed`
