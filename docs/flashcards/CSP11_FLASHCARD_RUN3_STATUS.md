# CSP11 Flashcard Core - FC Run 3 Status

**Phase:** FC - Flashcard Core  
**Run:** 3 of 8  
**Implementation branch:** `phase-fc3-content-system`  
**FC2 frozen base:** `phase-fc2-closed` at `b44dcec0168eaa82e3f6f08214449952fc03ff8a`  
**Checkpoint name:** `FC3_CONTENT_GREEN`  
**Backend access:** Zero Firebase / zero Supabase by design and validation.

## Run 3 purpose

FC Run 3 creates the deterministic local Flashcard content system.

It turns the FC1 semantic model and FC2 provenance model into one importable, exportable and locally storable content package that can be validated before bundling.

The frozen package boundary is:

```text
FlashcardContentPackage
        |
        +--> Deck
        +--> Concepts
        +--> Flashcards
        +--> Question -> Concept mappings
        +--> Source Registry entries
        |
        v
Structural validation
        |
        v
FCQ100
        |
        +--> PASS 100/100 -> bundle-ready
        |
        +--> <100 -> blocked from bundle-ready state
```

## Implemented

### 1. FCQ100

Run 3 introduces `Fcq100Validator` with contract:

```text
FCQ100-V1
```

FCQ100 contains 25 deterministic rules worth 4 points each.

Maximum score:

```text
25 x 4 = 100
```

A package passes only at exactly 100/100 with no failed rule.

The rule groups cover:

- package schema
- canonical Deck identity
- Deck version identity
- Deck title quality
- non-empty Concept set
- non-empty Flashcard set
- one Concept -> one canonical Flashcard
- unique Concept IDs
- unique Flashcard IDs
- unique Question mappings
- valid/unique Source Registry
- structural Deck/Concept/Card/mapping integrity
- exact Deck card membership
- learner-ready card lifecycle
- learner-ready Deck lifecycle
- concept-only card front contract
- definition length
- mandatory Why It Matters
- optional Key Point limits
- tag quality
- FC2 provenance validation
- primary source + locator requirements
- semantic Concept duplicate prevention
- semantic Flashcard duplicate prevention
- Concept/Card canonical placement parity

### 2. Content package contract

Run 3 adds:

```text
FlashcardContentPackage
```

Schema:

```text
csp11.flashcards.package.v1
```

The package contains:

- one Deck
- Concepts
- Flashcards
- QuestionConceptMappings
- FlashcardSourceRegistryEntries

The Deck ID is the package identity.

### 3. JSON import/export

Run 3 adds:

```text
FlashcardPackageJsonCodec
```

Behavior:

- JSON root must be an object
- unsupported schema versions fail closed
- package JSON decodes into the typed FC domain model
- package export is deterministic pretty JSON
- decode -> encode -> decode -> encode is byte-stable after canonical encoding

### 4. Deck validator

Run 3 adds:

```text
FlashcardDeckValidator
```

It integrates the frozen FC1 `FlashcardConceptCatalog` and checks:

- Concept/Card bidirectional references
- Question -> Concept references
- canonical Domain/Competency placement
- Deck identity and version
- Deck competency ownership
- duplicate IDs
- exact package-card versus Deck-card membership
- Concept/Card placement parity
- semantic duplicate findings

### 5. Duplicate detection

Run 3 adds:

```text
FlashcardDuplicateDetector
```

It normalizes learner-facing text and detects cross-identity collisions for:

- Concept canonical labels
- Concept aliases
- Flashcard front labels
- Flashcard front + definition content

This prevents two separate semantic IDs from silently representing the same collectible concept.

### 6. FC2 source validation integration

FCQ100 runs every card through:

```text
FlashcardProvenanceValidator
```

Therefore a 100/100 package cannot bypass the FC2 rules for:

- Source Registry integrity
- verification state
- copyright mode
- primary eligibility
- locators
- primary/supporting hierarchy
- explicit verbatim eligibility

### 7. Question/Concept mapping validation

The Run 3 package is validated through the FC1 Concept Catalog.

Question IDs must be positive and unique.

Every mapping must resolve to an existing Concept.

Many Question IDs may still resolve to one Concept exactly as frozen in FC1.

