# SEC-01 — CSP11 Google Play Release Foundation

**Status:** IN PROGRESS — baseline verified, Play upload BLOCKED until release gates pass  
**Business model:** Completely free app (no in-app billing, premium entitlements, or subscription enforcement)  
**Source repository:** `thecrimsonengineer/exam_platform`  
**Immutable source checkpoint:** `phase-post-rel-gov-global-navigation-motion-integration-closed@156ea074e1f420672490511a01117804dc22ce74`  
**Working branch:** `phase-sec01-play-release-foundation`  
**Scope:** Android package identity, secure upload signing, Android App Bundle CI, safe client configuration, automated release gates, audit evidence.

## Non-negotiable preservation rules

1. Do not modify, merge into, force-push, or rebase the frozen checkpoint. All SEC-01 work lands on the new working branch only.
2. Do not change Firebase Auth, FR8 online access, FR9 question package delivery, FR10 learning-content delivery, Supabase functions, Firestore rules, or learner progress semantics in SEC-01.
3. Do not expose server keys, Supabase secret/service-role keys, Firebase service account credentials, private upload keys, or keystore passwords to the Android bundle, public GitHub repository, CI output, or artifacts.
4. Preserve existing debug APK development workflows. A Play-bound artifact must use a separate, explicitly configured production upload key and must never fall back to the debug certificate.
5. Do not upload any artifact to Google Play before manual acceptance and final package-name approval.

## Verified repository baseline (02 Nov 2026)

| Finding | Location | SEC-01 implication |
| --- | --- | --- |
| Package ID is `com.example.exam_platform` | `android/app/build.gradle.kts` | Replace with final unique, permanent ID before the first Play upload. |
| Release signing can use `signingConfigs.getByName("debug")` | `android/app/build.gradle.kts` | Make Play builds fail closed on missing upload-key material. |
| R9A6 CI restores `androiddebugkey` and builds APK | `.github/workflows/home_startup_auth_r9a6_release_candidate.yml` | Retain as historical debug/test build; never treat it as a Play artifact. |
| Supabase initialization uses `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` Dart defines | `lib/services/supabase/supabase_runtime_config.dart` | Pass public configuration to Play builds; never embed server secrets. |
| Firebase Android config is tied to placeholder package | `android/app/google-services.json` | Re-register the final package in Firebase and update platform config before release. |
| Flutter app version is `1.0.0+1` | `pubspec.yaml` | Choose initial version and monotonically increasing versionCode. |
| Gradle target uses `flutter.targetSdkVersion` | `android/app/build.gradle.kts` | Verify the *resolved* target API is at least 36 in the final Android App Bundle. |
| Android signing secrets are not covered by all usual filename patterns in `.gitignore` | `.gitignore` | Add explicit ignores for keystore and local key properties. |

## Implementation order and gates

### SEC-01A. Immutable branch and evidence
- [x] Verify source checkpoint SHA, frozen branch, repository build files, and signing mechanism.
- [x] Create dedicated SEC-01 branch from the exact checkpoint SHA.
- [ ] Record original state and prepare baseline source/provenance evidence.
- [ ] Require `git merge-base --is-ancestor 156ea074e1f420672490511a01117804dc22ce74 HEAD` in all SEC-01 CI workflows.
- [ ] Prove working branch changes do not touch authentication, content-delivery, Firestore/Supabase rules, or learner-progress components.

**Acceptance A:** frozen SHA unchanged; SEC-01 branch has verified ancestry; change list contains only explicitly approved SEC-01 files.

### SEC-01B. Production package name and Firebase identity
- [ ] Owner selects final unique reverse-domain package ID and checks it is not already reserved in their Play Console.
- [ ] Decide whether historical sideloaded debug installations must be separately uninstallable: changing the package ID creates a different Android app.
- [ ] Update `applicationId` and appropriate Android Kotlin/namespace/component paths while preserving functionality.
- [ ] Register final Android app in Firebase project `csp11-exam-platform`; replace `google-services.json` for final package. Verify any `firebase_options.dart` changes are limited to Android config.
- [ ] Configure Google sign-in certificate SHA-1/SHA-256 for the **upload** certificate and the **Play app-signing** certificate, as appropriate.
- [ ] Run email/password and Google sign-in tests on Play-installed build after internal release.

**Acceptance B:** bundle application ID equals Play Console application ID and Firebase Android registration; sign-in tests pass; package identity fixed for future updates.

