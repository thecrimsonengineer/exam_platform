# CSP11 LTAM-5: Backward-Compatible LearningTwinAvatar Upgrade and Controlled Runtime Pilot

**Status:** FROZEN IMPLEMENTATION PLAN  
**Freeze date:** 2026-09-23  
**Repository:** thecrimsonengineer/exam_platform  
**Branch:** phase-learning-twin-motion-avatar  
**Baseline commit:** d426cf912483d7507c1c4e2ac395bf4694924efa  
**Parent:** LTAM-4 Motion Manifest, State Mapper and Flutter Renderer Foundation  
**Canonical Twin identity:** Naveed • Learning Guide  
**Primary objective:** introduce the new motion renderer into the existing LearningTwinAvatar façade without breaking legacy callers, then validate animation on one controlled production surface before any wider rollout.

---

## 1. Purpose

LTAM-5 is the first production-facing rollout phase of the Learning Twin motion system.

The previous phases established:

- the canonical face-based avatar concept
- the full-body master
- the animation layer and rig architecture
- the idle motion proof
- the V1 motion-state library
- the motion manifest
- the state mapper
- the motion policy
- the animation controller
- the Lottie/SVG renderer foundation

LTAM-5 now introduces those capabilities into the existing CSP11 Learning Twin UI without creating a second avatar component family.

The central principle is:

~~~text
existing LearningTwinAvatar
        ↓
backward-compatible upgrade
        ↓
legacy static calls still work
        ↓
motion-enabled calls opt in
        ↓
controlled pilot surface
        ↓
real-device acceptance
        ↓
freeze before wider rollout
~~~

---

## 2. Core freeze decision

LearningTwinAvatar remains the canonical public avatar widget.

Do not create a parallel production widget such as:

- AnimatedLearningTwinAvatar
- LearningTwinLottieAvatar
- LearningTwinAvatarV2
- MotionTwinAvatar

The existing widget is upgraded internally.

This prevents two competing avatar systems from developing in the repository.

---

## 3. Existing compatibility contract

Current production callers can already use:

~~~text
LearningTwinAvatar(
  asset: LearningTwinAsset.neutral,
  size: 56,
)
~~~

or other existing asset variants.

These existing callers must continue to compile and render with no required migration.

The upgrade is additive.

---

## 4. Proposed additive API

Conceptually, LearningTwinAvatar may gain optional parameters such as:

~~~text
motionState
animationEnabled
eventKey
onAnimationComplete
motionPolicyOverride
~~~

Existing fields remain:

~~~text
asset
size
decorative
compactCrop
semanticLabel
~~~

Exact names may be adjusted to repository conventions.

All new motion parameters must have safe defaults.

---

## 5. Default behavior freeze

If a caller does not specify a motion state, LearningTwinAvatar behaves exactly as before.

Frozen rule:

~~~text
motionState == null
        ↓
existing SVG renderer
~~~

Motion is not inferred silently from LearningTwinAsset during the first production rollout.

This makes migration explicit and easier to audit.

A later phase may introduce safe derivation once the pilot proves stable.

---

## 6. Explicit opt-in model

A production surface opts into animation by providing a motion state.

Example conceptually:

~~~text
LearningTwinAvatar(
  asset: LearningTwinAsset.hero,
  motionState: LearningTwinMotionState.idle,
  size: 180,
)
~~~

This preserves the existing static asset as the fallback identity while enabling motion.

---

## 7. Internal rendering path

Frozen internal path:

~~~text
LearningTwinAvatar
        ↓
motionState present?
    ├── no
    │    ↓
    │ existing SvgPicture path
    │
    └── yes
         ↓
    LearningTwinMotionPolicy
         ↓
    animation permitted?
      ├── no
      │    ↓
      │ SVG fallback
      │
      └── yes
           ↓
      LearningTwinMotionRenderer
           ↓
      Lottie asset
~~~

The existing static path remains first-class.

---

## 8. No layout regression rule

