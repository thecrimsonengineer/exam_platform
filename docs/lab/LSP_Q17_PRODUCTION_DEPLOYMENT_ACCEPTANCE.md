# CSP11 LSP-Q17 - Production Deployment Preflight and Live Release Acceptance

## Status

**IMPLEMENTED / VALIDATION CHECKPOINT**

Program: LSP-Q

Checkpoint: LSP-Q17

Branch: phase-l4-scenario-population

Frozen Q16 recovery branch: phase-lsp-q16-closed

Frozen Q16 closure SHA: 04bfdc9d5c61faeb5a7a30e86cb753947ba8e49a

Q16 exact-SHA validation run: 35950731991

## Purpose

LSP-Q17 makes the production release sequence deployment-aware.

Q16 proved that the app can safely classify and execute the release state machine. Q17 adds two independent production controls:

1. an immutable deployment preflight that proves the app is pointed at the intended Firebase project and that the Q17 Firestore rules are active
2. an immutable live release acceptance record created only after the learner runtime can reconstruct the exact closed 10-LAB / 50-decision release

CI never writes these live records.

## Deployment preflight proof

The production Firebase project is frozen to:

csp11-exam-platform

The Q17 preflight record is:

labProductionDeploymentPreflight/phase_l_population_v1_q17_preflight_v1

The preflight record is only writable by an authenticated admin under the new Q17 Firestore rules.

Because all unknown Firestore paths are denied, the app cannot create this record while older Q16 rules are still deployed. A successful preflight write therefore acts as a practical deployment sentinel for the Q17 ruleset.

The preflight binds:

- Firebase project ID
- frozen Q16 closure SHA
- frozen Q16 validation run
- population manifest ID
- deterministic manifest fingerprint
- live Q16 operator state
- admin actor
- verification timestamp
- exactly 10 LABs
- exactly 50 decisions
- tamper-evident preflight fingerprint

## Hard release gate

Q17 wraps the frozen Q16 release operator.

The guarded operator refuses both:

- initial Q14 seed + Q15 closure
- Q15 closure-only recovery

unless valid Q17 preflight evidence already exists.

This moves the deployment check from guidance into the service boundary.

## Live release acceptance

After the Q16 state becomes CLOSED, Q17 acceptance reloads the production learner runtime through the Q15 release barrier.

It verifies:

- learner catalogue contains exactly 10 identities
- identities exactly match the population manifest
- every exact LAB/version loads through the production learner runtime
- total delivered decisions equal 50
- Q15 release evidence reports 10 LABs and 50 decisions
- Q17 preflight evidence is present

It then writes:

labProductionReleaseAcceptance/phase_l_population_v1_q17_acceptance_v1

The acceptance record binds the Q17 preflight fingerprint and the Q15 release evidence fingerprint.

It is admin-only, create-once and immutable.

## Admin workflow

Admin -> Publishing now opens:

LAB Deployment & Acceptance

The sequence is:

Q17 deployment preflight
-> Q16 production release control
-> Q17 live release acceptance

The Q16 production control cannot open from the supported Admin flow until preflight exists.

## Rules deployment boundary

The repository can validate the rules, builds and runtime contracts, but the production Firestore rules still require an authenticated deployment action outside CI.

From the exact Q17 validated source:

firebase deploy --only firestore:rules --project csp11-exam-platform

No service-account secret is embedded in the Flutter app.

After rules deployment, an authenticated CSP11 admin runs RUN DEPLOYMENT PREFLIGHT in the app. If the immutable preflight marker cannot be written and reread, production release remains blocked.

## Production runbook

1. Use the exact Q17 validated source/build.
2. Deploy firestore.rules to csp11-exam-platform.
3. Sign in to CSP11 as an existing admin.
4. Open Admin -> Publishing.
5. Confirm environment shows firebase_project:csp11-exam-platform.
6. Run RUN DEPLOYMENT PREFLIGHT.
7. Record the preflight fingerprint.
8. Open the Q16 production release control.
9. Follow the Q16 state-specific instruction:
   - PRISTINE -> RELEASE 10 LABS
   - COMPLETE_UNCLOSED -> CLOSE 10 LABS
   - CLOSED -> no release mutation
   - BLOCKED_PARTIAL -> stop
10. Return to LAB Deployment & Acceptance.
11. Confirm live state CLOSED.
12. Run RUN LIVE RELEASE ACCEPTANCE.
13. Record the acceptance fingerprint.

A production release is not considered live-accepted until step 12 succeeds.

## Build preflight

Q17 validation adds:

- Android release APK build
- Web release build

These are buildability gates only. They do not deploy an APK, web site, Firebase rules or Firestore data.

## Recovery semantics

If preflight fails:

- do not execute Q16 release
- verify Firebase project and deployed Firestore rules
- do not create markers manually

If Q16 reports BLOCKED_PARTIAL:

- stop
- preserve Firestore state and logs
- do not delete or overwrite immutable documents

If release is CLOSED but live acceptance fails:

- do not reseed
- do not rewrite Q15 evidence
- diagnose learner-runtime visibility or data-path failure
- rerun only Q17 acceptance after the issue is resolved

## Files

Added:

- lib/features/lab/lab_production_deployment_acceptance.dart
- lib/screens/admin/lab/lab_production_deployment_screen.dart
- test/lab_quality/lsp_q17_production_deployment_acceptance_test.dart
- docs/lab/LSP_Q17_PRODUCTION_DEPLOYMENT_ACCEPTANCE.md

Updated:

- lib/screens/admin/admin_home_screen.dart
- firestore.rules
- .github/workflows/lsp_unified_lab_question_validation.yml

## Validation

Dedicated Q17 coverage verifies:

1. preflight pins Q16 SHA and validation run
2. preflight pins csp11-exam-platform
3. preflight validates 10 LABs and 50 decisions
4. guarded Q16 release refuses execution before preflight
5. live acceptance reconstructs the exact 10-LAB learner runtime
6. live acceptance totals exactly 50 decisions
7. acceptance is tied to Q15 evidence and Q17 preflight fingerprints
8. Firebase configuration and content asset contract are pinned
9. Firestore preflight and acceptance paths are immutable
10. Admin Publishing routes through Q17

All Q1-Q16 gates and the full repository regression remain mandatory.

## Closure condition

LSP-Q17 code closure requires dedicated Q17 tests, all prior LSP-Q gates, static analysis, Android release build, Web release build, full repository regression, diff hygiene and canonical formatting to be green on the exact Q17 closure SHA.

Live production acceptance is a separate operational result. It requires the real rules deployment, admin execution and persisted Q17 acceptance evidence in csp11-exam-platform.
