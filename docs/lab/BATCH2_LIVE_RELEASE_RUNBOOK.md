# Batch 2 LAB Live Release Runbook

Release branch: `release-batch2-labs-only`

Frozen integration closure: `phase-lsp-batch2-release-integration-closed@fc015ae2626cce59c57362a38b49da70881dbfb0`

Validated source: `7535d343340c9e0128324eab454c527fc75d4ef4`

Reproducibility run: `36059704566`

Result: 3,243 passed, 1 skipped, 0 failed.

## Intended learner state

Only the new Batch 2 population may become learner-visible.

The original first 10 LABs remain retained for admin/rework purposes but are blocked from learner catalogue and direct published-version reads.

## Live sequence

1. Check out `release-batch2-labs-only`.
2. Ensure the working tree is clean.
3. Run `powershell -ExecutionPolicy Bypass -File tools/lab/START_BATCH2_LIVE_RELEASE.ps1`.
4. The script deploys Firestore rules only and starts the validated Flutter app on Chrome.
5. Log in as an admin.
6. Open **Batch 2 Release**.
7. Q16 must show `PRISTINE` before first execution.
8. Type `RELEASE BATCH 2 LABS`.
9. Run Q16 and refresh.
10. Require `CLOSED`, `Published 10/10`, and `Staged catalogue 10/10`.
11. Q17 must then show `READY`.
12. Type `ACCEPT BATCH 2 LIVE RELEASE`.
13. Confirm the final acceptance dialog.
14. Require `ACCEPTED` and `Activated learner catalogue 10/10`.
15. Log in with a learner account and verify exactly the new 10 LABs are listed.
16. Verify none of the original first 10 are listed or directly openable.

## Stop conditions

Stop immediately if:
- Q16 is `BLOCKED`.
- Q16 reports a partial population.
- Published or staged count is not exactly 10.
- Q17 is not `READY` after Q16 closes.
- Q17 does not finish at `ACCEPTED`.
- Learner catalogue count is not exactly 10.
- Any original first-10 LAB becomes learner-visible.

Do not use the legacy Publishing or Release Acceptance screens for this release.
