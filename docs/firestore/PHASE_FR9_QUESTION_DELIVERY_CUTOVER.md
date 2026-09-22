# CSP11 Phase FR9 Question Delivery Cutover

Status: IMPLEMENTATION CANDIDATE  
Branch: `phase-fr9-question-delivery-cutover`  
Source checkpoint: `phase-fr8-closed`  
Source SHA: `a55dd91c25df2f3e1b9f59298130d2bd72a929f3`  
Date: 2026-09-22

## Purpose

FR9 removes global learner Firestore question delivery and replaces it with
online-authorized, competency-scoped immutable question packages from Supabase.

FR9 does not change Admin Studio authoring, DQG validation, lifecycle state,
question publication, learner progress persistence or StudyContent delivery.

Firestore may remain an authoring/migration source during FR9, but learner quiz
delivery must stop calling the global Firestore published-question path.

## Frozen inheritance

FR9 inherits all FR8 rules:

- current Firebase UID remains the learner identity;
- protected material renders only after current remote authorization;
- direct learner Data API access remains forbidden;
- private Storage objects are never made public;
- cache access is Firebase-UID scoped;
- confirmed network loss locks protected access;
- resume revalidates before protected content renders;
- logout/account switch locks the prior UID;
- learner-owned local progress/readiness/history remains untouched.

## Current problem

The learner quiz path still performs a global Firestore preload:

```text
BottomNavigation
-> QuizService.shared.initialize()
-> CloudQuestionRepository.loadPublished()
+ CloudContentRepository.loadPublished()
-> merge complete learner question catalogue
```

QuizScreen also constructs a fresh QuizService and initializes the same global
catalogue before competency/topic/subtopic quizzes.

This violates the frozen FR target because a one-competency quiz can trigger
reads of the complete published question/content population.

## FR9 target architecture

```text
ONLINE_AUTHORIZED
-> choose the smallest required quiz scope
-> Firebase ID token
-> learner-question-packages Edge Function
-> private published_catalog metadata
-> cached package version/checksum current?
   yes: return metadata only, use authorized UID cache
   no: create short-lived private Storage signed URL
-> download one changed competency question package
-> verify compressed byte count
-> verify SHA-256
-> gzip decode
-> verify package schema + competency + count + question invariants
-> write UID-scoped bounded cache
-> read back verified cache
-> expose questions to QuizService
-> filter/randomize locally
```

A cache hit is never authorization.

## Server-side gateway

Add `learner-question-packages` as a custom Firebase-authorized Supabase Edge
Function with `verify_jwt = false`.

The function must independently verify:

- RS256;
- Firebase Secure Token JWKS;
- issuer `https://securetoken.google.com/csp11-exam-platform`;
- audience `csp11-exam-platform`;
- non-empty Firebase UID.

Only after Firebase verification may the function use the server-side Supabase
service-role environment credential.

No service-role value may be embedded in source, returned to the client or
logged.

### Gateway operations

#### competency

Input:

```json
{
  "operation": "competency",
  "competencyId": "d01_c01",
  "knownQuestionVersion": 1,
  "knownQuestionChecksumSha256": "..."
}
```

The function reads one active `published_catalog` row.

If version and checksum match, return metadata with `current: true` and no
signed URL.

If the package changed or is absent locally, return metadata with
`current: false` plus a short-lived signed URL for exactly:

```text
csp11-published-packages/questions/<competency>/v<version>.json.gz
```

#### catalog

Used only to plan bounded multi-competency practice.

Return small active question metadata:

- competency ID;
- question version;
- checksum;
- compressed bytes;
- published question count;
- optional Ultra Hard count.

Do not return question stems, options, explanations or references.

The Ultra Hard count is discovery metadata only. It is derived server-side from
published canonical question rows carrying `ultra-hard-dqg300`.

## Package contract

FR7 already publishes deterministic gzip envelopes:

```json
{
  "schemaVersion": 1,
  "kind": "questions",
  "competencyId": "d01_c01",
  "sourceRecordMaxVersion": 1,
  "questionCount": 100,
  "questions": []
}
```

FR9 must reject a package when any of the following is wrong:

- compressed byte count;
- SHA-256 checksum;
- gzip decoding;
- schema version;
- kind;
- competency ID;
- declared question count;
- duplicate/non-positive question IDs;
- question competency mismatch;
- non-published status;
- option count is not four;
- correct answer is outside 0-3.

A failed replacement must leave the previous verified cache intact.

## Cache budget

Live production evidence at FR9 start:

- current question packages: 35;
- total current question package bytes: 1,040,943;
- minimum package: 11,311 bytes;
- maximum package: 51,361 bytes;
- average package: about 29,741 bytes;
- median package: about 30,054 bytes;
- largest currently published domain: 227,249 bytes.

FR9 freezes the protected question-package cache budget at **512 KiB**.

