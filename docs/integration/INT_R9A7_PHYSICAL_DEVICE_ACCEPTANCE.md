# INT-R9A7 Physical Device Release Acceptance

## Status

**AUTOMATION / DEVICE READINESS IN PROGRESS**

Working branch:

`phase-home-startup-integration-auth-hotfix-r9a7`

Frozen parent:

`phase-home-startup-integration-auth-hotfix-r9a6-closed`

Parent SHA:

`12e0bc8b58248c908cc7ed3dc1d4c8d6d9e9c5a4`

## Purpose

INT-R9A7 is the final handset-facing acceptance gate for the Home + Startup integration authorization hotfix chain.

R9A6 proved the integrated release candidate in CI and produced a deterministically signed Android APK. R9A7 now proves that the same release behavior survives installation and use on a real Android device.

This phase must not claim full closure from CI evidence alone. Physical-device observations are required for the user-facing checks that cannot be certified honestly by GitHub Actions or an emulator.

## Acceptance boundaries

### CI can prove

CI must prove:

1. R9A6 frozen ancestry is preserved.
2. Required Supabase public runtime configuration is present.
3. The backed-up Android signing keystore is present.
4. Critical Startup/Auth/Home and FR8/FR9/FR10 regressions remain green.
5. Android `FLAG_SECURE` protection remains present.
6. The release APK builds.
7. The APK contains the expected package ID:
   `com.example.exam_platform`
8. The APK contains the Startup Motion asset.
9. APK Signature Scheme v2 is valid.
10. The APK signer fingerprint exactly matches:
    `97C014CA29254343FE825B8CDB9BFBE1830E8D619FEDAC0F263C4164AA5206BD`
11. The APK, ADB acceptance harness, and readiness evidence are uploaded together.

### A real Android device must prove

The handset acceptance must prove:

1. clean install or same-signature update succeeds;
2. an existing installation can be updated without uninstalling when present;
3. the app cold-launches and remains alive;
4. there is no fatal launch crash in captured logcat;
5. Startup animation renders correctly on physical hardware;
6. real Firebase learner sign-in works;
7. Supabase authorization completes after sign-in;
8. Home renders correctly;
9. Search CSP Content and Continue CSP are usable;
10. protected FR9 question/practice delivery works;
11. protected FR10 StudyContent delivery works;
12. protected access fails closed when connectivity is removed;
13. the learner recovers correctly after connectivity returns;
14. logout and re-login work;
15. screenshot/screen-record blocking behaves as intended;
16. there is no visible release regression.

## Physical-device harness

Use:

`tools/integration/INT_R9A7_DEVICE_ACCEPTANCE.ps1`

Requirements:

- Windows PowerShell 7 or Windows PowerShell 5.1;
- Android platform-tools with `adb` available in PATH;
- one Android device connected by USB;
- USB debugging enabled;
- the computer authorized on the phone;
- the R9A7 acceptance APK downloaded locally.

The script intentionally requires exactly one authorized Android device so evidence cannot accidentally mix multiple devices.

## Recommended execution

From the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\integration\INT_R9A7_DEVICE_ACCEPTANCE.ps1 -ApkPath "C:\PATH\TO\CSP11-INT-R9A7-device-acceptance.apk"
```

If PowerShell 7 is available:

```powershell
pwsh -File .\tools\integration\INT_R9A7_DEVICE_ACCEPTANCE.ps1 -ApkPath "C:\PATH\TO\CSP11-INT-R9A7-device-acceptance.apk"
```

Do not add `-SkipInteractive` for final closure. That switch is only for automated ADB preflight and leaves all physical UI checks pending.

## Evidence generated locally

The harness creates a timestamped folder:

`INT-R9A7-device-acceptance-YYYYMMDD-HHMMSS`

It includes:

- `INT-R9A7-device-acceptance.txt`
- `INT-R9A7-device-acceptance.json`
- `adb-install.txt`
- `launch.txt`
- `app-logcat.txt`
- `activity.txt`
- `package-before.txt` when an earlier installation exists
- `package-after.txt`
- `apksigner.txt` when `apksigner` is available locally

The final evidence line must be:

`FINAL_STATUS=PASS`

for physical acceptance closure.

`AUTOMATED_PASS_MANUAL_PENDING` is not sufficient for phase closure.

## Update-continuity rule

If `com.example.exam_platform` is already installed, the harness uses:

`adb install -r`

This is deliberate. It tests signer continuity and update behavior without removing app data first.

If the update fails because of a signature mismatch, R9A7 fails. Do not uninstall the existing application merely to turn the result green.

## Screenshot-protection rule

The repository already protects the Android activity using:

`WindowManager.LayoutParams.FLAG_SECURE`

R9A7 still requires a physical-device confirmation because static code presence does not prove OEM/device behavior.

Attempt a normal Android screenshot and, where practical, a screen recording while CSP11 is visible. The protected content must not be captured in a usable form.

## Connectivity acceptance

For the connectivity-loss check:

1. remain signed in;
2. open a protected online learner surface successfully;
3. disable Wi-Fi and mobile data or use Airplane mode;
4. attempt protected online navigation again;
5. confirm the app fails closed rather than exposing an unauthorized bypass;
6. restore connectivity;
7. confirm recovery without reinstalling or clearing app data.

The harness does not toggle radios automatically because doing so can vary by Android/OEM permissions and could disrupt the tester's device unexpectedly.

## Closure criteria

INT-R9A7 may be frozen only when all of the following exist:

- green exact-SHA R9A7 readiness workflow;
- signature-verified R9A7 APK artifact;
- physical-device evidence generated from that APK;
- `FINAL_STATUS=PASS`;
- no unresolved fatal launch crash;
- no signer mismatch;
- no authorization bypass;
- no regression requiring a production-code fix.

If a production defect is found, R9A7 remains open and the fix must receive a fresh exact-SHA CI readiness run plus a fresh physical-device acceptance run.

## Planned frozen branch

After complete physical acceptance:

`phase-home-startup-integration-auth-hotfix-r9a7-closed`

The closed branch must point to the exact commit whose APK and physical-device evidence were accepted.
