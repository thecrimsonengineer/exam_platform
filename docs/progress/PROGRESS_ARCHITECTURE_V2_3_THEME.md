# CSP11 Progress Architecture V2.3 Theme Completion

## Problem

The learner shell uses a local Theme wrapper for dark mode. The root
MaterialApp stays light, so pushed routes are not guaranteed to remain dark.
That meant Domain analytics could open with light-mode styling even when the
Progress tab itself was dark.

The shared V2 analytics screen also relied only on inherited theme state, which
made the top CSP11 Learning Analytics hero less deterministic across the
separate light and dark Progress wrappers.

## V2.3 fix

- Light Progress explicitly passes `isDarkMode: false`.
- Dark Progress explicitly passes `isDarkMode: true`.
- `ProgressAnalyticsScreen` applies `AppTheme.lightTheme` or
  `AppTheme.darkTheme` itself.
- The overview background and Learning Analytics hero receive dedicated light
  and dark palettes.
- Domain drill-down carries the same mode through navigation.
- `ProgressDomainDetailScreen` applies the selected AppTheme explicitly.
- Domain hero, scaffold, app bar, tables, cards, charts and expansion panels now
  resolve from the correct theme.
- No progress, analytics, Firebase, caching or tracking semantics are changed.

This is a visual/theme completion patch only.
