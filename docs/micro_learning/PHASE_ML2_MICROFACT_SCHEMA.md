# CSP11 Phase ML-2 — MicroFact Schema

Status: IMPLEMENTED  
Parent: `docs/micro_learning/PHASE_ML1_AUTHORITY_REGISTRY.md`  
Branch: `phase-ml2-microfact-schema`

## Purpose

ML-2 freezes the versioned structural contract for one CSP11 micro-learning fact.

ML-2 defines what a MicroFact is. It does not yet prove that a source ID exists in the ML-1 registry, that a curriculum ID exists in the canonical CSP11 registry, that wording is pedagogically excellent, or that facts are semantically unique. Those responsibilities remain in ML-3, ML-6, ML-7 and ML-8.

## Delivered artifacts

- `content/micro_learning/micro_fact_schema_v1.json`
- `lib/models/micro_learning/micro_fact.dart`
- `lib/services/micro_learning/micro_fact_schema_validator.dart`
- `test/fixtures/micro_learning/valid_micro_fact_v1.json`
- `test/micro_learning/micro_fact_schema_validator_test.dart`
- `tool/validate_micro_learning_schema.dart`

The fixture is test-only. It is not part of the future published fact bank.

## Stable identity

`microFactId` is intentionally independent of curriculum placement.

A fact may be remapped from one topic or competency to another without changing its stable identity. This protects impression history, supersession links and future analytics.

MicroFact v1 IDs must match:

```text
mf_[a-z0-9][a-z0-9_-]{5,63}
```

## Root contract

Every MicroFact v1 contains exactly these root fields:

- `schemaVersion`
- `microFactId`
- `contentVersion`
- `status`
- `category`
- `display`
- `curriculum`
- `provenance`
- `claim`
- `assessment`
- `review`
- `runtime`
- `supersession`
- `tags`

Unknown fields fail closed.

## Lifecycle states

Frozen ML-2 lifecycle vocabulary:

```text
draft
review
validated
published
review_due
superseded
withdrawn
rejected
```

Only a `published` fact may set `runtime.startupEligible=true`.

A published fact must have all review gates at `pass` and must contain both `reviewedAt` and `nextReviewDueAt`.

## Categories

Frozen category vocabulary:

- `safety_insight`
- `csp_tip`
- `learning_tip`
- `quick_recall`
- `think_about_it`
- `process_safety_insight`
- `ih_insight`
- `emergency_insight`
- `environmental_insight`
- `fire_electrical_insight`
- `management_insight`
- `transport_insight`

Category availability does not override the ML-1 authority whitelist. If an approved authority cannot support a proposed fact, that fact cannot be published simply because a category exists.

## Display object

`display` contains:

- `displayText`
- `shortVariant`
- `estimatedReadSeconds`

ML-2 applies broad structural limits only. The stricter startup readability, word-count and pedagogical rules belong to ML-7.

## Curriculum object

`curriculum.scope` is either:

- `mapped`
- `general`

Mapped facts use canonical-shaped IDs:

```text
domainId      d01 ... d07
competencyId  d##_c##
topicId       d##_c##_t##
subtopicId    d##_c##_t##_s##
```

ML-2 verifies hierarchy shape and parent-prefix consistency.

It does not yet prove that a particular ID exists in the canonical blueprint. ML-6 owns that check.

General facts must keep domain, competency, topic and subtopic placement null.

Every fact still requires at least one `conceptId`.

## Provenance object

Every MicroFact carries:

- `sourceRegistryId`
- `sourceClass`
- `sourceTitle`
- `officialUrl`
- `sourceLocator`
- `editionOrRevision`
- `sourceSection`
- `sourcePage`
- `sourcePublishedAt`
- `sourceVerifiedAt`
- `rightsTreatment`

`sourceRegistryId` must have the `SRC-##` shape.

Actual membership in the frozen ML-1 registry and official-host matching are deliberately deferred to ML-3.

## Source classes

ML-2 uses exactly the source-class vocabulary frozen in ML-1.

No generic `blog`, `website`, `AI`, `training provider` or other escape hatch exists in the schema.

## Rights treatment

Frozen structural vocabulary:

- `original_paraphrase`
- `brief_summary`
- `minimal_quote`
- `licensed_excerpt`

ML-5 will enforce the copyright/provenance rules that determine when each value is legitimate.

## Claim object

Every fact records:

