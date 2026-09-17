# CSP11 DQ6 Validator — Step 1 Validation Record

Status: CONTRACT COMPLETE CANDIDATE

Branch: `phase-q-dqg64-step1-contract-hardening`

Base checkpoint: `479ec879e53cf97a42c2b04978302738c1433c4f`

Parent specification: `docs/quiz_engine/CSP11_QUIZ_QUALITY_VALIDATOR_FREEZE_CANDIDATE.md`

## Scope

This validation record covers Step 1 only: the frozen DQG contract, red contract tests, fixture design, mutation coverage, manifest integrity, fail-closed semantics, and implementation isolation.

It does not claim that the red contract suite passes. The Step 1 suite intentionally references the future Step 2 API and remains non-green until the deterministic DQG implementation exists.

## Verified Step 1 properties

- DQG-001 through DQG-064 are explicitly enumerated in `DQG_64_RULE_MATRIX.md`.
- DQG-064 is the aggregate fail-closed publication gate.
- The contract requires exactly four options and exactly one valid BEST answer.
- Exact DQ6 thresholds are frozen, including plausibility 5/5, Truth Component 4/4, KEY↔distractor confusability 4/5, and computed DQS 100/100.
- Incoming DQS is never trusted. DQS is contractually computed from ten fixed 10-point categories.
- Missing mandatory evidence blocks publication.
- Any unresolved block, fail, or warning blocks publication.
- Manual override requests block publication and no override route is part of the contract.
- Semantic DQGs require structured review evidence rather than keyword inference.
- One perfect DQ6 fixture defines the complete intended passing evidence surface.
- Targeted mutation tests cover every named DQG and require the named rule plus DQG-064 to block.
- Compound DQGs have additional independent subcondition mutations, including technical-universe versus professional-level parity, terminology validity versus decision relevance, conditional-wording parity, answer-position cues, source presence versus source authority versus KEY support, numeric calculation consistency, and sophistication parity versus advanced-distractor presence.
- Controlled specification exceptions have positive-path coverage, including technically justified custom distractor families.
- Manifest integrity requires exactly 64 contiguous, unique identifiers.
- The production architecture branch and Phase M branch remain outside this work.

## Isolation audit

Compared with Step 1 base checkpoint `479ec879e53cf97a42c2b04978302738c1433c4f`, the hardening branch changes only:

1. `docs/quiz_engine/DQG_TWO_STEP_IMPLEMENTATION_PLAN.md`
2. `test/quality_validator_contract/temporary/dqg_compound_dimension_hardening_test.dart`
3. this validation record

The repository already contains a legacy `lib/services/question_quality_validator.dart` on the Step 1 base. That existing validator is not the new DQG-001..064 implementation and is not modified by Step 1 hardening.

The future Step 2 evidence model `lib/models/question_quality_evidence.dart` is absent on the Step 1 hardening branch, preserving the red-contract boundary.

## Step 1 closure rule

Step 1 can be frozen when this branch is accepted as the contract authority for Step 2. No production merge is required to begin Step 2; Step 2 should branch from the accepted Step 1 contract checkpoint so implementation is judged against this exact contract.

## Next action after Step 1 freeze

Create the Step 2 implementation branch from the accepted Step 1 commit. Implement the evidence models, validation result, and deterministic DQG validator without modifying the 64-rule contract or weakening any threshold. Run the red contract suite until green, then run the existing Flutter regression suite before any integration decision.
