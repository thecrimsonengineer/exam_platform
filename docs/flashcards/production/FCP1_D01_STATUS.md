# FCP-1 — Domain 01 Production Status

Status: CLOSED CANDIDATE  
Gate: `FCP1_D01_GREEN`  
Recovery base: `phase-fcp0-production-spec-closed@42dd596449a6a1265a5fc505d4f32b26956c912c`  
Target checkpoint: `phase-fcp1-d01-closed`

## Competency sequence

```text
FCP-1A  d01_c01  CLOSED   8 cards
FCP-1B  d01_c02  CLOSED  11 cards
FCP-1C  d01_c03  CLOSED  14 cards
FCP-1D  d01_c04  CLOSED   9 cards
FCP-1E  d01_c05  CLOSED   9 cards
FCP-1F  d01_c06  CLOSED  14 cards
FCP-1G  d01_c07  CLOSED  13 cards
-------------------------------
TOTAL                78 cards
```

## Pre-closure validation evidence

```text
SHA: b34ce34f10ded57769f7697a39b9be38e8805ce7
GitHub Actions run: 35958681343
Result: SUCCESS
```

Passed gates:

- formatting
- Flutter analyze
- 7 / 7 D01 competency packages discovered
- 78 total cards
- FCQ100 = 100 / 100 for every package
- deterministic JSON round trip for every package
- provenance and exact-locator validation
- unique Deck / Concept / Flashcard IDs
- normalized canonical-label and alias collision gate
- all seven concept inventories resolved
- HOLD = 0
- complete per-competency report bundles
- frozen Flashcard Core regression
- full repository regression

The closure metadata commit must itself pass the dedicated FCP workflow before the recovery checkpoint branch is created.
