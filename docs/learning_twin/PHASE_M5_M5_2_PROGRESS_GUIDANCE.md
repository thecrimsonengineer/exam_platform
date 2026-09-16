# CSP11 Phase M5.2 - Progress Overview Adaptive Guidance

## Status

CHECKPOINTED / PASS

## Purpose

Introduce the first adaptive Learning Twin learner surface on the existing
Progress Analytics overview.

The Progress screen is the selected first adaptive host because it already owns
the local `ProgressAnalyticsSnapshot` that M5.0 interprets. M5.2 therefore
requires no additional Firebase read and no duplicate progress aggregation.

## Runtime flow

`ProgressAnalyticsSnapshot`
-> `DeterministicLearningTwinProgressInterpreter`
-> `LearningTwinProgressInsight`
-> `LearningTwinProgressMessageBridge`
-> `LearningTwinMessage`
-> `DeterministicLearningTwinDecisionService`
-> `LearningTwinCard`

The M3 decision service remains the final authority.

## Placement

One adaptive Twin card is placed immediately after the Progress hero and before
the KPI grid.

The Progress screen already installs the correct nested CSP11 light/dark
`ThemeData`, so the existing M2 card remains theme-driven.

## Visit stability

M5.2 interprets the snapshot available when the guidance host first mounts.

It deliberately does not replace the intervention during silent snapshot
revalidation on the same screen visit. This prevents a cached-to-authoritative
refresh from changing or repeating guidance while the learner is reading it.

A new Progress screen visit may produce a new deterministic recommendation.

## Action routing

M5.1 may attach a target action to a candidate.

M5.2 deliberately does not wire that action to navigation yet.

This keeps the first adaptive UI slice read-only and dismissible while
navigation semantics are reviewed separately.

## Frozen protections preserved

- maximum one unsolicited intervention per screen visit
- dismissal respected for the visit
- deterministic interpretation
- deterministic M3 decision
- timed-exam suppression remains in the decision contract
- no automatic Subtopic adaptive guidance
- no Firebase introduced by the Twin
- no persistence introduced
- no randomness
- no LLM
- no voice/TTS/audio
