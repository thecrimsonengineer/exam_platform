# CSP11 Phase FR8 Online-Authorized Cache Security

Status: CLOSED CANDIDATE
Branch: phase-fr8-online-authorized-cache-security
Source checkpoint: phase-fr7-closed
Source SHA: 4c160881fc1661221b8a9f2f67cd55db35cfa5da
Date: 2026-09-21

## Purpose

FR8 establishes the security boundary that allows CSP11 to feel cache-fast while
remaining strictly online-authorized.

Protected StudyContent, questions, explanations, references, LAB payloads,
flashcards and protected readiness material must never be unlocked merely
because bytes exist on the device.

FR8 does not perform learner delivery cutover. Firestore remains the learner
source until the later reviewed FR cutover phases.

## Frozen security invariant

Protected cache access is allowed only when all of the following refer to the
same learner session:

```text
current Firebase UID
+ current Firebase token
+ successful remote authorization
+ unlocked UID-scoped cache boundary
= protected cache may render
```

A cache hit is never an authorization decision.

## Session state model

FR8 uses three states:

```text
LOCKED -> VALIDATING -> AUTHORIZED
```

Any sign-out, account switch, rejected authorization, backend-unavailable
result, confirmed network loss or explicit lock returns the session to LOCKED.

A stale asynchronous validation result must never reopen a session after a
newer lock or user switch.

## Resume rule

When the learner app resumes from background, protected access is locked first.
The current Firebase identity is then revalidated remotely before protected
cache access can be restored.

## Network handover rule

A short reconnect grace may be used for Wi-Fi/mobile handover. The grace is not
an offline-study mode.

After the grace window, authorization must succeed again. Confirmed network loss
locks protected access immediately.

## UID isolation

Every persistent protected cache introduced or migrated by FR8 is namespaced by
Firebase UID.

User B must never unlock User A's protected cache.

Process-memory caches that contain protected material must also be cleared or
made UID-scoped across sign-out and account switch.

## Existing local learner data

Learner-owned progress, question history, Exam Readiness state, study plans,
preferences and unsynchronized learner-owned records are preserved.

FR8 requires no uninstall, no Clear Data operation and no package-ID change.

Existing UID-scoped learner-owned storage keys are not rewritten merely to
satisfy cache security.

## Legacy protected-cache migration

The existing device-global StudyContent cache is protected payload, not
learner-owned progress.

It may be migrated only after current online authorization succeeds for the
active Firebase UID.

Migration order is frozen as:

```text
copy -> validate -> write -> read-back -> switch -> retire legacy cache
```

If validation or read-back verification fails, the legacy bytes remain intact
and the new cache is not activated.

Legacy protected bytes are never rendered offline during migration.

## Bounded cache direction

FR8 prepares the cache boundary for a byte-bounded LRU implementation. The
initial package-size evidence from FR7 is 1,823,286 compressed bytes across 70
published competency packages. Final cache byte limits will be set from measured
package sizes and device behavior rather than an arbitrary full-bank cache.

## Implementation slices

### FR8A — Authorization session core

Status: COMPLETE on exact SHA
`14e26a6e1e75e00e41f8ad4ce046100faac7becf`.

Validation run `35645884484` passed FR1-FR8, frozen L4, full repository
regression and diff hygiene.

- reuse the frozen FR2 `LearnerOnlineAccessGate`;
- add a UID-bound authorization-session controller;
- reject stale in-flight authorization results;
- lock on sign-out and account switch;
- lock and revalidate on app resume;
- define transient connectivity debounce and confirmed-loss behavior;
- expose an explicit protected-cache unlock interface;
- add unit and architecture tests.

### FR8B — UID-scoped protected StudyContent cache

Status: COMPLETE on exact SHA
`9ab4a812e5d565fc16a71e9bda5776bf34218bb0`.

Validation run `35646970175` passed the FR8 secure-cache tests, frozen L4,
full repository regression and diff hygiene.

FR8B stages the secure cache repository beside the current learner runtime.
The existing `StudyContentLoader` is not switched to this repository until
FR8C owns a live authorization session.

