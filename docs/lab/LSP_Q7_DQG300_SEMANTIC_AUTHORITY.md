# CSP11 LSP-Q7 — DQG300 Semantic Authority Preservation

## Status

**IMPLEMENTED / VALIDATION CHECKPOINT**

Program: LSP-Q

Checkpoint: LSP-Q7

Branch: phase-l4-scenario-population

Baseline Q6 commit: db872515c36a22b30bc23a4cddc52fb4ab4797c2

## Purpose

LSP-Q7 proves and preserves the frozen rule that DQG300 remains the stronger semantic quality layer after the normal CSP11 parser and strict H0.3 gate are combined with LAB Decision validation.

H0.3 answers whether a LAB Decision is structurally and editorially a valid high-quality CSP scenario question.

DQG300 remains responsible for the deeper evidence-backed semantic proof that the Decision is exceptionally difficult, technically defensible, unambiguous and supported by a uniquely superior BEST answer.

The combined gate is not allowed to reinterpret a DQG failure as acceptable merely because canonical parsing and H0.3 pass.

## Semantic authority rule

For one Decision:

DQGSemanticPass =
DQG-001 through DQG-299 all PASS &&
derived DQG-300 PASS &&
DQS == 100 &&
the underlying DQG result is publishable

DecisionQualityPass continues to require:

CanonicalParsePass &&
StrictH03Pass &&
DQGSemanticPass

No local heuristic may substitute for DQGSemanticPass.

## Q7 implementation

The existing LabDecisionQualityResult now exposes explicit DQG witness properties:

- dqg300AtomicRulesPass
- dqg300DerivedPass
- dqg300DqsPerfect
- dqg300SemanticPass
- dqg300PassedRuleCount
- dqg300FailedRuleCount

The existing dqg300Pass property remains available and delegates to dqg300SemanticPass.

This is intentionally an observation and composition layer. It does not reproduce any DQG semantic predicate.

Dqg300QuestionQualityValidator remains the only authority that decides whether individual DQG rules pass.

## Anti-bypass invariants

Q7 freezes these invariants:

1. Canonical parser PASS cannot override a DQG failure.
2. Strict H0.3 PASS cannot override a DQG failure.
3. H0.3 does not absorb or downgrade DQG semantic warnings.
4. DQS below 100 remains blocking.
5. Failure of any atomic DQG rule remains blocking.
6. Failure of derived DQG-300 remains blocking.
7. Manual override requests remain blocking.
8. Unresolved DQG warnings remain blocking.
9. Unverified source authority remains blocking.
10. Semantic ambiguity remains blocking.
11. Unsupported BEST-answer assumptions remain blocking.
12. Semantic option duplication remains blocking even when literal H0.3 duplicate checks pass.

## Why this layer is stronger

Several DQG concepts are intentionally outside H0.3.

Examples include:

- source authority verification rather than merely having a reference string
- evidence-backed BEST-answer superiority
- expert near-miss distractor plausibility
- targeted misconception fingerprints
- semantic duplication detection
- assumption discipline
- ambiguity analysis
- counterfactual defensibility
- scenario-evidence anchoring
- DQ6 reasoning sophistication
- elimination resistance
- unresolved semantic warning state
- manual-override prohibition

A Decision can therefore have zero H0.3 errors and zero H0.3 warnings while still being correctly blocked by DQG300.

That is expected behavior, not a mismatch between validators.

## Test coverage

Dedicated Q7 tests prove that strict H0.3 still passes while DQG300 independently blocks when:

- manual override is requested
- unresolved DQG warnings remain
- source authority is unverified
- ambiguity is detected
- the BEST answer requires an unsupported assumption
- semantic duplicate options are detected

The Q7 PASS case also requires:

- all 299 atomic rules PASS
- derived DQG-300 PASS
- 300 total passed DQG rules
- zero failed DQG rules
- DQS 100/100
- strict H0.3 PASS

A deterministic repeated-run test verifies that the semantic witness is stable.

## Preserved boundaries

LSP-Q7 does not change:

- Dqg300QuestionQualityValidator
- QuestionQualityValidationResult
- QuestionQualityEvidence
- any DQG-001 through DQG-300 predicate
- DQS category calculation
- CanonicalQuestionParser
- QuestionQualityValidator / H0.3
- LabDecisionQuestionAdapter
- LAB1000 publication eligibility
- learner presentation
- learner runtime
- scenario population

No DQG rule is copied into the combined gate.

## Next authorized action

LSP-Q8 — Validate learner presentation records against the authoritative technical LAB package without allowing presentation data to modify technical story mechanics or Decision truth.
