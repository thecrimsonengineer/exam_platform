# CSP11 Phase FR10 StudyContent Delivery Cutover

## Status

**IMPLEMENTATION COMPLETE - FINAL SAME-SHA FREEZE GATE**

Working branch: `phase-fr10-studycontent-delivery-cutover`  
Frozen source branch: `phase-fr9-closed`  
Frozen source SHA: `7787a1aed26317432285d6b38d51f60927cb9396`  
Date: 2026-09-22

## Purpose

FR10 replaces learner-side Firebase/Firestore StudyContent delivery with the
same online-authorized, competency-scoped, immutable-package architecture
proven by FR9 for questions.

FR10 does not migrate admin authoring. It does not change the canonical
draft -> review -> validated -> published lifecycle. It does not permit offline
protected learning.

## Frozen inherited invariants

FR10 inherits all closed FR1-FR9 rules.

In particular:

- Firebase Auth remains the learner identity provider.
- Protected content renders only while the current Firebase UID is
  ONLINE_AUTHORIZED.
- Direct learner Supabase Data API access remains forbidden.
- Published packages remain in the private
  `csp11-published-packages` bucket.
- Learner clients never receive a Supabase secret/service-role key.
- Signed package URLs are short lived.
- Existing learner-owned progress, attempts, readiness, preferences and other
  local state must not be destroyed.
- Frozen Phase L4 behavior must remain green.
- FR10 must not reintroduce global learner question loading.

## Production content-package baseline

Measured from the active production `published_catalog` on 2026-09-22:

| Metric | Value |
|---|---:|
| Active competency rows | 35 |
| Rows with content package paths | 35 |
| Minimum compressed content package | 8,212 bytes |
| Maximum compressed content package | 28,334 bytes |
| Average compressed content package | 22,353 bytes |
| Total compressed content bank | 782,343 bytes |

The complete content bank is therefore larger than the frozen FR10 learner
content-package cache budget.

## FR10 target architecture

```text
learner opens competency
-> Online Access Gate confirms current Firebase UID
-> current Firebase ID token
-> reviewed Supabase Edge gateway
-> one active published_catalog row
-> compare cached content package version + checksum
-> current?
   yes -> verify/read authorized UID package cache
   no  -> one 60-second signed URL
          -> download one immutable gzip package
          -> verify byte count
          -> verify SHA-256
          -> verify gzip
          -> verify package envelope
          -> verify published StudyContent payload
          -> persist verified package in bounded UID cache
-> decode StudyContent
-> session RAM
-> learner UI
```

No learner Firestore StudyContent read belongs in the final FR10 path.

## Package contract

FR10 uses the existing FR7 immutable content envelope:

```json
{
  "schemaVersion": 1,
  "kind": "content",
  "competencyId": "d01_c01",
  "sourceVersion": 5,
  "content": { "...": "StudyContent payload" }
}
```

The catalogue descriptor exposed to the learner contains only:

- `competencyId`
- `contentVersion`
- `contentChecksumSha256`
- `contentSizeBytes`

Storage object paths stay server-side.

A changed package response may additionally contain:

- `current: false`
- one HTTPS `signedUrl`
- `signedUrlTtlSeconds: 60`

An unchanged response contains:

- `current: true`
- no signed URL
- no Storage object path

## Strict decoder order

A package is not trusted until validation succeeds in this order:

1. compressed byte count matches catalogue metadata;
2. compressed SHA-256 matches catalogue metadata;
3. gzip decoding succeeds;
4. JSON root is an object;
5. `schemaVersion == 1`;
6. `kind == content`;
7. envelope competency matches requested descriptor;
8. `sourceVersion` is positive;
9. content payload is an object;
10. payload status is published;
11. payload competency matches the descriptor;
12. payload domain matches the competency domain;
13. payload version equals `sourceVersion`;
14. StudyContent model decoding succeeds;
15. normalized StudyContent still satisfies all preceding identity/lifecycle
    checks.

