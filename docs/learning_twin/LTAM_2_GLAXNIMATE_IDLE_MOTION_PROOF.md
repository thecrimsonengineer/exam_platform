# CSP11 LTAM-2: Glaxnimate Idle Motion Proof

**Status:** FROZEN IMPLEMENTATION PLAN  
**Freeze date:** 2026-09-23  
**Repository:** `thecrimsonengineer/exam_platform`  
**Branch:** `phase-learning-twin-motion-avatar`  
**Baseline commit:** `f49a27bc675fd1b05cf803d9a3c8d2e36eb15c47`  
**Parent:** LTAM-1C Animation Layer Preparation and Rig Architecture  
**Canonical Twin identity:** `Naveed • Learning Guide`  
**Authoring tool:** Glaxnimate  
**Export format:** Lottie JSON  
**Runtime proof target:** Flutter `lottie` package  
**Supported platforms:** Android, Web, Windows

---

## 1. Purpose

LTAM-2 creates the first production-quality animation proof for the existing CSP11 Learning Twin.

The goal is not to animate every Learning Twin state. The goal is to prove that the approved full-body master and frozen LTAM-1C rig can produce one high-quality, seamless, lightweight, cross-platform idle animation that feels alive without becoming distracting.

The idle proof is the foundation for every later motion state.

The required sequence is:

```text
LTAM-1C frozen rig
      ↓
Glaxnimate idle composition
      ↓
subtle breathing
      ↓
natural blink
      ↓
tiny head drift
      ↓
small gaze adjustment
      ↓
subtle digital-node motion
      ↓
seamless loop
      ↓
Lottie export
      ↓
Flutter isolated proof
      ↓
Android / Web / Windows validation
      ↓
idle proof frozen
```

No additional animation state may be considered production-ready until this idle proof passes.

---

## 2. Preservation contract

LTAM-2 is an animation proof phase only.

It must not change:

- Learning Twin domain state
- Learning Twin triggers
- deterministic coaching decisions
- guidance message content
- learner progress interpretation
- exam suppression
- dismissal behavior
- navigation
- authentication
- Home behavior
- Study Hub behavior
- Domain behavior
- Competency behavior
- Practice/Quiz behavior
- Startup Motion behavior
- data repositories
- Firebase/Firestore reads
- Supabase behavior
- learner scoring
- readiness calculations

The existing production Learning Twin remains fully functional using its current SVG assets.

No production caller is switched to Lottie during LTAM-2.

---

## 3. LTAM-2 success definition

LTAM-2 succeeds only if the idle animation is:

- recognisably Naveed
- visually calm
- professional
- natural
- loopable
- lightweight
- Lottie-compatible
- stable at small and large sizes
- accessible through static fallback
- visually correct on Android, Web, and Windows
- free of animation seams
- free of rig tearing
- free of obvious uncanny motion
- suitable to become the default animated resting state later

The correct feeling is:

```text
alive
but not performing
```

---

## 4. Scope

LTAM-2 includes only one production candidate animation:

```text
twin_idle.json
```

The idle animation may contain:

- subtle breathing
- one natural blink
- tiny head drift
- tiny gaze movement
- subtle torso settling
- low-intensity halo/node motion

It must not contain:

- speech
- mouth flapping
- large gestures
- waving
- pointing
- celebration
- thinking pose
- explain pose
- warning/focus pose
- progress-specific effects
- domain labels
- learner data
- competency data
- readiness values
- text
- audio

---

## 5. Canonical idle duration

Freeze the first idle cycle at:

```text
6.0 seconds
30 fps
180 frames
```

This gives enough time for the animation to breathe without feeling mechanically repetitive.

A later visual review may allow a narrow adjustment between 5.5 and 7.0 seconds if a specific loop-quality issue requires it.

Do not exceed 8 seconds for the first proof.

---

## 6. Frame-rate freeze

The canonical LTAM-2 authoring rate is:

```text
30 fps
```

Do not author at 60 fps.

The face and body motions in this phase are slow enough that 30 fps is sufficient and reduces JSON complexity.

---

## 7. Timeline architecture

The initial six-second timeline is frozen conceptually as:

```text
0.00s  bind pose
0.40s  breathing begins
1.20s  slight chest rise
1.80s  settle
2.25s  natural blink begins
2.40s  eyes closed
2.55s  eyes reopen
3.10s  tiny head drift begins
3.70s  tiny gaze shift
4.25s  gaze returns
4.70s  head returns
5.20s  second subtle breathing settle
6.00s  exact visual return to bind pose
```

