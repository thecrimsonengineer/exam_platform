# FCP-1 — Domain 01 Production Status

Status: IN PROGRESS  
Recovery base: `phase-fcp0-production-spec-closed@42dd596449a6a1265a5fc505d4f32b26956c912c`

## Competency sequence

```text
FCP-1A  d01_c01  CLOSED
FCP-1B  d01_c02  CLOSED
FCP-1C  d01_c03  VALIDATING
FCP-1D  d01_c04  VALIDATING
FCP-1E  d01_c05  IN PROGRESS
FCP-1F  d01_c06  NOT STARTED
FCP-1G  d01_c07  NOT STARTED
```

C03 and C04 remain unclosed until a cumulative exact-SHA CI run passes all FCP production gates, the frozen Flashcard Core regression, and the full repository regression.

### FCP-1D package

```text
d01_c04
9 cards
OSHA 1910.36 / 1910.37 / 1910.22
status: VALIDATING
```

### FCP-1E current task

Resolve fleet-safety concepts using current GSA, DOE FEMP, FMCSA, and NHTSA federal guidance. GPS monitoring and driver-behavior monitoring remain candidate concepts until semantic review decides whether they are distinct collectible concepts or should merge under Fleet Telematics.