Introducing Lottie must not change the external layout contract of LearningTwinAvatar.

The widget must continue honoring:

- requested size
- square bounds where currently expected
- compact crop behavior
- semantic behavior
- parent constraints
- existing card spacing

Animated rendering must fit inside the same logical box.

---

## 9. Background behavior

The current LearningTwinAvatar uses a surrounding surface treatment for visibility in both themes.

LTAM-5 must preserve the visual container behavior unless a deliberate visual review proves a change is needed.

Do not remove background contrast simply because the new Lottie is transparent.

---

## 10. Compact crop compatibility

The current avatar performs a compact crop for small non-hero assets.

The motion renderer must not accidentally magnify the animated character differently from the static avatar.

For the pilot, the hero surface avoids this complication because it uses a larger uncropped presentation.

Compact crop adaptation is deferred until later rollout.

---

## 11. Pilot-surface freeze

The first learner-facing animated surface will be:

**LearningTwinHero**

Reasons:

- large enough to inspect facial movement
- does not depend on aggressive compact cropping
- defects are easier to observe
- lower visual density than a compact card
- allows reliable comparison against static hero
- easier to disable without affecting coaching frequency

No other learner-facing Twin surface is enabled in the initial LTAM-5 pilot.

---

## 12. Why not LearningTwinCard first

LearningTwinCard appears in multiple controlled guidance locations and often uses a 56 px avatar.

Starting there would combine several risks:

- compact crop
- multiple integration locations
- repeated unsolicited guidance
- smaller facial rendering
- harder visual inspection
- greater chance of motion becoming distracting

Therefore the card remains static during the first pilot.

---

## 13. Why not celebration first

Celebration is a one-shot state with replay complexity.

It should not be the first production animation.

The pilot begins with idle/low-intensity hero motion because that is the safest way to validate:

- renderer lifecycle
- Lottie packaging
- reduced motion
- fallback
- route navigation
- background/resume
- visual quality

---

## 14. Hero pilot motion

The initial hero pilot uses:

~~~text
LearningTwinMotionState.idle
~~~

Only.

Do not enable welcome, explain, or celebration in the first pilot commit.

This isolates the motion system from event/replay behavior.

---

## 15. Hero fallback

If idle Lottie cannot render:

~~~text
LearningTwinAsset.hero
        ↓
naveed_twin_fullbody.svg
~~~

The Hero title, message, action, spacing, and navigation remain intact.

---

## 16. Pilot feature switch

Introduce a presentation-only switch for the controlled pilot.

This may be:

- a const flag
- a locally scoped configuration
- a typed motion rollout policy

Preferred rule:

~~~text
hero motion pilot enabled
card motion disabled
celebration motion disabled
compact motion disabled
~~~

Do not use remote feature-flag infrastructure for V1 unless such infrastructure already exists and is clearly appropriate.

---

## 17. No datastore for rollout flag

The LTAM-5 pilot switch must not introduce:

- Firestore
- Supabase
- SharedPreferences
- remote config

A code-level scoped rollout flag is sufficient for this phase.

---

## 18. LearningTwinHero integration

Current hero usage conceptually contains:

~~~text
LearningTwinAvatar(
  asset: LearningTwinAsset.hero,
  size: 150/180,
  compactCrop: false,
)
~~~

LTAM-5 upgrades it conceptually to:

~~~text
LearningTwinAvatar(
  asset: LearningTwinAsset.hero,
  motionState: pilotEnabled
      ? LearningTwinMotionState.idle
      : null,
  size: ...,
  compactCrop: false,
)
~~~

Exact implementation should remain clean and typed.

---

## 19. Hero business logic freeze

LearningTwinHero must not itself decide:

- whether the learner needs guidance
- whether a message should show
- whether a milestone occurred
- whether exam readiness is achieved

It only renders the state supplied by its parent/presentation integration.

For the first pilot, its animated state is explicitly idle.

---

## 20. First-run behavior

