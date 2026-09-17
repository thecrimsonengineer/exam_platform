# CSP11 DQ6 Validator — Step 1 Validation Record

Status: **STEP 1 CLOSED — DQG300 CONTRACT COMPLETE**

Branch: `phase-q-dqg64-step1-contract-hardening`

Original Step 1 base checkpoint: `479ec879e53cf97a42c2b04978302738c1433c4f`

Parent specification: `docs/quiz_engine/CSP11_QUIZ_QUALITY_VALIDATOR_FREEZE_CANDIDATE.md`

Pinned parent-specification Git blob: `68b4fe0a132c8cc7ebd095aa7340a6ee4bb29b4b`

Authoritative Step 1 rule matrix: `docs/quiz_engine/DQG_300_RULE_MATRIX.md`

The earlier `DQG_64_RULE_MATRIX.md` is retained as historical Step 1 development evidence but is superseded by the DQG300 matrix for all future implementation work.

## Final Step 1 scope

Step 1 converts every mandatory requirement identified across all 35 numbered sections of the freeze candidate into a fail-closed atomic contract before the new validator is implemented.

The contract contains exactly:

- `DQG-001` through `DQG-299` as atomic requirements;
- `DQG-300` as the derived final publication aggregate;
- 300 contiguous unique DQG identifiers;
- 35/35 freeze-candidate sections represented;
- no optional DQG;
- no manual override or reduced-quality publication route.

## Frozen quality thresholds preserved

Step 1 preserves without tolerance:

- Question difficulty: DQ6 only.
- Exactly four options.
- Exactly one uniquely defensible BEST answer.
- Exactly three expert near-miss distractors.
- Distractor 1, 2 and 3 plausibility: exactly 5/5 each.
- Distractor 1, 2 and 3 Truth Component Score: exactly 4/4 each.
- KEY↔D1, KEY↔D2 and KEY↔D3 confusability: exactly 4/5 each.
- DQS: exactly 100/100.
- No rounding or tolerance. DQS 99 fails.
- BLOCK_COUNT = 0.
- FAIL_COUNT = 0.
- WARNING_COUNT = 0 before publication.
- Ambiguity, source support, option equivalence, scenario evidence, counterfactual, calculation, linguistic, elimination-resistance and BEST-answer superiority requirements are publication gates.
- Missing structured evidence fails closed rather than being guessed.
- Any failed DQG causes final DQG-300 to remain BLOCK.

## Coverage architecture

The 300 DQGs explicitly cover:

1. one-BEST-answer structure and expert-near-miss philosophy;
2. DQ6 publication thresholds;
3. DQ6 definition and multi-fact reasoning;
4. 5/5 distractor plausibility;
5. 4/4 Truth Component requirements;
6. single fatal flaw construction;
7. distinct distractor failure mechanisms and misconception fingerprints;
8. mandatory distractor metadata;
9. distractor-family semantics and controlled custom-family justification;
10. scenario integration;
11. criterion-matrix completeness;
12. KEY>D1, KEY>D2 and KEY>D3 superiority proof;
13. minimal plausible counterfactuals;
14. exact pairwise confusability;
15. option homogeneity;
16. character, word, clause, technical-term and qualifier balance;
17. specificity parity;
18. linguistic-cue suppression;
19. keyword-leakage suppression;
20. absolute-language scrutiny;
21. non-technical elimination resistance;
22. advanced-sounding distractor requirements;
23. numerical distractor reasoning provenance;
24. wrong-level correctness controls;
25. assumption controls;
26. authoritative source support for the KEY and distractor rejection distinctions;
27. the ambiguity firewall;
28. BEST-answer completeness across hazard, scope, timing, priority, mechanism, technical principle, scenario conditions, command word, calculation and assumptions;
29. equal strength of all three distractors;
30. the fixed ten-category DQS 100 model;
31. every listed hard-fail condition;
32. PASS/BLOCK publication status and zero unresolved warnings;
33. the complete machine-rule conjunction;
34. the frozen CSP11 DQ6 question philosophy;
35. freeze-candidate governance and anti-drift requirements.

## Test architecture

Step 1 adds:

- `tools/generate_dqg300_temp_tests.py` to generate 30 temporary Python test shards;
- 10 DQGs per generated shard;
- `tools/verify_dqg300_step1.py` to audit rule contiguity, uniqueness, section coverage, source-blob integrity, critical threshold anchors, generated-test coverage and DQG-300 aggregate semantics;
- `.github/workflows/dqg300_step1_audit.yml` to regenerate and run the complete Step 1 audit on GitHub Actions.

The temporary files are deliberately generated rather than permanently hand-maintained so the committed DQG300 matrix remains the single atomic contract source and stale copied tests cannot silently diverge.

## Failure-and-retest record

Step 1 was not declared complete on the first test attempt.

The first full GitHub Actions run generated all 30 temporary test shards and the DQG300 global verifier passed, but all 30 shard tests failed because the generated helper resolved the repository root one directory too high.

The failure was investigated rather than bypassed. `tools/generate_dqg300_temp_tests.py` was corrected so generated tests resolve the repository root from `parents[4]`.

The complete workflow was then rerun from scratch.

GitHub Actions run #3, run ID `35268999503`, against commit `46048fa86c83853ed6f5c4bb099b2f33f51af2bf`, completed with conclusion **success**.

That successful run verified:

- 300 contiguous unique atomic DQGs;
- all 35 freeze-candidate sections covered;
- the freeze-candidate Git blob remained pinned;
- all critical frozen thresholds remained present;
- 30 generated temporary test shards collectively covered DQG-001 through DQG-300;
- DQG-300 remained the derived final aggregate;
- all generated shard tests passed.

## Step 1 implementation boundary

Step 1 does not implement the new DQG300 production validator.

The repository already contained the legacy `lib/services/question_quality_validator.dart` before this Step 1 work. That baseline file is not the DQG300 implementation and is not intentionally changed by this contract closure.

The future Step 2 structured evidence model, validation-result model and DQG300 production validator belong to Step 2.

The production architecture branch and Phase M branch are not merged or modified by this Step 1 closure.

## Closure rule

**Step 1 is complete.**

The accepted Step 1 contract for Step 2 is DQG-001 through DQG-300 as recorded in `DQG_300_RULE_MATRIX.md` against the pinned freeze-candidate source blob.

Step 2 must branch from the final accepted Step 1 checkpoint and implement this contract without deleting, renumbering, weakening, reinterpreting, bypassing or reducing any DQG. If implementation pressure reveals a genuine specification problem, that must be handled as an explicit specification-change review rather than silently changing tests or validator thresholds.
