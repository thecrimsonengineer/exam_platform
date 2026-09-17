# CSP11 Quiz Quality Validator
## Frozen DQ6 Distractor Engineering Standard — Freeze Candidate

**Status:** FREEZE CANDIDATE — NOT YET FROZEN  
**Branch:** `phase-q-quiz-quality-validator-freeze-candidate`  
**Base production architecture commit:** `815b25b5a19f2d8d6cc400b103121ba29d3098d2`  
**Purpose:** Candidate specification for the CSP11 Quiz Quality Validator before implementation and final freeze.

> This document is the authoritative freeze candidate. No threshold in this document may be weakened during implementation without an explicit specification change and review.

---

## 1. Purpose

The CSP11 Quiz Quality Validator shall enforce an exceptionally demanding one-BEST-answer assessment standard.

Every published CSP11 question shall contain exactly:

- 1 BEST answer
- 3 distractors
- 4 options in total

The three incorrect options are not filler answers.

Every distractor shall be an **expert-level near miss** that appears technically defensible during superficial analysis but becomes incorrect when the learner applies the complete technical principle, all relevant scenario evidence, the correct causal level, correct priority, correct assumptions, or correct calculation pathway.

The assessment objective is:

> A knowledgeable learner must discriminate precisely between four highly credible alternatives. An expert applying the complete scenario and technical principle must still be able to identify exactly one defensible BEST answer.

Difficulty shall never depend on ambiguity, deceptive wording, obscure trivia, grammatical tricks, or missing information.

---

## 2. Frozen Publication Standard

A question may be published only when ALL of the following are true:

```text
Question Difficulty Level = DQ6

Distractor 1 Plausibility = 5/5
Distractor 2 Plausibility = 5/5
Distractor 3 Plausibility = 5/5

Distractor 1 Truth Component Score = 4/4
Distractor 2 Truth Component Score = 4/4
Distractor 3 Truth Component Score = 4/4

DQS = 100/100

All BLOCK gates = PASS
All mandatory FAIL gates = PASS
All ambiguity checks = PASS
All source-support checks = PASS
All option-equivalence checks = PASS
All BEST-answer superiority checks = PASS
```

There is no publication override for:

```text
DQ5
DQS 99
Distractor Plausibility 4
Truth Component Score 3
Unresolved ambiguity
Missing rationale
Incomplete source support
```

Any one of these means:

```text
PUBLICATION BLOCKED
```

---

## 3. DQ6 Definition

`DQ6` is the mandatory difficulty level for every CSP11 question.

A DQ6 question shall meet all of the following conditions:

1. All four options belong to the same technical answer universe.
2. All three distractors are credible to a well-prepared learner.
3. Each distractor is substantially correct except for one decisive technical defect.
4. At least two scenario facts or technical conditions must normally be integrated to identify the BEST answer.
5. Superficial keyword matching shall not reveal the answer.
6. Familiarity with terminology alone shall not reveal the answer.
7. Elimination based on grammar, option length, formatting, category mismatch, or absurdity shall not be possible.
8. Each distractor shall represent a sophisticated reasoning pathway.
9. Exactly one option shall satisfy every material requirement of the stem.
10. A qualified SME shall be able to explain precisely why each distractor fails.
11. Each distractor should normally become correct or defensible after a small and plausible change to the scenario.
12. The learner must distinguish the BEST answer through technical reasoning rather than test-taking technique.

DQ6 therefore represents:

> **Expert near-miss discrimination requiring complete technical and scenario integration.**

---

## 4. Distractor Plausibility Score

Every distractor shall score exactly:

```text
5 / 5
```

### Score 5 definition

A Score-5 distractor:

- belongs to the correct technical domain;
- uses correct professional terminology;
- addresses the actual hazard, system, control, calculation, or decision;
- contains substantial technical truth;
- would be selected by an informed learner following an incomplete reasoning pathway;
- differs from the BEST answer through a minute but decisive defect;
- cannot be eliminated without applying subject knowledge;
- remains credible after careful first reading;
- requires comparison against the complete stem;
- could plausibly appear in professional practice.

Anything less than 5 shall fail.

```text
Plausibility 0 = BLOCK
Plausibility 1 = BLOCK
Plausibility 2 = BLOCK
Plausibility 3 = BLOCK
Plausibility 4 = BLOCK
Plausibility 5 = PASS
```

---

## 5. Truth Component Score

