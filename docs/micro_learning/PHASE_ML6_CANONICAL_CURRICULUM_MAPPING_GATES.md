# CSP11 Phase ML-6 - Canonical Curriculum Mapping Gates

Status: IMPLEMENTED  
Parent: `docs/micro_learning/PHASE_ML5_COPYRIGHT_PROVENANCE_GATES.md`  
Branch: `phase-ml6-canonical-curriculum-mapping-gates`

## Purpose

ML-6 proves that MicroFact curriculum placement is real, canonical and reviewable.

ML-5 answers:

> Is this MicroFact legally and provenance-wise suitable to publish?

ML-6 answers:

> Does this fact actually belong to the CSP11 curriculum location it claims, and is that location still canonical and active?

A syntactically valid ID is not enough.

## Authoritative hierarchy

Domain and Competency authority remains:

```text
docs/source_pipeline/CSP11_canonical_blueprint.json
        ↓
lib/data/csp11_blueprint.dart
```

The canonical blueprint defines:

- exactly 7 CSP11 Domains;
- exactly 47 Competencies;
- canonical Domain IDs `d01` through `d07`;
- canonical Competency IDs such as `d01_c01`;
- exact Domain-to-Competency parentage.

Topic and Subtopic authority is separate:

```text
content/micro_learning/canonical_curriculum_registry_v1.json
```

No Topic or Subtopic is treated as canonical merely because it exists in a content package, Firestore, Supabase, a local draft or an imported JSON file.

## Current production navigation state

The ML-6 production navigation registry currently declares:

```text
populationStatus = domain_competency_only
topicCount = 0
subtopicCount = 0
```

This is deliberate.

The repository already has authoritative Domain/Competency structure, but it does not yet contain a frozen globally authoritative Topic/Subtopic catalogue for every competency.

ML-6 therefore blocks any production MicroFact that attempts to map to an unregistered Topic or Subtopic.

This is safer than inventing canonical navigation nodes from legacy content files.

A future controlled registry update may populate Topic/Subtopic nodes.

## Delivered artifacts

- `content/micro_learning/canonical_curriculum_policy_v1.json`
- `content/micro_learning/canonical_curriculum_registry_v1.json`
- `content/micro_learning/curriculum_mapping_evidence_schema_v1.json`
- `lib/services/micro_learning/canonical_curriculum_policy_validator.dart`
- `lib/services/micro_learning/canonical_curriculum_registry_validator.dart`
- `lib/services/micro_learning/curriculum_mapping_evidence_validator.dart`
- `lib/services/micro_learning/micro_fact_curriculum_gate_validator.dart`
- `test/fixtures/micro_learning/valid_mapped_micro_fact_v1.json`
- `test/fixtures/micro_learning/canonical_curriculum_registry_test_v1.json`
- `test/fixtures/micro_learning/valid_curriculum_mapping_evidence_v1.json`
- ML-6 adversarial tests
- `tool/validate_micro_learning_curriculum_gates.dart`
- this closure document

## Prerequisite chain

ML-6 composes the complete earlier quality chain:

1. ML-1 approved authority
2. ML-2 valid MicroFact structure
3. ML-3 genuine first-party source
4. ML-4 correct factual/legal representation
5. ML-5 acceptable copyright/provenance evidence
6. ML-6 frozen curriculum policy
7. ML-6 frozen navigation registry
8. ML-6 mapping evidence
9. ML-6 exact fact-to-curriculum binding

No ML-6 result can bypass ML-1 through ML-5.

## General scope

For:

```text
curriculum.scope = general
```

all of these must be null:

- domainId
- competencyId
- topicId
- subtopicId

A general fact must not carry curriculum mapping evidence.

This prevents a fact from being labelled `general` while quietly influencing competency-specific rotation.

## Mapped scope

For:

```text
curriculum.scope = mapped
```

ML-6 requires:

- canonical Domain ID;
- canonical Competency ID;
- exact Domain→Competency parentage.

