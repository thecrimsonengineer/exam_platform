# Home + Startup Integration Authorization Hotfix

## Status

This hotfix exists only to repair Android release packaging for the already-frozen Home + Startup integration.

Base frozen checkpoint:

- Branch: `phase-home-startup-integration-closed`
- SHA: `b9a8150adaf21a3f43cb2120b5dbfcc0ce119c8a`

Hotfix branch:

- `phase-home-startup-integration-auth-hotfix`

## Defect

The frozen INT-R9 APK was built without the compile-time Supabase runtime values required by:

- `SupabaseRuntimeConfig.fromEnvironment()`
- `SupabaseBootstrapService.initializeIfConfigured()`
- `LearnerOnlineAccessRuntime.createDefaultController()`

As a result, Firebase learner sign-in could succeed while the FR8 fail-closed online authorization layer remained locked.

Observed learner UI:

`Protected learning content is locked until online authorization succeeds.`

## Scope

This hotfix must not weaken or bypass FR8/FR9/FR10 authorization controls.

Allowed changes:

1. release workflow packaging configuration;
2. CI validation for required public Supabase runtime values;
3. documentation and evidence related to the packaging correction.

No learner authorization code, cache boundary, content-delivery gateway, question-delivery gateway, Firebase authentication logic, Home behavior, Startup behavior, LAB behavior, Learning Twin behavior, or frozen content rules may be weakened.

## Runtime configuration contract

The Android release APK must be compiled with:

- `SUPABASE_URL=https://esfycnmfywxczfillioj.supabase.co`
- `SUPABASE_PUBLISHABLE_KEY` from GitHub Actions secret `SUPABASE_PUBLISHABLE_KEY`

The publishable key must begin with:

`sb_publishable_`

The following must never be embedded in the client APK:

- Supabase secret key;
- service-role key;
- database password;
- Firebase Admin credentials.

## CI fail-closed rule

The hotfix APK workflow must fail before compilation when:

- `SUPABASE_URL` is absent;
- `SUPABASE_PUBLISHABLE_KEY` is absent;
- the publishable key does not have the expected public-key prefix.

## Required validation

Before an APK artifact is accepted:

1. verify ancestry from the frozen INT-R9 checkpoint;
2. resolve Flutter packages without modifying `pubspec.lock`;
3. run Supabase runtime configuration tests;
4. replay online access gate and learner shell tests;
5. replay integrated Startup → Auth → Home navigation tests;
6. build Android release APK using both required `--dart-define` values;
7. upload APK and sanitized evidence;
8. keep server-side secrets out of APK build configuration.

## Manual device acceptance

After downloading the resulting APK, test on a real learner account:

1. open the app;
2. complete Startup Motion;
3. sign in through Firebase;
4. confirm verified learner routing;
5. confirm online authorization completes;
6. confirm Home appears instead of the secure-access lock screen;
7. open protected study content;
8. open protected practice/question delivery;
9. background and resume the app and confirm revalidation succeeds;
10. disconnect network and confirm fail-closed behavior still applies.

Only after these checks pass should the corrected APK be treated as the release candidate.
