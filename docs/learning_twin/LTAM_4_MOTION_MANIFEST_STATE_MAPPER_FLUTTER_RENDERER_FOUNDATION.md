# CSP11 LTAM-4: Motion Manifest, State Mapper and Flutter Renderer Foundation

**Status:** FROZEN IMPLEMENTATION PLAN  
**Freeze date:** 2026-09-23  
**Repository:** thecrimsonengineer/exam_platform  
**Branch:** phase-learning-twin-motion-avatar  
**Baseline commit:** 050bc825fd905a4cc2b96d3f112ad2d4779b09af  
**Parent:** LTAM-3 Learning Twin Motion State Library  
**Canonical Twin identity:** Naveed • Learning Guide  
**Runtime stack:** Flutter + Lottie + flutter_svg  
**Supported platforms:** Android, Web, Windows

## 1. Purpose

LTAM-4 introduces the presentation-side software foundation that connects the existing CSP11 Learning Twin to the validated motion asset library.

This phase does not redesign Learning Twin logic and does not create a second Twin system.

~~~text
Existing Learning Twin domain state
        ↓
LearningTwinMotionMapper
        ↓
LearningTwinMotionState
        ↓
LearningTwinMotionManifest
        ↓
LearningTwinMotionPolicy
        ↓
LearningTwinMotionController
        ↓
LearningTwinMotionRenderer
        ↓
Lottie asset
        ↓
static SVG fallback
~~~

The existing Learning Twin remains the source of truth for all learner-facing decisions.

## 2. Architectural boundary

The motion system is presentation-only.

The domain layer must never know Lottie filenames, asset paths, animation duration, loop settings, frame rate, render-cache settings, animation-controller details, reduced-motion implementation, or static fallback paths.

Frozen dependency direction:

~~~text
domain
  ↓
presentation mapper
  ↓
motion presentation model
  ↓
renderer/controller
  ↓
Lottie / flutter_svg
~~~

Forbidden:

~~~text
domain
  ↓
Lottie package
~~~

Forbidden:

~~~text
decision service
  ↓
assets/learning_twin/motion/twin_celebrate.json
~~~

## 3. Existing contracts preserved

LTAM-4 must preserve:

- LearningTwinState
- LearningTwinTrigger
- LearningTwinMessage
- deterministic decision-service behavior
- LearningTwinCard behavior
- LearningTwinHero behavior
- LearningTwinCelebration behavior
- LearningTwinAvatar semantics
- dismissal behavior
- one-unsolicited-intervention-per-visit rule
- exam suppression
- Study Hub behavior
- Domain guidance behavior
- Competency guidance behavior
- Practice/Quiz coaching behavior
- progress interpretation
- readiness logic

No domain-state rename is allowed merely to make animation easier.

## 4. Existing runtime dependencies

The current project already contains Lottie 3.6.1, flutter_svg 2.2.0, and flutter_animate 4.5.2.

LTAM-4 introduces no new runtime animation dependency unless a proven blocking defect requires it.

Glaxnimate remains an authoring tool and is not a runtime dependency.

## 5. Target presentation files

~~~text
lib/features/learning_twin/ui/
├── learning_twin_asset.dart
├── learning_twin_avatar.dart
├── learning_twin_motion_state.dart
├── learning_twin_motion_descriptor.dart
├── learning_twin_motion_manifest.dart
├── learning_twin_motion_mapper.dart
├── learning_twin_motion_policy.dart
├── learning_twin_motion_controller.dart
├── learning_twin_motion_renderer.dart
├── learning_twin_motion_fallback.dart
└── learning_twin_motion_error.dart
~~~

Names may be adjusted to repository conventions, but responsibilities must remain separated.

## 6. Motion-state enum

Create a presentation-only enum containing:

~~~text
idle
welcome
thinking
explain
insightReady
focus
encourage
celebrate
checkpoint
examReady
resultReview
reducedMotion
~~~

This enum is not a replacement for LearningTwinState. It is a visual vocabulary.

## 7. State-mapper responsibility

LearningTwinMotionMapper has exactly one business-neutral responsibility:

