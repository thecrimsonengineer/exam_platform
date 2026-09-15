# CSP11 Phase M Learning Twin - Frozen Roadmap

## Roadmap status

Phase M is an experimental but controlled development stream on:
`phase-m-learning-twin-spike`

M0 is CLOSED / PASS.

M1 is CLOSED / PASS.

M2 is CLOSED / PASS.

M3 is CLOSED / PASS.

M4 is IN PROGRESS.

The production branch remains separate until an explicit later integration decision.

## M0 - Architecture and package spike

Status:
CLOSED / PASS

Purpose:
Verify that avatar_maker can author a canonical Twin without forcing avatar state or package architecture into the learner runtime.

Frozen outcomes:
- `avatar_maker: 1.8.0`
- exact package pin
- explicit `NonPersistentAvatarMakerController`
- no root avatar provider
- no persistent avatar state
- in-memory JSON export
- in-memory SVG export
- separate alternate Flutter entry point
- no production navigation integration
- no Firebase integration
- no audio or voice integration
- learner runtime direction is bundled SVG rendered with flutter_svg

Frozen code checkpoint:
`9123ca04df08495dcd36dba8be7bf5ac414d688e`

Closure tag:
`phase-m0-closed`

## M1 - Naveed Twin Identity

Status:
CLOSED / PASS

Purpose:
Design, compare and explicitly approve the canonical Naveed Learning Twin identity.

M1.1:
Create a Twin Identity Studio within the isolated authoring area.

M1.2:
Create multiple candidate identities.

M1.3:
Preview candidates at real learner sizes and on light/dark surfaces.

M1.4:
Select one approved canonical identity.

M1.5:
Freeze:
- `assets/learning_twin/naveed_twin.svg`
- `assets/learning_twin/naveed_twin.json`
- `assets/learning_twin/twin_manifest.json`

M1 acceptance direction:
- recognizable enough to represent Naveed without requiring photorealism
- friendly and professional
- legible at small sizes
- transparent-background compatible
- stable SVG export
- no dependency on package cosmetic effect layers
- deterministic, versioned and hashable assets

## M2 - Twin UI System

Status:
CLOSED / PASS

Purpose:
Create reusable learner-facing Twin presentation components while keeping the visual system responsive and unobtrusive.

Candidate widgets:
- LearningTwinAvatar
- LearningTwinBubble
- LearningTwinCard
- LearningTwinCompactTip
- LearningTwinHero
- LearningTwinCoachSheet
- LearningTwinInlineBlock
- LearningTwinCelebration

Requirements:
- mobile responsive
- light/dark parity
- accessibility semantics
- reduced motion
- no primary-navigation obstruction
- reusable canonical SVG renderer

## M3 - Guidance Domain Model

Status:
CLOSED / PASS

Purpose:
Define deterministic data structures and decision contracts for guidance.

Candidate types:
- LearningTwinContext
- LearningTwinMessage
- LearningTwinTrigger
- LearningTwinAction
- LearningTwinState
- LearningTwinSessionState
- LearningTwinDecisionService
- LearningTwinRepository

Key rule:
UI presentation must not become the source of truth for whether guidance is allowed.

## M4 - Core Learning Integration

Status:
IN PROGRESS

Purpose:
Introduce carefully selected Learning Twin interventions in pedagogically useful learner surfaces.

Rules:
- do not show everywhere
- one unsolicited intervention maximum per screen visit
- no overlap with primary content/navigation
- dismissal respected
- deterministic triggers first

## M5 - Adaptive Learning Coach

Status:
PLANNED

Purpose:
Use existing learner progress and question-progress information to make deterministic study recommendations.

Possible outputs:
- weak competency remediation
- next-best subtopic
- practice recommendations
- mastery acknowledgement
- study/practice imbalance
- domain readiness

Do not introduce an LLM requirement in this phase.

## M6 - Practice and Quiz Coach

Status:
PLANNED

Purpose:
Support pre-practice, post-practice and result interpretation without leaking answers.

The coach may explain patterns after an attempt where appropriate.

The coach must not expose protected answers through hints or intervention logic.

## M7 - Exam Simulator Boundaries

Status:
PLANNED

Purpose:
Enforce exam-mode safety at the decision layer.

Hard rule:
When an active timed Exam Simulator session is running, `LearningTwinDecisionService` returns no intervention.

Pre-exam and post-exam interactions are allowed.

Do not rely only on hiding the Twin widget.

## M8 - Studio Authoring

Status:
PLANNED

Purpose:
Allow approved static Twin interventions to be authored and associated with published learning content.

avatar_maker usage remains restricted to Twin visual authoring/admin scope.

Do not spread avatar_maker imports into learner runtime code.

## M9 - Persistence, Frequency and Settings

Status:
PLANNED

Purpose:
Persist learner interaction preferences and frequency controls without persisting separate Twin appearances.

Future coaching frequency:
- Off
- Low
- Normal
- High

Requirements:
- dismissal respected
- repeat-message suppression
- frequency governor
- low local-storage complexity
- no per-device canonical-avatar customization

## M10 - Analytics and Quality Gate

Status:
PLANNED

Purpose:
Measure whether the Twin helps rather than distracts.

Potential quality checks:
- intervention frequency
- dismissals
- next-action engagement
- repeated-message prevention
- accessibility
- exam-boundary enforcement
- runtime architecture import boundaries
- Firebase/network traffic
- asset integrity

## M11 - Optional Intelligent / Conversational Twin

Status:
OPTIONAL FUTURE

Purpose:
Explore richer conversational capability only after deterministic coaching is stable and safe.

This phase does not automatically approve:
- voice
- TTS
- speech recognition
- microphone access
- audio playback

Any such capability requires a new explicit decision.

## Permanent architectural boundaries

1. Canonical identity is a single versioned Learning Twin, not a per-learner avatar.
2. avatar_maker is primarily an authoring tool.
3. Learner runtime renders frozen canonical assets.
4. No root avatar provider.
5. No visual-identity Firebase fetch.
6. No sound/voice in current roadmap implementation.
7. Timed Exam Simulator suppresses Twin decisions.
8. Accessibility and reduced motion are mandatory.
9. Frequency governance is mandatory.
10. Production integration happens only after explicit review and narrow commits.
