# CSP11 Flashcard Core - FC Run 2 Status

**Phase:** FC - Flashcard Core  
**Run:** 2 of 8  
**Implementation branch:** `phase-fc2-provenance`  
**FC1 frozen base:** `f99c7b1dbb33c3e70872c762a1ebd36e84849fde`  
**Checkpoint name:** `FC2_PROVENANCE_GREEN`  
**Backend access:** Zero Firebase / zero Supabase by design and validation.

## Run 2 purpose

FC Run 2 makes authoritative sourcing and provenance a first-class Flashcard content contract.

The learner-facing provenance relationship is:

```text
Flashcard
   |
   +--> Primary Source
   |       |
   |       +--> exact source identity
   |       +--> source locator
   |       +--> authority tier
   |       +--> definition-use mode
   |       +--> copyright mode
   |       +--> verification status/date
   |
   +--> Supporting Source(s)
   |
   v
Visible Source Footer + Source Details
```

A factual learner card cannot silently graduate into a learner-ready lifecycle state without validated provenance.

## Implemented

### Source Registry

Run 2 adds a deterministic local `FlashcardSourceRegistry`.

Source IDs use:

```text
csp11.source.<semantic_source_key>
```

The registry fails closed on:

- malformed source IDs
- duplicate source IDs
- missing organizations
- missing titles
- missing domain allow-lists
- non-HTTPS canonical URLs
- canonical URLs outside the declared source-domain allow-list
- federal source tiers outside official `.gov` hosts
- invalid verified dates
- blocked sources marked primary-eligible
- unknown copyright sources marked primary-eligible
- inconsistent verbatim-use permissions
- incompatible federal law/regulation source types

### Authority tiers

The frozen local authority order is:

```text
1. federalLawRegulation
2. federalAgencyPrimary
3. federalTechnical
4. nationalConsensus
5. scholarlySupporting
6. otherSupporting
99. blocked
```

The rank is used only for provenance integrity.

It does not claim that every higher-tier source is automatically the best source for every technical statement.

When a stronger source is already attached to a card, a weaker source cannot be labeled as the primary source.

### Source types

Run 2 models:

- statute
- regulation
- agencyStandard
- agencyGuidance
- technicalPublication
- officialGlossary
- consensusStandard
- peerReviewedPublication
- other

### Definition-use modes

Every Flashcard source reference records how the learner-facing wording relates to the source:

- `officialDefinition`
- `faithfulParaphrase`
- `educationalParaphrase`
- `verbatimExcerpt`

The default is `educationalParaphrase`.

### Copyright modes

Run 2 models:

- `federalGovernmentWork`
- `openLicensed`
- `permissionGranted`
- `proprietaryParaphraseOnly`
- `unknownBlocked`

Copyright mode is deliberately separate from source authority.

A source can be technically authoritative while still requiring paraphrase or permission for reuse.

### Explicit verbatim permission

Run 2 adds `verbatimEligible` as an explicit per-source flag.

A trusted or federal host does not automatically grant word-for-word reuse.

This avoids assuming that every item hosted on a government page is itself an unrestricted U.S. Government work.

A `verbatimExcerpt` is allowed only when:

1. the source copyright mode permits verbatim use; and
2. the exact registry entry is explicitly marked `verbatimEligible: true`.

### Verification states

Source verification states are:

- `verified`
- `needsReview`
- `stale`
- `blocked`

A learner-ready card may use only verified sources.

Verified sources require a parseable `verifiedOn` date.

### Primary and supporting sources

For learner-ready cards:

- at least one source is mandatory
- exactly one source must be primary
- the primary source must be explicitly primary-eligible
- every source requires an exact locator
- every source must be verified
- a weaker source cannot be primary when a stronger attached source exists

Candidate and review-stage cards may still exist before provenance review so authoring is not blocked prematurely.

### Source locators

Locators are mandatory for learner-ready cards.

Examples include:

- regulation paragraph
- section heading
- publication section
- glossary entry
- page or table location where appropriate

This allows a learner or reviewer to trace the learning statement to the relevant part of the source rather than only to a homepage.

### Source footer

Run 2 adds `FlashcardSourceFooter`.

The footer contract exposes:

- source ID
- organization
- locator
- canonical URL
- learner-facing label

