# CSP11 LEARNER PROGRESS CONTRACT
## FROZEN DECISION

**Status:** FROZEN
**Authority:** CSP11 Exam Platform Learner Progress
**Applies to:** Student learning progress, Progress dashboard aggregation, Topic/Subtopic completion semantics, and future content population.

This standard MUST be read together with:

- `CSP11_FINAL_TOPIC_SUBTOPIC_ARCHITECTURE_FROZEN.md`
- `CSP11_CONTENT_AUTHORING_STANDARD_FROZEN.md`

---

## 1. AUTHORITATIVE LEARNING HIERARCHY

Learner content uses:

`StudyContent.topics → StudyTopic.subtopics → StudySubtopic.blocks`

No retired `MainContentTopic` / `mainContent` layer may participate in progress identity.

---

## 2. SUBTOPIC PROGRESS IS AUTHORITATIVE PERSISTED STATE

The Subtopic is the persisted learner-progress unit.

A Subtopic progress record is identified by its stable canonical `subtopicId` and carries the associated content ID/version metadata.

Supported learner states are:

- Not Started
- In Progress
- Completed

Published Subtopic IDs MUST remain stable.

Opening an already completed Subtopic MUST NOT downgrade it to In Progress.

---

## 3. CONTENT VERSION SAFETY

Dashboard completion for a Subtopic is valid only when the persisted progress record belongs to the same:

- `studyContentId`
- `studyContentVersion`

as the published content currently being aggregated.

Progress from an older or different content version MUST NOT silently complete the current content version.

---

## 4. TOPIC COMPLETION IS DERIVED, NOT SEPARATELY AUTHORITATIVE

A Topic is a parent learning-navigation unit.

A Topic is COMPLETED only when:

1. it contains at least one Subtopic; and
2. every child Subtopic has valid COMPLETED progress for the current content ID/version.

A partially completed Topic is NOT completed.

An empty Topic is NOT completed.

One logical Topic is counted at most once.

Topic completion MUST NOT depend on a composite identity containing one particular child `subtopicId`.

---

## 5. LEGACY TOPIC-PROGRESS STORAGE

`StudentTopicProgress` and `StudentTopicProgressService` may remain temporarily in the repository for compatibility/history, but they are NOT authoritative for Progress-dashboard Topic completion after this contract.

Do not delete or repurpose them casually because other historical features may still share related composite identity patterns.

Their eventual retirement or migration requires a separate scoped audit.

---

## 6. DASHBOARD AGGREGATION

The Progress dashboard derives:

- total Subtopics from published canonical Topic → Subtopic content;
- completed Subtopics from valid persisted Subtopic completion records;
- total Topics from canonical published Topics;
- completed Topics by deriving whether all child Subtopics are complete;
- Domain completion from Subtopic completion;
- overall learner completion from completed Subtopics / total Subtopics.

The dashboard MUST NOT double-count a Topic because it contains multiple Subtopics.

---

## 7. BLOCKS DO NOT CREATE PROGRESS IDENTITIES

Content Blocks are learner-content presentation units.

They do NOT independently create persisted learner progress under this contract.

Any future block-level, scroll-based, automatic, quiz-gated, or time-gated completion requires a separate explicit architecture decision.

---

## 8. QUESTION BANK RELATIONSHIP

Formal questions remain in the existing Question Bank architecture.

Question completion or quiz score does not automatically change Subtopic completion unless a later explicit progress policy introduces such a gate.

---

## 9. NAVIGATION

Previous/Next Subtopic navigation may provide a continuous ordered learning path.

Navigation convenience MUST NOT alter the canonical Topic → Subtopic hierarchy or progress identity.

Any future Topic-aware navigation redesign is a UX decision and does not change the progress contract unless explicitly approved.

---

## 10. REQUIRED REGRESSION CONTRACT

Regression coverage must prove at minimum:

- 0/N Subtopics completed → Topic not completed;
- partial Subtopics completed → Topic not completed;
- N/N Subtopics completed → Topic completed exactly once;
- multiple Topics roll up independently;
- stale content-version progress does not complete current content;
- empty Topic is not completed;
- reopening a completed Subtopic does not downgrade it.

---

## 11. CHANGE CONTROL

This document is FROZEN.

Do not silently change learner-progress semantics.

Any material change requires explicit authorization from Naveed and an updated frozen decision/checksum.

END OF FROZEN CSP11 LEARNER PROGRESS CONTRACT
