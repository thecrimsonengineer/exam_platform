# CSP11 Phase ML-0 — Micro-Learning Startup Architecture Freeze

Status: FROZEN BASELINE  
Phase: ML-0  
Branch: `phase-ml-micro-learning`  
Purpose: Freeze the architecture contract for CSP11 startup micro-learning before implementation of source registries, schemas, validators, content, selection logic, or UI.

## 1. Objective

CSP11 shall use unavoidable startup/authentication time as an optional micro-learning surface without changing the security-critical startup path.

The learner may see one concise, professionally sourced micro-learning item while CSP11 performs real online-access verification. The educational surface is supplemental only. It must never delay, weaken, simulate, or replace authentication.

## 2. Architectural invariants

The following rules are non-negotiable for all later ML phases.

1. Authentication and secure-access verification remain the primary startup responsibility.
2. Micro-learning runs independently from authentication.
3. Micro-learning must never delay navigation after startup verification succeeds.
4. Failure of micro-learning must never fail authentication or block Home.
5. Startup facts are local-first and require zero backend reads solely to obtain a fact.
6. The app must remain capable of showing no fact when no eligible fact passes all gates.
7. Only `published` and `startupEligible=true` facts may appear.
8. AI may assist authoring, classification, review support, or paraphrasing, but AI is never an authority or source.
9. No technical micro-fact may use a source outside the approved CSP11 Authority Registry.
10. All technical claims must preserve their authority type, legal status, jurisdiction, context, conditions, edition/revision, and provenance.
11. Regulatory requirements, consensus standards, guidance, recommendations, research findings, and professional-practice principles must not be conflated.
12. Accuracy outranks brevity.
13. If a concept cannot be expressed accurately within startup constraints, it is not startup-eligible.
14. Assessment leakage is prohibited.
15. Numerical and safety-critical claims require enhanced review.
16. Content publication is fail-closed.
17. Content lifecycle is versioned and auditable.
18. Accessibility and reduced-motion behavior are first-class requirements.
19. Startup behavior must remain deterministic enough to test and reproduce.
20. No later ML run may weaken these invariants without an explicit architecture-change phase.

## 3. Core fail-closed rule

> CSP11 shall prefer showing no micro-learning fact over showing a fact whose accuracy, authority, currency, context, legal status, provenance, copyright status, curriculum relevance, or display suitability cannot be demonstrated.

## 4. Approved authority boundary

The future Source Registry may contain only the following source families unless a later architecture-change phase explicitly amends this list.

| Registry family | Approved authority | Primary role |
|---|---|---|
| SRC-01 | OSHA / U.S. Department of Labor | Federal OSHA regulations, interpretations, technical guidance, PSM, LOTO, confined spaces, electrical safety, construction, PPE, recordkeeping |
| SRC-02 | NIOSH / CDC | Occupational exposure, industrial hygiene, engineering controls, respirators, ergonomics, heat stress, noise, disease prevention, HHE/research |
| SRC-03 | ANSI / ASSP | Z10, risk assessment, fall protection, confined spaces, construction, management systems, professional practice |
| SRC-04 | ISO | ISO 45001, ISO 14001 family, ISO 19011, relevant management/risk concepts |
| SRC-05 | NFPA | Fire, electrical, life safety, flammables/combustibles, fire-protection systems |
| SRC-06 | ACGIH | TLVs/BEIs, exposure assessment, industrial hygiene, physical agents, heat stress |
| SRC-07 | AIHA | Exposure assessment strategy, sampling, controls, occupational-health practice |
| SRC-08 | EPA | Environmental management, hazardous waste, releases, RCRA, CERCLA, Clean Air Act, Clean Water Act |
| SRC-09 | DOT / PHMSA / FMCSA | Hazardous-material transportation, shipping, fleet/driver safety, pipeline/transport context |
| SRC-10 | FEMA / DHS / NIMS / ICS | Emergency management, incident command, preparedness, coordination, continuity |
| SRC-11 | AIChE / CCPS | Process safety, RBPS, MOC, PHA/HIRA, asset integrity, process hazards |
| SRC-12 | National Safety Council | Occupational safety, accident prevention, industrial hygiene, professional practice |
| SRC-13 | ASSP professional literature | Safety engineering, risk, professional safety practice, technical applications |
| SRC-14 | FM / FM Global | Property-loss prevention, fire protection, facility/equipment loss-control guidance |
| SRC-15 | UL / UL Standards & Engagement / UL Solutions | Product safety, certification/testing, electrical/fire equipment and standards |

