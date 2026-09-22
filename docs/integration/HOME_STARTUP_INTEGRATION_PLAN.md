# HOME + STARTUP MOTION INTEGRATION CONTRACT

Status: FROZEN AT INT-R0  
Working branch: `phase-home-startup-integration`

## 1. Frozen source checkpoints

### Home R
Branch: `phase-home-r-closed`  
SHA: `243d9fdf93c55775321468eb17ce85cd3b7c557f`

### Startup Motion
Branch: `phase-startup-motion-closed`  
SHA: `9c1697b1d01c8db85fe535bc77ea6b6aa6f39565`

Both source branches are immutable integration inputs.

No implementation work, rebasing, force-pushing, conflict repair, feature development, or cleanup may be performed directly on either closed branch.

## 2. Integration base

`phase-home-startup-integration` is created directly from the exact Home R closed SHA:

`243d9fdf93c55775321468eb17ce85cd3b7c557f`

Home R is therefore the authoritative starting tree for integration.

Startup Motion is integrated later as the second closed system. INT-R0 does not merge Startup Motion.

## 3. Purpose

Integrate the completed Startup Motion system with the completed Home R learner experience while preserving both closed systems and their validated behavior.

The desired runtime boundary is:

```text
Application bootstrap
    ↓
Startup Motion
    ↓
startup completion / reduced-motion / watchdog / fail-open
    ↓
existing CSP11 application shell
    ↓
existing role/auth routing
    ↓
bottom navigation
    ↓
HOME-R Home
```

## 4. Frozen ownership boundaries

### Startup Motion owns

- startup visual experience
- startup animation/timeline
- startup personalization
- reduced-motion behavior
- watchdog behavior
- fail-open behavior
- startup-to-app handoff

Startup Motion does not own learner planning state, Home content, Today’s Plan, learning position, progress state, quiz completion, or learner navigation after handoff.

### Home R owns

- learner Home information architecture
- Search CSP Content
- Continue CSP
- Today’s Plan projection
- Learn / Practice / Remember Home cards
- Progress Intelligence
- Exam Readiness
- Home-to-plan navigation
- Home completion-state presentation

Home R does not own startup animation or startup lifecycle behavior.

### Existing application architecture owns

- app bootstrap
- authentication
- role routing
- MaterialApp/application root
- theme initialization
- bottom navigation
- shared service initialization

The integration must preserve one application architecture. It must not create an app-inside-an-app design or duplicate navigator shell.

### Planner remains authoritative

The authoritative Daily Study Plan remains owned by the existing planner/repository architecture.

Startup Motion must never:

- create a Daily Study Plan
- modify a Daily Study Plan
- classify plan blocks
- mark plan blocks complete
- alter learner learning position
- trigger quiz completion
- regenerate Home planning state

## 5. Frozen Home R contract

The learner Home remains:

```text
Hero
↓
Search CSP Content
↓
Continue CSP
↓
Today’s Plan
  Learn
  Practice
  Remember
↓
Progress Intelligence
↓
Exam Readiness
```

The integration must not restore:

- Quick Practice on Home
- Train with Intent on Home
- generic Study shortcut on Home
- generic Practice shortcut on Home
- generic Flashcards shortcut on Home
- Home bookmark shortcut

Bookmarked Questions remains under:

`Settings → Learning & Progress`

## 6. Frozen Startup Motion contract

The final Startup Motion checkpoint is treated as a completed subsystem.

The integration must preserve:

- startup timeline
- startup asset contract
- personalization behavior
- reduced-motion mode
- fail-open behavior
- watchdog behavior
- lifecycle hardening
- release-render expectations
- Android/Web/Windows startup asset packaging requirements

The closed Startup Motion branch must not be reopened for conflict repair.

All integration repairs happen only on `phase-home-startup-integration`.

## 7. Known shared integration surfaces

The primary known shared surfaces are:

- `lib/main.dart`
- `pubspec.yaml`