~~~text
LearningTwinState
        ↓
LearningTwinMotionState
~~~

It must not inspect learner scores, calculate readiness, decide whether guidance should show, decide remediation, navigate, fetch data, read Firestore/Supabase, or alter LearningTwinSessionState.

## 8. Exhaustive mapping

Frozen mapping:

~~~text
idle         -> idle
welcome      -> welcome
explain      -> explain
tip          -> insightReady
important    -> focus
warning      -> focus
encourage    -> encourage
celebrate    -> celebrate
remediate    -> focus
recommend    -> insightReady
checkpoint   -> checkpoint
examReady    -> examReady
resultReview -> resultReview
~~~

Use an exhaustive Dart switch.

A future domain-state addition must force explicit review rather than silently falling through a string map.

## 9. Reduced-motion override

Reduced motion is not a Learning Twin domain state.

It is a presentation override:

~~~text
mapped motion state
        +
motion policy
        ↓
effective visual mode
~~~

If reduced motion is active, any motion state resolves to a static fallback.

Do not mutate LearningTwinState to represent accessibility.

## 10. Motion descriptor

Create an immutable UI-side descriptor carrying:

- motion state
- Lottie asset path
- fallback SVG path
- loop flag
- duration
- priority
- motion intensity

It must not carry learner scores, content, competency IDs, or business decisions.

## 11. Motion manifest

Create:

~~~text
assets/learning_twin/manifest/
└── twin_motion_manifest.json
~~~

The manifest is bundled locally and never fetched remotely.

It configures known motion states with asset path, fallback path, loop flag, duration, priority, and motion intensity.

## 12. Manifest schema

Conceptual V1 schema:

~~~json
{
  "schema_version": 1,
  "twin_id": "naveed_learning_guide",
  "default_state": "idle",
  "states": {
    "idle": {
      "asset": "assets/learning_twin/motion/twin_idle.json",
      "fallback": "assets/learning_twin/naveed_twin.svg",
      "loop": true,
      "duration_ms": 6000,
      "priority": 0,
      "motion_intensity": 1
    }
  }
}
~~~

All V1 states must be present.

## 13. Fail-closed manifest behavior

If the motion manifest is invalid:

~~~text
manifest invalid
      ↓
animated mode disabled
      ↓
existing static SVG used
      ↓
Learning Twin message/action continues
~~~

Animation failure must never suppress guidance.

## 14. Manifest validation

Validate at least:

- supported schema version
- valid twin_id
- default state exists
- every canonical V1 state exists
- non-empty asset and fallback paths
- valid boolean loop field
- positive duration
- valid priority
- motion intensity between 0 and 3
- no duplicate state keys
- no remote URL
- no path traversal
- no unsupported required state

Invalid manifests fall back to static mode.

## 15. No remote asset policy

Reject HTTP and HTTPS motion asset paths.

V1 Learning Twin animation is local-only.

## 16. Canonical motion asset paths

~~~text
assets/learning_twin/motion/
├── twin_idle.json
├── twin_welcome.json
├── twin_thinking.json
├── twin_explain.json
├── twin_insight_ready.json
├── twin_focus.json
├── twin_encourage.json
├── twin_celebrate.json
├── twin_checkpoint.json
├── twin_exam_ready.json
└── twin_result_review.json
~~~

## 17. Static fallback mapping

~~~text
idle          -> naveed_twin.svg
welcome       -> naveed_twin.svg
thinking      -> naveed_twin.svg
explain       -> naveed_twin_explain.svg
insightReady  -> naveed_twin_explain.svg
focus         -> naveed_twin.svg
encourage     -> naveed_twin.svg
celebrate     -> naveed_twin_success.svg
checkpoint    -> naveed_twin_success.svg
examReady     -> neutral/success fallback after visual review
resultReview  -> naveed_twin_explain.svg
~~~

The examReady fallback must not imply guaranteed exam success.

## 18. Motion policy

LearningTwinMotionPolicy decides whether animation is allowed at presentation time.

It may consider:

