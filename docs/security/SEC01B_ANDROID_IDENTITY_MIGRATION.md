# SEC-01B — Android package ID reservation and Firebase identity migration

**Registered Android package:** `com.csp11.examplatform`  
**Decision:** REGISTERED IN PLAY (per developer confirmation) + FIREBASE CONFIG RECEIVED; **GOOGLE SIGN-IN SHA / PLAY RELEASE STILL PENDING**  
**Working branch:** `phase-sec01-play-release-foundation`  
**Frozen baseline:** `phase-post-rel-gov-global-navigation-motion-integration-closed@156ea074e1f420672490511a01117804dc22ce74`  
**Business model:** Completely free, no billing or premium entitlements.

## 2026-11-02 refreshed Android OAuth certificate evidence

- User provided a refreshed `google-services.json` for `com.csp11.examplatform`; it now includes an Android OAuth `client_type=1` for the Nova package with SHA-1 certificate hash `b4a0b1b13b673177e072c4bacd01e7614c60e41f`.
- Refreshed file was committed to the isolated SEC-01 development branch; the legacy Android client and the existing Firebase project were retained.
- The hash is **also present for the legacy app**. This verifies an already-known signing certificate was registered for Nova; do not assume it is Google Play's **app-signing** certificate or the eventual upload certificate.
- The Google Services JSON includes **SHA-1**, not SHA-256 fingerprint fields. Confirm SHA-256 registration separately in Firebase settings.
- Updated SEC-01B CI checks to require an Android OAuth SHA-1 for Nova. Existing Android build/regression tests remain required.
- Strengthened SEC-01C signed Play App Bundle preflight: a distinct expected Play app-signing SHA-1 (from GitHub Actions variable `CSP11_PLAY_APP_SIGNING_SHA1`) must match an Android OAuth entry in the Nova Firebase client. An ordinary debug certificate can no longer satisfy this separate production gate by itself.
- To complete signing: in **Google Play Console → App integrity**, obtain the **App signing key certificate** SHA-1 and SHA-256 once available. Add both under the **new** Firebase Android app `com.csp11.examplatform`; redownload `google-services.json`, commit it, set `CSP11_PLAY_APP_SIGNING_SHA1` to the exact public SHA-1 in GitHub Actions variable settings and test Play-installed Google sign-in.
- Keep the Play upload-key certificate distinct and private. SHA fingerprints are public; keystores, store passwords, and signing private keys are not.
- **SEC-01B static registration is complete, but full Google sign-in acceptance is incomplete until signed test-device verification.**

## 2026-11-02 actual registration and migration evidence

