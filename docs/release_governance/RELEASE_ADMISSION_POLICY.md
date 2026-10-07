# CSP11 REL-GOV-4 Release Admission Policy

Status: IMPLEMENTED CANDIDATE
Phase: REL-GOV-4
Repository: thecrimsonengineer/exam_platform
Base checkpoint: phase-rel-gov3-repository-provenance-closed
Base commit: 04f2585e29947127c6ad306b94ee474c8d77c818
Date: 2026-09-24

## 1. Purpose

REL-GOV-4 converts release evidence into one deterministic admission decision.

The engine does not publish a release and does not claim that a future release is production-ready. It answers one narrower question:

```
Does this candidate satisfy every blocking release-admission gate required by the frozen REL-GOV policy?
```

The only final decisions are:

```
ADMISSIBLE
BLOCKED
```

## 2. Fail-closed admission rule

The decision rule is frozen as:

```
blockingFailureCount == 0 -> ADMISSIBLE
blockingFailureCount > 0 -> BLOCKED
```

Unknown, missing, malformed or unverifiable required evidence is never interpreted as PASS.

The engine derives the decision. Callers cannot directly set it.

## 3. Policy-owned canonical gate registry

REL-GOV-4 owns the required gate inventory. A caller may provide gate observations but may not redefine a required gate name, severity or blocking status.

The canonical registry is:

| Gate | Name | Severity | Blocking |
|---|---|---|---|
| RG001 | repository_clean | ERROR | yes |
| RG002 | repository_identity | ERROR | yes |
| RG003 | version_valid | ERROR | yes |
| RG004 | build_number_valid | ERROR | yes |
| RG005 | dependency_lock | ERROR | yes |
| RG006 | environment_valid | ERROR | yes |
| RG007 | formatter | ERROR | yes |
| RG008 | analyzer | ERROR | yes |
| RG009 | unit_tests | ERROR | yes |
| RG010 | widget_tests | ERROR | yes |
| RG011 | schema_validation | ERROR | yes |
| RG012 | component_evidence | ERROR | yes |
| RG013 | artifact_inventory | ERROR | yes |
| RG014 | artifact_hashes | ERROR | yes |
| RG015 | provenance | ERROR | yes |
| RG016 | release_state | ERROR | yes |
| RG017 | manifest_completeness | ERROR | yes |

A missing canonical gate is a blocking policy failure.

A duplicate canonical gate is a blocking policy failure.

An unknown gate is a blocking policy failure. New governed gates must be introduced deliberately rather than silently accepted.

## 4. Gate record

Each supplied gate record contains:

```
gateId
name
status
severity
blocking
evidence
message
```

Allowed status vocabulary:

```
PASS
FAIL
NOT_APPLICABLE
```

Allowed severity vocabulary:

```
INFO
WARNING
ERROR
```

The current 17 canonical gates are all ERROR severity and blocking.

## 5. Evidence rule

A PASS is valid only when:

- the gate exists in the canonical policy
- the canonical name matches
- canonical severity matches
- canonical blocking status matches
- the message is non-empty
- at least one non-empty evidence reference exists
- evidence references within the gate are unique
- the status is PASS

This follows the REL-GOV-0 invariant that a required PASS must identify supporting evidence.

REL-GOV-4 validates evidence references as admission records. Later phases are responsible for generating, hashing and re-verifying the referenced evidence bytes.

## 6. FAIL semantics

FAIL on a blocking canonical gate creates a blocking admission issue.

A caller cannot change `blocking` to false to bypass the failure because the engine compares the supplied gate metadata against the policy-owned definition.

## 7. NOT_APPLICABLE semantics

NOT_APPLICABLE is rejected by default.

It is accepted only when the active admission policy explicitly lists that gate ID as permitted to be not applicable.

The default CSP11 admission policy permits no NOT_APPLICABLE exceptions.

An explicit policy exception removes a blocking failure but does not count the gate as PASS.

## 8. Admission policy issue codes

REL-GOV-4 defines these fail-closed policy issues:

```
RGA001_DUPLICATE_GATE
RGA002_UNKNOWN_GATE
RGA003_MISSING_REQUIRED_GATE
RGA004_GATE_NAME_MISMATCH
RGA005_GATE_SEVERITY_MISMATCH
RGA006_GATE_BLOCKING_MISMATCH
RGA007_GATE_MESSAGE_MISSING
RGA008_PASS_EVIDENCE_MISSING
RGA009_INVALID_EVIDENCE_REF
RGA010_DUPLICATE_EVIDENCE_REF
RGA011_NOT_APPLICABLE_NOT_PERMITTED
RGA012_REQUIRED_GATE_FAILED
```

Every emitted issue is blocking in REL-GOV-4.

## 9. Determinism

Input order does not change canonical gate output order.

Evaluated canonical gates are emitted in RG001 through RG017 order.

The engine uses frozen uppercase wire values for:

```
PASS
FAIL
NOT_APPLICABLE
INFO
WARNING
ERROR
ADMISSIBLE
BLOCKED
```

This gives later evidence-generation phases a stable machine contract.

## 10. Phase boundary

REL-GOV-4 owns:

- canonical admission gate definitions
- admission gate record semantics
- evidence-reference presence rules
- fail-closed structural validation
- deterministic admission decision
- deterministic admission-result serialization

REL-GOV-4 does not yet own:

- artifact discovery or SHA-256 generation
- build-environment discovery
- evidence-package generation
- GitHub release-candidate CI
- rollback execution
- final tamper regression
- application-store publication

Those remain in their frozen later REL-GOV phases.

## 11. Validation expectations

The REL-GOV-4 test suite proves at minimum:

- exact 17-gate registry
- complete evidence-backed PASS set is ADMISSIBLE
- blocking FAIL produces BLOCKED
- missing required gate produces BLOCKED
- duplicate gate produces BLOCKED
- unknown gate produces BLOCKED
- PASS without evidence produces BLOCKED
- blank evidence produces BLOCKED
- duplicate evidence produces BLOCKED
- caller cannot weaken canonical gate metadata
- empty message produces BLOCKED
- NOT_APPLICABLE is rejected by default
- NOT_APPLICABLE requires an explicit policy exception
- invalid exception gate IDs are rejected
- input ordering cannot change canonical output ordering
- wire vocabulary remains stable

## 12. Exit criteria

REL-GOV-4 may close only when:

```
base checkpoint exact
admission policy document present
admission engine present
admission tests present
format gate green
analyzer gate green
REL-GOV regression green
repository hygiene green
blocking implementation failures = 0
```

Closure checkpoint:

```
phase-rel-gov4-release-admission-closed
```

Next frozen phase:

```
REL-GOV-5 -> Artifact inventory and SHA-256
```
