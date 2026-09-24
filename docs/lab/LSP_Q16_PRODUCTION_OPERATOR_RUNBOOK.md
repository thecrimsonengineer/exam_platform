# CSP11 LSP-Q16 - Production Execution Command Surface and Operator Runbook

## Status

**IMPLEMENTED / VALIDATION CHECKPOINT**

Program: LSP-Q

Checkpoint: LSP-Q16

Branch: phase-l4-scenario-population

Frozen Q15 recovery branch: phase-lsp-q15-closed

Frozen Q15 closure SHA: ff4aa9c2a04b668549bb7af8a5f03806c31d6644

Q15 exact-SHA validation run: 35946294148

## Purpose

LSP-Q16 provides the authenticated administrator command surface for executing the frozen Q14 seed and Q15 closure contracts against the app's Firebase production repositories.

Q16 does not add a second publication path. It is an operator shell around the already validated Q14/Q15 services.

## Operator states

The production surface classifies the live repository state before any action.

### PRISTINE

- zero target published LAB versions
- zero target learner catalogue entries
- no learner catalogue identities
- no Q15 evidence
- no release-state marker

Only this state may execute the one-shot initial seed.

Required typed confirmation:

RELEASE 10 LABS

### COMPLETE_UNCLOSED

- all ten immutable published versions exist
- all ten learner catalogue entries exist
- Q14 exact release verification passes
- Q15 evidence does not yet exist

This is the recovery state for an interruption after Q14 completed but before Q15 closure.

The operator must not seed again.

Required typed confirmation:

CLOSE 10 LABS

### CLOSED

Q15 evidence exists and independently verifies against the live published versions and learner catalogue.

No release mutation action is available.

### BLOCKED_PARTIAL

Any partial, inconsistent or invalid population is blocked.

Q16 deliberately provides no automatic repair, overwrite or delete action.

The operator must preserve evidence and handle the condition through a separately reviewed recovery phase.

## Admin preflight rule correction

Q15 correctly gated learner catalogue visibility behind the release-state marker, but the original rule also prevented an admin from reading the unreleased learner catalogue before Q15 closure.

That creates an operational deadlock because Q15 must verify the catalogue before it can create the release marker.

Q16 corrects the rule to:

- admins may GET/LIST the learner catalogue before release
- authenticated learners remain blocked until initialLabPopulationReleased() is true

The learner barrier is therefore preserved while the authenticated admin can perform Q14/Q15 verification.

## Production command surface

Admin navigation:

Admin -> Publishing -> LAB Production Release

The screen displays:

- frozen Q15 closure SHA
- frozen Q15 validation run
- Firebase project environment identifier
- population manifest ID
- deterministic manifest fingerprint
- published count
- catalogue count
- catalogue identity count
- operator state
- blocking reason when applicable
- immutable Q15 evidence when CLOSED

The irreversible action button stays disabled until the operator types the exact state-specific confirmation phrase.

A second confirmation dialog is required before execution.

## Asset source

Q16 reads the already version-controlled population package from Flutter assets:

content/lab_population/manifest.json

For each manifest entry it loads:

- technical.json
- dqg300_evidence.json
- learner_presentation.json

The same manifest and artifacts validated by Q9-Q15 are therefore used by the production operator.

No file picker and no ad-hoc JSON paste is allowed on the production release surface.

## Operator runbook

Before touching the action control:

1. Confirm the app build contains frozen Q15 SHA ff4aa9c2a04b668549bb7af8a5f03806c31d6644 or a later Q16-validated descendant.
2. Sign in through the existing admin gate.
3. Open Publishing -> LAB Production Release.
4. Record the displayed environment ID and manifest fingerprint.
5. Refresh once immediately before execution.
6. Read the state and follow only the matching instruction below.

### If PRISTINE

- Confirm Published = 0/10.
- Confirm Catalogue = 0/10.
- Type RELEASE 10 LABS exactly.
- Select EXECUTE INITIAL RELEASE.
- Read the confirmation dialog.
- Confirm once.
- Do not navigate away during the foreground command.
- After completion, the screen must refresh to CLOSED.
- Record the Q15 evidence fingerprint.

### If COMPLETE_UNCLOSED

- Do not run the seed again.
- Confirm Published = 10/10.
- Confirm Catalogue = 10/10.
- Type CLOSE 10 LABS exactly.
- Select CLOSE EXISTING RELEASE.
- Confirm once.
- The screen must refresh to CLOSED.
- Record the Q15 evidence fingerprint.

### If CLOSED

- Make no release write.
- Record the existing release ID, actor, execution timestamp and evidence fingerprint.
- Learner LAB access is already enabled by the immutable release-state marker.

### If BLOCKED_PARTIAL

- Stop.
- Do not delete documents.
- Do not overwrite versions.
- Do not manually create a release-state marker.
- Preserve Firestore state and logs.
- Record published and catalogue counts plus the blocking message.
- Open a dedicated recovery phase before any mutation.

## Credential boundary

Q16 uses the user's existing authenticated Firebase admin session.

No Firebase service-account key, admin SDK credential or embedded secret is added to the Flutter client.

Firestore remains the authorization boundary.

## Release evidence to retain

For the production execution record retain:

- Q16 validated app commit
- Firebase project environment ID
- admin execution UID
- execution timestamp
- manifest ID
- manifest fingerprint
- release ID
- 10 LAB count
- 50 decision count
- Q15 evidence fingerprint

The immutable Q15 Firestore document remains the authoritative machine-readable release certificate.

## Files

Added:

- lib/features/lab/lab_production_release_operator.dart
- lib/screens/admin/lab/lab_production_release_screen.dart
- test/lab_quality/lsp_q16_production_release_operator_test.dart
- docs/lab/LSP_Q16_PRODUCTION_OPERATOR_RUNBOOK.md

Updated:

- lib/screens/admin/admin_home_screen.dart
- firestore.rules
- .github/workflows/lsp_unified_lab_question_validation.yml

## Validation

Dedicated Q16 coverage verifies:

1. pristine state classification
2. complete-unclosed state classification
3. closed state classification
4. closure-only recovery without reseeding
5. partial population hard block
6. exact typed confirmation requirement
7. admin pre-release catalogue access with learner barrier retained
8. production screen confirmation gating
9. Admin Publishing navigation binding

All Q1-Q15 gates and the full repository regression remain mandatory.

## Closure condition

LSP-Q16 closes only after the dedicated Q16 tests, all prior LSP-Q gates, static analysis, full repository regression, diff hygiene and canonical formatting are green on the exact Q16 closure SHA.


## Closure candidate

Q16 operator surface implementation commit: `0de2a347386116e4152f059b6fc97e479e63d9b4`

Analyzer repair commit: `3462143012b6f3f04ae69c49321687e7f5122f55`

Off-screen widget-test repair commit: `d00f23f9ce3804a33e0f00648dc077d2facb14f6`

Successful full validation run including Q16 operator tests and full repository regression: `35948765658`

Canonical formatter output commit: `fb752f15d78ef95fdff79d6c2feb47c753083a6b`

The formatter commit changes formatting only in:

- `lib/features/lab/lab_production_release_operator.dart`
- `lib/screens/admin/lab/lab_production_release_screen.dart`
- `test/lab_quality/lsp_q16_production_release_operator_test.dart`

This documentation-only closure commit is the exact-SHA validation target for LSP-Q16. It does not change the Q14 seed contract, Q15 evidence contract, learner release barrier, Firestore authorization model, operator state machine or production action semantics.

## Next authorized action

LSP-Q17 - Production Deployment Preflight and Live Release Acceptance.
