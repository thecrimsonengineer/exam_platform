# CSP11 F4 Step 1 Changeset

This ZIP contains the source files changed or added for Part 1 of the 10-part Studio Question Bank Integration resolution plan.

## Apply

Copy the files into the matching paths in the CSP11 project, preserving the directory structure.

## Files

- `lib/models/studio_question_context.dart` - new shared Studio question context and canonical quiz-ID generator.
- `lib/screens/admin/study_content/study_content_studio_screen.dart` - Studio uses the shared canonical quiz-ID foundation.
- `lib/screens/admin/question_bank_screen.dart` - legacy authoring code uses the same canonical quiz-ID generator, reducing future migration drift.
- `test/services/studio_question_context_test.dart` - focused tests for canonical quiz-ID generation.
- `STUDIO_QUESTION_BANK_10_PART_RESOLUTION_PLAN.md` - full 10-part resolution plan.
- `F4_1_STEP1_FOUNDATION_CHANGELOG.md` - exact scope of Part 1.

## Important

This is intentionally a small foundation changeset. It does not yet migrate the authoring UI, change the five-question publication semantics, add JSON question import, remove the legacy Question Bank, or modify Firebase architecture.

The full project ZIP was not reproduced here because the supplied project archive contains large generated/tool directories. This ZIP contains only the files required for Part 1.
