# CSP11 Question Bank
# H0.3 FROZEN SPECIFICATION

## Title
H0.3: Deterministic CSP11 Quality-Gate Hardening

## Status
FROZEN

## Purpose
Strengthen the H0.2 structured validation system so the CSP11 Question Bank has a deterministic, testable, Admin-friendly quality gate.

The validator must answer:
"Exactly what is wrong with this question, which field is affected, how serious is it, and can the question safely proceed?"

The validator must remain deterministic and objective. It must not attempt subjective semantic judgment.

## Acceptance Criteria

### 1. Stable issue identity
Every validation issue must contain:
- code
- field
- severity
- message

The issue-code vocabulary must be frozen and stable.

### 2. Frozen issue codes

Structural/blocking errors:
- invalid_question_type
- invalid_cognitive_level
- invalid_difficulty
- missing_question_stem
- invalid_option_count
- empty_answer_option
- duplicate_answer_option
- invalid_correct_answer
- missing_explanation
- missing_reference

Quality warnings:
- weak_question_stem
- best_answer_length_bias
- option_length_imbalance
- weak_explanation
- insufficient_tags

No dynamically invented issue codes.

### 3. Explicit field mapping
Issues must map to the responsible Question field:
- questionType -> questionType
- cognitiveLevel -> cognitiveLevel
- difficulty -> difficulty
- question -> question
- options -> options
- correctAnswer -> correctAnswer
- explanation -> explanation
- reference -> reference
- tags -> tags

### 4. Severity contract

ERROR:
- Blocking
- passed == false
- blocked == true

WARNING:
- Non-blocking
- passed remains true when warnings are the only issues

Warnings must never cause a question to be blocked.

### 5. Malformed-input safety
The validator must not crash on:
- empty strings
- empty option lists
- fewer than four options
- more than four options
- invalid correctAnswer
- empty tags
- duplicate options
- unexpected capitalization

Malformed input must produce a validation report rather than an exception.

### 6. Determinism
The same Question object must always produce the same validation result.

Validation must not depend on:
- randomness
- current time
- UI state
- iteration order that can vary

### 7. Deterministic issue ordering
Issues must appear in a predictable Question-structure order:
1. Question type
2. Cognitive level
3. Difficulty
4. Question stem
5. Options
6. BEST answer
7. Answer-length quality
8. Explanation
9. Reference
10. Tags

### 8. Duplicate prevention
A single underlying failure must produce one issue for its issue code.

Duplicate issue codes must not be emitted for the same validation run.

### 9. Warning-only behavior
A question containing only warnings must produce:
- passed == true
- blocked == false
- errorCount == 0
- warningCount > 0

### 10. Error behavior
A question containing one or more errors must produce:
- passed == false
- blocked == true
- errorCount > 0

Warnings may coexist with errors but do not determine blocking.

### 11. Configurable answer-length validation
When answerLengthCheckEnabled == true, answer-length quality checks are active.

When answerLengthCheckEnabled == false, these codes must not be generated:
- best_answer_length_bias
- option_length_imbalance

### 12. No Plausible Alternative / distractor classification
Plausible Alternative and distractor classification are permanently excluded from this validation architecture.

## Required H0.3 Regression Tests

Tests must cover:
- valid question
- wrong question type
- wrong cognitive level
- wrong difficulty
- missing stem
- weak stem
- wrong option count
- empty option
- duplicate option
- invalid BEST answer
- missing explanation
- weak explanation
- missing reference
- insufficient tags
- BEST answer longest
- option imbalance
- length check disabled
- warning-only report passes
- error report blocks
- multiple errors
- mixed errors and warnings
- deterministic issue ordering
- no duplicate issue codes
- malformed input does not crash

## Completion Gate

H0.3 is complete only when:
- flutter analyze reports 0 errors
- all Flutter tests pass
- git diff --check is clean
- only intentional H0.3 changes are present in git status
- the H0.3 implementation is committed

## Architectural Boundary

H0.3 strengthens validation only. It does not redesign the Question model, Firebase architecture, Admin Home, or the broader Content Repository.

The next Phase H work may build on this contract, but must not silently change the frozen H0.3 validation semantics.

