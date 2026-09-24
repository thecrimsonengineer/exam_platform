# CSP11 LTAM-1C: Animation Layer Preparation and Rig Architecture

**Status:** FROZEN IMPLEMENTATION PLAN  
**Freeze date:** 2026-09-23  
**Repository:** thecrimsonengineer/exam_platform  
**Branch:** phase-learning-twin-motion-avatar  
**Parent programme:** Learning Twin Glaxnimate/Lottie Motion Avatar  
**Canonical Twin identity:** Naveed • Learning Guide  
**Authoring target:** Glaxnimate  
**Runtime target:** Flutter + Lottie  
**Supported platforms:** Android, Web, Windows

## 1. Purpose

LTAM-1C converts the approved full-body master artwork into an animation-ready character architecture.

This phase does not create the final idle animation and does not integrate animated assets into learner-facing runtime surfaces. Its job is to prepare the master artwork so later Glaxnimate animation can be produced without redrawing, layer confusion, pivot failure, joint gaps, or Lottie-incompatible rigging.

The phase ends with one clean, deterministic, documented rig-ready master.

~~~text
Approved full-body master artwork
            ↓
Layer audit and cleanup
            ↓
Animation hierarchy
            ↓
Pivot architecture
            ↓
Face controls
            ↓
Body controls
            ↓
Digital effect anchors
            ↓
Rig validation poses
            ↓
Frozen rig-ready Glaxnimate master
            ↓
LTAM-2 Idle Motion Proof
~~~

## 2. Preservation contract

The existing CSP11 Learning Twin remains authoritative for learning behavior.

LTAM-1C must not change:

- Learning Twin domain state
- Learning Twin triggers
- deterministic guidance decisions
- learner progress interpretation
- message content
- dismissal behavior
- exam suppression
- navigation
- Home behavior
- authentication
- Startup Motion
- Study Hub guidance logic
- Domain guidance logic
- Competency guidance logic
- Practice/Quiz coaching logic
- existing learner data

Existing runtime avatar assets also remain untouched during this phase.

~~~text
assets/learning_twin/
├── naveed_twin.svg
├── naveed_twin_explain.svg
├── naveed_twin_success.svg
├── naveed_twin_fullbody.svg
├── naveed_twin.json
└── twin_manifest.json
~~~

The new rig is developed under design/learning_twin/ until later runtime acceptance.

## 3. Rigging strategy freeze

The V1 Learning Twin rig will use a portable transform hierarchy, not a complex skeletal animation system.

This means motion is built primarily from:

- parent/child transform groups
- position
- rotation
- scale
- opacity
- simple path morphing
- controlled clipping/masks only where verified

The rig must not depend on an authoring-only feature that cannot export reliably to Lottie.

The hierarchy itself is the rig.

~~~text
simple portable transforms
        >
clever editor-only rigging
~~~

If Glaxnimate offers a bone/deformation feature that does not survive Lottie export consistently, it must not become a required part of the canonical V1 rig.

## 4. Bind pose

Create one canonical bind pose.

The bind pose is:

- front-facing
- upright
- neutral standing
- relaxed shoulders
- arms naturally resting
- elbows not fully locked
- legs naturally separated
- head nearly centred
- soft neutral expression
- eyes looking forward
- mouth neutral/soft smile
- digital effects hidden or at neutral opacity

The bind pose is the recovery state for all motion states. Every future animation must be able to return cleanly to this pose or a clearly documented derived hold pose.

## 5. Root hierarchy

~~~text
NAVEED_TWIN_MASTER
│
├── FX_ROOT
├── BODY_ROOT
│   ├── LEG_LEFT_ROOT
│   ├── LEG_RIGHT_ROOT
│   └── TORSO_ROOT
│       ├── ARM_LEFT_ROOT
│       ├── ARM_RIGHT_ROOT
│       └── NECK_ROOT
│           └── HEAD_ROOT
│               ├── FACE_ROOT
│               ├── HAIR_ROOT
│               └── FACIAL_CONTROLS
│
└── GUIDE_ANCHORS
~~~

This hierarchy must be preserved in Glaxnimate.

Layer order may differ for correct drawing order, but transform ownership must remain conceptually equivalent.

## 6. Naming convention

All animation source layers must use stable machine-readable names.

Use lowercase snake_case for internal art layers.

