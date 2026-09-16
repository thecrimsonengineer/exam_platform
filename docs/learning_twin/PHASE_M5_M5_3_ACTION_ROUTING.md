# CSP11 Phase M5.3 - Safe Adaptive Action Routing

## Status

CHECKPOINTED / PASS

## Purpose

Add the first user-initiated action to adaptive Progress guidance without
allowing the Learning Twin integration layer to own navigation.

## Routing architecture

`LearningTwinProgressGuidance`
-> selected M3 message
-> `LearningTwinProgressActionPolicy`
-> optional Domain action binding
-> Progress host callback
-> canonical CSP11 Domain learning screen

The Progress host owns `Navigator`.

The Twin integration widget only emits a Domain ID.

## Supported actions

M5.3 allows:

- `openContent` with a non-empty Domain target
- `continueLearning` with a non-empty Domain target

The current M5 interpreter/bridge uses these for:

- weak-domain remediation -> Review domain
- active-domain continuation -> Continue learning

Unsupported actions fail closed with no button.

## Target resolution

The Progress host resolves the target ID against the current
`ProgressAnalyticsSnapshot.domains`.

If the target is not present in the current snapshot, navigation does not occur.

The resolved domain number is then used to open the canonical learner Domain
screen:

- light mode -> `DomainScreen`
- dark mode -> `DarkDomainScreen`

This keeps adaptive routing aligned with the existing CSP11 learner navigation
rather than creating a parallel route stack.

## Action consumption

The action button is consumed after one tap for the mounted Progress visit.

Returning from the Domain screen does not expose the same action again until a
new Progress guidance visit is created.

## Boundaries

M5.3 adds no:

- automatic navigation
- Firebase dependency inside the Twin
- SharedPreferences
- randomness
- current-time decision logic
- LLM
- voice/TTS/audio
- Exam Simulator integration
- automatic Subtopic guidance