Do not automatically play the welcome state merely because hero animation exists.

Welcome behavior belongs to a later controlled state-integration step.

The first pilot is idle-only.

---

## 21. Reduced-motion behavior

When platform animation is disabled/reduced:

~~~text
LearningTwinHero
        ↓
LearningTwinAvatar
        ↓
MotionPolicy
        ↓
static hero SVG
~~~

No animation controller should continue invisibly behind the static fallback.

---

## 22. Motion-disabled behavior

When the pilot switch is disabled, the hero must render identically to the pre-LTAM-5 static implementation.

This is the primary rollback path.

---

## 23. Missing-asset behavior

Simulate removal or failure of twin_idle.json.

Expected result:

- no crash
- hero remains visible
- static full-body SVG appears
- title remains
- message remains
- button remains
- layout does not jump materially

---

## 24. Manifest-failure behavior

Simulate invalid motion manifest.

Expected result:

~~~text
motion disabled
+
hero SVG
+
normal Learning Twin experience
~~~

No learner-visible error message is needed.

---

## 25. Lottie parse failure

If Flutter Lottie throws or fails while resolving the asset, contain the failure inside the motion renderer/fallback boundary.

Do not allow the Hero tree to disappear.

---

## 26. Stateful upgrade

LearningTwinAvatar may need to become StatefulWidget if the final LTAM-4 renderer/controller design requires lifecycle ownership.

If so:

- preserve constructor compatibility
- keep external API stable
- dispose controller
- preserve semantics
- avoid rebuilding controller unnecessarily

Do not retain StatelessWidget status at the cost of incorrect lifecycle behavior.

---

## 27. Controller ownership

Preferred ownership:

~~~text
LearningTwinAvatar
   or
LearningTwinMotionRenderer
        ↓
AnimationController
~~~

Choose one clear owner.

Do not create separate competing controllers in both layers.

The owner must be documented.

---

## 28. Stable controller across rebuilds

Changing unrelated parent data such as:

- text theme
- parent copy
- layout constraints

must not unnecessarily recreate the animation controller.

Use lifecycle comparison only for motion-relevant parameter changes.

---

## 29. Relevant update triggers

Controller reset/reconfiguration may be appropriate when:

- motionState changes
- eventKey changes
- animationEnabled changes
- reduced-motion state changes
- descriptor asset changes

Size-only changes should normally not restart an idle clip.

---

## 30. Theme change

Switching light/dark theme must not replay a one-shot state.

For the idle pilot, the loop may continue naturally.

The avatar container colors can update independently.

---

## 31. Orientation and window resize

Changing device orientation or desktop window size should not cause:

- duplicate controller
- first-frame flash
- asset reload storm
- animation error

Idle may continue or restart harmlessly if unavoidable, but visual continuity is preferred.

---

## 32. Route push/pop

When navigating away from the hero surface:

- stop/pause unnecessary looping
- release controller if widget disposes

When returning:

- idle may start again
- no event-state replay concern exists for the first pilot

---

## 33. App background/resume

On background:

- pause or naturally suspend animation

On resume:

- idle resumes safely
- no duplicate ticker/controller

No learner data is changed.

---

## 34. Semantics preservation

LearningTwinAvatar semantics must remain exactly one of:

- excluded if decorative
- one image semantic label if meaningful

Lottie internals remain invisible to accessibility.

The pilot must not create new repeated announcements.

---

## 35. Hero semantics

The hero avatar itself may retain:

~~~text
Naveed Learning Guide
~~~

The Hero's title/message remain separate meaningful text.

Do not announce breathing or animation state.

---

## 36. Static-vs-motion visual parity

Compare the old full-body hero SVG and new idle Lottie.

The animated version must preserve:

- recognisable identity
- approximate size
- alignment
- visual weight
- head/body position
- professional appearance

If the animated version appears significantly smaller/larger, adjust renderer fit rather than changing surrounding layout without justification.

---

## 37. Hero mobile layout

