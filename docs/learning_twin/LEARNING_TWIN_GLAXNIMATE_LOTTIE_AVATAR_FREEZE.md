# CSP11 Learning Twin Glaxnimate/Lottie Avatar Motion Plan

**Status:** FROZEN IMPLEMENTATION PLAN  
**Freeze date:** 2026-09-23  
**Repository:** `thecrimsonengineer/exam_platform`  
**Plan branch:** `phase-learning-twin-motion-avatar`  
**Frozen baseline:** `acf87f6a67a923f2dcc9b70485cfac2f56962050`  
**Baseline source branch:** `phase-home-startup-integration-auth-hotfix-r9a7`  
**Feature:** Existing CSP11 Learning Twin  
**Canonical identity:** `Naveed • Learning Guide`  
**Authoring stack:** Glaxnimate -> Lottie JSON  
**Runtime stack:** Flutter + `lottie 3.6.1` + existing Flutter animation primitives  
**Supported runtime targets:** Android, Web, Windows

---

## 0. Freeze statement

This document freezes the implementation contract for adding a face-based animated Glaxnimate/Lottie presentation layer to the **existing** CSP11 Learning Twin.

This phase does **not** create a second Learning Twin, replace Phase M, redesign the Learning Twin domain model, or move Learning Twin intelligence into Lottie.

The existing Learning Twin remains the source of truth for:

- guidance state
- guidance trigger
- deterministic coaching decisions
- progress interpretation
- learner-facing message content
- session rules
- examination suppression rules
- accessibility meaning
- navigation behavior
- dismissal behavior
- learning recommendations

The new work adds a **motion-capable presentation renderer** beneath the existing Learning Twin UI.

The frozen architectural principle is:

```text
Existing Learning Twin intelligence
        ↓
Existing Learning Twin domain state
        ↓
Presentation mapping layer
        ↓
Animated Learning Twin renderer
        ↓
Glaxnimate-authored Lottie
```

Never:

```text
Lottie asset
   ↓
decides learning behavior
   ↓
changes learner state
```

Any future change that violates this direction requires an explicit architecture decision and must not be slipped into an animation phase.

---

# 1. Existing system audit and preservation contract

The baseline already contains a mature Learning Twin implementation under:

```text
lib/features/learning_twin/
├── coaching/
├── domain/
├── integration/
└── ui/
```

The current UI layer already includes:

```text
learning_twin_asset.dart
learning_twin_avatar.dart
learning_twin_bubble.dart
learning_twin_card.dart
learning_twin_celebration.dart
learning_twin_coach_sheet.dart
learning_twin_compact_tip.dart
learning_twin_hero.dart
learning_twin_inline_block.dart
learning_twin_ui.dart
```

The existing avatar renderer is `LearningTwinAvatar`. It renders bundled SVG assets using `flutter_svg`.

The existing canonical asset family is:

```text
assets/learning_twin/
├── naveed_twin.svg
├── naveed_twin_explain.svg
├── naveed_twin_success.svg
├── naveed_twin_fullbody.svg
├── naveed_twin.json
└── twin_manifest.json
```

The existing `LearningTwinAsset` enum is:

```text
neutral
explain
success
hero
```

The existing Learning Twin domain state enum is:

```text
idle
welcome
explain
tip
important
warning
encourage
celebrate
remediate
recommend
checkpoint
examReady
resultReview
```

The existing trigger enum is:

```text
screenVisit
learnerRequestedHelp
conceptOpened
contentCompleted
practiceCompleted
milestoneReached
remediationOpportunity
recommendationAvailable
preExam
postExam
```

These domain enums are **not replaced** by the animation system.

The current runtime has already integrated the Twin into controlled learning surfaces. The motion phase must preserve those placements and behavior. It must not accidentally introduce a new unsolicited intervention merely because animation becomes available.

---

# 2. Existing Phase M rules that remain frozen

The following Phase M decisions remain authoritative:

1. The canonical Twin is **Naveed • Learning Guide**.
2. The Twin is an instructor/learning companion, not a fictional mascot.
3. Guidance remains selective.
4. The Twin must not appear everywhere.
5. Unsolicited guidance remains governed by the existing decision/session layer.
6. Timed examination suppression remains fail-closed.
7. The animation layer must not expose protected quiz answers.
8. The animation layer must not read draft/admin content.
9. The animation layer must not add a new learner data store.
10. The animation layer must not add a new Firebase/Firestore read path.
11. The animation layer must not add an LLM dependency.
12. The animation layer must not change Study Hub, Domain, Competency, Practice, Quiz, or Exam readiness business rules.
13. Existing light/dark behavior must remain valid.
14. Existing dismissal behavior must remain valid.
15. Existing Learning Twin semantics must remain valid.
16. Existing static SVG artwork remains the fallback and recovery path until the animated replacement is fully accepted.

---

# 3. Purpose of this phase

The purpose is to evolve the existing static Learning Twin into a visually alive learning companion while keeping the proven Learning Twin architecture intact.

The target experience is:

- recognisably based on Naveed's face
- professional
- approachable
- restrained
- premium
- responsive to Learning Twin state
- lightweight enough for Home and Study surfaces
- deterministic
- accessible
- cross-platform
- offline-safe as a bundled asset
- visually consistent with CSP11 glassmorphism
- reusable across current and future Learning Twin surfaces

The animation should communicate state without becoming entertainment noise.

