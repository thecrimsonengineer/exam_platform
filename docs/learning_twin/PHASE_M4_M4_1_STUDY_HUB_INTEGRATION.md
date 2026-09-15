# CSP11 Phase M4.1 - Study Hub Learning Twin Integration

## Status

M4.1 is CHECKPOINTED / PASS after automated validation and human visual
review.

M4 remains IN PROGRESS for additional narrow core-learning integration.

## Integration scope

M4.1 introduces exactly one deterministic unsolicited Learning Twin
intervention on the CSP11 Study Hub.

The intervention is hosted on both existing Study Hub variants:

- `csp_study_hub_screen.dart`
- `csp_study_hub_screen_dark.dart`

Both screens use the same integration bridge:

`LearningTwinStudyHubGuidance`

No other learner screen is changed.

## Architecture

The flow is:

`Study Hub`
-> `LearningTwinStudyHubGuidance`
-> frozen M3 deterministic decision service
-> frozen M2 `LearningTwinCard`

The Study Hub does not directly decide whether guidance is eligible.

The integration bridge creates one visit-scoped `LearningTwinContext`, asks the
M3 decision service for an eligible message, records the shown message in
`LearningTwinSessionState`, and maps an approved decision to the M2 card.

## Guidance message

M4.1 uses one static, deterministic screen-visit message:

- ID: `csp-study-hub-welcome-v1`
- state: `welcome`
- trigger: `screenVisit`
- unsolicited: yes
- screen scope: `csp-study-hub`
- no navigation action

The message encourages the learner to select one domain and keep the study
session focused.

## Dismissal

The card exposes the M2 dismiss control.

Dismissal updates M3 session state and the decision service is evaluated again.
Because the message is dismissed, the decision layer returns no eligible
intervention and the card disappears.

Persistent cross-session dismissal and coaching-frequency settings remain M9
work. M4.1 does not introduce new persistence.

## One unsolicited intervention per visit

Only one M4.1 host exists on each Study Hub variant.

The M3 session state records the visit after the selected unsolicited message is
shown. The M3 decision service therefore remains the authority for the
one-unsolicited-intervention-per-visit rule.

## Theme and layout

The integration uses the frozen M2 `LearningTwinCard`, which derives its colors
and typography from the active theme.

The same bridge is inserted into both existing light and dark Study Hub
variants. It is an in-flow child of the existing scroll content and does not
overlay the bottom navigation or primary Study Hub controls.

## Deliberate exclusions

M4.1 does not:

- modify `lib/main.dart`
- modify bottom-navigation behavior
- add Firebase or Firestore
- read learner progress
- implement adaptive M5 recommendations
- integrate Practice or Quiz coaching
- integrate the Exam Simulator
- add persistent frequency settings
- add Studio authoring
- add analytics
- add animations
- add audio, voice or TTS
- introduce an LLM

## Exam boundary

M4.1 does not appear inside the Exam Simulator.

The M3 fail-closed timed-exam contract remains frozen. M7 will bind that
contract to the real Exam Simulator session state when the roadmap reaches M7.

## Validation gate

The installer validates:

- exact Phase M3 close branch, commit and tag
- clean working tree
- exact inspected Study Hub and M2/M3 baseline blobs
- exact integration target anchors
- payload SHA-256 integrity
- Dart formatting
- Flutter analyze
- focused M2/M3/M4 tests
- full Flutter regression suite
- `git diff --check`
- production web build using the normal application entry point
- exact final working-set integrity

## Human review before M4 close

After automated validation, review the real CSP11 Study Hub in light and dark
mode and confirm:

1. the Twin card does not dominate the Study Hub
2. the card does not obstruct navigation or the domain grid
3. dismissal feels natural
4. the placement works on Android-width layouts
5. no second unsolicited Twin intervention appears during the same Study Hub visit

Only after that review should M4 be closed or expanded.
