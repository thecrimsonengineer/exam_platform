# CSP11 REL-GOV Release Governance Implementation Plan

Status: FROZEN IMPLEMENTATION BASELINE
Phase: REL-GOV
Repository: thecrimsonengineer/exam_platform
Working branch: phase-rel-gov-release-governance
Frozen on: 2026-09-24
Base branch: main
Base commit: a464db00967aa6822c142268e8e6b2161af966f7
Base tree: 67f505d1986813dbc3d86feebf811486814b819c
Planned runs: 12
Final closure checkpoint: phase-rel-gov-closed

## 1. Purpose

REL-GOV creates a deterministic release-control plane for CSP11. It must make it possible to prove exactly which source code, Git identity, version, dependencies, environment, component checkpoints, tests, generated evidence, build artifacts and cryptographic hashes constitute one release candidate.

REL-GOV does not publish the app. It decides whether a future assembled CSP11 build is eligible to become a governed release candidate.

Core equation:

```
source + git provenance + version + dependencies + environment
+ component checkpoints + validation gates + artifacts + SHA-256
+ release manifest = one identifiable CSP11 release candidate
```

## 2. Parallel-development boundary

REL-GOV is intentionally independent from ML, LTAM, LSP, FCP, question-production and content-production branches. It must not merge those active branches during implementation.

Primary owned paths:

```
docs/release_governance/
tool/release_governance/
test/release_governance/
config/release_governance/
schemas/release_governance/
.github/workflows/csp11_release_candidate.yml
```

Avoid unrelated changes to learner runtime and active feature code.

## 3. Fail-closed rule

Unknown is not PASS.
Missing is not PASS.
Unverifiable is not PASS.
A blocking failure must produce BLOCKED.
No "mostly passed" release state is permitted.

## 4. Frozen release lifecycle

```
development -> candidate -> validated -> frozen -> released
released -> withdrawn
released -> superseded
frozen -> superseded
```

Direct jumps such as development -> released or candidate -> released are invalid.

## 5. Release identity

Human identity:
```
CSP11 vMAJOR.MINOR.PATCH
```

Machine identity:
```
versionName + buildNumber + commitSha + treeSha + manifestSha256
```

## 6. Run map

| Run | Phase | Objective | External blocker |
|---|---|---|---|
| 01 | REL-GOV-0 | Freeze governance specification | None |
| 02 | REL-GOV-1 | Versioning and release identity | None |
| 03 | REL-GOV-2 | Release manifest schema and builder | None |
| 04 | REL-GOV-3 | Repository identity and provenance | None |
| 05 | REL-GOV-4 | Release admission engine | None |
| 06 | REL-GOV-5 | Artifact inventory and SHA-256 | None |
| 07 | REL-GOV-6 | Build environment contract | None |
| 08 | REL-GOV-7 | Evidence generator and CLI | None |
| 09 | REL-GOV-8 | GitHub release-candidate CI | GitHub Actions only |
| 10 | REL-GOV-9 | Rollback and recovery contract | None |
| 11 | REL-GOV-10 | Drift and tamper regression | None |
| 12 | REL-GOV-11 | Whole-phase validation and closure | None |

## 7. REL-GOV-0 Governance specification freeze

Objective: freeze the rules every later REL-GOV run must obey.

Outputs:
- docs/release_governance/REL_GOV_RELEASE_GOVERNANCE_FREEZE.md
- config/release_governance/rel_gov_freeze.json

Freeze:
- lifecycle states and transition rules
- required release identity fields
- fail-closed rules
- evidence ownership
- phase boundaries
- publication exclusions
- 12-run sequence
- component-checkpoint model
- non-goals

Exit:
```
governance specification present
machine-readable freeze present
invariants complete
base repository identity recorded
scope boundary explicit
publication excluded
blocking failures = 0
```

Checkpoint:
```
phase-rel-gov0-governance-freeze-closed
```

## 8. REL-GOV-1 Versioning and release identity

Create:
- docs/release_governance/VERSIONING_CONTRACT.md
- tool/release_governance/release_version.dart
- test/release_governance/version_contract_test.dart

Contract:
```
MAJOR.MINOR.PATCH+BUILD
```

Model:
- major
- minor
- patch
- buildNumber
- versionName
- fullVersion
- releaseId

Validate malformed versions, invalid build numbers and illegal normalization.

Recommended build rule:
```
new governed buildNumber > previous governed buildNumber
```

Checkpoint:
```
phase-rel-gov1-version-contract-closed
```

