# CSP11 Motion & Transition System

**Phase:** MOT  
**Branch:** `phase-mot-motion-system`  
**Baseline:** `phase-hap-closed` at `204e447809a87bf372565e22851115d3bf1969e8`  
**Backend rule:** MOT is a local UI system. Firebase and Supabase access are out of scope for implementation and validation.

## Objective

Create one restrained and accessible motion language for CSP11. Motion should explain navigation, selection, confirmation, consequences, and meaningful completion without delaying learning or owning business state.

## Frozen principle

> Motion explains what changed. It must never change business logic, trigger backend activity, recreate learner state, or exist only as decoration.

## MOT0 - Motion language

Semantic intents:

- `navigate`
- `reveal`
- `select`
- `confirm`
- `consequence`
- `celebrate`

Explicitly silent passive events:

- widget rebuild
- Firestore/Supabase synchronization
- background retry
- cache refresh
- analytics recalculation
- timer ticks
- passive progress recalculation

Checkpoint: `MOT0_MOTION_LANGUAGE_FROZEN`

## MOT1 - Central motion tokens

Create a central motion package under:

```text
lib/theme/motion/
    csp11_motion.dart
    csp11_motion_intent.dart
    csp11_motion_duration.dart
    csp11_motion_curve.dart
    csp11_motion_preferences.dart
```

Frozen V1 duration family:

- instant: 80 ms
- quick: 140 ms
- standard: 220 ms
- emphasized: 320 ms
- celebration: 520 ms

Screens should consume semantic motion tokens rather than inventing arbitrary durations and curves.

Checkpoint: `MOT1_TOKENS_GREEN`

## MOT2 - Reduced motion

Respect Flutter/OS reduced-motion state through `MediaQuery.disableAnimationsOf(context)`.

Reduced-motion rules:

- large slide/scale transforms collapse to short fades or instant state changes
- information remains fully understandable without motion
- motion is not required for navigation or control discovery
- theme and haptic preferences remain independent

Checkpoint: `MOT2_REDUCED_MOTION_SAFE`

## MOT3 - Reusable motion primitives

Create reusable widgets under:

```text
lib/widgets/motion/
    csp11_fade_in.dart
    csp11_slide_fade.dart
    csp11_state_switcher.dart
    csp11_pressable.dart
    csp11_completion_reveal.dart
```

Run 1 implements the first four primitives. Completion reveal is activated later when completion surfaces are migrated.

Checkpoint: `MOT3_PRIMITIVES_GREEN`

## MOT4 - Route transitions

Create a central route factory:

```text
lib/navigation/csp11_route.dart
```

Initial route families:

- `forward`
- `detail`
- `modal`
- `replacement`

Ordinary forward navigation uses a restrained fade plus small translation. Reduced-motion mode removes spatial movement.

Settings is the Run 1 pilot route.

Checkpoint: `MOT4_ROUTE_SYSTEM_GREEN`

## MOT5 - Bottom navigation

Preserve existing cached learner screens and their state.

Requirements:

- no screen recreation solely for animation
- active tab receives a small directional fade/translation
- inactive cached tabs remain mounted but non-interactive
- tab motion direction follows navigation order
- re-tapping the active tab does not replay transition
- existing HAP navigation feedback remains synchronized with the tab change
- theme switching must not reset the selected tab

Checkpoint: `MOT5_NAVIGATION_GREEN`

## MOT6 - Press interaction system

Create `Csp11Pressable` for future migration of eligible action cards and controls.

Frozen V1 interaction:

- press scale target approximately 0.985
- quick release
- disabled/reduced-motion states avoid unnecessary transforms
- press visuals never replace semantic button/InkWell accessibility

Run 1 builds and tests the primitive. Screen-by-screen adoption follows later phases.

Checkpoint: `MOT6_PRESS_SYSTEM_GREEN`

## MOT7-MOT10 - Home, Learn, Quiz and Results

Run 2 scope:

- restrained Home entrance hierarchy
- Learn/Domain/Competency/Subtopic spatial continuity
- Quiz answer state reveal
- question-to-question transition
- Quiz completion to Results transition
- no full Quiz scaffold recreation
- maintain Quiz state and HAP synchronization

## MOT11-MOT18 - LAB, Learning Twin and completion

Run 3 scope:

- LAB option selection
- accepted-decision lock
- Decision to Consequence transition
- Story Gate progression
- ending treatment
- Learning Twin message/avatar event transitions
- future Flashcards motion foundation only
- reusable completion reveal

LAB motion must follow deterministic engine state. Animation never invents, delays, or changes route outcomes.

## MOT19-MOT30 - Hardening and closure

Run 4 scope:

- loading/empty/error transitions
- theme transition cleanup
- haptic-motion synchronization audit
- duplicate animation prevention
- performance budget
- 60 fps physical-device check
- admin/debug Motion Diagnostics
- architecture enforcement
- reduced-motion regression matrix
- state-retention gate
- final Firebase-free validation and phase freeze

## Performance rules

Prefer:

- opacity
- transform
- small translation
- small scale

Use caution with:

- animated BackdropFilter blur
- large shadow animation
- full-screen AnimatedSize
- expensive layout-driven effects

Existing glass surfaces should generally remain visually static while their children move.

## State-retention rule

Motion must not reset:

- bottom-navigation selection
- cached tab state
- scroll position
- Quiz selection/question/score
- LAB session/current node/history/state mutations
- Learning Twin state
- Subtopic position
- theme preference

## Implementation runs

### MOT Run 1

MOT0-MOT6:

- freeze motion language
- central tokens
- reduced-motion policy
- reusable primitives
- route factory
- Settings route pilot
- state-preserving bottom-navigation transition
- press primitive
- local deterministic tests

### MOT Run 2

MOT7-MOT10:

- Home
- Learn hierarchy
- Quiz
- Results

### MOT Run 3

MOT11-MOT18:

- LAB
- Story Gates
- endings
- Learning Twin
- Flashcards future motion foundation
- completion reveal

### MOT Run 4

MOT19-MOT30:

- loading/error/theme transitions
- synchronization
- duplicate prevention
- diagnostics
- architecture enforcement
- performance/state retention
- final Android validation
- freeze/close

## Definition of done

MOT is complete only when:

- motion tokens are centralized
- reduced-motion behavior exists
- critical learner flows retain state across transitions
- no motion triggers backend access
- Quiz/LAB motion follows accepted state transitions
- animations do not replay from rebuilds
- diagnostics and architecture enforcement exist
- automated regressions pass
- Android physical-device motion validation is recorded
