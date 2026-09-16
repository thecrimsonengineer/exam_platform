# CSP11 Phase M6.0 - Practice Foundation

## Status

IN PROGRESS

## Purpose

M6.0 establishes the learner-safe and fast practice foundation before the
Learning Twin is added to quiz attempts and results.

## Problems addressed

1. The learner quiz builder initialized `QuizService` and then called the
   Admin-oriented `ContentRepositoryService.loadPackages()` path.
2. `loadPackages()` reads both draft and published content. Normal learners
   are intentionally not authorized to list draft content.
3. A new `QuizService` instance was created whenever the quiz builder opened,
   causing repeated Firebase reads.
4. Daily Challenge, Weak Areas and Random Quiz had no dedicated learner hub.
5. Settings occupied the fifth bottom-navigation slot.

## M6.0 architecture

The learner shell now prewarms one session-scoped published quiz catalogue.

The catalogue combines:
- published documents from `questions`
- published questions embedded inside published StudyContent subtopics

The two Firebase reads begin concurrently.

The learner quiz builder obtains its hierarchy from the same published
StudyContent already loaded by `QuizService`. It no longer calls the Admin
content package repository.

A dedicated `Practice` bottom-navigation destination becomes the fifth tab:

- Home
- Study
- Flashcards
- Progress
- Practice

Settings remains available from the Home profile/settings control and is
opened as a normal route.

## Practice hub

The new Practice hub exposes:
- Daily Challenge
- Weak Areas
- Random Quiz
- Custom Quiz

M6.0 keeps these modes on the existing protected quiz builder. Direct automatic
selection logic for Daily, Weak Areas and Random Quiz is the next controlled
M6 slice.

## Theme contract

The Practice hub derives colors from `Theme.of(context)` and `ColorScheme`.

When it opens the existing quiz builder it chooses:
- `CspPracticeScreen` in light mode
- `DarkCspPracticeScreen` in dark mode

No independent Practice theme state is introduced.

## Firebase authorization

M6.0 does not widen Firestore access.

Learners remain allowed to read only:
- questions with `status == published`
- contentVersions with `copyType == published` and `status == published`

Draft, review, validated-only and archived content remains protected.

A separate deployment script is supplied to deploy the repository's verified
`firestore.rules` to `csp11-exam-platform` if the live Firebase project is
behind the repository rules.

## Performance contract

- one shared `QuizService` for learner runtime
- in-flight initialization deduplication
- question and published-content reads start concurrently
- learner shell background prewarm
- subsequent quiz-builder openings reuse the current session catalogue
- explicit `refresh()` remains available for newly published content

## Deferred to the next M6 slices

- automatic Daily Challenge selection
- progress-derived Weak Areas selection
- instant Random Quiz generation
- pre-practice Learning Twin guidance
- post-practice / result interpretation