Unapproved sources include, without limitation: generic blogs, commercial training summaries, Wikipedia, forums, Reddit, unattributed notes, answer sites, generic AI output, or secondary summaries used in place of an available primary authority.

## 5. Source semantics

Each fact must carry a source/claim classification sufficient to prevent false authority.

Minimum classifications include:

- federal_regulation
- regulatory_interpretation
- enforcement_or_compliance_guidance
- government_recommendation
- research_or_prevention_guidance
- consensus_standard
- international_standard
- professional_guideline
- professional_framework
- environmental_regulation
- transportation_regulation
- emergency_management_framework
- process_safety_framework
- loss_prevention_guidance
- testing_or_certification_standard

The renderer may show a simplified source label, but the stored metadata must preserve the full classification.

## 6. Prohibited authority distortions

The system must reject or block publication when wording would:

- describe a NIOSH recommendation as an OSHA requirement;
- describe an ACGIH TLV/BEI as an OSHA PEL;
- describe a consensus standard as federal law;
- describe a professional framework as a regulation;
- describe an FM loss-prevention recommendation as statutory compliance;
- describe UL certification as equivalent to regulatory approval;
- omit jurisdiction when jurisdiction materially changes meaning;
- omit conditions/exceptions where omission changes the claim;
- use `shall`, `must`, `required`, `recommended`, or equivalent language inconsistently with the underlying authority.

## 7. Runtime separation

Startup has two concurrent logical paths.

```text
APP START
   |
   +--------------------------+
   |                          |
SECURE STARTUP PATH       MICRO-LEARNING PATH
   |                          |
bootstrap/auth/network      local repository
   |                          |
authorization              eligibility filter
   |                          |
startup decision            selector
   |                          |
   |                       MicroFactCard
   |                          |
   +-------------+------------+
                 |
         STARTUP RESULT
                 |
         HOME / ERROR FLOW
```

The secure path owns navigation. The micro-learning path never owns navigation.

## 8. Startup state contract

Security-facing startup states may include real states such as:

- initializing
- connecting
- verifying_access
- restoring_session
- authorization_check
- ready
- recoverable_error
- blocking_error

Micro-learning state is separate:

- idle
- selecting
- eligible_fact
- no_fact
- displaying
- dismissed_by_navigation

Micro-learning failure must collapse to `no_fact`, not to a startup error.

## 9. Display timing contract

The app shall not intentionally hold the learner on startup to complete animation or reading.

Guidance for later implementation:

- very fast startup: title/short variant may appear briefly or not at all;
- normal startup: one normal micro-fact may appear;
- slow startup: retain the same fact rather than rapidly cycling multiple facts;
- once secure startup is ready, navigation proceeds immediately.

Exact timing constants are implementation details and are not frozen in ML-0.

## 10. Future MicroFact minimum contract

ML-2 will define the exact schema, but the architecture requires support for at least:

- stable microFactId
- schemaVersion
- contentVersion
- lifecycle status
- category
- displayText
- optional shortVariant
- domainId
- competencyId
- optional topicId/subtopicId
- concept identifiers/tags
- difficulty or learner level where used
- claimType
- legalStatus/authorityType
- jurisdiction where relevant
- sourceRegistryId
- sourceAuthority
- sourceTitle
- edition/revision/date where relevant
- source location/section/page where available and lawful
- official source URL or canonical locator
- sourceVerifiedAt
- contentReviewedAt
- startupEligible
- simplificationRisk
- assessmentSensitivity
- review outcomes
- supersession/review-due metadata

## 11. Lifecycle contract

Allowed lifecycle concepts must support at minimum:

```text
draft
  -> review
  -> validated
  -> published
  -> review_due
  -> superseded / withdrawn
```

Rejected content may move to:

```text
draft/review -> rejected
```

Only `published` content can be startup-eligible.

No stale, review-due, superseded, withdrawn, rejected, draft, or merely validated item may be selected at runtime.

## 12. Quality-gate families

Later validators must implement hard checks across these families:

1. Source authority
2. First-party provenance
3. Source currency/edition
4. Claim support
5. Legal/authority classification
6. Jurisdiction/context
7. Conditional/exception preservation
8. Numerical accuracy and units
9. Safety-critical simplification risk
10. Copyright/IP
11. CSP canonical mapping
12. Pedagogical quality
13. Startup readability
14. Terminology precision
15. Duplicate detection
16. Semantic-overlap review
17. Contradiction detection
18. Source-specific rules
19. Freshness/review-due policy
20. Assessment leakage
21. Runtime eligibility
22. Rotation diversity
23. Accessibility
24. Human-review requirement

