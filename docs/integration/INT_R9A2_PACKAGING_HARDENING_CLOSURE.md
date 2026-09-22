# INT-R9A2 Packaging Hardening Closure

## Status

**CLOSED — PASS**

Working branch:

`phase-home-startup-integration-auth-hotfix`

Frozen integration ancestor:

`b9a8150adaf21a3f43cb2120b5dbfcc0ce119c8a`

Validated hotfix candidate SHA:

`8960a70627bd1da2d1d020a6c6bd999cefa30bdb`

GitHub Actions run:

`35770682246`

Workflow:

`Home Startup Authorization Hotfix APK`

## Packaging contract proven

The Android release build was executed with the required public Supabase runtime configuration:

- `SUPABASE_URL` configured
- `SUPABASE_PUBLISHABLE_KEY` configured
- server-side Supabase secret not embedded

The workflow retained fail-closed preflight validation and did not weaken FR8, FR9, or FR10 authorization controls.

## CI evidence

The following gates passed on the exact validated SHA:

1. checkout exact hotfix candidate;
2. verify frozen integration ancestry;
3. require safe Supabase client configuration;
4. Java 17 setup;
5. Flutter 3.44.9 setup;
6. package resolution;
7. stable dependency graph;
8. Supabase runtime configuration tests;
9. learner online authorization tests;
10. integrated Startup → Home journey;
11. Android signing setup;
12. authorization-configured Android release APK build;
13. APK package verification;
14. APK artifact upload;
15. sanitized evidence upload;
16. clean repository verification.

Workflow conclusion:

`success`

## APK evidence

Generated file:

`CSP11-auth-hotfix-8960a70627bd1da2d1d020a6c6bd999cefa30bdb.apk`

Build output:

`72.6 MB`

APK SHA-256:

`e5a6b2b2c0db792b89322a10e6a1f9acf77d5d38741a4e72702524d4996bbea8`

GitHub artifact:

- name: `CSP11-auth-hotfix-android-apk`
- artifact ID: `10713744005`
- uploaded artifact size: `72613404` bytes

Sanitized evidence artifact:

- name: `CSP11-auth-hotfix-evidence`
- artifact ID: `10713988681`

## Security assertions

The workflow evidence records:

`SUPABASE_URL_CONFIGURED=true`

`SUPABASE_PUBLISHABLE_KEY_CONFIGURED=true`

`SUPABASE_SERVER_SECRET_EMBEDDED=false`

No server secret, service-role key, database password, or Firebase Admin credential was intentionally injected into the client build.

## Closure decision

INT-R9A2 is closed because the exact candidate:

- preserves the frozen INT-R9 ancestry;
- refuses unsafe/missing public runtime configuration;
- successfully consumes the publishable client key;
- passes runtime-config and authorization regression tests;
- passes integrated Startup → Home regression;
- builds and verifies an Android release APK;
- produces reproducible artifact and checksum evidence.

The next planned run is **INT-R9A3: Supabase Bootstrap Verification**, focused on proving the configured runtime reaches the intended Supabase bootstrap/authentication chain before device acceptance.
