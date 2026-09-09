# CSP11 FINAL TOPIC → SUBTOPIC ARCHITECTURE
## FROZEN ARCHITECTURAL DECISION
## Effective: 2026-09-07

STATUS: FROZEN
AUTHORITY: CSP11 EXAM PLATFORM ARCHITECTURE
MIGRATION OF CURRENT POPULATED CONTENT: NO
LEGACY COMPATIBILITY FOR MAINCONTENTTOPIC: NO

---

## 1. FINAL ARCHITECTURE

The CSP11 learning-content hierarchy is permanently defined as:

Domain
└── Competency
    └── Content Package
        └── Content Version
            └── Topic
                └── Subtopic
                    ├── Content Blocks
                    └── Practice Questions

Learner-facing navigation is:

Domain
→ Competency
→ Topic
→ Subtopic
→ Learning Content

Practice Questions are associated with the appropriate Subtopic and may
also retain their existing CSP11 repository metadata.

---

## 2. CANONICAL MODEL

The final structural model is:

StudyContent
└── StudyTopic[]
    └── StudySubtopic[]
        └── ContentBlock[]

The platform MUST introduce an explicit StudyTopic model.

StudyTopic is the parent learning-navigation unit.

StudySubtopic is the child learning-navigation unit.

ContentBlock represents the actual learning material inside a Subtopic.

Practice Questions remain managed by the existing Question Bank architecture.

---

## 3. MAINCONTENTTOPIC IS COMPLETELY REMOVED

The following legacy concept is permanently retired:

MainContentTopic

The following legacy field is permanently retired:

mainContent

There MUST NOT be:

- a MainContentTopic compatibility class
- a mainContent compatibility field
- a MainContentTopic adapter
- a MainContentTopic migration layer
- a MainContentTopic fallback parser
- a MainContentTopic repository branch
- a MainContentTopic UI
- a MainContentTopic renderer
- a MainContentTopic editor
- a MainContentTopic validation path
- a MainContentTopic test dependency

No new CSP11 code may introduce these concepts.

---

## 4. CURRENT POPULATED CONTENT IS DISPOSABLE

The currently populated legacy content using:

StudySubtopic
→ MainContentTopic
→ ContentBlock

is NOT authoritative and MUST NOT be migrated.

No data migration is required.

No automatic transformation is required.

No legacy content preservation layer is required.

The new Topic/Subtopic structure starts clean.

Existing disposable development content may therefore be deleted or replaced
as part of the implementation.

---

## 5. TOPIC DEFINITION

A Topic is an explicit learning-navigation unit within a CSP11 Competency.

A Topic is NOT:

- a source-book chapter
- a PDF chapter
- a source document heading copied automatically
- an old MainContentTopic
- a legacy Main Content item

Topics will be created from controlled CSP11 content analysis and accepted
source evidence.

Topics must use stable IDs.

Recommended structure:

topic_<controlled_identifier>

or another implementation-defined stable identifier.

The exact ID generation mechanism must be deterministic.

---

## 6. SUBTOPIC DEFINITION

A Subtopic belongs to exactly one Topic.

A Subtopic is the next learner-facing level below Topic.

The learner journey is therefore:

Competency
→ Topic
→ Subtopic
→ Learning Content

Subtopics contain the learning material through ContentBlocks and may be
associated with Practice Questions.

---

## 7. CONTENT BLOCKS

The existing flexible ContentBlock architecture should be retained unless
a direct dependency on the retired MainContentTopic architecture requires
adaptation.

Supported content block types may continue to include:

text
heading
image
table
formula
example
caseStudy
reference
warning
examTip
remember
checklist
quote

ContentBlocks belong to Subtopics.

They do NOT belong to MainContentTopic.

---

## 8. PRACTICE QUESTIONS

The existing CSP11 Question Bank architecture remains authoritative.

Questions continue to use:

- exactly 4 answer options
- exactly 1 BEST/correct answer
- existing validation
- existing H0.3 quality gate
- existing QuestionBankService
- existing publication lifecycle
- existing question metadata

