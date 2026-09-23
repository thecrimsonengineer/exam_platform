# INT-R9A6 Integrated Release Candidate Regression Closure

## Status

**CLOSURE CANDIDATE**

Working branch:

`phase-home-startup-integration-auth-hotfix-r9a6`

R9A5 recovery checkpoint:

`phase-home-startup-integration-auth-hotfix-r9a5-closed`

R9A5 closure SHA:

`616226a9df64eb0395b49f1046143541b3ad78a2`

Validated R9A6 candidate SHA:

`c4249463cdeeb2d53ecfcbb8873529daa34b322e`

Successful GitHub Actions run:

`35825464950`

Workflow:

`INT-R9A6 Integrated Release Candidate Regression`

## Purpose

INT-R9A6 validates the Home + Startup authorization hotfix chain as one integrated Android release candidate.

The run combines:

- frozen integration ancestry;
- configured Supabase bootstrap;
- learner authorization state-machine regression;
- Startup → Auth → Home rendering and navigation;
- FR8 authorization-boundary regression;
- FR9 protected question delivery;
- FR10 protected StudyContent delivery;
- deployed fail-closed endpoint checks;
- deterministic Android signing;
- Android release APK compilation;
- APK package and signature verification.

## Green candidate results

The exact-SHA workflow passed:

1. frozen Home + Startup and R9A5 ancestry;
2. public Supabase runtime configuration preflight;
3. stable Android signing-secret preflight;
4. Java 17 and Flutter 3.44.9 setup;
5. package resolution and lockfile stability;
6. integrated release-scope analysis;
7. configured Supabase bootstrap verification;
8. missing-config bootstrap fail-closed regression;
9. Supabase remote authorization-probe contract;
10. R9A4 end-to-end authorization-chain replay;
11. online-access gate, session, connectivity and learner-shell regressions;
12. Startup → Auth → Home integrated render/navigation regression;
13. R5 behavioral seam;
14. Startup release-render and hardening regressions;
15. critical FR8 authorization-cache architecture gate;
16. FR9 package, cache, gateway, QuizService and practice cutover gates;
17. FR10 package, cache, delivery, gateway, loader, navigation and closure gates;
18. deployed authorization endpoint missing/malformed-token rejection;
19. deployed FR9 and FR10 delivery endpoint missing/malformed-token rejection;
20. explicit backed-up Android signing identity restoration;
21. Android release APK build with required Supabase dart defines;
22. packaged Startup Motion asset verification;
23. APK Signature Scheme v2 verification;
24. exact APK certificate fingerprint match with the restored signing identity;
25. release-candidate APK upload;
26. sanitized evidence upload;
27. clean repository verification.

All passed.

## Signing defect found and corrected

Early R9A6 runs showed an important packaging defect.

The workflow restored the backed-up Android debug keystore with certificate SHA-256:

`97C014CA29254343FE825B8CDB9BFBE1830E8D619FEDAC0F263C4164AA5206BD`

However, the release APK was signed with a different valid debug certificate:

`738C7CB324C36795B1BC0062C455C58624D7529C14FA6BEB793B0620040262F7`

The R9A6 gate correctly rejected that APK.

The cause was reliance on the Android Gradle Plugin's implicit `debug` signing configuration. Restoring a keystore file was not sufficient to prove that the release variant consumed that exact file.

The correction added a conditional explicit signing configuration in:

`android/app/build.gradle.kts`

When the R9A6 CI signing environment is present, release signing now consumes the exact keystore path, password, alias and key password supplied by the workflow. Normal local development retains the existing debug-signing fallback when those CI variables are absent.

After the correction, the APK certificate fingerprint was:

`97C014CA29254343FE825B8CDB9BFBE1830E8D619FEDAC0F263C4164AA5206BD`

and exactly matched the restored backed-up keystore.

No learner runtime, authorization logic, protected-delivery behavior, Home behavior, Startup behavior, content model or question model was weakened to resolve this issue.

## Release-candidate APK evidence

Generated APK:

`CSP11-INT-R9A6-RC-c4249463cdeeb2d53ecfcbb8873529daa34b322e.apk`

Build output:

`72.6 MB`

APK SHA-256:

`fd7d1c5ddd99199affdc9c57719c538fbb4c617723c49655ba9bcad60583b2d8`

APK artifact:

- name: `CSP11-INT-R9A6-release-candidate-apk`
- artifact ID: `10735127589`
- artifact size: `72613404` bytes
- artifact digest: `sha256:90b90db3434ea524f3c8f8fc6b3acba037e8cd8ef3bfc628e5a12c48ef0fc692`

Evidence artifact:

- name: `INT-R9A6-release-candidate-evidence`
- artifact ID: `10734928198`
- artifact digest: `sha256:dc24b6eefcf0830cf95eadd4d679cd738f71384a9ff50983c1f451bd242e1b83`

## Security assertions reconfirmed

`SUPABASE_URL_CONFIGURED=true`

`SUPABASE_PUBLISHABLE_KEY_CONFIGURED=true`

`SERVER_SECRET_EMBEDDED=false`

`STABLE_ANDROID_SIGNING_IDENTITY=true`

`APK_SIGNATURE_V2_VERIFIED=true`

`STARTUP_ASSET_PACKAGED=true`

`FR8_FR9_FR10_CRITICAL_REGRESSION=true`

`DEPLOYED_ENDPOINTS_FAIL_CLOSED=true`

## Signing boundary

This release candidate uses the project's current Android debug-key signing identity, but now deterministically uses the backed-up stable debug keystore rather than an arbitrary CI runner-generated key.

This proves installation/update signing continuity for the current testing distribution.

It does not claim Google Play production-signing readiness. Play Store production signing remains a separate future release-management task.

## Closure rule

This closure document is included in the R9A6 workflow trigger.

INT-R9A6 is fully closed only after this documentation commit receives a successful exact-SHA R9A6 workflow run, including a newly built and signature-verified APK.

After that pass, freeze:

`phase-home-startup-integration-auth-hotfix-r9a6-closed`

at the exact green closure SHA and do not advance it.

Next planned run after closure:

**INT-R9A7 — Physical Device Release Acceptance**