The first reference fixture produces a footer containing NIOSH and the exact Hierarchy of Controls locator.

### Source Details

Run 2 adds `FlashcardSourceDetails`.

The details contract exposes:

- organization
- title
- canonical URL
- locator
- authority tier
- source type
- definition-use mode
- copyright mode
- verification status
- verification date
- primary/supporting role

The learner UI itself remains scheduled for FC Run 6.

### Provenance validator

`FlashcardProvenanceValidator` is fail-closed for learner-ready cards.

It rejects:

- unknown source IDs
- duplicate source references
- blocked sources
- unresolved copyright status
- primary sources that are not primary-eligible
- missing primary-source locators
- missing learner-ready locators
- unverified learner-ready sources
- multiple primary sources
- learner-ready cards with no provenance
- learner-ready cards without exactly one primary source
- a weaker primary source when a stronger supporting source is attached
- verbatim use without explicit reuse permission
- proprietary paraphrase-only sources used as official definitions

### Initial authoritative fixture

Run 2 adds:

```text
assets/flashcards/run2/fc_source_registry.v1.json
```

Initial registry examples include:

- NIOSH - Hierarchy of Controls
- OSHA - 29 CFR 1910.134 Respiratory protection
- NIST - CSRC safety glossary
- a deliberately non-validated proprietary consensus-source policy example

The consensus example is intentionally not learner-ready. It exists to prove that proprietary sources remain fail-closed until rights and verification are resolved.

### Learner-ready reference card

Run 2 adds:

```text
assets/flashcards/run2/fc_sourced_cards.v1.json
```

The reference Hierarchy of Controls card:

- is lifecycle `validated`
- uses the NIOSH Hierarchy of Controls source
- carries an exact locator
- identifies NIOSH as primary
- uses `educationalParaphrase`
- passes the Run 2 provenance validator

## Source-policy rationale

Primary source pages used to establish the initial registry contract include:

- NIOSH Hierarchy of Controls:
  https://www.cdc.gov/niosh/hierarchy-of-controls/about/index.html
- OSHA 29 CFR 1910.134:
  https://www.osha.gov/laws-regs/regulations/standardnumber/1910/1910.134
- NIST CSRC Glossary:
  https://csrc.nist.gov/glossary/term/safety

The Run 2 design also deliberately distinguishes U.S. Government provenance from copyright/reuse permission because federal websites can contain third-party or otherwise protected material.

## Validation evidence

First full green FC2 implementation workflow:

```text
35508530268
```

Green gates:

- package resolution
- canonical Dart formatting
- full Flutter analyze
- FC Run 1 identity/model regression
- FC Run 1 Concept Registry regression
- FC Run 1 zero-backend architecture regression
- FC Run 2 Source Registry tests
- FC Run 2 provenance-validator tests
- frozen MOT FlipCard regression
- frozen HAP architecture regression

## Backend boundary

FC Run 2 adds no Firebase or Supabase dependency.

The existing FC architecture gate continues to scan the full `lib/features/flashcards` tree for forbidden imports.

No production Firebase or Supabase operation is required by Run 2.

## Explicitly deferred

Run 2 does not implement:

- FCQ100
- JSON deck import/export
- local deck repository
- collection ownership
- Daily Discovery
- review scheduling
- learner Collection UI
- learner Source Details UI
- Quiz completion hook
- cloud publishing
- cross-device sync

These remain assigned to later FC runs and future FCC exactly as frozen in `CSP11_FLASHCARD_CORE_FREEZE.md`.

## Run 2 acceptance result

Run 2 satisfies its frozen deliverables:

- Source Registry: PASS
- source authority tiers: PASS
- source types: PASS
- definition modes: PASS
- copyright modes: PASS
- official-domain rules: PASS
- verification status/date: PASS
- primary/supporting source rules: PASS
- locator requirements: PASS
- federal/regulatory sourcing rules: PASS
- proprietary-source paraphrase rules: PASS
- visible source-footer model: PASS
- Source Details model: PASS
- provenance validator: PASS
- source fixture set: PASS
- zero-backend preservation: PASS

Checkpoint candidate:

```text
FC2_PROVENANCE_GREEN
```

The checkpoint becomes frozen after the status-document commit itself passes the Phase FC validation workflow.
