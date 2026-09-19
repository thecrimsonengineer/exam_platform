# CSP11 Phase FR2 Foundation

**Status:** STARTED  
**Base:** `phase-fr1-closed` @ `00c2efefdc8e9b653f62b7d128e5334df146b2b4`  
**Date:** 2026-09-19

## Scope

FR2 creates the Supabase foundation only. It does not migrate production learner data and does not alter the existing learner cache.

## Verified preflight

- Supabase organization: SafeZone.
- Organization plan: Free.
- Existing Supabase projects: 0.
- Current project creation cost returned by Supabase: $0/month.
- Firebase project ID: `csp11-exam-platform`.
- Repository currently has no Firebase Functions package.
- Current stable `supabase_flutter` version verified for implementation planning: `2.17.2`.
- Supabase Firebase third-party Auth requires Firebase JWTs to contain `role: authenticated`.

## Free-tier authentication constraint

FR2 must not introduce a paid Firebase Functions dependency merely to stamp the Supabase transport role claim.

Before production Supabase authorization is enabled, FR2 must prove a free-tier-compatible privileged claim-provisioning path for:

- all existing Firebase users;
- every new Firebase user;
- token refresh after claim provisioning;
- preservation of existing custom claims.

A Supabase Edge Function or another already-in-scope free privileged execution path may be evaluated, but no approach is frozen until it is implemented and security-tested.

The Supabase JWT `role: authenticated` claim is a transport/database role. It must not replace CSP11's separate admin/student application-role model.

## Foundation introduced

The first FR2 code establishes:

- validated runtime configuration using only `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`;
- explicit rejection of secret/service-role keys in client configuration;
- a Firebase access-token provider boundary;
- a fail-closed learner online authorization gate;
- deterministic unit tests for no-user, rejected, unavailable and authorized states.

No screen is switched to this gate yet. Protected-content enforcement is activated only after the real Supabase probe and migration-safe UI wiring are validated.

## Free-tier authorization decision

FR2 excludes Firebase Cloud Functions. Deploying Firebase Functions would require moving the Firebase project off the Spark-only constraint.

The selected FR2 authorization architecture is:

```text
Firebase Auth
   ↓ Firebase ID token
Supabase Edge Function: firebase-auth-probe
   ↓ server-side signature / issuer / audience / expiry verification
FR online-access gate
   ↓
protected CSP11 delivery paths
```

The Edge Function validates the Firebase ID token against Google's published Secure Token signing keys and requires:

- issuer `https://securetoken.google.com/csp11-exam-platform`;
- audience `csp11-exam-platform`;
- `RS256` signature;
- valid token lifetime;
- non-empty Firebase subject/UID.

The function uses custom Firebase-token verification, therefore its Supabase gateway JWT verification is intentionally disabled for this function only. This is not public authorization: the function itself performs fail-closed Firebase verification.

No Supabase service-role key or secret is embedded in Flutter or the function source.

Protected learner data will not use direct client access to Supabase tables during FR. Later learner reads/writes must pass through authenticated server-side boundaries or another explicitly reviewed mechanism.

This removes the need for the Firebase `role: authenticated` custom claim in the FR gateway path and keeps Firebase Auth as the single learner identity provider.

The Supabase project remains empty of learner schema/data during FR2.

## NEXT ACTION

After the FR2 foundation tests are green:

1. create/configure the Supabase Free project with explicit project-creation approval;
2. add/pin `supabase_flutter`;
3. deploy and verify the Firebase-token Edge authorization probe;
4. connect the real Supabase authorization probe to protected learner gating only after live verification;
5. preserve the existing Firebase identity and local-data contracts;
6. keep production data unmigrated until FR3 schema/RLS design is frozen.
