# CSP11 Phase FR Final Freeze
## Free-Tier Supabase Migration, Fast Online-Only Learner Delivery

**Status:** FINAL PLAN FROZEN  
**Working branch:** `phase-fr-firestore-read-reduction`  
**Frozen source checkpoint:** `phase-l4-closed`  
**Frozen source SHA:** `56cf3031709ca2ff9da81d48d8ede47bb589ee51`  
**FR0 recovery branch:** `phase-fr0-baseline`  
**Date:** 2026-09-19

## 1. Governing rule

Phase FR begins from the closed Phase L4 checkpoint. Phase L4A-L4P are frozen and closed.

Phase FR must not invent L4Q, reopen L4, redesign deterministic LAB routing, weaken Story Gate invariants, change published LAB immutability, weaken DQG300-LAB, or permit Learning Twin evidence to affect authored story truth.

Phase FR replaces expensive learner-side Firestore delivery with a free-tier-aware, fast, online-only Supabase delivery architecture while preserving frozen CSP11 behavior.

## 2. Final architecture

```text
                         CSP11
                           |
                  INTERNET ACCESS GATE
                           |
                     Firebase Auth
                           |
                     Firebase JWT
                           |
                           v
                       SUPABASE
                authorization + RLS
                           |
             +-------------+-------------+
             |                           |
             v                           v
        PostgreSQL                  Supabase Storage
             |                           |
      canonical data              immutable packages
      learner state               content/question/LAB
      progress                     flashcard payloads
      readiness
      attempts
             |                           |
             +-------------+-------------+
                           |
                           v
                 ONLINE-AUTHORIZED
                  PERFORMANCE CACHE
                           |
                           v
                     LEARNER UI
```

Firebase remains the identity and selected free application-services layer. Supabase becomes the primary CSP11 data platform. The learner device may cache protected content for speed, but that cache must never become an offline learning repository.

## 3. Platform responsibility

| Requirement | Platform |
|---|---|
| User authentication / existing UID / Google sign-in | Firebase Auth |
| Analytics / Crashlytics / FCM | Firebase |
| App integrity | Firebase App Check where applicable |
| Existing Firestore data | Temporary migration source |
| Questions / StudyContent / lifecycle | Supabase PostgreSQL |
| Learner progress / attempts / readiness / plans | Supabase PostgreSQL |
| Learning Twin data/evidence / LAB metadata | Supabase PostgreSQL |
| Published content/question/LAB/flashcard packages | Supabase Storage |
| Fast learner cache | Device, online-authorized only |
| Offline protected learner access | Forbidden |
| Realtime | Only genuinely live future features |

Do not create a second Google account, second Firebase project, or another backend provider at this stage.

## 4. Free-tier invariant

CSP11 is engineered around Firebase Free + Supabase Free.

Minimize Firestore reads/writes, Supabase database calls, Supabase egress, package re-downloads, Realtime connections, Edge Function calls, large responses and unbounded history queries.

The strategy is:

```text
small indexed queries
+ immutable packages
+ compression
+ version checks
+ bounded cache
+ local computation
```

Do not solve quota pressure by sharding across free accounts.

## 5. Strict online-only learner invariant

Protected learner material must never be rendered unless current internet-backed authorization succeeds.

Protected material includes StudyContent, questions, explanations, references, flashcards, LAB content, practice content and protected readiness material.

Required state:

```text
internet reachable
+ valid Firebase identity
+ Supabase authorization successful
= ONLINE_AUTHORIZED
```

Anything else blocks protected content.

## 6. Online-authorized performance cache

The cache is not an offline repository.

Correct order:

```text
verify online authorization
-> unlock authorized cache
-> render
```

Forbidden order:

```text
load/render cache
-> check internet later
```

Caches are Firebase-UID scoped. Logout, user switch, invalid authorization or confirmed network loss locks protected cache access.

## 7. Network-loss behavior

Use a short reconnect debounce for Wi-Fi/mobile handover. If backend authorization remains unavailable after the reconnect window, lock protected learner content.

On app resume from background, revalidate online authorization before protected content becomes accessible again.

Extended offline study is forbidden.

## 8. Learner performance invariant

CSP11 should feel local while remaining online-only.

```text
online authorization
-> tiny version lookup
-> cached version current?
   yes: use authorized cache
   no: fetch changed package only
-> render
```

Unchanged packages must not redownload. Ordinary widget rebuilds must not trigger backend calls.

## 9. Supabase region

Choose and freeze the production region before production migration. For the current India-focused learner population, evaluate `ap-south-1` first.

## 10. Database versus Storage

PostgreSQL stores small structured data: versions, checksums, paths, sizes, counts, learner state, attempts, readiness and ownership metadata.

Supabase Storage serves larger immutable StudyContent, question, LAB and flashcard packages.

Do not repeatedly send large curriculum/question JSON through PostgreSQL.

## 11. Published catalogue

Use PostgreSQL `published_catalog` rather than the old Firestore manifest plan.

Suggested fields:

