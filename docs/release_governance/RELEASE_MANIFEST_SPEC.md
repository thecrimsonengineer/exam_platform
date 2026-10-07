# CSP11 REL-GOV-2 Release Manifest Specification

Status: IMPLEMENTATION CANDIDATE
Phase: REL-GOV-2
Parent checkpoint: phase-rel-gov1-version-contract-closed
Parent SHA: 3ab7d09eb7bf249e6b875bfb54d4246188d5c9dd
Schema version: 1

## Purpose

The release manifest is the canonical machine-readable description of one governed CSP11 release candidate.

The manifest describes observed and supplied release evidence. It does not create evidence and it must never convert an unsupported declaration into a PASS.

## Top-level structure

Every schemaVersion 1 manifest contains exactly these top-level sections:

```
schemaVersion
release
source
environment
dependencies
components
validation
artifacts
recovery
```

Unknown top-level properties are rejected.

## Release section

Required fields:

```
releaseId
versionName
buildNumber
status
createdAt
```

Allowed release states:

```
development
candidate
validated
frozen
released
withdrawn
superseded
```

For candidate manifests created through the REL-GOV builder, releaseId is derived from the REL-GOV-1 version contract:

```
csp11-MAJOR.MINOR.PATCH-rc.N
```

## Source section

Required fields:

```
repository
branch
commitSha
treeSha
clean
```

commitSha and treeSha are lowercase 40-character hexadecimal Git object identities.

REL-GOV-3 will later replace caller-supplied source facts with repository-derived provenance. REL-GOV-2 only establishes the manifest shape and validates supplied values.

## Environment and dependency sections

REL-GOV-2 reserves these sections and preserves their data deterministically.

REL-GOV-6 will define the authoritative environment contract.

The dependency section may already carry identities such as pubspec and lockfile hashes, but REL-GOV-6 will determine which fields are mandatory.

## Components

Components are serialized as an object keyed by componentId.

Example:

```json
{
  "components": {
    "flashcards": {
      "componentId": "flashcards",
      "status": "closed",
      "checkpoint": "phase-fc-closed",
      "commitSha": "0123456789abcdef0123456789abcdef01234567",
      "version": null,
      "evidence": []
    }
  }
}
```

Rules:

- componentId must be unique
- object key must equal componentId
- status and checkpoint must be non-empty
- commitSha is nullable until a later gate requires it
- evidence is an ordered JSON array and is preserved
- components are emitted in lexicographic componentId order

## Validation section

Required fields:

```
requiredGateCount
passedGateCount
blockingFailureCount
evidenceRefs
```

Rules:

- counts are non-negative
- passedGateCount may not exceed requiredGateCount
- a non-zero passedGateCount requires at least one evidence reference
- duplicate evidence references are rejected
- a manifest may contain blocking failures because candidate manifests can describe a BLOCKED candidate
- admission semantics are implemented in REL-GOV-4

The manifest must not treat caller-provided counts as proof of successful validation. They are summary fields linked to evidence references.

## Artifacts

REL-GOV-2 reserves the artifacts array.

REL-GOV-5 will define cryptographic artifact records and SHA-256 requirements.

## Recovery

REL-GOV-2 reserves recovery lineage with:

```
previousStableRelease
rollbackEligible
```

REL-GOV-9 will add authoritative rollback/recovery validation.

## Determinism

The builder canonicalizes all JSON object keys recursively before serialization.

Therefore equivalent maps with different insertion orders produce the same canonical JSON.

Component keys are sorted lexicographically.

The builder never creates a current timestamp. createdAt must be supplied explicitly so repeated generation from the same inputs remains stable.

## Fail-closed builder rules

The builder rejects:

- malformed Git SHA
- empty repository or branch
- empty release identity
- version/releaseId mismatch for candidate factory construction
- duplicate component IDs
- empty component IDs, statuses or checkpoints
- invalid component commit SHA
- negative validation counts
- passedGateCount greater than requiredGateCount
- PASS summary counts without evidence references
- duplicate evidence references
- unsupported JSON values inside canonicalized maps

## Schema location

```
schemas/release_governance/release_manifest.schema.json
```

## Builder location

```
tool/release_governance/release_manifest_builder.dart
```

## Validation

```
test/release_governance/manifest_schema_test.dart
```

## Closure checkpoint

```
phase-rel-gov2-release-manifest-closed
```
