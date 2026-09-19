# CSP11 Haptic Interaction System

**Phase:** HAP  
**Branch:** `phase-hap-haptics-system`  
**Baseline:** `ui-android-theme-auth-cleanup` at `b67fcc6a721dac36f5e5a645f7a30ccfc9a94070`  
**Backend rule:** Firebase and Supabase are out of scope. Haptics must remain fully local.

## Objective

Introduce a consistent tactile interaction language across CSP11 using Flutter's built-in `HapticFeedback` API. Haptics are an enhancement only. A haptic failure must never block navigation, question submission, LAB decisions, flashcard actions, completion, authentication, or learner state.

## Frozen principles

1. Haptics communicate meaning. They do not fire because a widget rebuilt, data loaded, a timer fired, an animation ran, or background synchronization occurred.
2. Screens do not call `HapticFeedback` directly. All learner haptics go through the CSP11 haptic service.
3. Haptics are user-controllable through a local Settings preference.
4. The preference is stored only in SharedPreferences.
5. Theme choice does not alter haptic behavior.
6. Backend state and haptics remain completely independent.
7. Strong feedback is reserved for important or irreversible learner actions.
8. Unsupported-platform or driver errors fail silently and never break the user action.
9. Automated tests verify requested haptic events. They do not attempt to verify physical vibration.
10. V1 uses ON/OFF only. Intensity levels and custom vibration patterns are deferred.

## HAP0: Interaction vocabulary

Create the semantic event vocabulary:

- `selection`
- `navigation`
- `confirm`
- `success`
- `warning`
- `error`
- `criticalDecision`
- `completion`

Initial Flutter mapping:

| CSP11 event | Flutter haptic | Meaning |
| --- | --- | --- |
| selection | `selectionClick()` | Small choice acknowledgement |
| navigation | `lightImpact()` | User moved to another destination |
| confirm | `mediumImpact()` | Intentional action accepted |
| success | `mediumImpact()` | Positive result |
| warning | `heavyImpact()` | Important negative consequence |
| error | `vibrate()` | User action requires correction |
| criticalDecision | `heavyImpact()` | Irreversible or high-consequence LAB action |
| completion | `mediumImpact()` | Meaningful milestone |

Checkpoint: `HAP0_INTERACTION_LANGUAGE`

## HAP1: Central service and driver

Create:

```text
lib/services/haptics/
    csp11_haptic_event.dart
    csp11_haptic_driver.dart
    csp11_haptic_service.dart
```

Public API:

```dart
Csp11Haptics.selection();
Csp11Haptics.navigation();
Csp11Haptics.confirm();
Csp11Haptics.success();
Csp11Haptics.warning();
Csp11Haptics.error();
Csp11Haptics.criticalDecision();
Csp11Haptics.completion();
Csp11Haptics.trigger(event);
```

The production driver is the only place allowed to invoke Flutter `HapticFeedback` directly.

Checkpoint: `HAP1_SERVICE_GREEN`

## HAP2: Local user preference

Create a local preference service using:

```text
csp11.ui.haptics_enabled.v1
```

Default: **ON**

Settings must expose:

```text
Haptic feedback   ON / OFF
```

Requirements:

- Preference persists locally.
- OFF means semantic haptic requests produce no driver calls.
- ON restores normal tactile behavior.
- No Firebase or Supabase persistence.
- Both current light and dark Settings variants expose the same control until the UI architecture is unified.

Checkpoint: `HAP2_PREFERENCE_GREEN`

## HAP3: Bottom navigation

Apply `navigation` feedback only when the learner changes bottom-navigation destination:

- Home
- Learn
- Practice
- LAB
- Flashcards

Rules:

- Changing destination: one navigation haptic.
- Tapping the already-selected destination: no haptic.
- Programmatic navigation from Home quick actions is not automatically treated as a bottom-navigation tap.

Checkpoint: `HAP3_NAVIGATION_GREEN`

## HAP4: Quiz

Frozen mapping:

- Option selection: `selection`
- Answer confirmation: `confirm`
- Correct result: `success`
- Incorrect result: `warning`
- Submit without required selection: `error`
- Next question: `navigation`
- Quiz completion: `completion`

No haptics for timer ticks, progress animation, question loading, or explanation animation.

## HAP5: Decision LAB

Frozen mapping:

- Option selection: `selection`
- Ordinary accepted confirmation: `confirm`
- Irreversible/high-consequence accepted confirmation: `criticalDecision`
- Safe consequence: `success`
- Neutral consequence: no additional haptic
- Warning consequence: `warning`
- Invalid/rejected decision: `error`
- LAB completion/Story Gate completion: `completion`

