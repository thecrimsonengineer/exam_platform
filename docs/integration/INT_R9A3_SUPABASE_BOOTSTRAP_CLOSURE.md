# INT-R9A3 Supabase Bootstrap Verification Closure

## Status

**CLOSED — PASS**

Working branch:

`phase-home-startup-integration-auth-hotfix`

R9A2 recovery checkpoint:

`phase-home-startup-integration-auth-hotfix-r9a2-closed`

R9A2 closure SHA:

`479fb4c48605c2fdbba18022ab1e3c7a27aba854`

Validated R9A3 candidate SHA:

`e4f2fb23ca592dfa88ac3270d07341406fbaccc8`

Successful GitHub Actions run:

`35809331564`

Workflow:

`INT-R9A3 Supabase Bootstrap Verification`

## Purpose

INT-R9A3 proves that the corrected release configuration is not merely present at packaging time. It is wired through the application bootstrap path so that Firebase initializes first, Supabase receives the public runtime configuration, the Supabase client uses the current Firebase ID token, and the learner runtime selects the real remote authorization probe only after Supabase initialization succeeds.

## Verified bootstrap chain

The validated application chain is:

`Firebase.initializeApp()`
→ `SupabaseBootstrapService.initializeIfConfigured()`
→ `SupabaseRuntimeConfig.fromEnvironment()`
→ `Supabase.initialize(...)`
→ Firebase `currentUser?.getIdToken()`
→ `SupabaseBootstrapService.isInitialized == true`
→ `SupabaseLearnerRemoteAuthorizationProbe`
→ `firebase-auth-probe`

The fail-closed alternative remains:

missing or invalid Supabase configuration
→ bootstrap does not initialize
→ unavailable learner authorization probe
→ protected learner access remains locked.

## Exact validation results

The configured bootstrap test suite passed six R9A3 checks:

1. release dart-defines resolve the production public client configuration;
2. Firebase initializes before Supabase and before `runApp`;
3. Supabase bootstrap consumes the public URL and publishable key;
4. the Supabase access-token callback uses the Firebase ID token;
5. learner runtime selects the remote probe only after bootstrap succeeds;
6. client bootstrap surfaces contain no privileged Supabase key contract.

Additional existing regressions also passed:

- missing-config bootstrap remains inert/fail-closed;
- Supabase learner remote authorization probe tests;
- dependency graph stability;
- R9A2 ancestry verification.

## Production Edge Function smoke

The deployed endpoint:

`https://esfycnmfywxczfillioj.supabase.co/functions/v1/firebase-auth-probe`

was reachable during CI.

The endpoint correctly rejected:

- a request with no bearer token using HTTP 401 and `missing_bearer_token`;
- a malformed bearer token using HTTP 401 and `invalid_firebase_token`.

This confirms the deployed custom Firebase-token gateway remains reachable and fail-closed.

## Secret handling evidence

GitHub Actions masked the publishable key in logs.

The validation proved only that:

- `SUPABASE_URL` is configured;
- `SUPABASE_PUBLISHABLE_KEY` is configured;
- the publishable key has the required public-key format.

No server-side Supabase secret, service-role key, database password, or Firebase Admin credential was added to the client bootstrap path.

## Evidence artifact

Artifact name:

`INT-R9A3-supabase-bootstrap-evidence`

Artifact ID:

`10729265955`

Artifact digest:

`sha256:8eb10697ecab9ca91cccbadcb91658fb6aa714d3fb7f4c12a5f0a7bf852aef2e`

## Development note

The first R9A3 CI attempt failed because the newly added verification test contained an invalid Dart string literal for the literal text `$normalizedToken`. The defect was confined to the new test harness. No production application code was changed to resolve it.

The assertion was repaired and the complete R9A3 workflow then passed on exact SHA:

`e4f2fb23ca592dfa88ac3270d07341406fbaccc8`

## Closure decision

INT-R9A3 is closed.

The application now has evidence that the public Supabase release configuration flows through the intended Firebase-first bootstrap path and reaches the deployed fail-closed authorization gateway without exposing privileged credentials.

Next planned run:

**INT-R9A4 — Authorization Chain Regression**
