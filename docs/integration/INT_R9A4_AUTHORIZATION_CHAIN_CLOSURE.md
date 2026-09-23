# INT-R9A4 Authorization Chain Regression Closure

## Status

**CLOSURE CANDIDATE**

Working branch:

`phase-home-startup-integration-auth-hotfix`

R9A3 recovery checkpoint:

`phase-home-startup-integration-auth-hotfix-r9a3-closed`

R9A3 closure SHA:

`71b79c00a8aad52d9d6cc94a70164dc957c50c5c`

Validated R9A4 candidate SHA:

`957bd5b6860a4722c7f651eaafecb1d25009aee6`

Successful GitHub Actions run:

`35810065030`

Workflow:

`INT-R9A4 Authorization Chain Regression`

## Purpose

INT-R9A4 verifies the learner authorization state machine after the Supabase packaging and bootstrap correction. The run proves that protected learner access opens only after a Firebase token is obtained and the remote authorization layer approves it, while every tested failure, lifecycle, connectivity, and identity-change path remains fail-closed.

## Phase-specific regression results

Seven R9A4 chain tests passed:

1. valid Firebase token plus remote approval authorizes only the bound learner;
2. missing Firebase token locks without invoking the remote authorization probe;
3. remote rejection locks the learner session;
4. backend unavailability fails closed;
5. app resume locks first and then reauthorizes with forced token refresh;
6. confirmed network loss locks and restoration forces remote reauthorization;
7. a user switch during in-flight authorization cannot authorize the old user.

## Preserved FR regressions

The existing frozen authorization suites were replayed and passed:

- learner online access gate: 6 tests;
- learner online access session controller: 7 tests;
- learner online connectivity coordinator: 5 tests;
- learner authorized shell: 4 tests;
- Supabase learner remote authorization probe: 4 tests;
- FR8 online-authorized cache/security architecture: 13 tests.

Total authorization-related tests executed in this workflow:

`46`

All passed.

## Security properties proven

The successful workflow confirms:

`VALID_TOKEN_REMOTE_APPROVAL_AUTHORIZES=true`

`MISSING_TOKEN_FAILS_CLOSED=true`

`REMOTE_REJECTION_FAILS_CLOSED=true`

`BACKEND_UNAVAILABLE_FAILS_CLOSED=true`

`RESUME_LOCKS_THEN_FORCE_REFRESHES=true`

`NETWORK_LOSS_LOCKS=true`

`NETWORK_RESTORE_FORCE_REAUTHORIZES=true`

`USER_SWITCH_INVALIDATES_INFLIGHT_AUTHORIZATION=true`

`PROTECTED_SHELL_HIDDEN_UNTIL_AUTHORIZED=true`

`SUPABASE_PUBLISHABLE_KEY_CONFIGURED=true`

`SERVER_SECRET_EMBEDDED=false`

## Evidence artifact

Artifact name:

`INT-R9A4-authorization-chain-evidence`

Artifact ID:

`10729427070`

Artifact digest:

`sha256:a165f0aa12f3c3815be2e8c62cf6d3c73daafb7ed61d08c70e01a0b177423c3b`

## Development note

Early R9A4 attempts stopped at the newly introduced Dart formatting gate. No production application code failed and no production behavior was changed to resolve those attempts. The test file was formatted to the repository's Dart formatter output, the strict formatting gate was restored, and the complete authorization regression workflow then passed.

## Closure rule

The closure document itself is included in the R9A4 workflow trigger. INT-R9A4 should be marked fully closed only after this closure commit receives a successful exact-SHA workflow run.

Next planned run after closure:

**INT-R9A5 — FR9 / FR10 Protected Delivery Regression**