### SEC-01C. Protected production signing
- [ ] Generate a **new** Play upload key privately and keep encrypted backups outside the repository. Use Play App Signing for the distribution certificate.
- [ ] Add GitHub Actions secrets: `CSP11_PLAY_KEYSTORE_BASE64`, `CSP11_PLAY_STORE_PASSWORD`, `CSP11_PLAY_KEY_ALIAS`, `CSP11_PLAY_KEY_PASSWORD`; do not check in key bytes or passwords.
- [ ] Make the dedicated Play build fail closed if any signing secret is absent, if the signing alias/certificate is the Android debug identity, or if Gradle would fall back to debug signing.
- [ ] Retain pre-existing test/debug build workflows; place any Play-specific Gradle gating behind an explicit build intent flag if necessary.

**Acceptance C:** missing/invalid signing configuration **fails** the Play build; the AAB is signed by the intended new upload certificate (fingerprint independently verified); debug key is never accepted for store upload.

### SEC-01D. Dependency, secrets and distribution guardrails
- [ ] Add `*.jks`, `*.keystore`, `android/key.properties` (and equivalent private key settings) to Git ignore rules.
- [ ] Use least-privilege CI permissions and GitHub environment protections for signing.
- [ ] Verify no server/service-role secrets or credentials are bundled or disclosed in CI logs.
- [ ] Verify Dart `--dart-define` includes only public Supabase URL and `sb_publishable_...` key; a publishable key is *not* a secret but must never grant unauthorised data access.
- [ ] Keep dependency lockfile unchanged except for explicitly reviewed updates.

**Acceptance D:** secret scan clean; public config present and valid; no server secrets in repository, bundle, symbols, logs, or CI artifacts; existing learner authorization tests unchanged and green.

### SEC-01E. Play-ready Android App Bundle pipeline
- [ ] Configure separate manual release CI: preflight -> analyze/tests -> signed `flutter build appbundle --release` -> bundle validation -> evidence/artifacts.
- [ ] Verify resolved bundle `targetSdkVersion >= 36` (Google Play requirement effective 31 Aug 2026 for standard Android apps).
- [ ] Confirm release versionName/versionCode; increment versionCode for every new Play upload.
- [ ] Validate the package ID, Firebase configuration, launcher name/icon, app initialization, signing fingerprint, bundle integrity, and ABI compatibility.
- [ ] Preserve build provenance (branch, commit, Flutter/Java/Gradle versions, SHA-256, signature fingerprint, checks run) with no secret values.

**Acceptance E:** CI produces a signed, verifiable `.aab` with exact approved identity and target SDK, and explicit audit evidence. CI never auto-publishes to Play.

### SEC-01F. Regression and on-device acceptance
- [ ] Run `flutter analyze` and all existing FR8/FR9/FR10, startup, auth, navigation, question/flashcard delivery regression tests.
- [ ] Install Play internal-test build and verify email sign-in, Google sign-in, verification flow, startup, home, question bank, flashcards, labs, sign-out/sign-in, and error recovery.
- [ ] Test Android 16 (API 36) and at least one supported older Android version; inspect crashes, ANRs and networking.
- [ ] Confirm offline/disconnected protected content still follows existing frozen FR8 policy and the app restores access when backend is available.
- [ ] Confirm no unexpected permissions or tracking are introduced.

**Acceptance F:** all frozen contract tests pass; no protected-content regression; two-device matrix completed; Play Console internal test installation succeeds.

## Required release evidence

- Exact source baseline SHA and current branch/commit SHA
- Changed-file allowlist and `git diff --check`
- Flutter/Android version and API-level evidence
- Final package ID and Firebase Android registration confirmation
- Signing upload-certificate SHA-256 and separate Play app-signing SHA-256 (public fingerprints only)
- CI status, tests, signed AAB SHA-256, release build logs with secret redaction
- Functional smoke test report, Play Console internal release acceptance result

## Explicit blocked items / decisions

1. **Final package ID** has not been approved. Do not choose it automatically or ship using `com.example.exam_platform`.
2. **New upload keystore** has not been created or provided; do not reuse `androiddebugkey` for Play.
3. **Play Console app and Firebase SHA registration** are not yet verified.
4. **Target API** is configured indirectly through Flutter; resolved bundle target must be proven.
5. **Play submission** is out of scope until acceptance checks complete.

## After SEC-01

SEC-02: Firebase App Check + Play Integrity.  
SEC-03: Edge Function authorisation/rate limits and database policy hardening.  
SEC-04: Encrypted local protected-content storage.  
SEC-05: Account deletion and Play privacy/data safety.

## Primary references (as reviewed 02 Nov 2026)

- [Google Play target API policy](https://support.google.com/googleplay/android-developer/answer/11926878)
- [Android app signing / Play App Signing](https://developer.android.com/studio/publish/app-signing)
- [Flutter Android deployment and AAB signing](https://docs.flutter.dev/deployment/android)

SEC-01 is **not** completed merely because this plan exists. Completion requires all six acceptance gates A-F with reproducible evidence.
