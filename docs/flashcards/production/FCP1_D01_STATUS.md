# FCP-1 — Domain 01 Production Status

Status: VALIDATING  
Recovery base: `phase-fcp0-production-spec-closed@42dd596449a6a1265a5fc505d4f32b26956c912c`

## Competency sequence

```text
FCP-1A  d01_c01  CLOSED
FCP-1B  d01_c02  CLOSED
FCP-1C  d01_c03  VALIDATING
FCP-1D  d01_c04  VALIDATING
FCP-1E  d01_c05  VALIDATING
FCP-1F  d01_c06  VALIDATING
FCP-1G  d01_c07  VALIDATING
```

All seven D01 competency packages are now authored.

Current cumulative production count:

```text
d01_c01   8
d01_c02  11
d01_c03  14
d01_c04   9
d01_c05   9
d01_c06  14
d01_c07  13
----------------
TOTAL     78
```

No competency after C02 is declared CLOSED until the complete D01 exact-SHA gate passes.

## D01 closure gate

The cumulative validation must prove:

- 7/7 competency packages discovered
- FCQ100 = 100/100 for every package
- deterministic JSON round-trip for every package
- global Deck/Concept/Flashcard IDs unique
- no normalized canonical-label or alias collision across D01
- all seven inventories resolved
- HOLD = 0
- frozen Flashcard Core regression passes
- full repository regression passes

Target gate:

```text
FCP1_D01_GREEN
```
