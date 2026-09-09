# CSP11 Repository AI / Agent Instructions

This repository contains frozen CSP11 architecture and content-authoring decisions.

For ANY task involving CSP11 learning content, content population, Admin Studio, student learning, learner progress, Question Bank, validation, import, repository persistence, or Topic/Subtopic architecture, read these files FIRST:

1. `CSP11_FINAL_TOPIC_SUBTOPIC_ARCHITECTURE_FROZEN.md`
2. `CSP11_CONTENT_AUTHORING_STANDARD_FROZEN.md`
3. `CSP11_PROGRESS_CONTRACT_FROZEN.md`

Treat all three documents as frozen authority.

## Mandatory rules

- Preserve the canonical hierarchy:
  `StudyContent.topics -> StudyTopic.subtopics -> StudySubtopic.blocks`
- Do not reintroduce `MainContentTopic`, `mainContent`, or an equivalent hidden hierarchy level.
- Respect frozen L23-E4 Step 7B review decisions:
  - ACCEPT = eligible source evidence
  - HOLD = quarantined, not learner content
  - REJECT = excluded from learner content
- Keep learner-facing content easy to read, concept-first, technically accurate, and CSP application-oriented.
- Use the flexible ContentBlock palette defined in the frozen authoring standard. Do not force every Subtopic into the same template.
- Formal Practice Questions remain in the authoritative Question Bank architecture and must retain the normal CSP11 quality gate and lifecycle.
- Learner-visible references normally appear at the end of each Topic while finer internal source provenance is preserved.
- Preserve deterministic Topic and Subtopic IDs.
- Published Subtopic IDs are learner-progress identities and must not be casually changed.
- Do not create block-level progress identity unless a later explicit architectural decision authorizes it.

## Progress safety rule

Before changing learner-progress semantics, inspect the current implementations of:

- `lib/services/student_learning_progress_service.dart`
- `lib/services/student_topic_progress_service.dart`
- `lib/services/student_progress_dashboard_service.dart`
- `lib/screens/progress/progress_screen.dart`
- `lib/screens/courses/csp/study_subtopic_screen.dart`

The canonical learner-progress contract is frozen in `CSP11_PROGRESS_CONTRACT_FROZEN.md`.
Subtopic completion is authoritative persisted state. Topic completion is derived from all child Subtopics and is not separately authoritative. Preserve content ID/version safety when aggregating progress.

## Change control

If a requested change conflicts with either frozen document, STOP and ask Naveed for explicit authorization to unfreeze or revise the relevant rule.

Do not silently reinterpret or weaken a frozen rule.
