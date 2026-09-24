# CSP11 LTAM-3: Learning Twin Motion State Library

**Status:** FROZEN IMPLEMENTATION PLAN  
**Freeze date:** 2026-09-23  
**Repository:** `thecrimsonengineer/exam_platform`  
**Branch:** `phase-learning-twin-motion-avatar`  
**Baseline commit:** `4bb93598b51f7bc82f59b041622aa4e7df143cab`  
**Parent:** LTAM-2 Glaxnimate Idle Motion Proof  
**Canonical Twin identity:** `Naveed • Learning Guide`  
**Authoring tool:** Glaxnimate  
**Export format:** Lottie JSON  
**Runtime target:** Flutter + `lottie`  
**Supported platforms:** Android, Web, Windows

---

## 1. Purpose

LTAM-3 creates the complete V1 motion-state library for the existing CSP11 Learning Twin.

The idle animation created and accepted in LTAM-2 becomes the visual and technical baseline. Every additional state must look like the same person, use the same rig, preserve the same restrained motion language, and return cleanly to an idle or hold state.

The state library is not allowed to become a second Learning Twin brain.

The existing CSP11 Learning Twin continues to decide:

- what message should appear
- whether guidance is eligible
- whether guidance is suppressed
- what learner event occurred
- whether a milestone is meaningful
- whether the learner needs remediation
- whether the learner is exam-ready
- what post-result guidance is appropriate

LTAM-3 only defines how those already-determined states are expressed visually.

The target pipeline is:

```text
Existing Learning Twin state
          ↓
presentation mapping
          ↓
LTAM-3 motion state
          ↓
Glaxnimate-authored Lottie clip
          ↓
Flutter renderer
          ↓
return to idle / hold
```

---

## 2. Frozen V1 state library

LTAM-3 will create exactly these production motion states:

```text
idle
welcome
thinking
explain
insight_ready
focus
encourage
celebrate
checkpoint
exam_ready
result_review
```

`idle` is inherited from LTAM-2.

The other ten states are created in LTAM-3.

No additional emotional state may be added casually.

Any extra state requires a later explicit extension because every additional animation increases maintenance, testing, runtime asset size, and emotional complexity.

---

## 3. Existing Learning Twin domain-state mapping

The frozen domain-to-motion mapping is:

```text
LearningTwinState.idle
    -> idle

LearningTwinState.welcome
    -> welcome

LearningTwinState.explain
    -> explain

LearningTwinState.tip
    -> insight_ready

LearningTwinState.important
    -> focus

LearningTwinState.warning
    -> focus

LearningTwinState.encourage
    -> encourage

LearningTwinState.celebrate
    -> celebrate

LearningTwinState.remediate
    -> focus

LearningTwinState.recommend
    -> insight_ready

LearningTwinState.checkpoint
    -> checkpoint

LearningTwinState.examReady
    -> exam_ready

LearningTwinState.resultReview
    -> result_review
```

If a future domain state has no explicit motion mapping, the renderer must fail safely to `idle`.

---

## 4. Shared motion language

Every state must inherit the LTAM-2 visual language:

- natural human proportions
- very small head movement
- restrained gaze motion
- no exaggerated cartoon motion
- no lip-sync
- no speech-flap animation
- no large body bounce
- no rapid flashing
- no unnecessary particle storms
- no animation that implies judgement of the learner
- no state that looks like disappointment
- no state that looks angry
- no shaming gestures
- no dramatic surprise
- no exaggerated applause

The Twin should feel like a calm instructor who reacts appropriately, not a game-show host.

---

## 5. Shared technical rules

All LTAM-3 clips must:

- use the same canonical LTAM-1C rig
- remain at 30 fps
- use transparent backgrounds
- use local bundled assets only
- use stable canonical filenames
- contain no learner text
- contain no learner progress values
- contain no CSP competency labels
- contain no scores
- contain no remote URLs
- contain no raw reference photograph
- remain Lottie-compatible
- render on Android, Web, and Windows
- have a state-appropriate static SVG fallback
- preserve facial identity
- avoid destructive rig edits