The Twin should feel alive because of timing, expression, posture, gaze, and network effects. It should not behave like a talking cartoon.

---

# 4. Explicit non-goals

This phase does not include:

- voice
- TTS
- lip synchronisation
- photorealistic face video
- live facial capture
- camera input
- 3D character rendering
- Rive
- Spine
- Unity
- remote avatar streaming
- server-generated animations
- AI-generated animation at runtime
- user-uploaded learner faces
- learner avatar customisation
- a new bottom-navigation item
- a new Learning Twin business engine
- a second Learning Twin screen
- Lottie-based text rendering
- score/progress values baked into animation JSON
- CSP competency names baked into animation JSON
- any animation inside timed exam questions
- replacing all existing SVGs immediately

Future phases may revisit some of these, but they are outside this freeze.

---

# 5. Approved face reference and privacy rule

A front-facing reference photograph was supplied by Naveed on 2026-09-23.

The reference contains:

- full head
- clear facial proportions
- neutral/slight positive expression
- beard and moustache detail
- clear hair silhouette
- formal suit, shirt, and tie
- front-facing lighting suitable for likeness construction

The source photograph is an **authoring reference only**.

## Frozen privacy rule

The raw face photograph must **not** be committed into the public/runtime repository as part of this phase.

The repository should contain only:

- approved vector-derived avatar artwork
- Glaxnimate authoring file
- exported Lottie JSON
- static fallback SVG
- manifests
- documentation
- tests

The source photo may remain outside the repository in the owner's private design/reference storage.

The runtime must never need the original face photograph.

---

# 6. Visual identity contract

The existing canonical identity remains:

`Naveed • Learning Guide`

The new avatar should preserve recognisable features from the supplied reference while remaining stylised enough for clean vector animation.

## 6.1 Facial characteristics to preserve

Preserve:

- overall head shape
- hairstyle silhouette and volume
- eyebrow shape
- eye spacing
- nose proportions
- beard outline
- moustache/beard relationship
- jawline
- natural smile shape
- overall professional appearance

Do not over-detail:

- skin pores
- individual beard hairs
- photographic lighting gradients
- realistic eye reflections
- fine suit fabric texture
- microscopic facial asymmetry

Recognition should come from silhouette and proportion, not photographic texture.

## 6.2 Clothing

The V1 animated avatar should use a professional instructor/mentor outfit.

Preferred default:

- dark professional coat/blazer
- clean light shirt
- restrained tie or open formal collar depending on final approved master
- no visible brand logos
- no PPE unless a later dedicated state requires it

The avatar should look suitable for a safety professional and instructor without becoming a corporate stock-photo caricature.

## 6.3 Background

Avatar artwork should be transparent.

Background glow, halo, domain nodes, and glass effects belong to the UI/effects layer and should not be permanently baked into the face artwork.

---

# 7. Avatar design deliverables

The authoring phase must produce one canonical master avatar rather than separately redrawing every state.

Required master views:

1. head-and-shoulders master
2. chest-up master
3. optional full-body master only if the existing hero surface still benefits from it

The head-and-shoulders master is the primary motion source.

The same base face must drive all emotional states.

---

# 8. Vector decomposition specification

The avatar must be decomposed into animation-friendly layers before Glaxnimate rigging.

Minimum hierarchy:

```text
naveed_learning_twin
│
├── torso_group
│   ├── coat_back
│   ├── coat_left
│   ├── coat_right
│   ├── shirt
│   ├── tie_or_collar
│   ├── shoulder_left
│   └── shoulder_right
│
├── neck_group
│   ├── neck
│   └── collar_shadow
│
├── head_group
│   ├── ear_left
│   ├── ear_right
│   ├── face_base
│   ├── beard_base
│   ├── beard_detail_optional
│   ├── hair_back
│   ├── hair_front
│   ├── eyebrow_left
│   ├── eyebrow_right
│   ├── eye_left
│   │   ├── eye_white
│   │   ├── iris
│   │   ├── pupil
│   │   ├── upper_lid
│   │   └── lower_lid_optional
│   ├── eye_right
│   │   ├── eye_white
│   │   ├── iris
│   │   ├── pupil
│   │   ├── upper_lid
│   │   └── lower_lid_optional
│   ├── nose
│   ├── mouth_group
│   │   ├── mouth_neutral
│   │   ├── mouth_soft_smile
│   │   ├── mouth_success_smile
│   │   └── mouth_concerned
│   └── cheek_highlight_optional
│
└── digital_fx_anchor_group
    ├── halo_anchor
    ├── left_node_anchor
    ├── right_node_anchor
    ├── top_node_anchor
    └── insight_anchor
```

The avatar must not contain hard-coded learner progress text.

---

# 9. Rigging contract in Glaxnimate

Use transform hierarchy rather than independent free-floating layers.

Recommended rig:

```text
root
└── torso
    └── neck
        └── head
            ├── hair
            ├── brows
            ├── eyes
            ├── nose
            ├── mouth
            └── beard
```

Key pivot rules:

- torso pivot: approximate lower chest centre
- neck pivot: base of neck
- head pivot: lower centre of head/upper neck
- brows: inner or central brow pivot
- eyelids: horizontal blink movement
- pupils: constrained movement only
- mouth states: central mouth pivot
- node anchors: outside the face group so face transforms do not distort HUD geometry unexpectedly

Avoid skeletal complexity unless clearly required.

