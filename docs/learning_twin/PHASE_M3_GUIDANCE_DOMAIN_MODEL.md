# CSP11 Phase M3 - Guidance Domain Model

## Status

M3 is CLOSED / PASS after successful package validation.

M3 defines deterministic, presentation-independent guidance contracts.

Production learner-screen integration remains deferred to M4.

## Domain catalog

M3 introduces:

- `LearningTwinContext`
- `LearningTwinMessage`
- `LearningTwinTrigger`
- `LearningTwinAction`
- `LearningTwinState`
- `LearningTwinSessionState`
- `LearningTwinDecision`
- `LearningTwinDecisionService`
- `DeterministicLearningTwinDecisionService`
- `LearningTwinRepository`

The barrel export is:

`lib/features/learning_twin/domain/learning_twin_domain.dart`

## Decision ownership

The decision layer, not the UI layer, determines whether guidance is eligible.

M2 widgets remain passive presentation components.

M3 does not import M2 UI components and does not invoke navigation, dialogs, bottom sheets or other presentation behavior.

## Deterministic selection

`DeterministicLearningTwinDecisionService`:

1. fails closed when an active timed exam is indicated
2. filters messages that do not match the current context
3. suppresses dismissed messages
4. suppresses previously shown messages unless repeat delivery is explicitly allowed
5. enforces a maximum of one unsolicited intervention per screen visit
6. permits learner-requested guidance independently of the unsolicited visit quota
7. selects the highest-priority eligible message
8. resolves equal priority by stable message ID ordering

The service uses no random selection and no current-time dependency.

## Session state

`LearningTwinSessionState` is immutable from the caller's perspective.

It tracks only deterministic in-session governance needed by the M3 contract:

- dismissed message IDs
- shown message IDs
- screen visits that already received an unsolicited intervention

Persistent frequency settings remain M9 work.

## Repository boundary

`LearningTwinRepository` is an interface only.

M3 does not add Firebase, Firestore, SharedPreferences or network persistence.

A later approved phase may implement the repository using the appropriate publishing architecture.

## Exam boundary

The permanent Phase M rule is represented in M3 by
`LearningTwinContext.isTimedExamActive`.

When true, the deterministic decision service returns no intervention.

M3 does not connect directly to the real Exam Simulator.

M7 remains responsible for binding the real timed-exam state into this contract and validating the end-to-end safety boundary.

## M3 exclusions

M3 does not:

- modify production navigation
- wire guidance into learner screens
- interpret progress
- recommend next-best learning content
- read Firebase
- persist frequency preferences
- author messages in Studio
- add analytics
- add audio, voice or TTS
- introduce an LLM dependency

Those remain later roadmap work.

## Validation gate

M3 validation covers:

- deterministic message scoping
- stable priority selection
- timed-exam fail-closed behavior
- dismissal suppression
- repeat-message suppression
- one unsolicited intervention per screen visit
- learner-requested guidance behavior
- immutable session-state updates
- domain import-boundary scanning
- no production entry-point integration
- full Flutter regression suite
- isolated M2 web build regression
- `git diff --check`

## Next phase

M4 - Core Learning Integration.

M4 may consume M2 presentation widgets and M3 decision contracts only through narrow, explicitly reviewed learner-surface integrations.