This is large enough for more than the largest current domain while remaining
below the complete current question bank.

Eviction is least-recently-used by verified compressed bytes.

Eviction may delete protected cache bytes only. It must never delete learner
question progress, attempts, bookmarks, readiness, plans or preferences.

## Scope planning

### Competency, topic and subtopic quizzes

Resolve exactly one competency package.

Topic/subtopic IDs must map back to their canonical competency.

### Quiz ID

Resolve the canonical competency from the quiz ID when present. If the quiz ID
cannot be mapped safely, fail closed rather than globally loading questions.

### Domain quiz

Use the generated CSP11 blueprint to identify competencies in that domain and
load only active package descriptors required for that domain.

### Daily Challenge

Use compact catalog metadata to deterministically choose a small competency set
for the current date. Download only enough selected packages to obtain the
required five questions.

### Random Quiz

Choose a small randomized competency set from compact metadata. Download only
enough selected packages for the requested count.

### Weak Areas

Use existing UID-scoped question-progress records to determine the weak domain.
Those records already store domain and competency metadata. Load only packages
needed for that domain.

### Ultra Hard

Use server-returned `ultraHardCount` discovery metadata to select only
competencies that contain published DQG300 questions, then filter the verified
packages locally.

## Prewarm rule

The existing BottomNavigation global quiz-catalog prewarm must be removed.

FR9 may prewarm compact metadata only after Online Access Gate is authorized.
It must not pre-download all question packages.

## Implementation slices

### FR9A — contracts and verified package decoder

Status: COMPLETE on exact SHA
`3c68fa3fd503d343e63dd66ae404d2a0f53c4a79`.

Validation run `35691492174` passed dependency locking, formatting, analysis,
FR1-FR9, all frozen Phase L4 suites, full repository regression and diff
hygiene.

- freeze this design;
- add Edge gateway request/response contracts;
- add strict question package decoder;
- add deterministic checksum/byte/schema verification tests;
- add architecture guards;
- no learner runtime cutover yet.

### FR9B — UID-scoped 512 KiB question package cache

Status: COMPLETE on exact SHA
`e0b8eebb6ef61cc893e0362d08c7ef8592b8632c`.

Validation run `35692832487` passed dependency locking, formatting, analysis,
FR1-FR9, the dedicated protected question-cache suite, all frozen Phase L4
suites, full repository regression and diff hygiene.

- add per-UID package entries and metadata;
- add LRU accounting by verified compressed bytes;
- preserve previous verified entry on failed replacement;
- require the FR8 authorization boundary for every read and write;
- reject an individual package larger than the frozen cache budget;
- evict least-recently-used protected package bytes only;
- never touch learner progress, attempts, bookmarks, readiness or preferences;
- add eviction, cross-user, offline and interrupted-write tests.

### FR9C — Firebase-authorized Edge delivery gateway

- implement `learner-question-packages`;
- verify the exact CSP11 Firebase project;
- query service-role-only `published_catalog`;
- issue short-lived signed URLs only after authorization;
- add compact catalog/Ultra Hard discovery metadata;
- add architecture/security tests;
- deploy only after exact-SHA CI is green.

### FR9D — competency-scoped QuizService

- replace global initialization with explicit scope preparation;
- remove learner calls to `CloudQuestionRepository.loadPublished()`;
- remove learner calls to `CloudContentRepository.loadPublished()` for quiz
  assembly;
- keep existing synchronous QuizController filtering after scope preparation;
- preserve duplicate-ID and published-only semantics;
- add competency/topic/subtopic/domain tests.

### FR9E — practice mode cutover

- Daily, Random, Weak Areas and Ultra Hard use compact discovery metadata;
- download only the selected competency packages;
- preserve current question-count and DQG300 semantics;
- remove global question-bank prewarm from BottomNavigation.

### FR9F — production validation and closure

- deploy the Edge function;
- run authorized live metadata smoke tests;
- verify unchanged package returns no signed URL/package download;
- verify changed/missing package returns one signed URL;
- verify invalid/wrong-project/missing Firebase token fails closed;
- verify private Storage remains private;
- verify learner Firestore global question reads are absent by architecture gate;
- run FR1-FR9, frozen L4 and full repository regression;
- freeze `phase-fr9-closed` only at the exact green SHA.

## Permanent FR9 guard

Learner runtime must not reintroduce:

```text
CloudQuestionRepository.loadPublished()
CloudContentRepository.loadPublished()
global published question preload
cache-before-authorization
direct published_catalog Data API reads
public Storage question packages
whole-bank package prefetch
```

Admin authoring and migration tooling may continue to use their existing
repositories until their own later migration phase explicitly changes them.

## NEXT ACTION

Implement and validate FR9C only.

Do not deploy the Edge function until its repository implementation and
security guards are green on the exact-SHA FR gate. Do not cut learner
QuizService over during FR9C.