Plausible Alternative remains permanently excluded.

Questions should be mapped to the appropriate CSP11 Subtopic and may retain
their existing Topic, Competency, Domain, Content Package, difficulty,
cognitive level, question type, status, version, tags, and reference metadata.

The Topic/Subtopic architecture MUST NOT weaken or replace the existing
Question Bank architecture.

---

## 9. CONTENT PACKAGE AND CONTENT VERSION

The existing repository concept remains:

Competency
→ Content Package
→ Content Version

Lifecycle remains:

Draft
→ Review
→ Validated
→ Published
→ Archived

Lifecycle applies to Content Package/Content Version.

Lifecycle does NOT apply to Topic or Subtopic as independent hierarchy
nodes.

---

## 10. CANONICAL IDENTITIES

All new CSP11 content MUST use canonical competency IDs.

Required pattern:

d01_c01
d01_c02
...
d07_c01
d07_c02
...

Legacy competency identifiers such as:

domain_07_01
domain_01_01

MUST NOT be used for new content.

Existing compatibility infrastructure such as the
CanonicalContentIdentityMapper may remain temporarily where required for
existing system compatibility, but it MUST NOT be used as justification
for retaining the old Topic/MainContent architecture.

---

## 11. ADMIN STUDIO

Study Content Studio becomes the authoring environment for:

Topic
→ Subtopic
→ Content Blocks
→ Practice Questions

The existing Main Content UI is retired.

The following concepts are therefore retired from the final Studio workflow:

- Main Content
- Main Content Topic
- MainContentTopic editor
- MainContentTopic structure card
- MainContentTopic renderer

The Studio must provide direct authoring of:

Topic
→ Subtopic
→ Content Blocks

Practice Questions remain inside the Studio Question Bank workflow.

---

## 12. STUDENT PLATFORM

The final learner navigation MUST be:

Domain
→ Competency
→ Topic
→ Subtopic
→ Learning Content

The current behaviour where Subtopics are displayed as "Topics" MUST be
removed.

The student platform MUST NOT expose:

- Main Content
- Main Content Topic
- legacy MainContentTopic terminology
- a hidden compatibility navigation level

Topic and Subtopic must be visible as their actual architectural levels.

---

## 13. IMPORT AND SERIALIZATION

New JSON content must represent the final hierarchy directly.

Conceptually:

{
  "id": "...",
  "domainId": "d01",
  "competencyId": "d01_c01",
  "topics": [
    {
      "id": "...",
      "title": "...",
      "subtopics": [
        {
          "id": "...",
          "title": "...",
          "blocks": []
        }
      ]
    }
  ]
}

The exact production schema may be refined during implementation, but the
architectural hierarchy MUST remain:

topics
→ subtopics
→ blocks

The old:

subtopics
→ mainContent
→ blocks

schema is retired.

---

## 14. VALIDATION

Content validation must validate:

Content Version
→ Topics
→ Subtopics
→ Content Blocks
→ Practice Questions

Validation MUST NOT depend on MainContentTopic.

Validation MUST NOT silently convert MainContentTopic into StudyTopic.

Malformed legacy structures must not be silently accepted as current
architecture.

---

## 15. REPOSITORY

The repository must store the final Topic/Subtopic hierarchy directly.

Firestore collection:

contentVersions

remains the content repository mechanism unless a later frozen architectural
decision changes it.

Draft and Published repository behaviour remains intact.

The new hierarchy must work with:

Draft
Review
Validated
Published
Archived

No separate legacy repository is required.

---

## 16. SOURCE PIPELINE

The frozen CSP11 source-to-domain pipeline remains authoritative:

PDF
→ Source Index
→ CSP11 Mapping
→ Human Review
→ Extraction
→ Content
→ Questions
→ Quality Gate
→ Repository

The L23-E4 Step 7B Human Review dataset remains frozen and MUST NOT be
modified, regenerated, merged into, or overwritten.

Step 7B decisions are controlled input for downstream content development.