Failed replacement never destroys the previous verified package.

## Learner content-package cache

FR10 freezes a **512 KiB compressed-byte LRU budget**.

This is:

- larger than the current largest package by more than 18x;
- below the current complete content bank of 782,343 bytes;
- sufficient for many recently used competencies without becoming a permanent
  whole-bank offline repository.

The cache is Firebase-UID scoped and readable only through the existing
FR8 online-authorization boundary.

Cache entries contain verified immutable compressed bytes plus the descriptor
needed for version/checksum comparison.

FR10 does not write learner progress, readiness, attempts, bookmarks or
preferences into this cache.

## Navigation rule

Domain and competency navigation must not download StudyContent merely to build
an index.

The canonical CSP11 blueprint/competency registry provides structural domain and
competency navigation.

A content package is requested only when learner content for that competency is
actually needed or when a tightly controlled authorized prefetch policy later
permits it.

## Existing StudyContent cache migration

The FR8 decoded StudyContent cache may contain valid protected bytes from an
older installation.

FR10 may read it only while the same UID is ONLINE_AUTHORIZED.

It must not be deleted merely because the new package cache exists. Retirement
is allowed only after the corresponding replacement package has been
downloaded, verified, persisted and read back successfully.

Learner-owned non-content data is outside this retirement path and must remain
untouched.

## Implementation slices

### FR10A - contract and strict decoder

Status: COMPLETE on exact SHA
`3ba5e961e06c541cb982d85a894366870969c467`.

Validation run `35706488537` passed FR1-FR10A, frozen Phase L4, full repository
regression and diff hygiene.

- freeze this design;
- add content package descriptor/resolution models;
- add strict FR7 content-package decoder;
- add unit and architecture tests;
- wire FR10 into exact-SHA CI;
- no learner runtime cutover.

### FR10B - UID-scoped bounded content package cache

Status: COMPLETE on exact SHA
`7121eea1e40a917f357e81297da1a3857c02ddba`.

Validation run `35707297545` passed FR1-FR10B, frozen Phase L4, full repository
regression and diff hygiene.

- add 512 KiB compressed-byte LRU cache;
- require same-UID current online authorization for every cache operation;
- verify before write and after read-back;
- preserve prior verified entry on failed replacement;
- add cross-user, locked-state, eviction and corruption tests.

### FR10C - authorized content gateway

Status: COMPLETE.

Repository gateway checkpoint: `f4d9b4aecdcac9f67e696538c21adba570daff49`.  
Validation run: `35707994960` — PASS.  
Production function: `learner-question-packages` version 2 — ACTIVE.  
Authorized production proof SHA:
`811672cfac888eafde2e63d0d98b8cb7ea7ae835`.  
Authorized proof run: `35708961544` — PASS.  
Full FR run on proof SHA: `35708961310` — PASS.

The live proof returned 35 compact content descriptors. Competency `d01_c01`
downloaded as content package version 1 at exactly 13,006 compressed bytes,
matched SHA-256
`1b4455c812ff4b79acc10fdfe58375cb1e98812a0c3c92242fd16336c75af27b`,
passed gzip integrity, received one 60-second signed URL when changed, and
returned `current: true` with no signed URL when unchanged. The sanitized
artifact persisted no learner token or signed URL.

Extend the reviewed learner package Edge boundary with content-specific
operations while keeping existing FR9 question operations byte-compatible.

Required operations:

- compact content catalogue metadata;
- one competency content resolution;
- unchanged package returns no signed URL;
- changed package returns one 60-second signed URL;
- exact CSP11 Firebase issuer/audience/RS256 verification remains mandatory;
- private Storage remains private;
- no object path is exposed to the learner.

Deploy only after exact-SHA repository gates are green.

### FR10D - targeted StudyContentLoader cutover

Status: COMPLETE on exact SHA
`d68e37c901dc7a666a29e1ce5856070cefc94063`.

