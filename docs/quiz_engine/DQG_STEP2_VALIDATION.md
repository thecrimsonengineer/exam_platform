# CSP11 DQ6 Validator — Step 2 Validation Record

Status: **STEP 2 CLOSED CANDIDATE — DQG300 IMPLEMENTATION GREEN**

Branch: `phase-q-dqg300-step2-validator`

Frozen Step 1 checkpoint: `4fa911325c6377c0367e14ad7514a7ee043205e5`

Green Step 2 implementation checkpoint before this closure record: `5e59e485449b161529edc9dae7b0d808ee3b14df`

Parent specification: `docs/quiz_engine/CSP11_QUIZ_QUALITY_VALIDATOR_FREEZE_CANDIDATE.md`

Pinned parent-specification Git blob: `68b4fe0a132c8cc7ebd095aa7340a6ee4bb29b4b`

Authoritative Step 1 rule matrix: `docs/quiz_engine/DQG_300_RULE_MATRIX.md`

Pinned DQG300 matrix Git blob: `2927a23e24e6fc274629851a15110ba602d927a0`

## Closure principle

Step 2 implements the frozen DQG300 contract without changing, renumbering, weakening, shaving, rounding, bypassing or overriding any Step 1 requirement.

The implementation must satisfy the contract. The contract is not modified to accommodate the implementation.

No lower-quality publication route exists in the strict DQG300 path.

## Implemented architecture

Step 2 adds a strict validation layer that is intentionally separate from the legacy authoring linter and from the learner-facing `Question` model.

The implementation consists of:

- `lib/models/question_quality_evidence.dart`
- `lib/models/question_quality_validation_result.dart`
- `lib/services/dqg300_question_quality_validator.dart`
- strict DQG300 lifecycle integration in `lib/services/question_bank_service.dart`
- DQG300 fixtures, mutation tests, scoring tests and publication-path tests
- `tools/verify_dqg300_step2.py`
- `.github/workflows/dqg300_step2_validator.yml`

## Fail-closed semantic evidence

Semantic DQ6 requirements are not guessed from superficial keyword or length heuristics.

Each atomic DQG has structured review evidence containing the rule identifier, review result, proof, evidence references, reviewer identifier and review timestamp.

The strict validator requires an exact ledger for `DQG-001` through `DQG-299`.

A rule passes only when:

1. its structured evidence record exists;
2. the evidence record is complete;
3. the evidence record explicitly satisfies the rule; and
4. every deterministic machine predicate applicable to the rule also passes.

Structured evidence therefore cannot override a failed machine condition.

Missing or incomplete evidence fails closed.

## Frozen thresholds implemented exactly

The strict implementation requires:

- question difficulty: DQ6 only;
- exactly four options;
- exactly one defensible BEST answer;
- exactly three distractors;
- each distractor role: expert near miss;
- each distractor plausibility: exactly 5/5;
- each distractor Truth Component Score: exactly 4/4;
- each KEY-to-distractor confusability score: exactly 4/5;
- one dominant fatal flaw per distractor;
- distinct misconception fingerprints;
- complete scenario anchoring;
- complete counterfactual validation;
- complete source support;
- no unresolved ambiguity;
- no non-technical elimination shortcut;
- complete BEST-answer superiority proof;
- DQS exactly 100/100;
- unresolved BLOCK count = 0;
- unresolved FAIL count = 0;
- unresolved WARNING count = 0.

There is no `99 = pass` path and no score rounding or tolerance.

## DQS implementation

DQS is computed by the validator. It is not supplied by the caller.

The ten frozen categories are:

1. Plausibility
2. Truth Component
3. DQ6 compliance
4. Scenario integration
5. Distinct misconception targeting
6. Single-fatal-flaw quality
7. Pairwise confusability
8. Linguistic, length and specificity parity
9. Elimination resistance
10. BEST-answer superiority and ambiguity proof

Each category contributes either 10 or 0 points.

Every category must contribute 10 points for DQS 100.

