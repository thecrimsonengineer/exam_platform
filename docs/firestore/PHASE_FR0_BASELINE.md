# CSP11 Phase FR0 — Firestore Read Baseline

**Status:** BASELINE CAPTURED BY STATIC REPOSITORY INSPECTION  
**Branch:** `phase-fr-firestore-read-reduction`  
**Frozen code base:** `56cf3031709ca2ff9da81d48d8ede47bb589ee51`

## Documentation-only L4 run check

Requested run: `35427398807`

The triggering commit was:

`95dc271aa05624fecdeccb4472000ae57adfa1f3 — Document closed Phase L4 checkpoint`

Its parent is the exact closed code checkpoint `56cf3031709ca2ff9da81d48d8ede47bb589ee51`.

The commit changed exactly one file:

`docs/lab/PHASE_L4_CLOSURE.md`

with 127 additions and no code changes. Phase FR therefore branches from `56cf3031...`, not from the documentation commit.

At inspection time the requested validation run was still executing its full-repository/build tail, while all L4-specific steps through L4P and the exact frozen Phase L suite had already completed successfully. Its documentation-only classification is based on the triggering commit diff.

## Baseline read-path inventory

| Priority | Learner path | Repository operation | Firestore scope | Baseline concern |
|---|---|---|---|---|
| Critical | Quiz catalogue initialization | `CloudQuestionRepository.loadPublished()` | all `questions` where published | global question read |
| Critical | Quiz catalogue initialization | `CloudContentRepository.loadPublished()` | all published `contentVersions` | second global catalogue read |
| High | Published content catalogue | `StudyContentLoader.loadPublishedContent()` | delegates to global published content query | cloud-first |
| High | Study competency open | `loadStudyContent()` | competency published query | remote-first when no RAM hit |
| High | Study competency revisit | `refreshStudyContent()` | competency published query | background revalidation |
| High | Progress authoritative dashboard | `StudentProgressDashboardService.loadDashboard()` | can trigger global published content load | progress amplification |
| Medium | Domain published content | `loadPublishedDomain()` | published content in one domain | scoped but still cloud-first |
| Medium | Daily readiness history | `FirebaseDailyStudyPlanRemoteStore.loadPlans()` | all user's daily plans | unbounded history |
| Medium | Exam plans | `FirebaseExamStudyPlanRemoteStore.loadPlans()` | all user's exam plans | unbounded history |
| Medium | Readiness snapshots | `FirebaseReadinessSnapshotRemoteStore.loadAll()` | all user's readiness snapshots | unbounded collection |
| Low/positive | Learning progress | local SharedPreferences | no Firestore catalogue read | preserve |
| Low/positive | Question progress | local SharedPreferences | no Firestore catalogue read | preserve |

## Baseline code facts

### Question repository

`CloudQuestionRepository.loadPublished()`:

```text
questions
  -> where status == published
  -> get()
```

There is no limit or learner-scope filter.

### QuizService

`_loadPublishedCatalog()` performs two broad reads before local filtering:

```text
published questions
+
published StudyContent
-> merged local pool
-> domain / competency / topic / subtopic filtering
```

### StudyContent

Persistent and RAM caches already exist, but cloud access remains authoritative-first in the normal loader path.

### Progress

Core learner progress is local. The main Firestore exposure is curriculum acquisition when the authoritative dashboard path calls `loadPublishedContent()`.

## Runtime measurement note

FR0 intentionally does not alter production read behavior.

Exact billed Firestore document reads cannot be derived solely from source inspection. FR1 will add deterministic repository-level counters for development/tests, while Firebase billing/usage remains the authority for actual billed reads.

## FR0 result

FR0 confirms that the immediate optimization target is read amplification, not a lack of Firebase projects.

The first behavior-changing optimization must not occur until FR1 instrumentation establishes a measurable before/after boundary.
