# CSP11 DQ6 Validator — Two-Step Implementation Plan

## Base

Implementation branch: `phase-q-dqg64-question-quality-validator`

Parent specification: `docs/quiz_engine/CSP11_QUIZ_QUALITY_VALIDATOR_FREEZE_CANDIDATE.md`

The production architecture branch and Phase M branch are not modified by this work.

## Step 1 — Contract lock before implementation

1. Freeze the 64 atomic DQG identifiers and their traceability to the candidate MD.
2. Add temporary contract tests under `test/quality_validator_contract/temporary/`.
3. Add one perfect DQ6 fixture carrying every required proof.
4. Add targeted mutation tests that break one contract dimension at a time and require the named DQG plus aggregate DQG-064 to block publication.
5. Add manifest-integrity tests requiring exactly 64 contiguous, unique IDs.
6. Add no-override tests.
7. Do not write `question_quality_validator.dart` until these contract tests exist.

Step 1 is intentionally a red/contract stage. The tests reference the Step 2 API and are not claimed to pass until Step 2 is present.

## Step 2 — Deterministic implementation

1. Add `QuestionQualityEvidence` and subordinate evidence models without changing the existing `Question` authoring model.
2. Add `QuestionQualityValidationResult` with PASS/BLOCK only.
3. Add `QuestionQualityValidator` implementing DQG-001..064.
4. Compute DQS from ten fixed 10-point categories. Do not trust caller-supplied scores.
5. Fail closed on missing structured evidence.
6. Provide no manual override argument, method, or bypass.
7. Run all temporary contract tests plus existing Flutter tests locally before final freeze.
8. Only after green validation may temporary tests be promoted/renamed and the candidate specification be considered for final freeze.

## Why structured evidence is mandatory

The existing `Question` model can prove structural properties such as option count and answer-key index. It cannot itself prove semantic properties such as expert-near-miss plausibility, counterfactual validity, source-backed rejection distinctions, SME ambiguity review, or single-fatal-flaw quality. Pretending to infer those requirements with word-count or keyword heuristics would violate the candidate MD. Therefore those requirements are represented as explicit review evidence and missing evidence blocks publication.
