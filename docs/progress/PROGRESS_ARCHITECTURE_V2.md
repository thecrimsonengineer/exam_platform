# CSP11 Progress Architecture V2

## Goal

Make Progress feel immediate while expanding it into a real learner analytics
workspace.

## Main overview

The main Progress tab is now summary-first. It reads one small UID-scoped
`ProgressAnalyticsSnapshot` and renders:

- overall Subtopic completion
- Domains completed
- Topics completed
- Subtopics completed
- unique questions answered
- question accuracy
- foreground app time for the last 7 days
- active-day count
- study streak
- weekly learning-time line chart
- weekly activity heatmap
- Domain progress bar chart
- question accuracy donut
- completion analytics bars
- Domain analytics table
- seven tappable Domain drill-down cards

No placeholder percentages are generated.

## Domain drill-down

Each Domain opens its own page and loads only that Domain's published content.
The page shows:

- Domain completion
- Topic and Subtopic totals
- questions answered
- question accuracy
- competency analytics table
- expandable Competency → Topic analytics

This prevents the main Progress page from carrying the entire nested hierarchy.

## Performance architecture

1. Session memory snapshot
2. Small SharedPreferences snapshot
3. Local-cache reconciliation in the background when learner activity changed
4. Authoritative Firebase refresh without blanking existing analytics
5. No forced full refresh every time the Progress tab is tapped
6. Published-content, learning-progress and question-progress reads run in
   parallel
7. Question progress is indexed once rather than rescanned for every hierarchy
   node
8. Domain detail pages request one Domain only

## Time spent

`LearningActivityTracker` records learner-shell foreground time into UID-scoped
daily second buckets.

- background time is excluded
- buckets stay local
- tracking starts when V2 is installed
- existing historical time is not invented or backfilled

## Incremental analytics invalidation

Subtopic and question mutations mark the analytics snapshot dirty through
`ProgressAnalyticsEventBus`.

The existing snapshot remains immediately visible. Local reconciliation can
then rebuild the small snapshot without blocking first paint.

## Boundaries

- Firestore published content remains authoritative.
- No Firestore security rules are weakened.
- No analytics data is written to Firestore.
- No progress completion semantics are changed.
- No external chart dependency is introduced.
- Charts use lightweight Flutter rendering.

## V1 contract migration

The previous V1 fast-render source contract expected cache methods to live
directly in `ProgressScreen`. V2 moves that responsibility to
`ProgressAnalyticsScreen`, while `ProgressScreen` becomes a lightweight route
wrapper. The V1 contract test is therefore migrated to the V2 ownership model.