A hard BLOCK in any mandatory family makes the item non-publishable.

## 13. Copyright architecture

The system is designed around original CSP11 paraphrases and concise factual summaries, not reproduction of standards.

Mandatory architecture rules:

- do not store or display substantial copyrighted standard text as startup content;
- do not copy proprietary tables;
- do not reproduce protected clause text merely because it is technically accurate;
- preserve attribution;
- identify separately any content that is used under an explicit license;
- do not synthesize a near-verbatim derivative by stitching protected fragments together;
- government/public-source status does not remove the requirement for source attribution and context.

ML-5 will define enforceable provenance/IP fields and gates.

## 14. Curriculum integration

Every technical micro-fact must map into CSP11's canonical learning structure where applicable:

```text
Domain -> Competency -> Topic -> Subtopic -> Concept
```

Micro-learning does not create a second curriculum taxonomy.

The existing canonical registry remains authoritative. Invalid canonical IDs must block publication where mapping is required.

## 15. Selection architecture

Pure random selection is prohibited as the long-term production strategy.

The selector must eventually account for:

- lifecycle/eligibility
- source freshness
- recent impression history
- current learner competency
- previously studied concepts
- reinforcement need where available
- source diversity
- category diversity
- domain/concept diversity
- assessment sensitivity
- reduced repetition

The selection algorithm must remain testable. Learner-state weighting may influence eligible facts but may not bypass quality gates.

## 16. Personalization boundary

Permitted personalization sources:

- current learning position
- studied domains/competencies/topics
- practice/review state
- prior micro-fact impression history
- learning-plan context
- retention/reinforcement state where already legitimately available

Micro-learning must not rely on sensitive personal profiling.

## 17. Assessment leakage boundary

Startup content must not reveal or strongly cue answers to an imminent/active assessment.

The future schema/selector must support:

- linked concepts
- assessment sensitivity
- exclusion of facts that materially reveal active quiz answers
- conservative blocking where overlap is uncertain

## 18. Safety-critical and numerical claims

Enhanced review is mandatory for facts involving, for example:

- exposure limits
- ppm, mg/m3, dBA, dose, temperature, pressure, voltage
- required distances
- time intervals
- inspection frequencies
- percentages
- regulatory thresholds
- confined-space entry conditions
- electrical approach/shock/arc concepts
- fire/life-safety requirements
- chemical/process-safety limits
- emergency-response instructions

No inferred, approximated, or AI-invented technical value may be published.

## 19. Local-first runtime contract

The initial production design shall use a bundled/locally available approved fact set.

The startup fact must not trigger an extra Supabase, Firebase, or other network read solely for display.

Future content-update mechanisms may refresh the local bundle outside the startup critical path, but that is outside ML-0.

## 20. Performance invariants

Later implementation must preserve:

- no deliberate startup delay;
- no synchronous network request for micro-learning;
- no heavyweight semantic model at runtime solely for fact selection;
- bounded local selection work;
- graceful no-fact fallback;
- no repeated rebuild loop caused by micro-learning state;
- no animation requirement for successful startup completion.

Exact millisecond budgets will be established during implementation/regression phases after profiling.

## 21. Accessibility invariants

The design must support:

- screen-reader semantic order;
- sufficient contrast;
- scalable text;
- no information conveyed only by color;
- reduced-motion preference;
- no rapidly flashing content;
- readable layout on smallest supported device;
- graceful localization/long-text behavior;
- no requirement to interact with the fact before entering the app.

## 22. Animation boundary

Animation is decorative/supportive, not authoritative.

Allowed examples:

- subtle card fade/slide;
- secure indicator transition;
- source/category icon transition;
- ready-state transition.

Prohibited behavior:

- fake security scans;
- simulated checks that are not actually performed;
- animation that implies a security result before the secure path has resolved;
- animation that holds navigation after readiness;
- rapid fact carousels that prevent reading.

## 23. Error behavior

If micro-learning fails to initialize:

```text
micro-learning error -> log/diagnostic -> no_fact -> continue startup
```

If authentication fails:

```text
authentication error -> security/error UX
```

A fact card must not obscure, delay, or visually compete with a blocking security or authorization error.

## 24. Auditability

Every published fact must be traceable from rendered content back to:

