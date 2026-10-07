# REL-GOV Frozen Plan Amendment 001

Status: APPROVED IMPLEMENTATION AMENDMENT
Date: 2026-09-24
Applies to: REL-GOV implementation plan
Working branch: phase-rel-gov-release-governance

## Reason

The connected execution environment can write and inspect GitHub repository state but does not provide a registered Codex execution environment, a local Flutter/Dart runtime, or a GitHub workflow-dispatch action.

REL-GOV requires executable validation evidence before run checkpoints are closed.

Therefore a non-publishing phase-validation workflow is added earlier than REL-GOV-8.

## Added support file

```
.github/workflows/rel_gov_validation.yml
```

## Scope

This workflow is an implementation-validation harness only.

It may:
- resolve project dependencies
- check REL-GOV formatting
- analyze REL-GOV implementation/test paths
- execute REL-GOV tests

It must not:
- build a governed release candidate
- generate production release admission
- publish artifacts to stores
- deploy Firebase or Supabase
- access production deployment secrets
- sign production builds

## Relationship to REL-GOV-8

REL-GOV-8 remains unchanged.

```
.github/workflows/csp11_release_candidate.yml
```

will still be the dedicated governed release-candidate workflow.

The validation harness exists only to provide real execution evidence while REL-GOV itself is being constructed.

## Governance effect

No release invariant is weakened.
No run is removed.
No run is combined.
No production capability is introduced.
The 12-run sequence remains frozen.
