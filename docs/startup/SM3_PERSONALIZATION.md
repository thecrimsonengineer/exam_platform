# SM-3 — CSP11 Startup Personalization

## Purpose

SM-3 personalizes the 4.8 second startup experience using learner-owned local state that already exists on the device.

It must not create a new Firestore read, Supabase read, remote refresh, analytics lookup or animation-network dependency.

## Identity boundary

Personalization starts only after `AuthGate` activates the verified learner Firebase UID through `LearnerLocalIdentity`.

The startup screen never persists a UID itself.

Admin, unauthenticated and unverified-user paths remain generic because `LearnerLocalIdentity.currentUserId` is not active for those paths.

## Local data sources

### Continue CSP

Source:

`StudentLearningPositionService(userIdOverride: userId).loadPosition()`

Storage:

UID-scoped SharedPreferences under the existing learning-position V2 namespace.

Startup uses:
- domain/competency resume code
- subtopic title when available
- competency title as fallback

Example:

`D04 · C01`

`Reliability and probability foundations`

### Today's Plan

Source:

`DailyStudyPlanRepository(userIdOverride: userId).loadLatestForDate(date, refreshRemote: false)`

The repository is created without a remote store.

The explicit `refreshRemote: false` rule is frozen for startup personalization.

Startup derives:
- remaining activity count
- remaining planned minutes
- completed activity count
- total activity count

Outstanding statuses are:
- planned
- started
- shortened

Completed, skipped, moved, replaced and unavailable blocks are not counted as remaining work.

## Fail-soft rule

Resume and plan loading are independent.

If either local source throws or contains unusable data:
- the other source may still personalize the startup
- the animation continues
- generic copy remains available
- authentication is not delayed
- the learner is never trapped on startup

A blank UID results in no source calls.

## Runtime trigger

The single SM-2 animation controller checks only the in-memory `LearnerLocalIdentity.currentUserId`.

Once a verified learner UID becomes available:
1. one personalization load is started
2. the UID is remembered only in the startup state for ownership verification
3. local caches are read once
4. the resulting snapshot is applied only if the same learner UID is still active

There is no polling timer and no repeated storage load.

The animation itself never waits for personalization.

## Personalized beat behavior

### Ignite

Generic:

`Your learning environment is coming online`

When local learner context exists:

`Welcome back. Your learning path is ready`

### Learn

Generic:

`Continue where you stopped`

When resume position exists:

`Continue D04 · C01`

The cached subtopic or competency title appears as a secondary detail line.

### Practice

Primary choreography remains:

`Turn knowledge into confident answers`

If today's local plan exists, the secondary line shows remaining workload, for example:

`3 activities · 45 min remaining`

### Decision LAB

Remains generic in SM-3. No LAB-specific progress is read during startup.

### Remember

Remains generic in SM-3. No flashcard repository is read during startup.

### Ready

If today's local plan exists, its local summary becomes the final primary message.

If resume state exists, the final detail may show:

`Resume point: D04 · C01`

Otherwise the generic fallback is:

`Your learning continues`

## Privacy and performance rules

- do not display email address
- do not display Firebase UID
- do not require learner name
- do not inspect another UID namespace
- do not refresh remote plan history
- do not add Firestore reads
- do not add Supabase reads
- do not delay `AuthGate`
- do not delay FR authorization
- do not extend the 4.8 second choreography to wait for data
- do not retain personalization after an ownership mismatch
- truncate long resume titles before display

## Files

Implementation:
- `lib/screens/startup/startup_personalization_service.dart`
- `lib/screens/startup/csp11_startup_screen.dart`

Tests:
- `test/startup/startup_personalization_service_test.dart`

## SM-3 acceptance criteria

- verified learner UID is the only personalization namespace
- Continue CSP can appear from local resume state
- Today's Plan can appear from local cached plan state
- zero remote refresh is requested
- generic startup remains complete when no local data exists
- local-source exceptions fail soft
- blank UID performs zero personalization source calls
- SM-2 master timing remains 4.8 seconds
- Home R remains isolated on its own branch


## Validation procedure

SM-3 must pass the existing startup-motion gate in this order:

1. startup Dart formatting
2. SM-1 Lottie JSON contract
3. all tests under `test/startup/`
4. strict analysis of `lib/main.dart`, `lib/screens/startup` and `test/startup`
5. full repository analysis with baseline info-level lint debt non-fatal and warnings/errors still fatal

The personalization service tests verify:
- resume and daily-plan data combine correctly
- completed plans do not invent remaining work
- local-source failures fall back safely
- blank learner identity performs zero source calls
