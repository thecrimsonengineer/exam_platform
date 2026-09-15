# CSP11 Phase M4.2 - Additional Core Learning Surfaces

## Status

M4.2 is an additional controlled integration slice.

M4 remains IN PROGRESS until the M4.2 light/dark/mobile visual review is
accepted.

M4.1 Study Hub integration is treated as a visually approved checkpoint.

## Why these surfaces

M4.2 expands the Learning Twin along the active core learning path without
putting guidance on every page.

The selected surfaces are:

1. Domain overview
2. Competency content overview

The learner path therefore becomes:

Study Hub -> Domain -> Competency Overview -> Subtopic

The Twin appears on the first three orientation/decision surfaces but is
deliberately absent from every individual subtopic page.

This keeps the coach visible at useful transition points without turning the
learning experience into a stream of repeated interruptions.

## Domain integration

Light and dark Domain screens each host one `LearningTwinDomainGuidance`
instance after the domain hero and before quick actions.

Message:

- ID: `csp-domain-focus-v1`
- trigger: `screenVisit`
- state: `tip`
- title: `Work one learning area at a time`
- deterministic
- dismissible
- no navigation action
- no learner-progress interpretation

The context includes the current domain ID for future-safe scoping.

## Competency integration

Light and dark study-content renderers each host one
`LearningTwinCompetencyGuidance` instance after the competency overview card
and before the topic list.

Message:

- ID: `csp-competency-study-first-v1`
- trigger: `screenVisit`
- state: `explain`
- title: `Study first, then test recall`
- deterministic
- dismissible
- no navigation action
- no learner-progress interpretation

The context includes the current domain and competency IDs.

## Decision ownership

Both integrations use the frozen M3
`DeterministicLearningTwinDecisionService`.

Each bridge creates visit-scoped context and session state, asks M3 for an
eligible message, records the shown message, and re-evaluates through M3 after
dismissal.

The screens themselves do not decide message eligibility.

## Frequency restraint

M4.2 deliberately does not integrate automatic guidance into:

- `study_subtopic_screen.dart`
- `study_subtopic_screen_dark.dart`

That choice is intentional. Showing an unsolicited Twin message on every
subtopic would be too frequent and would work against the M4 rule to avoid
showing the Twin everywhere.

Persistent cross-session frequency governance remains M9.

## M4 boundaries preserved

M4.2 does not add:

- Firebase or Firestore
- SharedPreferences persistence
- adaptive progress interpretation
- weak-area recommendations
- next-best-content logic
- Practice or Quiz coaching
- Exam Simulator binding
- Studio authoring
- analytics
- voice, TTS or audio
- an LLM dependency

Adaptive use of existing progress remains M5.

## Validation gate

The installer validates:

- exact Phase M3 recovery tag
- a clean M4.1 checkpoint commit directly above M3
- exact M4.1 checkpoint commit subject and changed-path set
- exact untouched Git blobs for Domain and study-content renderer targets
- M4.1 structural signatures
- payload SHA-256 integrity
- exact insertion anchors
- Dart formatting
- Flutter analyze
- focused M1/M2/M3/M4 tests
- full Flutter regression suite
- `git diff --check`
- normal production `flutter build web`
- exact final working-set integrity

## Human review before the next checkpoint

Review the normal application in light and dark mode at Android width.

Confirm:

1. Domain guidance does not crowd the hero or quick actions.
2. Competency guidance does not obscure the overview or topic list.
3. Dismissal closes each surface cleanly.
4. Study Hub M4.1 remains visually unchanged.
5. Subtopic pages remain free of repeated automatic guidance.
6. The combined Study Hub -> Domain -> Competency journey feels helpful rather
   than repetitive.

After approval, M4.2 can be checkpointed. Then decide whether M4 has enough
core-learning coverage to close or whether one final narrow integration is
justified.