V1 should primarily animate:

- translation
- rotation
- scale
- opacity
- simple vector path deformation

Avoid effects that do not export consistently to Lottie.

---

# 10. Animation philosophy

The Twin should use **micro-motion**, not constant performance.

The baseline principle is:

```text
mostly calm
+
brief meaningful reactions
+
return to calm
```

The Home/Study experience must never feel as if a character is demanding attention.

Motion categories:

1. ambient idle
2. acknowledgement
3. cognitive/thinking
4. explanation
5. encouragement
6. caution/focus
7. success/milestone
8. reduced motion/static

---

# 11. Motion state model

Do not reuse the domain enum directly as filenames. Create a presentation-only mapping layer.

Add a presentation enum similar to:

```dart
enum LearningTwinMotionState {
  idle,
  welcome,
  thinking,
  explain,
  insightReady,
  focus,
  encourage,
  celebrate,
  checkpoint,
  examReady,
  resultReview,
  reducedMotion,
}
```

This is a renderer concern only.

## 11.1 Frozen domain-to-motion mapping

```text
LearningTwinState.idle
    -> idle

LearningTwinState.welcome
    -> welcome

LearningTwinState.explain
    -> explain

LearningTwinState.tip
    -> insightReady

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
    -> insightReady

LearningTwinState.checkpoint
    -> checkpoint

LearningTwinState.examReady
    -> examReady

LearningTwinState.resultReview
    -> resultReview
```

If a state cannot be mapped safely, default to `idle`.

This mapping must be exhaustively unit tested.

---

# 12. State choreography specification

## 12.1 Idle

Purpose: normal presence.

Duration: 6-8 seconds loop.

Motion:

- extremely subtle breathing
- one blink per loop, with timing variation handled through alternate idle clips only if required later
- head drift no more than a few degrees
- tiny gaze adjustment
- subtle digital node pulse

Avoid:

- repeated nodding
- large smile changes
- hand gestures
- constant eye darting

## 12.2 Welcome

Purpose: first display or meaningful re-entry.

Duration: 1.2-1.8 seconds one-shot.

Sequence:

```text
fade/scale settle
↓
eye contact
↓
small friendly smile
↓
brief halo/node activation
↓
settle to idle
```

No waving is required in V1.

## 12.3 Thinking

Purpose: brief analysis state.

Duration: 1.6-2.4 seconds. May loop for a short controlled interval.

Sequence:

- gaze offset slightly
- brow adjustment
- two or three nearby knowledge nodes reorganise
- central halo slowly rotates
- no mouth animation

Thinking must never imply cloud computation if no computation is happening. It is only shown when the existing UI is actually waiting on a deterministic or asynchronous result.

## 12.4 Explain

Purpose: instructional guidance.

Duration: 2.0-3.0 seconds one-shot then idle/explain hold.

Sequence:

- attentive eye contact
- slight head tilt
- small eyebrow lift
- one subtle hand/shoulder cue only if rig allows
- node highlight near insight anchor

No mouth flapping.

## 12.5 Insight ready

Purpose: recommendation/tip ready.

Duration: 1.0-1.6 seconds one-shot.

Sequence:

- node lights
- connector line draws
- small positive expression shift
- return to idle

## 12.6 Focus

Purpose: warning, remediation, or worthwhile review.

Duration: 1.2-1.8 seconds one-shot then calm hold.

Sequence:

- smile relaxes
- brows become attentive, not alarmed
- target node pulses
- no red emergency flash unless the surrounding feature already uses a legitimate safety-critical warning pattern

The emotional tone is supportive attention, not disappointment.

## 12.7 Encourage

Purpose: reinforce persistence.

Duration: 1.0-1.6 seconds.

Sequence:

- soft smile
- tiny nod
- upward node pulse

## 12.8 Celebrate

Purpose: meaningful milestone.

Duration: 1.5-2.2 seconds one-shot.

Sequence:

- broader but professional smile
- slight upward posture
- halo pulse
- small particle burst
- no confetti storm
- return to idle

## 12.9 Checkpoint

Purpose: completion/checkpoint event.

Duration: 1.2-1.8 seconds.

Sequence:

- circular progress sweep around avatar
- brief nod
- settle

## 12.10 Exam ready

Purpose: readiness guidance outside live timed exam sessions.

Duration: 1.4-2.0 seconds.

Sequence:

- calm confident expression
- stable ring
- minimal celebratory motion

No exaggerated celebration. Exam readiness is a preparation signal, not guaranteed success.

## 12.11 Result review

Purpose: post-assessment reflection.

Duration: 1.4-2.2 seconds.

Sequence determined by existing result state, but V1 should remain neutral-supportive.

Do not produce a negative facial reaction solely because the learner scored poorly.

## 12.12 Reduced motion

Purpose: accessibility/low-motion mode.

Use static SVG or first frame.

No continuous breathing, orbiting particles, or repeated motion.

Meaning remains available through text and semantics.

---

# 13. Animation priority and interruption rules

When multiple presentation events arrive, animation must be deterministic.

Frozen priority:

```text
celebrate
  ↓
checkpoint
  ↓
examReady
  ↓
resultReview
  ↓
focus
  ↓
insightReady
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

Rules:

1. One-shot high-priority reactions may finish before a lower-priority event replaces them.
2. Idle is always interruptible.
3. Thinking is interruptible when its underlying wait condition ends.
4. Celebration must not replay repeatedly for the same domain event.
5. Screen rebuilds must not restart one-shot animations unintentionally.
6. Animation identity should be tied to an event/message ID when replay control is required.
7. Reduced-motion mode overrides all animation priority rules.

---

# 14. Frame rate and canvas contract

Start at **30 fps**.

Do not default to 60 fps.

Recommended authoring canvas:

- 512 x 512 for head/shoulders states
- 768 x 768 only if detail requires it
- separate larger hero composition only if required

The runtime widget determines rendered size.

Do not export oversized art merely because desktop screens exist.

---

# 15. Lottie compatibility rules

Keep exported animation conservative.

Preferred:

- shape layers
- transform animation
- opacity
- simple path animation
- simple masks only when verified
- vector fills/strokes
- precomps only when they remain export-safe

Avoid unless tested across Android/Web/Windows:

- unsupported blur effects
- heavy raster embedding
- excessive masks
- expressions
- platform-specific effects
- deep nested precomp trees
- very large numbers of vector points
- text layers that carry learner content
- external fonts required by the animation
- audio

Every animation must pass real runtime verification. A successful export alone is not acceptance.

---

# 16. Asset architecture

New assets should coexist with the existing static family.

Target structure:

```text
assets/
└── learning_twin/
    ├── naveed_twin.svg
    ├── naveed_twin_explain.svg
    ├── naveed_twin_success.svg
    ├── naveed_twin_fullbody.svg
    ├── naveed_twin.json
    ├── twin_manifest.json
    │
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
    │
    ├── fallback/
    │   └── twin_motion_static.svg
    │
    └── manifest/
        └── twin_motion_manifest.json

design/
└── learning_twin/
    ├── README.md
    └── naveed_twin_master.glaxnimate
```

The existing bundled SVG family must remain in place during rollout.

---

# 17. Manifest versioning

Do not immediately rewrite the existing `twin_manifest.json`.

Add a separate motion manifest first.

Example conceptual schema:

```json
{
  "schema_version": 1,
  "twin_id": "naveed_learning_guide",
  "authoring_tool": "Glaxnimate",
  "runtime": "lottie",
  "default_motion_state": "idle",
  "fallback_asset": "assets/learning_twin/naveed_twin.svg",
  "states": {
    "idle": {
      "asset": "assets/learning_twin/motion/twin_idle.json",
      "loop": true,
      "priority": 0
    },
    "welcome": {
      "asset": "assets/learning_twin/motion/twin_welcome.json",
      "loop": false,
      "priority": 2
    }
  }
}
```

A later consolidation may merge static and motion manifests only after the migration is proven.

---

# 18. Flutter architecture

## 18.1 Preserve the existing public surface

Current callers depend on:

```dart
LearningTwinAvatar(
  asset: ...,
  size: ...,
  decorative: ...,
  compactCrop: ...,
  semanticLabel: ...,
)
```

Do not force every existing Learning Twin caller to change in the first motion commit.

The initial animated renderer should preserve backward compatibility.

## 18.2 Proposed presentation files

```text
lib/features/learning_twin/ui/
├── learning_twin_asset.dart                  existing
├── learning_twin_avatar.dart                 existing public widget
├── learning_twin_motion_state.dart           new
├── learning_twin_motion_mapper.dart          new
├── learning_twin_motion_manifest.dart        new
├── learning_twin_motion_controller.dart      new
├── learning_twin_motion_renderer.dart        new
├── learning_twin_motion_policy.dart          new
└── learning_twin_motion_fallback.dart        new
```

Do not put these under the domain folder.

---

# 19. LearningTwinAvatar migration strategy

The safest implementation is to keep `LearningTwinAvatar` as the public façade.

Internally:

```text
LearningTwinAvatar
        ↓
motion allowed?
   ├── no -> existing SvgPicture path
   └── yes
        ↓
LearningTwinMotionRenderer
        ↓
Lottie asset
        ↓
failure?
   ├── yes -> existing SVG
   └── no -> animated Twin
```

The constructor can be extended with optional fields while retaining all existing defaults.

Conceptual API:

```dart
LearningTwinAvatar(
  asset: LearningTwinAsset.neutral,
  motionState: null,
  animationEnabled: true,
  reducedMotion: false,
  size: 56,
  decorative: false,
  compactCrop: true,
  semanticLabel: null,
  eventKey: null,
)
```

If `motionState == null`, the widget may derive a safe visual default from the existing `LearningTwinAsset`.

---

# 20. Existing asset fallback mapping

Frozen compatibility mapping:

```text
LearningTwinAsset.neutral
  -> motion idle
  -> fallback naveed_twin.svg

LearningTwinAsset.explain
  -> motion explain
  -> fallback naveed_twin_explain.svg

LearningTwinAsset.success
  -> motion celebrate
  -> fallback naveed_twin_success.svg

LearningTwinAsset.hero
  -> motion idle or dedicated hero idle
  -> fallback naveed_twin_fullbody.svg
```

This keeps old callers functional.

---

# 21. Learning Twin domain integration mapping

The domain layer should not import Lottie types.

Add the mapping at the presentation/integration boundary:

```text
LearningTwinMessage.state
       ↓
LearningTwinMotionMapper
       ↓
LearningTwinMotionState
       ↓