---

## 6. Clip architecture

States fall into three motion categories.

### Category A: continuous loop

```text
idle
thinking
```

These may loop while the underlying state remains active.

### Category B: one-shot reaction then idle

```text
welcome
insight_ready
encourage
celebrate
checkpoint
exam_ready
```

These should play once and then resolve into idle unless the future controller explicitly holds another state.

### Category C: one-shot entry then stable hold

```text
explain
focus
result_review
```

These states may finish on a calm state-specific hold pose before the renderer returns to idle.

The final controller behavior is implemented later. LTAM-3 only authors clips with a clear end contract.

---

## 7. Naming convention

Canonical filenames are frozen as:

```text
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
```

Do not use version suffixes in production filenames.

Git history and the motion manifest provide versioning.

---

## 8. Duration budget

Initial duration targets are frozen as follows:

```text
idle            6.0s loop
welcome         1.5s one-shot
thinking        2.4s loop
explain         2.4s entry/hold
insight_ready   1.3s one-shot
focus           1.6s entry/hold
encourage       1.3s one-shot
celebrate       1.8s one-shot
checkpoint      1.5s one-shot
exam_ready      1.7s one-shot
result_review   1.8s entry/hold
```

Each clip may be tuned within roughly ±0.3 seconds during human review when needed for natural timing.

No state should become a long cinematic sequence.

---

## 9. State priority

Visual priority is frozen as:

```text
celebrate
  ↓
checkpoint
  ↓
exam_ready
  ↓
result_review
  ↓
focus
  ↓
insight_ready
  ↓
explain
  ↓
encourage
  ↓
welcome
  ↓
thinking
  ↓
idle
```

This priority does not change business-event priority.

It only guides future animation interruption behavior.

Reduced motion overrides all priorities.

---

# 10. WELCOME STATE

## Purpose

The welcome state acknowledges the learner when the Twin is introduced or meaningfully re-entered.

It must not play every time a widget rebuilds.

## Choreography

```text
0.00s  start from calm pose
0.20s  slight posture settle
0.45s  tiny head acknowledgement
0.65s  soft smile increases slightly
0.90s  subtle halo activation
1.15s  expression relaxes
1.50s  resolve to idle-compatible pose
```

## Body language

Allowed:

- tiny head acknowledgement
- slight posture lift
- tiny shoulder settle

Avoid:

- waving
- bowing
- large nod
- arm flourish

## Facial treatment

- direct attentive gaze
- soft smile
- neutral brows with tiny friendly lift

## FX

- one low-intensity halo pulse
- optional soft node appearance

## Exit

Return to an idle-compatible pose.

## Canonical asset

`twin_welcome.json`

---

# 11. THINKING STATE

## Purpose

Thinking is shown only when the Twin is genuinely waiting on analysis, recomputation, or another meaningful state transition.

It must not fake intelligence when the app is not actually doing anything.

## Choreography

```text
0.00s  idle-compatible start
0.35s  gaze lifts slightly
0.65s  tiny head tilt
0.90s  brow focus increases
1.20s  node cluster begins slow reorganisation
1.65s  halo rotates subtly
2.00s  gaze softens
2.40s  loop boundary
```

## Loop rule

The start and end pose must be visually compatible.

## Facial treatment

- neutral mouth
- tiny focused brow
- slight upward/side gaze
- no dramatic squint

## Body treatment

- essentially stable
- no hand-to-chin gesture in V1
- no exaggerated head tilt

## FX

Thinking may have the most visible node activity of the V1 states, but it must still remain restrained.

Allowed:

- 2–3 generic nodes
- slow connector reconfiguration
- slow halo rotation

Not allowed:

- loading spinner in front of face
- rapidly orbiting particles
- fake code text

## Canonical asset

`twin_thinking.json`

---

# 12. EXPLAIN STATE

## Purpose

Explain supports instructional guidance.

This is the main teaching expression.

## Choreography