This is the choreography contract, not a mandate for linear interpolation.

Curves must be tuned visually.

---

## 8. Loop seam rule

Frame 0 and frame 180 must be visually equivalent.

The following values must match at loop boundaries:

- root position
- body-root position
- torso position/scale
- neck rotation
- head rotation
- gaze position
- eyebrow position
- mouth state
- shoulder position
- FX opacity
- FX rotation
- node positions

No loop may visibly jump.

A crossfade workaround is not acceptable for the canonical idle.

The animation itself must loop cleanly.

---

## 9. Breathing design

Breathing must be extremely subtle.

The breathing effect should come primarily from:

- tiny torso vertical scale/translation
- tiny shoulder response
- tiny coat/shirt response
- optional small neck response

Avoid:

- expanding the whole body
- obvious chest inflation
- head bobbing with every breath
- exaggerated shoulder lift
- continuous sinusoidal cartoon breathing

The breathing should be barely noticed when the user is reading text.

---

## 10. Breathing amplitude

Start with very small transform values.

Suggested tuning range:

```text
torso Y translation: approximately 1–3 px at authoring scale
torso scale Y: approximately 0.2–0.6%
shoulder response: approximately 0.5–1.5 px
head vertical response: approximately 0–1 px
```

These values are starting points, not absolute requirements.

If the motion is noticeable before the user looks for it, reduce it.

---

## 11. Breathing easing

Use smooth ease-in/ease-out curves.

Avoid linear breathing.

The inhale and exhale should not have identical mechanical timing.

Recommended rhythm:

```text
slightly quicker inhale
+
slightly slower settle
```

The loop should feel organic without pretending to simulate medically accurate respiration.

---

## 12. Blink design

The first idle loop contains one normal blink.

The blink should be:

- brief
- symmetrical
- smooth
- not exaggerated
- not accompanied by eyebrow motion
- not accompanied by head movement

Use the LTAM-1C eyelid architecture.

Do not scale the eyeball.

---

## 13. Blink timing

Suggested first blink timing:

```text
start: 2.25s
half-close: 2.32s
closed: 2.40s
half-open: 2.47s
open: 2.55s
```

Exact timing may be visually adjusted.

The blink must not feel slow or theatrical.

---

## 14. Blink loop-frequency rule

The first proof uses exactly one blink in the six-second loop.

Do not create multiple repeated blinks.

A later runtime system may eventually alternate between more than one idle clip to reduce repetition, but that is outside LTAM-2.

---

## 15. Head drift design

Head motion should suggest subtle human presence rather than deliberate gesture.

Allowed:

- approximately 0.5–1.5 degrees of rotation
- tiny translation
- slow drift
- smooth return

Avoid:

- nodding
- repeated bobbing
- sharp direction changes
- obvious pose changes
- large head tilts

The learner should not interpret idle motion as a message.

---

## 16. Head drift timing

Suggested choreography:

```text
3.10s start drift
3.65s maximum offset
4.10s hold/soft settle
4.70s return
5.20s neutral
```

The maximum offset should remain extremely small.

---

## 17. Gaze adjustment design

Gaze may move slightly during the head drift.

The gaze should remain close to forward.

Allowed:

- tiny horizontal shift
- tiny upward shift
- smooth return

Not allowed:

- scanning around the screen
- following UI elements
- looking sharply sideways
- eye darting
- pupil edge contact

The Twin should still feel attentive to the learner.

---

## 18. Gaze timing

Suggested:

```text
3.55s gaze begins
3.75s max tiny shift
4.10s begin return
4.25s forward
```

The eye motion should be shorter than the head drift.

---

## 19. Eyebrow policy

Idle brows remain neutral.

No independent eyebrow animation is required in LTAM-2.

A tiny transform caused by head hierarchy is acceptable.

Do not add expressive brow motion simply to make the avatar feel more alive.

---

## 20. Mouth policy

Use a soft neutral mouth.

The mouth must not animate during the idle proof.

The idle face must not repeatedly smile larger and smaller.

A stable soft expression is more professional.

---

## 21. Beard and moustache integrity

During breathing and head movement:

- beard must stay attached to face
- moustache must remain aligned
- mouth must not float
- beard edge must not tear
- no face-base gaps may appear

This is a hard visual gate.

---

## 22. Shoulder motion

Shoulders may respond very slightly to breathing.

Both shoulders should not move with perfect mechanical symmetry.

A tiny natural asymmetry is acceptable.