Additional shared surfaces discovered during INT-R1 must be documented before structural merge.

No shared file may be resolved using a blanket “ours” or “theirs” rule when doing so could discard validated behavior from either subsystem.

## 8. Integration strategy

The integration sequence is frozen as:

```text
INT-R0  Freeze Integration Contract
INT-R1  Conflict / Surface Audit
INT-R2  Structural Merge
INT-R3  Bootstrap + App Root Integration
INT-R4  Dependencies + Assets + Platforms
INT-R5  Integration Contract Tests
INT-R6  Home + Startup Dual Regression
INT-R7  Full Repository Validation
INT-R8  Android + Web + Windows Closure
INT-R9  Freeze Integration Checkpoint
```

Do not skip directly from INT-R0 to implementation without the INT-R1 audit.

## 9. Merge policy

The planned structural integration is a real merge of:

`phase-startup-motion-closed`

into:

`phase-home-startup-integration`

This preserves ancestry from both closed systems.

Do not replace that merge with a long cherry-pick sequence unless a later documented technical constraint makes the merge impossible.

Do not merge into:

- `phase-home-r-closed`
- `phase-startup-motion-closed`
- `main`

during this integration phase.

## 10. Conflict-resolution policy

All conflicts are resolved on the integration branch only.

For every architectural conflict:

1. identify behavior owned by Home R
2. identify behavior owned by Startup Motion
3. preserve both when they are compatible
4. preserve the existing application-root architecture
5. avoid duplicate shells, navigators, services, planners, or state stores
6. add or update tests to prove the integrated behavior
7. document any intentionally changed cross-system contract

Never weaken a test merely to make the integration green.

A test may only be changed when its old expectation is demonstrably stale after legitimate integration, and the replacement assertion must describe the new intended contract.

## 11. Prohibited actions

During INT-R0 through INT-R9:

- no force-push to either closed source branch
- no rebase of either closed source branch
- no direct feature development on either closed source branch
- no deletion of either recovery branch
- no planner redesign
- no Startup Motion redesign
- no Home redesign
- no unrelated feature development
- no premature merge to `main`
- no duplicate MaterialApp/application root
- no duplicate learner shell
- no duplicate Home
- no second Daily Study Plan source
- no restoration of removed learner Firestore read paths
- no skipped critical tests to obtain a green gate

## 12. Recovery model

Recovery point A:

`phase-home-r-closed@243d9fdf93c55775321468eb17ce85cd3b7c557f`

Recovery point B:

`phase-startup-motion-closed@9c1697b1d01c8db85fe535bc77ea6b6aa6f39565`

Integration work is disposable until INT-R9 closure.

If the integration becomes structurally unsound, recreate the working integration branch from Recovery point A and repeat the audited merge. Do not repair the closed source branches.

## 13. Final validation target

Before INT-R9 closure, one exact integration SHA must pass:

- frozen integration architecture checks
- Dart formatting
- `flutter analyze`
- all Startup Motion tests
- all HOME-R tests
- planner regressions
- Study Content/navigation regressions
- practice/quiz regressions
- full Flutter test suite
- Startup release-render smoke tests
- Android release build
- Web release build
- Windows release build
- exact-SHA ancestry verification

The exact validated SHA must then be frozen as:

`phase-home-startup-integration-closed`

## 14. INT-R0 closure definition

INT-R0 is complete only when:

1. `phase-home-startup-integration` exists.
2. It originates from exact Home R closed SHA `243d9fdf93c55775321468eb17ce85cd3b7c557f`.
3. This frozen integration contract is committed on that branch.
4. No production Dart behavior is changed.
5. Startup Motion has not yet been merged.
6. Both closed source branches remain unchanged.
7. The exact INT-R0 commit SHA is recorded.
8. A frozen INT-R0 recovery checkpoint is created.
9. INT-R1 begins only from that exact frozen INT-R0 state.