- `legalStatus`
- `jurisdiction`
- `numericalClaim`
- `safetyCritical`
- `simplificationRisk`

This makes numerical and safety-critical facts identifiable before later enhanced review gates execute.

## Legal-status vocabulary

- `binding_requirement`
- `regulatory_interpretation`
- `nonbinding_guidance`
- `recommendation`
- `consensus_standard`
- `international_standard`
- `professional_guideline`
- `professional_framework`
- `research_finding`
- `certification_or_testing`
- `not_applicable`

ML-4 will validate whether the selected legal status is actually compatible with the authority and source class.

## Assessment object

Every fact records:

- `sensitivity`
- `linkedQuestionConcepts`

Frozen sensitivity values:

- `none`
- `low`
- `medium`
- `high`
- `block_during_linked_assessment`

A non-`none` sensitivity requires at least one linked question concept.

A `none` sensitivity must have no linked question concepts.

This prevents ambiguous assessment-leakage metadata.

## Review object

Review channels are independently represented:

- technical
- source
- pedagogy
- copyright
- UI
- human technical approval

Each uses:

```text
pending
pass
fail
```

Review dates:

- `reviewedAt`
- `nextReviewDueAt`

For published facts:

- every review channel must be `pass`;
- both dates are required;
- the next-review date cannot precede the review date;
- final review cannot predate source verification.

## Runtime object

ML-2 freezes only:

```json
{
  "startupEligible": true
}
```

Selector scoring, repetition weighting and learner-state weighting remain later-phase concerns and are intentionally not embedded prematurely.

## Supersession object

MicroFact v1 supports:

- `supersedesMicroFactId`
- `supersededByMicroFactId`

A fact cannot reference itself.

A fact with status `superseded` must identify its replacement.

A non-superseded fact cannot claim that it has already been superseded.

## Tags

Every fact requires 2 to 20 unique lower-case tags.

Tags are search/classification metadata. They do not replace structured curriculum placement or concept IDs.

## Fail-closed rules implemented in ML-2

Among other checks, the validator rejects:

- malformed JSON;
- incorrect schema version;
- unknown or missing fields;
- invalid stable IDs;
- invalid lifecycle/category/source/legal vocabularies;
- malformed HTTPS source URLs;
- invalid dates;
- invalid mapped curriculum hierarchy;
- hierarchy placement on a general fact;
- startup eligibility on a non-published fact;
- published facts with incomplete review;
- invalid assessment-link combinations;
- reversed review dates;
- published review predating source verification;
- duplicate tags/concept IDs;
- supersession self-reference;
- superseded facts without a replacement ID.

## Explicitly deferred

ML-2 does not implement:

- source-registry membership/host enforcement — ML-3;
- source-class/legal-status truth checks — ML-4;
- copyright/provenance evidence gates — ML-5;
- canonical CSP11 existence checks — ML-6;
- strict pedagogical/readability gates — ML-7;
- semantic duplicate/contradiction detection — ML-8;
- production fact authoring — ML-9;
- startup repository/UI integration — ML-10 onward.

## Verification

From repository root:

```powershell
dart run tool/validate_micro_learning_schema.dart
flutter test test/micro_learning/micro_fact_schema_validator_test.dart
```

Expected CLI output begins:

```text
ML-2 MicroFact v1 VALID
```

## Exit criteria

- [x] Formal MicroFact v1 JSON schema created.
- [x] Typed Dart MicroFact object created.
- [x] Stable ID rule frozen.
- [x] Lifecycle vocabulary frozen.
- [x] Category vocabulary frozen.
- [x] Display contract frozen.
- [x] Curriculum mapping structure frozen.
- [x] Source provenance structure frozen.
- [x] Legal-status metadata frozen.
- [x] Numerical and safety-critical flags frozen.
- [x] Assessment-sensitivity structure frozen.
- [x] Review channels and dates frozen.
- [x] Startup-eligibility rule frozen.
- [x] Supersession structure frozen.
- [x] Tags contract frozen.
- [x] Fail-closed validator implemented.
- [x] Positive and adversarial tests authored.
- [x] No production micro-facts generated.
- [x] No startup UI changed.
- [x] No backend path added.

## Next run

ML-3 — Source Gates.

ML-3 must connect MicroFact provenance to the frozen ML-1 Authority Registry and fail closed on invalid authority membership, unapproved host, source-class incompatibility or first-party violations.
