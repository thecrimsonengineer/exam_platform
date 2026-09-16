# CSP11 Phase M4.3 - Dark Twin Theme and Competency Polish

## Status

M4.3 is a narrow human-review repair slice for Phase M4.

It addresses issues observed during real dark-mode review after the M4.2
checkpoint. It does not expand the Learning Twin to any new learner surface.

## Fixes

1. Dark Study Hub Twin guidance receives `AppTheme.darkTheme` locally.
2. Dark Domain Twin guidance receives `AppTheme.darkTheme` locally.
3. Dark Competency Overview Twin guidance receives `AppTheme.darkTheme` locally.
4. `LearningTwinCard` remains theme-driven. It is not given an independent
   dark-mode flag.
5. Competency renderer bullet separators use the encoding-safe Dart escape
   `\u2022` instead of the corrupted `â€¢` sequence.
6. The dark competency renderer adopts the same
   `StudentLearningProgressSessionCache` path already used by the light
   renderer, avoiding an unnecessary full progress load on each dark
   competency visit.

## Architectural reason

The root `MaterialApp` remains light. Existing dark learner screens are pushed
deeper routes and use dark visual constants without automatically changing
`Theme.of(context)`. The M2 Twin card correctly derives its colors from
`Theme.of(context)`, so M4.3 supplies the existing CSP11 dark `ThemeData`
locally at each dark Twin host.

This preserves the frozen rule that Twin UI derives from theme context rather
than owning a separate global light/dark state.

## Deliberate exclusions

M4.3 does not add:
- new Twin surfaces
- adaptive progress interpretation
- M5 recommendations
- Firebase changes
- persistence changes
- Exam Simulator binding
- voice, TTS or audio
- an LLM

Subtopic pages remain free of automatic Twin guidance.