Topic and Subtopic are optional.

Therefore these are valid mapping depths:

```text
Domain + Competency
Domain + Competency + Topic
Domain + Competency + Topic + Subtopic
```

A Subtopic can never exist without its Topic.

## Canonical IDs only

MicroFacts may use only canonical identifiers:

```text
Domain      d01
Competency  d01_c03
Topic       d01_c03_t01
Subtopic    d01_c03_t01_s01
```

Legacy identifiers such as:

```text
domain_01
domain_01_03
```

are not accepted in MicroFact curriculum mapping.

Legacy compatibility remains an application-import concern. It does not become canonical MicroFact identity.

## Domain and Competency existence

ML-6 resolves Domain and Competency against the generated canonical registry.

A structurally valid ID such as:

```text
d01_c99
```

still fails because it does not exist in the CSP11 blueprint.

A real Competency also fails if attached to the wrong Domain.

## Topic and Subtopic registry

Topic/Subtopic mappings are valid only when explicitly present in the frozen navigation registry.

Registry topics carry:

- id
- domainId
- competencyId
- title
- lifecycle status
- nested Subtopics

Allowed node statuses are:

- active
- deprecated
- retired

Only:

```text
active
```

may receive new MicroFact mappings.

Deprecated and retired nodes fail closed.

## No inference

The frozen policy prohibits creating or repairing a curriculum mapping from:

- title similarity;
- tags;
- concept IDs;
- source text;
- source authority;
- old content IDs;
- AI classification;
- runtime network lookup.

ML-6 does not silently move a fact to the “closest” competency.

Unknown or stale placement is blocked for review.

## Mapping evidence

Validated, published and review-due mapped facts require a separate mapping-evidence record.

Startup-eligible mapped facts also require evidence.

The evidence is bound to:

- microFactId
- contentVersion
- blueprintVersion
- navigationRegistryVersion
- scope
- domainId
- competencyId
- topicId
- subtopicId
- exact deterministic mappingKey

Example:

```text
d01|d01_c03|d01_c03_t01|d01_c03_t01_s01
```

Competency-only mapping uses:

```text
d01|d01_c03|-|-
```

## Human placement review

A passing mapping-evidence record requires:

```text
humanReviewed = true
conceptAlignmentConfirmed = true
placementRationale = non-empty
reviewedAt = valid date
nextReviewDueAt = valid date
```

Allowed reviewer roles are:

- curriculum_reviewer
- content_governance_reviewer
- subject_matter_reviewer

The evidence record stores a role, not personally identifying reviewer details.

## Lifecycle gates

For mapped facts:

- `validated` requires mapping evidence
- `published` requires mapping evidence
- `review_due` requires mapping evidence
- startup eligibility requires mapping evidence

Evidence must be `pass` for:

- validated
- published
- startup-eligible use

## Mapping drift

Old mapping evidence becomes invalid when any of these change:

- MicroFact contentVersion
- Domain ID
- Competency ID
- Topic ID
- Subtopic ID
- navigation registry version
- blueprint version
- node lifecycle state

A fact cannot keep an old approval after being moved to another curriculum location.

## Review chronology

ML-6 rejects evidence when:

- mapping review occurs after the final MicroFact review;
- mapping evidence was already stale when the MicroFact was reviewed;
- mapping evidence exceeds the frozen 365-day maximum age.

## Navigation node deprecation

Even perfectly matching historical evidence cannot keep a mapping alive after its Topic or Subtopic becomes deprecated or retired.

The node lifecycle gate is checked at validation time.

This implements:

```text
nodeDeprecationInvalidatesEvidence = true
```

## Production versus test navigation registry

The production registry deliberately contains no Topic/Subtopic nodes yet.

The test-only registry:

```text
test/fixtures/micro_learning/canonical_curriculum_registry_test_v1.json
```

contains active, deprecated and retired nodes solely to exercise ML-6 behavior.

Those test nodes are not production curriculum authority.

## Network behavior

