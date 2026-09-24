# CSP11 Phase ML-12 — Startup MicroFactCard

Status: IN PROGRESS

Base recovery point: `phase-ml11-intelligent-selector-closed`

Working branch: `phase-ml12-startup-microfact-card`

## Objective

Render one selected, published, current MicroFact inside the existing CSP11 startup overlay without adding network reads, persistence writes, navigation ownership, or any requirement that the learner finish reading before startup completes.

## Frozen boundaries

1. ML-10 remains the authoritative local repository and freshness gate.
2. ML-11 remains the authoritative deterministic selector.
3. ML-12 must not rewrite MicroFact content or production metadata.
4. ML-12 must not add Firebase, Supabase, HTTP, or other backend reads.
5. ML-12 must not write impression history.
6. ML-12 must not add learner-state weighting.
7. ML-12 must not extend the existing startup duration or watchdog.
8. Any repository, selector, or card failure must collapse to no card.
9. The secure child application must remain visible underneath the startup overlay.
10. Animation choreography remains ML-13.

## Runtime orchestration

Service:

```text
lib/services/micro_learning/startup_micro_fact_service.dart
```

The service:

- loads the ML-10 local repository;
- returns no fact when the bundle is invalid or empty;
- passes ML-11 context into the selector;
- catches MicroFact-only failures;
- never owns startup completion.

Until impression history is introduced in ML-15, the default rotation ordinal is calendar-day based and deterministic:

```text
UTC date -> integer day ordinal -> ML-11 selector
```

Tests and future layers may override the ordinal explicitly.

## Startup card

Widget:

```text
lib/screens/startup/startup_micro_fact_card.dart
```

The card:

- uses `shortVariant` when available;
- otherwise falls back to `displayText`;
- caps learner-facing copy at three lines;
- exposes a compact category label;
- is non-interactive inside the startup overlay;
- uses the existing dark startup visual language;
- introduces no independent timing or animation.

## Startup integration

`Csp11StartupScreen` starts MicroFact loading asynchronously in parallel with existing startup work.

It accepts optional injection points for:

- `StartupMicroFactService`;
- explicit rotation ordinal;
- recent MicroFact IDs;
- active assessment concept IDs.

The selected fact is optional state.

```text
fact loads -> render card
no fact    -> render normal startup
error      -> render normal startup
```

No MicroFact state participates in the startup watchdog or dismissal decision.

The existing startup ceiling remains seven seconds.

The existing full/balanced duration remains 4.8 seconds.

Reduced motion remains 250 ms.

## Phase boundary

ML-12 does not add custom MicroFact entrance/exit animation. That work belongs to ML-13.

ML-12 does not persist encounters or suppress repeats across launches. That work belongs to ML-15.

ML-12 does not weight selection from mastery/readiness state. That work belongs to ML-14.

## ML-12 exit criteria

- [ ] one selected MicroFact can render on startup;
- [ ] short variant is preferred when present;
- [ ] full display text is a safe fallback;
- [ ] narrow-screen card rendering has no overflow;
- [ ] real frozen ML-10 bundle can supply a startup fact;
- [ ] daily fallback ordinal is deterministic;
- [ ] no-fact state preserves normal startup;
- [ ] selected fact does not extend startup handoff;
- [ ] ML-11 selector regression remains green;
- [ ] ML-10 repository regression remains green;
- [ ] startup watchdog/hardening regression remains green;
- [ ] startup render regression remains green;
- [ ] production MicroFact files remain unchanged;
- [ ] exact closing SHA is validated;
- [ ] immutable ML-12 recovery branch is created.

## Next phase

ML-13 — Animation Choreography.

ML-13 may animate the MicroFact surface within the existing motion policy, but must never extend startup duration or create a reading-completion dependency.
