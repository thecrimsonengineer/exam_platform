# CSP11 SEC-01C: controlled Android App Bundle and upload-signing gates

**State: CODE PREPARED, CI GUARD TESTS PASS, PRODUCTION AAB NOT BUILT.**  
**Date:** 2026-11-02  
**Business model:** completely free app, no Play Billing.  
**Source freeze:** `phase-post-rel-gov-global-navigation-motion-integration-closed` at `156ea074e1f420672490511a01117804dc22ce74`.  
**Development:** `phase-sec01-play-release-foundation` only.

## What has been implemented

1. `android/app/build.gradle.kts` now rejects `:app:bundleRelease` unless `CSP11_PLAY_RELEASE=true` and refuses the Play intent when the package ID/namespace is not `com.csp11.examplatform`, upload signing variables are missing, the keystore does not exist, or the alias is `androiddebugkey`.
2. Historical local/debug APK release candidate fallback remains for **non-Play builds only**, preserving the original signing behaviour.
3. `tools/security/sec01c_play_release_preflight.py` rejects the old package identity, inconsistent Firebase registration, missing client configuration, absent signing inputs, a debug signing alias, invalid expected SHA-256, and missing Gradle release safeguards. It does not print secrets.
4. `tools/security/test_sec01c_play_release_preflight.py` tests failure modes without a real keystore.
5. `.github/workflows/sec01c_play_appbundle.yml` runs guard tests on branch changes and has a **manual-only** production AAB job. The AAB job requires two explicit user attestation inputs and the `play-release` environment.
6. In the manual AAB job, the key is decoded only to temporary runner storage; `keytool` compares the actual upload certificate with the separately configured SHA-256, rejects an Android Debug subject, Flutter runs analysis and auth/content regression tests, Flutter builds an AAB, `jarsigner` checks it, and a hash-pinned bundletool 1.18.3 validates the package, version code, and API target (36+). Only a signed AAB and non-secret evidence are uploaded as build artifacts.

## Verified CI evidence

- SEC-01B identity workflow: successful at https://github.com/thecrimsonengineer/exam_platform/actions/runs/41418874881
- SEC-01C guard workflow: successful at https://github.com/thecrimsonengineer/exam_platform/actions/runs/41419134078
- The SEC-01C **signed-play-aab** job was **SKIPPED**. Passing guard unit tests does not prove a production signing key, bundle or Play installation works.
- SEC-01 branch ancestry is checked against the original freeze. The frozen branch is untouched.

## Required external setup: do not skip or fabricate

### Gate 1. Google Play package name
Visit https://play.google.com/console and confirm that the account can create/register `com.csp11.examplatform`. A public search is not an authoritative availability test. Keep the application **Free**.

### Gate 2. New Android app in the existing Firebase project
In https://console.firebase.google.com/project/csp11-exam-platform/settings/general register an **additional** Android app using `com.csp11.examplatform`. Keep the legacy Android registration to support development, and retain existing Firebase users. Obtain its own `google-services.json` and Android Firebase app ID. Plan to register signing SHA-1/SHA-256 for both the upload key and Google Play's app-signing certificate.

### Gate 3. Generate a separate upload key PRIVATELY (Windows example)
Use a current JDK, on the owner's trusted computer, outside `C:\\NAVEED\\exam_platform`. Do not use the existing Android debug key.

In PowerShell, first create an access-restricted directory, then run (the command prompts for passwords):

```powershell
$privateDir = Join-Path $env:USERPROFILE 'CSP11-private-signing'
New-Item -ItemType Directory -Force -Path $privateDir | Out-Null

keytool -genkeypair -v -keystore "$privateDir\csp11-play-upload.jks" `
  -storetype PKCS12 -alias csp11-upload -keyalg RSA -keysize 3072 `
  -validity 10000
```

Keep a secure offline backup of the keystore and passwords. Do not paste or attach private key bytes, Base64 keystore content, or passwords in ChatGPT, issues, messages or the repository.

After generating, print **public certificate fingerprints only**:

```powershell
keytool -list -v -keystore "$privateDir\csp11-play-upload.jks" -alias csp11-upload
```

The upload certificate fingerprint is **not** the same as the Play app-signing certificate fingerprint. Register whichever certificates Firebase/Google sign-in requires for the actual installed channel, including Play-generated app signing.

### Gate 4. GitHub Actions configuration
In **GitHub repository Settings → Environments**, configure `play-release` and restrict it to the approved security release branch. Require manual approval if available for the plan/settings. The workflow names an environment but **does not automatically establish its protection rules**.

Add the following encrypted Action secrets (repository or protected environment):
- `CSP11_PLAY_KEYSTORE_BASE64`: Base64 bytes of the separately created keystore
- `CSP11_PLAY_STORE_PASSWORD`
- `CSP11_PLAY_KEY_ALIAS`: e.g., `csp11-upload`
- `CSP11_PLAY_KEY_PASSWORD`
- `SUPABASE_PUBLISHABLE_KEY`: only `sb_publishable_...`, **not** a secret/service-role key

Add one non-secret Actions variable:
- `CSP11_PLAY_UPLOAD_CERT_SHA256`: public SHA-256 fingerprint of the intended upload certificate, 64 hexadecimal digits (colons optional)

The private keystore Base64 is **sensitive** despite being Base64; treat it as private key material. Protect GitHub account access and signing environment.

### Gate 5. Identity migration and source release
Only after Play Console and Firebase registration are confirmed:
- Migrate Gradle `applicationId` and `namespace` together.
- Move Kotlin `MainActivity` to the new namespace directory; preserve its screenshot-protection logic.
- Update Android-specific `google-services.json`, `firebase.json`, and `FirebaseOptions.android` with the new **Firebase Android app ID**. Preserve Web/Windows options.
- Switch SEC-01B CI from `--mode baseline` to `--mode release` only after these files match.
- Run production CI, **then** independently test Play internal-track installation, Google sign-in, email sign-in, content and progress.

## Expected behaviour now

- Historical debug APK workflow: unaffected.
- Release AAB without `CSP11_PLAY_RELEASE=true`: rejected in Gradle.
- Release AAB with the flag but current placeholder package/Firebase identity: rejected.
- Release AAB with missing keystore, signing material, public config or wrong certificate: rejected.
- CI push to SEC-01 branch: guard tests only, never builds/uploads a production bundle.
- Manual signed bundle workflow: must have both confirmations + secrets + release identity; will not publish to Play automatically.

## Known limitations / SEC-01E follow-up

- No private key has been generated or stored, no production AAB created, and no Play listing/package reservation or new Firebase Android registration confirmed by these changes.
- The new signing/Gradle path has not been validated by a full Android Gradle build; guard-unit tests alone cannot prove Kotlin DSL configuration compiles on the release runner.
- Current `flutter.targetSdkVersion` must be resolved by a real AAB. The bundle validation step rejects an API target below 36, as required for standard Android apps from 31 August 2026.
- Initial AAB upload and installation, public privacy policy, full data safety review, account deletion, and advanced app integrity are separate acceptance stages; do not call SEC-01 complete yet.
- On GitHub, manual `workflow_dispatch` availability may require the workflow file to exist on the default branch. Do not merge an incomplete package migration into `main` just to enable a manual run; coordinate a safe CI-admission plan first.

## References

- Google Play target API policy: https://support.google.com/googleplay/android-developer/answer/11926878
- Android signing/Play App Signing: https://developer.android.com/studio/publish/app-signing
- Flutter Android release: https://docs.flutter.dev/deployment/android
- Bundletool docs: https://developer.android.com/tools/bundletool
