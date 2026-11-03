# SEC-01E — CSP 11 Nova first Google Play upload (Windows)

**Status:** Secure pipeline implemented; production AAB has **NOT** been created. The developer must privately generate and configure the upload key.

**App name:** CSP 11 Nova: CSP Exam Prep.  
**Package:** com.csp11.examplatform  
**Firebase:** csp11-exam-platform; Android Firebase app 1:984608502679:android:99d154c5e5f6d083ca0ad2  
**Development branch:** phase-sec01-play-release-foundation  
**Frozen source:** 156ea074e1f420672490511a01117804dc22ce74  
**First Play track:** Internal testing only. Do not submit to production until privacy/account deletion/security acceptance.

## Why two signing stages?

The first uploaded AAB is signed using your **private upload key**. The Play-generated **app-signing key** may only become available after Play App Signing is configured during that release. It is not needed **before** the first upload.

- Stage `first_upload`: all upload-signing, package, OAuth, Flutter, secrets, target API 36, and AAB validation gates apply. **Only** the future Play distribution certificate check is deferred.
- Stage `post_play_signing`: all previous checks plus verify `CSP11_PLAY_APP_SIGNING_SHA1` matches Firebase for this new Android package. Register Play SHA-1/SHA-256 and redownload Google Services configuration after Play generates the certificate.

## A. Safest first build on your Windows computer

1. Open PowerShell 7 (do not run as Administrator). Use the SEC-01 branch:

```powershell
cd C:\NAVEED\exam_platform
git fetch origin
git switch phase-sec01-play-release-foundation
git pull --ff-only origin phase-sec01-play-release-foundation
git status --short
```

The working tree should be clean. Never build for Play from `main` or the frozen checkpoint.

2. Get Android Studio's Java tools. Earlier, PowerShell could not resolve bare `keytool`. The most common path is:

```powershell
$jdkBin = 'C:\Program Files\Android\Android Studio\jbr\bin'
$kt = Join-Path $jdkBin 'keytool.exe'
$js = Join-Path $jdkBin 'jarsigner.exe'
$java = Join-Path $jdkBin 'java.exe'
Test-Path $kt
```

If False, run `flutter doctor -v`, find **Java binary at**, then change `$jdkBin` to that binary's parent directory.

3. Create a **new private upload keystore outside the repository**, once only:

```powershell
$privateDir = Join-Path $env:USERPROFILE 'CSP11-private-signing'
New-Item -ItemType Directory -Force -Path $privateDir | Out-Null
$keystore = Join-Path $privateDir 'csp11-play-upload.jks'
if (Test-Path $keystore) { throw 'Keystore already exists: do not overwrite an established Play upload key.' }
& $kt -genkeypair -v -keystore $keystore -storetype PKCS12 -alias csp11-upload -keyalg RSA -keysize 3072 -validity 10000
```

Record all prompted passwords in a password manager. Back up the private keystore securely. **Never share the keystore, its Base64, or its passwords in ChatGPT, GitHub, or an ordinary message.**

4. Read public upload-certificate SHA-1 and SHA-256 values, and register the upload certificate fingerprints in Firebase for local validation where applicable:

```powershell
& $kt -list -v -keystore $keystore -alias csp11-upload
```

5. Prepare values for a **single PowerShell session**. The Supabase publishable key is on Supabase Dashboard → Project Settings → API Keys. Use only `sb_publishable_...`, **never** the server-side secret key.

```powershell
$env:CSP11_PLAY_RELEASE = 'true'
$env:CSP11_RELEASE_STAGE = 'first_upload'
$env:CSP11_ANDROID_KEYSTORE_PATH = $keystore
$env:CSP11_ANDROID_KEY_ALIAS = 'csp11-upload'
$env:CSP11_ANDROID_KEYSTORE_PASSWORD = (Read-Host 'Upload keystore password' -AsSecureString | ConvertFrom-SecureString -AsPlainText)
$env:CSP11_ANDROID_KEY_PASSWORD = (Read-Host 'Upload key password' -AsSecureString | ConvertFrom-SecureString -AsPlainText)
$env:SUPABASE_URL = 'https://esfycnmfywxczfillioj.supabase.co'
$env:SUPABASE_PUBLISHABLE_KEY = Read-Host 'Supabase sb_publishable_ key'
$env:CSP11_PLAY_UPLOAD_CERT_SHA256 = Read-Host 'Upload-key SHA-256 (from keytool)'
```

6. Verify and build. Keep the PowerShell commands in one session. The preflight uses Python 3 installed locally; if Python is absent, install Python or rely on the CI preflight. **Do not skip signing/bundle certificate verification.**

```powershell
py -3 tools\security\sec01c_play_release_preflight.py
flutter pub get
flutter analyze --no-fatal-infos
flutter build appbundle --release --dart-define="SUPABASE_URL=$env:SUPABASE_URL" --dart-define="SUPABASE_PUBLISHABLE_KEY=$env:SUPABASE_PUBLISHABLE_KEY"
```

7. Verify AAB integrity and signer. The project CI additionally checks bundletool manifest package, version and SDK target.

