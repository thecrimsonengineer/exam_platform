# CSP11 Startup Motion — Free Stack Freeze

## Status
Foundation branch: `phase-startup-motion`

Base branch: `phase-home-r`

Base SHA: `bf01d8fd2776cc7e741f6811d1640105e4496f35`

## Frozen technology stack

The startup experience must remain subscription-free.

1. Glaxnimate for authored vector animation.
2. Lottie JSON as the export format.
3. Flutter `lottie` for runtime playback.
4. `flutter_animate` for UI choreography.
5. Native Flutter `CustomPainter`, animation controllers and shaders for dynamic learner-aware motion.

Rive is not required.

## Architectural rule

The startup animation is an overlay above `AuthGate`.

Authentication, learner authorization, Firebase initialization, Supabase initialization and FR online-access enforcement remain authoritative and must not be weakened, bypassed or delayed by the animation.

The authenticated destination is allowed to initialize beneath the overlay.

## Startup sequence

Target normal-launch duration: approximately 4.8 seconds.

1. Dark CSP11 glass background.
2. CSP11 knowledge core appears.
3. Seven domain nodes form around the core.
4. Glaxnimate/Lottie vector sequence runs in the centre.
5. Feature messages rotate:
   - Continue where you stopped
   - Follow today's learning plan
   - Practice intelligently
   - Make decisions in LAB
   - Remember with flashcards
6. Overlay dissolves into the already-loading authenticated destination.

## Glaxnimate asset contract

Primary exported animation:

`assets/startup/csp11_startup_master.json`

Development placeholder:

`assets/startup/csp11_glaxnimate_placeholder.json`

Recommended Glaxnimate document:
- 512 × 512 logical canvas
- 30 fps
- 3 to 5 second loopable central sequence
- no embedded raster imagery unless necessary
- keep text out of the Lottie file when the text must be personalized
- use vector paths, opacity, transform, scale and rotation first
- export as Lottie JSON

## Separation of responsibilities

Glaxnimate/Lottie owns:
- book opening
- flashcard rotation
- target formation
- LAB branch motif
- icon morphs
- decorative vector motion

Native Flutter owns:
- actual learner name
- current domain and competency
- today's plan count
- learning position
- readiness/progress values
- authorization state
- responsive layout
- final transition into Home

CustomPainter/shaders own:
- domain orbit
- particles
- glow/pulse
- knowledge network
- ambient background motion

## Performance rules

- Startup must never wait for remote animation assets.
- Production Lottie files are bundled locally.
- Prefer vector-only Lottie.
- Avoid very large path counts and excessive masks.
- Avoid continuous shader work after startup overlay exits.
- Dispose all animation controllers.
- Respect reduced-motion accessibility in a later hardening run.
- Animation failure must fall back to the authenticated app instead of blocking entry.

## Implementation runs

### SM-0 — foundation
- branch isolation
- dependencies
- startup asset path
- startup overlay
- native knowledge-core painter
- Lottie integration point
- architecture freeze

### SM-1 — Glaxnimate master artwork ✅ IMPLEMENTED
Production asset: `assets/startup/csp11_startup_master.json`

Frozen characteristics:
- 512 × 512 vector canvas
- 30 fps
- 144 frames / 4.8 seconds
- 25 vector layers
- six timeline markers: ignite, learn, practice, lab, remember, converge
- seven domain nodes
- Learn/book motif
- Practice/target motif
- LAB branching motif
- Remember/flashcard motif
- final convergence pulse
- no embedded text
- no remote assets
- obsolete placeholder removed

Validation is enforced by:
- `test/startup/csp11_startup_asset_contract_test.dart`
- `.github/workflows/startup_motion_validation.yml`

### SM-2 — choreography ✅ IMPLEMENTED

Implementation record:
`docs/startup/SM2_CHOREOGRAPHY.md`

Frozen characteristics:
- one 4.8 second master `AnimationController`
- Lottie playback is driven by the same master progress as Flutter motion
- exact beat boundaries mirror Lottie marker frames 0, 18, 44, 70, 96 and 132
- deterministic particle field
- seven-node ambient knowledge orbit
- center-to-domain and perimeter network links
- moving accent arc and core pulse
- beat-synchronized glass feature card
- six-segment startup timeline
- convergence begins at frame 132
- overlay exit completes at frame 144
- authentication and learner authorization continue underneath the overlay
- no independent decorative timer is used by the startup choreography
- no remote animation asset is introduced
- no `phase-home-r` work is merged into this branch

Validation:
- startup formatting gate passes
- SM-1 Lottie asset contract passes
- all `test/startup/` tests pass
- strict analysis of `lib/main.dart`, `lib/screens/startup` and `test/startup` passes
- full repository analysis passes with only pre-existing info-level lint debt treated as non-fatal
- warnings and errors remain fatal in the full repository analyzer gate

### SM-3 — personalization ✅ IMPLEMENTED

Implementation record:
`docs/startup/SM3_PERSONALIZATION.md`

Frozen characteristics:
- personalization begins only after `AuthGate` activates the verified learner UID
- startup does not persist or display the Firebase UID
- Continue CSP reads only the existing UID-scoped `StudentLearningPositionService` cache
- Today's Plan reads only the existing UID-scoped `DailyStudyPlanRepository` local cache
- daily-plan lookup explicitly uses `refreshRemote: false`
- the startup personalization repository is created without a remote store
- no Firestore read is introduced by startup personalization
- no Supabase read is introduced by startup personalization
- no network request is required for personalization
- the 4.8 second master choreography never waits for learner data
- resume context can render as `D04 · C01`
- cached subtopic title is preferred, with competency title as fallback
- Today's Plan can show remaining activity count and remaining minutes
- completed plans can show `Today's plan complete`
- local-source failures fail soft to generic startup copy
- blank learner UID performs zero personalization source calls
- admin, unauthenticated and unverified paths remain generic
- Decision LAB and Remember remain generic in SM-3 to avoid unnecessary repository reads
- Home R remains isolated on `phase-home-r`

Validation:
- final SM-3 freeze SHA: `6c33111c61cbdb8d9880a5b4318d8647788e02c3`
- exact-SHA validation Run 22 passed on that freeze commit
- all `test/startup/` tests pass
- strict startup analysis passes
- full repository analysis passes with baseline info-only lint debt non-fatal and warnings/errors fatal

### SM-4 — accessibility and performance
Reduced motion, low-end device behavior, frame timing, memory and startup validation.

### SM-5 — platform validation
Android, web and Windows. Extend to iOS when the iOS target is active.

## Acceptance criteria

- no paid animation service
- no Rive dependency
- no authentication bypass
- no startup network dependency for animation
- animation cannot trap the learner
- Home redesign remains independently mergeable
- production asset can be replaced by exporting a new Glaxnimate Lottie JSON without rewriting startup architecture


## Parallel branch isolation rule

`phase-home-r` and `phase-startup-motion` are active parallel workstreams.

Until an explicit integration step:
- do not merge `phase-home-r` into `phase-startup-motion`
- do not merge `phase-startup-motion` into `phase-home-r`
- do not cherry-pick feature commits between them
- each branch must remain independently runnable and testable
- Home work continues only on `phase-home-r`
- startup-motion work continues only on `phase-startup-motion`
- integration happens only after either workstream reaches a stable closure checkpoint
- the integration branch will resolve shared-file changes deliberately, especially `lib/main.dart` and `pubspec.yaml`
- neither branch is considered the integration source of truth until that explicit integration checkpoint
