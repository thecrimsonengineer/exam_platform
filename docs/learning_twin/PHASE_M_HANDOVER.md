# CSP11 Phase M Learning Twin - Recovery Handover

## Status

This document is the authoritative recovery handover for Phase M of the CSP11 learning platform.

Phase M0 through M4 are CLOSED / PASS.

Phase M5 is IN PROGRESS.

The next implementation phase is M5 - Adaptive Learning Coach.

Do not rebuild M0 from memory. Do not replace the frozen architecture unless a later explicitly approved change records the reason.

## Repository anchors

Repository:
`thecrimsonengineer/exam_platform`

Production repository:
`C:\NAVEED\exam_platform`

Production branch:
`csp11-final-topic-subtopic-architecture`

Frozen production baseline before Phase M:
`815b25b5a19f2d8d6cc400b103121ba29d3098d2`

Baseline commit message:
`Optimize Android study content density`

Safety tag:
`phase-m-pre-learning-twin`

Phase M experimental worktree:
`C:\NAVEED\exam_platform_phase_m_spike`

Phase M experimental branch:
`phase-m-learning-twin-spike`

Frozen M0 code checkpoint:
`9123ca04df08495dcd36dba8be7bf5ac414d688e`

M0 commit message:
`Add isolated Learning Twin avatar maker spike`

M0 closure tag:
`phase-m0-closed`

The `phase-m0-closed` tag is intentionally created on the documentation freeze commit so that checking out the tag includes this handover, roadmap and validation record.

## Production safety state

The production branch remains separate from the Phase M experimental branch.

Do not merge the Phase M branch into production automatically.

The experimental branch started directly from the frozen production baseline.

The M0 code checkpoint is one commit after the frozen production baseline.

The production baseline must remain recoverable through:
- commit `815b25b5a19f2d8d6cc400b103121ba29d3098d2`
- tag `phase-m-pre-learning-twin`

## Phase M purpose

Phase M introduces a Learning Twin, a stylized digital Naveed that appears only where it has pedagogical value.

Working identity:
`Naveed ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¢ Learning Guide`

The Learning Twin is intended to:
- orient learners
- explain concepts
- highlight important or exam-relevant ideas
- coach based on progress
- recommend next actions
- interpret practice and quiz results
- encourage learners
- remain unobtrusive
- never leak answers

## Frozen behavior rules

These rules remain in force unless explicitly changed in a later approved Phase M checkpoint.

1. The Twin must not appear everywhere.
2. Maximum one unsolicited intervention per screen visit.
3. A frequency governor must prevent repetitive interventions.
4. Dismissal must be respected.
5. Future coaching frequency settings are Off, Low, Normal and High.
6. The Twin must not cover primary content or navigation.
7. Light and dark modes must have parity.
8. Mobile responsiveness is mandatory.
9. Accessibility is mandatory.
10. Reduced motion support is mandatory.
11. Static guidance should eventually travel with published StudyContent where appropriate.
12. Adaptive coaching initially uses deterministic rules, not an LLM.
13. Firebase traffic should remain low.
14. Visual identity should be bundled and versioned.
15. No sound or voice integration is approved for the current Phase M roadmap.

## Exam Simulator hard boundary

During an active timed Exam Simulator session, the Learning Twin must disappear at the decision layer.

The future `LearningTwinDecisionService` must return no intervention when an active timed exam is in progress.

Do not implement this merely by hiding a widget. The decision layer itself must suppress guidance.

Pre-exam and post-exam interaction are allowed.

No hints, coaching or answer-revealing assistance are permitted during an active timed exam.

## M0 package decision

Package:
`avatar_maker`

Frozen package version:
`1.8.0`

Use an exact dependency pin:
`avatar_maker: 1.8.0`

Do not change this to a caret constraint during the frozen M0/M1 authoring work without an explicit dependency review.

Reason:
the upstream package can release later 1.x versions, while the canonical Twin authoring process must be reproducible.

## M0 controller decision

Authoring uses:
`NonPersistentAvatarMakerController`

Every avatar_maker widget used by CSP11 authoring must receive an explicit non-persistent controller.

Do not rely on avatar_maker's provider fallback.

Do not introduce a root `AvatarMakerControllerProvider`.

Do not adopt Provider as the CSP11 application state architecture simply because avatar_maker depends on Provider transitively.

Provider is currently an implementation dependency of avatar_maker, not a CSP11 architectural decision.

## Persistence decision

The canonical Learning Twin is not a per-learner avatar.

Do not persist a separate Learning Twin appearance for each learner or device.

Do not use avatar_maker's persistent SharedPreferences controller for the canonical Twin.

The authoring controller is disposable.

## Runtime visual architecture

The intended architecture is:

`avatar_maker authoring`
-> `NonPersistentAvatarMakerController`
-> export JSON + SVG
-> freeze canonical assets
-> runtime renders bundled SVG with `flutter_svg`

The learner runtime should not need avatar_maker to construct the canonical Twin.

The learner runtime should not need an avatar controller.

The learner runtime should not need Provider for the Twin.

The learner runtime should not fetch the Twin from Firebase Storage or another network source.

## Canonical asset target

M1 closed with a frozen local Learning Twin asset family:

```text
assets/learning_twin/
  naveed_twin.svg
  naveed_twin_explain.svg
  naveed_twin_success.svg
  naveed_twin_fullbody.svg
  naveed_twin.json
  twin_manifest.json
```

The canonical visual identity is frozen and bundled locally.

M2 renders these assets through reusable presentation widgets and does not require avatar_maker in the learner runtime.

The M0 sample avatar remains non-canonical.
## SVG export constraint discovered in M0

avatar_maker's exported avatar SVG includes the primary avatar parts such as hair, facial hair, eyes, eyebrows, nose, mouth, outfit, skin and accessory.

Package-level custom cosmetic layers for:
- AvatarBackground
- AvatarEffect
- AvatarEffectColor

are not part of the same exported avatar SVG in the architecture inspected during M0.

Therefore the canonical Twin should keep these package cosmetic layers set to `None` when the goal is a single frozen SVG.

Future CSP11 UI may add its own rings, backgrounds, state indicators or effects around the canonical SVG.

## SVG renderer note

The M0 exported SVG can contain filter-related elements such as:
- `<filter>`
- `<feOffset>`
- `<feColorMatrix>`
- `<feMerge>`

During widget tests, flutter_svg printed non-fatal messages including unhandled SVG style/filter elements.

The tests still passed and the avatar rendered sufficiently for the M0 proof of concept.

Before M1 freezes the final canonical asset, visually inspect the exported SVG at the intended learner sizes. If necessary, sanitize or simplify the final SVG only through a controlled, validated step.

## M0 sample avatar only

The following configuration was produced during M0 as a proof of export. It is not the canonical Naveed Twin:

```json
{
  "HairStyle": "ShortFlat",
  "HairColor": "Black",
  "FacialHairType": "BeardLight",
  "FacialHairColor": "Black",
  "EyeType": "Happy",
  "EyebrowType": "DefaultNatural",
  "Nose": "Default",
  "MouthType": "Smile",
  "SkinColor": "Peach",
  "OutfitType": "BlazerSweater",
  "OutfitColor": "Black",
  "Accessory": "PrescriptionGlasses",
  "Background": "Transparent",
  "AvatarBackground": "None",
  "AvatarEffect": "None",
  "AvatarEffectColor": "None"
}
```

## Theme decision

Future Learning Twin widgets should derive colors and typography from:
- `Theme.of(context).colorScheme`
- `Theme.of(context).textTheme`

Do not create an independent global light/dark boolean for the Twin.

The existing learner shell already manages light/dark behavior.

## Firebase decision

M0 adds no Firebase dependency for the Twin.

Canonical visual identity should be bundled locally.

Do not use Firebase to fetch the canonical avatar on each session.

Later guidance content may use existing publishing architecture only when Phase M reaches the appropriate roadmap stage.

## Audio decision

Current Phase M has no audio integration.

Do not add:
- TTS
- audio playback
- speech recognition
- microphone permissions
- voice assets
- sound controls

M11 is optional future intelligent/conversational work. Voice is not automatically approved even if M11 is reached.

