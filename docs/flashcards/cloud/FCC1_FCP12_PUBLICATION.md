# FCC-1 — FCP1/FCP2 Protected Flashcard Publication

Status: IMPLEMENTING

Publication source is immutable and pinned to:

- FCP-1: `phase-fcp1-d01-closed@45d00a95dc6d8cb9e7c06db6df57bb71c5e17fe2`
- FCP-2: `phase-fcp2-d02-closed@8719defd9759d65e491170aa8331462869dcfe4f`

Scope:

- 21 competency packages
- 252 learner-ready cards
- Domain 01: 7 packages / 78 cards
- Domain 02: 14 packages / 174 cards

Publication contract:

1. Production package JSON is copied by Git blob identity from the frozen FCP checkpoint.
2. Each competency becomes one canonical gzip object.
3. Storage path is `flashcards/<competencyId>/v<version>.json.gz`.
4. Storage is the existing private `csp11-published-packages` bucket.
5. Compressed bytes and canonical JSON receive SHA-256 fingerprints.
6. Storage objects are create-once and never overwritten.
7. `published_packages.package_kind = flashcards` stores immutable version metadata.
8. Exactly one version per competency may be current.
9. Catalogue delivery is authenticated with the learner's Firebase ID token.
10. Learners receive compact metadata first and a 60-second signed URL only when the cached version/checksum is stale.
11. Direct anonymous/authenticated access to publication tables remains denied.
12. FCP content is never regenerated or edited during FCC publication.

The first live publication is blocked until the dedicated source test, remote read-only preflight, atomic database RPC, and protected delivery endpoint are ready.