LearningTwinAvatar
```

A business service must never return an asset filename.

---

# 22. Existing surface rollout

Do not animate every existing placement at once.

Rollout order is frozen as follows.

## Stage A: isolated preview

Add a development-only preview/gallery screen or widget test harness for all motion states.

No learner-facing change.

Acceptance:

- every animation loads
- every animation falls back
- state transitions work
- reduced motion works
- light/dark containers work

## Stage B: existing LearningTwinHero

Use animation first on a larger controlled surface.

Reason:

- visual defects are easier to inspect
- more space exists
- less risk of tiny-motion clutter

## Stage C: existing LearningTwinCard

Enable animation in the current card without changing its business logic or message frequency.

The card's current layout and dismissal behavior stay intact.

## Stage D: LearningTwinCelebration

Map the existing success asset to the one-shot celebration animation.

Replay control must prevent repeat celebration during rebuild.

## Stage E: compact surfaces

Only after performance validation:

- LearningTwinCompactTip
- LearningTwinInlineBlock
- LearningTwinBubble/coach sheet where appropriate

Tiny surfaces may stay static if motion does not improve usability.

---

# 23. Home integration rule

The current app already has a Learning Twin system, while the current Home-R architecture does not need a new Twin engine.

If a Home Learning Twin summary card is introduced later, it must reuse:

- existing Learning Twin domain/services
- existing `LearningTwinAvatar`
- existing motion mapping
- existing Learning Twin semantics

Do not build a separate Home-only Twin.

Home may show a compact summary, but Home is not allowed to become a second Learning Twin architecture.

Home placement should be handled in a later integration slice after the animated renderer itself closes.

---

# 24. Full Learning Twin screen rule

If the app later exposes a richer dedicated Learning Twin screen, the animated avatar should be reusable as its visual centre.

The competency/network visualisation should remain Flutter-owned.

Lottie should not encode:

- competency IDs
- learner scores
- progress percentages
- readiness values
- daily plan data

Recommended split:

```text
Lottie
  face
  posture
  expression
  generic halo
  generic local particles

Flutter / CustomPainter
  real competency nodes
  progress arcs
  domain labels
  recommendations
  actual learner state
```

---

# 25. Dynamic effects outside Lottie

Not every effect should be exported from Glaxnimate.

Use Flutter for:

- card glow
- state-colour tint
- knowledge node layout
- connector paths
- progress rings
- readiness arcs
- one-off particle accents when cheap
- responsive scaling
- accessibility substitutions

This keeps the Lottie files small and generic.

---

# 26. Reduced motion

Respect platform accessibility preferences.

Motion policy should check the Flutter accessibility environment.

When reduced motion is active:

- do not loop idle breathing
- do not orbit particles
- do not repeatedly pulse halo
- use static fallback SVG or frozen first frame
- keep text, title, action, and semantic meaning unchanged

Reduced-motion behavior must be tested rather than assumed.

---

# 27. Semantics

The current `LearningTwinAvatar` already distinguishes decorative vs meaningful presentation.

Preserve that contract.

Rules:

- decorative animation: `ExcludeSemantics`
- meaningful avatar: one image semantic label
- do not announce every visual state change
- use surrounding Learning Twin message for actual guidance
- celebration live-region behavior remains owned by `LearningTwinCelebration`
- avoid duplicate announcement from Lottie and parent card

Example semantic labels remain concise:

- `Naveed Learning Guide`
- `Naveed Learning Guide explaining`
- `Naveed Learning Guide celebrating`

Do not announce decorative particles, blinks, breathing, or halo effects.

---

# 28. Performance budget

The animation system must have explicit budgets.

Initial budgets:

- 30 fps authoring target
- no startup-blocking animation load
- no network fetch
- local bundled assets only
- no animation file should be accepted solely because desktop can render it
- compact avatar must remain smooth on physical Android hardware
- no continuous animation when widget is off-screen
- pause animation in inactive routes where feasible
- avoid multiple simultaneous looping Twin animations on one screen

Use `Lottie.asset` with appropriate controllers and caching behavior where beneficial.

Measure release mode, not only debug mode.

---

# 29. Runtime loading policy

Frozen fallback chain:

```text
Lottie animation available and motion enabled
        ↓
animated Twin

Lottie unavailable / parse failure / policy disabled
        ↓
existing state-appropriate SVG

SVG failure
        ↓
