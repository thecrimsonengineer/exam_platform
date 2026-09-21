# CSP11 Phase FR7 Supabase Storage Publishing Pipeline

Status: IMPLEMENTATION CANDIDATE
Branch: phase-fr7-storage-publishing
Source checkpoint: phase-fr6-closed at c7689ed50a2a950cc3e79da5701c3fe9758ba3a4
Date: 2026-09-21

## Purpose

FR7 turns the FR5 parity-verified Supabase shadow records into small immutable competency packages for later online-authorized learner delivery.

FR7 does not cut learner runtime over to Supabase. Firestore remains the learner source until later FR cutover phases.

## Frozen package architecture

For every competency that has both published StudyContent and published questions:

1. select the latest published content version;
2. select the latest published version of each question ID;
3. build canonical JSON with no generated timestamp;
4. gzip deterministically;
5. SHA-256 the compressed bytes;
6. reuse an existing immutable package when the checksum already exists;
7. otherwise allocate the next package revision and immutable object path;
8. upload with overwrite disabled;
9. download and verify the exact compressed checksum;
10. call one service-role-only PostgreSQL transaction per competency;
11. register or verify both immutable package metadata rows inside that transaction;
12. switch both current package pointers inside that transaction;
13. update published_catalog last inside that same transaction.

Package paths are:

```text
content/<competency_id>/v<package_version>.json.gz
questions/<competency_id>/v<package_version>.json.gz
```

The package revision is independent from individual source-record versions. This prevents a question-package change from being missed merely because another question already has a higher source version.

## Rollback

If the source returns to a checksum that already exists in immutable history, FR7 reuses that historical package version and repoints the current package/catalogue state. It does not upload a duplicate object.

FR7 also defines a service-role-only atomic rollback function that repoints content, questions and the competency catalogue to known-good immutable versions in one transaction. It never deletes Storage objects.

## Storage security

The bucket is `csp11-published-packages`.

It must be private. FR7 refuses to publish if that bucket is public.

The server-side publisher uses `SUPABASE_SECRET_KEY` from GitHub Secrets. The key is never stored in the repository or Flutter client.

FR7 creates no learner Storage policy. Direct learner package delivery remains blocked until the reviewed online-authorization boundary is implemented in later FR phases.

## Non-destructive rules

FR7 never:

- overwrites an immutable Storage object;
- deletes a Storage object;
- deletes an unexpected package row;
- silently removes an unexpected active catalogue row;
- publishes when a registered object is missing;
- accepts an existing object whose checksum differs from the planned package.

Unexpected stale current package/catalogue rows are blockers rather than cleanup targets.

## Catalogue-last rule

The publication sequence is fail-safe:

```text
source snapshot
-> deterministic package plan
-> private bucket
-> immutable object
-> download/checksum verification
-> immutable published_packages registration
-> current package selection
-> published_catalog update LAST
-> final database + object verification
```

Storage objects are verified before the database transaction starts. Package registration, both current-package switches and the catalogue pointer then commit or roll back together. A crash cannot leave current package metadata ahead of the learner-visible catalogue pointer.

## Current production source shape

The FR5 production shadow currently contains 35 competencies that have both published content and published questions.

Published content has multiple historical versions for several competencies, so FR7 explicitly selects the latest content source version. Question selection is by latest version per question ID.

## Acceptance

FR7 can close only when:

1. deterministic unit tests pass;
2. repeated fixture builds are byte-identical;
3. the private bucket is proven private;
4. production preflight is green;
5. production package publication completes with checksum verification;
6. published_packages current rows exactly match the plan;
7. published_catalog has exactly one active row per publishable competency and is updated last;
8. security advisors remain clean;
9. package sizes are measured;
10. exact-SHA FR1-FR7, frozen L4, full repository and diff-hygiene gates are green;
11. phase-fr7-closed is created only at that exact green SHA.

## NEXT ACTION

Run the normal FR validation on this implementation candidate.

If green, run the manual FR7 production workflow with publish=false first. Only after a green production preflight may publish=true be run with exact confirmation `FR7_PUBLISH_PACKAGES`.

Then verify live Storage/package/catalogue state, record evidence, rerun the exact repository gate and freeze phase-fr7-closed.