- animationEnabled
- platform reduced-motion/disabled-animation state
- widget visibility
- application lifecycle state
- compact-surface policy
- optional developer override

It must not inspect learner performance.

## 19. Initial policy inputs

A simple policy input may carry animation enabled, platform animations disabled, visibility, app-active state, and presentation size.

Do not over-engineer the policy in V1.

## 20. Accessibility source

Use Flutter/platform accessibility settings as the authoritative reduced-motion input where supported.

A future user preference may further restrict motion, but must not override a platform request to reduce motion.

## 21. Static fallback conditions

Use SVG fallback when:

- reduced motion is active
- animation is globally disabled
- manifest invalid
- requested state missing
- Lottie asset missing
- Lottie parse fails
- policy denies playback
- runtime animation failure occurs

Surrounding layout must remain stable.

## 22. Renderer responsibility

LearningTwinMotionRenderer renders only the visual character.

It returns either Lottie or static SVG.

It does not render title, message, CTA, dismiss button, learner score, progress text, or domain labels.

## 23. Renderer inputs

The renderer should accept presentation information such as state, size, animation-enabled flag, decorative semantics flag, semantic label, optional event key, and optional completion callback.

Exact constructor shape should follow existing code style.

## 24. Preserve LearningTwinAvatar façade

LearningTwinAvatar remains the compatibility façade.

~~~text
LearningTwinAvatar
      ↓
motion requested?
      ├── no -> existing SVG
      └── yes
            ↓
        MotionPolicy
            ↓
        MotionRenderer
            ↓
        Lottie or SVG fallback
~~~

Legacy callers must not be forced to migrate at once.

## 25. Backward compatibility

Existing calls that specify only LearningTwinAsset and size must still compile and render correctly.

Motion support is additive.

## 26. Production default during LTAM-4

Production callers remain static by default.

The new motion foundation may be exercised by an isolated developer preview.

Learner-facing rollout is deliberately deferred.

## 27. Controller responsibility

LearningTwinMotionController owns playback mechanics:

- start
- stop
- loop
- one-shot completion
- idle return
- hold-state handling
- replay protection
- interruption
- priority
- pending state
- lifecycle/disposal

It must not choose learning messages.

## 28. Controller presentation state

Allowed controller data includes current motion state, current event key, isPlaying, isLooping, one pending state, and last completed event key.

No learner profile belongs here.

## 29. Event key

One-shot motion may receive a stable event key such as LearningTwinMessage ID, milestone ID, checkpoint ID, or result-review event ID.

Same state plus same completed event key does not replay on unrelated rebuild.

## 30. Replay rule

~~~text
same motion state
+
same event key
+
already completed
        ↓
do not replay
~~~

Debug tooling may explicitly override this.

## 31. Idle behavior

Idle is not event-based.

It may loop while visible and permitted.

Rebuilds should not cause obvious resets when controller continuity is preserved.

## 32. Thinking behavior

Thinking is interruptible.

When the wait condition ends, transition to the new meaningful state or idle without waiting for an arbitrary number of loops.

## 33. One-shot completion

Welcome, insightReady, encourage, celebrate, checkpoint, and examReady are one-shot visual reactions.

Default completion target is idle.

## 34. Hold-state completion

Explain, focus, and resultReview may end on a stable hold pose before returning to idle.

The controller may support a short hold duration, but no indefinite full-body motion is required.

## 35. Priority model

Frozen relative priority:

~~~text
celebrate       100
checkpoint       90
examReady        80
resultReview     70
focus            60
insightReady     50
explain          40
encourage        30
welcome          20
thinking         10
idle              0
~~~

## 36. Interruption policy

- idle is always interruptible
- thinking is interruptible by higher-priority meaningful states
- high-priority one-shots normally complete
- lower-priority ambient states cannot replace a high-priority one-shot
- reduced motion immediately overrides animated playback

## 37. Pending-state rule

Maintain at most one meaningful pending visual state.

Do not create an unbounded animation queue.

## 38. No animation storm

Collapse redundant visual reactions rather than playing a rapid chain of events.

Learning messages remain available as text even when a lower-priority visual reaction is dropped.

