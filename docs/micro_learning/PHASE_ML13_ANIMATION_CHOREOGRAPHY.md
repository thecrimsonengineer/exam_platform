# CSP11 Phase ML-13 — MicroFact Animation Choreography

Status: CLOSED

Base recovery point: `phase-ml12-startup-microfact-card-closed`

Working branch: `phase-ml13-animation-choreography`

## Objective

Animate the already-approved ML-12 startup MicroFact surface inside the existing CSP11 startup timeline without adding time, navigation dependencies, content dependencies, backend reads, or independent animation controllers.

## Frozen boundaries

1. The startup controller remains the single choreography clock.
2. Full and balanced startup duration remain 4.8 seconds.
3. Reduced-motion startup remains 250 ms.
4. The seven-second watchdog remains unchanged.
5. MicroFact loading remains optional and cannot block handoff.
6. ML-13 must not alter MicroFact content, publication state, eligibility, selection, or repository behavior.
7. ML-13 must not add persistence or learner-state weighting.
8. Reduced motion must not receive an independent MicroFact animation.
9. No animation-completion callback may control startup dismissal.
10. ML-13 stops at choreography. ML-14 learner-state weighting is explicitly out of scope.

## Choreography contract

The MicroFact surface uses the existing normalized startup progress.

For full and balanced motion:

```text
frames 0–11    hidden / pre-entry state
frames 12–27   ease-out entrance
frames 28–109  stable reading window
frames 110–129 ease-in exit
frames 130–144 transparent
```

The card remains in the widget tree while transparent so late-loading and existing ML-12 render contracts stay deterministic.

### Full motion

Entrance:

- fade 0 → 1;
- translate vertically toward rest from 10 logical pixels;
- scale 0.985 → 1.

Exit:

- fade 1 → 0;
- translate upward up to 9 logical pixels;
- scale 1 → 1.008.

### Balanced motion

Balanced mode uses the same frame windows with smaller spatial excursions:

- entrance translation: 7 logical pixels;
- entrance scale depth: 0.008;
- exit translation: 6 logical pixels;
- exit scale lift: 0.004.

### Reduced motion

Reduced mode is static:

```text
opacity = 1
translation = 0
scale = 1
```

No MicroFact-specific animation is introduced.

## Implementation

Pure choreography function:

```text
lib/screens/startup/startup_micro_fact_motion.dart
```

Startup integration:

```text
lib/screens/startup/csp11_startup_screen.dart
```

The choreography function is deterministic and side-effect free.

It accepts only:

- current startup progress;
- existing `StartupMotionMode`.

It returns:

- opacity;
- vertical translation;
- scale;
- visibility metadata.

It owns no timer, controller, stream, repository, selector, or navigation state.

## Validation

ML-13 tests verify:

- reduced motion is always static;
- full motion follows pre-entry → entrance → hold → exit → transparent sequence;
- balanced motion has lower movement amplitude than full motion;
- progress is safely clamped;
- widget integration uses the existing startup controller;
- the card reaches the exit phase before the existing startup handoff;
- full startup still dismisses on its original clock;
- reduced startup still dismisses on its original 250-ms clock.

Regressions must also keep green:

- ML-12 MicroFact service/card/integration tests;
- ML-11 selector tests;
- ML-10 local repository tests;
- startup motion policy tests;
- startup timeline tests;
- startup hardening tests;
- startup release render smoke tests.

## ML-13 exit criteria

- [x] deterministic MicroFact choreography implemented;
- [x] no independent animation controller or timer added;
- [x] full mode entrance/hold/exit windows pass;
- [x] balanced mode uses reduced motion amplitude;
- [x] reduced mode remains static;
- [x] full startup duration remains 4.8 seconds;
- [x] reduced startup remains 250 ms;
- [x] seven-second watchdog remains unchanged;
- [x] ML-12 regression remains green;
- [x] ML-11 regression remains green;
- [x] ML-10 regression remains green;
- [x] production MicroFact files remain unchanged;
- [x] exact closing SHA is validated;
- [x] immutable ML-13 recovery branch is created.

## Stop boundary

Per the current execution instruction, work stops after ML-13 is closed.

ML-14 Learner-State Weighting must not be started in this execution.


## Closure evidence

- Normalized implementation commit: `4d90d1317b5642593802cc2acc298924e598c3f7`.
- Implementation validation run: `35954810900` — PASS.
- ML-13 choreography unit tests: PASS.
- ML-13 startup timing integration tests: PASS.
- ML-12 startup MicroFact regression: PASS.
- ML-11 selector regression: PASS.
- ML-10 local repository regression: PASS.
- Startup motion policy and timeline regressions: PASS.
- Startup watchdog/hardening and release render regressions: PASS.
- Production MicroFact files modified by ML-13: 0.
- Independent animation controllers introduced by ML-13: 0.
- Independent timers introduced by ML-13: 0.
- ML-14 was not started. Execution stops at the ML-13 closed recovery point.