The movement must not look like shrugging.

---

## 23. Arm policy

Arms remain effectively at rest.

Only inherited torso motion is allowed.

Do not add hand gestures to idle.

No finger motion is required.

---

## 24. Leg policy

Legs remain stable.

A very tiny body-weight settle is acceptable only if it improves the full-body hero view.

Do not animate knee bending or foot repositioning.

The compact/head crop must not depend on leg motion.

---

## 25. Full-body stability

The full-body silhouette must remain calm.

When viewed from a distance, the user should mostly perceive a stable professional figure.

The motion becomes apparent on closer observation.

---

## 26. Digital halo

A subtle halo may be included.

The halo must:

- remain behind the character
- use low opacity
- avoid flashing
- avoid competing with the face
- loop seamlessly

Possible motion:

- very slow rotation
- tiny opacity breathing
- tiny radial pulse

Only one of these may be prominent at a time.

---

## 27. Knowledge-node motion

Generic decorative nodes may move subtly.

They must not represent actual domain/competency values.

Allowed:

- one or two slow node pulses
- one small travelling dot
- one faint connector activation

Not allowed:

- progress percentages
- D1–D7 labels
- learner scores
- dynamic recommendations
- blinking warning signals

---

## 28. FX timing separation

Digital effects should not peak at the exact same moment as every body movement.

Avoid synchronized robotic timing such as:

```text
breath + halo + node + blink
all peak together
```

Instead stagger them subtly.

This helps the animation feel less procedural.

---

## 29. FX opacity budget

Digital effects should remain secondary.

The face must always be the visual focus.

If the first thing visible is the halo rather than the person, reduce the FX.

---

## 30. Colour policy

Use the approved CSP11-compatible digital accent treatment.

The avatar skin, hair, beard, clothing, and facial features remain natural.

Digital effects may use restrained app accent hues.

Do not recolour the character into a blue hologram in the canonical idle.

---

## 31. Transparent background

The Lottie animation must export with a transparent background.

No passport-style blue background.

No fixed card background.

No baked glass surface.

Flutter owns the surrounding surface.

---

## 32. Crop compatibility

The idle animation must work when rendered as:

- full body
- hero crop
- mid body
- head and shoulders
- compact crop

The same animation asset should not require separate identity artwork for each crop unless a later performance phase proves that separate optimized assets are necessary.

---

## 33. Safe animation area

Ensure head drift, halo, and node motion do not leave the intended composition bounds.

Maintain safe margins around:

- hair
- shoulders
- hands
- halo
- node FX

No animation element should be clipped unexpectedly when rendered with standard Flutter `BoxFit.contain`.

---

## 34. Glaxnimate composition

Create a dedicated production-idle composition in the canonical rig source.

Recommended naming:

```text
composition_idle_v1
```

Do not destroy the bind-pose/reference composition.

Keep:

```text
bind_pose
rig_tests
composition_idle_v1
```

as clearly distinct authoring contexts if Glaxnimate project structure supports it.

---

## 35. Keyframe discipline

Use the minimum number of keyframes needed for good motion.

Avoid keyframing every frame.

The animation should be curve-driven.

This reduces:

- JSON size
- editing complexity
- accidental jitter
- runtime workload

---

## 36. Interpolation policy

Use smooth interpolation.

Avoid default linear interpolation where it produces mechanical movement.

Check:

- torso
- head
- gaze
- halo
- nodes

individually.

Do not use overshoot/bounce curves for idle facial or body motion.

---

## 37. Motion hierarchy rule

Animate the highest sensible parent.

Example:

If the entire head moves, animate `head_root`, not each facial component individually.

If only the pupils move, animate gaze groups.

If the whole torso breathes, animate `torso_root`, not every coat panel separately.

This keeps the animation maintainable.

---

## 38. Rig integrity test during animation

During the entire six-second loop inspect:

- neck seam
- shoulder seam
- elbow seam
- wrist seam
- face/beard seam
- eyelid edges
- hairline
- coat layers
- tie alignment

No gap or visual pop is allowed.

---

## 39. Authoring source

The canonical editable source remains:

```text
design/learning_twin/rig/naveed_twin_master_rig.glaxnimate
```

LTAM-2 should not create a completely unrelated Glaxnimate file unless required by tool limitations.

If a derived animation project is needed, use a clearly linked name such as:

```text
design/learning_twin/motion/naveed_twin_idle_v1.glaxnimate
```

and document its relationship to the rig master.

---

## 40. Production export path

The first production candidate export is:

```text
assets/learning_twin/motion/twin_idle.json
```

However, it must not be wired into production UI during LTAM-2.

The file may be committed as an accepted candidate after export validation.

---

## 41. Static fallback

Preserve the current static SVG fallback.

A new LTAM-specific fallback may also be created later if required, but LTAM-2 does not need to replace the existing neutral SVG.

Fallback chain for the proof:

```text
twin_idle.json
    ↓ if unavailable
existing neutral Learning Twin SVG
```

---

## 42. Export procedure

Before export:

1. hide authoring guides
2. hide pivot markers
3. hide reference layers
4. verify transparent background
5. verify frame range 0–180
6. verify 30 fps
7. verify first/last pose match
8. verify no embedded reference photo
9. verify no unsupported temporary effect
10. save canonical Glaxnimate source

Then export to Lottie JSON.

---

## 43. Export naming

Canonical asset:

```text
twin_idle.json
```

Do not use:

- twin_idle_final.json
- twin_idle2.json
- idle_new.json
- test_idle.json

Versioning belongs in Git history and manifests, not filenames.

---

## 44. Lottie JSON inspection

After export inspect the JSON for:

- valid Lottie version metadata
- correct frame range
- expected frame rate
- expected canvas size
- no external remote URL
- no unexpected embedded image reference
- no source-photo embedding
- no text-layer learner content
- no unsupported reference path

Do not manually prettify or restructure exported JSON just for aesthetics.

---

## 45. Asset-size review

Record the exported JSON size.

Do not create an arbitrary hard fail limit in LTAM-2.

Instead classify the result:

- lightweight
- acceptable
- investigate
- unacceptable

If the idle file is unexpectedly large, inspect:

- excessive path points
- duplicated layers
- embedded raster data
- unnecessary masks
- redundant keyframes

before moving on.

---

## 46. Isolated Flutter proof harness

Create or use a development-only proof surface.

It must allow:

- play
- pause
- restart
- loop toggle
- size selection
- background selection
- reduced-motion fallback preview

Suggested sizes:

```text
56
72
88
150
180
320
```

Suggested backgrounds:

- transparent checker
- CSP11 light surface
- CSP11 dark surface
- glass surface

The harness must not be part of normal learner navigation.

---

## 47. Flutter proof behavior

Load:

```dart
Lottie.asset(
  'assets/learning_twin/motion/twin_idle.json',
  repeat: true,
)
```

The exact production renderer is deferred to LTAM-4/5.

LTAM-2 only proves the asset.

---

## 48. Android validation

Validate on physical Android hardware if available.

Check:

- first load
- loop smoothness
- no missing layers
- no flicker
- no frame tear
- no obvious dropped frames
- screen rotation if supported
- app background/resume
- repeated route open/close in proof harness
- dark/light background rendering

Prefer profile/release mode for performance judgment.

---

## 49. Web validation

Verify:

- animation loads without console asset error
- transparent background works
- loop is seamless
- resizing does not distort avatar
- no rendering difference from Glaxnimate that changes likeness
- repeated play/pause works
- browser tab background/return does not corrupt state

Use the renderer configuration supported by the project.

---

## 50. Windows validation

Verify:

- asset loading
- transparency
- scaling
- loop timing
- resize behavior
- no visual difference in eyes, beard, or coat
- no timing drift

---

## 51. Cross-platform visual parity

Compare screenshots or recorded observations from:

- Glaxnimate
- Android
- Web
- Windows

The following must match materially:

- face proportions
- eye placement
- eyelid coverage
- beard
- head movement
- torso breathing
- halo positioning
- loop start/end

Small renderer antialiasing differences are acceptable.

Structural differences are not.

---

## 52. Compact-size review

At 56–88 px verify:

- blink remains natural
- head drift is not noisy
- beard does not flicker
- pupils do not look unstable
- FX does not become clutter
- face remains recognisable

If FX is noisy at compact size, the later runtime renderer may suppress FX for compact variants.

Do not distort the main animation solely to optimize the smallest crop.

---

## 53. Hero-size review

At 150–320 px verify:

- breathing is subtle
- head movement looks natural
- eyes feel alive
- vector construction remains clean
- coat/neck overlap is invisible
- halo is not overpowering

Hero size is where uncanny facial motion is easiest to detect.

---

## 54. Reduced-motion proof

LTAM-2 must prove a static behavior.

When reduced motion is enabled in the proof harness:

- do not play the Lottie loop
- display the existing static SVG or frozen first frame
- keep size/layout identical
- preserve semantics