### 8. Mapping coverage report

Run 3 adds:

```text
FlashcardMappingCoverageReport
```

It reports:

- total mappings
- all mapped Question IDs
- mapped eligible Question IDs
- unmapped eligible Question IDs
- Concepts with mappings
- Concepts without mappings
- mapping counts per Concept
- eligible-question coverage ratio

The coverage denominator uses the explicit eligible-question universe.

Mappings outside that universe cannot inflate coverage.

### 9. Local repository

Run 3 adds:

```text
FlashcardPackageRepository
```

Implementations:

- `MemoryFlashcardPackageRepository`
- `SharedPreferencesFlashcardPackageRepository`

The persistent implementation is sharded by Deck/package ID.

Package key example:

```text
csp11.flashcards.package.v1.d03_c02_flashcards_v1
```

Index key:

```text
csp11.flashcards.package.index.v1
```

This avoids one monolithic Flashcard data blob and keeps package replacement local to one Deck.

The UI does not write SharedPreferences directly.

### 10. Deck index

Run 3 adds:

```text
FlashcardDeckIndex
FlashcardDeckIndexEntry
```

The index exposes local package metadata including:

- Deck ID
- Domain
- Competency
- title
- version
- lifecycle
- card count
- Concept count
- mapping count

### 11. Local Flashcard Studio foundation

Run 3 adds:

```text
FlashcardStudioService
```

It provides the service boundary for:

- JSON import
- structural validation
- FCQ100 validation
- local save
- JSON export
- local Deck index
- mapping coverage
- local package delete

This is the Studio foundation only.

Full Admin learner-facing authoring/preview integration remains assigned to FC Run 7.

### 12. Reference package

Run 3 adds:

```text
assets/flashcards/run3/fc_reference_package.v1.json
```

The reference package contains:

- Deck `d03_c02_flashcards_v1`
- 2 Concepts
- 2 canonical Flashcards
- 2 Question mappings
- verified NIOSH source provenance

Reference concepts:

- Hierarchy of Controls
- Elimination Control

The package passes FCQ100 at:

```text
100 / 100
```

## Validation evidence

First full green FC3 content-system workflow:

```text
35509535366
```

Coverage-hardening green workflow:

```text
35509681481
```

Green gates include:

- package resolution
- canonical Dart formatting
- full Flutter analyze
- FC Run 1 identity/model regression
- FC Run 1 Concept Registry regression
- FC Run 1 zero-backend architecture regression
- FC Run 2 Source Registry regression
- FC Run 2 provenance regression
- FCQ100 reference-package validation
- FCQ100 fail-closed mutation tests
- JSON package round-trip test
- unsupported-schema fail-closed test
- SharedPreferences sharded repository test
- Studio import/validate/save/export/delete test
- Deck index test
- exact eligible-question mapping coverage test
- frozen MOT FlipCard regression
- frozen HAP architecture regression

## Backend boundary

FC Run 3 remains a local-core phase.

It adds no Firebase or Supabase dependency to `lib/features/flashcards`.

The frozen FC architecture test continues to scan the complete Flashcard feature tree for forbidden imports.

SharedPreferences is used only behind the repository abstraction.

## Explicitly deferred

Run 3 does not implement:

- collection ownership
- unlock events
- Daily Discovery
- memory scheduling
- learner Collection UI
- review player
- Quiz completion reward hook
- Learning Twin summary integration
- cloud publishing
- cross-device collection/review synchronization

These remain assigned to FC Runs 4-8 and future FCC.

## Run 3 acceptance result

Frozen Run 3 deliverables:

- FCQ100 validator: PASS
- Deck validator: PASS
- source validator integration: PASS
- duplicate Flashcard detection: PASS
- duplicate Concept detection: PASS
- Question/Concept mapping validation: PASS
- JSON import: PASS
- JSON export: PASS
- local Deck repository: PASS
- Deck index: PASS
- local Flashcard Studio foundation: PASS
- reference Deck/package: PASS
- mapping coverage reports: PASS
- zero-backend preservation: PASS

Checkpoint candidate:

```text
FC3_CONTENT_GREEN
```

The checkpoint becomes frozen after this status-bearing commit passes the Phase FC validation workflow.
