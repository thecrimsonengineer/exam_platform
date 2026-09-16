# CSP11 Phase M6.1 - Direct Practice Modes

## Status

IN PROGRESS / HUMAN REVIEW REQUIRED

## Purpose

Make Daily Challenge, Random Quiz and Weak Areas genuinely different learner
flows while preserving Custom Quiz as the manual Domain -> Competency ->
Subtopic builder established in M6.0.

## Daily Challenge

- one tap from Practice Hub or Home
- no scope-selection screen
- up to 5 published questions
- deterministic for the learner's local calendar date
- reuses the M6.0 shared published-question catalogue

## Random Quiz

- one tap from Practice Hub or Home
- no scope-selection screen
- up to 10 unique published questions
- uses ordinary quiz randomization
- reuses the M6.0 shared published-question catalogue

## Weak Areas

Weak Areas reads UID-scoped local question progress only.

Evidence boundary:
- current published questions only
- at least 5 answered questions inside a domain
- mastery signal below 65%
- mastery uses the existing progress-dashboard semantics where a unique
  question counts as mastered once `everCorrect` is true

Selection order:
1. lowest mastery
2. more answered-question evidence
3. lower domain number

The focused session uses up to 10 currently published questions from the
selected weak domain.

If evidence is insufficient, if no domain is below the threshold, or if the
identified domain does not have enough currently published questions, Weak
Areas explicitly falls back to a mixed published quiz.

The fallback is never presented as a detected weak area.

## Custom Quiz

Custom Quiz remains the M6.0 manual builder with:
- Domain
- Competency
- Subtopic
- question count
- difficulty
- cognitive level

The M6.0 overflow protections remain unchanged.

## Home integration

The existing Home quick-practice cards use the same M6.1 direct launcher as
the Practice Hub. There is no second question-loading pipeline.

## Theme contract

The quick-launch loading and error surfaces explicitly use the app light or
dark theme supplied by their calling learner surface.

The existing QuizScreen remains theme-aware through the established quiz
theme system.

## Result / retry behavior

Direct modes use custom question lists. Quiz results now preserve that list
for Retry Quiz so a mixed-domain session does not accidentally retry Domain 0.

## Safety boundaries

M6.1 does not:
- widen Firestore rules
- read draft / review / validated-only questions
- add Learning Twin answer access
- expose correct-answer data to Learning Twin logic
- add voice or audio
- change Exam Simulator behavior
- modify Studio authoring
- push, tag or merge automatically

Learning Twin pre/post-practice coaching remains deferred to the later M6
coaching slices.
