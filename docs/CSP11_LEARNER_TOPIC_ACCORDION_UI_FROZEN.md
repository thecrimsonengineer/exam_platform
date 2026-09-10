# CSP11 Learner Topic Accordion UI

Status: FROZEN
Phase: Learner UI Upgrade P1
Scope: Competency learning index only

## Frozen navigation decision

The learner-facing hierarchy is:

**Domain → Competency → Topics + Subtopics accordion → Learning Content**

A separate Topics screen is intentionally not introduced.

The competency learning page displays one premium expandable card per Topic. Selecting a Topic expands its Subtopics in place. Selecting a Subtopic opens the existing dedicated learning-content screen.

## Frozen interaction contract

1. Topic is the primary visual navigation unit on the competency learning page.
2. Subtopics are never shown as one flat competency-wide list.
3. Only one Topic is expanded at a time.
4. The first incomplete Topic opens automatically. If no learner progress exists, Topic 1 opens.
5. A resume target selects its parent Topic before the saved Subtopic is opened.
6. Topic completion is derived from child Subtopics and is never persisted independently.
7. Persisted Subtopic progress remains Not Started / In Progress / Completed.
8. Previous/Next navigation keeps canonical competency-wide Topic → Subtopic order.
9. Formal Question Bank and QuizReference behavior is unchanged.
10. No Firestore schema, content JSON schema, canonical IDs, or frozen Step 7B artifacts are changed.

## Premium presentation contract

Each Topic card shows Topic number, Topic title, Subtopic count, completed/total progress, completion state, animated expansion affordance, and a derived progress bar.

Expanded Subtopics retain their content-block count, objective count, practice-link count, progress status, and direct navigation to StudySubtopicScreen.

The UI remains responsive and reuses the established CSP11 Study theme tokens.
