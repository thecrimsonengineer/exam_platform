# CSP11 Phase I.1 Change Set

Source baseline: current uploaded exam_platform ZIP.

## Finding
`StudyContentLoader` was still reading `LocalStudyContentRepository` for all student content operations. This violated the Phase I target of Firebase-backed published-content delivery.

## Changes
1. Added `CloudPublishedContentRepository` as the student-facing published-content boundary.
2. Changed `StudyContentLoader` to use that Firebase-backed repository by default.
3. Preserved the existing public loader API and all existing `const StudyContentLoader()` call sites.
4. Added dependency injection to `StudyContentLoader` for deterministic testing.
5. Added Firebase/FakeFirebaseFirestore tests covering published-only loading, latest published version selection, competency loading, and archived-content rejection.

## No changes
No Phase J authentication/roles work was introduced.
No offline caching/synchronization was introduced. That remains Phase K.
No student UI rewrite was introduced.
No local repository deletion was introduced. Local content remains available for migration/cache work, but is no longer the production source through StudyContentLoader.

## Required validation on the Git working copy
Run:

flutter test test/services/study_content_loader_test.dart --reporter expanded
flutter test
flutter analyze
git diff --check

Then inspect:

git diff --stat
git status

Commit only after all validation passes.
