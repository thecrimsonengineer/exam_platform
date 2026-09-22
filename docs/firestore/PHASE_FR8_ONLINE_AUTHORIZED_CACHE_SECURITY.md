# CSP11 Phase FR8 Online-Authorized Cache Security

Status: IMPLEMENTATION CANDIDATE
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

Status: IMPLEMENTATION CANDIDATE.

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

- connect platform network change signals to the FR8 controller;
- use a short reconnect debounce for handover;
- revalidate after recovery;
- lock when loss is confirmed;
- never treat connectivity state alone as authorization.

### FR8E — Closure

- run offline launch tests;
- run cached-content offline tests;
- run logout/account-switch isolation tests;
- run resume revalidation tests;
- run interrupted cache-migration tests;
- run existing learner-data preservation tests;
- run FR1-FR8, frozen L4 and full repository regression;
- freeze `phase-fr8-closed` only at the exact green SHA.

## NEXT ACTION

Validate FR8C on the full FR gate. If green, continue to FR8D network-loss
integration from the exact green FR8C SHA.

Do not begin learner source cutover during FR8. Firestore remains the learner
content/question source until the later reviewed cutover phases.