```text
0.00s  idle-compatible start
0.25s  attentive brow shift
0.50s  small head tilt
0.80s  one restrained open-hand gesture
1.20s  insight anchor appears softly
1.65s  hand settles
2.10s  face returns toward neutral
2.40s  calm explain hold
```

## Gesture rule

Only one small arm/forearm gesture is needed.

Preferred:

- open palm
- elbow near body
- hand movement stays within silhouette

Avoid:

- pointing finger
- repeated hand movement
- both arms gesturing at once
- presenter-style theatrics

## Face

- attentive eyes
- slight brow lift
- soft neutral/small smile
- no mouth movement

## FX

A small insight node or connector may activate near the guide anchor.

## Canonical asset

`twin_explain.json`

---

# 13. INSIGHT READY STATE

## Purpose

Signals that a useful recommendation, tip, or learning insight is ready.

This should feel like a subtle “something useful is available” reaction.

## Choreography

```text
0.00s  idle
0.20s  one node activates
0.40s  connector line draws
0.65s  tiny eye/brow acknowledgement
0.85s  slight smile
1.05s  glow settles
1.30s  return to idle-compatible pose
```

## Face

- tiny positive recognition
- no broad smile
- no surprise

## FX

This state relies slightly more on node/connector activity than body motion.

## Canonical asset

`twin_insight_ready.json`

---

# 14. FOCUS STATE

## Purpose

Focus represents important guidance, remediation, worthwhile review, or caution.

It must be supportive rather than negative.

## Emotional contract

Focus means:

```text
"This deserves your attention."
```

It must never mean:

```text
"You performed badly."
```

## Choreography

```text
0.00s  idle-compatible start
0.25s  smile relaxes
0.45s  brows become attentive
0.70s  gaze centres
0.95s  one focus node pulses
1.20s  posture becomes slightly steadier
1.60s  calm focus hold
```

## Forbidden reactions

- head shaking
- frown
- eye narrowing
- disappointment
- arms crossed
- finger wagging
- red alarm flashing

## FX

Use a restrained target-node pulse.

Colour meaning must be inherited from app semantics rather than forcing alarm red into the animation.

## Canonical asset

`twin_focus.json`

---

# 15. ENCOURAGE STATE

## Purpose

Reinforces persistence after useful effort, progress, or continued study.

## Choreography

```text
0.00s  idle
0.25s  soft smile increases
0.45s  tiny nod begins
0.70s  node pulse rises
0.95s  nod returns
1.30s  idle-compatible pose
```

## Body

A tiny nod is sufficient.

Optional small hand cue may be evaluated but is not required.

## Face

- supportive smile
- relaxed brows
- direct gaze

## Avoid

- thumbs up as the canonical gesture
- applause
- exaggerated nodding

## Canonical asset

`twin_encourage.json`

---

# 16. CELEBRATE STATE

## Purpose

Reserved for meaningful learner milestones.

It must not trigger for trivial actions.

## Choreography

```text
0.00s  idle
0.20s  posture rises slightly
0.45s  smile broadens
0.65s  shoulders open slightly
0.85s  halo pulse
1.05s  small particle burst
1.25s  optional restrained hand/arm lift
1.50s  settle begins
1.80s  idle-compatible end
```

## Emotional contract

Celebration should feel rewarding but professional.

The Twin is pleased with the learner's progress, not performing a victory dance.

## FX

Allowed:

- small particle burst
- one halo pulse
- one outward node pulse

Avoid:

- confetti filling the screen
- flashing lights
- bouncing
- repeated celebration loop

## Replay rule

This is a one-shot state.

Future runtime logic must not replay it merely because a widget rebuilds.

## Canonical asset

`twin_celebrate.json`

---

# 17. CHECKPOINT STATE

## Purpose

Signals completion of a meaningful learning checkpoint.

This state is calmer than celebration.

## Choreography

```text
0.00s  idle
0.25s  circular progress ring begins
0.60s  ring completes
0.80s  tiny nod
1.05s  ring fades to stable accent
1.50s  idle-compatible pose
```

