# CSP11 Motion & Transition System - Run 1 Status

**Phase:** MOT  
**Branch:** `phase-mot-motion-system`  
**Run:** 1 of 4  
**Baseline:** `phase-hap-closed` at `204e447809a87bf372565e22851115d3bf1969e8`  
**Backend access:** None. Run 1 uses no Firebase or Supabase reads/writes.

## Implemented

### MOT0 - Motion language

Frozen semantic intents:

- navigate
- reveal
- select
- confirm
- consequence
- celebrate

Passive rebuilds, background synchronization, cache refresh, analytics recalculation, and timer ticks remain outside the motion language.

### MOT1 - Central tokens

Added the central motion package under:

```text
lib/theme/motion/
```

Frozen V1 durations:

- instant: 80 ms
- quick: 140 ms
- standard: 220 ms
- emphasized: 320 ms
- celebration: 520 ms

Shared curves are also centralized.

### MOT2 - Reduced motion

`Csp11MotionPreferences` reads `MediaQueryData.disableAnimations`.

Reduced-motion behavior removes unnecessary spatial transforms and collapses interaction animation durations where appropriate.

### MOT3 - Reusable primitives

Added:

```text
Csp11FadeIn
Csp11SlideFade
Csp11StateSwitcher
Csp11Pressable
```

These primitives consume the central motion tokens and reduced-motion policy.

### MOT4 - Route system

Added:

```text
lib/navigation/csp11_route.dart
```

Run 1 route families:

- forward
- detail
- modal
- replacement

Settings is the first production route migrated to `Csp11Route.forward`.

### MOT5 - Bottom navigation

Bottom-navigation content now receives a restrained directional fade/translation on real tab changes.

The existing lazy cached screen maps and `IndexedStack` are retained. Motion wraps the existing state instead of replacing tab screens.

Properties:

- screen cache preserved
- selected tab preserved
- re-tapping active tab remains silent
- existing HAP navigation feedback remains intact
- reduced-motion mode bypasses the spatial transition
- theme rebuilds do not replay tab motion automatically

### MOT6 - Press interaction foundation

Added `Csp11Pressable` with a frozen pressed scale of approximately `0.985`.

Reduced-motion mode removes the scale animation. Broad screen adoption is intentionally deferred to the later screen migration runs.

## Validation

Run 1 validation covers:

- motion duration tokens
- semantic intent vocabulary
- reduced-motion detection
- state switcher reduced-motion behavior
- pressable behavior
- Settings central route integration
- Settings central state-switcher integration
- cached `IndexedStack` retention
- route-family contract
- no Firebase/Supabase imports in the motion foundation
- existing Settings regressions
- frozen HAP service and architecture regressions
- Flutter analyzer

## Compatibility fix discovered during validation

The first Settings regression showed that a 220 ms shared switcher duration kept the outgoing light Settings variant alive longer than the existing immediate-toggle contract allowed.

Settings now uses the central `quick` token at 140 ms, preserving the existing interaction expectation without weakening the test.

## Run 2 handoff

MOT Run 2 remains scoped to:

- Home entrance hierarchy
- Learn/Domain/Competency/Subtopic transitions
- Quiz selection/reveal/question transitions
- Quiz completion to Results
- continued state-retention and reduced-motion gates
