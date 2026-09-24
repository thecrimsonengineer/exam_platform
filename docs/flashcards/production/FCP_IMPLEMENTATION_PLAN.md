# CSP11 FCP — Flashcard Production Corpus Implementation Plan

Status: FROZEN FOR IMPLEMENTATION  
Phase: FCP — Flashcard Production Corpus  
Frozen base branch: `phase-fc-closed`  
Frozen base SHA: `eeaad1d2d02c3aaf3c09f39ed277185624542c93`  
Working branch: `phase-fcp-flashcard-production`  
Final closure checkpoint: `phase-fcp-production-closed`

## Purpose

FCP creates the complete learner-ready CSP11 Flashcard production corpus on top of the already frozen Flashcard Core.

FCP is a content-production phase. It must not reopen or redesign the Flashcard engine.

The execution sequence is:

```text
FCP-0   Production specification freeze
FCP-1   Domain 01 production
FCP-2   Domain 02 production
FCP-3   Domain 03 production
FCP-4   Domain 04 production
FCP-5   Domain 05 production
FCP-6   Domain 06 production
FCP-7   Domain 07 production
FCP-8   Whole-corpus duplicate / semantic-overlap gate
FCP-9   Curriculum coverage gate
FCP-10  Human review
FCP-11  Production freeze
```

There are 12 FCP runs in total: FCP-0 through FCP-11.

## Permanent architecture boundary

FCP inherits and preserves:

- `csp11.flashcards.package.v1`
- Question -> Concept -> canonical Flashcard
- one canonical Concept -> one canonical collectible Flashcard in FC V1
- semantic Concept IDs
- matching semantic Flashcard IDs
- competency Deck packaging
- structured source provenance
- FCQ100
- FlashcardDeckValidator
- FlashcardDuplicateDetector
- FlashcardProvenanceValidator
- deterministic JSON codec
- zero Firebase / Supabase Flashcard Core boundary

FCP must not:

- redesign Flashcard UI
- modify review scheduling
- modify unlock or ownership logic
- modify Daily Discovery
- change frozen ID or schema rules
- weaken FCQ100
- generate learner cards at runtime with an LLM
- implement cloud publication
- depend on active ML, LTAM, LSP, Home, or Startup branches

## Parallel-development rule

FCP branches only from `phase-fc-closed`.

It must not merge unfinished parallel feature branches during production.

Later integration consumes the closed FCP checkpoint rather than modifying the production phase in place.

## Repository layout

```text
docs/flashcards/production/
  FCP_IMPLEMENTATION_PLAN.md
  FCP_PRODUCTION_SPECIFICATION.md
  FCP_AUTHORING_RULES.md
  FCP_SOURCE_POLICY.md
  FCP_REVIEW_POLICY.md
  FCP_STATUS.md

assets/flashcards/production/
  manifest/
    fcp_corpus_manifest.v1.json
  sources/
  d01/
  d02/
  d03/
  d04/
  d05/
  d06/
  d07/
  reports/

test/features/flashcards/production/
```

## Content contract

Flashcard fronts are concepts, terms, acronyms, principles, formulas, thresholds, controls, processes, classifications, hazards, or models.

They are not questions.

Valid examples:

```text
Hierarchy of Controls
Immediately Dangerous to Life or Health
Fault Tree Analysis
Minimum Ignition Energy
```

Invalid examples:

```text
What is IDLH?
Which control is most effective?
What does FTA mean?
```

Concept identity:

```text
csp11.concept.<semantic_slug>
```

Flashcard identity:

```text
csp11.flashcard.<same_semantic_slug>
```

A wording-only improvement keeps the semantic identity. A material semantic change requires a new identity.

## Card authoring requirements

Each production Flashcard contains:

- front label
- back definition
- Why It Matters
- optional Key Point
- canonical placement
- source references
- 2–8 tags
- lifecycle

Existing FCQ100 limits remain authoritative.

Front:
- 2–80 characters
- one line
- no question mark
- concept-oriented

Definition:
- 20–600 characters

Why It Matters:
- 20–500 characters
- required

Key Point:
- optional
- <=300 characters

Tags:
- 2–8
- unique
- lowercase canonical syntax
- <=40 characters each

## No arbitrary card quota

FCP does not require a fixed number of cards per subtopic or competency.

Every material curriculum concept must resolve to exactly one of:

```text
CARD
MERGED
NOT_FLASHCARD_WORTHY
```

This prevents quota-driven duplicate cards.

## Concept inventory first

Every competency starts with a concept inventory before card authoring.

The inventory records:

- candidate concepts
- accepted concepts
- merged concepts
- rejected concepts
- concepts judged not Flashcard-worthy
- unresolved/HOLD entries during active work

No competency can close with an unresolved concept.

## Source policy

Every learner-ready factual card requires validated provenance.

The frozen authority order remains:

```text
1  federalLawRegulation
2  federalAgencyPrimary
3  federalTechnical
4  nationalConsensus
5  scholarlySupporting
6  otherSupporting
99 blocked
```

Source authority does not automatically grant verbatim reuse.

Use educational or faithful paraphrase unless rights explicitly permit verbatim use.

A learner-ready card requires:

- at least one source
- exactly one primary source
- exact locator
- verified source status
- valid copyright mode
- valid definition mode

## Competency production pipeline

Every competency follows one deterministic sequence:

```text
Canonical curriculum
 -> concept extraction
 -> concept consolidation
 -> inventory freeze
 -> source identification
 -> card authoring
 -> provenance binding
 -> package assembly
 -> deterministic JSON round trip
 -> FCQ100
 -> deck validation
 -> competency duplicate scan
 -> coverage report
 -> competency closure
```

Per-competency outputs:

