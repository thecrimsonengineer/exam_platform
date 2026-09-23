# CSP11 Phase ML-4 - Factual / Legal-Status Gates

Status: IMPLEMENTED  
Parent: `docs/micro_learning/PHASE_ML3_SOURCE_GATES.md`  
Branch: `phase-ml4-factual-legal-status-gates`

## Purpose

ML-4 validates whether an approved first-party source is represented with the correct legal weight, jurisdictional context and learner-facing wording.

ML-3 answers:

> Is this source genuinely from an approved authority?

ML-4 answers:

> Is CSP11 describing what that kind of source means without silently turning guidance into law, a standard into a regulation, a recommendation into a mandate, or a numerical claim into unsupported precision?

ML-4 remains deterministic and local. It performs no runtime web request and adds no backend dependency.

## Delivered artifacts

- `content/micro_learning/claim_semantics_policy_v1.json`
- `lib/services/micro_learning/claim_semantics_policy_validator.dart`
- `lib/services/micro_learning/micro_fact_claim_gate_validator.dart`
- `test/micro_learning/claim_semantics_policy_validator_test.dart`
- `test/micro_learning/micro_fact_claim_gate_validator_test.dart`
- `tool/validate_micro_learning_claim_gates.dart`
- `docs/micro_learning/PHASE_ML4_FACTUAL_LEGAL_STATUS_GATES.md`

## Prerequisite chain

ML-4 fails closed unless the fact already passes:

1. ML-1 Authority Registry
2. ML-2 MicroFact schema
3. ML-3 source gates
4. ML-4 claim-semantics policy integrity

A fact cannot bypass a lower gate by reaching ML-4 directly.

## Frozen claim-semantics policy

The policy is versioned:

```text
Claim Semantics Policy 1.0.0
Authority Registry 1.0.0
MicroFact Schema 1
```

The policy validator rejects:

- unknown root fields;
- missing root fields;
- altered source-class coverage;
- broadened legal-status mappings;
- weakened mandatory-language rules;
- removed authority attribution families;
- reduced mandatory-term vocabulary;
- disabled human technical review;
- insufficient numerical-signal coverage;
- malformed numerical regex patterns;
- unknown authority IDs in authority-specific safeguards.

This prevents a fact from being made valid by quietly weakening the policy underneath it.

## Source-class to legal-status contract

| Source class | Permitted legal status |
|---|---|
| `federal_regulation` | `binding_requirement` |
| `regulatory_interpretation` | `regulatory_interpretation` |
| `enforcement_or_compliance_guidance` | `nonbinding_guidance` |
| `government_recommendation` | `recommendation`, or `not_applicable` only for permitted tip categories |
| `research_or_prevention_guidance` | `recommendation`, `research_finding`, or `not_applicable` only for permitted tip categories |
| `consensus_standard` | `consensus_standard` |
| `international_standard` | `international_standard` |
| `professional_guideline` | `professional_guideline`, or `not_applicable` only for permitted tip categories |
| `professional_framework` | `professional_framework`, or `not_applicable` only for permitted tip categories |
| `environmental_regulation` | `binding_requirement` |
| `transportation_regulation` | `binding_requirement` |
| `emergency_management_framework` | `professional_framework`, or `not_applicable` only for permitted tip categories |
| `process_safety_framework` | `professional_framework` |
| `loss_prevention_guidance` | `professional_guideline` |
| `testing_or_certification_standard` | `certification_or_testing` |

A source class cannot choose a more forceful legal status merely because the wording sounds authoritative.

## Regulatory-authority gate

A MicroFact may use:

- `binding_requirement`; or
- `regulatory_interpretation`

only when the selected ML-1 authority is marked as a regulatory authority.

This prevents NIOSH, ACGIH, ANSI/ASSP, ISO, NFPA, AIHA, CCPS, NSC, ASSP literature, FM or UL from being represented as creating a federal legal duty merely through a metadata change.

## Jurisdiction gates

Jurisdiction is mandatory for:

- federal regulation;
- regulatory interpretation;
- enforcement/compliance guidance;
- environmental regulation;
- transportation regulation;
- any claim with legal status `binding_requirement`;
- any claim with legal status `regulatory_interpretation`.

A `not_applicable` legal-status claim must not carry jurisdiction.

This avoids startup statements that read as universal law when they only apply within a defined legal system.