- create a Firebase-UID-scoped protected cache namespace;
- require the FR8 protected-cache unlock boundary before reads and writes;
- migrate the legacy cache only after successful online authorization;
- merge the newest valid published competency versions during migration;
- use copy/validate/write/read-back/marker/switch semantics;
- retire the legacy cache only after read-back verification;
- restore the previous scoped cache if verification or marker write fails;
- preserve legacy bytes on migration failure;
- add cross-user, offline-blocking and interrupted-migration tests.

### FR8C — Runtime lifecycle integration

Status: COMPLETE on exact SHA
`02309eaa4a0e7b2e3f24c9b0755d1c60b1ed468f`.

Validation run `35681733913` passed FR1-FR8, the frozen Phase L4 learner,
quality and engine suites, 2,530 full-repository tests and diff hygiene.

- bind the verified student shell to the FR8 session controller;
- authorize before protected learner content is rendered;
- switch the default StudyContent cache to the FR8B UID-scoped repository;
- migrate legacy protected StudyContent bytes only after authorization;
- lock on logout and account switch;
- lock first and revalidate on resume;
- clear StudyContent, quiz-catalogue and progress-dashboard process memory;
- generation-guard quiz preload so stale reads cannot repopulate after lock;
- keep Firestore as the current content/question source in FR8.

### FR8D — Network-loss integration

Status: COMPLETE on exact SHA
`5a767d136c7e82946f4949ee9bb29c39f0d4058b`.

Validation run `35683002299` passed dependency/native-registration checks,
formatting, analysis, FR1-FR8, the frozen Phase L4 suites, full repository
regression and diff hygiene.

- use `connectivity_plus 7.3.1` only as a cross-platform transport signal;
- keep connectivity state separate from authorization state;
- fail closed on an offline launch or connectivity-monitor failure;
- use the frozen short reconnect grace for Wi-Fi/mobile handover;
- remotely revalidate the current Firebase token after transport recovery;
- cancel stale loss handling when transport recovers and a newer authorization
  generation wins;
- keep protected content locked whenever remote authorization fails;
- inject the connectivity source in tests so shell behavior remains
  deterministic;
- never treat Wi-Fi, mobile or other transport presence as proof of Internet
  reachability or learner authorization.

### FR8E — Closure

Status: COMPLETE on exact SHA
`1dfed6439045be4a9964613307f33530c75869b2`.

Validation run `35683479860` passed the dependency/native-registration
checks, formatting, analysis, FR1-FR8, the executable FR8 closure evidence
matrix, all frozen Phase L4 suites, full repository regression and diff
hygiene.

The closure matrix is executable in
`test/architecture/phase_fr8_closure_test.dart` and requires all of the
following evidence to remain present and green:

- offline launch does not render protected learner UI;
- cached protected StudyContent cannot be read while authorization is locked;
- logout/account-switch changes lock the prior UID and keep UID caches isolated;
- app resume locks protected UI first and requires remote reauthorization;
- interrupted protected-cache migration restores the previous scoped cache and
  retains legacy bytes;
- learner progress and Exam Readiness persistence namespaces remain preserved;
- Firestore remains the learner content/question source after FR8;
- FR1-FR8, frozen Phase L4, full repository regression and diff hygiene pass.

No uninstall, Clear Data operation, package-ID change or learner-data rewrite is
required by FR8.

## FR8 closure evidence

FR8 is ready to freeze subject to one final evidence-only exact-SHA validation.

The closure candidate proves:

- FR8A authorization sessions are UID-bound and fail closed;
- FR8B protected StudyContent storage is Firebase-UID scoped;
- legacy protected cache migration is verify-before-retire and rollback-safe;
- FR8C protected learner UI renders only after current remote authorization;
- logout, account switch and resume transitions clear or lock protected
  process-memory state;
- FR8D transport recovery never substitutes connectivity for authorization;
- offline launch and confirmed network loss leave protected content locked;
- existing learner progress and Exam Readiness namespaces remain preserved;
- Firestore remains the learner content/question source after FR8;
- no uninstall, Clear Data operation, package-ID change or learner-data rewrite
  is required.

## NEXT ACTION

Run the final exact repository validation on this evidence-only closure commit.
If green, create `phase-fr8-closed` at that exact SHA.

Do not begin learner source cutover during FR8. Firestore remains the learner
content/question source until the later reviewed cutover phases.
