# CSP11 Flashcard Core - FC Run 8 Status

**Phase:** FC - Flashcard Core  
**Run:** 8 of 8  
**Implementation branch:** `phase-fc8-hardening`  
**Starting point:** protected `agentic-pdca-m2-closed` at `b18e8297c3ed5589db95e609dfa5d3bfead0e7bf`  
**Frozen FC7 checkpoint:** `phase-fc7-closed` at `e6d1c28fe7b7428267c343068f4471671a765dd8`  
**Pre-closure validated implementation:** `eeaad1d2d02c3aaf3c09f39ed277185624542c93`  
**Validation evidence:** Phase FC Flashcard Core Validation Run 73 - SUCCESS  
**Target final branch:** `phase-fc-closed`  
**Status:** FC8_HARDENING_GREEN

## Why FC8 starts from the M2-closed SHA

The protected M2 checkpoint is a descendant of FC7 and therefore preserves all
FC1-FC7 implementation while also retaining later validated app work,
including the accepted Flashcard source-footer accessibility hardening.

FC8 does not rebuild FC1-FC7.

## Closure evidence already inherited

The existing regression suite covers:

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

## FC8 hardening evidence

FC8 closes the remaining hardening gaps with dedicated proof for:

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
   - 360/390/412/430 px phone widths;
   - tablet 900 px;
   - light and dark parity;
   - 2.0x text scaling;
   - reduced-motion environment;
   - large-text-safe Daily Discovery actions, metric chips and status chips;
   - existing Pilot B source-footer semantics regression remains in the suite.

4. **Cross-phase contract reconciliation**
   - obsolete pre-FC placeholder contracts were replaced with contracts for the
     implemented collection and review engine;
   - Flashcard motion remains centralized through the shared motion system;
   - Flashcard haptics remain centralized through `Csp11Haptics`;
   - LAB learner UI still does not render internal option quality;
   - the dark Flashcard screen delegates to the shared glass-scaffold screen.

5. **Final workflow**
   - FC formatting gate;
   - analyzer with warnings/errors fatal;
   - all FC1-FC7 targeted regressions;
   - FC8 hardening tests;
   - frozen HAP/MOT regressions;
   - full repository `flutter test` regression.

## Pre-closure validation result

Phase FC Flashcard Core Validation Run 73 passed on
`eeaad1d2d02c3aaf3c09f39ed277185624542c93`.

That run proved the complete FC validation chain and the full repository
regression green before this closure-status update.

## Exact-SHA closure rule

This document is intentionally closure-bearing. The `FC8_HARDENING_GREEN`
status becomes effective only if the exact commit containing this document
passes the same Phase FC workflow.

No later commit may inherit that proof implicitly.

After this status-bearing exact SHA passes:

1. create `phase-fc-closed` at that exact SHA;
2. protect `phase-fc-closed`;
3. treat that protected exact SHA as the FC recovery and closure point.

Until all three conditions are satisfied, Phase FC is not finally closed.
