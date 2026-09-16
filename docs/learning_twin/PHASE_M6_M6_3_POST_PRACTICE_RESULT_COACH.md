# CSP11 Phase M6.3 - Post-Practice / Result Coaching

## Status

IMPLEMENTED BY PATCH / HUMAN REVIEW REQUIRED

## Baseline

M6.2 checkpoint:

`696608acc1f992fbe92af4074483e397387f1bca`

M6.2 visual review was completed before that checkpoint.

Security S1 and S2 remain a separate uncommitted 12-path working set.

## Goal

Add deterministic Learning Twin coaching after a completed practice session.

The result coach interprets an aggregate sanitized result only. It does not
receive question-bank or answer-key payloads.

## Sanitized result contract

Allowed:

- practice mode
- question count
- score
- total question count
- incorrect count derived from aggregates
- accuracy / percentage derived from aggregates
- Domain ID when the practice session was legitimately scoped
- learner-selected competency / subtopic scope already carried by M6.2
- Weak Areas fallback flag

Forbidden:

- `Question` objects
- question text
- answer choices
- correct answers
- incorrect-question objects
- explanations
- references
- answer keys

`ResultScreen` may continue to own `incorrectQuestions` for the existing
Review Incorrect Answers flow. That list never enters the Learning Twin layer.

## Deterministic result bands

- 100%: `celebrate`
- 80% to 99%: `resultReview` with strong-result guidance
- 60% to 79%: `resultReview` with targeted review guidance
- below 60%: `remediate`

These bands are deterministic presentation rules for practice coaching. They
are not persisted mastery classifications.

## Weak Areas fallback protection

When Weak Areas used its M6.1 mixed-question fallback, result coaching says so
explicitly.

The result is treated as additional performance evidence. The Twin must not
claim that a particular Domain is weak when the evidence threshold was not
met.

## M3 governance

Post-practice guidance uses:

- `LearningTwinTrigger.practiceCompleted`
- `DeterministicLearningTwinDecisionService`
- existing dismiss semantics
- existing unsolicited-per-visit rule
- existing timed-exam fail-closed suppression

No random, clock-based, LLM, Firebase, or persistence behavior is added.

## Navigation and theme

The sanitized practice context is forwarded:

Practice launcher / Custom Quiz
→ `QuizScreen`
→ `ResultScreen`

The quiz captures its current route `ThemeData` before opening the result route
and explicitly reapplies it. This preserves Custom Quiz dark mode for result
coaching.

Retry Quiz preserves the same sanitized practice context so a retry can produce
valid result coaching again.

Review Incorrect Answers deliberately does **not** receive the original
practice context. It remains a review flow rather than masquerading as a new
Daily, Random, Weak Areas, or Custom practice session.

## Out of scope

M6.3 does not:

- add result persistence
- change mastery calculations
- change Weak Areas evidence thresholds
- add cross-visit Twin frequency persistence
- add Twin Firebase reads/writes
- add LLM behavior
- change Firestore rules
- change Firebase App Check
- change Security S1
- change Security S2
- integrate the real Exam Simulator
- add voice/audio
- merge to production

Human visual review is required before an M6.3 checkpoint.
