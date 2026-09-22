# INT-R9A1 Runtime Configuration Provisioning

## Status

**READY FOR OWNER PROVISIONING — NOT CLOSED**

Working branch:

`phase-home-startup-integration-auth-hotfix`

Frozen base:

`b9a8150adaf21a3f43cb2120b5dbfcc0ce119c8a`

Current branch checkpoint before INT-R9A1 provisioning:

`879c1e3849f5f008d28e0cdf5077d908a38903ad`

## Purpose

Provision the public Supabase runtime configuration needed by the Android learner client without weakening the FR8 fail-closed authorization boundary or exposing server-side credentials.

## Required client configuration

The release client requires exactly these public runtime values:

- `SUPABASE_URL=https://esfycnmfywxczfillioj.supabase.co`
- GitHub Actions secret `SUPABASE_PUBLISHABLE_KEY`

The publishable key must use the Supabase publishable-key format:

`sb_publishable_...`

## Explicitly prohibited from client builds

The following values must never be passed through `--dart-define`, committed to the repository, written to build evidence, or embedded in the APK:

- `SUPABASE_SECRET_KEY`
- Supabase service-role key
- database password
- Firebase Admin credentials
- private signing secrets

## Existing repository enforcement

`.github/workflows/home_startup_auth_hotfix_apk.yml` already:

1. fixes the public Supabase project URL to the production project;
2. reads `SUPABASE_PUBLISHABLE_KEY` only from GitHub Actions secrets;
3. fails before compilation when the secret is absent;
4. rejects a key that does not begin with `sb_publishable_`;
5. avoids printing the key;
6. injects only the public URL and publishable key into the Flutter release build.

## Owner provisioning action

In GitHub:

`Repository → Settings → Secrets and variables → Actions → New repository secret`

Create:

- **Name:** `SUPABASE_PUBLISHABLE_KEY`
- **Value:** the production Supabase publishable key beginning with `sb_publishable_`

Do not rename or reuse `SUPABASE_SECRET_KEY`.

## Acceptance gate

INT-R9A1 can close only when a GitHub Actions run on the hotfix branch demonstrates:

- `SUPABASE_URL` is present;
- `SUPABASE_PUBLISHABLE_KEY` is present;
- publishable-key prefix validation passes;
- no server-side key is consumed by the APK workflow;
- no secret value is printed to logs.

Until that evidence exists, the phase remains open and INT-R9A2 must not be treated as validated.

## Next action after provisioning

Trigger the `Home Startup Authorization Hotfix APK` workflow on:

`phase-home-startup-integration-auth-hotfix`

The configuration preflight must pass before proceeding to INT-R9A2 packaging validation.