safe native placeholder/icon without blocking UI
```

No avatar failure may prevent learner navigation.

No avatar failure may prevent the Learning Twin message from appearing.

The message is more important than the animation.

---

# 30. Preloading policy

Do not preload every animation at startup.

Recommended:

- idle may be warmed when the first Twin-containing route becomes active
- one-shot state asset loads on demand
- hero may preload only on a route known to use it
- never delay authentication/bootstrap/startup motion for Learning Twin animation assets

The existing CSP11 startup sequence owns app startup.

---

# 31. Lifecycle policy

Animation controllers must respect widget lifecycle.

Required behavior:

- stop/dispose controller on widget disposal
- do not restart one-shot clips during unrelated rebuild
- pause when route is no longer visible if practical
- re-enter idle cleanly after one-shot completion
- handle theme changes without resetting event state
- handle orientation/window resizing without restarting milestone animation
- handle hot reload only as a development concern

---

# 32. Event replay policy

One-shot animation must use a stable event identity when tied to an event.

Possible event sources:

- Learning Twin message ID
- milestone ID
- result review ID
- checkpoint ID

A rebuild with the same event ID must not automatically replay a milestone animation.

A genuinely new event may play it.

Do not persist cosmetic replay state to Firestore.

Session/local presentation state is sufficient unless a later product requirement explicitly demands cross-session replay control.

---

# 33. Glaxnimate authoring workflow

## Step 1: trace/build master vector

Use the approved face reference to create the stylised vector master.

Review likeness at:

- large view
- 150 px
- 88 px
- 56 px

If recognition collapses at 56 px, simplify or strengthen key shapes.

## Step 2: separate layers

Split the face according to the frozen layer hierarchy.

## Step 3: clean paths

Reduce unnecessary nodes.

Check:

- no accidental open paths
- no invisible giant bounding boxes
- no embedded reference photograph
- no duplicated hidden art
- correct transparency

## Step 4: import into Glaxnimate

Verify:

- layer names
- pivots
- canvas
- transforms
- colours
- clipping

## Step 5: create master idle

Idle becomes the rig proof.

Do not author all states until idle exports correctly.

## Step 6: export idle Lottie

Test in Flutter on all three target platforms.

## Step 7: create one-shot state family

Build states from the same rig.

## Step 8: export each state

Do not manually edit exported JSON unless an exceptional documented fix is required.

## Step 9: compare export with Glaxnimate preview

Record unsupported differences.

## Step 10: freeze authoring source

Commit the `.glaxnimate` file only after it is clean and reproducible.

---

# 34. Source-control rules for design assets

The canonical editable source is:

`design/learning_twin/naveed_twin_master.glaxnimate`

The runtime source is the exported JSON family.

Do not treat exported JSON as the editable master.

If a runtime JSON changes, the Glaxnimate source should change in the same logical change set unless the change is a documented export-tool metadata-only difference.

Do not commit temporary exports such as:

- `final2.json`
- `new.json`
- `test.json`
- `working.svg`

All assets must use canonical names.

---

# 35. Motion manifest loader

A small immutable presentation model should parse `twin_motion_manifest.json`.

Validation should fail closed to static mode if:

- schema version unsupported
- default state missing
- asset path malformed
- referenced state missing
- invalid loop flag
- invalid priority
- duplicate state key

Do not crash learner UI for manifest failure.

---

# 36. Testing strategy

## 36.1 Unit tests

Create:

```text
test/features/learning_twin/ui/
├── learning_twin_motion_mapper_test.dart
├── learning_twin_motion_manifest_test.dart
├── learning_twin_motion_policy_test.dart
├── learning_twin_motion_controller_test.dart
└── learning_twin_motion_fallback_test.dart
```

Test every domain state mapping.

Test every fallback.

Test every priority.

## 36.2 Widget tests

Verify:

- legacy `LearningTwinAvatar` invocation still renders
- `animationEnabled: false` renders SVG
- reduced motion renders static
- missing Lottie asset renders SVG
- semantic label appears once
- decorative mode excludes semantics
- size constraints remain stable
- compact crop behavior remains valid
- parent card layout remains unchanged
- celebration does not repeat on rebuild with same event key

## 36.3 Golden/visual tests

Use where stable and useful for:

- 56 px avatar
- 72/88 px celebration avatar
- 150 px hero
- light card
- dark card
- narrow Android width
- desktop width

Golden tests validate layout/static frames, not full temporal animation quality.

## 36.4 Integration tests

Exercise:

```text
Study Hub
→ Twin card
→ dismiss

Domain
→ Twin guidance
→ dismiss

Competency
→ Twin explain state

Practice/result
→ appropriate Twin state

Milestone
→ one-shot celebration
```

Ensure business behavior remains identical.

## 36.5 Manual physical-device tests

Required on Android release/profile build.

Observe:

- smoothness
- CPU/GPU impact
- frame drops
- battery/heat symptoms during repeated navigation
- rebuild/replay bugs
- background/foreground lifecycle
- dark mode
- text scale
- device rotation if supported

## 36.6 Web

Verify:

- first load
- route changes
- CanvasKit/web renderer behavior used by project
- no console asset errors
- responsive resize
- animation pause/disposal

## 36.7 Windows

Verify:

- asset load
- scaling
- resize
- animation timing
- release build

---

# 37. Regression contract

No implementation subphase may change the following without an explicit scoped reason:

- Learning Twin decision eligibility
- Learning Twin message wording
- Learning Twin message IDs
- dismissal rules
- one-unsolicited-intervention-per-visit behavior
- exam suppression
- learner progress calculations
- quiz scoring
- content loading
- Supabase/Firestore delivery
- auth
- Home-R behavior
- Startup Motion
- LAB
- Flashcards
- Study plan execution

This phase is presentation-only unless a later explicitly approved integration subphase says otherwise.

---

# 38. Dependency rule

The baseline already contains:

```yaml
lottie: ^3.6.1
flutter_animate: ^4.5.2
flutter_svg: ^2.2.0
```

Therefore the Learning Twin motion phase should introduce **no new runtime animation dependency** unless a blocking technical defect is proven.

Glaxnimate is an authoring tool and does not become a runtime dependency.

Do not replace the existing startup motion stack.

---

# 39. Interaction with existing startup motion

Startup Motion and Learning Twin Motion are separate systems.

Shared technology does not mean shared ownership.

```text
Startup Motion
  -> app launch choreography

Learning Twin Motion
  -> in-app learning companion