- **Play Console:** developer confirmed package `com.csp11.examplatform` registered.
- **Firebase:** downloaded `google-services.json` from the existing `csp11-exam-platform` project, with new Android `mobilesdk_app_id` `1:984608502679:android:99d154c5e5f6d083ca0ad2`. The same file retains the legacy Android client `com.example.exam_platform`.
- **SEC-01 branch migrated:** Gradle namespace/applicationId, Kotlin activity package/path, `android/app/google-services.json`, `firebase.json`, and `FirebaseOptions.android` now reference the registered Android app. Flutter Web/Windows configuration, existing Firebase users and Supabase protected-content services remain unchanged.
- **CI checks:** `python tools/security/sec01b_android_identity.py --mode registered` passed on GitHub Actions run [41424752853](https://github.com/thecrimsonengineer/exam_platform/actions/runs/41424752853). The separate signed Play AAB job remains skipped at [41424760821](https://github.com/thecrimsonengineer/exam_platform/actions/runs/41424760821).
- **Google sign-in SHA remains pending:** new Android client has a web OAuth client, but **no Android OAuth client certificate hash** yet. Add production upload and Play app-signing SHA-1/SHA-256 fingerprints in Firebase, redownload `google-services.json`, and commit it before switching the production gate to `--mode release`.
- **Historical text below describes the initial migration plan**, not outstanding source changes. The actual current state is recorded here.

## 1. Evidence and availability status (02 Nov 2026)

- Package ID matches lowercase reverse-domain identifier syntax.
- Public Google Play search found no exact matching listing, but this is not proof the ID is unclaimed; reserved or unlisted packages may not be indexed.
- **Only the developer's Play Console can confirm package-name eligibility and register it to their account.** Registration has not been performed by this work.
- Current project uses `com.example.exam_platform`, associated with `csp11-exam-platform` Firebase project.
- Existing Google sign-in is configured for the old Android package/signing certificates. The current configuration must not be overwritten until the new Firebase Android app is registered and its signing SHA identities are known.
- No Play Console connector is currently available, and no Firebase account mutation was performed.

## 2. Exact dependencies that must migrate together

| Existing source | Identity-dependent value | Migration |
| --- | --- | --- |
| `android/app/build.gradle.kts` | `applicationId` and `namespace`: `com.example.exam_platform` | Both become `com.csp11.examplatform`; do NOT change signing logic until SEC-01C |
| `android/app/src/main/kotlin/com/example/exam_platform/MainActivity.kt` | Kotlin package and directory | Move to `.../com/csp11/examplatform/MainActivity.kt`; preserve screenshot-protection logic |
| `android/app/src/main/AndroidManifest.xml` | Relative `.MainActivity` | Keep relative activity, verify it resolves to new namespace; do not remove flags/metadata |
| `android/app/google-services.json` | Android client package and new `mobilesdk_app_id` | Obtain **fresh config** for registered new Android app in same Firebase project |
| `lib/firebase_options.dart` | `FirebaseOptions.android.appId` and other Android-specific options | Regenerate Android configuration; do NOT overwrite web/windows entries |
| `firebase.json` | FlutterFire `android.default.appId` and Dart Android appId mapping | Update to **same new Android Firebase appId** |
| Google OAuth client registration | Android package + signing SHA-1 | Add new upload-key SHA-1 and later Play app signing SHA-1; keep legacy registrations for development builds |

**Important:** `FirebaseOptions.android.appId` is a Firebase SDK application identifier (e.g. `1:...:android:...`). It is **not** the Android package name. Do not copy `com.csp11.examplatform` into that field.

## 3. Two external registration gates

### Gate B1. Reserve/check in Play Console
1. Sign in: https://play.google.com/console
2. Select **Create app**, choose app, choose **Free**, specify `com.csp11.examplatform` in the package-name field.
3. Review package name availability/registration prompts. Confirm Google Play links the name to *your* developer account.
4. Record confirmation (screenshot or non-sensitive identifier). Do **not** upload a production build until SEC-01C/E.
5. If the package name is unavailable or Google requests ownership proof you cannot supply, stop. Do not rename the code to an unconfirmed replacement.

### Gate B2. Register Android app in Firebase
1. Open https://console.firebase.google.com/project/csp11-exam-platform/settings/general
2. Under **Your apps**, add an **Android** app with package `com.csp11.examplatform` to the **existing** `csp11-exam-platform` project.
3. Record the new Android Firebase `mobilesdk_app_id` (public identifier) and download its updated `google-services.json`.
4. Generate a distinct production Play upload key during SEC-01C, privately; register its SHA-1/SHA-256 in Firebase.
5. When Google Play App Signing creates the distribution-signing certificate, register its SHA-1/SHA-256 in Firebase as well. The download's Google OAuth client section must include a web `client_type=3` and new Android certificate registration.
6. Keep the old Android registration intact until old sideloaded testing can be retired.

**Never** commit/upload private key files or passwords. A `google-services.json` config is generally public app configuration, but verify it is obtained from the correct project and does not contain unexpected secrets.

## 4. Controlled source migration (only after B1 + B2)

- Checkout `phase-sec01-play-release-foundation`. Verify frozen SHA remains `156ea074e1f420672490511a01117804dc22ce74`.
- Change the package ID and namespace together, move Kotlin `MainActivity.kt` without changing logic, keep `.MainActivity` in manifest.
- Replace Android's Google Services config and update FlutterFire Android IDs in `lib/firebase_options.dart` and `firebase.json`. Preserve all existing non-Android entries.
- Run `python tools/security/sec01b_android_identity.py --mode release`, and switch the SEC-01B CI identity preflight from `--mode baseline` to `--mode release`. Until external gates pass, it intentionally remains `--mode baseline`.
- Run Flutter analyzer and existing FR8/FR9/FR10, login, Google sign-in, protected content, and startup/navigation regression suites.
- Use the **new** Play upload key and real Play internal-test delivery for final Google sign-in validation; Android sideload sign-in alone does not test the Play distribution certificate.

## 5. Local-data continuity and regression

- A different Android application ID is treated as a different app. It does not auto-upgrade or inherit the locally persisted SharedPreferences learning data from `com.example.exam_platform`.
- The same Firebase project and users can be retained so the user can authenticate with existing credentials, but local progress/history does not automatically migrate between packages.
- Do **not** uninstall the existing debug app until local-data continuity requirements are decided. If migration is required, design and test a safe export/import flow in a separately reviewed task.
- Existing Windows/Web builds must remain unchanged by Android-only identity migration.

## 6. SEC-01B acceptance matrix

| Acceptance test | Status now | Must be true before SEC-01B closure |
| --- | --- | --- |
| Proposed ID syntax | PASS | valid candidate |
| Exact public Play listing check | No match located (not definitive) | no ownership conflict |
| Play Console reserved by owner | PENDING | confirmed under developer account |
| Firebase Android app with final ID | PENDING | registered in existing Firebase project |
| Production/upload SHA and Play certificate registration | PENDING | authorised Google sign-in configurations registered |
| New Gradle app ID/namespace and Kotlin path | NOT CHANGED | exact match to reserved Play ID |
| `google-services.json`, `firebase_options.dart`, `firebase.json` | NOT CHANGED | consistent with new Firebase Android app ID |
| Read-only automated identity preflight | COMMITTED | `--mode release` passes in CI |
| Baseline existing app unaffected | VERIFIED BY DIFF (not device-tested) | frozen source unchanged; existing sign-in tested |
| Play-installed Google sign-in and email-password | NOT TESTED | both work; backend FR8 auth and content delivery work |

**Implementation is intentionally partial until account-linked Play/Firebase registration is verified.** Do not mark SEC-01B closed based only on a successful static check.

## Official references

- https://support.google.com/googleplay/android-developer/answer/9859152
- https://support.google.com/googleplay/android-developer/answer/16984799
- https://firebase.google.com/docs/android/setup
- https://firebase.google.com/docs/auth/android/google-signin
- https://developer.android.com/build/configure-app-module
- https://docs.flutter.dev/deployment/android