Current compact Hero layout stacks avatar above copy.

Verify animation at Android-width layouts:

~~~text
[ animated hero ]
       ↓
     title
     copy
     action
~~~

Check vertical height carefully.

The animation must not push important content below the fold unnecessarily.

---

## 38. Hero desktop layout

Current wider Hero layout places avatar beside copy.

Verify:

~~~text
[ animated hero ]   title
                    copy
                    action
~~~

Ensure the Lottie does not overflow or clip.

---

## 39. Hero motion intensity

Pilot motion must remain LTAM-2 intensity level 1.

Do not add particle bursts or state reactions during LTAM-5A.

The pilot asks one question:

**Can the existing Learning Twin safely stay subtly alive in the real UI?**

---

## 40. Performance profile

Measure the real hero surface in profile/release mode.

Observe:

- frame stability
- scrolling
- navigation
- memory
- repeated entry/exit
- CPU/GPU cost where available
- device heat over repeated viewing

Debug-mode jank alone is not a release verdict.

---

## 41. Long-view test

Leave the hero surface visible for several minutes.

Assess:

- motion fatigue
- loop obviousness
- annoyance
- visual competition with text
- device behavior

An animation can pass a 10-second demo and fail a 5-minute learning session.

---

## 42. Pilot acceptance decision

After real-device review, classify the hero pilot as:

~~~text
ACCEPT
TUNE
REJECT_TO_STATIC
~~~

ACCEPT allows the phase to proceed to a narrow second slice.

TUNE returns to motion/renderer adjustment.

REJECT_TO_STATIC keeps the new infrastructure but leaves hero rendering static.

This is not considered an architectural failure because fallback is intentional.

---

## 43. Second slice after hero acceptance

Only after Hero passes, enable animation in:

**LearningTwinCard**

This becomes LTAM-5B.

Do not enable Card and Hero in the same initial rollout commit.

---

## 44. Card animation strategy

The card uses compact avatar rendering.

Start card rollout with state-aware animation only at approved sizes.

Potential policy:

~~~text
size >= reviewed threshold
    -> motion

size below threshold
    -> static SVG
~~~

The exact threshold is determined from physical-device visual review.

Do not invent a threshold without testing.

---

## 45. Card motion mapping

Unlike the idle-only Hero pilot, LearningTwinCard may eventually use its actual Learning Twin domain message state.

Flow:

~~~text
LearningTwinMessage.state
       ↓
LearningTwinMotionMapper
       ↓
motion state
       ↓
LearningTwinAvatar
~~~

The existing message decision remains unchanged.

---

## 46. Card state exclusions during first card pilot

For the first card-motion pilot, consider enabling only low-risk states:

~~~text
idle
welcome
explain
insightReady
focus
encourage
~~~

Keep celebrate/checkpoint/examReady/resultReview disabled until one-shot behavior is separately verified.

This narrows replay risk.

---

## 47. Card compact distraction gate

At 56 px verify whether:

- blink remains visible but not noisy
- head motion remains clean
- FX is legible
- animation does not pull attention from text

If not, use static SVG at 56 px.

Animation is optional. Usability is not.

---

## 48. Card dismissal behavior

Dismissing LearningTwinCard must:

- remove card exactly as before
- dispose/pause animation
- not trigger another visual state
- not alter M3/M4 decision behavior

Dismissal remains controlled by existing Learning Twin integration.

---

## 49. Card frequency rule

Animation must not change how often cards appear.

The existing one-unsolicited-intervention-per-visit and other frequency restraints remain authoritative.

Animation is not a reason to surface the Twin more often.

---

## 50. Third slice: LearningTwinCelebration

Only after Hero and Card acceptance, enable animation in LearningTwinCelebration.

This is LTAM-5C.

It uses:

~~~text
LearningTwinMotionState.celebrate
~~~

with a stable event key.

---

## 51. Celebration event key

The celebration surface must supply an event identity when available.

This prevents:

~~~text
widget rebuild
    ↓