## 39. Lifecycle handling

Controller must safely handle initialization, rebuilds, app background/resume, route visibility, and disposal.

No disposed controller may continue ticking.

## 40. Off-screen behavior

Pause or stop loops when the Twin is clearly off-screen or route-inactive where practical.

Ambient idle may resume later. Completed one-shots do not replay without a new event.

## 41. Render caching

Use Lottie render caching only after measurement.

Do not globally enable memory-heavy caching by assumption.

## 42. Asset preloading

Do not preload all motion assets at app startup.

Allowed strategy:

- lazy-load on first Twin use
- optionally warm idle on a known Twin route
- load one-shot states on demand
- rely on Flutter's normal asset caching afterward

Startup and login must never wait for Learning Twin motion assets.

## 43. Error handling

Provide presentation-side diagnostics for manifest parse failure, missing asset, Lottie parse failure, unsupported state, and controller failure.

Errors must never bubble into a learner-visible crash.

## 44. Fail-soft UX

If motion fails:

~~~text
message remains
+
static avatar remains
+
action remains
+
dismiss remains
~~~

Only motion disappears.

## 45. Semantics

Preserve existing decorative vs meaningful semantics.

- decorative avatar -> excluded from semantics
- meaningful avatar -> one concise image label
- internal Lottie layers -> no semantics
- breathing/blinking -> never announced
- parent card -> owns message semantics
- celebration parent -> owns live-region semantics

## 46. Avoid duplicate announcements

Do not announce the same avatar/state redundantly from both renderer and parent surface.

## 47. Size handling

Continue supporting direct numeric size unless a small enum materially simplifies existing APIs.

Do not introduce a size abstraction solely for architectural neatness.

## 48. Compact policy

Compact surfaces may later suppress FX or use static fallback.

Do not create a different business state for compact rendering.

## 49. Hero policy

Hero surfaces may use the same motion state at larger scale.

No separate hero-domain state is required.

## 50. Manifest loader

Create a small UI-side loader responsible for bundled JSON loading, parsing, validation, immutable descriptor exposure, caching, and safe failure.

No network access.

## 51. Manifest caching

Parse once per app/session where practical.

Do not parse JSON on every widget build.

## 52. Mapper tests

Test every current LearningTwinState mapping.

The mapping test should be exhaustive enough to reveal accidental drift.

## 53. Manifest tests

Test valid manifest plus malformed JSON, unsupported schema, missing default state, missing canonical state, invalid duration, invalid intensity, remote URL, and malformed paths.

Every invalid case must resolve to static-safe behavior.

## 54. Policy tests

Test animations enabled, disabled, reduced motion, visibility, app-inactive state, and invalid manifest behavior.

Policy tests should not require learner data.

## 55. Controller tests

Test:

- idle loop
- one-shot completion
- return to idle
- thinking interruption
- priority handling
- lower-priority suppression
- same event key replay suppression
- new event key replay
- one pending state
- disposal
- app inactive behavior

Use deterministic fake timing where practical.

## 56. Renderer tests

Test:

- Lottie selected when permitted
- SVG selected for reduced motion
- SVG selected when motion asset fails
- SVG selected when manifest fails
- semantics
- decorative mode
- size stability
- transparent layout stability

## 57. LearningTwinAvatar compatibility tests

Verify neutral, explain, success, and hero legacy calls still render.

Existing callers should not know motion infrastructure exists.

## 58. Architecture guard

Add a regression check preventing the Learning Twin domain/coaching folders from importing the Lottie package or directly referencing assets/learning_twin/motion.

Motion paths belong in UI/presentation.

## 59. Production-rollout gate

LTAM-4 ends with infrastructure ready but learner-facing rollout still gated.

This is intentional.

## 60. Developer preview

Extend the isolated motion preview to use the real mapper, manifest, policy, controller, and renderer.

The preview should support:

- select LearningTwinState
- view mapped motion state
- reduced-motion toggle
- animation-enabled toggle
- event-key simulation
- replay
- size
- background
- return to idle
- simulated missing asset/invalid manifest in debug mode

