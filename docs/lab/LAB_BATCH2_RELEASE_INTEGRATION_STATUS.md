# Batch 2 LAB Release Integration

Status: CLOSED AND RELEASE-READY

## Release intent

Only the second validated 10-LAB population may become learner-visible.

The original first 10 LABs remain hidden from learners and are retained for further authoring/review work.

## Frozen architecture

- Batch 2 is independent of the original first-10 Q17 acceptance.
- Batch 2 Q16 publishes immutable technical versions and stages learner catalogue entries.
- Q16 creates no learner-visible catalogue entries.
- Batch 2 Q17 records immutable admin acceptance.
- Q17 atomically creates the learner-visible Batch 2 marker and activates exactly the staged 10 catalogue entries.
- Production learner catalogue queries are pinned to the Batch 2 release ID.
- Direct learner reads of published LAB versions require the corresponding accepted Batch 2 catalogue entry.
- Original first-10 catalogue entries and published versions are not learner-readable.
- Detailed Q16/Q17 evidence remains admin-only.
- Learners read only the minimal Batch 2 Q17 visibility marker.

## Validated checkpoint

Release-ready source SHA: `7535d343340c9e0128324eab454c527fc75d4ef4`

First hardened green run: `36057436701`

Committed-artifact reproducibility run: `36059704566`

Reproducibility result:
- Firestore rules compile: PASS
- Batch 2 pre-catalogue regression: PASS
- Batch 2 release integration: PASS
- Original Q16 regression: PASS
- Original Q17 regression: PASS
- Q13 persistent runtime regression: PASS
- Q15 legacy release regression: PASS
- Full repository regression: 3,243 passed, 1 skipped, 0 failed
- Diff hygiene: PASS
- Canonical formatting persistence: PASS

## Release boundary

This closure does not itself deploy Firestore rules, publish Batch 2 to live Firestore, or activate learner visibility.

The live release sequence is:

1. Deploy the validated Firestore rules.
2. Run Batch 2 Q16 from the admin Batch 2 Release surface.
3. Verify Q16 CLOSED with 10 published and 10 staged entries.
4. Run Batch 2 Q17 acceptance.
5. Verify exactly 10 Batch 2 learner catalogue entries are active.
6. Verify the original first 10 remain hidden from learner reads.
