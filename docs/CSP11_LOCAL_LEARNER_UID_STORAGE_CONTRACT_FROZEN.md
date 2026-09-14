# CSP11 LOCAL LEARNER UID STORAGE CONTRACT — FROZEN

Status: FROZEN FOR IMPLEMENTATION

## Problem

SharedPreferences is device/browser-profile local. The previous learner progress and
Continue Learning keys were device-global, so Account B could read completion and
learning-position state created by Account A on the same device.

## Frozen identity rule

Every learner-owned local record must resolve through:

`Firebase UID -> functional record ID`

For Subtopic progress:

`Firebase UID -> Subtopic ID -> progress record`

For Continue Learning:

`Firebase UID -> learning-position fields`

## Storage contracts

Progress namespace:

`csp11.student.<firebaseUid>.learning_progress.v2`

The JSON map inside that namespace remains keyed by canonical Subtopic ID.

Continue Learning namespace:

`csp11.student.<firebaseUid>.learning_position.v2.<field>`

Examples:

`csp11.student.uid-A.learning_progress.v2`

`csp11.student.uid-B.learning_progress.v2`

`csp11.student.uid-A.learning_position.v2.subtopic_id`

`csp11.student.uid-B.learning_position.v2.subtopic_id`

## Authentication boundary

`AuthGate` activates the verified student `AppUser.uid` before constructing the learner
shell.

Signed-out, admin, unverified, waiting, and auth-error states clear the local learner
identity.

The learner shell is keyed by Firebase UID so account changes cannot reuse another
learner's in-memory BottomNavigation/Progress/Home state.

## Legacy V1 handling

The old device-global keys are not automatically migrated:

`csp11.student.learning_progress.v1`

`csp11.student.learning_position.*`

The app cannot prove which historical Firebase account created those records.
Automatically assigning them to the next account would recreate the contamination
problem.

V1 data is therefore ignored by the new V2 repositories and left untouched for
rollback/diagnostics.

## Required behavior

- Account A completes Subtopic X.
- Switch to Account B on the same phone.
- Account B sees Subtopic X as Not Started unless B completed it independently.
- Account B can complete Subtopic Y.
- Switching back to Account A restores A's X and does not inherit B's Y.
- Continue Learning follows the same account boundary.
- `clearAllProgress()` clears only the active learner.
- `clearPosition()` clears only the active learner.
- Subtopic content-version checks remain unchanged.
- Topic completion remains derived from the active learner's child Subtopic records.
- Logging out does not delete the learner's saved namespace.
- Logging back into the same Firebase UID on the same device restores that UID's local
  state.

## Not in scope

This phase does not:
- move learner progress to Firestore;
- synchronize progress between devices;
- change published-content caching;
- change Question Bank rules;
- change canonical Topic/Subtopic IDs;
- implement Flashcard review persistence;
- stage, commit, push, or deploy.
