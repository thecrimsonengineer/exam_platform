# SM-2 — CSP11 Startup Choreography

## Scope
SM-2 synchronizes the production Lottie master and all Flutter-owned motion to one authoritative 4.8 second startup clock.

The Lottie master remains:
- 512 × 512
- 30 fps
- 144 frames
- local asset only
- no learner-specific text

## Authoritative beat boundaries

The Flutter timeline mirrors the marker frames embedded in the Lottie file.

| Beat | Start frame | Start progress |
| --- | ---: | ---: |
| Ignite | 0 | 0.0000 |
| Learn | 18 | 0.1250 |
| Practice | 44 | 0.3056 |
| Decision LAB | 70 | 0.4861 |
| Remember | 96 | 0.6667 |
| Converge | 132 | 0.9167 |
| End | 144 | 1.0000 |

Implementation:
`lib/screens/startup/startup_timeline.dart`

## Single-clock rule

`Csp11StartupScreen` owns one `AnimationController` with a 4.8 second duration.

That controller now drives:
- Lottie frame progress
- ambient domain orbit
- knowledge-network geometry
- particle field
- brand entrance
- feature-card timing
- segmented startup rail
- final overlay dissolve

No independent decorative timer is permitted in SM-2.

## Choreography layers

### Ambient background
A dark CSP11 radial field remains behind the central animation. Accent colour changes by learning beat while keeping the background restrained enough to hand off cleanly to the existing glass UI.

### Knowledge field
Flutter `CustomPainter` owns the outer learner-system environment:
- seven-node domain orbit
- center-to-domain connections
- perimeter network links
- moving accent arc
- core pulse
- one beat-linked highlighted domain node

This is deliberately separate from the central feature artwork.

### Particle field
A deterministic particle field is generated from progress and particle index. It has no random runtime state and therefore remains repeatable across launches.

Particles move outward during the feature sequence and converge toward the core during the final beat.

### Central feature animation
The Glaxnimate/Lottie asset owns:
- ignition geometry
- opening book
- practice target
- LAB branching
- flashcards
- final convergence pulse

The Flutter layer does not redraw those feature motifs.

### Feature glass card
Each master beat has a synchronized Flutter-owned feature card:

- CSP11 — Your learning environment is coming online
- LEARN — Continue where you stopped
- PRACTICE — Turn knowledge into confident answers
- DECISION LAB — Make decisions and see their consequences
- REMEMBER — Strengthen key concepts with flashcards
- READY — Your learning continues

The card uses a glass blur, beat accent, icon, title and message. It cross-fades and lifts slightly at marker transitions.

### Segmented timeline
Six segments represent the six beats. Completed beats stay filled. The active beat fills according to local beat progress.

This replaces the generic linear loader from SM-0/SM-1.

## Exit transition
The overlay does not begin its exit until frame 132, the Lottie convergence marker.

Frames 132–144:
- particles move inward
- core pulse expands
- overlay scales outward by approximately 1.8%
- opacity eases to zero
- the already-initializing authenticated app is revealed beneath it

Authentication and learner authorization are never bypassed.

## Responsive behaviour
The Lottie centerpiece is constrained by the shortest screen dimension and capped at 390 logical pixels.

The feature glass card is capped at 430 logical pixels and receives horizontal safe padding.

## Tests and CI
SM-2 adds:
- `test/startup/startup_timeline_test.dart`
- marker-boundary tests
- beat-progress tests
- out-of-range clamping tests

The branch workflow validates:
- Dart formatting
- Lottie JSON contract
- startup tests
- full `flutter analyze`

## Separation rule
SM-2 remains exclusive to `phase-startup-motion`.

No commits from `phase-home-r` are merged or cherry-picked during this phase.