~~~text
body_root
torso_root
neck_root
head_root
upper_arm_left
forearm_left
hand_left
eye_left_iris
eye_left_pupil
eyelid_left_upper
eyebrow_left
mouth_neutral
halo_anchor
~~~

Avoid spaces, punctuation-heavy names, anonymous editor names, copy suffixes, and temporary naming.

Layer names become part of debugging and asset maintenance.

## 7. Layer preparation audit

Before rig construction, inspect every master-artwork component.

Each component must satisfy:

~~~text
one visual responsibility
+
clear name
+
clean bounds
+
correct stacking
+
correct transform ownership
~~~

Remove duplicate hidden shapes, accidental empty groups, embedded source photography, exportable reference guides, invisible off-canvas objects, unused masks, redundant gradients, excessive path points, and temporary design notes inside the runtime tree.

## 8. Root transform

Create a master root transform.

The root owns global position, overall scale, and global opacity if ever required.

It must not be used for routine head, torso, or expression movement.

This allows the complete character to be placed on different compositions without changing its internal rig.

## 9. Body root

body_root owns the entire physical character.

It must contain the torso, neck/head chain, both arms, and both legs.

It must not contain UI text, learner data, competency labels, or progress indicators.

## 10. Torso architecture

~~~text
torso_root
├── coat_back
├── shirt
├── tie
├── collar_left
├── collar_right
├── coat_left
├── coat_right
├── shoulder_overlay_left_optional
└── shoulder_overlay_right_optional
~~~

The torso pivot should sit around the lower chest/upper abdomen for subtle posture motion.

The torso artwork must overlap the neck and upper arms enough to prevent visible holes during minor movement.

Do not merge all clothing into a single immutable path if that prevents clean shoulder movement.

## 11. Neck architecture

~~~text
neck_root
├── neck_base
├── neck_shadow_optional
└── head_root
~~~

The head pivot should sit near the natural base of the skull/upper neck rather than the centre of the face.

Expected future motion is intentionally small: tiny tilt, tiny nod, and tiny gaze-oriented head movement.

## 12. Head root

head_root owns the face, ears, beard, moustache, eyes, eyebrows, nose, mouth, and hair.

All facial features must remain correctly attached when the head moves.

The head root must not own halo or real competency graphics.

## 13. Face base

~~~text
face_root
├── ear_left
├── ear_right
├── face_base
├── face_shadow
├── face_highlight
├── beard_base
├── moustache
├── nose
├── eye_left_root
├── eye_right_root
├── eyebrow_left
├── eyebrow_right
└── mouth_root
~~~

Face shading should remain simple enough that head movement does not expose seams.

## 14. Eye rig

Each eye is independent.

~~~text
eye_left_root
├── eye_left_white
├── eye_left_iris
├── eye_left_pupil
├── eyelid_left_upper
└── eyelid_left_lower_optional

eye_right_root
├── eye_right_white
├── eye_right_iris
├── eye_right_pupil
├── eyelid_right_upper
└── eyelid_right_lower_optional
~~~

The iris and pupil may share small gaze transform groups.

Gaze movement must be constrained. V1 supports forward gaze, tiny left/right shifts, and a slight upward thinking shift.

## 15. Blink architecture

Blinking should use eyelid movement or simple eyelid path change.

~~~text
open
↓
half closed
↓
closed
↓
half open
↓
open
~~~

The rig must not simulate blinking by vertically scaling the entire eyeball.

Both eyes normally blink together. A wink is outside V1.

## 16. Eyebrow rig

Use independent eyebrow_left and eyebrow_right groups.

Each should support position, slight rotation, and only export-safe path deformation.

The V1 brow vocabulary must support neutral, attentive, thinking, explain, focus, encourage, and celebrate.

Avoid cartoon-scale brow movement.

## 17. Mouth architecture

~~~text
mouth_root
├── mouth_neutral
├── mouth_soft_smile
├── mouth_success_smile
└── mouth_focus
~~~

Only one primary mouth state is visible at a time.

Transitions may use opacity crossfade, simple compatible path morphing, or tiny transform adjustments.

V1 must not implement phoneme mouth shapes or lip-sync.

## 18. Beard and mouth interaction

The beard must not block mouth movement.

Recommended structure:

~~~text
beard_base
beard_chin
moustache
mouth_root
~~~

If needed, use a small beard_mouth_overlay to maintain facial continuity.

Rig validation must check that smiling does not create beard tearing, face gaps, moustache collisions, or a floating-mouth appearance.

## 19. Hair architecture