```powershell
$aab = 'build\app\outputs\bundle\release\app-release.aab'
if (-not (Test-Path $aab)) { throw 'Signed App Bundle not found' }
& $js -verify -strict $aab
& $kt -printcert -jarfile $aab
Get-FileHash -Algorithm SHA256 $aab
```

Compare the AAB signer's SHA-256 with the **upload** key's certificate fingerprint from step 4. They must be the same. It must not be Android Debug.

8. Verify the package and target API from the AAB itself using hash-verified [bundletool](https://github.com/google/bundletool/releases/tag/1.18.3):

```powershell
$bt = Join-Path $env:TEMP 'bundletool-all-1.18.3.jar'
Invoke-WebRequest 'https://github.com/google/bundletool/releases/download/1.18.3/bundletool-all-1.18.3.jar' -OutFile $bt
if ((Get-FileHash -Algorithm SHA256 $bt).Hash.ToLower() -ne 'a099cfa1543f55593bc2ed16a70a7c67fe54b1747bb7301f37fdfd6d91028e29') { throw 'Bundletool checksum mismatch' }
& $java -jar $bt validate --bundle="$aab"
& $java -jar $bt dump manifest --bundle="$aab" --xpath='/manifest/@package'
& $java -jar $bt dump manifest --bundle="$aab" --xpath='/manifest/uses-sdk/@android:targetSdkVersion'
```

Require package `com.csp11.examplatform` and target SDK at least `36`. The Android Gradle file now sets `targetSdk = 36` explicitly. Ensure Flutter and Android Gradle can compile and the final bundle reports 36.

9. After saving and verifying the AAB in a secure location, clean the session's credential variables:

```powershell
'CSP11_PLAY_RELEASE','CSP11_RELEASE_STAGE','CSP11_ANDROID_KEYSTORE_PATH','CSP11_ANDROID_KEY_ALIAS','CSP11_ANDROID_KEYSTORE_PASSWORD','CSP11_ANDROID_KEY_PASSWORD','SUPABASE_URL','SUPABASE_PUBLISHABLE_KEY','CSP11_PLAY_UPLOAD_CERT_SHA256' | ForEach-Object { Remove-Item "Env:$_" -ErrorAction SilentlyContinue }
```

## B. CI workflow alternative

The SEC-01C CI workflow supports a **manual**, environment-restricted, first-upload mode. For the build job, provide:

**GitHub Action secrets** (encrypted):
- `CSP11_PLAY_KEYSTORE_BASE64` (private keystore bytes encoded to Base64; STILL SECRET)
- `CSP11_PLAY_STORE_PASSWORD`
- `CSP11_PLAY_KEY_ALIAS` (`csp11-upload`)
- `CSP11_PLAY_KEY_PASSWORD`
- `SUPABASE_PUBLISHABLE_KEY` (public `sb_publishable_...`)

**GitHub Action variable** (public):
- `CSP11_PLAY_UPLOAD_CERT_SHA256` (public SHA-256 of upload certificate)

Set workflow inputs `confirm_play_registration=true`, `confirm_firebase_registration=true`, `release_stage=first_upload`.

The `CSP11_PLAY_APP_SIGNING_SHA1` variable is **not needed** for first-upload mode; it is required in `post_play_signing` mode.

**Caution:** GitHub requires a manually dispatched workflow file on the repository's **default branch**. Here, the SEC-01C workflow lives only on the isolated SEC-01 working branch. If GitHub doesn't show a **Run workflow** button, do **not** merge an unfinished release into `main` to force it. Use the local method above or request a separately reviewed CI admission path.

The workflow never auto-uploads to Play Console. It produces a signed AAB for review, only after secrets, checks, and protected environment controls are available.

## C. First Play internal-testing upload

In Google Play Console, open **CSP 11 Nova → Testing → Internal testing → Create new release** (actual menu labels may vary).

1. Configure Play App Signing if prompted, preferably letting Google generate the distribution app-signing key.
2. Upload your **upload-key-signed** AAB.
3. Review errors/warnings and keep release in **internal testing**.
4. Once Play app-signing details appear, copy its *App signing key certificate* SHA-1 and SHA-256 and add both to the **new** Firebase Android registration `com.csp11.examplatform`.
5. Redownload `google-services.json` and commit the new Android OAuth mapping on the SEC-01 branch.
6. Set `CSP11_PLAY_APP_SIGNING_SHA1` (public certificate fingerprint) and use `post_play_signing` verification for subsequent builds.
7. Test **Play-installed** Google sign-in, email sign-in, protected content, question bank, flashcards, progress, sign-out/sign-in and recovery on Android 16 and another supported version.

**Not ready for production listing until** Privacy Policy, in-app + external account deletion, Data Safety, permissions, content licensing, icon/trademark compliance, and other Play declarations are addressed.

## Sources
- https://developer.android.com/studio/publish/app-signing
- https://docs.flutter.dev/deployment/android
- https://support.google.com/googleplay/android-developer/answer/11926878
- https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow
