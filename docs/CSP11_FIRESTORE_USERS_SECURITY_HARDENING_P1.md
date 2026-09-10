# CSP11 Firestore User Security Hardening P1

Status: **DEPLOYMENT-BLOCKED UNTIL MERGED WITH THE CURRENT GLOBAL FIRESTORE RULESET**

## Purpose

This checkpoint hardens the learner profile path:

`/users/{uid}`

The learner registration flow writes a compact profile to that document while
Firebase Authentication owns passwords, password reset, and email verification.

The security objective is fail-closed:

- learners may create only their own profile;
- a new self-created profile must have `role == "student"`;
- learners may read only their own profile;
- learners may update only approved learner-profile fields;
- `uid`, `email`, `role`, and `createdAt` are immutable for learner updates;
- learners may not delete their own user document;
- admins may read and manage user profiles and roles.

## Why this patch does not deploy `firestore.rules`

At the inspected repository checkpoint, the repository did not contain an
authoritative `firestore.rules` + `firebase.json` rules deployment baseline.

Firestore rules apply to the whole database. Replacing the live rules with a
file containing only `/users/{uid}` would deny the app's other Firestore paths.
Conversely, adding a broad signed-in catch-all beneath this fragment could
silently defeat the user restrictions because matching `allow` statements are
OR-combined.

Therefore this patch deliberately creates a **merge fragment** and a regression
contract, but does not invent or deploy a global ruleset.

## Required deployment sequence

1. Open Firebase Console for project `csp11-exam-platform`.
2. Firestore Database -> Rules.
3. Copy the complete currently deployed rules into a local review file.
4. Do not publish changes yet.
5. Provide that complete ruleset for review.
6. Merge this fragment inside the existing
   `match /databases/{database}/documents` block.
7. Remove or narrow any broader rule that would also allow unrestricted access
   to `/users/{uid}`.
8. Test the merged rules with the Firestore Rules simulator/emulator.
9. Confirm the existing Question Bank and Content Repository paths still work.
10. Only then deploy the complete merged ruleset.

## Expected learner security checks

Authenticated learner A:
- create `/users/A` with role `student`: ALLOW
- create `/users/A` with role `admin`: DENY
- create `/users/B`: DENY
- read `/users/A`: ALLOW
- read `/users/B`: DENY
- list `/users`: DENY
- update own fullName/country/optional profile fields: ALLOW
- change own `role`: DENY
- change own `uid`: DENY
- change own `email`: DENY
- change own `createdAt`: DENY
- add an unapproved field: DENY
- delete own profile: DENY

Authenticated admin:
- read/list user profiles: ALLOW
- create/update/delete user profiles: ALLOW
- assign or change roles: ALLOW

Unauthenticated client:
- all `/users/{uid}` access: DENY

## Important

Do not deploy the fragment by itself.
Do not add a broad `match /{document=**}` signed-in write rule that overlaps
`/users/{uid}`.