```

Do not place Learning Twin assets in `assets/startup/`.

Do not make startup wait for Twin assets.

Do not reuse startup state controllers for the Twin.

They may share coding conventions, but not feature state.

---

# 40. Branch strategy

This frozen plan lives on:

`phase-learning-twin-motion-avatar`

Base:

`acf87f6a67a923f2dcc9b70485cfac2f56962050`

This baseline is a descendant of the completed Phase M Learning Twin work and the later integrated Home/Startup/Auth stack.

The branch must remain isolated from any other active feature-development branch.

Future implementation should occur on this branch or on child branches from its frozen plan commit.

Suggested child checkpoints:

```text
phase-learning-twin-motion-avatar
├── ltam-1-master-art
├── ltam-2-idle-proof
├── ltam-3-state-library
├── ltam-4-flutter-renderer
├── ltam-5-existing-surface-integration
├── ltam-6-platform-validation
└── ltam-closed
```

Do not merge partially working animation into the release branch.

---

# 41. Detailed implementation phases

## LTAM-0: Freeze and baseline audit

Deliverables:

- this frozen plan
- exact baseline SHA recorded
- existing Learning Twin files inventoried
- existing asset hashes preserved
- no code changes

Exit gate:

- plan committed
- branch points to expected baseline + plan commit
- no runtime file changes

## LTAM-1: Master avatar artwork

Deliverables:

- face-reference-derived stylised master
- professional clothing
- transparent background
- animation-ready vector source
- small-size readability proof

Review sizes:

- 56 px
- 88 px
- 150 px
- 180 px

Exit gate:

- likeness accepted
- no raw source photo embedded
- no runtime integration

## LTAM-2: Glaxnimate rig and idle proof

Deliverables:

- `naveed_twin_master.glaxnimate`
- layer naming validated
- pivots validated
- `twin_idle.json`
- static motion fallback SVG

Exit gate:

- Android/Web/Windows idle renders
- loop seam accepted
- no obvious frame drop
- fallback verified

## LTAM-3: Motion state library

Deliverables:

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

Exit gate:

- all states export
- all states visually consistent
- all one-shots return cleanly to idle/hold
- no unsupported-export artefacts

## LTAM-4: Motion manifest and renderer foundation

Deliverables:

- motion manifest
- motion state enum
- mapper
- controller
- renderer
- fallback policy
- accessibility policy

Exit gate:

- focused tests green
- no changes to existing Learning Twin behavior
- legacy avatar API still valid

## LTAM-5: Existing avatar façade upgrade

Modify `LearningTwinAvatar` internally while retaining backward compatibility.

Exit gate:

- existing tests pass
- existing call sites compile unchanged
- animation can be globally disabled
- reduced motion works
- static fallback works

## LTAM-6: Hero pilot

Animate `LearningTwinHero` first.

Exit gate:

- responsive layouts pass
- Android narrow width accepted
- Web/Windows accepted
- no lifecycle/replay defects

## LTAM-7: Card integration

Enable state-aware motion in `LearningTwinCard`.

Do not change decision logic or message frequency.

Exit gate:

- Study Hub behavior unchanged
- Domain behavior unchanged
- Competency behavior unchanged
- dismissal unchanged
- motion does not dominate card

## LTAM-8: Celebration and result surfaces

Integrate one-shot celebration/result-review states where current Learning Twin components already exist.

Exit gate:

- no repeated one-shot on rebuild
- semantic live region remains correct
- poor results do not trigger shaming/negative animation

## LTAM-9: Compact surface audit

Evaluate each compact surface individually.

Decision for each:

- animated
- static by design
- animation only on explicit event

Do not assume every surface benefits from motion.

Exit gate:

- no screen has several competing Twin loops
- CPU/GPU behavior acceptable

## LTAM-10: Accessibility and motion-policy closure

Verify:

- reduced motion
- semantics
- text scale
- screen-reader duplication
- decorative state
- high contrast/theme legibility

Exit gate:

- accessibility tests green
- manual reduced-motion review accepted

## LTAM-11: Platform and release validation

Run:

- Flutter format
- Flutter analyze
- focused tests
- full test suite
- `git diff --check`
- Android release/profile build
- Web production build
- Windows build where build environment supports it
- physical-device Android review

Exit gate:

- no blocker
- release artifacts load locally
- no network dependency
- no startup regression

## LTAM-12: Closure freeze

Create closure document recording:

- exact commit
- asset list
- asset hashes
- Glaxnimate source hash
- animation JSON hashes
- test evidence
- build evidence
- manual visual acceptance
- known limitations
- rollback instructions

Then freeze/tag the implementation according to the repository's normal governance.

---

# 42. CI gates

A dedicated workflow should eventually verify:

1. expected branch ancestry
2. Dart format
3. Flutter analyze
4. focused Learning Twin tests
5. full Flutter tests
6. `git diff --check`
7. required animation assets exist
8. motion manifest references only existing assets
9. no remote asset URLs in manifest
10. raw reference photo is not committed
11. no business/domain file imports `package:lottie`
12. static fallbacks exist
13. web build passes
14. Android build passes in the project's supported CI path

Optional size gate:

- fail/warn when animation JSON exceeds a reviewed threshold

Do not hardcode an arbitrary threshold until real V1 assets are measured.

---

# 43. Architecture test

Add a regression test or repository check that prevents this dependency:

```text
lib/features/learning_twin/domain/
  importing