celebration restarts
    ↓
loop of applause-like behavior
~~~

Same event must play once.

---

## 52. Celebration completion

After the celebration animation completes:

- hold/revert to static success or idle-compatible state
- do not loop celebration
- do not continuously burst particles

Text remains visible.

---

## 53. Celebration accessibility

The existing parent live-region behavior remains authoritative.

The avatar animation must not duplicate the milestone announcement.

---

## 54. Fourth slice: compact/inline surfaces

Only after the first three slices pass, audit:

- LearningTwinCompactTip
- LearningTwinInlineBlock
- LearningTwinBubble
- LearningTwinCoachSheet

For each surface choose explicitly:

~~~text
animate
static
event-only animation
~~~

Do not assume animation everywhere is better.

---

## 55. Static-by-design is valid

A surface may remain permanently static if:

- too small
- too frequent
- motion distracts
- motion adds no useful emotional cue
- performance cost is unjustified

This is an accepted outcome.

---

## 56. No bottom-navigation change

LTAM-5 does not introduce a new Learning Twin bottom-navigation tab.

It only upgrades existing Twin surfaces.

---

## 57. No Home card expansion in LTAM-5

Do not create a new Home Learning Twin summary card during this phase.

If Home later receives a Learning Twin summary, it should be a separate integration slice after runtime animation itself is stable.

---

## 58. No new full Twin screen in LTAM-5

Do not build a new dedicated Learning Twin screen here.

The phase is about backward-compatible motion rollout on existing surfaces.

---

## 59. Runtime feature matrix

Maintain an explicit rollout matrix.

Initial target:

~~~text
Surface                     Motion
LearningTwinHero            PILOT ON
LearningTwinCard            OFF
LearningTwinCelebration     OFF
LearningTwinCompactTip      OFF
LearningTwinInlineBlock     OFF
LearningTwinBubble          OFF
LearningTwinCoachSheet      OFF
~~~

After each accepted slice, update intentionally.

---

## 60. Motion-state matrix

Maintain a second matrix indicating which states are permitted on which surfaces.

Example:

~~~text
Hero:
  idle

Card pilot:
  idle
  welcome
  explain
  insightReady
  focus
  encourage

Celebration:
  celebrate

Compact:
  determined later
~~~

This prevents accidental use of all states everywhere.

---

## 61. Error telemetry/logging

Use non-sensitive development diagnostics when fallback occurs.

Example:

~~~text
LearningTwinMotion fallback: surface=hero state=idle reason=asset_load
~~~

Do not log learner score or guidance text.

---

## 62. No user-visible animation error

Never show messages such as:

~~~text
Animation failed
Lottie asset missing
Twin renderer error
~~~

to learners.

Fallback should be silent.

---

## 63. Golden/static regression

Preserve or add static/golden checks for:

- Hero mobile layout
- Hero desktop layout
- Card static fallback
- Celebration fallback

Motion itself is validated separately.

---

## 64. Widget regression

Test legacy LearningTwinAvatar calls.

Also test:

- motion-enabled Hero
- reduced-motion Hero
- invalid-manifest Hero
- missing-asset Hero
- motion-disabled Hero
- Hero semantics
- Hero layout at narrow width
- Hero layout at wide width

---

## 65. Card tests after pilot expansion

When Card animation is enabled, test:

- state mapping
- dismissal
- compact fallback
- reduced motion
- message/action unchanged
- one-intervention behavior unaffected

---

## 66. Celebration tests

Test:

- event key replay suppression
- one-shot completion
- fallback
- live-region semantics not duplicated
- rebuild does not replay same event

---

## 67. Integration regression

Run the real learner path containing existing Twin surfaces.

At minimum:

~~~text
Study Hub
Domain
Competency
Practice/Quiz result
Exam-readiness-related surfaces where applicable
~~~

Verify only the intended surface gained motion.

---

## 68. Timed-exam protection

No animated Twin may appear inside a timed exam context where existing Learning Twin suppression prohibits the Twin.