## 9. REL-GOV-2 Release manifest

Create:
- docs/release_governance/RELEASE_MANIFEST_SPEC.md
- schemas/release_governance/release_manifest.schema.json
- tool/release_governance/release_manifest_builder.dart
- test/release_governance/manifest_schema_test.dart

Minimum manifest sections:
- schemaVersion
- release
- source
- environment
- dependencies
- components
- validation
- artifacts
- recovery

The manifest describes repository reality. It may not manually self-declare test or gate success without linked evidence.

Checkpoint:
```
phase-rel-gov2-release-manifest-closed
```

## 10. REL-GOV-3 Repository provenance

Create:
- docs/release_governance/REPOSITORY_PROVENANCE_CONTRACT.md
- tool/release_governance/repository_provenance.dart
- test/release_governance/provenance_test.dart

Capture:
- repository
- branch
- HEAD SHA
- tree SHA
- tag/checkpoint when applicable
- tracked dirty state
- governed untracked-file state

Official candidate rule:
```
dirty governed source -> BLOCK
unknown commit -> BLOCK
branch/checkpoint mismatch -> BLOCK
```

Checkpoint:
```
phase-rel-gov3-repository-provenance-closed
```

## 11. REL-GOV-4 Release admission engine

Create:
- docs/release_governance/RELEASE_ADMISSION_POLICY.md
- tool/release_governance/release_admission.dart
- test/release_governance/admission_gate_test.dart

Gate record:
- gateId
- name
- status
- severity
- blocking
- evidence
- message

Initial required gates:
```
RG001 repository_clean
RG002 repository_identity
RG003 version_valid
RG004 build_number_valid
RG005 dependency_lock
RG006 environment_valid
RG007 formatter
RG008 analyzer
RG009 unit_tests
RG010 widget_tests
RG011 schema_validation
RG012 component_evidence
RG013 artifact_inventory
RG014 artifact_hashes
RG015 provenance
RG016 release_state
RG017 manifest_completeness
```

Decision:
```
blockingFailureCount == 0 -> ADMISSIBLE
blockingFailureCount > 0 -> BLOCKED
```

Checkpoint:
```
phase-rel-gov4-release-admission-closed
```

## 12. REL-GOV-5 Artifact inventory and hashing

Create:
- tool/release_governance/artifact_inventory.dart
- tool/release_governance/checksum_service.dart
- test/release_governance/artifact_inventory_test.dart
- test/release_governance/checksum_test.dart

Authoritative hash:
```
SHA-256
```

Artifact record:
- artifactId
- fileName
- sizeBytes
- sha256
- required

Detect modification, deletion, substitution and unexpected duplicates.

Generate checksums.sha256.

Checkpoint:
```
phase-rel-gov5-artifact-integrity-closed
```

## 13. REL-GOV-6 Build environment contract

Create:
- docs/release_governance/BUILD_ENVIRONMENT_CONTRACT.md
- tool/release_governance/environment_validator.dart
- test/release_governance/environment_contract_test.dart

Capture:
- Flutter
- Dart
- Java
- Gradle
- Android Gradle plugin where discoverable
- Kotlin where applicable
- runner platform
- pubspec.yaml SHA-256
- pubspec.lock SHA-256

Material unexpected drift is blocking.

Checkpoint:
```
phase-rel-gov6-build-environment-closed
```

## 14. REL-GOV-7 Evidence generator

Create:
- tool/release_governance/release_governance.dart
- tool/release_governance/release_evidence.dart
- test/release_governance/evidence_generator_test.dart

Target output:
```
build/release-evidence/
  release_manifest.json
  repository_evidence.json
  version_evidence.json
  environment_evidence.json
  dependency_evidence.json
  test_evidence.json
  component_evidence.json
  artifact_manifest.json
  admission_result.json
  checksums.sha256
  release_summary.txt
```

The same stable source and evidence must generate deterministic identity data. Volatile timestamps must not alter identity semantics.

Checkpoint:
```
phase-rel-gov7-release-evidence-closed
```

## 15. REL-GOV-8 GitHub release-candidate CI

Create:
```
.github/workflows/csp11_release_candidate.yml
```

Initial trigger:
```
workflow_dispatch
```

Pipeline:
```
exact checkout
-> pinned toolchain
-> dependency validation
-> format
-> analyze
-> tests
-> repository gates
-> evidence generation
-> selected candidate builds
-> artifact hashes
-> admission
-> evidence upload
```

