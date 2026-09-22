# SM-4 — CSP11 Startup Accessibility and Performance Hardening

## Purpose

SM-4 hardens the startup experience so animation remains decorative rather than becoming an accessibility, performance or availability dependency.

It preserves the free Glaxnimate + Lottie + native Flutter stack frozen in SM-0 through SM-3.

## Motion policy

Implementation:

`lib/screens/startup/startup_motion_policy.dart`

Three deterministic rendering profiles are available.

### Full

- 4.8 second master choreography
- 34 particles
- 15 logical-pixel glass blur
- Lottie enabled
- ambient knowledge-network motion enabled

### Balanced

Selected when raster workload is high or the viewport is unusually narrow.

- 4.8 second master choreography
- 20 particles
- 8 logical-pixel glass blur
- Lottie enabled
- ambient knowledge-network motion enabled

The trigger is based on rendered pixel workload and viewport geometry rather than learner identity or remote device telemetry.

### Reduced

Selected when the platform requests disabled animations or reduced motion.

- 250 ms static handoff
- zero particles
- zero backdrop blur
- Lottie disabled
- ambient motion disabled
- no animated feature-card sequence
- CSP11 identity and safe learner summary remain readable

Both Flutter's disable-animation signal and the platform reduce-motion accessibility signal are honored.

## High contrast

When the platform requests high contrast:

- startup glass opacity increases
- borders become stronger
- primary feature text and icon contrast increases
- reduced-motion text remains high contrast

High contrast does not trigger any remote state or alternate asset.

## Lifecycle behavior

`Csp11StartupScreen` implements `WidgetsBindingObserver`.

When the app becomes inactive, hidden or paused:

- the startup animation controller stops without cancelling state

When the app resumes:

- the same controller continues from its existing progress if the overlay is still active

When the app detaches:

- animation work stops

The startup overlay never restarts from frame zero solely because of a lifecycle interruption.

## Fail-open behavior

Startup has three independent failure protections.

### Asset preflight

Before Lottie rendering, the bundled JSON is loaded locally and checked for the frozen SM-1 contract:

- width 512
- height 512
- 30 fps
- 144 frames

If the local asset is absent, malformed or violates the contract, the startup overlay is dismissed.

### Lottie runtime error handling

`Lottie.asset` uses an `errorBuilder`.

If Lottie itself reports a load/parser error after preflight, the overlay is dismissed on the next frame.

### Hard watchdog

The startup overlay has an absolute seven-second ceiling.

If any future controller, asset, lifecycle or rendering defect prevents normal completion, the watchdog removes the overlay and reveals the real app beneath it.

The watchdog does not bypass authentication. It only removes decorative startup UI.

## Rendering cost controls

- production Lottie remains local-only
- reduced mode never builds the Lottie widget
- reduced mode never builds particle or knowledge-network painters
- balanced mode lowers particle count from 34 to 20
- balanced mode lowers backdrop blur from 15 to 8
- zero-blur paths do not build a `BackdropFilter`
- static brand and Lottie regions are isolated from unrelated paint where useful
- animation controllers are stopped when the overlay exits
- the lifecycle observer and watchdog are removed/cancelled on dispose

Lottie render caching is intentionally not enabled in SM-4 because the startup sequence normally runs once per launch and render caching trades additional memory for cheaper repeat playback.

## Accessibility semantics

The visual startup sequence is exposed as one stable semantic container:

`CSP11 Learning System`

Rapidly changing decorative feature text is excluded from repeated semantic announcements.

The authenticated application remains underneath the overlay and becomes visible when startup exits.

## Test coverage

### Motion policy

`test/startup/startup_motion_policy_test.dart`

Validates:

- disable-animations selects reduced mode
- reduce-motion selects reduced mode
- high raster load selects balanced mode
- narrow viewport selects balanced mode
- ordinary workload retains full mode

### Runtime hardening

`test/startup/startup_screen_hardening_test.dart`

Validates:

- reduced motion uses a short static handoff
- missing Lottie asset fails open
- watchdog removes an overlong overlay
- lifecycle pause stops progress and resume continues startup

## Frozen safety rules

SM-4 must not:

- introduce a network animation asset
- add Firebase reads
- add Supabase reads
- extend startup because learner data is late
- bypass AuthGate or FR authorization
- trap a learner behind an animation error
- merge Home R into startup-motion
- add a paid animation dependency

## Acceptance criteria

- reduced-motion request produces no decorative motion
- high-contrast request improves startup legibility
- normal mode retains the SM-2 4.8 second choreography
- balanced mode materially reduces particle and blur workload
- asset preflight fails open
- Lottie runtime errors fail open
- watchdog provides an absolute exit ceiling
- backgrounded startup stops animation work
- resumed startup continues safely
- all startup tests pass
- strict startup analysis passes
- full repository analysis passes with existing info-level lint debt non-fatal and warnings/errors fatal
- `phase-home-r` remains isolated