It must remain outside learner navigation.

## 61. Dart vs manifest authority

Dart code defines the supported visual-state vocabulary.

The manifest configures known states.

Unknown manifest state names are rejected or ignored, never used to invent runtime enum values.

## 62. Manifest versioning

Start with schema_version 1.

Incompatible future schema changes increment the version.

Unsupported versions fail to static mode.

## 63. V1 metadata

Each manifest state should carry:

- state ID
- Lottie asset
- fallback SVG
- loop
- duration
- priority
- motion intensity

## 64. Pubspec handling

Confirm that the existing assets/learning_twin declaration packages nested motion/manifest files in the project's current Flutter setup.

Do not add redundant asset declarations unless build verification proves they are required.

## 65. No startup coupling

Do not initialize the motion manifest inside startup-motion bootstrap.

Learning Twin motion initializes lazily when needed.

## 66. No auth coupling

The renderer does not need Firebase or Supabase auth.

It receives visual state from its parent.

## 67. No datastore coupling

LTAM-4 introduces zero Firestore reads/writes, zero Supabase reads/writes, and no business-behavior persistence.

## 68. Logging

Development logs may identify motion state and fallback cause.

Do not log learner scores, private content, or sensitive learning details.

## 69. Performance requirements

Avoid recreating controllers on trivial rebuilds, reparsing manifest repeatedly, loading all clips up front, running invisible loops, stacking multiple Lottie renderers for one avatar, or unnecessary wrapper animations.

Measure before deeper optimization.

## 70. Failure-injection testing

Simulate:

- missing idle asset
- missing celebrate asset
- malformed manifest
- unsupported state
- reduced motion
- animation disabled
- same event replay
- controller disposal mid-animation

The UI must remain stable.

## 71. Implementation sequence

~~~text
LTAM-4A  Motion state enum
   ↓
LTAM-4B  Exhaustive mapper
   ↓
LTAM-4C  Descriptor + manifest schema
   ↓
LTAM-4D  Manifest loader/validator
   ↓
LTAM-4E  Motion policy
   ↓
LTAM-4F  Motion controller
   ↓
LTAM-4G  Lottie/SVG renderer
   ↓
LTAM-4H  Preserve LearningTwinAvatar façade
   ↓
LTAM-4I  Developer preview
   ↓
LTAM-4J  Focused tests
   ↓
LTAM-4K  Architecture guardrails
   ↓
LTAM-4L  Analyze/regression/build validation
   ↓
LTAM-4M  Freeze renderer foundation
~~~

## 72. Suggested commit sequence

~~~text
LTAM-4A add motion state and mapper
LTAM-4B add manifest model and validator
LTAM-4C add motion policy
LTAM-4D add motion controller
LTAM-4E add renderer and fallback
LTAM-4F preserve avatar compatibility
LTAM-4G extend developer preview
LTAM-4H add focused tests
LTAM-4I add architecture guardrails
LTAM-4J freeze renderer foundation
~~~

No unrelated feature work belongs in these commits.

## 73. Expected file tree

~~~text
assets/learning_twin/
├── motion/
│   ├── twin_idle.json
│   ├── twin_welcome.json
│   ├── twin_thinking.json
│   ├── twin_explain.json
│   ├── twin_insight_ready.json
│   ├── twin_focus.json
│   ├── twin_encourage.json
│   ├── twin_celebrate.json
│   ├── twin_checkpoint.json
│   ├── twin_exam_ready.json
│   └── twin_result_review.json
└── manifest/
    └── twin_motion_manifest.json

lib/features/learning_twin/ui/
├── learning_twin_asset.dart
├── learning_twin_avatar.dart
├── learning_twin_motion_state.dart
├── learning_twin_motion_descriptor.dart
├── learning_twin_motion_manifest.dart
├── learning_twin_motion_mapper.dart
├── learning_twin_motion_policy.dart
├── learning_twin_motion_controller.dart
├── learning_twin_motion_renderer.dart
└── learning_twin_motion_fallback.dart

