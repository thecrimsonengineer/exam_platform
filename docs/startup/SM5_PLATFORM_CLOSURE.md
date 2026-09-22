# SM-5 — CSP11 Startup Platform Closure

## Status

SM-5 is complete.

Validated implementation SHA:

`e7eee657e85739883523a503e1a13ebf60ded105`

Startup Motion Validation:

- workflow run: 43
- conclusion: PASS

Startup Motion SM-5 Platform Closure:

- workflow run: 2
- run id: `35731055179`
- conclusion: PASS

## Closure gate

SM-5 uses:

`.github/workflows/startup_motion_platform_closure.yml`

The platform workflow first runs release-render smoke tests. Android, web and Windows release builds are blocked unless rendering smoke passes.

## Rendering verification

`test/startup/startup_release_render_smoke_test.dart`

Verified:

- full startup begins with the CSP11 overlay
- full startup reaches Learn
- full startup reaches Practice
- full startup reaches Decision LAB
- full startup reaches Remember
- full startup exits to the real destination
- balanced mode completes without rendering exceptions
- existing reduced-motion, fail-open, watchdog and lifecycle hardening tests remain green

The smoke test intentionally accepts multiple visible `CSP11` labels during ignition because the brand lockup and beat card can both display the product name at the same time.

## Android release validation

Command:

`flutter build apk --release`

Result:

PASS

The workflow verified:

- `app-release.apk` exists and is non-empty
- the APK contains `assets/flutter_assets/assets/startup/csp11_startup_master.json`
- the packaged asset contains the frozen `CSP11 Startup Master SM-1` identity

Evidence artifact:

`sm5-android-release-evidence`

Artifact size at closure:

445 bytes

### Android signing boundary

`android/app/build.gradle.kts` currently configures the release build to use the debug signing configuration.

Therefore SM-5 proves:

- release-mode Flutter/AOT compilation
- Android packaging
- startup-asset inclusion

SM-5 does not claim:

- Play Store signing readiness
- production keystore readiness
- install/update signature compatibility with a separately signed installed build

The existing same-signature debug-update workflow remains a separate concern.

## Web release validation

Command:

`flutter build web --release`

Result:

PASS

The workflow verified:

- `build/web/main.dart.js` exists
- `build/web/flutter_bootstrap.js` exists
- `build/web/assets/assets/startup/csp11_startup_master.json` exists
- packaged Lottie dimensions are 512 × 512
- packaged Lottie frame rate is 30 fps
- packaged Lottie endpoint is frame 144
- packaged Lottie name remains `CSP11 Startup Master SM-1`

Evidence artifact:

`sm5-web-release-evidence`

Artifact size at closure:

354 bytes

## Windows release validation

Command:

`flutter build windows --release`

Result:

PASS

The workflow verified:

- `exam_platform.exe` exists and is non-empty
- the release data bundle contains the startup Lottie asset
- packaged Lottie dimensions are 512 × 512
- packaged Lottie frame rate is 30 fps
- packaged Lottie endpoint is frame 144
- packaged Lottie identity remains `CSP11 Startup Master SM-1`

Evidence artifact:

`sm5-windows-release-evidence`

Artifact size at closure:

358 bytes

## Normal startup validation

The ordinary startup gate also passed on the same implementation SHA.

It includes:

- startup Dart formatting
- Lottie JSON contract
- all startup tests
- strict startup analysis
- full repository analysis with baseline info-level lint debt non-fatal and warnings/errors fatal

## Heavy workflow trigger policy after closure

The SM-5 three-platform build workflow remains available through `workflow_dispatch`.

Automatic push runs remain enabled for startup/runtime/platform-affecting changes such as:

- startup assets
- startup Dart code
- `lib/main.dart`
- `pubspec.yaml`
- Android project files
- web project files
- Windows project files
- startup tests

Documentation-only changes no longer trigger Android, web and Windows rebuilds.

## Branch isolation

`phase-home-r` remains a separate active workstream.

SM-5 does not:

- merge Home R
- rebase Home R
- cherry-pick Home R feature commits
- resolve future integration conflicts prematurely

The known shared integration surfaces remain primarily:

- `lib/main.dart`
- `pubspec.yaml`

## Integration readiness

Startup Motion is now a closed, independently validated feature system.

Future integration should:

1. start from an explicit integration branch
2. preserve the final Startup Motion checkpoint
3. bring in the completed Home R state deliberately
4. resolve `lib/main.dart` and `pubspec.yaml` by review rather than automatic preference
5. rerun startup tests
6. rerun Home R tests
7. rerun full repository analysis
8. rerun Android/web/Windows platform closure after integration

Do not merge `phase-startup-motion` directly into `phase-home-r` while Home R is still active.