package:lottie
```

Also prevent domain/coaching code from referencing:

```text
assets/learning_twin/motion/
```

Animation belongs in UI/presentation.

---

# 44. Failure scenarios and required behavior

## Lottie parse failure

Expected:
- log diagnostically in development
- render SVG
- preserve message/action

## Missing state asset

Expected:
- map to idle or state-appropriate SVG
- no crash

## Motion manifest invalid

Expected:
- disable animated mode
- static Twin remains usable

## Device performance poor

Expected:
- motion policy can disable animation for that session/build strategy
- do not degrade learning functionality

## Reduced motion

Expected:
- static asset
- no looping motion

## Theme switch during animation

Expected:
- card theme updates
- animation event is not replayed solely because theme changed

## Widget rebuild

Expected:
- idle continues/restarts harmlessly
- one-shot event does not replay without a new event identity

## App backgrounded

Expected:
- controller behaves safely
- no duplicate milestone on resume

---

# 45. Rollback strategy

Rollback must be instant and low-risk.

Because the existing SVG renderer remains available, animated rendering can be disabled through a presentation-level flag/policy.

Rollback target:

```text
LearningTwinAvatar
   ↓
existing flutter_svg renderer
```

No Learning Twin domain/data migration is required for rollback.

No learner data rollback is required.

This is a major reason for preserving the existing public widget façade.

---

# 46. Product behaviour rules

The animated Twin must never:

- appear disappointed in the learner
- shake its head at wrong answers
- look angry at low scores
- celebrate trivial UI taps
- constantly move to attract attention
- interrupt timed exam work
- cover primary controls
- hide learning content
- imply an assessment result not supported by the model
- imply a competency is mastered solely because an animation played

Animation follows data. It does not redefine data.

---

# 47. Visual QA checklist

For every state verify:

- recognisable likeness
- professional expression
- eyes not uncanny
- blink natural
- beard/mouth layers do not tear
- head rotation does not expose gaps
- neck/coat relationship remains intact
- no clipping at compact size
- transparent background clean
- halo/effects do not obscure face
- first and last idle frames loop cleanly
- one-shot end frame transitions cleanly
- dark mode contrast acceptable
- light mode contrast acceptable
- mobile card not crowded

---

# 48. Acceptance criteria

The motion phase can close only when all of the following are true:

- [ ] Existing Learning Twin architecture remains intact
- [ ] Canonical identity remains `Naveed • Learning Guide`
- [ ] Face-based master avatar accepted
- [ ] Raw face photograph is not required at runtime
- [ ] Raw face photograph is not committed as a runtime asset
- [ ] Canonical Glaxnimate source committed
- [ ] Idle animation accepted
- [ ] Required state library exported
- [ ] Lottie files local/bundled
- [ ] Motion manifest valid
- [ ] Domain-to-motion mapping exhaustive
- [ ] Existing SVG fallbacks preserved
- [ ] Existing `LearningTwinAvatar` compatibility preserved
- [ ] Reduced-motion behavior verified
- [ ] Semantics verified
- [ ] Study Hub guidance behavior unchanged
- [ ] Domain guidance behavior unchanged
- [ ] Competency guidance behavior unchanged
- [ ] Practice/result coaching behavior unchanged
- [ ] Timed exam suppression unchanged
- [ ] Android verified
- [ ] Web verified
- [ ] Windows verified
- [ ] Physical Android review accepted
- [ ] Full Flutter regression suite green
- [ ] No new Firebase/Firestore reads introduced
- [ ] No new LLM dependency introduced
- [ ] No startup blocking introduced
- [ ] Closure document created
- [ ] Final commit/tag frozen

---

# 49. Future-safe extension points

After this phase is closed, future work may add:

- Home Learning Twin summary card
- richer full Learning Twin screen
- knowledge constellation around the avatar
- learner-selected avatar styles
- additional instructor gestures
- contextual domain-node effects
- optional voice/TTS as a separate architecture phase
- organisation-specific avatar skinning

These are deliberately not part of LTAM V1.

---

# 50. Final frozen implementation sequence

```text
LTAM-0  Freeze + baseline audit
   ↓
LTAM-1  Face-based master avatar
   ↓
LTAM-2  Glaxnimate rig + idle proof
   ↓
LTAM-3  Motion state library
   ↓
LTAM-4  Manifest + renderer foundation
   ↓
LTAM-5  Backward-compatible LearningTwinAvatar upgrade
   ↓
LTAM-6  Hero pilot
   ↓
LTAM-7  Existing card integration
   ↓
LTAM-8  Celebration/result integration
   ↓
LTAM-9  Compact surface audit
   ↓
LTAM-10 Accessibility + motion policy
   ↓
LTAM-11 Android/Web/Windows + physical device regression
   ↓
LTAM-12 Closure freeze
```

---

# 51. Frozen decision summary

The most important decision is that this phase **upgrades the existing Learning Twin instead of creating another one**.

The existing CSP11 Learning Twin already has:

- identity
- domain state
- triggers
- decision logic
- controlled placements
- UI components
- accessibility behavior
- static fallback artwork

Glaxnimate/Lottie therefore becomes a new **rendering capability**, not a new feature brain.

The implementation target is:

```text
Existing Learning Twin
        +
Face-based Naveed vector master
        +
Glaxnimate motion rig
        +
Lottie presentation renderer
        +
existing static SVG fallback
        =
Animated CSP11 Learning Twin
```

This contract is frozen.
