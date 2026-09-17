# CSP11 DQ6 Quality Gate — 64 Atomic Rule Matrix

Status: Step 1 contract candidate derived from `CSP11_QUIZ_QUALITY_VALIDATOR_FREEZE_CANDIDATE.md`.

The freeze candidate contains 34 prose sections. They are decomposed into 64 atomic, testable DQGs so no implementation can satisfy a broad heading while silently skipping a subordinate requirement. Publication is fail-closed. DQG-064 is the aggregate gate.

| DQG | Atomic requirement | Freeze-candidate coverage |
|---|---|---|
| DQG-001 | Exactly four options | §§1–2, 31, 33–34 |
| DQG-002 | Exactly one valid BEST-answer key | §§1–2, 27–29, 31, 33–34 |
| DQG-003 | Exactly three distractor evidence records matching the three non-key option indexes | §§1–2, 29, 33–34 |
| DQG-004 | Question and all distractors are DQ6 | §§2–5, 29–34 |
| DQG-005 | Every distractor plausibility score is exactly 5/5 | §§2, 4, 29–34 |
| DQG-006 | Every distractor Truth Component Score is exactly 4/4 | §§2, 5, 29–34 |
| DQG-007 | KEY↔distractor confusability is exactly 4/5 for all three | §§14, 29, 34 |
| DQG-008 | Computed DQS is exactly 100/100 | §§2, 30–34 |
| DQG-009 | Unresolved external block count is zero | §§2, 31–33 |
| DQG-010 | Unresolved external fail count is zero | §§2, 31–33 |
| DQG-011 | Unresolved warning count is zero | §32 |
| DQG-012 | No publication override is requested or supported | §§2, 32–33 |
| DQG-013 | Exactly one answer is defensible as BEST | §§1, 3, 27–29, 34 |
| DQG-014 | Human/SME review is complete | §§12, 27, 31–32 |
| DQG-015 | All mandatory structured quality evidence is present | §§8, 31–33 |
| DQG-016 | Frozen exact thresholds are enforced with no rounding or tolerance | §§2, 4–5, 14, 30, 33–34 |
| DQG-017 | Every distractor role is `expert_near_miss` | §§1, 3, 8, 29, 34 |
| DQG-018 | All options occupy the same technical answer universe and professional level | §§3–4, 15, 21 |
| DQG-019 | Every distractor is substantially technically correct, terminology-valid, and relevant to the actual decision/hazard | §§3–5, 15 |
| DQG-020 | Every distractor has one dominant fatal flaw | §§3, 5–6, 29, 31 |
| DQG-021 | No distractor contains multiple unrelated defects | §§6, 31 |
| DQG-022 | The three distractors use meaningfully distinct failure mechanisms/families | §§7, 29, 31 |
| DQG-023 | The three misconception fingerprints are unique | §§7–8, 29, 31 |
| DQG-024 | Every distractor represents a sophisticated, professionally credible reasoning pathway | §§3–4, 21–22 |
| DQG-025 | Every distractor has a specific `targetedMisconception` | §§8, 31 |
| DQG-026 | Every distractor has a specific `whyTempting` rationale | §§4, 8, 31 |
| DQG-027 | Every distractor has a specific `fatalFlaw` explanation | §§6, 8, 31 |
| DQG-028 | Every distractor has non-empty, validated scenario evidence anchors | §§8, 10, 31, 33 |
| DQG-029 | Every distractor documents its substantial `technicalTruth` | §§5, 8 |
| DQG-030 | Every distractor documents the decisive `keyDifference` | §§8, 12, 29 |
| DQG-031 | Every distractor documents `counterfactualToBecomeCorrect` | §§8, 13, 31 |
| DQG-032 | Every distractor family is recognized or explicitly technically justified | §§8–9 |
| DQG-033 | At least two decisive scenario facts/technical conditions must be integrated | §§3, 10 |
| DQG-034 | Criterion matrix is complete | §11 |
| DQG-035 | KEY satisfies every material criterion and every BEST-answer completeness dimension | §§3, 11, 28 |
| DQG-036 | Every distractor fails at least one decisive material criterion | §§11, 28–29 |
| DQG-037 | Specific KEY>D1 superiority proof exists | §12 |
| DQG-038 | Specific KEY>D2 superiority proof exists | §12 |
| DQG-039 | Specific KEY>D3 superiority proof exists | §12 |
| DQG-040 | Every counterfactual is minimal and plausible | §13 |
| DQG-041 | Grammar, answer type, and professional-level parity are satisfied | §§15, 18, 21 |
| DQG-042 | Specificity and detail parity are satisfied | §§15, 17, 21 |
| DQG-043 | Surface metrics are complete and there is no material length/clause cue | §§15–16, 21 |
| DQG-044 | Terminology, units, precision, and conditional-wording parity are satisfied | §§15, 21 |
| DQG-045 | No linguistic, formatting, or answer-position cue exists | §§18, 21 |
| DQG-046 | No KEY-specific keyword leakage shortcut exists | §§3, 19 |
| DQG-047 | No absolute/certainty-language shortcut exists | §20 |
| DQG-048 | No non-technical elimination shortcut exists | §§3, 21 |
| DQG-049 | KEY requires no unstated assumption | §25 |
| DQG-050 | Assumptions are explicitly documented with scenario support; any KEY assumption is supported | §25 |
| DQG-051 | No KEY/distractor equivalence arises from an unstated assumption | §§25, 27 |
| DQG-052 | At least one authoritative source supports the KEY and source authority is verified | §26 |
| DQG-053 | Source support exists for every distractor-rejection distinction | §26 |
| DQG-054 | No unsupported microscopic distinction is used | §26 |
| DQG-055 | Ambiguity firewall: no distractor is equally defensible from the stated stem | §27 |
| DQG-056 | Qualified-SME exact rejection proof exists for all three distractors | §§3, 12, 27, 31 |
| DQG-057 | No duplicate or semantically equivalent options exist | §§31, 33 |
| DQG-058 | Numerical questions have provenance for every distractor and consistent calculations | §23, 31 |
| DQG-059 | Answer key is independently verified and points to a valid option | §31 |
| DQG-060 | Stem contains sufficient information; no required decision data are missing | §§1, 27, 31 |
| DQG-061 | Item tests the intended competency rather than trivia | §§1, 3, 31 |
| DQG-062 | Wrong-level correctness is permitted only with a documented requested-level distinction | §24 |
| DQG-063 | Sophistication parity is satisfied and an advanced-sounding distractor exists when applicable | §22 |
| DQG-064 | Publishable iff DQG-001..063 all PASS, computed DQS=100, and final status is PASS; otherwise BLOCK | §§29–34 |

## Non-negotiable semantics

- The validator computes DQS; incoming `dqs` values are never trusted.
- Semantic requirements are not guessed from keywords. They require structured quality evidence.
- Missing evidence is a BLOCK.
- There is no override parameter or reduced-quality publication route.
- A DQS of 100 does not bypass any DQG. All gates must pass independently.
- DQG-064 is derived. It cannot be manually set.
