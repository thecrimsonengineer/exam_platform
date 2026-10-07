# CSP11 REL-GOV-7 Release Evidence and CLI Contract

Status: IMPLEMENTED CANDIDATE
Phase: REL-GOV-7
Repository: thecrimsonengineer/exam_platform
Base checkpoint: phase-rel-gov6-build-environment-closed
Base commit: 577573058835b5c6195bc237e9e49c7d91105c5c
Date: 2026-09-24

## 1. Purpose

REL-GOV-7 assembles the evidence produced by the earlier release-governance contracts into one deterministic release-evidence package.

It does not publish an application, build platform binaries or weaken any existing admission rule.

## 2. Frozen package shape

The generated directory contains exactly:

```
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

Unexpected files are rejected by package verification.

## 3. Reality over declaration

The generator does not accept a caller-supplied release manifest or final admission decision.

Instead it:

```
typed source evidence
+ typed version evidence
+ typed environment evidence
+ typed test evidence
+ typed component evidence
+ typed artifact evidence
+ admission gate records
        ↓
REL-GOV-4 policy evaluation
        ↓
REL-GOV-2 manifest construction
        ↓
deterministic evidence package
```

The final ADMISSIBLE or BLOCKED value is recomputed through the REL-GOV-4 ReleaseAdmissionPolicy.

## 4. Deterministic evidence identity

REL-GOV-7 creates evidenceIdentitySha256 from the canonical bytes of:

- all nine structured JSON evidence files
- checksums.sha256

File names are sorted before identity calculation.

The human-readable release_summary.txt contains the resulting identity but is excluded from its own digest to avoid a recursive hash.

No generator timestamp is added.

The governed candidate createdAt value comes from the release request and is part of the release manifest. Re-running the generator with the same governed inputs therefore produces byte-identical output regardless of wall-clock execution time or destination directory.

## 5. Canonical JSON

Every structured evidence JSON file is:

- recursively key-sorted
- UTF-8
- two-space pretty printed
- terminated with one newline

Verification rejects valid JSON whose bytes are not in the canonical representation.

## 6. Test evidence

Each test-suite record contains:

```
suiteId
status
evidenceRefs
message
```

PASS requires at least one evidence reference.

Test suite IDs must be unique.

Evidence references must be non-empty and unique within each suite.

Suites are serialized by suiteId.

## 7. Component evidence

Component checkpoints use the frozen REL-GOV component model:

```
componentId
status
checkpoint
commitSha
version
evidence
```

Components are serialized by componentId.

The release manifest and component_evidence.json are generated from the same typed component records.

## 8. Dependency evidence

dependency_evidence.json contains the authoritative SHA-256 identities already captured by REL-GOV-6:

```
pubspecYamlSha256
pubspecLockSha256
```

These same values are also present in environment_evidence.json.

## 9. Artifact evidence

artifact_manifest.json contains the REL-GOV-5 ArtifactInventoryResult.

checksums.sha256 is regenerated from those artifact records rather than accepted as caller text.

Package verification checks that the checksum file still matches the artifact manifest.

## 10. Package verification

The verifier detects at least:

```
EVD001_PACKAGE_DIRECTORY_MISSING
EVD002_REQUIRED_FILE_MISSING
EVD003_UNEXPECTED_FILE
EVD004_STRUCTURED_FILE_NOT_OBJECT
EVD005_NON_CANONICAL_JSON
EVD006_INVALID_JSON
EVD007_ARTIFACT_CHECKSUM_FILE_MISMATCH
EVD008_ARTIFACT_MANIFEST_INVALID
EVD009_SUMMARY_IDENTITY_MISMATCH
```

All verification issues are blocking.

## 11. CLI

Generation:

```
dart run tool/release_governance/release_governance.dart generate \
  --input <evidence-input.json> \
  --output <release-evidence-directory>
```

Verification:

```
dart run tool/release_governance/release_governance.dart verify \
  --directory <release-evidence-directory>
```

The generate command immediately self-verifies the package. A failed self-verification returns a non-zero exit code.

The normalized input JSON is parsed into REL-GOV typed records. Unknown admission status or severity vocabulary is rejected.

## 12. Exit semantics

```
0   success
2   generation or verification failure
64  CLI usage or command error
```

## 13. Phase boundary

REL-GOV-7 owns:

- evidence-package assembly
- canonical evidence serialization
- deterministic evidence identity
- release summary generation
- package self-verification
- normalized evidence-input parsing
- generate and verify CLI commands

REL-GOV-7 does not yet own:

- release-candidate GitHub workflow orchestration
- platform build production
- public deployment
- rollback execution
- final whole-phase tamper matrix

Those remain in later frozen REL-GOV runs.

## 14. Exit criteria

REL-GOV-7 may close only when:

```
base checkpoint exact
all 11 package files generated
canonical JSON deterministic
same inputs produce byte-identical packages
admission decision recomputed
artifact checksum consistency verified
tampered JSON detected
tampered checksums detected
missing files detected
unexpected files detected
CLI generate green
CLI verify green
format green
analyzer green
full REL-GOV regression green
repository diff limited to REL-GOV-7
blocking implementation failures = 0
```

Closure checkpoint:

```
phase-rel-gov7-release-evidence-closed
```

Next frozen phase:

```
REL-GOV-8 -> GitHub Release-Candidate CI
```