They are NOT themselves Topics or Subtopics.

---

## 17. L23-E4 STEP 7B PROTECTION

The following files remain authoritative and frozen:

C:\NAVEED\L23E4_STEP7B_MASTER_COMPLETED_HUMAN_REVIEW_DATASET.json

C:\NAVEED\L23E4_STEP7B_MASTER_COMPLETED_HUMAN_REVIEW_DATASET.csv

C:\NAVEED\L23E4_STEP7B_VALIDATION_AUDIT.txt

They MUST NOT be modified by the Topic/Subtopic implementation.

Final Step 7B state:

272 mappings reviewed
188 ACCEPT
40 REJECT
44 HOLD
0 BLANK
7 non-blocking warnings
0 failures

---

## 18. COMPLETE REMOVAL REQUIREMENT

Implementation must perform a complete dependency removal of:

MainContentTopic
mainContent
MainContentEditorPanel
MainContentStructureCard
MainContentTopicRenderer

and any other code whose sole purpose is supporting the retired architecture.

All references must be identified before deletion.

The implementation must update:

- models
- serializers
- importers
- validators
- repository services
- Admin Studio
- student navigation
- renderers
- editors
- preview
- tests
- fixtures
- documentation
- sample JSON
- content indexes

No orphaned references may remain.

---

## 19. NO MIGRATION

This is an explicit architectural decision:

NO LEGACY DATA MIGRATION.

The current populated Topic/Subtopic content is disposable.

The new implementation starts with the new canonical structure.

Do NOT build:

- migration scripts
- conversion scripts
- legacy import bridges
- compatibility JSON readers
- dual-schema repository support

unless Naveed explicitly unfreezes this decision.

---

## 20. IMPLEMENTATION ORDER

Implementation must follow this controlled sequence:

PHASE 1
Dependency scan of all MainContentTopic/mainContent references.

PHASE 2
Create StudyTopic model.

PHASE 3
Redesign StudyContent/StudyTopic/StudySubtopic relationships.

PHASE 4
Remove MainContentTopic and mainContent from models.

PHASE 5
Update JSON serialization/deserialization.

PHASE 6
Update validation.

PHASE 7
Update repository persistence.

PHASE 8
Rebuild Admin Studio hierarchy:

Topic
→ Subtopic
→ Content Blocks

PHASE 9
Rebuild student navigation:

Competency
→ Topic
→ Subtopic
→ Learning Content

PHASE 10
Remove legacy UI, renderers, editors, fixtures and disposable content.

PHASE 11
Update tests and add architecture regression tests.

PHASE 12
Run complete quality gate.

---

## 21. QUALITY GATE

Completion requires:

flutter analyze
0 errors

All relevant tests passing.

git diff --check
clean

No unintended repository changes.

No references to the retired architecture remain in production code.

Required forbidden-term scan:

MainContentTopic
mainContent

Any remaining occurrence must be reviewed and justified.

The only permitted occurrences after implementation should be inside
historical documentation explicitly describing the retired architecture,
if such documentation is intentionally retained.

---

## 22. ARCHITECTURAL REGRESSION RULE

A future change MUST NOT reintroduce:

StudySubtopic
→ MainContentTopic
→ ContentBlock

or any equivalent hidden intermediate level.

The only approved learning-content hierarchy is:

Domain
→ Competency
→ Content Package
→ Content Version
→ Topic
→ Subtopic
→ Content Blocks
→ Practice Questions

---

## 23. FROZEN DECISION

This document freezes the following decision:

OPTION B
CLEAN NEW STUDYTOPIC ARCHITECTURE

Complete removal of MainContentTopic.

No migration of currently populated legacy Topic/Subtopic data.

No compatibility architecture for the retired hierarchy.

No Step 8 content-population stage.

Development proceeds directly toward implementation of the final
Topic → Subtopic → Learning Content structure inside the CSP11 app.

Any deviation requires explicit authorization from Naveed.

END OF FROZEN ARCHITECTURAL DECISION