The confirmation haptic fires only after the deterministic LAB engine accepts the decision.

## HAP6: Flashcards

Frozen mapping:

- Flip: `selection`
- Know/Got it: `success`
- Needs review: `selection`
- Next: `navigation`
- Deck completion: `completion`
- Drag updates: no haptic
- Swipe commitment threshold: at most one selection haptic

## HAP7: Completion actions

Use `completion` for meaningful milestones such as:

- Subtopic marked complete
- Deck completed
- Quiz completed
- LAB completed
- Explicit study-plan completion

Do not fire on percentage changes, analytics recalculation, score loading, or refresh.

## HAP8: Errors and validation

Use `error` only for learner-caused actions that require correction, such as missing required input or invalid confirmation.

Do not vibrate for silent retries, background network failures, cache refresh failures, remote timeouts, or backend synchronization.

## HAP9: Learning Twin

Frozen mapping:

- Open destination: `navigation`
- Select guidance: `selection`
- Accept recommendation: `confirm`
- Complete suggested action: `success`
- Meaningful milestone: `completion`
- Invalid action: `error`

Avatar pose/expression animation itself must never trigger haptics.

## HAP10: Duplicate protection

Add bounded duplicate protection for rapid repeated callbacks. Strong events may use a longer suppression interval than light selection/navigation events.

## HAP11: Platform safety

Android and iOS are primary targets. Unsupported platforms must degrade gracefully. Driver exceptions are swallowed by the haptic layer and never propagate into learner workflow.

## HAP12: Accessibility and control

Frozen V1 rules:

- Haptics can always be disabled.
- Theme does not affect haptics.
- Reduced motion does not automatically disable haptics.
- Sound preferences are independent.
- V1 does not expose intensity levels.

## HAP13: Testing

Inject or replace the haptic driver in tests.

Required automated checks include:

- Preference ON/OFF behavior
- Preference persistence
- Bottom-navigation destination change emits one `navigation`
- Same destination emits none
- Semantic convenience methods route to the correct event
- Driver failures do not escape
- Later phases add Quiz, LAB, Flashcard, completion, error, and Learning Twin contracts

## HAP14: Integration order

1. Bottom navigation
2. Settings preference
3. Quiz
4. Flashcards
5. Decision LAB
6. Completion actions
7. Error/validation states
8. Learning Twin

## HAP15: Debug diagnostics

Add an optional debug/admin panel allowing physical-device testing of:

- Selection
- Navigation
- Confirm
- Success
- Warning
- Error
- Critical
- Completion

This must not appear in normal learner navigation.

## HAP16: Architecture enforcement

Add a repository test preventing direct `HapticFeedback` usage outside `lib/services/haptics/`.

Desired dependency direction:

```text
Learner UI
   ↓
Csp11Haptics
   ↓
Csp11HapticDriver
   ↓
Flutter HapticFeedback
```

## HAP17: Physical Android validation

Final same-certificate debug APK validation must cover:

- Bottom navigation
- Settings preference OFF/ON
- Quiz
- Flashcards
- LAB
- Completion states
- Learning Twin
- Error states

Physical-device validation evaluates feel and intensity. Automated tests remain the source of truth for event routing.

## Explicit NO-HAPTIC events

The following remain silent:

- Scrolling
- Widget rebuild
- Loading
- Background synchronization
- Firestore/Supabase operations
- Animations
- Progress-bar movement
- Timers
- Passive Learning Twin expression changes
- Hover
- Automatic content refresh

## Implementation runs

### Run 1
HAP0-HAP3:
- Plan freeze
- Event vocabulary
- Driver
- Central service
- SharedPreferences preference
- Settings toggle
- Bottom-navigation integration
- Unit/contract tests

### Run 2
HAP4-HAP8:
- Quiz
- Flashcards
- Decision LAB
- Completion actions
- Error and validation states
- Focused regression tests

### Run 3
HAP9-HAP17:
- Learning Twin
- Duplicate protection
- Platform hardening
- Accessibility checks
- Diagnostics
- Architecture enforcement
- Final regression
- Physical Android APK validation

## Definition of done

Phase HAP is complete only when:

- No learner screen calls `HapticFeedback` directly.
- Local Settings preference works in both themes.
- All frozen interaction mappings are implemented.
- Haptics OFF suppresses all learner haptics.
- Haptic driver failures cannot break app behavior.
- Automated tests are green.
- No Firebase or Supabase dependency was introduced by the haptic system.
- Android physical validation is completed with the same signing certificate workflow.
