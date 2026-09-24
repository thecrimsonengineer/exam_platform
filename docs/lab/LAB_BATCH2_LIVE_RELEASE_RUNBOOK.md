# LAB Batch 2 Live Release Runbook

Status: PREPARED, NOT EXECUTED

## Frozen prerequisites

- Pre-catalogue freeze:
  - branch: `phase-lsp-batch2-precatalogue-closed`
  - SHA: `4aa151a749b2324e9edd69a40781d7f8169a72c0`
  - validation run: `36015831093`
- Catalogue integration freeze:
  - branch: `phase-lsp-batch2-catalogue-integration-closed`
  - SHA: `674b5206647d217d2026193845fcff98f408d880`
- Publication operator candidate:
  - branch: `phase-lsp-batch2-publication-operator`
  - checkpoint SHA: `db327a3cf26106496747927f8a3608122b7ed8cc`
  - final reproducibility run: `36043520853`

## Live-release order

1. Confirm the final publication-operator reproducibility run is green.
2. Freeze the publication operator from the exact green SHA.
3. Deploy the matching `firestore.rules` to Firebase project `csp11-exam-platform`.
4. Re-authenticate as an admin user in CSP11.
5. Open Admin -> LAB Production Release.
6. Confirm the original release state is `CLOSED`.
7. Open `LAB Batch 2 Release`.
8. Confirm the Batch 2 state is `READY`, with:
   - published: `0/10`
   - catalogue: `0/10`
   - original release closed: `true`
9. Type the exact phrase:
   `RELEASE BATCH 2 10 LABS`
10. Publish once.
11. Require the resulting Batch 2 state to become `CLOSED`.
12. Verify:
   - 10 new `labPublishedVersions`
   - 10 new `labLearnerCatalogue` entries
   - Batch 2 immutable release evidence
   - Batch 2 release-state document with `released == true`
   - learner-side catalogue includes the original 10 plus the new 10
13. Do not retry publication after `CLOSED`.

## Fail-closed stop conditions

Stop without attempting repair when any of these occur:

- original release is not `CLOSED`
- Batch 2 state is `BLOCKED_PARTIAL`
- any Batch 2 published or catalogue identity already exists before release
- Batch 2 evidence exists without a matching release-state marker
- release-state marker exists without matching evidence
- the exact confirmation phrase is rejected
- Firestore rules are not deployed from the same frozen publication source
- post-publication verification does not report all 10 Batch 2 identities

Automatic overwrite, repair, partial continuation, or a second publication attempt is forbidden.

## Firestore rules deployment

From the exact frozen publication source:

```powershell
firebase deploy --only firestore:rules --project csp11-exam-platform
```

The deployment must complete successfully before opening the Batch 2 publication screen.

## Production boundary

This runbook does not itself deploy Firestore rules or publish any LAB. The only production write is the explicitly confirmed Batch 2 atomic publication from the admin operator after all prerequisites are green.
