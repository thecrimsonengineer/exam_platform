# CSP11 REL-GOV-9 Release Candidate Review and Rollback Recovery Contract

Status: IMPLEMENTED CANDIDATE
Phase: REL-GOV-9
Repository: thecrimsonengineer/exam_platform
Base checkpoint: phase-rel-gov8-release-candidate-ci-closed
Base commit: bf5dcab1e1c753774ce52e5a1ca438f87859c885
Date: 2026-09-24

## 1. Purpose

REL-GOV-9 defines the review boundary for a governed release candidate and the immutable lineage required to identify a prior stable release for recovery.

It records recovery metadata.

It does not execute rollback, checkout, deployment, database mutation, artifact restoration or publication.

## 2. Frozen recovery fields

The recovery contract records exactly:

```
previousStableRelease
previousStableCommit
previousStableTree
rollbackEligible
```

These fields map directly to the frozen REL-GOV implementation plan.

## 3. Recovery lineage states

Two valid lineage shapes exist.

No previous stable release:

```json
{
  "previousStableRelease": null,
  "previousStableCommit": null,
  "previousStableTree": null,
  "rollbackEligible": false
}
```

Complete prior stable lineage:

```json
{
  "previousStableRelease": "csp11-1.0.0",
  "previousStableCommit": "<40-character lowercase Git SHA>",
  "previousStableTree": "<40-character lowercase Git SHA>",
  "rollbackEligible": true
}
```

A complete prior stable lineage may also be recorded with rollbackEligible false when the stable release is known but policy does not permit recovery to it.

## 4. Fail-closed lineage rules

Recovery lineage is atomic.

The three identity fields are either:

- all null
- all populated

Partial lineage is invalid.

rollbackEligible may be true only when all three stable identity fields are present and valid.

previousStableCommit and previousStableTree must each be lowercase 40-character Git SHAs.

previousStableRelease must be non-empty when present.

## 5. Artifact recovery identity

REL-GOV-9 does not duplicate artifact hashes into the four-field recovery object.

previousStableRelease identifies the governed stable release record and its frozen evidence package.

That stable evidence package contains the prior artifact manifest and checksums produced by REL-GOV-5 and REL-GOV-7.

The recovery tuple therefore identifies:

```
stable release identity
+ exact source commit
+ exact source tree
+ governed stable evidence package
        ↓
correct prior source and artifacts
```

A later recovery executor must re-verify that package before any restoration action.

## 6. Candidate review intents

REL-GOV-9 defines three review intents:

```
APPROVE
REJECT
RECOVERY_REQUIRED
```

These are review decisions, not deployment commands.

## 7. Approval rule

APPROVE is allowed only when the existing REL-GOV-4 admission result is ADMISSIBLE.

A BLOCKED candidate cannot be approved by the review layer.

The review layer therefore cannot override release admission.

## 8. Rejection rule

REJECT is allowed for an admissible or blocked candidate.

This supports human release control even when a candidate technically satisfies automated admission.

REL-GOV never forces publication merely because a candidate is admissible.

## 9. Recovery-required rule

RECOVERY_REQUIRED is allowed only when:

```
rollbackEligible == true
```

and the recovery object has already passed the complete-lineage validation.

A review cannot claim that recovery is available when no valid prior stable anchor exists.

## 10. Review rationale

Every review intent requires a non-empty rationale.

The review policy returns blocking issues rather than inventing a successful review when rationale is absent.

Issue codes:

```
RCR001_RATIONALE_REQUIRED
RCR002_APPROVAL_REQUIRES_ADMISSIBLE
RCR003_RECOVERY_REQUIRES_ELIGIBLE_ANCHOR
```

## 11. Relationship to candidate CI

REL-GOV-8 produces a governed candidate and evidence bundle.

REL-GOV-9 consumes the already-computed admission result conceptually during review.

REL-GOV-9 does not change:

- the REL-GOV-8 workflow
- candidate artifacts
- candidate evidence
- admission gates
- source checkout
- build environment

Review remains downstream from technical admission.

## 12. Manifest integration

The existing release manifest already has a recovery object.

ReleaseRecoveryMetadata.toJson() produces the exact map shape intended for that field.

REL-GOV-9 does not rewrite the frozen manifest builder in place.

A future release-state transition may supply this validated recovery map when producing its governed manifest.

## 13. Non-execution boundary

The REL-GOV-9 implementation contains no code that performs:

```
git reset
git checkout
git switch
git push
artifact restore
flutter build
Firebase deployment
Supabase mutation
store publication
network rollback request
```

Recovery metadata is evidence and lineage only.

## 14. Why rollback is not automatic

An automatic rollback can affect:

- application binaries
- backend compatibility
- stored data
- authentication state
- remote configuration
- schema versions
- user sessions

Those effects require a later explicitly governed executor and platform-specific controls.

REL-GOV-9 deliberately stops before that boundary.

## 15. Exit criteria

REL-GOV-9 may close only when:

```
base checkpoint exact
recovery contract present
exact four recovery fields preserved
null recovery state valid
complete stable lineage valid
partial lineage blocked
invalid Git SHAs blocked
rollback eligibility without lineage blocked
approval requires ADMISSIBLE
rejection remains human-selectable
recovery-required needs eligible anchor
review rationale required
no rollback execution primitives present
format green
analyzer green
full REL-GOV regression green
repository diff limited to REL-GOV-9
blocking implementation failures = 0
```

Closure checkpoint:

```
phase-rel-gov9-rollback-recovery-closed
```

Next frozen phase:

```
REL-GOV-10 -> Drift and Tamper Regression
```