- competency_id
- content_version
- content_checksum
- content_object_path
- content_size_bytes
- question_version
- question_checksum
- question_object_path
- question_size_bytes
- published_question_count
- published_at
- active

Learner lookups are competency scoped.

## 12. Canonical lifecycle

Supabase PostgreSQL becomes the canonical content/question source only after migration.

The existing lifecycle remains:

```text
draft -> review -> validated -> published
```

Existing DQG rules remain unchanged.

## 13. Immutable package publishing

```text
canonical published records
-> lifecycle/DQG validation
-> deterministic serialization
-> remove duplication
-> gzip
-> SHA-256
-> immutable upload
-> verify package
-> update published_catalog LAST
```

Examples:

```text
content/d01_c01/v5.json.gz
questions/d01_c01/v14.json.gz
lab/<lab_id>/v3.json.gz
flashcards/d01_c01/v2.json.gz
```

Never overwrite a published version. Rollback points the catalogue to a known-good immutable version.

## 14. Quiz delivery

Learner-side global question catalogue loading must disappear.

```text
request D01 C01
-> online authorization
-> d01_c01 catalogue row
-> authorized cached version?
-> use cache or fetch changed package
-> filter/randomize locally
-> quiz
```

Competency/topic/subtopic/practice/Ultra Hard quizzes in the same competency reuse the same authorized package.

## 15. StudyContent delivery

Use the same versioned package model. Topic/subtopic navigation is local while current online authorization remains valid. Reopening unchanged content must not redownload or perform a broad database query.

## 16. Compression and egress

All large text packages are normalized/minified and gzip-compressed. Record package size and later enforce evidence-based package-size gates.

## 17. Bounded LRU cache

Use a byte-bounded LRU cache. Do not store the complete CSP11 bank permanently. Set limits from measured compressed package sizes.

## 18. Controlled prefetch

Prefetch only while online-authorized, under suitable network conditions, within cache budget, and for likely next content. Never prefetch all domains/question banks.

## 19. Home and Progress

Home/Progress must not load all content/questions. Use compact learner summary state where useful and render from authorized local state with bounded refresh.

## 20. Exam Readiness

Preserve M7 calculation logic. Migrate persistence gradually. Bound history queries, e.g. active plan `LIMIT 1`, recent history `LIMIT 30`, older history via cursors.

## 21. PostgreSQL performance

Candidate indexes include:

- `published_catalog(competency_id)`
- `questions(competency_id, status)`
- `questions(competency_id, subtopic_id, status)`
- `learner_progress(firebase_uid, competency_id)`
- `quiz_attempts(firebase_uid, created_at)`
- `readiness_snapshots(firebase_uid, competency_id)`
- `daily_study_plans(firebase_uid, study_date)`
- `exam_plans(firebase_uid, active)`

Validate with query plans and Supabase performance advisors.

## 22. RLS

RLS is mandatory on exposed tables.

Learners may read learner-approved published data but cannot mutate canonical content. User-owned rows are accessible only to their owner. Admin authorization uses trusted claims. Never use user-editable metadata for authorization.

## 23. Firebase-to-Supabase Auth bridge

Keep Firebase Auth. Configure Supabase third-party Firebase authentication. Flutter supplies the Firebase ID token to Supabase.

Verify the required authenticated-role/custom-claim behavior for existing users, new users, refresh, logout and account switching before learner cutover.

## 24. Migration principle

```text
Firestore authoritative
-> copy to Supabase
-> parity verification
-> shadow reads
-> Supabase primary
-> temporary controlled fallback
-> remove learner Firestore path
```

Dual write, if used, is temporary. The final architecture has one authoritative data platform.

## 25. Realtime policy

Normal Home, StudyContent, Quiz, Progress, Readiness, LAB and Flashcards do not require Supabase Realtime. Realtime is reserved for genuinely live future features.

## 26. Write optimization

Do not write on scroll, passive reading or ordinary navigation. Aggregate local activity and sync meaningful checkpoints. Important completion events may sync immediately.

## 27. Performance budgets

| Operation | Target |
|---|---:|
| App shell | < 500 ms where device permits |
| Cached Home after authorization | < 500 ms |
| Cached competency | < 300 ms |
| Topic/subtopic navigation | < 150 ms |
| Cached quiz startup | < 300 ms |
| Progress local rendering | < 500 ms |
| Normal access/version lookup | target < 500 ms |
| Reopen unchanged competency | 0 package downloads |
| Second quiz same competency | 0 package downloads |
| Widget rebuild | 0 backend queries |

These are engineering budgets, not universal network guarantees.

## 28. Offline acceptance

Mandatory outcomes:

| Scenario | Required result |
|---|---|
| Launch offline | protected data unavailable |
| Cached StudyContent/questions/LAB/flashcards + offline | unavailable |
| Internet + valid authorization | access permitted |
| Invalid Firebase auth or Supabase rejection | block |
| Confirmed network loss | protected content locks |
| Resume | revalidate first |
| Logout | immediately lock |
| Account switch | prior user's cache inaccessible |
| Internet restored | revalidate then restore |

Permanent rule: protected data must never load/render before Online Access Gate = ONLINE_AUTHORIZED.