## Face

- calm satisfaction
- small smile

## FX

Use one progress-style circular sweep.

The ring is decorative only.

It must not display or imply an actual percentage unless Flutter independently renders the true value.

## Canonical asset

`twin_checkpoint.json`

---

# 18. EXAM READY STATE

## Purpose

Represents an existing Learning Twin exam-readiness message outside a live timed examination.

## Accuracy rule

This animation must never imply guaranteed exam success.

It communicates confidence in preparation, not certainty of outcome.

## Choreography

```text
0.00s  neutral
0.25s  posture stabilises
0.50s  calm confident smile
0.80s  stable outer ring appears
1.10s  one controlled node activation
1.40s  ring settles
1.70s  idle-compatible end
```

## Face

- calm
- confident
- not celebratory

## Body

- upright
- steady
- no victory gesture

## FX

A stable ring is preferred to fireworks.

## Exam boundary

This state must not be shown inside timed exam question-taking where the existing Learning Twin suppression contract forbids interventions.

## Canonical asset

`twin_exam_ready.json`

---

# 19. RESULT REVIEW STATE

## Purpose

Supports post-assessment reflection.

It must work for both strong and weak results without visually judging the learner.

## Choreography

```text
0.00s  idle-compatible start
0.30s  attentive expression
0.60s  gaze centres
0.90s  two neutral review nodes appear
1.20s  small insight connector draws
1.50s  head returns to centre
1.80s  calm review hold
```

## Emotional contract

The canonical result-review animation is neutral-supportive.

The message text can communicate the actual result context.

The face must not switch to a sad expression for low scores.

## Why one canonical result-review state

V1 avoids separate “good score” and “bad score” emotional reactions.

This reduces the risk of:
- judgement
- shame
- excessive emotional interpretation
- misleading reaction to borderline results

## Canonical asset

`twin_result_review.json`

---

# 20. Shared transition rules

Every one-shot clip must start from an idle-compatible pose.

Every clip must either:

- end in an idle-compatible pose, or
- end in a documented stable hold pose

No clip may end with:

- arm mid-air
- eye mid-blink
- head sharply tilted
- particle burst incomplete
- halo at an awkward phase
- torso offset from neutral

This makes future controller transitions safe.

---

# 21. State-to-idle blending strategy

Do not rely on a runtime crossfade to hide badly matched endpoints.

Author the states so their endpoints naturally align with idle.

The future renderer may still use a short transition blend if helpful, but the source clips must be internally compatible.

---

# 22. One-shot replay identity

One-shot states likely to require event identity later are:

```text
welcome
insight_ready
encourage
celebrate
checkpoint
exam_ready
result_review
```

The animation library itself does not persist replay history.

Future controller logic will use message IDs, milestone IDs, checkpoint IDs, or equivalent stable event identifiers.

LTAM-3 simply guarantees that clips are safe one-shot assets.

---

# 23. Thinking lifecycle

Thinking is special because it may be stopped before completing many loops.

The animation must therefore look acceptable if interrupted at any point.

Avoid a choreography that depends on reaching a dramatic final frame.

Its loop should remain visually calm across the entire duration.

---

# 24. Facial consistency gate

Across all state clips, verify:

- same face shape
- same eyes
- same brow geometry
- same beard
- same hairstyle
- same nose
- same clothing
- same proportions
- same skin tones
- same overall likeness

State animation must never look like a different version of the person.

---

# 25. Expression amplitude hierarchy

Maximum facial-expression intensity should broadly follow:

```text
celebrate
   >
encourage / welcome
   >
explain / insight_ready
   >
exam_ready
   >
focus / result_review
   >
thinking
   >
idle
```

Even the strongest V1 expression remains professional.

---

# 26. Body-motion hierarchy

Maximum body-motion intensity should broadly follow:

```text
celebrate
   >
explain
   >
welcome / encourage
   >
checkpoint
   >
exam_ready
   >
focus / result_review
   >
thinking
   >
idle
```

