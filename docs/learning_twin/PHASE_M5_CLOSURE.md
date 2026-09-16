# CSP11 Phase M5 Closure Record

## Status

CLOSED / PASS

Closure tag:
`phase-m5-closed`

## Scope closed

Phase M5 introduced a deterministic adaptive Learning Twin coach driven by
existing learner progress and question-progress information.

Closed adaptive chain:

`ProgressAnalyticsSnapshot`
-> `DeterministicLearningTwinProgressInterpreter`
-> `LearningTwinProgressInsight`
-> `LearningTwinProgressMessageBridge`
-> M3 `LearningTwinMessage`
-> M3 decision service
-> Progress adaptive card
-> fail-closed user action policy
-> host-owned canonical Domain navigation

## M5 checkpoints

M5.0:
- deterministic progress interpreter
- start-learning recommendation
- active-domain continuation
- study/practice imbalance recommendation
- weak-domain remediation
- mastery acknowledgement
- no LLM, randomness or Firebase dependency

M5.1:
- deterministic insight-to-message bridge
- semantic state and trigger mapping
- recommendation target separated from context-matching scope
- M3 remains the final decision authority

M5.2:
- first adaptive learner surface on Progress Analytics
- existing `ProgressAnalyticsSnapshot` reused
- no extra Twin Firebase read
- one dismissible adaptive card
- light/dark/mobile human review passed

M5.3:
- safe user-initiated Domain action routing
- weak-domain `Review domain`
- active-domain `Continue learning`
- unsupported or missing targets fail closed
- Twin integration widget owns no `Navigator`
- Progress host resolves target and owns canonical route navigation
- action consumed for the mounted visit

## Validation evidence

Automated validation across M5 included:
- analyzer passing at the established info-only baseline
- focused M5 interpreter, bridge, presentation and action-routing tests
- full Flutter test suite
- production web build
- exact working-set checks
- `git diff --check`
- rollback-safe recovery validation during installer corrections

Human/device review:
PASS

Confirmed:
- adaptive Progress guidance displays correctly
- M5.3 actions route to the intended learner Domain screen
- light/dark learner routing is preserved
- dismissal behavior remains functional
- Android device validation passed

## Incidental device-validation hotfix

During M5.3 Android verification, an existing administrator preview boundary
was exposed: Admin Home opened the learner shell without activating the local
learner identity required by progress prewarming.

That issue was fixed in a separate narrow commit:
- admin UID is activated only for Student Portal preview
- learner-local identity is cleared when returning
- desktop/mobile admin logout now uses the existing auth provider

This hotfix is not part of the adaptive-coach decision model.

## Frozen M5 boundaries

1. Deterministic coaching only.
2. No LLM requirement.
3. No Twin-owned Firebase reads for adaptive Progress guidance.
4. No automatic navigation.
5. M3 remains the authority for intervention eligibility.
6. No automatic Subtopic guidance.
7. Timed Exam Simulator suppression remains a decision-layer rule.
8. No voice, TTS or audio.
9. No persisted coaching-frequency preference yet.
10. No production-branch merge is performed by M5 closure.

## Deferred adaptive ideas

The roadmap listed next-best Subtopic and domain-readiness style outputs as
possible M5 directions. They are not required for this closed deterministic
slice and remain available for later controlled expansion if needed.

## Next phase

M6 - Practice and Quiz Coach

M6 may add pre-practice, post-practice and result interpretation while
preserving protected-answer boundaries.
