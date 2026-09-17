# CSP11 DQ6 Validator — Two-Step Implementation Plan

## Base

Step 1 hardening branch: `phase-q-dqg64-step1-contract-hardening`

Parent specification: `docs/quiz_engine/CSP11_QUIZ_QUALITY_VALIDATOR_FREEZE_CANDIDATE.md`

Authoritative Step 1 rule matrix: `docs/quiz_engine/DQG_300_RULE_MATRIX.md`

Pinned freeze-candidate Git blob: `68b4fe0a132c8cc7ebd095aa7340a6ee4bb29b4b`

The production architecture branch and Phase M branch are not modified by this work.

## Step 1 — Contract lock before implementation

1. Decompose every mandatory requirement in all 35 freeze-candidate sections into 300 atomic DQGs.
2. Require exactly contiguous identifiers `DQG-001` through `DQG-300`.
3. Make `DQG-300` the derived aggregate publication gate. It cannot be manually set.
4. Pin the source freeze-candidate Git blob so any later specification drift invalidates the Step 1 audit until remapped and retested.
5. Preserve exact DQ6 thresholds: all three plausibility scores 5/5, all three Truth Component Scores 4/4, all three KEY↔distractor confusability scores exactly 4/5, and DQS exactly 100/100.
6. Preserve zero-tolerance publication semantics: no unresolved blocks, failures, warnings, ambiguity, unsupported source distinction, option equivalence, or incomplete BEST-answer superiority proof.
7. Preserve one uniquely defensible BEST answer and exactly three expert near-miss distractors.
8. Preserve fail-closed structured evidence. Semantic quality must not be guessed from keywords when the evidence needed by the contract is absent.
9. Provide no manual override, rounding tolerance, warning escape, reduced-quality route, or alternate publication path.
10. Generate 30 temporary test shards covering 10 DQGs each. The generated shards collectively cover all 300 DQGs.
11. Run a repository-native static audit verifying rule count, contiguity, section coverage, critical source anchors, pinned source blob, generated shard coverage, and final aggregate semantics.
12. Keep Step 1 isolated from the new production validator implementation. The repository's pre-existing legacy `question_quality_validator.dart` remains baseline code and is not the DQG300 implementation.
13. Do not add the Step 2 evidence model, result model, publication integration, or new DQG300 validator implementation during Step 1.
14. Preserve the earlier targeted red Dart tests as implementation-facing design evidence. The 300-DQG matrix supersedes the earlier 64-rule matrix as the contract authority for Step 2.

### Step 1 completion gate

Step 1 is CLOSED only when all of the following are true:

- `DQG_300_RULE_MATRIX.md` contains exactly DQG-001 through DQG-300, once each, in order.
- All 35 numbered sections of the freeze candidate have at least one atomic DQG and every mandatory requirement identified in the coverage audit is represented.
- The source freeze-candidate Git blob remains exactly `68b4fe0a132c8cc7ebd095aa7340a6ee4bb29b4b`.
- DQG-300 is the derived final aggregate and cannot pass unless DQG-001 through DQG-299 all pass.
- The temporary test generator produces exactly 30 shards and those shards collectively reference all 300 DQGs.
- The Step 1 verifier passes after generation of the temporary tests.
- The temporary Python contract suite passes in full.
- A real failing test, if encountered during Step 1 construction, is corrected and the complete audit is rerun rather than bypassed.
- The exact DQ6, 5/5, 4/4, 4/5 and DQS 100/100 thresholds remain unchanged.
- Missing structured evidence remains publication-blocking.
- No override or reduced-quality path exists in the contract.
- No Step 2 implementation is introduced to make the contract artificially green.
- The production architecture branch and Phase M branch remain outside the Step 1 changes.

## Step 2 — Deterministic implementation

1. Branch from the accepted final Step 1 checkpoint.
2. Add `QuestionQualityEvidence` and subordinate evidence models without weakening the existing `Question` authoring architecture.
3. Add a validation result surface with publication eligibility restricted to PASS/BLOCK.
4. Implement the new `QuestionQualityValidator` against DQG-001 through DQG-300.
5. Compute DQS from the frozen ten fixed 10-point categories. Never trust caller-supplied DQS as authority.
6. Fail closed on missing structured evidence.
7. Provide no manual override argument, method, bypass, tolerance, or reduced-quality publication route.
8. Convert each atomic DQG into implementation-facing mutation coverage and require DQG-300 to block whenever any preceding rule fails.
9. Run the DQG300 contract suite, Flutter analysis, validator tests, and existing regression suite before any final freeze or integration decision.
10. Step 2 may implement the Step 1 contract but may not rewrite the Step 1 contract to fit implementation.

## Why structured evidence is mandatory

The existing `Question` model can prove structural properties such as option count and answer-key index. It cannot itself prove semantic properties such as expert-near-miss plausibility, counterfactual validity, source-backed rejection distinctions, SME ambiguity review, single-fatal-flaw quality, or the reasoning pathway behind a numerical distractor. Pretending to infer these requirements using shallow word-count or keyword heuristics would violate the freeze candidate. Therefore semantic requirements must be represented as structured evidence and missing evidence blocks publication.