Every distractor shall have:

```text
Truth Component Score = 4 / 4
```

### Truth Component Score 4 definition

The distractor is:

> **Almost completely technically correct but invalid because of one decisive condition, limitation, assumption, priority, classification, timing requirement, causal level, calculation relationship, equipment specification, or scenario fact.**

The distractor must not be generally false.

Example weak distractor:

> Use training instead of controlling the airborne contaminant.

This is too obviously inferior.

Example DQ6 distractor:

> Use a powered respirator with a higher assigned protection factor while retaining the existing organic-vapour-only filtration.

This contains substantial technical truth:

- a powered respirator is legitimate equipment;
- APF is relevant;
- increased protection may be appropriate;
- vapour filtration is relevant.

Its fatal defect is narrow:

> The filtration remains unsuitable for the simultaneous particulate exposure.

That is Truth Component Score 4.

---

## 6. Single Fatal Flaw Requirement

Each distractor shall contain one dominant fatal flaw.

Preferred structure:

```text
Correct hazard recognition
+
Correct technical family
+
Correct professional terminology
+
Correct general objective
+
Correct partial reasoning
+
ONE decisive defect
=
DQ6 DISTRACTOR
```

The distractor shall not contain several unrelated errors.

### PASS

```text
Correct method
Correct variable
Correct equation family
Wrong dependency assumption
```

### FAIL

```text
Wrong method
Wrong units
Wrong hazard
Wrong equipment
Wrong sequence
```

The second option is too damaged to function as an expert near miss.

---

## 7. Mandatory Distractor Diversity

The three distractors shall fail for three meaningfully different reasons.

Example:

```text
D1 = incomplete hazard integration
D2 = correct control but incorrect priority
D3 = sophisticated assumption error
```

Prohibited:

```text
D1 = incomplete control
D2 = another incomplete control
D3 = differently worded incomplete control
```

Cosmetic differences do not count as reasoning diversity.

Each distractor shall have a unique:

```text
misconceptionFingerprint
```

---

## 8. Mandatory Distractor Metadata

Every distractor shall contain internal metadata equivalent to:

```json
{
  "role": "expert_near_miss",
  "difficultyLevel": "DQ6",
  "plausibilityScore": 5,
  "truthComponentScore": 4,
  "family": "D_PARTIAL",
  "targetedMisconception": "...",
  "whyTempting": "...",
  "fatalFlaw": "...",
  "scenarioEvidence": ["...", "..."],
  "technicalTruth": "...",
  "keyDifference": "...",
  "counterfactualToBecomeCorrect": "...",
  "misconceptionFingerprint": "..."
}
```

Missing required metadata:

```text
BLOCK
```

---

## 9. Distractor Families

CSP11 may use families including:

```text
D-COND       Correct principle under wrong condition
D-SCOPE      Incomplete coverage of the problem
D-PRIORITY   Correct action but wrong priority
D-HIER       Correct control at inferior hierarchy level
D-CAUSE      Correct fact at wrong causal level
D-TIME       Correct action at wrong stage or sequence
D-METHOD     Valid method used for wrong problem
D-ASSUME     Reasoning depends on unsupported assumption
D-PARTIAL    Nearly complete answer missing one condition
D-OVER       More sophisticated intervention that misses decisive mechanism
D-UNDER      Valid but insufficient control
D-CLASS      Adjacent classification error
D-MEASURE    Correct metric family but wrong quantity
D-DENOM      Wrong denominator
D-COMP       Complement-rule error
D-SEQ        Correct actions in incorrect sequence
D-STANDARD   Correct guidance family but wrong provision or scope
D-DEVICE     Correct equipment family with unsuitable specification
D-THRESHOLD  Correct concept with incorrect threshold application
D-EXPOSURE   Correct hazard with incomplete exposure reasoning
D-EFFECT     Cause/effect relationship reversed
D-RELIAB     Correct reliability concepts used incorrectly
D-HUMAN      Surface human error instead of requested systemic mechanism
D-BARRIER    Prevention/mitigation barrier role confusion
D-LOPA       Valid safeguard that fails IPL qualification
D-FTA        Correct events with wrong gate logic
D-ETA        Correct sequence with wrong success/failure branch
```

Other families may be added where technically justified.

---

## 10. Scenario Integration Requirement

Every DQ6 question must normally require integration of multiple pieces of information.

Preferred structure:

```text
Scenario Fact A
Scenario Fact B
Scenario Fact C
Technical Principle
Question Command
↓
BEST answer
```

Distractors should represent incomplete integration.

Example:

```text
D1 integrates A + B
D2 integrates B + C
D3 integrates A + C
KEY integrates A + B + C + technical principle
```

This is preferred over distractors that are simply textbook misconceptions.

---

## 11. Criterion Matrix Requirement

Before final validation the system shall create a decision matrix.

Example:

| Criterion | KEY | D1 | D2 | D3 |
|---|---:|---:|---:|---:|
| Correct hazard | ✓ | ✓ | ✓ | ✓ |
| Correct control family | ✓ | ✓ | ✓ | ✓ |
| Correct scope | ✓ | ✗ | ✓ | ✓ |
| Correct timing | ✓ | ✓ | ✗ | ✓ |
| Supported assumption | ✓ | ✓ | ✓ | ✗ |
| Complete response | ✓ | ✗ | ✗ | ✗ |

The KEY must satisfy:

```text
100% of material criteria
```

Every distractor must fail:

```text
at least one decisive criterion
```

but remain otherwise highly credible.

---

## 12. Pairwise Key Superiority Test

The validator must establish:

```text
KEY > D1
KEY > D2
KEY > D3
```

Each comparison requires a specific explanation.

Example:

```text
KEY > D1 because D1 does not address the simultaneous particulate exposure.

KEY > D2 because D2 addresses both contaminants but assumes a receiving hood can capture emissions without the required contaminant trajectory.

KEY > D3 because increased APF does not correct unsuitable filtration.
```

Statements such as:

```text
D1 is less appropriate.
D2 is not the best answer.
D3 is incorrect.
```

shall fail.

---

## 13. Counterfactual Validation

Each distractor shall specify the smallest plausible change that would make it correct or defensible.

Example:

```text
D1 becomes correct if particulate is the only respiratory contaminant.

D2 becomes correct if contaminant movement reliably carries the plume into the receiving hood.

D3 becomes correct if filtration is already suitable and inadequate APF is the remaining problem.
```

A distractor requiring complete rewriting of the scenario is usually too remote from the KEY.

---

## 14. Pairwise Confusability Requirement

Every distractor shall be closely related to the KEY.

Internal scale:

```text
0 unrelated
1 weakly related
2 same broad field
3 same concept family
4 expert-level close competitor
5 effectively equivalent
```

For CSP11 DQ6:

```text
KEY ↔ D1 = 4
KEY ↔ D2 = 4
KEY ↔ D3 = 4
```

Anything below 4:

```text
BLOCK
```

Anything equal to 5:

```text
BLOCK FOR AMBIGUITY
```

Therefore the only acceptable value is:

```text
4
```

---

## 15. Option Homogeneity Gate

All four options shall have comparable:

- technical domain;
- professional level;
- grammatical structure;
- specificity;
- length;
- terminology;
- degree of detail;
- units;
- numerical precision;
- conditional wording.

A learner must not be able to identify the KEY because one option appears more professional.

---

## 16. Length Balance Gate

Measure:

```text
characterCount
wordCount
clauseCount
technicalTermCount
qualifierCount
```

The KEY shall not be uniquely longer or uniquely shorter in a way that provides a cue.

Hard publication requirement:

```text
No material option-length cue
```

Any detected cue that could support test-wise elimination:

```text
BLOCK
```

---

## 17. Specificity Parity Gate

If the KEY contains:

```text
equipment type
location
distance
process condition
numerical threshold
technical qualifier
```

then distractors shall contain comparable specificity where technically appropriate.

The KEY shall never look like the only option written by a subject-matter expert.

---

## 18. Linguistic Cue Gate

Reject items where the correct answer is identifiable through:

- grammatical agreement;
- repeated wording;
- distinctive terminology;
- wording copied from the stem;
- different tense;
- different voice;
- unusual capitalization;
- excessive precision;
- unique parenthetical explanation;
- unique qualification.

No answer-position or linguistic cue is permitted.

---

## 19. Keyword Leakage Gate

The validator shall compare lexical overlap between the stem and all four options.

Excessive unique overlap between the stem and KEY:

```text
BLOCK
```

unless the shared terminology is technically unavoidable and comparably represented across the distractors.

---

## 20. Absolute-Language Gate

Words such as:

```text
always
never
only
completely
guarantees
eliminates
under all circumstances
```

shall receive additional scrutiny.

If such wording makes a distractor easy to eliminate:

```text
BLOCK
```

---

## 21. Elimination Resistance Gate

Every option must survive non-technical elimination.

A learner shall not be able to reject an option because it is:

- absurd;
- unrelated;
- grammatically different;
- much shorter;
- much longer;
- from another technical category;
- numerically ridiculous;
- obviously unsafe;
- obviously overgeneralised.

Required standard:

> **Every elimination must require relevant subject knowledge or scenario reasoning.**

---

## 22. Advanced-Sounding Distractor Requirement

Where technically appropriate at least one distractor should be capable of sounding as sophisticated as, or more sophisticated than, the KEY.

Sophisticated terminology shall not be reserved for correct answers.

Example:

```text
KEY:
Use the suitable combination particulate and organic-vapour filtration.

DISTRACTOR:
Use a powered respirator with a higher assigned protection factor while retaining the existing organic-vapour filtration.
```

The second option sounds more advanced but remains wrong for a precise technical reason.

---

## 23. Numerical Distractor Requirement

For calculation questions every distractor shall originate from a valid reasoning pathway.

Required metadata:

```text
distractorCalculationPath
```

Examples:

```text
wrong complement
AND/OR inversion
series/parallel inversion
incorrect denominator
incorrect event frequency conversion
PFD/RRF inversion
wrong conditional probability step
premature rounding
```

Random numerical values are prohibited.

---

## 24. Wrong-Level Correctness Gate

A distractor may contain a true statement if it answers the wrong level of the question.

Examples:

```text
Immediate cause
Contributing factor
Underlying cause
Root organisational failure
```

All may be true scenario observations.

Only one may answer the specific command.

This is permitted and encouraged when the distinction is technically defensible.

---

## 25. Assumption Control Gate

The KEY shall not require an unstated assumption.

Distractors may intentionally represent reasonable but unsupported assumptions.

The validator must document:

```text
assumptionUsed
scenarioSupport
```

If a distractor and KEY become equally valid depending on an unstated assumption:

```text
BLOCK FOR AMBIGUITY
```

---

## 26. Source Support Gate

The tested distinction must be supported by:

- authoritative source;
- recognised technical principle;
- published guidance;
- accepted calculation;
- applicable standard;
- validated course source.

The source must support not merely the KEY but also the distinction used to reject the distractors.

Unsupported microscopic distinctions:

```text
BLOCK
```

---

## 27. Ambiguity Firewall

This is absolute.

Ask:

> Could a competent SME reasonably defend any distractor as equally correct using only the information provided in the stem?

If:

```text
YES
```

then:

```text
BLOCK
```

DQ6 difficulty shall never be produced through uncertainty about what the question means.

---

## 28. BEST-Answer Completeness Gate

The KEY must satisfy every explicit and implicit material condition required by the stem.

Test:

```text
Hazard
Scope
Timing
Priority
Mechanism
Technical principle
Scenario conditions
Command word
Calculation
Assumptions
```

One unmet material condition:

```text
BLOCK
```

---

## 29. Three-Distractor Strength Rule

All three distractors shall independently satisfy:

```text
DQ6
Plausibility = 5
Truth Component = 4
Pairwise Confusability with KEY = 4
Unique Fatal Flaw = PASS
Unique Misconception Fingerprint = PASS
Scenario Anchoring = PASS
Counterfactual Validation = PASS
Technical Homogeneity = PASS
Elimination Resistance = PASS
```

There shall be no "strongest distractor plus two weaker distractors."

All three are expert near misses.

---

## 30. DQS 100-Point Model

Every CSP11 question must receive exactly:

```text
100 / 100
```

Scoring model:

| Category | Required |
|---|---:|
| Three distractors at plausibility 5 | 10/10 |
| Three Truth Component Scores at 4 | 10/10 |
| DQ6 compliance | 10/10 |
| Scenario integration | 10/10 |
| Distinct misconception targeting | 10/10 |
| Single-fatal-flaw quality | 10/10 |
| Pairwise confusability = 4 for all | 10/10 |
| Linguistic / length / specificity parity | 10/10 |
| Elimination resistance | 10/10 |
| BEST-answer superiority and ambiguity proof | 10/10 |
| **TOTAL** | **100/100** |

No rounding.

No tolerance.

```text
99 = FAIL
100 = PASS
```

