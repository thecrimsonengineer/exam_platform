# CSP11 Micro-Learning — Frozen Implementation Roadmap

Status: FROZEN  
Parent architecture: `docs/micro_learning/PHASE_ML0_ARCHITECTURE_FREEZE.md`

## Goal

Turn CSP11's secure online-access loading surface into an optional, authoritative, curriculum-linked micro-learning experience while preserving startup security, speed, accessibility, and reliability.

## Frozen run sequence

| Run | Scope | Exit |
|---|---|---|
| ML-0 | Architecture Freeze | Invariants and boundaries frozen |
| ML-1 | Authority Registry | Approved source registry validated |
| ML-2 | MicroFact Schema | Versioned schema frozen |
| ML-3 | Source Gates | Invalid/unapproved sources fail closed |
| ML-4 | Factual / Legal-Status Gates | Claim type, jurisdiction and authority semantics enforced |
| ML-5 | Copyright / Provenance Gates | Traceability and IP constraints enforced |
| ML-6 | CSP Curriculum Mapping | Canonical curriculum IDs validated |
| ML-7 | Pedagogical / Readability Gates | Startup suitability and precision enforced |
| ML-8 | Duplicate / Contradiction Detection | Overlap/conflict review works |
| ML-9 | First 120-Fact Curated Bank | 120 human-reviewed facts pass all gates |
| ML-10 | Local Repository | Startup facts available locally with no fact-only network read |
| ML-11 | Intelligent Selector | Deterministic eligible selection and diversity/repetition rules |
| ML-12 | Startup MicroFactCard | Responsive startup learning surface |
| ML-13 | Animation Choreography | Motion integrated without delaying startup |
| ML-14 | Learner-State Weighting | Eligible facts may be weighted by learning state |
| ML-15 | Impression-History Control | Repetition suppression and encounter history |
| ML-16 | Accessibility / Reduced Motion | Accessibility contract verified |
| ML-17 | Android / Web / Windows Regression | Cross-platform tests pass |
| ML-18 | Physical-Device Acceptance | Real-device startup behavior accepted |
| ML-19 | Freeze / Version Initial Release | Versioned release and recovery point |

## Global execution rules

- Fail closed.
- No bulk fact authoring before ML-8 is closed.
- No source outside the approved Authority Registry.
- AI is never the source.
- No startup fact may add a required backend read.
- Micro-learning cannot block or delay secure startup.
- One hard-gate failure makes a fact non-publishable.
- Only published, current, startup-eligible facts can render.
- Human technical review remains mandatory for initial technical content.
- High-risk technical claims retain enhanced human review.
- Existing CSP11 canonical curriculum IDs remain authoritative.
- Later runs may refine implementation details but may not weaken ML-0 invariants without an explicit architecture amendment.

## Initial release target

Initial curated bank target: 120 high-quality facts after the quality foundation is complete.

Suggested distribution remains planning guidance rather than a hard schema constraint:

- occupational safety: 25
- industrial hygiene: 20
- process safety: 15
- fire/electrical: 12
- management systems: 12
- environmental: 10
- emergency management: 8
- transportation/fleet: 6
- CSP reasoning tips: 6
- evidence-based learning tips: 6

Quality outranks count. A release with fewer facts is preferable to filling a quota with weak content.