Validation run `35710217566` passed formatting, analysis, FR1-FR10D,
frozen Phase L4, full repository regression and diff hygiene.

- route `loadStudyContent` through the verified content-package delivery
  service;
- route refresh through the same targeted version/checksum flow;
- remove learner Firebase/Firestore fallback behavior;
- preserve protected session RAM semantics;
- keep compatibility constructors only where required by existing non-learner
  tests, without restoring learner Firestore behavior.

### FR10E - navigation and broad-read retirement

Status: COMPLETE on exact SHA
`76df4eb28dc760077331e92869928ea8bbcebb1a`.

Validation run `35713353625` passed formatting, analysis, FR1-FR10E,
frozen Phase L4, full repository regression and diff hygiene.

The learner light and dark domain screens now build competency navigation from
the canonical CSP11 blueprint. The development content test route also uses
canonical targeted navigation. No student-facing CSP screen calls broad
published-content loaders, and session-RAM navigation no longer performs an
unconditional background content revalidation.

- replace `loadDomains` and `loadCompetencies` data discovery with the
  canonical blueprint registry;
- remove learner calls to `loadPublished()`;
- remove learner calls to `loadPublishedDomain()`;
- remove unconditional navigation revalidation;
- architecture-gate against broad learner StudyContent reads.

### FR10F - production validation and closure

Status: COMPLETE.

The implementation and production closure proof are complete. The final
documentation commit must itself pass the same exact-SHA repository and live
production gates before the immutable closure branch is advanced to it.

Verified functional closure candidate:
`ef51a7960219b58282ff20f6e068b97bd0c57f33`.

Authorized production proof run `35715777666`: PASS.  
Full FR validation run `35715777759`: PASS.

Sanitized production evidence:

- valid Firebase learner token authorized successfully;
- missing token failed closed;
- malformed token failed closed;
- authorized compact content catalogue returned 35 competencies;
- changed `d01_c01` content package version 1 returned one 60-second signed URL;
- compressed package size matched exactly at 13,006 bytes;
- SHA-256 matched
  `1b4455c812ff4b79acc10fdfe58375cb1e98812a0c3c92242fd16336c75af27b`;
- gzip integrity passed;
- the live package passed the app's real `ContentPackageDecoder`;
- exactly one package download occurred;
- unchanged re-open returned `current: true`;
- unchanged response contained no signed URL;
- unchanged re-open required zero additional package downloads;
- no learner token or signed URL was persisted in evidence.

The implementation closure candidate passed the authorized production proof
and the full FR1-FR10, frozen L4 and repository regression. The final
documentation-only closure commit is subject to the same two exact-SHA gates
before `phase-fr10-closed` is advanced to it.

Prove on production:

- valid learner token succeeds;
- missing/malformed token fails closed;
- one changed content package receives one 60-second signed URL;
- compressed size and checksum match;
- gzip and StudyContent decoding succeed;
- unchanged content package returns `current: true` and no signed URL;
- cached unchanged reopen performs zero package downloads;
- offline/locked state cannot read protected content;
- full FR1-FR10, frozen L4 and repository regression remain green.

Freeze `phase-fr10-closed` only at the exact green evidence SHA.

## Permanent FR10 guards

Learner runtime must not reintroduce:

```text
CloudPublishedContentRepository.loadPublished()
CloudPublishedContentRepository.loadPublishedDomain()
CloudContentRepository learner published reads
Firestore-first StudyContent loading
cloud-failure offline StudyContent fallback
cache-before-authorization
public content package Storage
direct learner published_catalog Data API access
whole-bank content package prefetch
```

Admin authoring may continue using its existing repository until its later
migration phase explicitly changes it.

## NEXT ACTION

None. Phase FR10 is complete.

Do not add further FR10 implementation work after the final documentation SHA
passes both exact-SHA closure workflows and `phase-fr10-closed` is advanced
to that SHA. Any later change belongs to a new phase or an explicitly reopened
phase with its own review and recovery point.
