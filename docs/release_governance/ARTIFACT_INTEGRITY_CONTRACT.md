# CSP11 REL-GOV-5 Artifact Integrity Contract

Status: IMPLEMENTED CANDIDATE
Phase: REL-GOV-5
Repository: thecrimsonengineer/exam_platform
Base checkpoint: phase-rel-gov4-release-admission-closed
Base commit: b60373e7be2641d99c918f82d9f12049734a5b4f
Date: 2026-09-24

## 1. Purpose

REL-GOV-5 gives CSP11 release artifacts deterministic byte identity.

A governed artifact is identified by:

```
artifactId
fileName
sizeBytes
sha256
required
```

SHA-256 is the authoritative artifact hash.

## 2. Boundary

REL-GOV-5 owns:

- artifact declarations
- deterministic inventory capture
- portable artifact-path validation
- file-size capture
- streaming SHA-256 calculation
- deterministic checksums.sha256 rendering
- inventory-to-inventory integrity verification
- modification, deletion, substitution and duplicate detection

REL-GOV-5 does not decide which platform builds REL-GOV-8 will produce. Later candidate CI supplies the concrete artifact declarations.

## 3. Artifact declarations

Before capture, each artifact has:

```
artifactId
fileName
required
```

artifactId must match:

```
^[A-Za-z][A-Za-z0-9._-]*$
```

fileName is a portable relative path using forward slashes.

The following are rejected:

- absolute POSIX paths
- Windows drive-qualified paths
- backslash paths
- empty path segments
- . or .. path segments
- multiline file names

Artifact IDs and file names must both be unique.

## 4. Captured artifact record

A successfully captured artifact becomes:

```json
{
  "artifactId": "android-apk",
  "fileName": "build/app-release.apk",
  "sizeBytes": 123456,
  "sha256": "<64 lowercase hexadecimal characters>",
  "required": true
}
```

Records are emitted deterministically by artifactId and then fileName.

Optional artifacts may be absent without creating invented records.

A required artifact that is absent is a blocking inventory failure.

## 5. SHA-256 implementation

REL-GOV-5 uses a pure-Dart streaming SHA-256 implementation.

This deliberately avoids relying on:

- sha256sum
- openssl
- certutil
- platform shell behavior
- undeclared transitive packages

File bytes are streamed into the digest so candidate artifacts do not need to be loaded into memory as one complete byte array.

The implementation is locked by published SHA-256 vectors including empty input, abc and the one-million-a test vector.

## 6. checksums.sha256

The checksum file format is:

```
<sha256><two spaces><fileName>
```

Entries are sorted by fileName.

Duplicate file names, malformed hashes and multiline file names are rejected.

## 7. Integrity verification

The verifier compares an expected frozen inventory with a newly captured actual inventory.

It blocks:

- malformed expected SHA-256
- duplicate expected artifact IDs
- duplicate expected file names
- malformed actual SHA-256
- duplicate actual artifact IDs
- duplicate actual file names
- missing required artifacts
- artifact ID to file-name substitution
- required-flag drift
- byte-size drift
- SHA-256 drift
- unexpected artifacts

A same-size modification is still detected by SHA-256.

## 8. Inventory issue codes

Capture may emit:

```
AIN001_INVALID_ARTIFACT_ID
AIN002_INVALID_FILE_NAME
AIN003_DUPLICATE_ARTIFACT_ID
AIN004_DUPLICATE_FILE_NAME
AIN005_REQUIRED_ARTIFACT_MISSING
AIN006_ARTIFACT_NOT_FILE
AIN007_ARTIFACT_READ_FAILED
```

## 9. Verification issue codes

Integrity comparison may emit:

```
AIV001_INVALID_EXPECTED_SHA256
AIV002_DUPLICATE_EXPECTED_ARTIFACT_ID
AIV003_DUPLICATE_EXPECTED_FILE_NAME
AIV004_INVALID_ACTUAL_SHA256
AIV005_DUPLICATE_ACTUAL_ARTIFACT_ID
AIV006_DUPLICATE_ACTUAL_FILE_NAME
AIV007_REQUIRED_ARTIFACT_MISSING
AIV008_FILE_NAME_SUBSTITUTION
AIV009_REQUIRED_FLAG_MISMATCH
AIV010_SIZE_MISMATCH
AIV011_SHA256_MISMATCH
AIV012_UNEXPECTED_ARTIFACT
```

All REL-GOV-5 issues are blocking.

## 10. Admission integration boundary

REL-GOV-4 already reserves:

```
RG013 artifact_inventory
RG014 artifact_hashes
```

REL-GOV-5 provides the deterministic evidence needed for those gates.

The admission engine itself is not weakened or rewritten in this phase.

## 11. Exit criteria

REL-GOV-5 may close only when:

```
base checkpoint exact
artifact inventory service present
streaming SHA-256 service present
checksums.sha256 generation present
deletion detection green
modification detection green
same-size modification detection green
substitution detection green
duplicate detection green
format green
analyzer green
full REL-GOV regression green
repository diff limited to REL-GOV-5
blocking implementation failures = 0
```

Closure checkpoint:

```
phase-rel-gov5-artifact-integrity-closed
```

Next frozen phase:

```
REL-GOV-6 -> Build Environment Contract
```
