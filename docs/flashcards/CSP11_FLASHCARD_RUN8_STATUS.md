# CSP11 Flashcard Core - FC Run 8 Status

**Phase:** FC - Flashcard Core  
**Run:** 8 of 8  
**Implementation branch:** `phase-fc8-hardening`  
**Starting point:** protected `agentic-pdca-m2-closed` at `b18e8297c3ed5589db95e609dfa5d3bfead0e7bf`  
**Frozen FC7 checkpoint:** `phase-fc7-closed` at `e6d1c28fe7b7428267c343068f4471671a765dd8`  
**Target final branch:** `phase-fc-closed`  
**Status:** FC8_IMPLEMENTATION_CANDIDATE

## Why FC8 starts from the M2-closed SHA

The protected M2 checkpoint is a descendant of FC7 and therefore preserves all
FC1-FC7 implementation while also retaining later validated app work,
including the accepted Flashcard source-footer accessibility hardening.

FC8 does not rebuild FC1-FC7.

## Closure evidence already inherited

The existing regression suite already covers:

- source coverage and provenance fail-closed behavior;
- source-reference integrity;
- Question -> Concept mapping integrity;
- Concept -> Flashcard integrity;
- duplicate Concept/Card/mapping prevention;
- unlock idempotency and concurrent duplicate callbacks;
- no duplicate ownership;
- Daily Discovery determinism and all-owned empty-day behavior;
- learner-scoped local repositories;
- deterministic review intervals and session ordering;
- interruption/retry recovery without double-counting;
- HAP architecture;
- MOT FlipCard reduced-motion behavior;
- FC1, FC6 and FC7 architecture boundaries.

## New FC8 hardening evidence

This run adds dedicated proof for closure gaps:

1. **Closure matrix / zero backend**
   - learner-ready package source and identity integrity;
   - exact one-card-per-concept relationship;
   - Question mapping references;
   - whole Flashcard runtime/admin root scan for Firebase/Supabase;
   - learner UI persistence/scheduler ownership guard;
   - runtime LLM generation dependency guard.

2. **Large deck behavior**
   - deterministic 1,000-card due-deck planning;
   - unique output;
   - deterministic result regardless of input iteration order;
   - maxCards bounding.

3. **Responsive/accessibility hardening**
   - 360/390/412/430 px;
   - tablet 900 px;
   - light and dark parity;
   - 2.0x text scaling;
   - reduced-motion environment;
   - existing Pilot B source-footer semantics regression remains in the suite.

4. **Final workflow**
   - all FC1-FC7 targeted regressions;
   - FC8 hardening tests;
   - HAP/MOT frozen regressions;
   - analyzer with warnings/errors fatal;
   - full repository `flutter test` regression.

## Closure state

This status is not a closure claim.

FC8 becomes eligible for `FC8_HARDENING_GREEN` only after the status-bearing
candidate itself passes the updated Phase FC workflow.

`phase-fc-closed` must then be created at the final exact validated SHA and
protected before FC is treated as closed.