This workflow MUST NOT publish to Google Play, App Store, production Firebase, production Supabase or any public deployment channel.

Checkpoint:
```
phase-rel-gov8-release-candidate-ci-closed
```

## 16. REL-GOV-9 Rollback and recovery

Create:
- docs/release_governance/ROLLBACK_RECOVERY_CONTRACT.md
- tool/release_governance/release_recovery.dart
- test/release_governance/release_recovery_test.dart

Record:
- previousStableRelease
- previousStableCommit
- previousStableTree
- rollbackEligible

Recovery metadata identifies the correct prior source and artifacts. It does not deploy them.

Checkpoint:
```
phase-rel-gov9-rollback-recovery-closed
```

## 17. REL-GOV-10 Drift and tamper regression

Create:
- test/release_governance/tamper_detection_test.dart
- controlled fixtures as needed

Must prove BLOCK for at least:
- version/build mismatch
- manifest alteration
- artifact alteration
- unknown Git SHA
- dirty governed source
- missing dependency lock
- dependency drift
- missing evidence
- failed required test
- illegal state transition
- corrupt manifest
- malformed component checkpoint
- missing required artifact
- checksum mismatch
- environment drift
- provenance mismatch
- evidence from another commit
- duplicate artifact identity

Positive control must prove an exact valid fixture is ADMISSIBLE.

Checkpoint:
```
phase-rel-gov10-tamper-regression-closed
```

## 18. REL-GOV-11 Whole-phase validation and closure

Create:
- test/release_governance/rel_gov_whole_phase_test.dart
- docs/release_governance/REL_GOV_CLOSURE_REPORT.md

Run a clearly marked synthetic/internal candidate through:
```
format
-> analyze
-> REL-GOV tests
-> negative tests
-> provenance
-> version validation
-> environment validation
-> manifest
-> component admission
-> artifact hashing
-> release admission
-> evidence package
-> evidence re-verification
```

Final hygiene:
- no unrelated feature changes
- no secrets
- no accidental build artifacts tracked
- working branch at exact closure commit
- all blocking failures zero

Run checkpoint:
```
phase-rel-gov11-whole-phase-validation-closed
```

Final phase checkpoint:
```
phase-rel-gov-closed
```

## 19. Component checkpoint model

REL-GOV must accept frozen component identities without owning their implementation. A future manifest may reference:
- home
- content
- questions
- flashcards
- labs
- microLearning
- learningTwin
- authentication
- backendConfiguration

Each governed component may record:
- componentId
- status
- checkpoint
- commitSha
- version
- evidence

REL-GOV validates the supplied checkpoint evidence. It does not decide when a feature team should close.

## 20. Non-goals

REL-GOV explicitly excludes:
- Google Play publication
- App Store publication
- Microsoft Store publication
- production signing-key custody
- store credentials
- subscription product setup
- staged production rollout
- production Firebase deployment
- production Supabase deployment
- marketing launch
- public release notes and store copy

These belong to a later REL-PUB phase.

## 21. Run discipline

Every run:
```
previous closed checkpoint
-> verify branch/ref
-> implement only run scope
-> format
-> targeted tests
-> relevant regression
-> repository hygiene
-> commit
-> verify exact commit
-> create immutable-style closed checkpoint branch/ref
```

Do not begin the next run with unresolved blocking failures.

## 22. Definition of done

REL-GOV is complete only when:
- governance specification is frozen
- version identity is deterministic
- manifest schema and builder are operational
- repository provenance is operational
- admission engine is fail-closed
- artifact inventory and SHA-256 are operational
- environment contract is operational
- evidence generation is operational
- candidate CI is operational and non-publishing
- rollback/recovery lineage is operational
- state transitions are validated
- drift and tamper tests pass
- valid synthetic candidate passes
- tampered synthetic candidate fails
- repository regression remains green
- closure evidence is recorded
- phase-rel-gov-closed points to the exact closure commit

## 23. Frozen execution order

```
REL-GOV-0  Governance freeze
REL-GOV-1  Versioning
REL-GOV-2  Manifest
REL-GOV-3  Provenance
REL-GOV-4  Admission
REL-GOV-5  Artifact integrity
REL-GOV-6  Environment
REL-GOV-7  Evidence generator
REL-GOV-8  Candidate CI
REL-GOV-9  Recovery
REL-GOV-10 Tamper/drift
REL-GOV-11 Whole-phase closure
```

Changes to this frozen plan require an explicit documented amendment. Silent scope expansion is prohibited.