```text
<competency>_concept_inventory.v1.json
<competency>_flashcards_v1.json
<competency>_fcq100_report.json
<competency>_duplicate_report.json
<competency>_source_report.json
<competency>_coverage_report.json
<competency>_validation_summary.md
```

A competency closes only when:

- canonical placement resolves
- all concepts are resolved
- IDs are unique and valid
- Concept / Flashcard semantic slugs match
- one canonical card exists per accepted concept
- provenance passes
- exactly one primary source exists per card
- exact locators exist
- deterministic JSON round trip passes
- FCQ100 = 100 / 100
- deck validation passes
- exact duplicates = 0
- unresolved semantic collisions = 0
- unresolved concept coverage = 0

## FCP-0 — Production specification freeze

Deliver:

- frozen implementation plan
- production specification
- authoring rules
- source policy
- human-review policy
- corpus manifest skeleton
- status tracker
- dedicated FCP CI workflow
- initial FCP manifest test

Checkpoint target:

```text
FCP0_PRODUCTION_SPEC_GREEN
phase-fcp0-production-spec-closed
```

FCP-0 may close only after CI is green.

## FCP-1 — D01

Produce D01 competency-by-competency.

Checkpoint:

```text
FCP1_D01_GREEN
phase-fcp1-d01-closed
```

## FCP-2 — D02

Checkpoint:

```text
FCP2_D02_GREEN
phase-fcp2-d02-closed
```

## FCP-3 — D03

Checkpoint:

```text
FCP3_D03_GREEN
phase-fcp3-d03-closed
```

## FCP-4 — D04

Checkpoint:

```text
FCP4_D04_GREEN
phase-fcp4-d04-closed
```

## FCP-5 — D05

Checkpoint:

```text
FCP5_D05_GREEN
phase-fcp5-d05-closed
```

## FCP-6 — D06

Checkpoint:

```text
FCP6_D06_GREEN
phase-fcp6-d06-closed
```

## FCP-7 — D07

Checkpoint:

```text
FCP7_D07_GREEN
phase-fcp7-d07-closed
```

## FCP-8 — Whole-corpus semantic gate

Combine D01–D07 and scan globally for:

- duplicate Concept IDs
- duplicate Flashcard IDs
- duplicate Deck IDs
- identical normalized fronts
- alias collisions
- materially equivalent definitions
- semantic overlap
- abbreviation/full-name duplication
- broader/narrower concept confusion
- cross-domain duplicate concepts
- contradictory definitions
- conflicting numerical facts
- source-context conflicts

Resolution states:

```text
ACCEPT
MERGE
RENAME
DISTINGUISH
REJECT
HOLD
```

Closure requires HOLD = 0 and no unresolved blocking collision.

Checkpoint:

```text
FCP8_SEMANTIC_CORPUS_GREEN
phase-fcp8-semantic-gate-closed
```

## FCP-9 — Curriculum coverage

Invert validation from cards back to curriculum.

Coverage hierarchy:

```text
Domain
 -> Competency
 -> Topic
 -> Subtopic
 -> approved Concept inventory
```

Coverage is based on resolved approved concepts, not merely whether a subtopic has at least one card.

Final concept states:

```text
CARD
MERGED
NOT_FLASHCARD_WORTHY
```

Closure requires unresolved approved concepts = 0.

Checkpoint:

```text
FCP9_CURRICULUM_COVERAGE_GREEN
phase-fcp9-coverage-gate-closed
```

## FCP-10 — Human review

Machine validation does not equal technical approval.

Human review verifies:

- technical accuracy
- source interpretation
- clarity
- appropriate simplification
- practical/exam usefulness
- safety-critical wording
- concept boundaries
- placement

Review states:

```text
ACCEPT
REJECT
HOLD
```

Closure requires:

```text
HOLD = 0
BLANK = 0
UNREVIEWED = 0
```

Checkpoint:

```text
FCP10_HUMAN_REVIEW_GREEN
phase-fcp10-human-review-closed
```

## FCP-11 — Production freeze

Rebuild final packages only from accepted content.

Run:

- schema validation
- ID validation
- Concept -> Flashcard integrity
- placement validation
- source registry validation
- provenance validation
- FCQ100 on every package
- deck validation
- deterministic JSON round trip
- global duplicate gate
- contradiction gate
- curriculum coverage
- human review gate
- frozen FC regressions
- full repository regression
- zero-backend proof

Generate the final corpus manifest from repository contents.

Final counts must be computed, never predeclared.

Generate a deterministic SHA-256 over canonical production artifacts in sorted path order and record it as `corpusContentSha256`.

Final checkpoint:

```text
FCP11_PRODUCTION_CORPUS_GREEN
phase-fcp-production-closed
```

## Fail-closed policy

Block a card when:

- concept identity is uncertain
- authoritative sourcing is unresolved
- source verification is blocked/stale for learner-ready use
- a numerical value cannot be verified
- legal/regulatory context is unclear
- copyright use is unresolved
- semantic duplication is unresolved
- placement is unresolved
- review status is HOLD
- FCQ100 < 100

Do not lower a quality gate to force completion.

## Final acceptance

FCP closes only when:

- D01–D07 are complete
- every final package passes FCQ100 100/100
- every package round trips deterministically
- global Concept, Flashcard, and Deck IDs are unique
- provenance is valid
- no unresolved duplicate or contradiction remains
- every approved curriculum concept is resolved
- every final card has completed human review
- FCP tests pass
- frozen Flashcard regressions pass
- full repository regression passes
- final manifest and SHA-256 exist
- final closure report is committed
- `phase-fcp-production-closed` is created

## Immediate next action

Execute FCP-0 only.

Do not begin D01 authoring until FCP-0 is green and closed.