Animation rollout must not weaken this boundary.

Add regression coverage if the relevant integration path can be tested reliably.

---

## 69. Startup regression

Opening the app must not preload the entire motion library.

Verify:

- startup animation remains unchanged
- auth remains unchanged
- login not delayed
- Home not delayed solely for Twin motion

---

## 70. Auth regression

Learning Twin animation must work independently of auth implementation details once its parent screen exists.

No new auth listener is permitted solely for animation.

---

## 71. Network regression

Animation must work without fetching motion assets from the network.

Bundled asset behavior should function even when network is unavailable, subject to the rest of CSP11's online requirements.

---

## 72. Data-access regression

Verify the LTAM-5 diff introduces:

- no Firestore read
- no Firestore write
- no Supabase read
- no Supabase write

Motion is presentation-only.

---

## 73. Physical Android test matrix

For each enabled pilot slice test:

- cold app launch
- navigate to surface
- first animation load
- repeated entry
- back navigation
- screen rotation if supported
- background/resume
- dark mode
- light mode
- reduced motion
- long-view loop
- missing-asset fallback in controlled build/test
- network disconnected where app route can still be exercised

---

## 74. Web test matrix

Verify:

- first asset load
- reload
- browser resize
- route push/pop
- tab background/resume
- reduced motion
- fallback
- no console asset errors
- no layout shift

---

## 75. Windows test matrix

Verify:

- initial rendering
- resize
- minimize/restore
- theme switch
- reduced motion
- fallback
- repeated route entry
- no clipping

---

## 76. Performance acceptance

The pilot must not introduce material UI degradation.

Investigate:

- visible stutter
- delayed navigation
- sustained excessive CPU
- excessive memory growth
- repeated asset parsing
- controller leaks

Do not optimize blindly. Measure and simplify where needed.

---

## 77. Human visual acceptance: Hero

Confirm:

1. the Twin remains recognisable
2. the animation looks professional
3. the loop is not obvious
4. text remains the visual priority
5. no uncanny eye movement
6. no clipping
7. dark/light modes work
8. it remains comfortable after repeated viewing
9. static fallback still looks intentional
10. animation adds value

---

## 78. Human visual acceptance: Card

If Card pilot proceeds:

1. motion is not too small/noisy
2. text remains dominant
3. dismissal feels unchanged
4. no repeated visual nagging
5. multiple visits do not feel over-animated

---

## 79. Human visual acceptance: Celebration

If Celebration pilot proceeds:

1. celebration feels meaningful
2. not childish
3. one-shot timing is appropriate
4. no repeated burst
5. no semantic duplication
6. milestone text remains primary

---

## 80. Rollback levels

Freeze three rollback levels.

### Level 1: surface rollback

Disable motion only for one surface.

Example:

~~~text
Hero motion OFF
Card unchanged
~~~

### Level 2: all Learning Twin motion rollback

~~~text
motion policy global disable
        ↓
all static SVG
~~~

### Level 3: code rollback

Revert LTAM-5 integration commits while retaining LTAM-1 to LTAM-4 design/foundation work.

No learner-data rollback is required.

---

## 81. Pilot closure rule

Do not call LTAM-5 complete merely because animation renders.

Closure requires:

- backwards compatibility
- pilot acceptance
- accessibility
- fallback
- lifecycle
- platform verification
- regression
- no business-logic drift

---

## 82. Suggested implementation sequence

~~~text
LTAM-5A
Upgrade LearningTwinAvatar API additively
    ↓
LTAM-5B
Wire motion renderer internally
    ↓
LTAM-5C
Verify legacy static compatibility
    ↓
LTAM-5D
Enable idle animation on LearningTwinHero only
    ↓
LTAM-5E
Run Android/Web/Windows pilot validation
    ↓
LTAM-5F
Human Hero acceptance
    ↓
LTAM-5G
Enable controlled LearningTwinCard state pilot
    ↓
