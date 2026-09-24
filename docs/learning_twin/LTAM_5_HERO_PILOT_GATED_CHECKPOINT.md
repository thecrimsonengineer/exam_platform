# CSP11 LTAM-5 Hero Pilot Gated Checkpoint

**Status:** GATED CHECKPOINT — CODE READY, MOTION ASSET NOT YET ADMITTED  
**Date:** 2026-09-24  
**Repository:** thecrimsonengineer/exam_platform  
**Source baseline:** phase-ml-ltam4-motion-foundation-closed  
**Baseline SHA:** d3b4529501bd1a1e9c5059e133b98bafda885da0  
**Implementation branch:** phase-ml-ltam5-runtime-pilot  
**Validated implementation SHA before this evidence commit:** 39ed4a124f59a700e06cf7e1d96b6353e934f451  
**Validation run:** 35960561293  

## Checkpoint purpose

LTAM-5 has reached the maximum safe implementation point before canonical motion-asset admission and real-device human acceptance.

The existing LearningTwinAvatar remains the canonical public avatar widget. Legacy callers remain static by default. LearningTwinHero now has an additive idle-only motion pilot path, but the production rollout switch remains fail-closed because the reviewed canonical idle Lottie clip is not present.

## Runtime matrix

| Surface | Motion status | Allowed state |
| --- | --- | --- |
| LearningTwinHero | Requested, gated OFF | idle only |
| LearningTwinCard | OFF | none |
| LearningTwinCelebration | OFF | none |
| LearningTwinCompactTip | OFF | none |
| LearningTwinInlineBlock | OFF | none |
| LearningTwinBubble | OFF | none |
| LearningTwinCoachSheet | OFF | none |

## Asset admission gate

The canonical Hero idle asset is:

`assets/learning_twin/motion/twin_idle.json`

At this checkpoint it is intentionally absent.

The rollout contract is:

`heroPilotRequested = true`  
`canonicalIdleClipAdmitted = false`  
`heroMotionEnabled = heroPilotRequested && canonicalIdleClipAdmitted`

A regression test requires actual idle-clip presence to match the admission switch. This prevents a motion asset from silently entering production without the explicit review decision.

No placeholder Lottie file is permitted.

## Hero pilot behavior already implemented

When the production switch is OFF:

`LearningTwinHero -> LearningTwinAvatar -> existing SVG path`

When a controlled test explicitly requests the pilot while the clip is absent:

`LearningTwinHero -> LearningTwinAvatar -> LearningTwinMotionRenderer -> local asset preflight -> static hero SVG fallback`

The title, message, CTA, layout, semantics and navigation remain available throughout fallback.

## Validation evidence

GitHub Actions run 35960561293 completed successfully for the LTAM-5 validation job.

Validated gates include:

- exact ancestry from the frozen LTAM-4 closure
- protected Learning Twin domain/coaching/integration boundaries
- Micro-Learning fact boundary
- startup MicroFact static boundary
- Dart formatting
- targeted analysis
- focused LTAM-5 tests
- full Learning Twin regression
- ML/LTAM integration seam
- startup static regressions
- Web release build
- Android debug APK build
- final diff hygiene

The repository-wide Flutter regression currently contains two unrelated inherited failures. The LTAM-5 workflow proves both failures reproduce on the exact LTAM-4 frozen baseline before allowing the job to pass:

- `test/integration/home_startup/int_r4_dependencies_assets_platform_test.dart`
- `test/integration/home_startup/int_r9a3_supabase_bootstrap_verification_test.dart`

They are not introduced by LTAM-5.

## Compatibility result

Legacy LearningTwinAvatar calls compile unchanged and remain static unless a motion state is explicitly supplied.

LearningTwinCard and LearningTwinCelebration remain static.

Startup MicroFact remains static.

No Learning Twin domain, coaching, decision, progress, auth, Firebase or Supabase behavior is changed by this pilot.

## Accessibility and lifecycle result

Automated coverage verifies:

- meaningful Hero semantics remain available
- reduced-motion requests remain static
- no learner-visible animation error is shown
- missing idle motion fails to static SVG
- Hero CTA remains immediately usable
- compact and wide Hero sizes remain 150 px and 180 px respectively
- background/resume is safe on the gated path
- dark theme preserves content and action
- motion completion is not a business dependency

## Platform status

- Web release build: PASS
- Android debug APK build: PASS
- Windows build: NOT EXECUTED in the Linux CI runner
- Physical-device visual acceptance: BLOCKED pending canonical idle clip admission

## Why LTAM-5 does not advance to Card or Celebration yet

The frozen LTAM-5 contract requires Hero acceptance before enabling Card and requires Hero plus Card acceptance before enabling Celebration.

Because the real idle clip is not yet available, the following cannot honestly be completed:

- real Hero animation visual review
- motion fatigue / long-view review
- real-device animation quality review
- final performance assessment with the production clip
- Hero ACCEPT / TUNE / REJECT_TO_STATIC classification

Therefore Card and Celebration remain static.

## Exact continuation gate

The next LTAM-5 action is asset admission, not Card rollout.

Required sequence:

1. Add the reviewed canonical `twin_idle.json`.
2. Verify manifest and first-frame/fallback identity parity.
3. Perform Android, Web and Windows visual/lifecycle checks where available.
4. Perform reduced-motion and long-view review.
5. Record Hero result as ACCEPT, TUNE or REJECT_TO_STATIC.
6. Only after ACCEPT may LTAM-5 proceed to the controlled LearningTwinCard slice.

## Rollback

Rollback remains presentation-only.

Setting Hero motion OFF immediately returns the Hero to the existing full-body SVG without learner-data migration or backend rollback.

## Checkpoint conclusion

LTAM-5 is not being falsely declared complete.

The backward-compatible Hero runtime pilot infrastructure is validated and ready. Production motion remains intentionally gated until the canonical reviewed idle clip exists and receives the acceptance required by the frozen LTAM-5 contract.
