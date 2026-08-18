# CSP11 Studio Question Bank Integration
## F4.1 Step 1 Resolution: Question Context and Quiz-ID Foundation

This change set establishes the first implementation foundation identified by the full ZIP audit.

### Changes

1. Added `lib/models/studio_question_context.dart`.
   - Centralizes domain, competency, subtopic, topic, content package, content version, and quiz ID context.
   - Provides one deterministic `canonicalQuizId()` generator.
   - Preserves an existing linked quiz ID when one is already attached to the selected subtopic.

2. Updated Study Content Studio to use `StudioQuestionContext` for its canonical quiz-ID fallback.
   - Existing managed-question discovery remains intact for this step so current data is not silently orphaned.

3. Updated the legacy Question Bank to use the same canonical quiz-ID generator.
   - Existing authoring behaviour is otherwise unchanged.

4. Added a focused unit test for canonical quiz-ID generation.

### Deliberately NOT changed in Step 1

- No question-authoring UI migration yet.
- No legacy Question Bank removal yet.
- No five-question publication rule change yet.
- No JSON question import yet.
- No lifecycle redesign yet.
- No repository duplication.
- No Firebase changes.

Those items belong to later steps of the 10-part resolution plan.