No partial-credit route can produce a publishable result.

## DQG-300 derivation

`DQG-300` cannot be supplied by the caller.

The validation-result model accepts only the 299 atomic rule results and the ten computed DQS categories.

It derives `DQG-300` as PASS only when every atomic rule passes and computed DQS equals 100.

Final publication status is therefore also derived rather than caller-controlled.

## No override architecture

The strict validator has a parameterless constructor.

It exposes no quality-disable parameter and no publication-override method.

`publicationOverrideSupported` is hard-coded to `false`.

The legacy `answerLengthCheckEnabled` option remains part of the pre-existing authoring linter only. It is not accepted by the strict DQG300 validator and cannot rescue a failed DQG300 publication decision.

A dedicated regression test verifies this separation.

## Publication lifecycle integration

Step 2 closes the previously identified lifecycle gap in `QuestionBankService`.

A question cannot advance from REVIEW to VALIDATED without DQG300 evidence and a complete 300/300 PASS.

A VALIDATED question cannot become PUBLISHED without DQG300 evidence and a complete 300/300 PASS.

Prepared bulk publication requires DQG300 evidence for every question before any publication write is attempted.

The private bulk publication path rechecks DQG300 immediately before lifecycle writes.

Missing evidence is a hard block.

One failed DQG is a hard block.

One unresolved DQG warning is a hard block.

In addition, final lifecycle advancement requires a clean legacy authoring-linter result. Any remaining authoring issue, including a warning, blocks VALIDATED or PUBLISHED status.

Draft authoring may still display legacy warnings, but those warnings cannot cross the final lifecycle gate.

## Learner-data separation

DQG semantic evidence remains outside `lib/models/question.dart`.

The Step 2 verifier rejects leakage of answer-sensitive fields such as:

- misconception fingerprints;
- fatal-flaw explanations;
- counterfactual-to-correct proofs;
- SME rejection proofs;
- KEY superiority proofs;
- the atomic rule-evidence ledger.

This prevents the normal learner question model from becoming an answer-key side channel.

## Test architecture

The Step 2 runtime suite includes:

- a perfect DQ6 fixture that must pass exactly 300/300 gates with DQS 100;
- 299 atomic fail-closed mutation tests, one for every DQG-001 through DQG-299;
- DQS no-shaving tests;
- deterministic structural and semantic-evidence mutation tests;
- exact confusability boundary tests for 3, 4 and 5;
- missing-evidence tests;
- no-override tests;
- source-support tests;
- generic-superiority-proof rejection tests;
- custom-family justification tests;
- numerical-provenance tests;
- publication lifecycle tests;
- prepared-batch preflight and atomicity tests;
- answer-randomization semantic-preservation tests.

The complete repository Flutter regression suite is also required to pass before closure.

## Anti-shortcut static verifier

`tools/verify_dqg300_step2.py` independently verifies that:

- the frozen Step 1 specification blob is unchanged;
- the frozen DQG300 matrix blob is unchanged;
- DQG-001 through DQG-300 remain contiguous and complete;
- the strict validator remains parameterless;
- publication override support remains false;
- the legacy answer-length toggle is absent from the strict validator;
- semantic proof cannot replace a failed machine predicate;
- the rule-evidence ledger contains exactly 299 atomic records;
- all ten fixed DQS categories remain present;
- caller-supplied DQS and caller-supplied final PASS/BLOCK are absent;
- DQG-300 remains derived;
- single-question and bulk publication paths require DQG300 evidence;
- final lifecycle paths reject unresolved authoring warnings;
- DQG evidence remains outside the learner-facing Question model;
- no DQG300 runtime test is skipped.

## Superseded DQG64 executable tests

The historical temporary DQG64 contract tests were removed from the Step 2 branch because DQG300 changed and expanded the rule numbering and became the authoritative Step 1 contract.

Their history remains preserved at the frozen Step 1 checkpoint.

Their removal does not modify the frozen Step 1 matrix or source specification. The current DQG300 suite supersedes them and tests the authoritative 300-rule contract directly.

