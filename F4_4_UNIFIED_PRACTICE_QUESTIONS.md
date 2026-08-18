# CSP11 F4 Part 4: Unified Practice Questions Authoring Hub

## Purpose

Practice Questions inside Study Content Studio is now the primary question authoring and management surface.

The Part 4 input paths are:

1. Manual Create/Edit
2. Complete Question Paste
3. JSON file import

All three paths feed the same `Question` model, the same `StudioQuestionService`, the same `QuestionQualityValidator`, and the same `LocalQuestionRepository` through `QuestionBankService`.

## Context rule

The active Studio context is attached automatically:

- domain
- competency
- subtopic
- topic when available
- content package
- resolved quiz ID

Imported JSON metadata does not replace the active Studio placement context.

## JSON shapes accepted

A JSON file may contain:

- one question object
- an array of question objects
- `{ "questions": [ ... ] }`
- `{ "items": [ ... ] }`
- `{ "data": [ ... ] }`

Each question supports `question` or `stem`, `options`, `correctAnswer` or `bestAnswer`, `explanation`, `reference` or `source`, `tags`, `difficulty`, `cognitiveLevel`, `questionType`, and optional `bestAnswerRationale`.

Imported questions enter as Drafts and are validated before the import action is enabled.

## UI changes

Practice Questions now provides:

- Create Question
- Paste
- Import JSON
- Edit
- Publish
- Delete
- Refresh
- Answer Length Check control
- Question and Published counts
- Five-published minimum quiz readiness

The legacy `Open in Question Bank` action is removed from the Studio question list.

## Important scope boundary

This step does not remove `question_bank_screen.dart` from the project or final navigation. That remains a later cleanup step after the Studio workflow is proven stable.

## Verification on the development machine

Run:

```powershell
flutter test test\services\studio_question_context_test.dart
flutter test test\services\quiz_semantics_test.dart
flutter test test\services\studio_question_service_test.dart
flutter test test\services\studio_question_import_service_test.dart
flutter analyze
```

Expected result: all four focused tests pass and no analyzer errors are introduced. Existing unrelated analyzer findings may remain.
