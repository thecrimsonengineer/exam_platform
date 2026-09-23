# CSP11 Phase ML-5 - Copyright / Provenance Gates

Status: IMPLEMENTED  
Parent: `docs/micro_learning/PHASE_ML4_FACTUAL_LEGAL_STATUS_GATES.md`  
Branch: `phase-ml5-copyright-provenance-gates`

## Purpose

ML-5 determines whether a technically valid MicroFact also has an acceptable and auditable rights/provenance basis for startup display.

ML-4 answers:

> Is the claim represented with the right factual and legal weight?

ML-5 answers:

> Is CSP11 using that source in a way that is traceable, independently worded where required, minimally quoted where justified, and licensed where protected reuse goes beyond the product's conservative quotation rules?

ML-5 is intentionally conservative. It does not attempt to determine fair use, public-domain status or legal permission from a URL alone.

## Delivered artifacts

- `content/micro_learning/rights_provenance_policy_v1.json`
- `content/micro_learning/rights_evidence_schema_v1.json`
- `lib/services/micro_learning/rights_provenance_policy_validator.dart`
- `lib/services/micro_learning/rights_evidence_validator.dart`
- `lib/services/micro_learning/micro_fact_rights_gate_validator.dart`
- `test/fixtures/micro_learning/valid_rights_evidence_v1.json`
- `test/micro_learning/rights_provenance_policy_validator_test.dart`
- `test/micro_learning/rights_evidence_validator_test.dart`
- `test/micro_learning/micro_fact_rights_gate_validator_test.dart`
- `tool/validate_micro_learning_rights_gates.dart`
- `docs/micro_learning/PHASE_ML5_COPYRIGHT_PROVENANCE_GATES.md`

## Prerequisite chain

A MicroFact cannot pass ML-5 unless it already passes:

1. ML-1 Authority Registry
2. ML-2 MicroFact Schema
3. ML-3 Source Gates
4. ML-4 Factual / Legal-Status Gates
5. ML-5 Rights Policy Integrity
6. ML-5 Rights Evidence Integrity
7. ML-5 Fact-to-Evidence Binding

This keeps rights review downstream of source and claim validation without allowing it to weaken any earlier gate.

## No automated fair-use or public-domain decision

The frozen policy requires:

```text
aiIsRightsAuthority = false
publicDomainAssumptionAllowed = false
fairUseAutoDeterminationAllowed = false
sourceAvailabilityImpliesReusePermission = false
citationAloneCreatesReusePermission = false
```

This is a product-governance rule, not a statement that every source is copyrighted or that every reuse would be unlawful.

The purpose is to prevent CSP11 from treating:

- a public URL;
- a citation;
- an AI judgment;
- a government hostname;
- or a technical source's authority

as automatic proof of reuse permission.

## Preferred treatment

The preferred MicroFact rights treatment is:

```text
original_paraphrase
```

For original paraphrase and brief summary, ML-5 requires evidence that:

- the source was directly compared;
- independent wording was confirmed;
- no direct quote was used;
- quote word count is zero;
- quote segment count is zero;
- no quote hash is retained;
- no quote justification is needed;
- no verbatim run longer than five words was retained;
- protected source structure was not copied;
- no license metadata is being used to disguise an unlicensed copy.

The five-word threshold is a conservative CSP11 product-control rule. It is not presented as a universal legal threshold.

## Rights evidence is separate from the MicroFact

ML-2 intentionally froze the MicroFact schema before ML-5.

ML-5 therefore uses a separate evidence record rather than expanding the MicroFact object.

The evidence record is bound to:

- `microFactId`;
- `contentVersion`;
- `rightsTreatment`;
- `sourceRegistryId`;
- `officialUrl`;
- `sourceLocator`;
- `editionOrRevision`.

A source, version or treatment change invalidates the previous evidence.

This means a reviewer cannot approve one source and later have the fact silently switched to another source while keeping the old copyright approval.

## Lifecycle evidence requirement

Rights evidence is required for:

- `validated`;
- `published`;
- `review_due`;
- any fact with `startupEligible=true`.

Evidence must be `pass` for:

- `validated`;
- `published`;
- startup-eligible use.

The MicroFact's own:

```text
review.copyrightStatus
```

must also be `pass`.

The MicroFact review flag and the evidence record therefore cross-check each other rather than one replacing the other.

## Human review

A passing evidence record requires:

```text
humanReviewed = true
reviewedAt != null
nextReviewDueAt != null
```

Allowed reviewer roles are:

- `copyright_reviewer`;
- `content_governance_reviewer`;
- `legal_or_rights_reviewer`.

ML-5 stores reviewer role rather than requiring personally identifying reviewer data in each evidence object.

## Review chronology

ML-5 rejects rights evidence when:

- rights review predates source verification;
- final MicroFact review predates the rights review;
- rights evidence was already stale when final fact review occurred;
- rights evidence is more than 365 days old at final fact review.

This keeps provenance review tied to the actual source/version and time at which the fact was approved.

## Authority rights tiers

ML-5 defines two rights-governance tiers.

### Government first-party

- SRC-01 OSHA / U.S. Department of Labor
- SRC-02 NIOSH / CDC
- SRC-08 EPA
- SRC-09 DOT / PHMSA / FMCSA
- SRC-10 FEMA / DHS / NIMS / ICS

This tier does **not** mean every item on those sites is automatically free to reuse.

The frozen policy explicitly requires:

- no whole-page public-domain assumption;
- separate clearance for third-party material;
- no automatic clearance for logos, seals or trademarks.

### Rights-sensitive professional / standards sources

- SRC-03 ANSI / ASSP Standards
- SRC-04 ISO
- SRC-05 NFPA
- SRC-06 ACGIH
- SRC-07 AIHA
- SRC-11 AIChE / CCPS
- SRC-12 NSC
- SRC-13 ASSP professional literature
- SRC-14 FM Global
- SRC-15 UL

For rights-sensitive sources, ML-5 adds stricter edition/revision and human-review controls.

## Edition/revision provenance

For rights-sensitive authorities whose ML-1 edition policy is:

- `revision_tracked`;
- `annual_or_revision_check`;
- `publication_specific`;

ML-5 requires:

```text
provenance.editionOrRevision != null
```

This prevents a paraphrase or quote from a proprietary standard/publication from floating free of the edition that was actually reviewed.

## Minimal quote policy

`minimal_quote` is permitted only under the frozen CSP11 product rules.

Required evidence includes:

- direct quote used;
- one quote segment only;
- 1 to 12 quoted words;
- SHA-256 fingerprint of the quoted text;
- documented reason why exact wording is needed;
- source comparison completed;
- visible quotation marks in learner-facing text;
- source section or page.

The evidence stores a hash rather than the raw quoted text.

This avoids turning the evidence system itself into a repository of protected source excerpts.

The 12-word limit is a CSP11 product limit, not a statement of copyright law.

## Licensed excerpt policy

`licensed_excerpt` requires a complete license record.

The license must identify:

- license ID;
- licensor;
- scope;
- effective date;
- optional expiry date;
- startup-display permission;
- digital-redistribution permission;
- whether protected source structure may be reused.

A licensed excerpt fails when startup display or digital redistribution is not explicitly permitted.

If an expiry date exists, the license must still be valid when the MicroFact is reviewed.

## Protected structures and materials

Without explicit licensed permission, ML-5 blocks declared copying of:

- tables;
- figures;
- diagrams;
- charts;
- photographs;
- standard clause blocks;
- exposure-limit tables;
- checklists;
- question-bank items;
- answer keys;
- worked examples;
- book paragraphs;
- code/standard excerpts beyond the minimal-quote rule.

The evidence validator also blocks storing these source artifacts inside MicroFact evidence:

- raw source document;
- full standard;
- full book chapter;
- paywalled source snapshot;
- copyrighted table image.

MicroFact evidence is an audit record, not a source-document archive.

## Source comparison and derivative-similarity evidence

Every ML-5 rights treatment requires:

```text
sourceComparisonPerformed = true
```

For paraphrase/summary, evidence must also confirm:

```text
independentWordingConfirmed = true
```

and record:

```text
longestVerbatimRunWords
```

The validator does not claim to infer copyright infringement from token overlap.

Instead, it requires an auditable human comparison record before validated/published use.

## Quote presentation

If a fact declares:

- `minimal_quote`; or
- `licensed_excerpt`;

the learner-facing display must visibly contain quotation markers.

If a fact declares:

- `original_paraphrase`; or
- `brief_summary`;

quotation markers are rejected.

This prevents direct quotation from being hidden behind paraphrase metadata.

## Government-hosted third-party content

A government hostname does not automatically clear embedded third-party material.

Rights evidence records:

```text
thirdPartyMaterialPresent
thirdPartyMaterialCleared
```

If third-party material is present and not separately cleared, the evidence fails.

## Evidence fingerprint

ML-5 evidence fingerprints exactly:

```text
sourceRegistryId
officialUrl
sourceLocator
editionOrRevision
```

The values must match the MicroFact provenance exactly.

This blocks approval replay after:

- source URL changes;
- section/locator changes;
- edition changes;
- authority changes.

## Restricted evidence storage

The evidence record intentionally does not contain:

- raw quote text;
- source PDFs;
- full standards;
- book chapters;
- paywalled screenshots;
- copyrighted table images.

Minimal quotations use a SHA-256 quote fingerprint instead.

License evidence stores license metadata and scope, not the licensed source itself.

## What ML-5 can prove