## M0 spike files

The frozen M0 code checkpoint added only:

```text
lib/spikes/learning_twin/avatar_maker_spike_main.dart
lib/spikes/learning_twin/avatar_maker_spike_screen.dart
pubspec.lock
pubspec.yaml
test/spikes/learning_twin/avatar_maker_spike_test.dart
```

M0 did not modify production:
- `lib/main.dart`
- authentication
- learner navigation
- Firebase configuration
- production theme architecture
- Android platform files
- Web platform files
- Windows platform files
- question bank
- study content
- progress services
- Exam Simulator behavior

## Existing learner data relevant to later phases

Later Phase M adaptive coaching can use existing learner progress structures, including detailed progress aggregation across:
Domain -> Competency -> Topic -> Subtopic

Existing learner question progress can also support later recommendations.

Potential later M5 outputs include:
- weak competency remediation
- next-best subtopic
- practice recommendations
- mastery acknowledgement
- study/practice imbalance
- domain readiness

Do not build M5 logic during M1.

## Proposed future domain types

These are roadmap candidates, not all required in M1:

```text
LearningTwinContext
LearningTwinMessage
LearningTwinTrigger
LearningTwinAction
LearningTwinState
LearningTwinDecisionService
LearningTwinProgressInterpreter
LearningTwinSessionState
LearningTwinRepository
```

## Proposed future UI types

These are roadmap candidates, not all required in M1:

```text
LearningTwinAvatar
LearningTwinBubble
LearningTwinCard
LearningTwinCompactTip
LearningTwinHero
LearningTwinCoachSheet
LearningTwinInlineBlock
LearningTwinCelebration
```

Semantic states under consideration:

```text
idle
welcome
explain
tip
important
warning
encourage
celebrate
remediate
recommend
checkpoint
exam_ready
result_review
```

## Git safety rules

Before every change:
`git status -sb`

Never use:
- `git add .`
- `git clean -fd`
- `git reset --hard`
- blind restoration from old archives
- force push

Stage exact paths only.

Use narrow checkpoints.

Validate the exact staged snapshot before every commit.

## Current Windows limitation

Windows build validation is environmentally blocked because Visual Studio with the Desktop development with C++ workload is not installed on the development machine.

This is not classified as an M0 code failure.

Do not change Phase M code to work around the missing Windows toolchain.

## NEXT ACTION

Begin M5.3 - Safe Adaptive Action Routing.

Work only in:
`C:\NAVEED\exam_platform_phase_m_spike`

Branch:
`phase-m-learning-twin-spike`

Frozen recovery point:
`phase-m4-closed`

M5.0, M5.1 and M5.2 are CHECKPOINTED / PASS.

M5.3 may expose a user-initiated action only when the selected M5/M3 message
already carries a supported Domain target.

Routing rules:
- the Learning Twin integration widget must not own Navigator logic
- the Progress host owns navigation
- Domain target IDs must resolve against the current Progress snapshot
- weak-domain review and continue-learning may open the canonical CSP11 Domain
  learning screen
- unsupported or missing action targets fail closed with no button
- one action tap is consumed for the mounted Progress visit
- no automatic navigation
- no Firebase added by the Twin
- no persistence
- no randomness
- no LLM
- no voice, TTS or audio

M3 remains the final authority for whether an adaptive candidate may be shown.

Do not merge the Phase M branch into production yet.
## New-chat recovery prompt

In a new ChatGPT chat, use this request:

```text
Inspect the GitHub repository thecrimsonengineer/exam_platform and work from branch phase-m-learning-twin-spike. Read docs/learning_twin/PHASE_M_HANDOVER.md, docs/learning_twin/PHASE_M_ROADMAP.md and docs/learning_twin/PHASE_M_M0_VALIDATION.md before proposing changes. Treat tag phase-m0-closed as the frozen Phase M0 recovery point. Continue from the NEXT ACTION only. Do not rebuild or redesign M0, do not merge to production, and preserve all frozen Phase M safety rules.
```

That prompt plus the repository documents is the supported recovery mechanism if conversation context is unavailable.