## 29. Telemetry

Development/test telemetry will measure online gate, catalogue query, cache lookup, package download/decode, quiz start, Home/Progress render/sync, package bytes, cache hits and misses without becoming a heavy backend workload.

# 30. Implementation roadmap

## FR0 — Existing Firestore Baseline
**COMPLETE.** Preserve FR0 history and `phase-fr0-baseline`.

## FR1 — Measurement and CI Stabilization
**CURRENT.**

1. Canonically format new read-audit files.
2. Repair FR formatting gate.
3. Run analyze.
4. Run FR1 tests.
5. Preserve frozen L4 learner/quality/engine suites.
6. Run full repository regression.
7. Fix L4 workflow formatter staging omission only as workflow hygiene.
8. Freeze FR1.

No production query optimization before FR1 is green.

## FR2 — Supabase Foundation

1. Confirm/create one Supabase Free project.
2. Select/freeze region.
3. Add/pin `supabase_flutter`.
4. Add config abstraction.
5. Use project URL + publishable key only in Flutter.
6. Never expose secret/service-role keys.
7. Configure Firebase third-party Auth.
8. Supply Firebase ID token.
9. Implement authenticated connectivity test.
10. Implement Online Access Gate skeleton.
11. Verify role-claim strategy.
12. Add auth/connectivity tests.
13. Run security checks.
14. Migrate no production data yet.
15. Freeze FR2.

## FR3 — PostgreSQL Schema + RLS + Query Design

Design published catalogue, content/questions, learner profiles/progress/summary, attempts, readiness/plans, LAB attempts and Learning Twin evidence. Add PK/FK/lifecycle constraints, indexes, RLS, Firebase UID ownership, admin authorization, query-plan tests and advisor checks. Freeze schema before data migration.

## FR4 — Firestore-to-Supabase Migration Tooling

Build repeatable deterministic normalization/upsert/count/ID/checksum/duplicate/failure/unmapped verification.

## FR5 — Shadow Data Parity

Copy canonical production content/questions to Supabase without learner cutover. Require complete structural and learner-visible parity.

## FR6 — Published Catalogue

Implement competency-scoped `published_catalog` with package versions, checksums, sizes, paths, counts and publication metadata.

## FR7 — Supabase Storage Publishing Pipeline

Build private immutable package delivery with deterministic builders, compression, checksums, upload verification, catalogue-last update, rollback and package-size measurement.

## FR8 — Online-Authorized Cache Security

Implement OnlineAccessGate, auth state controller, UID cache, unlock boundary, LRU eviction, network-loss lock, resume revalidation and logout/account-switch lock. Add offline-blocking tests.

## FR9 — Question Delivery Cutover

Remove learner global `CloudQuestionRepository.loadPublished()`. Make QuizService competency-scoped/package-backed. Add architecture guards.

## FR10 — StudyContent Delivery Cutover

Remove learner global/cloud-first StudyContent delivery and unconditional navigation revalidation. Use authorization + catalogue version + authorized cache.

## FR11 — Home and Progress Acceleration

Eliminate global curriculum/question loads and use bounded summary/local state.

## FR12 — Exam Readiness Migration

Move readiness snapshots/plans to Supabase while preserving M7 logic and bounded queries.

## FR13 — Learner State and Attempts Migration

Migrate progress, quiz attempts, study activity, LAB attempts and Learning Twin evidence with UID isolation and retry/conflict handling.

## FR14 — Controlled Supabase Cutover

```text
Firestore primary
-> Supabase shadow
-> Supabase primary
-> controlled Firestore fallback
-> remove fallback
```

## FR15 — Firestore Learner Retirement

Remove unnecessary learner reads of migrated collections. Retain only explicitly justified Firebase services.

## FR16 — Free-Tier Optimization

Measure DB size, Storage, cached/uncached egress, query frequency, package downloads/sizes and Firebase reads/writes. Optimize before adding infrastructure.

## FR17 — Performance Validation

Test cold/warm launch, Home, Study, Quiz, Progress, Readiness, LAB, Flashcards, Wi-Fi/mobile, latency, disconnect, resume and cold/warm cache.

## FR18 — Security Validation

Test RLS, anonymous/cross-user access, invalid/expired/wrong-project JWT, Storage access, cache isolation, logout, account switch and offline launch. Run security advisors.

## FR19 — Architecture Regression Gates

Fail CI if learner code reintroduces global Firestore reads, offline protected access, cache-before-auth rendering, cross-user cache, unbounded histories, package overwrite, catalogue-before-package publication or client secret/service keys.

## FR20 — Final Closure

Close only when frozen L4 suites, full tests, analyze, Android/web builds, Auth bridge, RLS, migration parity, checksum/rollback, online-only cache security, performance budgets and free-tier measurements all pass, with no need for a second Firebase account/project.

## 31. Immediate NEXT ACTION

```text
FR1 closure
-> fix formatting-only CI failure
-> full green FR validation
-> freeze FR1 recovery point
-> FR2 Supabase Foundation
```

Do not migrate production data before FR2 and FR3 are designed, tested and frozen.
