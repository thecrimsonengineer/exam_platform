# CSP11 Motion & Transition System - Run 2 Status

**Phase:** MOT  
**Branch:** `phase-mot-motion-system`  
**Run:** 2 of 4  
**Baseline:** MOT Run 1 checkpoint `8b9ae79f3fd387c1f2c02620854746d18111023f`  
**Validation run:** `35496519059`  
**Backend access:** None. Run 2 uses no Firebase or Supabase reads/writes.

## Implemented

### MOT7 - Home entrance hierarchy

Both light and dark Home screens now use restrained staged reveals for the major learner-facing sections.

Frozen Run 2 entrance offsets:

- hero: immediate
- search: 30 ms
- continue learning: 60 ms
- primary actions: 90 ms
- quick practice: 120 ms
- progress intelligence: 150 ms

The existing `PageStorageKey<String>('csp11-home-scroll')` remains unchanged, so the motion layer does not replace the Home scroll identity.

The reveal primitive respects OS reduced-motion state and bypasses animation when `MediaQueryData.disableAnimations` is true.

### MOT8 - Learn hierarchy transitions

The Learn path now uses the central `Csp11Route` system instead of ad hoc `MaterialPageRoute` calls for the migrated hierarchy.

Covered paths include:

- Study Hub -> Domain
- Domain -> Study Content
- legacy Competency surface -> Study Content
- adjacent Subtopic replacement
- Home Continue Learning -> Domain or Study Content
- Home Study search result -> Study Content
- Domain -> Practice Quiz uses the central detail route

Both light and dark variants were migrated.

Existing deep-link identifiers and learner navigation targets remain unchanged. The dark Home search behavior was preserved exactly rather than silently changing its existing topic targeting.

### MOT9 - Quiz motion language

Quiz now changes the question body without recreating the surrounding scaffold.

Implemented:

- question card uses keyed `Csp11SlideFade`
- answer list uses keyed `Csp11SlideFade`
- new questions enter with a small horizontal offset
- submitted explanation reveals through `Csp11StaggeredReveal`
- reference follows with a 40 ms staged delay
- hierarchy-tag navigation uses `Csp11Route.detail`
- Quiz -> Results uses `Csp11Route.replacement`
- bottom `QuizActionBar` remains outside the question transition and therefore visually stable

Answer option selection now uses a subtle `AnimatedScale` target of `1.006`.

That selection animation:

- uses `Csp11MotionDuration.quick`
- uses the central motion curve
- collapses to no scale animation under reduced-motion mode
- does not replace the existing InkWell semantics
- leaves HAP answer-selection feedback intact

### MOT10 - Quiz completion and Results

Results now use a restrained completion entrance:

- hero: immediate
- Learning Twin post-practice guidance: 40 ms
- performance card: 80 ms
- review card: 120 ms
- action buttons: 150 ms

The result progress bar animates from zero to the final value using the central `celebration` duration.

Reduced-motion mode makes the progress update immediate.

Retry Quiz and Review Incorrect Answers now use `Csp11Route.replacement`, preserving the existing route replacement semantics while standardizing motion.

The score itself is not artificially counted from zero, avoiding unnecessary delay.

## New reusable primitive

Run 2 added:

```text
Csp11StaggeredReveal
```

It uses one `TweenAnimationBuilder` with an interval derived from `delay + duration`. No separate Timer is created.

This avoids lifecycle leakage and allows reduced motion to return the child directly.

## Regression compatibility

Run 2 updated legacy source-contract tests that previously required `MaterialPageRoute` syntax.

The tests now require the central route system while preserving the original destination guarantees.

## Validation

Run `35496519059` passed:

- canonical Dart formatting
- Flutter analyzer
- MOT Run 1 tests
- MOT Run 2 tests
- staggered reveal reduced-motion tests
- Home/Learn/Quiz/Results motion contracts
- Domain direct-study navigation regression
- Quiz dark/light tag-navigation regression
- Quiz UI regressions
- Settings regressions
- frozen HAP service regression
- frozen HAP architecture enforcement

## State-retention rules preserved

Run 2 does not intentionally reset:

- Home scroll identity
- selected bottom-navigation tab
- Quiz controller state
- current Quiz question
- selected answer
- Quiz score
- existing HAP mappings
- learner theme preference

## Run 3 handoff

MOT Run 3 remains scoped to:

- LAB option-selection motion
- accepted-decision lock state
- Decision -> Consequence transition
- Story Gate progression
- LAB ending treatment
- Learning Twin event-driven transitions
- future Flashcards motion foundation only
- reusable completion reveal
