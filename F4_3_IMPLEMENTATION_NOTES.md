# F4.3 Implementation Notes

## Apply
Copy the included `lib/` and `test/` files into the existing CSP11 project and allow overwrite of the listed files.

## Validation
Run:

```powershell
flutter test test\services\studio_question_context_test.dart
flutter test test\services\quiz_semantics_test.dart
flutter test test\services\studio_question_service_test.dart
flutter analyze
```

The expected baseline remains the existing project analyzer findings. Do not clean unrelated lint/warning items during this step.

## Important
Do not remove `question_bank_screen.dart` yet. F4.3 only establishes the service boundary. Legacy UI migration happens after the new Studio authoring path is implemented and tested.
