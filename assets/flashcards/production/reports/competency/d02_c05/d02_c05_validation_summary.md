# FCP-2E — d02_c05 Validation Summary

Status: CLOSED CANDIDATE  
Gate: `FCP2E_D02_C05_GREEN`

Package validation:

```text
SHA: cc58d577877d8fbb88a71cda32f6e2fc479ad684
Run: 35970245287
Result: SUCCESS
```

Results:

- 12 accepted concepts
- 12 learner-ready cards
- 4 cross-competency canonical references
- FCQ100: 100 / 100
- deterministic JSON round trip: PASS
- provenance: PASS
- duplicate gate: PASS
- HOLD: 0
- unresolved concepts: 0
- frozen Flashcard Core regression: PASS
- full repository regression: PASS

Initial run `35968953529` correctly blocked FCQ-021 because two cards used the weaker Appendix C guidance as primary while the stronger regulation was supporting evidence. Provenance ordering was corrected without changing learner content, and run `35970245287` passed all gates.

The closure metadata commit must pass CI before `phase-fcp2e-d02-c05-closed` is created.