---

## 31. Hard-Fail Conditions

The following always block publication regardless of any other score:

```text
More than one defensible answer

Any distractor plausibility below 5

Any distractor Truth Component Score below 4

Question below DQ6

DQS below 100

Semantic duplicate options

Duplicate misconception fingerprints

Distractor outside the technical answer universe

Distractor lacking a single identifiable fatal flaw

Distractor containing several unrelated defects

Weak or absurd distractor

Missing scenario evidence

Missing temptation rationale

Missing counterfactual

Missing source support

Unsupported assumption in KEY

KEY identifiable by wording or formatting

KEY uniquely detailed

KEY uniquely long or short in a cueing manner

Numerical distractor without reasoning provenance

Calculation inconsistency

Incorrect answer key

Question relies on trivia rather than intended competency

Question requires information absent from the stem

Unresolved ambiguity

Distractor and KEY become equivalent under the stated scenario

SME cannot explain the exact technical distinction
```

---

## 32. Validator Status

The validator shall produce only:

```text
PASS
BLOCK
```

for publication eligibility.

Warnings may exist during authoring but:

> A question with unresolved warnings shall not reach the published state.

Therefore final publication status requires:

```text
BLOCK_COUNT = 0
FAIL_COUNT = 0
WARNING_COUNT = 0
DQS = 100
DQ_LEVEL = DQ6
```

---

## 33. Recommended Machine Rule

```text
PUBLISHABLE =
    optionCount == 4
    AND keyCount == 1
    AND distractorCount == 3
    AND difficultyLevel == DQ6
    AND everyDistractor.plausibilityScore == 5
    AND everyDistractor.truthComponentScore == 4
    AND everyDistractor.confusabilityScore == 4
    AND everyDistractor.singleFatalFlaw == true
    AND allDistractorMisconceptionsAreDistinct == true
    AND allScenarioAnchorsValid == true
    AND allCounterfactualsValid == true
    AND keyUniquelySuperior == true
    AND ambiguityDetected == false
    AND eliminationShortcutDetected == false
    AND sourceSupportComplete == true
    AND dqs == 100
    AND blockCount == 0
    AND failCount == 0
    AND warningCount == 0
```

Anything else:

```text
NOT PUBLISHABLE
```

---

## 34. Frozen CSP11 Question Philosophy

The final freeze-candidate principle is:

> **Every CSP11 question shall contain one uniquely defensible BEST answer and three DQ6 expert near-miss distractors. Every distractor shall be substantially technically correct, score 5/5 for plausibility, achieve a Truth Component Score of 4/4, remain closely confusable with the BEST answer, contain one precise fatal flaw, target a unique sophisticated misconception, and require genuine subject knowledge to eliminate. Every question must achieve DQS 100/100 and pass every quality, ambiguity, source, scenario, calculation, linguistic, and BEST-answer superiority gate before publication. No reduced-quality question shall be published.**

### Freeze-candidate thresholds

```text
QUESTION DIFFICULTY
DQ6 ONLY

DISTRACTOR PLAUSIBILITY
5 / 5
5 / 5
5 / 5

TRUTH COMPONENT
4 / 4
4 / 4
4 / 4

KEY ↔ DISTRACTOR CONFUSABILITY
4 / 5
4 / 5
4 / 5

DQS
100 / 100

BLOCKS
0

FAILURES
0

WARNINGS
0

DEFENSIBLE BEST ANSWERS
Exactly 1

DISTRACTORS
Exactly 3

PUBLICATION RESULT
PASS ONLY WHEN EVERY CONDITION ABOVE IS SATISFIED
```

---

## 35. Freeze-Candidate Governance

This file is intentionally committed as a **freeze candidate** rather than an already-frozen implementation contract.

Until explicit freeze approval:

- no validator implementation should weaken or reinterpret these thresholds;
- no production merge is implied by this candidate commit;
- no existing frozen question-bank architecture is changed by this document;
- any implementation proposal should map deterministic rule IDs to this specification;
- the final freeze should preserve the DQ6-only requirement, all three 5/5 plausibility requirements, all three 4/4 truth-component requirements, DQS 100/100, zero unresolved warnings, and exactly one defensible BEST answer.

The intended next step after approval is to translate this candidate into deterministic validator rules such as `DQG-001` onward and map them into the CSP11 question-quality validation pipeline without weakening any threshold above.