No state uses full-body theatrical motion.

---

# 27. FX hierarchy

FX intensity may follow:

```text
celebrate
   >
insight_ready / checkpoint
   >
thinking
   >
exam_ready
   >
welcome / encourage
   >
focus / result_review
   >
explain
   >
idle
```

FX remain secondary to the character at all times.

---

# 28. Small-size motion policy

At compact sizes, not every state needs every visual effect.

The asset can still contain the full clip, but the later renderer may choose compact policies such as:

- hide particles
- suppress halo
- reduce node opacity
- use only facial motion
- use static fallback for very small surfaces

LTAM-3 must not hardcode screen-size logic into Lottie.

---

# 29. Hero-size motion policy

Hero surfaces may show the full motion clip.

At larger sizes, scrutinise:

- eye motion
- face deformation
- hand shapes
- joint overlap
- head/neck continuity
- clothing seams
- halo alignment

A clip that passes at 56 px may still fail visually at 320 px.

Both must be checked.

---

# 30. Reduced-motion contract

Every LTAM-3 state must have a safe static representation.

Use the current static Learning Twin family or an approved frozen frame.

Reduced motion must never require a separate emotional animation.

The future policy is:

```text
motion allowed
   -> Lottie state

reduced motion
   -> static state-appropriate Twin
```

---

# 31. State fallback mapping

Frozen fallback mapping:

```text
idle
  -> naveed_twin.svg

welcome
  -> naveed_twin.svg

thinking
  -> naveed_twin.svg

explain
  -> naveed_twin_explain.svg

insight_ready
  -> naveed_twin_explain.svg

focus
  -> naveed_twin.svg

encourage
  -> naveed_twin.svg

celebrate
  -> naveed_twin_success.svg

checkpoint
  -> naveed_twin_success.svg

exam_ready
  -> naveed_twin_success.svg or neutral after visual review

result_review
  -> naveed_twin_explain.svg
```

The exact `exam_ready` fallback can be finalised during visual review. It must not imply guaranteed success.

---

# 32. Glaxnimate source organisation

Recommended authoring structure:

```text
design/learning_twin/motion/
├── naveed_twin_idle_v1.glaxnimate
├── naveed_twin_welcome_v1.glaxnimate
├── naveed_twin_thinking_v1.glaxnimate
├── naveed_twin_explain_v1.glaxnimate
├── naveed_twin_insight_ready_v1.glaxnimate
├── naveed_twin_focus_v1.glaxnimate
├── naveed_twin_encourage_v1.glaxnimate
├── naveed_twin_celebrate_v1.glaxnimate
├── naveed_twin_checkpoint_v1.glaxnimate
├── naveed_twin_exam_ready_v1.glaxnimate
└── naveed_twin_result_review_v1.glaxnimate
```

If Glaxnimate supports reliable multiple compositions inside one canonical master file, separate files are optional.

The key requirement is one canonical rig identity and reproducible export.

---

# 33. Rig ownership rule

Do not fork the character rig separately for each state.

If a rig defect is found:

1. fix the canonical rig
2. propagate or regenerate state compositions
3. retest affected exports

Do not patch one state with unique face geometry unless absolutely necessary.

This prevents state drift.

---

# 34. Asset manifest candidate

The V1 motion manifest should eventually describe the full library.

Conceptually:

```json
{
  "schema_version": 1,
  "twin_id": "naveed_learning_guide",
  "default_motion_state": "idle",
  "states": {
    "idle": {
      "asset": "assets/learning_twin/motion/twin_idle.json",
      "loop": true
    },
    "welcome": {
      "asset": "assets/learning_twin/motion/twin_welcome.json",
      "loop": false
    },
    "thinking": {
      "asset": "assets/learning_twin/motion/twin_thinking.json",
      "loop": true
    }
  }
}
```

The final parser and runtime ownership remain later phases.

---

# 35. Lottie export quality gate

Each export must be checked for:

- expected frame rate
- expected duration
- transparent background
- no embedded source photo
- no remote assets
- no learner text
- no missing shape layers
- no unexpected clipping
- no unsupported effect substitution
- no broken pivots
- no first-frame flash
- no end-frame pop

A clip fails if Glaxnimate preview looks correct but Flutter output does not.

Runtime output is the acceptance target.

---

# 36. First-frame flash prevention

Every clip must render sensibly before animation advances.

Frame 0 must not contain:

- invisible character
- wrong mouth state
- wrong eye state
- misplaced arm
- giant halo
- off-screen node
- temporary setup geometry

This prevents one-frame flashes during asset load.

---

# 37. End-frame discipline

One-shot clips must end on a clean pose.

Do not leave transforms at an extreme and expect the future controller to magically fix them.

For each state, document:

```text
entry_pose
peak_pose
exit_pose
next_expected_state
```

---

# 38. Cross-state visual review

Review the state library together, not only one clip at a time.

Place thumbnail/frame captures side by side and check whether the emotional vocabulary is distinguishable but coherent.

The learner should be able to intuitively see differences between:

- thinking
- focus
- encourage
- celebrate

without each state becoming exaggerated.

---

# 39. Avoid emotional ambiguity

Key distinctions:

```text
thinking
= cognitive processing

focus
= pay attention

encourage
= keep going

celebrate
= meaningful achievement

result_review
= reflect on outcome
```

If two animations look nearly identical, simplify the library rather than adding arbitrary movement.

---

# 40. Accessibility semantics

Animation state must not be the sole carrier of meaning.

The existing Learning Twin title/message remains authoritative.

The Lottie state itself must not announce:

- “thinking”
- “celebrating”
- “focus”

unless the surrounding product semantics genuinely require that meaning.

Usually the avatar remains one semantic image:

```text
Naveed Learning Guide
```

or is decorative inside an already-labelled Learning Twin surface.

---

# 41. Performance budget

Do not assume ten short animations are harmless.

For every clip record:

- JSON size
- layer count
- mask count
- approximate vector complexity
- loop/one-shot type

Investigate any state that is significantly larger than the idle baseline without a good reason.

Celebration may be larger due to FX, but should still remain restrained.

---

# 42. Asset reuse

Prefer reusing the same internal vector artwork and rig structures rather than duplicating geometry.

If the Lottie exporter duplicates geometry per file, that is acceptable at packaging level, but authoring source should still share the same canonical master.

---

# 43. Android test matrix

On physical Android hardware, test every state for:

- successful load
- first-frame integrity
- correct duration
- no frame tear
- no visible dropped frames
- clean one-shot completion
- clean loop for thinking
- correct transparency
- no asset exception
- repeated state switching
- background/resume behavior

---

# 44. Web test matrix

Verify:

- every asset loads
- no console warnings that indicate missing assets
- no shape disappearance
- no timing distortion
- no scaling distortion
- loops remain seamless
- one-shots complete
- repeated switching remains stable

---

# 45. Windows test matrix

Verify:

- all clips load
- transparency is correct
- facial detail matches
- duration is correct
- resize is stable
- state switching works
- no renderer-specific clipping

---

# 46. State-transition proof harness

Extend the isolated motion proof harness so a developer can manually select:

```text
idle
welcome
thinking
explain
insight_ready
focus
encourage
celebrate
checkpoint
exam_ready
result_review
```

Controls should include:

- play
- pause
- replay
- loop on/off where applicable
- size
- background
- reduced-motion/static preview
- return to idle
- state-to-state switching

This harness remains outside learner navigation.

---

# 47. Transition torture test

Rapidly switch states in the developer harness to expose defects.

Examples:

```text
idle -> welcome -> idle
idle -> thinking -> explain
thinking -> insight_ready
focus -> encourage
encourage -> celebrate
checkpoint -> idle
exam_ready -> result_review
celebrate -> idle
```

The purpose is engineering robustness, not a production behavior recommendation.

---

# 48. Human review matrix

Each state must pass five human questions:

```text
1. Is the intended meaning visually understandable?
2. Does it still look like Naveed?
3. Is the motion restrained enough?
4. Does it feel professional?
5. Would it become annoying if seen repeatedly?
```

If the last answer is yes, reduce motion.

---

# 49. No-shame review

Specifically inspect:

- focus
- result_review
- exam_ready

Ensure none visually communicates:

- blame
- disappointment
- ridicule
- superiority
- false certainty

The Twin is a learning guide.

---

# 50. Visual hierarchy review

On real CSP11 surfaces, the future animation must remain below the information hierarchy.

Even though production integration comes later, mock the clips inside:

- a Learning Twin card
- a hero surface
- a compact tip
- a celebration surface

Check that motion does not steal attention from text and actions.

---

# 51. Motion intensity token

Document a simple internal motion-intensity classification:

```text
0 = static
1 = ambient
2 = subtle reaction
3 = meaningful reaction
```

Suggested state classification:

```text
idle          1
thinking      1
welcome       2
explain       2
insight_ready 2
focus         2
encourage     2
checkpoint    2
exam_ready    2
result_review 2
celebrate     3
```

No V1 state exceeds level 3.

This becomes a useful design guardrail.

---

# 52. State asset metadata

Each state should have metadata recording:

```text
state_id
filename
fps
duration_ms
loop
motion_intensity
fallback_asset
entry_contract
exit_contract
review_status
sha256
```

This metadata can feed the later motion manifest.

---

# 53. QA artefacts

Create review stills or short captured proofs for each state.

Suggested:

```text
design/learning_twin/motion/review/
├── welcome_peak.png
├── thinking_peak.png
├── explain_peak.png
├── insight_ready_peak.png
├── focus_peak.png
├── encourage_peak.png
├── celebrate_peak.png
├── checkpoint_peak.png
├── exam_ready_peak.png
└── result_review_peak.png
```

These are review artefacts, not runtime dependencies.

---

# 54. Source-control discipline

Do not commit temporary naming such as:

- test2
- final2
- fixed_final
- old
- new_new

Use canonical names.

Temporary experiments should remain outside the committed canonical asset tree unless needed as review evidence.

---

# 55. Regression boundary

LTAM-3 is still a motion-authoring phase.

Do not modify production Learning Twin decision services.

Do not alter learner message frequency.

Do not add animations to all screens yet.

Do not add runtime state controller logic yet beyond isolated proof harness needs.

Production integration belongs in later phases.

---

# 56. Recommended implementation sequence

```text
LTAM-3A
Freeze shared motion grammar
    ↓
LTAM-3B
Create welcome
    ↓
LTAM-3C
Create thinking
    ↓
LTAM-3D
Create explain
    ↓
LTAM-3E
Create insight_ready
    ↓
LTAM-3F
Create focus
    ↓
LTAM-3G
Create encourage
    ↓
LTAM-3H
Create celebrate
    ↓
LTAM-3I
Create checkpoint
    ↓
LTAM-3J
Create exam_ready
    ↓
LTAM-3K
Create result_review
    ↓
LTAM-3L
Cross-state review
    ↓
LTAM-3M
Android/Web/Windows validation
    ↓
LTAM-3N
State-library freeze
```

---

# 57. Suggested commit sequence

```text
LTAM-3A freeze motion-state grammar
LTAM-3B add welcome and thinking states
LTAM-3C add explain and insight states
LTAM-3D add focus and encourage states
LTAM-3E add celebrate and checkpoint states
LTAM-3F add exam-ready and result-review states
LTAM-3G add cross-state proof harness coverage
LTAM-3H validate platform parity
LTAM-3I freeze Learning Twin motion state library
```

No unrelated app changes should be mixed into this chain.

---

# 58. Expected runtime asset tree after LTAM-3

```text
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
```

These assets exist as validated production candidates but remain unbound to learner-facing production widgets until the renderer/controller phases.

---

# 59. Expected design tree