~~~text
hair_root
├── hair_back
├── hair_main
├── hair_front
└── hair_highlight_optional
~~~

Hair moves with the head.

V1 does not require secondary hair simulation.

## 20. Left arm hierarchy

~~~text
arm_left_root
└── upper_arm_left
    └── forearm_left
        └── hand_left
~~~

Pivots sit at the shoulder, elbow, and wrist.

Artwork must overlap at joints.

V1 motion remains restrained: small explain cue, subtle welcome movement, and small encouragement gesture.

## 21. Right arm hierarchy

~~~text
arm_right_root
└── upper_arm_right
    └── forearm_right
        └── hand_right
~~~

The structure may be symmetrical while the visible pose remains naturally asymmetrical.

## 22. Hand architecture

V1 does not need finger-by-finger rigging.

Each hand may be one primary vector group.

If another gesture is needed, use state variants such as:

~~~text
hand_left_relaxed
hand_left_open
~~~

Prefer state switching over a complex finger rig.

## 23. Leg hierarchy

~~~text
leg_left_root
└── upper_leg_left
    └── lower_leg_left
        └── shoe_left

leg_right_root
└── upper_leg_right
    └── lower_leg_right
        └── shoe_right
~~~

Pivots sit at the hip, knee, and ankle.

V1 is not a walking character. Leg rigging exists for natural stance, subtle weight shift, and future hero movement.

## 24. Joint overlap rule

Every rotating joint must include sufficient artwork overlap.

Required checks include neck/head, shoulder/upper arm, elbow/forearm, wrist/hand, hip/thigh, knee/lower leg, and ankle/shoe.

The construction should use layered overlap rather than edge-to-edge contact.

## 25. Pivot documentation

Every major pivot must be deliberately placed and documented.

~~~text
pivot_root
pivot_torso
pivot_neck
pivot_head

pivot_shoulder_left
pivot_elbow_left
pivot_wrist_left

pivot_shoulder_right
pivot_elbow_right
pivot_wrist_right

pivot_hip_left
pivot_knee_left
pivot_ankle_left

pivot_hip_right
pivot_knee_right
pivot_ankle_right
~~~

Pivots become stable after this rig is frozen.

## 26. Digital effect architecture

Digital effects are separate from the body rig.

~~~text
fx_root
├── halo_root
├── node_fx_root
├── particle_fx_root
├── insight_fx_root
└── status_fx_root
~~~

These groups may remain placeholders in LTAM-1C.

## 27. Guide anchors

~~~text
guide_anchors
├── anchor_halo_center
├── anchor_insight_top
├── anchor_node_left
├── anchor_node_right
├── anchor_node_upper_left
├── anchor_node_upper_right
├── anchor_torso_core
└── anchor_ground
~~~

These are layout reference points only. Real domain, competency, readiness, and learner values remain Flutter-owned.

## 28. Draw-order contract

Transform hierarchy and draw order are not always identical.

Document exceptions required to prevent arms crossing coats incorrectly, beard/face ordering errors, eyelid layering errors, and hand/torso conflicts.

Where needed, use front/back visual layers while preserving transform ownership.

## 29. Clipping and mask policy

Use clipping only where necessary.

Legitimate candidates include pupil/iris eye bounds, eyelid coverage, and limited face highlights.

Avoid masks for routine body joints.

Any mask used must survive a Lottie export smoke test before the rig can close.

## 30. Gradient policy

Prefer flat fills and simple compatible gradients.

Avoid gradient meshes and editor-specific shading.

The avatar must remain attractive without fragile rendering features.

## 31. Transform limits

Expected movement ranges remain deliberately small.

Head tilt, head nod, torso sway, shoulder movement, wrist movement, eye gaze, brow movement, and leg weight shift should remain subtle.

Exact degrees and pixel offsets are intentionally deferred to LTAM-2 visual testing.

## 32. Expression control matrix

~~~text
STATE        BROWS        EYES         MOUTH           HEAD
idle         neutral      forward      soft neutral    centred
welcome      slight lift  forward      soft smile      tiny settle
thinking     focused      slight up    neutral         tiny tilt
explain      attentive    forward      soft smile      small tilt
insight      slight lift  forward      soft smile      centred
focus        attentive    forward      focus           centred
encourage    relaxed      forward      smile           tiny nod
celebrate    lifted       forward      success smile   tiny rise
~~~

LTAM-1C prepares the controls. It does not author final timing curves.

