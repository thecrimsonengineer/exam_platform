# LAB Chunked Firestore Storage Contract

Status: IMPLEMENTED AND VALIDATED  
Branch: `phase-lsp-batch2-direct-publication`

## Purpose

Published LAB payloads must never be persisted as one monolithic Firestore document.

The previous v1 shape placed the technical package and the automated evidence chain in one `labPublishedVersions` document. Batch 2 demonstrated that a single generated published payload could exceed 50 MB, far above the Firestore per-document boundary.

The v2 storage contract applies generically to every persistent LAB publication.

## Canonical v2 shape

Parent document:

`labPublishedVersions/{labId}__{versionId}`

Schema:

`csp11.lab.published_repository.chunked.v2`

The parent contains only lightweight immutable metadata:

- LAB ID
- version ID
- published lifecycle
- publication timestamp
- reviewer / validation authority
- snapshot fingerprint
- payload schema
- payload manifest
- total payload chunk count

Heavy payload data is stored under:

`labPublishedVersions/{versionKey}/payloadChunks/{chunkId}`

Chunk schema:

`csp11.lab.published_payload_chunk.v1`

## Chunked fields

The following published-version fields are always moved out of the parent document:

1. `publishedJson`
2. `qualityEvidenceJson`
3. `exhaustiveRouteEvidenceJson`
4. `publishEvidenceJson`

Each field is:

1. UTF-8 encoded.
2. GZip compressed.
3. Split into deterministic compressed chunks of at most 480 KiB before Base64 encoding.
4. Base64 encoded for Firestore storage.
5. Bound to SHA-256 fingerprints at payload and chunk level.

The frozen safety limit is 450 chunks per LAB version.

## Integrity

The parent payload manifest records, per field:

- encoding
- chunk count
- uncompressed byte length
- compressed byte length
- SHA-256 payload fingerprint

Each child chunk records:

- field name
- chunk index
- total chunk count
- payload fingerprint
- chunk fingerprint
- Base64 payload

Runtime reconstruction rejects:

- missing chunks
- extra chunks
- reordered indexes
- count mismatches
- invalid Base64
- chunk fingerprint mismatches
- compressed-size mismatches
- payload fingerprint mismatches
- unsupported field names or schemas

## Immutability and failure behavior

The Flutter Firestore repository writes one LAB version transactionally, including its payload chunks and parent metadata.

The controlled GitHub production publisher uses a resumable chunks-first strategy:

1. Write and verify small immutable payload chunks.
2. Write the lightweight parent only after all chunks for that LAB verify.
3. Stage learner catalogue metadata only after all published parents verify.
4. Close Q16 only after the complete published and staged population verifies.
5. Create learner catalogue entries.
6. Atomically write Q17 acceptance and visibility as the final learner gate.

If a network timeout occurs, the publisher reads back the exact document payload before deciding whether to resume.

The original first 10 LAB release remains outside the Batch 2 write set and learner visibility remains unchanged.

## Compatibility

`FirestoreLabPublishedRepository` retains read compatibility with legacy:

`csp11.lab.published_repository.v1`

All new persistent LAB publications use the chunked v2 schema.

## Validated Batch 2 result

Validation run: `36123791235`

- Published LAB parents: 10
- Generated payload chunks: 50
- Largest serialized chunk document: 655,726 bytes
- Chunk codec regression: PASS
- Batch 2 release integration regression: PASS
- Flutter analyze: PASS
- Firestore rules compilation: PASS
- Direct bundle boundary validation: PASS
- Publisher Python validation: PASS

Pre-release live verification run: `36124419110`

- Chunked parents: 0/10
- Payload chunks: 0
- Orphan chunks: 0
- Staged: 0/10
- Q16: absent
- Q17: absent
- Learner catalogue: 0/10
- Production state: PRISTINE

## Current production gate

Production run `36124593922` validated the complete chunked release bundle and authenticated through Google Cloud WIF.

It stopped before any LAB write because the currently connected identity:

`csp11-fr5-firestore-reader@csp11-exam-platform.iam.gserviceaccount.com`

does not have permission to deploy Firestore Security Rules. The Firebase Rules API returned HTTP 403.

The release publisher remains blocked until the chunk-aware `firestore.rules` file is deployed by an authorized Firebase identity. Data publication must not bypass this gate.