```text
design/learning_twin/
├── master/
├── rig/
└── motion/
    ├── source/
    ├── review/
    └── metadata/
```

The raw face reference remains outside the runtime repository.

---

# 60. Testing recommendations

Add stable automated tests only where they give meaningful protection.

Useful automated checks include:

- every canonical motion asset exists
- every asset parses
- expected frame rate is present
- expected loop metadata is present in manifest
- no remote asset URL exists
- no raw source image is referenced
- no duplicate state ID exists
- every state has a fallback
- every domain state mapping resolves

Temporal emotional quality remains human-reviewed.

---

# 61. Failure conditions

Do not close LTAM-3 if any state:

- breaks the canonical likeness
- contains uncanny facial movement
- visually judges the learner
- loops badly
- has a first-frame flash
- has an end-frame pop
- uses unsupported Lottie features
- renders differently across platforms in a material way
- contains excessive FX
- causes obvious performance degradation
- duplicates another state without meaningful distinction
- requires changing Learning Twin business logic

Fix or simplify the animation.

---

# 62. Acceptance checklist

LTAM-3 closes only when:

- [ ] LTAM-2 idle remains unchanged or intentionally versioned
- [ ] all ten new V1 motion states exist
- [ ] all clips use the canonical rig
- [ ] all clips preserve Naveed likeness
- [ ] all clips use 30 fps
- [ ] loop states loop cleanly
- [ ] one-shot states begin and end cleanly
- [ ] no clip uses speech/lip-sync
- [ ] no clip contains learner data
- [ ] no clip embeds the source photo
- [ ] no clip uses remote assets
- [ ] no clip visually shames the learner
- [ ] fallback mapping is complete
- [ ] Android validation passes
- [ ] Web validation passes
- [ ] Windows validation passes
- [ ] compact-size review passes
- [ ] hero-size review passes
- [ ] reduced-motion preview works
- [ ] cross-state visual review passes
- [ ] proof harness supports all states
- [ ] production Learning Twin logic remains unchanged
- [ ] closure documentation is complete

---

# 63. Closure document

Create:

```text
docs/learning_twin/
└── LTAM_3_MOTION_STATE_LIBRARY_CLOSURE.md
```

Record:

- baseline commit
- final state-library commit
- canonical rig version
- each asset filename
- each SHA-256
- each duration
- loop/one-shot classification
- motion intensity
- Android result
- Web result
- Windows result
- compact review
- hero review
- reduced-motion review
- known limitations
- exact next phase

The closure document must explicitly state:

```text
LTAM-3 added only validated motion assets and proof tooling.
No Learning Twin business decision logic was changed.
```

---

# 64. Next phase

After LTAM-3 closes, proceed to:

# LTAM-4: Motion Manifest, State Mapper and Flutter Renderer Foundation

LTAM-4 will introduce the presentation-side software architecture that safely maps the existing Learning Twin state into the validated Lottie asset library.

It will include:

```text
LearningTwinMotionState
LearningTwinMotionMapper
LearningTwinMotionManifest
LearningTwinMotionPolicy
LearningTwinMotionController
LearningTwinMotionRenderer
static fallback chain
reduced-motion handling
```

The key dependency direction remains:

```text
Learning Twin domain
        ↓
presentation mapping
        ↓
motion renderer
        ↓
Lottie
```

Never the reverse.

---

# 65. Final frozen outcome

LTAM-3 turns one proven idle avatar into a coherent visual vocabulary for the existing Learning Twin.

```text
              idle
                │
     ┌──────────┼──────────┐
     ↓          ↓          ↓
  welcome    thinking    explain
     │          │          │
     ↓          ↓          ↓
 insight      focus     encourage
     │          │          │
     └──────┬───┴─────┬────┘
            ↓         ↓
        checkpoint  celebrate
            │         │
            ├─────────┤
            ↓         ↓
       exam_ready  result_review
                │
                ↓
         unified motion library
                ↓
       LTAM-4 renderer foundation
```

**LTAM-3 is the frozen Learning Twin Motion State Library contract.**
