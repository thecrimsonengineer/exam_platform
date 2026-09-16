# CSP11 Phase M5.1 - Progress Insight to M3 Candidate Bridge

## Status

CHECKPOINTED / PASS

## Purpose

Connect the deterministic M5.0 progress interpretation layer to the frozen M3
guidance contract without placing adaptive coaching on a learner screen yet.

Flow:

`ProgressAnalyticsSnapshot`
-> `LearningTwinProgressInterpreter`
-> `LearningTwinProgressInsight`
-> `LearningTwinProgressMessageBridge`
-> `LearningTwinMessage`
-> `LearningTwinDecisionService`

The M5 bridge creates a candidate. It does not decide whether that candidate may
be shown.

## Explicit mappings

Initial state mapping:

- start learning -> `recommend`
- continue learning -> `recommend`
- add practice -> `recommend`
- weak-domain remediation -> `remediate`
- mastery acknowledgement -> `celebrate`

Initial trigger mapping:

- start learning -> `recommendationAvailable`
- continue learning -> `recommendationAvailable`
- add practice -> `recommendationAvailable`
- weak-domain remediation -> `remediationOpportunity`
- mastery acknowledgement -> `milestoneReached`

## Target versus context scope

An insight domain ID identifies the recommendation target.

It must not automatically become the message's context-matching domain. A
global Progress surface may legitimately recommend Domain 03 while its current
M3 context is not inside Domain 03.

Therefore M5.1 keeps these concepts separate:

- recommendation target -> action `targetId`
- context constraint -> optional `scopeDomainId`

A future host must opt in explicitly when it wants the M3 candidate restricted
to a domain context.

## M3 authority remains frozen

Every M5.1 candidate still passes through `LearningTwinDecisionService`.

This preserves:
- timed-exam suppression
- context matching
- dismissal suppression
- shown-message suppression
- one unsolicited intervention per screen visit
- deterministic priority ordering

## Boundaries

M5.1 adds no:
- learner-screen integration
- Firebase
- SharedPreferences
- current-time reads
- randomness
- LLM
- voice/TTS/audio
- real Exam Simulator binding

The next M5 slice should choose and validate the first adaptive learner surface
before any UI integration is committed.
