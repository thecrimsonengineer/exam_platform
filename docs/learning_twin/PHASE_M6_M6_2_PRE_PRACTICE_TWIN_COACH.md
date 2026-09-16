# CSP11 Phase M6.2 - Pre-Practice Learning Twin Coach

## Status

IMPLEMENTED BY PATCH / HUMAN REVIEW REQUIRED

## Working-sequence note

M6.1 intentionally batched the Daily Challenge, Random Quiz, and Weak Areas
behaviors that had originally been listed as separate roadmap slices.

For the active implementation sequence, this package is named **M6.2** because
it is the next unimplemented functional slice after that batch. This does not
rewrite the historical roadmap or earlier frozen checkpoints.

## Goal

Add Learning Twin guidance at the start of learner practice without adding a
setup screen or another required tap.

Daily Challenge, Random Quiz, and Weak Areas remain one-tap practice modes.
Custom Quiz remains the manual builder.

## Security boundary

The Learning Twin receives only `LearningTwinPracticeContext`.

Allowed metadata:

- practice mode
- question count
- Domain number / canonical Domain ID when scoped
- competency ID when learner-selected
- subtopic ID when learner-selected
- whether Weak Areas used its explicit mixed-practice fallback

The Learning Twin does not receive:

- `Question` objects
- question text
- answer options
- correct answers
- explanations
- references
- protected answer-key payloads

The actual `QuizScreen` remains a host-owned child outside the Twin domain
logic.

## Frozen M3 governance

The pre-practice candidate passes through
`DeterministicLearningTwinDecisionService`.

This preserves:

- timed-exam suppression at the decision layer
- deterministic selection
- context matching
- dismiss semantics
- one unsolicited intervention per visit
- no random or clock-based Twin behavior

M6.2 does not add persistence or cross-visit frequency governance. That remains
a later Phase M responsibility.

## UX

The guidance appears on the same practice route above the quiz.

It is:

- non-blocking
- dismissible
- theme-aware through the existing Learning Twin card
- present in light and dark mode through ambient theme inheritance
- suppressed when the M3 timed-exam flag is active

There is no modal, no extra start button, and no automatic navigation.

## Mode behavior

### Daily Challenge

Provides a brief reasoning cue for the daily published-question set.

### Random Quiz

Frames the mixed set as fresh decision practice.

### Weak Areas

When evidence is sufficient, the Twin states the Domain focus.

When Weak Areas falls back, the Twin explicitly says there is not enough
reliable evidence yet and identifies the session as mixed practice.

### Custom Quiz

Uses only the learner-selected scope metadata and question count.

## Out of scope

M6.2 does not:

- interpret quiz results
- provide post-practice coaching
- access Firebase directly
- persist Twin frequency state
- introduce LLM behavior
- change Firestore rules
- change Firebase App Check
- change Android screen-capture protection
- add voice/audio
- merge to production

The next coaching slice is post-practice/result interpretation using a separate
sanitized result summary.
## M6.2A dark-theme correction

DarkCspPracticeScreen applies AppTheme.darkTheme below the root Navigator.
The Custom Quiz builder now captures that local ThemeData before navigation
and passes only the theme object to LearningTwinPracticeSessionHost.

The host has an optional ThemeData override. When supplied, it wraps both the
Learning Twin guidance and the host-owned quiz child in that same theme.
Direct practice modes do not supply an override and retain their existing
ambient-theme behavior.

No Learning Twin colors are hard-coded. No question or answer payload is added
to the Twin boundary.
