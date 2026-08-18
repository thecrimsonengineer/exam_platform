# CSP11 F4.3 Change Log

## Studio Question Service Boundary

This step introduces the Studio-facing service boundary without creating a second question repository.

### Added
- `lib/services/studio/studio_question_service.dart`
- `test/services/studio_question_service_test.dart`

### Updated
- `lib/screens/admin/study_content/study_content_studio_screen.dart`

### Architecture
- Study Content Studio now depends on `StudioQuestionService` rather than directly on `QuestionBankService`.
- `StudioQuestionService` delegates persistence and quality validation to the existing `QuestionBankService`.
- `QuestionBankService` continues to delegate persistence to `LocalQuestionRepository`.
- Quiz ID resolution is centralized at the Studio service boundary.
- Studio question loading can use the shared `StudioQuestionContext`.
- No second repository or duplicate question state was introduced.

### Compatibility
- Existing linked quiz IDs are preserved.
- Existing managed quiz IDs can still be discovered for legacy/imported questions.
- Canonical quiz IDs remain the fallback.
- Existing question visibility is not made stricter by content-package metadata during this step.

### Scope control
This step does not migrate manual authoring UI, Complete Question Paste, JSON import, lifecycle UI, or the legacy Question Bank screen. Those remain in later phases of the 10-part plan.