## 33. Body control matrix

Prepare the rig for idle torso breathing, welcome settling, a small explain gesture, stable focus posture, encouragement nods, and a restrained celebration response.

No final animation timing is authored in this phase.

## 34. Rig test poses

Required engineering pose proofs:

~~~text
P0 bind
P1 head tilt left
P2 head tilt right
P3 blink closed
P4 thinking brows/gaze
P5 explain arm pose
P6 encourage nod hold
P7 celebrate pose
P8 subtle weight shift
~~~

These are test poses, not final animation clips.

## 35. Rig stress test

Use slightly exaggerated temporary rotations to expose gaps at the head, elbow, wrist, shoulder, hip, knee, and ankle.

If a seam opens, either improve overlap or formally narrow the safe range.

Do not make production motion exaggerated merely because a stress test uses it.

## 36. Small-size validation

Inspect the rig and derived crops at:

- 180 px
- 150 px
- 88 px
- 72 px
- 56 px

At compact sizes, some motion details may later be disabled if they become visual noise.

The rig should allow that policy rather than requiring all controls on all surfaces.

## 37. Full-body and cropped variants

The canonical rig remains full-body.

All other views derive from it:

~~~text
full-body master rig
       ↓
hero crop
mid-body crop
head/shoulders crop
compact crop
~~~

Do not create unrelated portrait rigs.

## 38. Glaxnimate source architecture

~~~text
design/learning_twin/
├── master/
│   ├── naveed_twin_master_fullbody.svg
│   └── README.md
│
└── rig/
    ├── naveed_twin_master_rig.glaxnimate
    ├── RIG_MAP.md
    ├── RIG_LAYER_MANIFEST.json
    └── review/
        ├── bind_pose.png
        ├── head_tilt_test.png
        ├── blink_test.png
        ├── explain_pose_test.png
        └── celebrate_pose_test.png
~~~

The source Glaxnimate file must not live under runtime assets.

## 39. Rig layer manifest

Create a machine-readable manifest of required canonical layer names.

~~~json
{
  "schema_version": 1,
  "twin_id": "naveed_learning_guide",
  "required_groups": [
    "body_root",
    "torso_root",
    "neck_root",
    "head_root",
    "arm_left_root",
    "arm_right_root",
    "leg_left_root",
    "leg_right_root",
    "fx_root",
    "guide_anchors"
  ],
  "required_face_controls": [
    "eye_left_root",
    "eye_right_root",
    "eyebrow_left",
    "eyebrow_right",
    "mouth_root"
  ]
}
~~~

This manifest allows future validation to detect accidental layer deletion or renaming.

## 40. Rig map documentation

RIG_MAP.md must document layer hierarchy, parent-child relationships, pivot intent, draw-order exceptions, visibility-state layers, mouth variants, hand variants, digital anchors, export exclusions, and known limitations.

The rig map is part of the canonical asset system.

## 41. Export exclusions

Authoring-only elements such as the reference photo, construction guides, safe-area markings, pivot markers, notes, and pose-test labels must not enter runtime exports.

## 42. Raw photo protection

The approved face reference remains private authoring input.

The Glaxnimate file must not embed the raw source photograph.

Before closure, inspect the source package to ensure no hidden image layer contains it.

## 43. Lottie readiness gate

Before LTAM-1C closes, create a minimal temporary transform proof:

~~~text
bind pose
↓
tiny head rotation
↓
tiny arm rotation
↓
blink proof
↓
return
~~~

Export that proof to Lottie and verify hierarchy, pivots, masks, shape rendering, and absence of missing art.

The proof is an engineering artifact, not a production animation.

## 44. Flutter smoke proof

Load the temporary rig-proof Lottie only in an isolated developer test surface.

Verify it renders consistently on Android, Web, and Windows and matches the Glaxnimate preview.

Do not wire it into LearningTwinAvatar yet.

## 45. Performance sanity check

Check exported JSON size, layer count, vector complexity, mask count, simple render smoothness, and repeated open/close behavior.

If the rig is already heavy before real motion exists, simplify it now.

## 46. No production runtime integration

LTAM-1C must not modify the current Learning Twin runtime widgets merely to demonstrate the rig.

The following remain production-stable:

~~~text
lib/features/learning_twin/ui/learning_twin_avatar.dart
lib/features/learning_twin/ui/learning_twin_card.dart
lib/features/learning_twin/ui/learning_twin_hero.dart
lib/features/learning_twin/ui/learning_twin_celebration.dart
~~~