## Mandatory-language policy

ML-4 monitors learner-facing wording for terms such as:

```text
must
shall
required
requires
mandated
mandates
prohibited
prohibits
may not
```

Source classes are assigned one of three modes.

### allowed

Binding regulatory source classes may use mandatory wording.

If mandatory language is shown, the learner-facing variant must identify the authority or regulatory context.

For example:

```text
OSHA requires...
29 CFR requires...
EPA requires...
PHMSA requires...
```

is structurally distinguishable from an unattributed universal statement.

### attributed_only

Regulatory interpretations, consensus standards, international standards and testing/certification standards may use requirement language only when that requirement is explicitly attributed to the source.

For example:

```text
ISO 45001 requires...
NFPA 70E requires...
OSHA interprets...
```

This communicates a requirement inside that source without falsely presenting it as universal law.

### blocked

Recommendations, professional guidance, professional frameworks, loss-prevention guidance and similar non-binding classes may not be expressed with mandatory legal wording.

## Full and short display variants are separate claims

ML-4 validates:

- `display.displayText`
- `display.shortVariant`

independently.

This is essential because fast startup may show only the short variant.

A compliant full statement cannot rescue a misleading short statement.

Example:

```text
Full:
ISO 45001 requires specified documented information.

Short:
Organizations must keep the required documents.
```

The short form fails because it loses the ISO attribution.

## False legal-equivalence gate

Non-binding material cannot use phrases that imply statutory force, including frozen expressions such as:

- required by law;
- legally required;
- federal law requires;
- statutory requirement;
- has the force of law.

A consensus standard, professional guideline or recommendation therefore cannot silently become law through prose.

## Authority-specific semantic safeguards

ML-4 adds targeted protections where recurring confusion is especially likely.

### NIOSH / CDC

The policy blocks constructions such as:

- NIOSH requires;
- required by NIOSH;
- NIOSH regulation;
- NIOSH mandates.

This does not deny that NIOSH administers limited program-specific regulations. It prevents ordinary NIOSH research/prevention guidance used under the frozen CSP11 source classes from being represented as a general workplace mandate.

### ACGIH

The policy blocks constructions such as:

- ACGIH PEL;
- ACGIH permissible exposure limit;
- ACGIH requires;
- TLV is an OSHA PEL;
- TLV is a legal limit.

This protects the distinction between ACGIH TLV/BEI guidance and regulatory exposure limits.

### AIChE / CCPS

The policy blocks wording that would turn CCPS frameworks into regulation or equate RBPS with OSHA PSM.

### FM

FM loss-prevention guidance cannot be represented as an FM regulation or statutory requirement.

### UL

UL listing or certification cannot be described as regulatory approval merely because a product is listed or certified.

## CSP Tip and Learning Tip legal status

The categories:

- `csp_tip`
- `learning_tip`

must use:

```text
legalStatus = not_applicable
```

They may still require an approved authority source under the frozen CSP11 source policy, but the legal-status field must not imply that the learning advice itself carries regulatory force.

Other categories may not use `not_applicable`.

## Factual review floor

At lifecycle states:

- `validated`
- `published`

every fact must have:

```text
technicalStatus = pass
sourceStatus = pass
```

Technical categories must additionally have:

```text
humanTechnicalStatus = pass
```

This preserves the ML-0 decision that technical micro-learning content cannot silently self-validate.

## Technical categories

Human technical approval is mandatory at validated/published lifecycle for:

- safety insight;
- quick recall;
- think about it;
- process safety insight;
- industrial hygiene insight;
- emergency insight;
- environmental insight;
- fire/electrical insight;
- management insight;
- transport insight.

## Numerical-claim gates

ML-4 detects common numerical safety signals in learner-facing text, including patterns for:

- percentages;
- ppm;
- ppb;
- mg/m3;
- dBA/dB;
- temperature;
- volts/kV;
- psi;
- distance;
- seconds/minutes/hours/days.

If such wording is detected while:

```text
numericalClaim = false
```

the fact fails.

For a validated or published numerical claim:

- technical review must pass;
- source review must pass;
- human technical review must pass;
- at least one of edition/revision, source section or source page must identify the evidence location.

The detector is an additional safety net. It does not replace technical review.

## Safety-critical gates

At validated or published lifecycle, a fact marked:

```text
safetyCritical = true
```