LTAM-5H
Validate compact behavior and dismissal
    ↓
LTAM-5I
Enable LearningTwinCelebration one-shot pilot
    ↓
LTAM-5J
Verify event-key replay protection
    ↓
LTAM-5K
Audit compact/inline surfaces individually
    ↓
LTAM-5L
Run full regression
    ↓
LTAM-5M
Freeze controlled runtime rollout
~~~

If Hero fails, stop at LTAM-5F and keep other surfaces static until corrected.

---

## 83. Suggested commit sequence

~~~text
LTAM-5A upgrade LearningTwinAvatar compatibly
LTAM-5B add Hero idle-motion pilot
LTAM-5C harden Hero fallback and accessibility
LTAM-5D validate Hero platform behavior
LTAM-5E add controlled Card motion pilot
LTAM-5F validate compact Card behavior
LTAM-5G add Celebration one-shot pilot
LTAM-5H audit remaining compact surfaces
LTAM-5I run integrated regressions
LTAM-5J freeze runtime pilot
~~~

Do not combine all surfaces into one commit.

---

## 84. Expected code changes

Primary expected files:

~~~text
lib/features/learning_twin/ui/
├── learning_twin_avatar.dart
├── learning_twin_hero.dart
├── learning_twin_card.dart
├── learning_twin_celebration.dart
└── existing LTAM-4 motion files
~~~

Not every file is modified in the first pilot slice.

Hero changes first.

---

## 85. Expected tests

~~~text
test/features/learning_twin/ui/
├── learning_twin_avatar_motion_compatibility_test.dart
├── learning_twin_hero_motion_pilot_test.dart
├── learning_twin_card_motion_pilot_test.dart
├── learning_twin_celebration_motion_test.dart
├── learning_twin_motion_reduced_motion_test.dart
├── learning_twin_motion_failure_fallback_test.dart
└── learning_twin_motion_lifecycle_test.dart
~~~

Naming may follow current test conventions.

---

## 86. Build gates

Before each rollout checkpoint:

- Dart/Flutter formatting
- flutter analyze
- focused Learning Twin tests
- relevant integration tests
- full Flutter test suite
- git diff --check
- web release build
- Android supported build
- Windows build where environment permits

Do not expand to the next surface while the current slice is red.

---

## 87. Architecture guard remains active

Continue enforcing:

~~~text
domain
  X
Lottie
~~~

No rollout commit may move animation knowledge into domain/coaching services.

---

## 88. No animation-driven business behavior

Animation completion must not:

- mark content complete
- change mastery
- write progress
- unlock a feature
- change a Learning Twin decision
- navigate automatically

Animation completion is visual only.

---

## 89. No business dependency on animation success

The inverse is equally important.

Business functionality must not wait for:

~~~text
onAnimationComplete
~~~

before enabling the CTA or showing guidance.

The learner should not be blocked by animation.

---

## 90. CTA behavior

Existing Hero/Card/celebration actions remain immediately usable.

Animation must not disable buttons while playing.

If a user taps an action mid-animation:

- navigation proceeds
- animation disposes
- no delay

---

## 91. Gesture/tap behavior

Do not make the avatar itself tappable unless it already has a product requirement.

Motion alone is not an invitation to add new interactions.

---

## 92. Loading behavior

The animation may show its static fallback immediately while Lottie resolves.

Avoid blank boxes.

Preferred visual sequence:

~~~text
static fallback available immediately
        ↓
Lottie ready
        ↓
motion begins without layout shift
~~~

If implementation complexity makes that transition unstable, prefer static until fully ready.

---

## 93. First-frame consistency

The first frame of the Lottie should visually align with the fallback enough to avoid a noticeable identity jump.

This was an LTAM-3 asset concern and becomes a real runtime requirement here.

---

## 94. Surface-specific motion policy

After all pilot slices, record a production matrix stating:

- surface
- allowed states
- minimum reviewed size
- default animated/static
- reduced-motion behavior
- fallback asset

