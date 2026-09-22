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

### SM-2 — choreography
Synchronize Lottie, domain nodes, feature text and exit transition.

### SM-3 — personalization
Connect learner-safe local state such as resume position and today's plan. Do not introduce extra remote reads merely for startup decoration.

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
