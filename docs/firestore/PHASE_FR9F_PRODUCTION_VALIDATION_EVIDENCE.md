# CSP11 Phase FR9F Production Validation Evidence

Status: PARTIAL PRODUCTION EVIDENCE — CLOSURE BLOCKED  
Date: 2026-09-22  
Branch: `phase-fr9-question-delivery-cutover`  
Green checkpoint: `c1cadb82c9a551604249083f091b2311ea377848`  
Green CI run: `35697656070`

## Purpose

This file separates live production facts from repository-only assertions so
FR9 cannot be frozen from incomplete evidence.

## Exact-SHA repository gate

Run `35697656070` completed successfully on exact SHA
`c1cadb82c9a551604249083f091b2311ea377848`.

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

The custom gateway therefore retains in-handler Firebase RS256 verification
against the CSP11 project before constructing the privileged Supabase client.

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

The only anon/authenticated policy on `published_catalog` is
`fr_edge_only_deny_direct_client`, command `ALL`, with predicate
`false`.

Therefore direct learner Data API catalogue access and direct Storage reads
remain denied. Package delivery remains through the Edge gateway and
short-lived signed URLs.

## Live fail-closed authentication evidence

The main FR workflow now performs production HTTP requests to
`learner-question-packages`.

On run `35697656070`:

1. a POST `catalog` request with no Authorization header returned HTTP 401
   with `invalid_firebase_token`;
2. a POST `catalog` request with a malformed bearer token returned HTTP 401
   with `invalid_firebase_token`.

The repository architecture tests also pin:

- Firebase project `csp11-exam-platform`;
- issuer `https://securetoken.google.com/csp11-exam-platform`;
- audience `csp11-exam-platform`;
- algorithm RS256;
- Google Secure Token JWKS.

## Remaining closure proof

FR9F is not complete yet.

A pre-existing valid signed Firebase learner ID token is still required to
perform the positive production path without automating creation or handling of
a new live authentication credential.

The remaining proof must demonstrate:

1. authorized `catalog` returns compact metadata only;
2. a competency request without a matching known version/checksum returns
   `current: false`, exactly one HTTPS signed URL and TTL 60 seconds;
3. the downloaded gzip byte count equals `questionSizeBytes`;
4. SHA-256 equals `questionChecksumSha256`;
5. gzip integrity succeeds;
6. the same competency request with the returned current version/checksum
   returns `current: true`;
7. that unchanged response contains no `signedUrl`;
8. issuer/audience checks continue to reject a token not issued for the CSP11
   Firebase project.

## Closure rule

Do not create or move `phase-fr9-closed` while any item in the preceding
section remains unproven.

After the authorized positive-path proof is captured, run the full FR workflow
again on the exact evidence SHA. Only a fully green exact-SHA result may become
the FR9 recovery point.
