# CSP11 REL-GOV-0 Release Governance Freeze

Status: CLOSED BASELINE CANDIDATE
Phase: REL-GOV-0
Repository: thecrimsonengineer/exam_platform
Working branch: phase-rel-gov-release-governance
Frozen date: 2026-09-24
Base branch: main
Base commit: a464db00967aa6822c142268e8e6b2161af966f7
Base tree: 67f505d1986813dbc3d86feebf811486814b819c

## Purpose

REL-GOV-0 freezes the governance rules that all later REL-GOV runs must obey. Later implementation may add code and evidence, but it may not silently weaken these invariants.

## Frozen invariants

### RG-INV-001 Reality over declaration
Release evidence must be derived from repository, build, test, component and artifact reality. A manifest may not self-declare success without evidence.

### RG-INV-002 Fail closed
Unknown, missing, malformed, stale or unverifiable required evidence is not PASS.

### RG-INV-003 Blocking failures
Any blocking release-admission failure produces BLOCKED.

### RG-INV-004 Frozen release immutability
A frozen governed release identity is immutable. Any material source, dependency, manifest, environment or artifact change creates a new candidate identity.

### RG-INV-005 Cryptographic artifact identity
Authoritative release artifact identity uses SHA-256.

### RG-INV-006 Exact Git provenance
A governed candidate must resolve to an exact repository, commit SHA and tree SHA.

### RG-INV-007 Publication separation
REL-GOV creates and validates release candidates. It does not publish to application stores or production channels.

### RG-INV-008 Secret separation
Production signing keys, store credentials and deployment secrets are outside the REL-GOV phase and must never be committed to Git.

### RG-INV-009 Parallel-phase independence
REL-GOV must be capable of closing without requiring ML, LTAM, LSP, FCP or other content-production branches to finish.

### RG-INV-010 Synthetic self-validation
REL-GOV may use clearly marked synthetic/internal component checkpoints for self-validation. Synthetic identities must never be represented as production feature closures.

### RG-INV-011 Evidence ownership
Every required PASS must identify supporting evidence.

### RG-INV-012 State-machine enforcement
Release status changes must be validated transitions, not arbitrary JSON edits.

### RG-INV-013 No silent scope expansion
Changes to frozen governance rules require an explicit documented amendment.

### RG-INV-014 Non-publishing CI
Initial release-candidate CI must be incapable of automatic public publication.

### RG-INV-015 Component independence
REL-GOV validates supplied component checkpoint evidence. It does not own or redefine the feature implementation.

## Frozen release states

```
development
candidate
validated
frozen
released
withdrawn
superseded
```

Primary forward path:

```
development -> candidate -> validated -> frozen -> released
```

Allowed terminal/lineage transitions:

```
released -> withdrawn
released -> superseded
frozen -> superseded
```

Disallowed unless a later explicit amendment says otherwise:

```
development -> validated
development -> frozen
development -> released
candidate -> frozen
candidate -> released
validated -> released
withdrawn -> released
```

## Frozen identity fields

Every governed candidate must ultimately expose:

```
releaseId
versionName
buildNumber
releaseStatus
repository
branch/ref
commitSha
treeSha
manifestSchemaVersion
manifestSha256
createdAt
```

The release identity must distinguish human-readable identity from machine identity.

Human identity:
```
CSP11 vMAJOR.MINOR.PATCH
```

Machine identity:
```
versionName + buildNumber + commitSha + treeSha + manifestSha256
```

## Frozen validation families

REL-GOV admission must be able to govern at least:

```
repository
version
dependencies
environment
formatting
analysis
tests
schemas
components
artifacts
hashes
provenance
release-state
evidence-completeness
```

## Frozen gate result semantics

Required gate outcomes are:

```
PASS
FAIL
NOT_APPLICABLE
```

NOT_APPLICABLE is valid only where policy explicitly permits it.

A warning must never be silently interpreted as PASS for a blocking gate.

## Frozen component checkpoint model

REL-GOV may consume checkpoint evidence for components such as:

```
coreApp
home
content
questions
flashcards
labs
microLearning
learningTwin
authentication
backendConfiguration
```

A component record may include:

```
componentId
status
checkpoint
commitSha
version
evidence
```

REL-GOV validates the checkpoint evidence. It does not decide when a feature phase is complete.

## Frozen artifact-integrity rule

Authoritative artifact identity:

```
SHA-256
```

A required artifact whose bytes do not match its expected SHA-256 is a blocking failure.

## Frozen repository rule

For an official release candidate:

```
dirty governed source -> BLOCK
unknown/unresolvable source identity -> BLOCK
provenance mismatch -> BLOCK
```

Generated output may only be exempt when explicitly governed or ignored by policy.

## Frozen dependency rule

Dependency identity must include at minimum:

```
pubspec.yaml identity
pubspec.lock identity
```

Missing required lock evidence is blocking.

## Frozen environment rule

The release environment must record enough information to detect material drift, including at least:

```
Flutter
Dart
Java
Gradle
runner platform
dependency lock identity
```

## Frozen evidence rule

A result such as:

```json
{"gateId":"RG009","status":"pass"}
```

is insufficient for a required gate if no evidence reference is attached.

A governed PASS must link to evidence generated or captured by the release process.

## Frozen candidate-CI boundary

Candidate CI may:

```
checkout exact source
verify toolchain
restore dependencies
validate dependencies
check formatting
run analyzer
run tests
run repository gates
generate release evidence
build internal candidate artifacts
hash artifacts
evaluate admission
upload CI evidence
```

Candidate CI must not:

```
publish to Google Play
publish to Apple App Store
publish to Microsoft Store
deploy production Firebase state
deploy production Supabase state
create production subscriptions
perform production rollout
create or expose production signing secrets
```

## Frozen non-goals

The following are intentionally outside REL-GOV:

```
production-store publication
production signing-key ownership
store API credentials
subscription product configuration
staged rollout
marketing launch
public store metadata
production deployment
```

A later REL-PUB phase may own those concerns.

## Frozen run sequence

```
REL-GOV-0  Governance specification freeze
REL-GOV-1  Versioning and release identity
REL-GOV-2  Release manifest
REL-GOV-3  Repository provenance
REL-GOV-4  Release admission
REL-GOV-5  Artifact inventory and SHA-256
REL-GOV-6  Build environment contract
REL-GOV-7  Evidence generator
REL-GOV-8  Candidate CI
REL-GOV-9  Rollback/recovery
REL-GOV-10 Drift/tamper regression
REL-GOV-11 Whole-phase validation and closure
```

## File ownership boundary

Primary REL-GOV ownership:

```
docs/release_governance/
tool/release_governance/
test/release_governance/
config/release_governance/
schemas/release_governance/
.github/workflows/csp11_release_candidate.yml
```

REL-GOV must avoid unrelated edits to learner runtime and active feature implementation.

## REL-GOV-0 closure gates

REL-GOV-0 may close only when:

- implementation plan is committed on the REL-GOV branch
- governance freeze is committed
- machine-readable freeze metadata is committed
- base repository SHA and tree are recorded
- all frozen invariants are represented in both human-readable and machine-readable form
- phase boundaries and non-goals are explicit
- no production publication capability has been introduced
- no active feature branch has been merged into REL-GOV

## Next action after closure

```
REL-GOV-1: Versioning and Release Identity Contract
```

Expected REL-GOV-0 closed checkpoint:

```
phase-rel-gov0-governance-freeze-closed
```
