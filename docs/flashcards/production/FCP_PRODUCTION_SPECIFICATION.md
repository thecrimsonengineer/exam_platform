# FCP Production Specification

Status: FROZEN  
Base: `phase-fc-closed@eeaad1d2d02c3aaf3c09f39ed277185624542c93`

## Production unit

The production unit is one competency Flashcard package using the frozen schema:

```text
csp11.flashcards.package.v1
```

Deck identity follows the frozen FC convention:

```text
dNN_cNN_flashcards_vN
```

## Semantic identity

```text
csp11.concept.<semantic_slug>
csp11.flashcard.<same_semantic_slug>
```

One accepted semantic concept maps to one canonical Flashcard in FCP V1.

## Required production sequence

```text
curriculum
 -> concept inventory
 -> semantic consolidation
 -> provenance
 -> card authoring
 -> package
 -> FCQ100
 -> duplicate validation
 -> coverage
 -> review
 -> freeze
```

## Lifecycle

Use the frozen lifecycle:

```text
candidate -> review -> validated -> bundled
```

`published` remains outside FCP.

## Closure invariant

No competency, domain, or corpus checkpoint may close with unresolved blocking findings.
