# CSP11 Phase M2.1 - Twin UI Foundation

## Scope

M2.1 starts the Twin UI System without integrating the Twin into production learner flows.

This slice creates reusable presentation-only components that render the frozen M1 canonical assets:

- `LearningTwinAvatar`
- `LearningTwinBubble`
- `LearningTwinCard`
- `LearningTwinCompactTip`
- `LearningTwinHero`

An isolated showcase entry point is included for responsive and light/dark review.

## Preserved boundaries

M2.1 does not add:

- guidance decision logic
- progress interpretation
- Firebase reads or writes
- avatar_maker imports in learner runtime UI
- production navigation integration
- quiz or Exam Simulator behavior changes
- audio, voice, TTS or microphone access

Those responsibilities belong to later controlled phases.

## M2 requirement coverage

### Mobile responsive

Bubble, card and hero components adapt their layout at narrow widths. The compact tip is designed for constrained surfaces.

### Light/dark parity

Components derive colors and typography from `Theme.of(context)` and do not maintain a separate Twin theme state.

### Accessibility

The canonical avatar renderer exposes an image semantic label unless explicitly marked decorative. Interactive controls use standard Material controls and tooltips.

### Reduced motion

M2.1 introduces no animation. Any future motion must explicitly respect reduced-motion preferences before it is approved.

### Navigation safety

M2.1 provides content components only. It does not add overlays, floating navigation or production routes.

### Canonical renderer

All visual states resolve to the bundled M1.5 canonical SVG family. The learner runtime does not require avatar_maker or a network fetch.

## Isolated showcase

Run:

```powershell
flutter run -d edge -t lib\spikes\learning_twin\learning_twin_ui_showcase_main.dart
```

Review at narrow and wide widths and in both light and dark themes before M2 advances further.

## Next decision

After validation and visual review, decide whether M2.2 should add the remaining presentation surfaces such as inline blocks, coach sheets and celebration treatment, or first refine the M2.1 component API.
