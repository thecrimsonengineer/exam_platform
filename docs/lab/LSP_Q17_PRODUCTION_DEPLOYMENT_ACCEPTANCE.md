# CSP11 LSP-Q17 - Production Deployment Preflight and Live Release Acceptance

## Status

**IMPLEMENTED / VALIDATION CANDIDATE**

Program: LSP-Q

Checkpoint: LSP-Q17

Branch: phase-lsp-q17-production-deployment-preflight

Frozen Q16 recovery branch: phase-lsp-q16-closed

Frozen Q16 closure SHA: 04bfdc9d5c61faeb5a7a30e86cb753947ba8e49a

Q16 exact-SHA validation run: 35950731991

## Purpose

LSP-Q17 adds the final production deployment preflight and immutable live-release acceptance layer after Q16.

Q17 does not publish LAB content. It does not seed, overwrite, delete or repair production records. It verifies that the live environment already matches the frozen Q16 release contract and then allows an authenticated administrator to record acceptance once.

## Frozen production environment

Q17 is pinned to:

firebase_project:csp11-exam-platform

A different Firebase project fails closed.

The project binding is checked in both the application service and Firestore rules.

## Required preflight state

Q17 reaches READY only when all of the following are true:

1. Q16 reports CLOSED.
2. Q15 immutable release evidence exists.
3. Q15 learner release marker is active.
4. Firebase environment equals firebase_project:csp11-exam-platform.
5. Release ID equals phase_l_population_v1_q15_release_v1.
6. Manifest identity and manifest fingerprint match the Q16 inspection.
7. Published LAB count is 10.
8. Learner catalogue count is 10.
9. Learner catalogue identity count is 10.
10. Q15 evidence certifies 10 LABs and 50 decisions.
11. No conflicting Q17 acceptance record exists.

Any mismatch produces BLOCKED.

## Acceptance action

Required typed confirmation:

ACCEPT LIVE RELEASE

The admin UI requires both the exact phrase and a second confirmation dialog.

The action writes one immutable document:

labProductionReleaseAcceptance/phase_l_population_v1_q15_release_v1

The acceptance record contains:

- Q16 closure SHA
- Q16 exact validation run ID
- Firebase production environment
- manifest fingerprint
- Q15 evidence fingerprint
- LAB count
- decision count
- authenticated acceptance actor
- UTC acceptance timestamp
- deterministic acceptance fingerprint

The document cannot be updated or deleted through Firestore rules.

## Acceptance states

### BLOCKED

The environment or frozen release evidence does not match Q17 requirements.

No acceptance write is available.

### READY

The production environment and Q16 CLOSED release match the frozen contract.

The exact typed confirmation may be used to record acceptance.

### ACCEPTED

Immutable Q17 acceptance exists and independently matches the current Q15/Q16 release evidence.

No second acceptance action is available.

## Firestore boundary

Only authenticated admins may read or create Q17 acceptance evidence.

Create is allowed only when:

- the release ID is the frozen initial production release ID
- Q16 SHA is 04bfdc9d5c61faeb5a7a30e86cb753947ba8e49a
- Q16 validation run is 35950731991
- environment is firebase_project:csp11-exam-platform
- LAB count is 10
- decision count is 50
- Q15 release evidence exists
- Q15 learner release state exists
- stored environment, manifest fingerprint and evidence fingerprint match Q15 evidence
- learner release state is active and fingerprint-linked

Update and delete are forbidden.

## Admin surface

Admin navigation:

Admin -> Release Acceptance

The screen displays:

- frozen Q16 SHA
- Q16 exact validation run
- expected Firebase project
- current Firebase project
- manifest ID
- manifest fingerprint
- published count
- catalogue count
- catalogue identity count
- Q15 evidence fingerprint
- Q17 state
- blocking reason when applicable
- immutable Q17 acceptance when present

## Validation

Dedicated Q17 coverage verifies:

1. non-production Firebase project is blocked
2. a valid Q16 CLOSED release becomes READY
3. exact typed confirmation is required
4. acceptance moves READY to ACCEPTED
5. acceptance is immutable
6. Firestore acceptance rules are admin-only and immutable
7. admin navigation exposes the acceptance surface
8. acceptance UI remains disabled until the exact phrase is entered

All Q1-Q16 tests, static analysis, Studio regressions and the full repository regression remain mandatory.

## Safety rule

CI must never create the live Q17 acceptance record.

GitHub Actions validates code and contracts only. The acceptance write remains an explicit foreground administrator action in the authenticated application.

## Closure condition

LSP-Q17 closes only when:

- dedicated Q17 tests are green
- all prior LSP-Q gates are green
- static analysis is green
- full repository regression is green
- diff hygiene is green
- canonical formatting is green
- the exact Q17 closure SHA has a successful validation run

Live acceptance itself is an operator action after the validated build is deployed to the frozen production Firebase project.

## Closure candidate

Q17 deployment acceptance implementation commit: `af0dfd673daee2e7081e7c35828c88ae9a43aca4`

Successful full validation run including Q17 deployment acceptance tests, Studio regressions, full repository regression, diff hygiene and formatter closure: `35954257324`

Canonical formatter output commit: `3b92054154da54f6d1bfa3f3b65368d7ee0cd429`

The formatter commit changes formatting only in:

- `test/lab_quality/lsp_q17_production_deployment_acceptance_test.dart`

This documentation-only closure commit is the exact-SHA validation target for LSP-Q17. It does not change the Q14 seed contract, Q15 immutable release evidence, Q16 operator contract, Firestore authorization model, production environment binding, Q17 acceptance state machine or live acceptance semantics.

## Next authorized action

After this exact documentation-only closure SHA has a successful validation run, freeze it as `phase-lsp-q17-closed`.

No LSP-Q18 checkpoint is currently defined in the repository. Any further LSP-Q work should begin from a separately frozen implementation plan rather than extending Q17 implicitly.
