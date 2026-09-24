# CSP11 LTAM-5 Hero Asset Admission Gate

**Status:** BLOCKED ON CANONICAL AUTHORING ASSET  
**Date:** 2026-09-24  
**Source checkpoint:** phase-ml-ltam5-hero-pilot-gated  
**Source SHA:** 720f88328bc1985e25f3bc3feea225cea0adae48  
**Working branch:** phase-ml-ltam5-hero-asset-admission

## Finding

The repository contains no canonical `twin_idle.json` and no editable Glaxnimate Learning Twin rig.

The historical `phase-learning-twin-motion-avatar` branch was inspected read-only. It also contains no canonical runtime Lottie clip.

The available Learning Twin identity assets are raster-backed SVG files. They are valid static fallbacks, but they do not satisfy the frozen LTAM-2 authoring contract for the canonical idle animation.

No placeholder, raster-wrapped Lottie, generated substitute, or unrelated animation is admitted.

## Frozen idle candidate contract

A future `assets/learning_twin/motion/twin_idle.json` candidate must satisfy automated admission checks before the rollout switch may be enabled:

- valid Lottie JSON object
- Lottie version metadata present
- 30 fps
- frame 0 through frame 180
- 6.0 second canonical duration
- positive composition bounds
- non-empty animation layers
- no text layers
- no HTTP or HTTPS asset references
- no raster or embedded-image assets
- exact SHA-256 frozen in the rollout policy when admitted

The contract is derived from the already-frozen LTAM-2 idle-motion specification.

## Rollout state

`heroPilotRequested = true`

`canonicalIdleClipAdmitted = false`

`canonicalIdleClipSha256 = null`

Therefore:

`heroMotionEnabled = false`

LearningTwinHero continues to use the existing static full-body SVG in production.

## Why real visual acceptance cannot run yet

Android, Web and Windows can validate the renderer and fallback architecture without the clip, but they cannot provide a meaningful visual verdict on motion that does not exist.

The following remain blocked until the real canonical clip is supplied:

- blink quality
- breathing subtlety
- head drift
- gaze motion
- seamless loop review
- first-frame identity parity
- long-view fatigue
- real motion performance
- final Android/Web/Windows visual parity
- ACCEPT / TUNE / REJECT_TO_STATIC classification

## Exact continuation sequence

1. Supply or commit the editable Glaxnimate rig derived from the approved Learning Twin master.
2. Export the canonical six-second `twin_idle.json`.
3. Run the automated admission contract.
4. Freeze the candidate SHA-256.
5. Change `canonicalIdleClipAdmitted` to true in the same reviewed commit.
6. Run the real Hero pilot.
7. Capture Android, Web and Windows visual/lifecycle evidence.
8. Record Hero as ACCEPT, TUNE or REJECT_TO_STATIC.
9. Proceed to LearningTwinCard only if Hero is ACCEPT.

## Safety conclusion

LTAM-5 remains fail-closed.

The code is ready to admit a real asset, but the repository will not manufacture evidence by treating a static raster wrapper or placeholder animation as the reviewed canonical Learning Twin idle motion.