This matrix becomes part of closure.

---

## 95. Success criteria

LTAM-5 succeeds when CSP11 has at least one real learner-facing Learning Twin surface using the motion system safely, while every previous static path still works.

The strongest success is not “everything animates.”

It is:

~~~text
motion adds life
without adding fragility
~~~

---

## 96. Acceptance checklist

LTAM-5 closes only when:

- [ ] LearningTwinAvatar remains the canonical public widget
- [ ] legacy calls compile unchanged
- [ ] legacy static rendering remains available
- [ ] motion parameters are additive and optional
- [ ] Hero idle pilot works
- [ ] Hero fallback works
- [ ] Hero reduced-motion behavior works
- [ ] Hero lifecycle behavior works
- [ ] Hero Android review passes
- [ ] Hero Web review passes
- [ ] Hero Windows review passes
- [ ] Card rollout occurs only after Hero acceptance
- [ ] Card frequency/dismissal behavior remains unchanged
- [ ] Celebration one-shot uses event replay protection if enabled
- [ ] compact surfaces are individually audited
- [ ] no animation-driven navigation exists
- [ ] CTAs never wait for animation
- [ ] no backend reads/writes added
- [ ] no auth coupling added
- [ ] no startup delay added
- [ ] timed-exam suppression remains intact
- [ ] reduced motion produces static UI
- [ ] missing assets fail to static UI
- [ ] full regression passes
- [ ] production rollout matrix is recorded
- [ ] rollback path is proven
- [ ] closure document records exact commit

---

## 97. Failure conditions

Do not close LTAM-5 if:

- old avatar callers break
- Hero layout shifts materially
- animation delays navigation
- reduced-motion still animates
- fallback produces blank content
- Card appears more frequently because of motion
- celebration replays on rebuild
- timed-exam Twin suppression regresses
- controllers leak
- startup becomes slower due to preload
- a motion failure breaks message/action rendering
- compact motion is distracting
- domain code learns about Lottie
- backend access is added for visual state

---

## 98. Closure document

Create:

~~~text
docs/learning_twin/
└── LTAM_5_BACKWARD_COMPATIBLE_AVATAR_RUNTIME_PILOT_CLOSURE.md
~~~

Record:

- baseline commit
- final implementation commit
- LearningTwinAvatar API changes
- legacy compatibility result
- enabled pilot surfaces
- surface/state matrix
- reduced-motion result
- fallback result
- replay-protection result
- Android result
- Web result
- Windows result
- full regression result
- performance observations
- human visual acceptance
- rollback verification
- known limitations
- exact next phase

Closure statement:

~~~text
LTAM-5 introduced controlled learner-facing motion through the existing LearningTwinAvatar façade while preserving all existing Learning Twin business logic and static fallback behavior.
~~~

---

## 99. Next phase

After LTAM-5 closes, proceed to:

# LTAM-6: Accessibility, Performance, Lifecycle and Cross-Platform Hardening

LTAM-6 will take the now-real runtime motion system and harden it for release by focusing on:

- reduced motion
- accessibility semantics
- controller lifecycle
- off-screen pausing
- memory
- CPU/GPU behavior
- asset caching
- long-session stability
- Android/Web/Windows parity
- failure injection
- release-build acceptance

No new emotional state is needed in LTAM-6.

---

## 100. Final frozen outcome

~~~text
existing LearningTwinAvatar
        ↓
backward-compatible motion support
        ↓
static legacy calls preserved
        ↓
Hero idle pilot
        ↓
platform + human acceptance
        ↓
controlled Card pilot
        ↓
controlled Celebration pilot
        ↓
compact surface audit
        ↓
full regression
        ↓
safe runtime rollout frozen
~~~

The governing product principle is:

**Animation is an enhancement to the existing Learning Twin, never a dependency of the Learning Twin.**

**LTAM-5 is the frozen Backward-Compatible LearningTwinAvatar Upgrade and Controlled Runtime Pilot contract.**