- content version;
- review state;
- source registry entry;
- source locator;
- review date;
- source verification date;
- curriculum mapping;
- quality-gate result.

The runtime bundle must be versioned.

## 25. Content bundle boundary

Later runs are expected to establish a structure conceptually similar to:

```text
assets/micro_learning/
  source_registry.json
  micro_facts_v1.json
  micro_fact_manifest.json
```

Names are indicative until ML-1/ML-2 freeze their exact schemas and paths.

## 26. Human-review boundary

Human technical approval remains mandatory at initial launch for all technical facts.

Enhanced human review is permanently expected for high-risk categories, including:

- regulatory claims;
- numerical limits;
- electrical safety;
- confined spaces;
- process safety;
- fire/life safety;
- chemical compatibility;
- emergency-response instructions.

Automation may assist, but may not silently self-publish such content.

## 27. Security/privacy boundary

Micro-learning must not:

- log secrets/tokens;
- expose auth state through fact metadata;
- embed user PII into fact bundles;
- make learner identity part of fact content;
- transmit additional startup analytics unless separately designed and approved;
- weaken existing protected-delivery or authorization behavior.

## 28. Diagnostics boundary

Later implementation should make it possible to diagnose:

- selected fact ID;
- fact-bundle version;
- reason a fact was ineligible;
- selector fallback to no_fact;
- stale/review-due exclusion;
- duplicate/repetition exclusion.

Diagnostics must not expose secrets or copyrighted source content beyond permitted stored metadata.

## 29. Testability requirements

Future implementation must make each layer independently testable:

- source registry validator;
- MicroFact schema validator;
- quality gates;
- lifecycle validator;
- canonical mapping;
- selector eligibility;
- selector rotation/repetition;
- assessment leakage;
- stale/superseded filtering;
- startup widget rendering;
- reduced-motion behavior;
- auth/micro-learning independence;
- no-fact fallback;
- platform regression.

## 30. Explicitly deferred from ML-0

ML-0 does not implement or choose:

- exact JSON schema field names beyond architectural minimums;
- exact source registry file shape;
- actual facts;
- exact fact-count distribution;
- final UI visual design;
- exact animation asset format;
- exact timing constants;
- selector scoring constants;
- backend content-update mechanism;
- admin authoring UI;
- cloud synchronization strategy;
- learner-facing Micro-Learning Library.

Those belong to later phases.

## 31. Frozen implementation sequence

The approved execution order is:

- ML-0 — Architecture Freeze
- ML-1 — Authority Registry
- ML-2 — MicroFact Schema
- ML-3 — Source Gates
- ML-4 — Factual / Legal-Status Gates
- ML-5 — Copyright / Provenance Gates
- ML-6 — CSP Curriculum Mapping
- ML-7 — Pedagogical / Readability Gates
- ML-8 — Duplicate / Contradiction Detection
- ML-9 — First 120-Fact Curated Bank
- ML-10 — Local Repository
- ML-11 — Intelligent Selector
- ML-12 — Startup MicroFactCard
- ML-13 — Animation Choreography
- ML-14 — Learner-State Weighting
- ML-15 — Impression-History Control
- ML-16 — Accessibility / Reduced Motion
- ML-17 — Android / Web / Windows Regression
- ML-18 — Physical-Device Acceptance
- ML-19 — Freeze / Version Initial Release

No bulk fact generation begins before ML-0 through ML-8 are complete.

## 32. ML-0 exit criteria

ML-0 is complete only when:

- [x] micro-learning/security separation is defined;
- [x] fail-closed philosophy is defined;
- [x] authority boundary is defined;
- [x] authority-type/legal-status distinction is defined;
- [x] lifecycle boundary is defined;
- [x] quality-gate families are defined;
- [x] copyright boundary is defined;
- [x] curriculum-mapping boundary is defined;
- [x] selection/personalization boundary is defined;
- [x] assessment leakage boundary is defined;
- [x] numerical/safety-critical review boundary is defined;
- [x] local-first runtime requirement is defined;
- [x] accessibility/animation boundaries are defined;
- [x] security/privacy boundaries are defined;
- [x] deferred decisions are explicit;
- [x] later run sequence is frozen.

## 33. ML-0 change-control rule

After ML-0 closure, any change that weakens or materially alters an architectural invariant must be handled as an explicit architecture amendment. Later implementation phases may refine details but may not silently bypass this contract.

---

ML-0 establishes the contract only. ML-1 is the first implementation phase and must create the authoritative source registry under these frozen constraints.
