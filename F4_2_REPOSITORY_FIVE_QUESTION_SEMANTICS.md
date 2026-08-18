# CSP11 F4 Part 2 Changeset

## Repository + Five-Question Semantics

This changeset implements Part 2 of the Studio Question Bank Integration resolution plan.

### Changes
- `QuestionBankService.publish()` no longer requires five questions before publishing an individual valid question.
- Legacy publish callers were updated.
- Dedicated subtopic quizzes now require at least five published questions, with no maximum.
- `QuizService.hasMinimumPublishedQuestions()` centralizes the readiness rule.
- Studio Practice Question metrics show actual totals instead of `X / 5`.
- Studio quiz readiness and overview readiness use `publishedCount >= 5`.
- Added a focused semantics test.

### Intended behaviour
- 1 to 4 published questions: publication allowed; quiz not ready.
- 5 published questions: quiz ready.
- 6+ published questions: allowed; quiz remains ready.

### Validation
```powershell
flutter test test\services\quiz_semantics_test.dart
flutter test test\services\studio_question_context_test.dart
flutter analyze
```

Part 1 context foundation is carried forward in this changeset.
