# CSP11 Phase M5.0 - Deterministic Progress Interpreter Foundation

## Status

CHECKPOINTED / PASS

## Purpose

Start the Adaptive Learning Coach with a pure deterministic interpreter that
turns the existing local `ProgressAnalyticsSnapshot` into one stable coaching
insight.

M5.0 does not place adaptive coaching on learner screens yet.

## Initial signal order

1. mastery acknowledgement
2. weak-domain remediation
3. study/practice imbalance
4. continue an active incomplete domain
5. general continue-learning guidance
6. start-learning guidance

## Evidence floor

Weak-domain accuracy is ignored until at least five answered questions exist in
that domain. This avoids unstable remediation advice from one or two attempts.

## Architecture

Input:
`ProgressAnalyticsSnapshot`

Output:
`LearningTwinProgressInsight`

The interpreter is:
- deterministic
- pure
- local
- testable
- independent of UI
- independent of Firebase

## M5.0 exclusions

No:
- Firebase reads
- SharedPreferences
- current-time reads
- randomness
- navigation
- learner-screen integration
- LLM
- voice/TTS/audio
- Exam Simulator integration

Future M5 slices may convert a progress insight into M3 candidate messages.
M3 remains the final authority for whether an intervention may be shown.
