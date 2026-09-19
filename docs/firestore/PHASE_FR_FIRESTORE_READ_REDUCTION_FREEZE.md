# CSP11 Phase FR — Firestore Read Reduction Freeze

**Status:** FROZEN FOR IMPLEMENTATION  
**Phase:** FR — Firestore Read Reduction  
**Working branch:** `phase-fr-firestore-read-reduction`  
**Base / frozen handoff:** `phase-l4-closed`  
**Base commit:** `56cf3031709ca2ff9da81d48d8ede47bb589ee51`  
**Date:** 2026-09-19

## 1. Handoff rule

Phase FR starts from the exact closed Phase L4 checkpoint above.

Phase L4A–L4P are frozen and closed. Phase FR must not invent L4Q, reopen L4, redesign LAB behavior, or weaken any frozen Phase L/L4 invariant.

The later documentation commit `95dc271aa05624fecdeccb4472000ae57adfa1f3` is documentation-only and is not the FR code base. It added only `docs/lab/PHASE_L4_CLOSURE.md` on top of the closed checkpoint.

## 2. Objective

Firestore remains the authoritative publishing database, but learner delivery must stop depending on broad reads of published question and StudyContent collections.

Phase FR converts learner delivery toward a manifest-driven, versioned, cache-first architecture.

The control-plane target is:

```text
Firestore manifest
      |
      v
version/checksum/package path
      |
      +--> matching local package -> use cache
      |
      +--> changed/missing package -> fetch immutable delivery package
```

Firestore remains authoritative for canonical/Admin data. Static published learner payloads move toward immutable versioned delivery packages.

## 3. Frozen scope boundary

Phase FR changes:

- learner content/question delivery
- caching behavior
- query scope
- Firestore read instrumentation
- manifest/version checks
- package delivery
- bounded readiness history queries
- read-budget architecture tests

Phase FR does not redesign:

- Phase L or L4 runtime semantics
- Decision LAB Story Gate behavior
- DQG quality rules
- M7 readiness algorithms
- Learning Twin reasoning
- unrelated UI
- broad multi-project Firebase architecture

A second Firebase project is not part of the immediate fix.

## 4. Confirmed FR0 baseline hotspots

Static inspection at `56cf3031709ca2ff9da81d48d8ede47bb589ee51` confirms:

### 4.1 Global learner question catalogue

`lib/services/cloud_question_repository.dart`

`loadPublished()` executes a Firestore query over all documents matching `status == published` with no learner-side scope, pagination, package version, or persistent question package cache.

### 4.2 Quiz startup read amplification

`lib/services/quiz_service.dart`

`_loadPublishedCatalog()` starts both:

```dart
_questionRepository.loadPublished();
_contentRepository.loadPublished();
```

The learner catalogue is then filtered locally by domain / competency / topic / subtopic.

This is the highest-priority confirmed read-amplification path.

### 4.3 Global published StudyContent read

`lib/services/study_content/cloud_content_repository.dart`

`loadPublished()` queries all published `contentVersions`.

### 4.4 Cloud-first StudyContent loader

`lib/services/study_content_loader.dart`

Student cache is primarily a fallback after cloud access. `loadPublishedContent()`, domain loads, content ID loads and competency loads attempt the cloud boundary first.

### 4.5 Study screen background revalidation

`lib/screens/courses/csp/study_content_screen.dart`

A RAM/session hit is rendered immediately, but `refreshStudyContent()` is still called in the background and can issue another Firestore competency read.

### 4.6 Progress authoritative refresh

`lib/services/student_progress_dashboard_service.dart`

`loadDashboard()` includes `StudyContentLoader().loadPublishedContent()`. Student learning progress and question progress are local, but the content side can trigger a global cloud read.

### 4.7 Exam Readiness historical reads

The following remote stores contain unbounded collection `.get()` paths:

- `daily_study_plan_repository.dart`
- `exam_study_plan_repository.dart`
- `readiness_snapshot_repository.dart`

These are lower priority than the global question/content catalogue but must be bounded later in FR10.

## 5. Positive baseline findings

The following existing boundaries should be preserved:

- learner study progress is primarily UID-scoped local persistence
- learner question progress is primarily local persistence
- session StudyContent RAM caching already exists
- persistent StudentContent cache already exists
- Progress can be built from local data once curriculum delivery stops forcing cloud reloads
- no primary learner path inspected showed a broad real-time `.snapshots()` listener as the main read problem

## 6. Implementation order

The frozen order is:

```text
FR0 Baseline
FR1 Read Instrumentation
FR2 Published Catalog Manifest
FR3 Question Package Builder
FR4 Remove Global Quiz Reads
FR5 Persistent Question Cache
FR6 Study Content Packages
FR7 Cache-First StudyContentLoader
FR8 Remove Navigation Revalidation
FR9 Progress Zero-Cloud Reads
FR10 Readiness Query Tightening
Architecture gates
Migration
Measurement
Closure
```

Do not skip directly to a second Firebase project.

## 7. Target published catalogue

Initial manifest target:

```text
publishedCatalog/current
```

Per competency it will eventually carry at least:

- contentVersion
- contentChecksum
- contentPackage
- questionVersion
- questionChecksum
- questionPackage
- publishedQuestionCount

The manifest should normally be read once per app session, with explicit TTL-based revalidation rather than screen-by-screen refresh.

## 8. Delivery package invariants

Published learner packages must be:

- immutable
- versioned
- competency scoped
- checksum verified
- learner safe
- generated only from publish-eligible authoritative records
- uploaded and verified before the manifest points to them

The manifest is updated last.

Rollback selects an older immutable package version rather than overwriting a package.

## 9. Read-budget targets

For published content/question delivery:

| Learner operation | Target |
|---|---:|
| Cold authenticated app start | <= 1 manifest read |
| Home open/revisit | 0 |
| Open previously cached competency | 0 |
| Reopen same competency | 0 |
| Additional quiz in same cached competency | 0 |
| Progress open | 0 |
| Domain progress open | 0 |
| Manifest TTL refresh | 1 |
| Unchanged content after manifest refresh | 0 package redownloads |
| Changed package | changed package only |
| Navigate within cached competency | 0 |
| Widget rebuild | 0 |

User-specific sync is outside these content/question figures.

## 10. Architecture guard target

A permanent test will prevent learner production code from reintroducing broad calls such as:

```dart
CloudQuestionRepository.loadPublished()
CloudContentRepository.loadPublished()
```

Admin authoring and package-generation code may retain authoritative broad reads when explicitly required.

## 11. FR0 baseline journeys

FR0 tracks:

- cold authenticated launch
- Home open
- Progress open
- domain progress open
- open D01 C01
- reopen D01 C01
- competency quiz
- subtopic quiz
- second quiz in the same competency
- Exam Readiness open
- Exam Readiness refresh

For each journey, Phase FR instrumentation will identify repository operation, collection/query scope, and returned document count where observable.

## 12. FR0 closure / NEXT ACTION

FR0 is closed only after:

1. exact base checkpoint is recorded
2. broad learner Firestore read paths are mapped
3. Phase FR plan and invariants are frozen
4. baseline journeys are recorded
5. a recovery point is created
6. FR1 instrumentation can begin without altering learner semantics

**NEXT ACTION:** FR1 — add development/test read instrumentation without changing read behavior.
