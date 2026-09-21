# CSP11 Phase FR6 Published Catalogue

Status: IMPLEMENTATION CANDIDATE
Branch: phase-fr6-published-catalogue
Source checkpoint: phase-fr5-closed at 0c241694703bea2bc6bfae86334a36e8d125f6ba
Date: 2026-09-21

## Purpose

FR6 adds the small competency-scoped PostgreSQL catalogue used by later learner delivery phases to decide whether a protected immutable package has changed.

FR6 does not build Storage packages, does not change learner routing, does not remove Firestore reads and does not permit offline protected learning.

## Frozen architecture

The catalogue is a current pointer, not package history.

```text
published_packages
  = immutable version history

published_catalog
  = one current content/question pointer per competency
```

A rollback therefore changes the catalogue pointer to a known-good immutable package. It does not overwrite a published package.

## Catalogue contract

One row is keyed by competency_id and records:

- content version
- content SHA-256
- content Storage object path
- content compressed size
- question version
- question SHA-256
- question Storage object path
- question compressed size
- published question count
- publication timestamp
- active state

FR7 owns deterministic package building, compression, upload verification and catalogue-last publication.

## Security contract

published_catalog is in the public schema, so FR6 explicitly enables RLS.

Direct anon and authenticated Data API privileges are revoked and an explicit fail-closed RLS policy is retained. Server-side service_role access remains available for reviewed Edge/server publication and lookup boundaries.

No service-role or secret key is stored in the repository or Flutter client.

## Performance contract

The ordinary learner path later becomes:

```text
online authorization
-> one competency catalogue lookup
-> compare versions/checksums with UID-scoped authorized cache
-> fetch only changed immutable package
```

FR6 must not introduce global catalogue scans into learner runtime.

## Acceptance

FR6 can close only when:

1. The migration is schema-only.
2. The catalogue has exactly one competency-scoped current pointer.
3. Content/question versions, checksums, paths, sizes and count are constrained.
4. Direct learner Data API access remains fail-closed.
5. Immutable package history remains in published_packages.
6. The live Supabase schema migration is applied successfully.
7. Supabase security advisors have no FR6 security finding.
8. The exact FR6 repository SHA passes formatting, analyze, FR1-FR6 gates, frozen L4 suites, full repository regression and diff hygiene.
9. phase-fr6-closed is created only at that exact green SHA.

## NEXT ACTION

Validate the FR6 repository candidate.

If green, apply the published_catalog migration to csp11-supabase, verify its live schema and advisors, record the live result, rerun the exact repository gate, then freeze phase-fr6-closed.

After FR6 closure, continue to FR7 Supabase Storage Publishing Pipeline.