test/features/learning_twin/ui/
├── learning_twin_motion_mapper_test.dart
├── learning_twin_motion_manifest_test.dart
├── learning_twin_motion_policy_test.dart
├── learning_twin_motion_controller_test.dart
├── learning_twin_motion_renderer_test.dart
└── learning_twin_avatar_motion_compatibility_test.dart
~~~

## 74. Validation gate

Before closure run:

- formatting
- flutter analyze
- focused Learning Twin tests
- full Flutter test suite
- git diff --check
- production web build
- Android build in the supported project path
- Windows build where the environment supports it

Production rollout may remain disabled while this technical foundation closes.

## 75. Human review

In the developer preview confirm:

1. each LearningTwinState maps correctly
2. correct Lottie asset is selected
3. reduced motion switches to SVG
4. missing asset switches to SVG
5. one-shot replay protection works
6. thinking can be interrupted
7. celebration is not replaced by idle before completion
8. background/size changes do not alter business state
9. compact and hero sizes remain stable
10. learner navigation remains unchanged

## 76. Acceptance checklist

LTAM-4 closes only when:

- LearningTwinMotionState exists
- every current LearningTwinState maps exhaustively
- motion descriptor is immutable
- local motion manifest exists
- manifest validation fails closed
- remote URLs are rejected
- motion policy exists
- reduced-motion override works
- controller supports loop/one-shot behavior
- event-key replay protection works
- priority/interruption rules work
- renderer selects Lottie when appropriate
- renderer falls back to SVG
- existing LearningTwinAvatar calls remain compatible
- static mode remains available
- domain code does not import Lottie
- domain code does not reference motion asset paths
- no new Firestore/Supabase access exists
- startup is not coupled
- focused tests pass
- full regression passes
- web build passes
- supported Android build passes
- developer preview works
- production rollout remains gated
- closure document records exact implementation commit

## 77. Failure conditions

Do not close if:

- domain code references Lottie
- manifest failure crashes UI
- missing motion asset removes guidance
- legacy callers break
- reduced motion still animates
- same event replays on rebuild
- controller leaks
- invisible loops continue unnecessarily
- state mapping depends on learner score
- renderer performs network fetches
- startup waits for motion manifest
- production surfaces are switched without explicit rollout review

## 78. Rollback strategy

~~~text
disable motion through presentation policy
        ↓
LearningTwinAvatar uses existing SVG
        ↓
all Learning Twin business behavior continues
~~~

No learner-data or backend rollback is required.

## 79. Closure document

Create:

~~~text
docs/learning_twin/
└── LTAM_4_MOTION_RENDERER_FOUNDATION_CLOSURE.md
~~~

Record baseline commit, final implementation commit, manifest schema version, motion-state list, mapper tests, manifest tests, policy tests, controller tests, renderer/fallback tests, architecture guard result, full regression, web build, Android build, Windows result if available, known limitations, and next phase.

Closure must explicitly state:

~~~text
LTAM-4 introduced presentation-side animation infrastructure only.
No Learning Twin decision logic, learner-progress logic, assessment logic, or guidance-eligibility logic was changed.
~~~

## 80. Next phase

After LTAM-4 closes:

# LTAM-5: Backward-Compatible LearningTwinAvatar Upgrade and Controlled Runtime Pilot

Recommended rollout order:

~~~text
LearningTwinHero
      ↓
LearningTwinCard
      ↓
LearningTwinCelebration
      ↓
compact/inline surfaces only after review
~~~

## 81. Final frozen outcome

~~~text
Existing Learning Twin
       ↓
LearningTwinState
       ↓
Motion Mapper
       ↓
Motion Descriptor
       ↓
Manifest + Policy
       ↓
Motion Controller
       ↓
Renderer
   ┌───┴────┐
   ↓        ↓
Lottie     SVG
   ↓        ↓
animated   safe fallback
   └───┬────┘
       ↓
same Learning Twin experience
~~~

The motion system remains replaceable, fail-soft, accessible, and subordinate to the existing Learning Twin.

**LTAM-4 is the frozen Motion Manifest, State Mapper and Flutter Renderer Foundation contract.**