requires:

- technical review pass;
- source review pass;
- human technical review pass.

The same enhanced review applies to:

```text
simplificationRisk = high
```

## Legal-source location gate

Validated or published claims classified as:

- `binding_requirement`; or
- `regulatory_interpretation`

must have a source section or page in addition to the general source locator.

A legal claim cannot rely only on metadata such as:

```text
homepage
website
general
about
source
```

## Generic-source-locator gate

At validated or published lifecycle, generic source locators are rejected.

The frozen generic list includes:

- homepage;
- website;
- general;
- about;
- source;
- n/a;
- na;
- not applicable.

The source locator must identify where the claim can actually be reviewed.

## What ML-4 means by "factual gate"

ML-4 can deterministically verify:

- source-class/legal-status consistency;
- authority regulatory role;
- jurisdiction presence;
- legal wording consistency;
- authority attribution;
- common authority-specific misattributions;
- numerical metadata consistency;
- review completion;
- evidence-location metadata.

ML-4 does not pretend that local string analysis proves the scientific or legal truth of every sentence.

Actual claim support still requires source review and human technical approval. That is why those review channels are hard gates at validated/published lifecycle.

This is intentional. CSP11 must prefer a transparent human-review requirement over a false claim that a lexical validator can prove technical truth.

## Test coverage

The ML-4 suite covers:

- valid frozen fixture;
- all frozen source-class policy paths;
- non-regulator presented as binding authority;
- missing regulatory jurisdiction;
- NIOSH mandatory-language misuse;
- ACGIH PEL/legal-limit misuse;
- attributed ISO requirement wording;
- unattributed ISO mandatory wording;
- false legal equivalence;
- independent short-variant validation;
- OSHA interpretation without attribution;
- attributed OSHA interpretation;
- invalid `not_applicable` use;
- CSP Tip legal-status enforcement;
- numerical signal without numerical flag;
- missing numerical evidence location;
- missing enhanced numerical review;
- missing human technical approval;
- missing technical/source review;
- generic source locator;
- legal claim without section/page;
- policy tampering.

The separate policy suite also tests quiet policy weakening.

## Deliberately deferred

ML-4 does not implement:

- copyright/provenance evidence gates - ML-5;
- canonical curriculum existence checks - ML-6;
- startup readability and pedagogy gates - ML-7;
- semantic duplicate/contradiction detection - ML-8;
- production fact authoring - ML-9;
- runtime fact repository or startup UI - ML-10 onward.

## Verification

From repository root:

```powershell
dart run tool/validate_micro_learning_claim_gates.dart

flutter test \
  test/micro_learning/claim_semantics_policy_validator_test.dart \
  test/micro_learning/micro_fact_claim_gate_validator_test.dart
```

Expected CLI output begins:

```text
ML-4 FACTUAL / LEGAL-STATUS GATES VALID
```

## Exit criteria

- [x] Frozen legal-semantics policy created.
- [x] Policy integrity validator created.
- [x] Exact source-class/legal-status mappings enforced.
- [x] Regulatory-authority boundary enforced.
- [x] Jurisdiction requirements enforced.
- [x] Mandatory wording classified by source class.
- [x] Authority attribution enforced when required.
- [x] Full and short display variants validated independently.
- [x] False legal-equivalence phrases blocked.
- [x] NIOSH-specific misattribution controls added.
- [x] ACGIH TLV/PEL distinction protected.
- [x] CCPS, FM and UL semantic safeguards added.
- [x] CSP Tip / Learning Tip legal-status rule frozen.
- [x] Validated/published factual-review floor enforced.
- [x] Human technical approval enforced for technical categories.
- [x] Numerical signal/metadata mismatch detection added.
- [x] Enhanced numerical review enforced.
- [x] Safety-critical enhanced review enforced.
- [x] High-simplification-risk enhanced review enforced.
- [x] Generic source locators blocked at validated/published lifecycle.
- [x] Legal claims require section/page evidence location.
- [x] Policy tampering fails closed.
- [x] No production MicroFacts generated.
- [x] No startup UI changed.
- [x] No backend path added.
- [x] No runtime network request added.

## Next run

ML-5 - Copyright / Provenance Gates.

ML-5 must determine whether the recorded rights treatment and provenance evidence are acceptable for publication without weakening ML-1 through ML-4.
