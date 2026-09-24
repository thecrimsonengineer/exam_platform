# Batch 2 LAB Release Integration

Status: REPRODUCIBILITY CANDIDATE

## Release intent

Only the second validated 10-LAB population may become learner-visible.

The original first 10 LABs remain hidden from learners and are retained for further authoring/review work.

## Validated architecture

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

## First hardened green run

Run: `36057436701`

Validated source SHA: `60894bf9ab0846b41816931d0d8b5a06605e997a`

Result:
- Firestore rules compile: PASS
- Batch 2 pre-catalogue regression: PASS
- Batch 2 release integration: PASS
- Original Q16 regression: PASS
- Original Q17 regression: PASS
- Q13 persistent runtime regression: PASS
- Q15 legacy release regression: PASS
- Full repository regression: 3,243 passed, 1 skipped, 0 failed
- Diff hygiene: PASS

CI canonical-format commit: `27a55a3bbac14e914e8f60634ca00521e1fddab6`

A clean reproducibility run on the formatted branch state is required before release closure.