This does not yet require production policy wiring.

It proves the visual fallback path.

---

## 55. Semantics proof

The idle animation itself must not create repeated accessibility announcements.

The proof harness should treat the visual as:

```text
Naveed Learning Guide
```

or exclude semantics when decorative.

Blink, breathing, and halo must never be announced.

---

## 56. Runtime lifecycle proof

Even in the isolated harness verify:

- controller stops/disposes cleanly
- repeated mount/unmount does not throw
- no duplicate controller is retained
- pause/resume works
- loop restart is clean

The phase is not allowed to introduce a leaking animation pattern.

---

## 57. Off-screen policy design note

Production integration later should stop or pause animation when off-screen.

LTAM-2 does not need the final policy implementation, but the asset must not depend on continuously running while invisible.

---

## 58. Power and motion-restraint check

Run the idle loop continuously for several minutes on a physical device.

Observe:

- whether the device becomes unexpectedly warm
- whether scrolling with the proof visible remains smooth
- whether animation feels visually tiring
- whether the loop becomes annoying after repeated exposure

The last point is critical.

An idle animation that looks impressive for ten seconds may become irritating after five minutes.

---

## 59. Human visual review

Human acceptance should explicitly answer:

1. Does the avatar still look like Naveed?
2. Does breathing look natural?
3. Is the blink natural?
4. Does the head drift feel subtle?
5. Do the eyes remain calm?
6. Does the halo remain secondary?
7. Is the loop invisible?
8. Does the animation become distracting after repeated viewing?
9. Does it still feel professional?
10. Would this be acceptable beside study text?

Any major concern sends the asset back for tuning.

---

## 60. No-uncanny gate

Do not close LTAM-2 if the animation produces any of these:

- staring eyes
- slow eyelid motion
- eye asymmetry
- pupils moving too far
- smile twitch
- beard sliding
- head floating independently of neck
- chest visibly inflating
- repeated mechanical bobbing
- halo flashing
- robotic loop rhythm

The correct response is to simplify motion.

---

## 61. Idle restraint hierarchy

If animation feels too active, remove motion in this order:

```text
extra node motion
↓
extra halo pulse
↓
gaze shift
↓
head drift amplitude
↓
breathing amplitude
```

Keep the blink unless it is technically broken.

A minimal idle is preferable to an overanimated idle.

---

## 62. Asset manifest preparation

LTAM-2 may create the first motion-manifest candidate entry, but the final runtime manifest parser belongs to later phases.

Conceptual entry:

```json
{
  "idle": {
    "asset": "assets/learning_twin/motion/twin_idle.json",
    "loop": true,
    "fps": 30,
    "duration_ms": 6000,
    "fallback": "assets/learning_twin/naveed_twin.svg"
  }
}
```

Do not make production runtime depend on this manifest yet.

---

## 63. Test files

Recommended test/proof artifacts:

```text
test/features/learning_twin/motion/
├── twin_idle_asset_test.dart
├── twin_idle_render_smoke_test.dart
└── twin_idle_reduced_motion_proof_test.dart
```

Only add tests that provide stable value.

Temporal visual quality still requires human review.

---

## 64. Asset existence test

A simple test should verify that:

- `twin_idle.json` exists
- Flutter can load/parse it
- the JSON is not empty
- expected frame rate and frame range are present if practical to inspect

This catches packaging mistakes.

---

## 65. Regression boundary

LTAM-2 must not require changing existing Learning Twin UI components.

The current UI should continue rendering existing SVGs exactly as before.

No production navigation surface is allowed to switch to the idle Lottie yet.

---

## 66. Git strategy

Continue on:

```text
phase-learning-twin-motion-avatar
```

Suggested logical commits:

```text
LTAM-2A author idle choreography
LTAM-2B export idle Lottie proof
LTAM-2C add isolated Flutter proof harness
LTAM-2D validate Android Web Windows
LTAM-2E tune loop and performance
LTAM-2F freeze idle motion proof
```

Do not mix unrelated app changes.

---

## 67. Expected source files

Likely design/runtime structure after LTAM-2:

```text
design/learning_twin/
├── rig/
│   └── naveed_twin_master_rig.glaxnimate
└── motion/
    ├── naveed_twin_idle_v1.glaxnimate   # only if a separate derived file is needed
    └── review/
        ├── idle_bind.png
        ├── idle_midloop.png
        └── idle_dark_light_review.png

assets/learning_twin/
└── motion/
    └── twin_idle.json
```

