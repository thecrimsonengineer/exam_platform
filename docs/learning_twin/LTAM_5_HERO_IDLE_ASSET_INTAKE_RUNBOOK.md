# CSP11 LTAM-5 Hero Idle Asset Intake Runbook

**Status:** INTAKE READY, CANONICAL ASSET STILL REQUIRED
**Date:** 2026-09-24
**Source checkpoint:** `phase-ml-ltam5-hero-asset-admission-blocked`
**Source SHA:** `94e5982055b5f1ea8664f2ab15c9c2ed4f12743f`
**Continuation branch:** `phase-ml-ltam5-hero-asset-intake`

## Purpose

This checkpoint removes manual production-rollout editing from the LTAM-5 Hero idle asset admission path.

It does not create, synthesize or substitute the missing Learning Twin animation.

The real Glaxnimate-derived idle asset is still required.

## Required candidate

The candidate should be supplied as a reviewed Lottie JSON export derived from the approved Learning Twin rig.

Expected production destination:

`assets/learning_twin/motion/twin_idle.json`

The frozen admission contract remains:

- valid Lottie JSON
- 30 fps
- frame 0 through frame 180
- 6.0 seconds
- positive composition bounds
- non-empty layers
- no text layers
- no HTTP or HTTPS references
- no raster or embedded-image assets

## Step 1: dry-run candidate validation

Run:

`dart run tool/learning_twin/ltam5_idle_asset_admission.dart --candidate <candidate-path>`

This performs the frozen contract checks and prints the SHA-256.

It does not change production state.

## Step 2: asset-level human review

Before promotion, confirm that the candidate is the intended Learning Twin idle export and is derived from the approved rig.

This is an asset-level admission review only.

It is not the final Android, Web or Windows runtime acceptance.

## Step 3: promote for the real Hero runtime pilot

Run:

`dart run tool/learning_twin/ltam5_idle_asset_admission.dart --candidate <candidate-path> --apply --reviewed --review-date YYYY-MM-DD`

The guarded apply path:

1. revalidates the Lottie contract
2. calculates SHA-256
3. requires the rollout policy to still be fail-closed
4. writes the canonical `twin_idle.json`
5. freezes the SHA-256 in `LearningTwinMotionRollout`
6. changes only `canonicalIdleClipAdmitted` to true
7. writes LTAM-5 asset-admission evidence
8. leaves Card, Celebration and every other motion surface disabled

## Step 4: exact-SHA CI

After promotion, the existing LTAM-5 exact-SHA workflow must pass:

- formatting
- analysis
- asset admission tests
- Hero pilot tests
- complete Learning Twin regression
- ML/startup boundaries
- repository regression classification
- Web release build
- Android debug APK
- Windows build
- final exact-SHA hygiene

## Step 5: real runtime acceptance

The promoted candidate must then be reviewed on Android, Web and Windows for:

- first-frame identity parity
- blink quality
- breathing restraint
- head drift
- gaze motion
- seamless looping
- scaling
- transparency
- background/resume behavior
- reduced-motion fallback
- repeated mount/unmount
- long-view fatigue
- real motion performance

Final Hero outcome must be exactly one of:

- `ACCEPT`
- `TUNE`
- `REJECT_TO_STATIC`

Only `ACCEPT` permits LTAM-5 to move to the LearningTwinCard pilot.

## Current state

No canonical Glaxnimate rig or `twin_idle.json` is currently available in the repository or the available project files.

Therefore the Hero production motion gate remains OFF.

This is intentional fail-closed behavior.