ML-5 can deterministically prove that:

- the rights policy remains frozen;
- a rights evidence record exists when required;
- the record is structurally complete;
- the evidence belongs to the exact MicroFact/version;
- source provenance has not drifted;
- rights treatment has not changed;
- required human review occurred;
- review chronology is coherent;
- conservative quote rules are followed;
- protected structure reuse has declared license permission;
- license scope covers startup display and digital redistribution;
- no prohibited raw protected source material is embedded in the evidence record.

## What ML-5 does not pretend to prove

ML-5 does not make an automated legal conclusion that:

- a work is copyrighted;
- a work is public domain;
- a use is fair use/fair dealing;
- a license is legally enforceable;
- a paraphrase is legally non-infringing;
- third-party rights do not exist.

Those questions may require actual rights/legal review.

The architecture therefore records and gates human review rather than replacing it with a false automated legal opinion.

## Test coverage

ML-5 tests include:

- valid policy;
- unknown root and nested policy fields;
- AI promoted to rights authority;
- automated fair-use determination enabled;
- public-domain assumption enabled;
- authority-tier overlap;
- minimal-quote limit broadening;
- paraphrase verbatim-run broadening;
- license permission weakening;
- evidence freshness weakening;
- human review weakening;
- government third-party clearance weakening;
- rights-sensitive similarity-review weakening;
- valid evidence;
- unknown evidence fields;
- paraphrase with direct quotation;
- excessive verbatim run;
- quote over 12 words;
- multiple quote segments;
- missing quote hash/necessity;
- incomplete licensed excerpt;
- protected structure without license;
- explicitly licensed protected structure;
- raw protected source storage;
- uncleared third-party material;
- passing evidence without human review;
- reversed review dates;
- reversed license dates;
- unexpected license metadata;
- evidence attached to wrong MicroFact;
- evidence attached to wrong content version;
- rights-treatment drift;
- source-fingerprint drift;
- missing evidence;
- non-passing evidence;
- non-passing MicroFact copyright review;
- rights review before source verification;
- final fact review before rights review;
- stale evidence;
- evidence older than 365 days;
- minimal quote without visible quotation;
- properly marked minimal quote;
- undeclared quotation in paraphrase;
- expired license;
- rights-sensitive source without edition provenance;
- formal evidence-schema fail-closed marker.

## Deliberately deferred

ML-5 does not implement:

- canonical CSP11 curriculum existence checks - ML-6;
- startup pedagogy/readability/accessibility gates - ML-7;
- semantic duplicate/contradiction detection - ML-8;
- production MicroFact authoring - ML-9;
- runtime repository or startup UI integration - ML-10 onward.

## Verification

From repository root:

```powershell
dart run tool/validate_micro_learning_rights_gates.dart

flutter test \
  test/micro_learning/rights_provenance_policy_validator_test.dart \
  test/micro_learning/rights_evidence_validator_test.dart \
  test/micro_learning/micro_fact_rights_gate_validator_test.dart
```

Expected CLI output begins:

```text
ML-5 COPYRIGHT / PROVENANCE GATES VALID
```

## Exit criteria

- [x] Frozen ML-5 rights/provenance policy created.
- [x] Separate rights-evidence schema created.
- [x] Rights policy validator created.
- [x] Rights evidence validator created.
- [x] Fact-to-evidence gate created.
- [x] No automatic fair-use determination permitted.
- [x] No blanket public-domain assumption permitted.
- [x] Evidence required for validated/published/startup facts.
- [x] Exact MicroFact/content-version binding enforced.
- [x] Exact source fingerprint binding enforced.
- [x] Exact rights-treatment binding enforced.
- [x] Human rights review enforced.
- [x] Review chronology enforced.
- [x] Evidence freshness enforced.
- [x] Conservative paraphrase rules enforced.
- [x] Minimal quote rules enforced.
- [x] Quote hash stored instead of raw quote text.
- [x] Visible quotation required for quote treatments.
- [x] Undeclared quotation blocked for paraphrase/summary.
- [x] Licensed-excerpt scope enforced.
- [x] License expiry checked.
- [x] Protected structure reuse requires explicit license permission.
- [x] Raw protected source storage blocked from evidence.
- [x] Government third-party material requires separate clearance.
- [x] Rights-sensitive edition/revision provenance enforced.
- [x] Policy and evidence adversarial tests authored.
- [x] Cross-record replay/tampering tests authored.
- [x] No production MicroFacts generated.
- [x] No startup UI changed.
- [x] No backend path added.
- [x] No runtime network request added.

## Next run

ML-6 - Canonical Curriculum Mapping Gates.

ML-6 must prove that every mapped MicroFact points to real CSP11 canonical Domain, Competency, Topic and Subtopic identifiers without weakening ML-1 through ML-5.