If the canonical rig file can safely contain the idle composition, a separate Glaxnimate file is not mandatory.

---

## 68. Documentation

Create closure evidence:

```text
docs/learning_twin/
└── LTAM_2_IDLE_MOTION_PROOF_CLOSURE.md
```

The closure record should include:

- source commit
- source Glaxnimate hash
- `twin_idle.json` hash
- file size
- frame rate
- duration
- loop result
- Android result
- Web result
- Windows result
- reduced-motion result
- human visual review result
- known limitations
- next phase

---

## 69. CI considerations

Once implementation exists, CI should verify:

- Lottie asset included
- JSON parse succeeds
- no remote URLs
- no raw reference photo
- Flutter analyze
- focused motion tests
- full regression tests
- web build
- Android build in supported CI path
- `git diff --check`

Do not block on final Windows CI if the project has no Windows build agent, but manual Windows verification remains required for closure.

---

## 70. Rollback

LTAM-2 has an inherently safe rollback because production UI is not yet switched.

If the animation fails:

```text
ignore/remove twin_idle.json
↓
existing SVG Learning Twin continues unchanged
```

No learner data or migration is involved.

---

## 71. Acceptance checklist

LTAM-2 closes only when:

- [ ] LTAM-1C rig is used
- [ ] 30 fps authoring is used
- [ ] idle duration is approximately 6 seconds
- [ ] breathing is subtle
- [ ] blink is natural
- [ ] head drift is tiny
- [ ] gaze shift is tiny
- [ ] mouth remains stable
- [ ] brows remain neutral
- [ ] arms remain at rest
- [ ] legs remain stable
- [ ] generic FX remain subtle
- [ ] frame 0 and final frame visually match
- [ ] loop seam is not visible
- [ ] no joint gaps appear
- [ ] no face/beard tearing occurs
- [ ] transparent background works
- [ ] Lottie export is local-only
- [ ] no raw photo is embedded
- [ ] Android proof passes
- [ ] Web proof passes
- [ ] Windows proof passes
- [ ] compact review passes
- [ ] hero review passes
- [ ] reduced-motion static proof passes
- [ ] repeated viewing does not feel distracting
- [ ] production Learning Twin behavior remains unchanged
- [ ] closure evidence is recorded

---

## 72. Failure conditions

Do not proceed if:

- loop visibly jumps
- blink looks artificial
- breathing is obvious
- avatar identity is distorted
- pupils drift too far
- head movement looks like a deliberate gesture
- FX dominates the face
- exported Lottie differs materially from Glaxnimate
- Android/Web/Windows rendering differs structurally
- JSON contains the source photograph
- animation produces meaningful performance degradation
- production Learning Twin had to be changed merely to run the proof

Fix or simplify the idle first.

---

## 73. Frozen LTAM-2 sequence

```text
LTAM-2A
Open LTAM-1C rig
    ↓
LTAM-2B
Create six-second 30 fps idle composition
    ↓
LTAM-2C
Add subtle breathing
    ↓
LTAM-2D
Add one natural blink
    ↓
LTAM-2E
Add tiny head drift + gaze
    ↓
LTAM-2F
Add restrained halo/node FX
    ↓
LTAM-2G
Perfect loop seam
    ↓
LTAM-2H
Export twin_idle.json
    ↓
LTAM-2I
Flutter isolated proof harness
    ↓
LTAM-2J
Android / Web / Windows validation
    ↓
LTAM-2K
Reduced-motion + compact/hero review
    ↓
LTAM-2L
Human visual acceptance
    ↓
LTAM-2M
Freeze idle motion proof
```

---

## 74. Next phase

After LTAM-2 closes, proceed to:

# LTAM-3: Learning Twin Motion State Library

LTAM-3 will build state animations from the proven rig and idle language:

- welcome
- thinking
- explain
- insight ready
- focus
- encourage
- celebrate
- checkpoint
- exam ready
- result review

The idle animation remains the visual baseline for all of them.

No state should become more visually aggressive than necessary.

---

## 75. Final frozen outcome

LTAM-2 proves that the CSP11 Learning Twin can move beautifully without becoming a distraction.

```text
Naveed Learning Twin
      +
LTAM-1C rig
      +
6-second restrained choreography
      +
Glaxnimate
      ↓
twin_idle.json
      ↓
Android / Web / Windows proof
      ↓
seamless professional idle
      ↓
foundation for all future Twin motion
```

**LTAM-2 is the frozen Glaxnimate Idle Motion Proof contract.**