A developer-only harness is acceptable only if isolated from production navigation.

## 47. Versioning

The first accepted rig should record:

~~~text
twin_id: naveed_learning_guide
rig_version: ltam-1c-v1
artwork_parent: ltam-1b-v1
runtime_status: not_published
~~~

## 48. Git strategy

Suggested checkpoint sequence:

~~~text
LTAM-1C1 prepare animation layer hierarchy
LTAM-1C2 establish transform parenting and pivots
LTAM-1C3 add facial control architecture
LTAM-1C4 add body and gesture rig architecture
LTAM-1C5 add FX anchors and rig manifest
LTAM-1C6 validate Glaxnimate to Lottie transform proof
LTAM-1C7 freeze rig architecture
~~~

No unrelated feature changes belong in this sequence.

## 49. Validation checklist

LTAM-1C closes only when all of the following pass:

- canonical full-body artwork is used as the source
- runtime Learning Twin remains unchanged
- transform hierarchy is complete
- major layers use stable names
- major pivots are intentionally placed
- head/neck chain is clean
- eye and blink rig is clean
- brows are independently controllable
- mouth states are independently controllable
- beard does not block mouth motion
- arms have shoulder/elbow/wrist hierarchy
- hands use a low-complexity state strategy
- legs have hip/knee/ankle hierarchy
- joint overlaps prevent gaps
- digital effect anchors exist
- real learner data is absent from the rig
- source photo is not embedded
- authoring-only guides are excluded from export
- rig map is documented
- rig layer manifest exists
- static pose tests pass
- minimal Lottie proof exports
- proof renders in Flutter test harness
- no obvious Android/Web/Windows rendering defect exists
- no obvious performance blocker exists
- rig version is frozen

## 50. Failure conditions

Do not move to LTAM-2 if the blink tears the face, pupils escape the eye area, beard/mouth layers collide, head movement exposes a neck gap, arm movement exposes a shoulder gap, wrist movement detaches the hand, leg movement opens joint gaps, pivots create unnatural arcs, the raw photo is embedded, the rig relies on non-exportable editor behavior, the Lottie proof differs materially from Glaxnimate, or the hierarchy is too complex to maintain.

Fix the rig before timing animation.

## 51. Deliverables

~~~text
design/learning_twin/
├── master/
│   └── naveed_twin_master_fullbody.svg
│
└── rig/
    ├── naveed_twin_master_rig.glaxnimate
    ├── RIG_MAP.md
    ├── RIG_LAYER_MANIFEST.json
    └── review/
        ├── bind_pose.png
        ├── blink_test.png
        ├── thinking_pose_test.png
        ├── explain_pose_test.png
        ├── encourage_pose_test.png
        └── celebrate_pose_test.png

docs/learning_twin/
└── LTAM_1C_RIG_ARCHITECTURE_CLOSURE.md
~~~

A temporary rig-proof Lottie may exist under a clearly non-production test path and should be removed or archived before release packaging if no longer required.

## 52. Closure record

The closure document must record the baseline commit, final LTAM-1C commit, rig version, master SVG hash, Glaxnimate source hash, layer-manifest hash, proof Lottie hash if retained, visual review result, export-compatibility result, platform-smoke result, known limitations, and exact next phase.

It must explicitly state:

~~~text
No CSP11 Learning Twin business logic or learner-facing runtime behavior changed during LTAM-1C.
~~~

## 53. Next phase

After LTAM-1C passes, proceed to:

# LTAM-2: Glaxnimate Idle Motion Proof

LTAM-2 will create the first production-quality motion:

~~~text
bind pose
↓
subtle breathing
↓
natural blink
↓
tiny head drift
↓
subtle gaze adjustment
↓
generic digital-node motion
↓
seamless return to bind pose
~~~

The first production Lottie asset should be twin_idle.json.

No other motion state should be built until the idle rig proves visually and technically sound.

## Frozen outcome

LTAM-1C establishes the character's animation skeleton without changing its learning brain.

~~~text
full-body Naveed master
        ↓
clean transform hierarchy
        ↓
stable pivots
        ↓
facial controls
        ↓
body controls
        ↓
FX anchors
        ↓
Lottie export proof
        ↓
rig frozen
        ↓
LTAM-2 animation begins
~~~

**LTAM-1C is the frozen rig-architecture contract.**