## Failure and retry record

Step 2 was not closed on the first attempt.

### Failure 1 — Step 1 shard discovery

After obsolete temporary test cleanup, root-level Python unittest discovery found zero generated Step 1 shard tests.

The frozen Step 1 verifier itself still passed.

The workflow was corrected to target the generated shard directory explicitly and the complete Step 1 audit was rerun successfully.

### Failure 2 — superseded DQG64 tests

Flutter analysis identified historical DQG64 temporary tests that still imported obsolete Step 1 red-contract support APIs.

Those executable tests were removed from the Step 2 branch because DQG300 supersedes their identifiers and semantics. The frozen Step 1 checkpoint and contract documents were not changed.

### Failure 3 — analyzer information lints

The repository contained information-level analyzer findings but zero analyzer errors and warnings.

CI uses `flutter analyze --no-fatal-infos` so errors and warnings remain fatal while pre-existing information-level lints do not falsely fail closure.

No DQG quality condition is disabled by this analyzer configuration.

### Failure 4 — generic superiority wording

The first DQG300 runtime attempt passed 327 tests and failed one test.

The validator incorrectly accepted the generic superiority statement `D1 is less appropriate.`

The implementation was corrected so optional D1/D2/D3 prefixes do not make generic superiority wording acceptable.

The test was not weakened or removed.

### Failure 5 — legacy publication gap

Repository review found that the pre-existing lifecycle could validate or publish without DQG300 evidence.

Step 2 added strict evidence requirements to single-question and bulk lifecycle paths.

### Failure 6 — first guarded publication patch attempt

The exact-SHA guarded patcher found an ambiguous repeated legacy validation snippet and stopped without committing changes.

The patch was narrowed to exact lifecycle methods and rerun.

The SHA guards were retained.

### Failure 7 — unresolved legacy warning path

Further review found that strict DQG evidence could be green while the legacy authoring linter still contained a warning.

Final lifecycle checks were hardened from error-only rejection to rejection of every unresolved authoring issue.

The corresponding tests and static-verifier checks were added.

### Migration tooling cleanup

The temporary write-enabled migration workflow and guarded patcher were removed before closure-grade CI.

The final Step 2 branch retains only read-only validation CI for this feature.

## Closure-grade CI evidence

Closure-grade implementation run:

- workflow: `DQG300 Step2 Validator`
- run ID: `35273163184`
- job ID: `105377220119`
- tested implementation SHA: `5e59e485449b161529edc9dae7b0d808ee3b14df`

Every required stage completed with conclusion SUCCESS:

- frozen Step 1 contract verification;
- Step 2 anti-shortcut verification;
- Flutter setup;
- package resolution;
- Flutter analysis;
- targeted DQG300 Step 2 runtime tests;
- complete Flutter regression suite.

## Step 1 isolation audit

A Git comparison from frozen Step 1 checkpoint `4fa911325c6377c0367e14ad7514a7ee043205e5` to the green implementation checkpoint confirms that neither:

- `docs/quiz_engine/DQG_300_RULE_MATRIX.md`, nor
- `docs/quiz_engine/CSP11_QUIZ_QUALITY_VALIDATOR_FREEZE_CANDIDATE.md`

was modified by Step 2.

The Step 2 production changes are limited to the new DQG300 evidence/result/validator components and the required publication-gate integration in `QuestionBankService`.

No production architecture branch merge is performed by Step 2.

No Phase M branch merge or modification is performed by Step 2.

## Final closure condition

Step 2 is considered formally CLOSED only when the commit containing this closure record itself completes the same `DQG300 Step2 Validator` workflow successfully.

The closure commit must therefore again prove:

- unchanged Step 1 hashes;
- DQG300 anti-shortcut integrity;
- analyzer success;
- targeted DQG300 runtime success at 300/300 and DQS 100;
- complete Flutter regression success.

Only after that final closure-head run is green may Step 2 be reported as CLOSED.