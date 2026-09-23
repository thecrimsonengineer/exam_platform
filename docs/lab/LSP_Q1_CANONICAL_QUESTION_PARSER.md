# CSP11 LSP-Q1 — Canonical Question Parser Extraction

## Status

**IMPLEMENTED / VALIDATION CHECKPOINT**

Program: `LSP-Q`

Checkpoint: `LSP-Q1`

Branch: `phase-l4-scenario-population`

Baseline Q0 commit: `e8de189e9f2736a5eb9e5fb32c5bb65e7732550f`

## Implemented boundary

LSP-Q1 extracts context-free JSON question parsing into:

`lib/services/questions/canonical_question_parser.dart`

The parser owns:

- supported JSON root shapes
- question/stem aliases
- answer decoding
- option normalization
- explanation and BEST-rationale parsing
- reference/source aliases
- difficulty and cognitive defaults
- question-type defaults
- version parsing
- tag parsing
- duplicate normalized-stem detection

`StudioQuestionImportService` now delegates raw question parsing to the canonical parser and retains responsibility for:

- selected StudyContent context
- domain identity
- competency identity
- topic identity
- subtopic identity
- quiz identity
- content package identity
- context-mismatch rejection
- final Draft Question construction

No LAB adapter is introduced in Q1. That begins at LSP-Q2.

## Compatibility rule

Established Studio import semantics are preserved, including the existing integer answer-index precedence.

Existing Studio context validation remains fail closed.

## Q1 test coverage

Dedicated canonical parser tests cover:

- context-free field parsing
- top-level arrays
- string tags
- snake_case aliases
- defaults
- established integer answer semantics
- exact-option answer matching
- empty collections
- invalid JSON root types
- duplicate normalized stems
- punctuation-insensitive stem normalization

Existing Studio import and Studio service regression suites remain mandatory.

## Next authorized action

**LSP-Q2 — Build LAB Decision Question Adapter.**
