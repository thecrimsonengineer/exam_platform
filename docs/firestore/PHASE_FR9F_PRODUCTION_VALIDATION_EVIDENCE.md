# CSP11 Phase FR9F Production Validation Evidence

Status: CLOSURE EVIDENCE COMPLETE — FINAL EXACT-SHA FREEZE GATE PENDING  
Date: 2026-09-22  
Branch: `phase-fr9-question-delivery-cutover`  
Authorized proof SHA: `9a01fe716421986513766ac0aab441ce582bf5cc`  
Authorized proof run: `35704749394`  
Full FR validation run on proof SHA: `35704749289`

## Purpose

This file records repository, production, authentication, package-integrity and
regression evidence required before FR9 may be frozen.

No Firebase learner ID token, signed package URL, refresh token, API key or
privileged Supabase credential is recorded in this file or in the sanitized
production-proof artifact.

## Exact-SHA repository gate

Run `35704749289` completed successfully on exact SHA
`9a01fe716421986513766ac0aab441ce582bf5cc`.

The run passed:

- dependency lock gate;
- formatting;
- analysis;
- FR1-FR8 inherited gates;
- FR9 package decoder and delivery contracts;
- protected UID-scoped question cache tests;
- Edge gateway security tests;
- scoped QuizService cutover tests;
- bounded Practice mode cutover tests;
- live production missing-token smoke;
- live production malformed-token smoke;
- frozen Phase L4 learner regressions;
- frozen Phase L4 quality gates;
- exact frozen Phase L engine suite;
- full repository regression;
- diff hygiene.

## Deployed Edge Function

Project: `csp11-supabase`  
Project ref: `esfycnmfywxczfillioj`  
Function: `learner-question-packages`  
Status: ACTIVE  
Version: 1  
`verify_jwt`: false  
Bundle SHA-256:
`08303edb83857d32f61766ba6e8dfe0ec4b4549bf7822c4d9ba980fe5bd5e817`

The deployed `index.ts` is byte-equivalent to:

`supabase/functions/learner-question-packages/index.ts`

The custom gateway retains in-handler Firebase RS256 verification against the
CSP11 project before constructing the privileged Supabase client.

## Live package catalogue and Storage evidence

Observed against the production Supabase project:

- active `published_catalog` rows: 35;
- active rows with question object paths: 35;
- stored question objects in `csp11-published-packages`: 35;
- active catalogue rows matching a stored object path: 35;
- total active compressed question bytes: 1,040,943;
- `csp11-published-packages` bucket public flag: false;
- `published_catalog` RLS: enabled;
- direct package-bucket SELECT policies: 0.

The anon/authenticated policy on `published_catalog` remains
`fr_edge_only_deny_direct_client`, command `ALL`, with predicate `false`.

Direct learner Data API catalogue access and direct Storage reads therefore
remain denied. Package delivery remains through the reviewed Edge gateway and
short-lived signed URLs.

## Live fail-closed authentication evidence

The main FR workflow performs production HTTP requests to
`learner-question-packages`.

The fail-closed production smoke proves:

1. a POST `catalog` request with no Authorization header returns HTTP 401
   with `invalid_firebase_token`;
2. a POST `catalog` request with a malformed bearer token returns HTTP 401
   with `invalid_firebase_token`.

The FR9 Edge gateway architecture gate also pins:

- Firebase project `csp11-exam-platform`;
- issuer `https://securetoken.google.com/csp11-exam-platform`;
- audience `csp11-exam-platform`;
- algorithm RS256;
- Google Secure Token JWKS;
- authentication before privileged Supabase client creation.

Because `jwtVerify` receives the exact CSP11 issuer and audience, a token for
another Firebase project cannot satisfy the gateway's accepted claim set.
The dedicated live adversarial invalid/expired/wrong-project JWT matrix remains
part of FR18 security validation and does not weaken the FR9 gateway contract.

## Authorized production proof

Workflow: `Phase FR9 Authorized Production Proof`  
Run: `35704749394`  
Exact SHA: `9a01fe716421986513766ac0aab441ce582bf5cc`  
Result: PASS

The workflow consumed a short-lived Firebase learner ID token only through the
GitHub Actions secret `FR9_FIREBASE_LEARNER_ID_TOKEN`.

The token-presence gate passed. The token itself was not printed, uploaded or
persisted.

The live authorized proof established:

1. authorized `catalog` returned compact metadata only;
2. the catalogue contained 35 competency descriptors;
3. competency `d01_c01` resolved to question version 1;
4. a request without a matching known version/checksum returned
   `current: false`;
5. exactly one HTTPS signed package URL was issued;
6. signed URL TTL was exactly 60 seconds;
7. expected compressed package size was 41,378 bytes;
8. downloaded compressed package size was exactly 41,378 bytes;
9. downloaded SHA-256 matched
   `b33bb5c30fa8533a9cbb4ae48a49d3161ecfb845c4a8897f9f910f59aaaaf12b`;
10. gzip integrity validation succeeded;
11. the package descriptor reported 160 published questions;
12. the same competency request with the returned version/checksum returned
    `current: true`;
13. the unchanged response contained no `signedUrl`;
14. the unchanged response contained no signed URL TTL;
15. no sensitive values were persisted by the proof.

## Sanitized evidence artifact

Artifact ID: `10684135351`  
Artifact name:
`fr9-authorized-production-proof-9a01fe716421986513766ac0aab441ce582bf5cc`  
Artifact ZIP size: 621 bytes  
Artifact digest:
`sha256:e52e918c4dc7daf7852d11ce19825249d505857b27f74e9c58d3a71963a09ab4`

The artifact contains only sanitized proof metadata. It contains no learner
token and no signed package URL.

## FR9 closure assessment

All FR9F production-validation evidence items are now satisfied.

The remaining mechanical closure action is intentionally separate from the
evidence itself:

1. commit this completed evidence record;
2. run the full FR workflow on that exact evidence SHA;
3. require a completely green result;
4. create `phase-fr9-closed` at that exact SHA;
5. do not move the recovery branch after freeze.

Until step 4 is complete, this branch remains the working FR9 branch rather
than the frozen recovery point.
