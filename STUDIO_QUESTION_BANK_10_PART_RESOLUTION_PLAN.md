# CSP11 Studio Question Bank Integration
## 10-Part Audit Resolution Plan

This plan follows the full ZIP audit and the existing CSP11 Studio Question Bank handover. The objective is to move question authoring into Study Content Studio without creating a second repository or parallel question-management architecture.

### Part 1. Question Context and Quiz-ID Foundation
Status: **RESOLVED IN THIS CHANGESET**

Establish one shared `StudioQuestionContext` and one deterministic canonical quiz-ID generator. Centralize domain, competency, subtopic, topic, content package/version, and quiz context so manual creation, Complete Question Paste, JSON import, and future Studio controllers do not independently rebuild identifiers. Preserve existing linked quiz IDs during this foundation step so existing managed questions are not orphaned.

### Part 2. Repository and Five-Question Semantics
Status: Next

Correct the current publication and quiz semantics. A valid question must be publishable even when it is question 1, 2, 3, or 4. Five published questions make the dedicated subtopic quiz READY/LINKABLE. There is no maximum question count. Remove exact-five assumptions from QuestionBankService, Studio overview metrics, legacy UI wording where relevant, and the student subtopic quiz path.

### Part 3. Studio Question Service Boundary
Status: Planned

Create/refactor a Studio-facing question-management service boundary while retaining `LocalQuestionRepository` as the single source of truth and `QuestionBankService` as the central management layer. Reuse validation, persistence, ID generation, and randomization logic. Do not create a second question repository.

### Part 4. Manual Create and Edit Migration
Status: Planned

Move manual question creation and editing from the legacy Question Bank into the Practice Questions section of Study Content Studio. The selected Studio context must automatically populate all structural identifiers. The legacy screen must not be required for authoring.

### Part 5. Complete Question Paste Migration
Status: Planned

Move Complete Question Paste into Studio. Preserve the current parser and route its output through the same Question model, Studio context, QuestionQualityValidator, draft saving, and publication path. The paste operation must populate stem, four options, BEST answer, explanation, reference, and tags.

### Part 6. Studio JSON Question Import
Status: Planned

Add standalone question JSON import inside Studio using the existing file-selector approach where practical. Imported question content must converge on the same canonical Question model and validation pipeline. Studio context remains authoritative for domain, competency, subtopic, topic, content package/version, and quiz ID.

### Part 7. Validation and Question Lifecycle UI
Status: Planned

Expose the canonical quality validator inside Studio. Add visible Draft, Review, Validated, Published, and appropriate archive handling where required by the finalized question lifecycle. Keep Answer Length Check independently configurable. Disabling it must not disable any other quality rule.

### Part 8. Publication, Counts, Linking, and Randomization
Status: Planned

Make publication quality-gated, preserve correct-answer relationships when options are randomized, display total and published counts, and make the dedicated quiz READY when published count is at least five. Verify quiz linking uses the same canonical quiz ID throughout Studio and the repository.

### Part 9. Legacy Question Bank Isolation and Removal
Status: Planned

After Studio authoring is fully functional and tested, remove the legacy Question Bank from the final Admin Home workflow. Remove Studio's `Open in Question Bank` dependency. Retain only genuinely reusable service/parser logic until it has been safely relocated or confirmed obsolete.

### Part 10. End-to-End Regression and Firebase Readiness
Status: Planned

Run the complete local workflow: create, paste, JSON import, validate, draft, review/validate, publish, refresh, link quiz, consume through student quiz, verify randomization, verify insufficient-pool messaging, and verify no Studio workflow requires the legacy page. Once stable, the finalized local question architecture becomes the basis for the later Firebase Question Bank migration in the A-to-K roadmap.