ML-6 is completely local and deterministic.

It adds:

- no Firebase read;
- no Supabase read;
- no HTTP lookup;
- no runtime AI classification;
- no startup delay.

## Test coverage

ML-6 tests include:

- frozen policy validity;
- policy unknown-field tampering;
- title-inference enabling;
- legacy-ID enabling;
- automatic-remap enabling;
- blueprint count drift;
- canonical ID-pattern broadening;
- deprecated-node selection weakening;
- evidence-age weakening;
- drift-rule weakening;
- production empty navigation registry;
- test registry with explicit nodes;
- topic-count mismatch;
- population-state mismatch;
- unknown Topic competency;
- wrong Domain→Competency parent;
- wrong Topic ID parent;
- wrong Subtopic ID parent;
- navigation registry policy weakening;
- valid mapping evidence;
- evidence unknown field;
- mapping-key mismatch;
- Subtopic without Topic;
- pass without human review;
- pass without concept alignment;
- reversed review dates;
- blueprint-version drift;
- navigation-registry-version drift;
- general fact without evidence;
- general fact carrying IDs;
- general fact carrying mapping evidence;
- competency-level mapped fact;
- full Topic/Subtopic mapped fact;
- unknown canonical Competency;
- wrong Competency parent;
- unregistered Topic;
- unregistered Subtopic;
- deprecated Topic;
- retired Subtopic;
- missing mapping evidence;
- wrong content-version evidence;
- mapping-ID drift;
- non-passing startup mapping evidence;
- mapping review after final fact review;
- formal evidence schema fail-closed marker.

## Deliberately deferred

ML-6 does not populate the production Topic/Subtopic catalogue.

That requires a separate controlled curriculum-registration operation after canonical learner-navigation content has been reviewed.

ML-6 also does not implement:

- startup readability/pedagogy/accessibility gates - ML-7;
- semantic duplicate and contradiction detection - ML-8;
- production MicroFact authoring - ML-9;
- runtime repository/selector integration - ML-10 onward.

## Verification

From repository root:

```powershell
dart run tool/validate_micro_learning_curriculum_gates.dart
```

Expected output begins:

```text
ML-6 CANONICAL CURRICULUM MAPPING GATES VALID
```

The closure workflow also runs the complete ML-1 through ML-6 focused regression plus the existing canonical CSP11 blueprint identity tests.

## Exit criteria

- [x] Frozen ML-6 curriculum policy created.
- [x] BCSP canonical blueprint retained as Domain/Competency authority.
- [x] Generated Dart blueprint registry retained as runtime representation.
- [x] Frozen Topic/Subtopic navigation registry created.
- [x] Current production navigation population state made explicit.
- [x] Unknown navigation nodes fail closed.
- [x] General scope semantics enforced.
- [x] Mapped scope semantics enforced.
- [x] Domain existence enforced.
- [x] Competency existence enforced.
- [x] Domain→Competency parentage enforced.
- [x] Topic registration enforced.
- [x] Topic parentage enforced.
- [x] Subtopic registration enforced.
- [x] Subtopic parentage enforced.
- [x] Deprecated/retired navigation nodes blocked.
- [x] Legacy MicroFact curriculum IDs blocked.
- [x] Automatic inference/remap blocked.
- [x] Separate mapping evidence schema created.
- [x] Mapping evidence bound to exact fact/version.
- [x] Mapping evidence bound to blueprint and registry versions.
- [x] Deterministic mapping fingerprint enforced.
- [x] Human concept-alignment review enforced.
- [x] Mapping review chronology enforced.
- [x] Evidence freshness enforced.
- [x] Mapping drift invalidates evidence.
- [x] No runtime network dependency added.
- [x] No production MicroFacts generated.
- [x] No startup UI changed.

## Next run

ML-7 - Startup Pedagogy / Readability / Accessibility Gates.

ML-7 should determine whether a fully sourced, legally represented, rights-cleared and canonically mapped fact is actually suitable to show during a short startup window.
