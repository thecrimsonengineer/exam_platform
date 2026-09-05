# L23E: Canonical Blueprint → Current CSP11 Content Repository

## Status

Phase: L23E
Title: Canonical Blueprint → Current CSP11 Content Repository
Status: MASTER PLAN CREATED
Implementation status: NOT STARTED
Source of truth: docs/source_pipeline/CSP11_canonical_blueprint.json

---

# 1. PURPOSE

This phase establishes the canonical CSP11 domain and competency structure as the authoritative structural layer of the Content Repository.

The objective is to ensure that the current Content Repository is based on the official CSP11 canonical blueprint rather than discovering competencies only from existing content packages.

The canonical structure must exist independently of whether learning content has already been created.

The target architecture is:

CSP11 Canonical Blueprint
        ↓
Canonical Domain Registry
        ↓
Canonical Competency Registry
        ↓
Current Content Repository
        ↓
Existing Content Packages / Versions
        ↓
Topics / Subtopics / Content Blocks / Questions

The canonical competency registry is derived from the canonical blueprint and is NOT a separate Firestore collection.

Firestore continues to store actual Content Package / Content Version records.

---

# 2. AUTHORITATIVE SOURCE

Primary authoritative source:

docs/source_pipeline/CSP11_canonical_blueprint.json

The canonical blueprint is authoritative for:

- The 7 official CSP11 domains
- Domain IDs
- Domain numbers
- Domain names
- Domain weights
- The 47 official competencies
- Competency IDs
- Competency numbers
- Full official competency statements
- Domain-to-competency relationships

Canonical competency IDs use:

d01_c01
d01_c02
...
d07_c06

The canonical blueprint uses domain IDs:

d01
d02
d03
d04
d05
d06
d07

The full official competency statements in the canonical blueprint must not be shortened, paraphrased, merged, split, or replaced by older application wording.

---

# 3. FROZEN ARCHITECTURAL DECISIONS

## 3.1 Canonical competency registry

The canonical competency registry is DERIVED from:

docs/source_pipeline/CSP11_canonical_blueprint.json

It is not independently authored in Firestore.

There will NOT be a new Firestore `competencies` collection as part of this phase.

---

## 3.2 Firestore

Firestore continues to store actual content package/version data in:

contentVersions

A canonical competency existing in the registry does NOT create an empty Firestore content record.

Therefore:

47 competencies != 47 Firestore content packages.

---

## 3.3 StudyContent

StudyContent represents actual learning content package/version data.

It must not be repurposed into the canonical competency entity.

The competency identity carried by StudyContent must reference a valid canonical competency.

---

## 3.4 Content Repository

The Admin Content Repository must be able to display all 47 canonical competencies even when a competency has:

- zero content packages
- zero topics
- zero subtopics
- zero content blocks
- zero questions
- zero published content

Content package/version information is overlaid onto the canonical competency.

---

## 3.5 Source mapping

L2.3-D source-to-competency mapping remains a separate evidence/mapping layer.

A candidate source-to-competency relationship MUST NOT be interpreted as:

- content coverage
- competency completion
- validated learning content
- published content
- question coverage

No L2.3-D mapping may be silently converted into repository coverage.

---

## 3.6 Existing content compatibility

Existing content must not be unnecessarily rewritten.

Existing legacy identifiers such as:

domain_01

may require compatibility handling.

Compatibility identifiers must not replace the canonical identity.

Canonical application identity remains:

d01

and canonical competency identity remains:

d01_c01

etc.

---

# 4. TARGET ARCHITECTURE

Current conceptual model:

Content Packages
        ↓
derive competencies
        ↓
Admin Repository

Target model:

Canonical Blueprint
        ↓
Canonical Domain Registry
        ↓
Canonical Competency Registry
        ↓
Admin Repository
        ↑
Content Packages / Versions from Firestore

This means:

COMPETENCY EXISTENCE

and

CONTENT EXISTENCE

are two separate concepts.

A competency may exist with no content.

A competency may have one or more content packages.

A competency may have draft content but no published content.

A competency may have published content.

The Repository must represent these states without creating false content records.

---

# 5. IMPLEMENTATION STRATEGY

This phase will be implemented incrementally.

Do NOT attempt a large uncontrolled migration.

Each implementation step must:

1. Have a clearly defined scope.
2. Make the smallest necessary code changes.
3. Add or update tests.
4. Run validation.
5. Record the result in this document.
6. Be committed before moving to the next significant step.

Where content work becomes large, implementation may proceed one competency at a time or one subtopic at a time.

No requirement exists to complete all 47 competencies in one operation.

---

# 6. L23E IMPLEMENTATION PHASES

## L23E-0: Master Plan and Tracking

Status: IN PROGRESS

Objectives:

- Create this master plan inside exam_platform.
- Establish the frozen architecture.
- Establish implementation checkpoints.
- Establish acceptance criteria.
- Track all completed work inside the repository.

Completion criteria:

- [ ] Master plan exists in repository
- [ ] Architecture decisions recorded
- [ ] Implementation phases recorded
- [ ] Acceptance criteria recorded
- [ ] Git checkpoint created

---

## L23E-1: Canonical Registry Foundation

Status: NOT STARTED

Objectives:

- Make the canonical JSON the authoritative application source.
- Establish canonical domain IDs d01 through d07.
- Establish all 47 canonical competency IDs.
- Establish full official competency statements.
- Preserve domain-to-competency relationships.
- Avoid duplication of authoritative competency data.

Requirements:

- [ ] Inspect current registry implementation
- [ ] Determine safest generated/runtime representation
- [ ] Implement canonical registry
- [ ] Preserve required compatibility helpers
- [ ] Ensure canonical IDs are emitted consistently
- [ ] Ensure full official statements are retained
- [ ] Add deterministic validation
- [ ] Add regression tests

---

## L23E-2: Canonical Competency Model

Status: NOT STARTED

Objectives:

Introduce a clean representation of a canonical competency that is separate from StudyContent.

The model should represent structural competency information such as:

- domain
- competency ID
- competency number
- official competency statement

It must not represent content package/version state as if that were part of the canonical competency.

Requirements:

- [ ] Define model
- [ ] Define canonical identity
- [ ] Define domain relationship
- [ ] Define official statement
- [ ] Avoid Firestore persistence
- [ ] Add tests

---

## L23E-3: Repository Competency Overlay

Status: NOT STARTED

Objectives:

Change repository aggregation so that canonical competencies form the base set.

Existing content packages/versions are then associated with the appropriate canonical competency.

Target:

47 canonical competencies
+
existing Content Packages / Versions

Requirements:

- [ ] Repository starts from canonical 47
- [ ] Existing package records overlay correctly
- [ ] Empty competencies remain visible
- [ ] Multiple packages are handled correctly
- [ ] Multiple versions are handled correctly
- [ ] Published/draft/review/validated states remain separate
- [ ] No fake Firestore records are created
- [ ] Add service tests

---

## L23E-4: Content Validation Against Canonical Registry

Status: NOT STARTED

Objectives:

Ensure imported or created content references valid canonical competency identity.

Validation must check:

- [ ] competency ID exists
- [ ] domain relationship is correct
- [ ] competency number is correct
- [ ] canonical ID format is correct
- [ ] invalid competency IDs are rejected
- [ ] mismatched domain is rejected
- [ ] mismatched competency number is rejected
- [ ] valid content passes

Existing Content Quality and Question Quality validation must remain intact.

---

## L23E-5: Existing Content Compatibility

Status: NOT STARTED

Objectives:

Ensure existing content remains usable while canonical identity is standardized.

Requirements:

- [ ] Inspect existing content identifiers
- [ ] Identify legacy domain ID formats
- [ ] Add compatibility normalization only where necessary
- [ ] Do not rewrite Firestore unnecessarily
- [ ] Do not silently change existing content semantics
- [ ] Verify published content loading
- [ ] Verify Admin repository loading
- [ ] Verify Studio opening/editing

---

## L23E-6: Admin Content Repository

Status: NOT STARTED

Objectives:

Update the Admin Content Repository to use the canonical competency registry as its structural foundation.

The UI must distinguish:

- canonical competency exists
- content exists
- content is published
- content is in review
- content is validated
- content is draft

A competency with no content must not appear as a missing competency.

Requirements:

- [ ] Display all 47 competencies
- [ ] Correct domain filtering
- [ ] Correct competency filtering
- [ ] Show canonical official statement where appropriate
- [ ] Show package counts
- [ ] Show lifecycle information
- [ ] Show empty/no-content state
- [ ] Do not claim coverage from source mapping
- [ ] Preserve existing package workflows

---

## L23E-7: Study Content Studio Compatibility

Status: NOT STARTED

Objectives:

Ensure Study Content Studio continues to operate as a content authoring environment.

Studio remains focused on:

Content Package
→ Content Version
→ Topics
→ Subtopics
→ Content Blocks
→ Practice Questions

Studio must NOT become a separate canonical competency authoring system.

Requirements:

- [ ] Studio selects canonical competency
- [ ] Existing content continues to open
- [ ] New content references canonical competency
- [ ] Content import uses canonical validation
- [ ] Question workflow remains unchanged unless required
- [ ] No duplicate competency authoring layer

---

## L23E-8: Student Compatibility

Status: NOT STARTED

Objectives:

Ensure student content consumption continues to work.

Requirements:

- [ ] Published content remains loadable
- [ ] Existing competency lookups remain functional
- [ ] Legacy compatibility is preserved where required
- [ ] Canonical registry does not break student content
- [ ] Student-side behavior remains unchanged unless necessary

---

## L23E-9: Competency-by-Competency Verification

Status: NOT STARTED

The repository architecture may be implemented globally, but detailed content verification may proceed incrementally.

Each competency receives a tracked status.

Format:

D01-C01
- Registry: [ ]
- Canonical ID verified: [ ]
- Official statement verified: [ ]
- Repository overlay verified: [ ]
- Existing content checked: [ ]
- Subtopics checked: [ ]
- Questions checked: [ ]
- QA complete: [ ]

Repeat for all 47 competencies.

If a competency is too large, verification may be broken into individual subtopics.

No requirement exists to complete all subtopics in one session.

---

# 7. COMPETENCY TRACKING MATRIX

## Domain 01

- [ ] d01_c01
- [ ] d01_c02
- [ ] d01_c03
- [ ] d01_c04
- [ ] d01_c05
- [ ] d01_c06
- [ ] d01_c07

## Domain 02

- [ ] d02_c01
- [ ] d02_c02
- [ ] d02_c03
- [ ] d02_c04
- [ ] d02_c05
- [ ] d02_c06
- [ ] d02_c07
- [ ] d02_c08
- [ ] d02_c09
- [ ] d02_c10

## Domain 03

- [ ] d03_c01
- [ ] d03_c02
- [ ] d03_c03
- [ ] d03_c04
- [ ] d03_c05
- [ ] d03_c06
- [ ] d03_c07

## Domain 04

- [ ] d04_c01
- [ ] d04_c02
- [ ] d04_c03
- [ ] d04_c04
- [ ] d04_c05
- [ ] d04_c06
- [ ] d04_c07

## Domain 05

- [ ] d05_c01
- [ ] d05_c02
- [ ] d05_c03
- [ ] d05_c04
- [ ] d05_c05
- [ ] d05_c06

## Domain 06

- [ ] d06_c01
- [ ] d06_c02
- [ ] d06_c03
- [ ] d06_c04
- [ ] d06_c05
- [ ] d06_c06

## Domain 07

- [ ] d07_c01
- [ ] d07_c02
- [ ] d07_c03
- [ ] d07_c04
- [ ] d07_c05
- [ ] d07_c06

Total canonical competencies: 47

---

# 8. TESTING REQUIREMENTS

## Canonical Registry Tests

The final implementation must verify:

- [ ] exactly 7 domains
- [ ] exactly 47 competencies
- [ ] domain IDs are d01 through d07
- [ ] competency IDs are unique
- [ ] competency IDs follow dXX_cYY format
- [ ] competency IDs belong to the correct domain
- [ ] competency numbering is correct
- [ ] official statements are non-empty
- [ ] official statements match canonical source
- [ ] domain weights remain correct
- [ ] domain weights total 100%

---

## Repository Tests

The final implementation must verify:

- [ ] all 47 competencies can exist without content
- [ ] existing packages attach to the correct competency
- [ ] multiple packages remain supported
- [ ] multiple versions remain supported
- [ ] lifecycle states remain correct
- [ ] no fake package is created for empty competencies
- [ ] canonical registry does not depend on Firestore package existence

---

## Content Validation Tests

The final implementation must verify:

- [ ] valid competency accepted
- [ ] unknown competency rejected
- [ ] wrong domain rejected
- [ ] wrong competency number rejected
- [ ] malformed competency ID rejected
- [ ] canonical valid content accepted

---

## Compatibility Tests

The final implementation must verify:

- [ ] existing content remains loadable
- [ ] published content remains loadable
- [ ] Admin Repository remains functional
- [ ] Studio remains functional
- [ ] student content loading remains functional
- [ ] legacy identifiers remain supported where required

---

# 9. ACCEPTANCE CRITERIA

L23E is complete only when all of the following are true:

1. CSP11_canonical_blueprint.json is the authoritative source for canonical domains and competencies.

2. The application recognizes exactly 7 canonical domains.

3. The application recognizes exactly 47 canonical competencies.

4. Canonical domain IDs use d01 through d07.

5. Canonical competency IDs use dXX_cYY.

6. Full official competency statements are preserved.

7. No separate Firestore competency collection is required.

8. Firestore continues to store actual Content Package / Content Version records.

9. The Content Repository can display canonical competencies even when no content exists.

10. Existing content packages continue to function.

11. Existing published content continues to function.

12. Content cannot reference an unknown canonical competency.

13. Domain and competency relationships are validated.

14. L2.3-D source mapping is not treated as content coverage.

15. Study Content Studio remains a content authoring workflow, not a competency authoring workflow.

16. The implementation is covered by deterministic regression tests.

17. flutter analyze completes with zero errors.

18. flutter test passes.

19. git diff --check passes.

20. Git status contains only intentional L23E changes.

---

# 10. FILES EXPECTED TO BE REVIEWED

Primary source:

docs/source_pipeline/CSP11_canonical_blueprint.json

Likely application files:

lib/data/csp11_blueprint.dart
lib/models/study_content.dart
lib/services/study_content/content_repository_service.dart
lib/services/study_content/cloud_content_repository.dart
lib/services/study_content/content_import_service.dart
lib/services/study_content/study_content_loader.dart
lib/screens/admin/content_repository/content_repository_screen.dart
lib/screens/admin/study_content/study_content_studio_screen.dart

Relevant tests:

test/services/content_repository_service_test.dart
test/services/study_content/content_repository_service_test.dart
test/services/study_content_loader_test.dart
test/services/study_content/student_content_cache_repository_test.dart
test/services/study_content/student_content_sync_service_test.dart
test/services/studio_question_import_service_test.dart
test/services/studio_question_service_test.dart
test/services/question_quality_validator_test.dart
test/services/question_bank_service_test.dart

Additional files may be added only when justified by the implementation.

---

# 11. GENERATED VS AUTHORITATIVE FILES

The canonical JSON remains authoritative.

If Dart or another application artifact is generated from the canonical JSON:

- The generated artifact must be clearly identified.
- Generation must be deterministic.
- The generated output must not become an independent source of truth.
- Regeneration must produce byte-stable output.
- The generation process must be documented.
- Generated changes must be reviewed before commit.

No manually edited duplicate of the canonical competency statements should become authoritative.

---

# 12. GIT CONTROL

All L23E work must be performed as controlled changes.

Do NOT use:

git add .

Use explicit file paths when staging changes.

Before each significant checkpoint:

git status
git diff
git diff --check
flutter analyze
flutter test

Only intentional L23E files may be committed.

---

# 13. IMPLEMENTATION CHECKPOINTS

Checkpoint L23E-0
- [ ] Master plan created
- [ ] Review plan
- [ ] Commit

Checkpoint L23E-1
- [ ] Canonical registry implemented
- [ ] Tests pass
- [ ] Commit

Checkpoint L23E-2
- [ ] Canonical competency model implemented
- [ ] Tests pass
- [ ] Commit

Checkpoint L23E-3
- [ ] Repository overlay implemented
- [ ] Tests pass
- [ ] Commit

Checkpoint L23E-4
- [ ] Content validation implemented
- [ ] Tests pass
- [ ] Commit

Checkpoint L23E-5
- [ ] Existing content compatibility verified
- [ ] Tests pass
- [ ] Commit

Checkpoint L23E-6
- [ ] Admin Repository updated
- [ ] Tests pass
- [ ] Commit

Checkpoint L23E-7
- [ ] Studio compatibility verified
- [ ] Tests pass
- [ ] Commit

Checkpoint L23E-8
- [ ] Student compatibility verified
- [ ] Tests pass
- [ ] Commit

Checkpoint L23E-9
- [ ] Competency verification completed
- [ ] Final audit completed
- [ ] Commit

---

# 14. CURRENT CHECKPOINT

Current phase:

L23E-0

Current status:

MASTER PLAN CREATED

Next action:

Inspect the exact current implementation files and establish the smallest safe L23E-1 change.

No application architecture has been changed by creation of this plan.

---

# 15. HANDOVER RULE

If work stops during L23E, update this file before ending the implementation session.

The handover must record:

- current phase
- current checkpoint
- files changed
- tests run
- test results
- known issues
- next exact action
- competency/subtopic currently being processed, if applicable

The repository must therefore remain sufficient to resume L23E without relying solely on chat history.

---

# 16. NON-NEGOTIABLE RULES

1. Canonical blueprint is authoritative.
2. Use d01 through d07 for canonical domain IDs.
3. Use dXX_cYY for canonical competency IDs.
4. Preserve full official competency statements.
5. Do not create a Firestore competency collection for this phase.
6. Do not create fake empty StudyContent records.
7. Do not confuse competency existence with content existence.
8. Do not use source mappings as proof of content coverage.
9. Do not turn Study Content Studio into a competency authoring system.
10. Do not unnecessarily rewrite existing Firestore content.
11. Preserve student compatibility.
12. Work incrementally.
13. Track every checkpoint in this file.
14. Add tests with implementation changes.
15. Keep generated artifacts deterministic.
16. Never use git add .
17. Never use em dashes in documentation or implementation notes.

---

# 17. CHANGE LOG

## 2026-09-05

L23E master plan created.

Initial architectural decision recorded:

Canonical Blueprint
→ Canonical Registry
→ Content Repository

Canonical competencies remain derived application metadata.

Firestore remains the persistence layer for actual Content Packages / Versions.

Implementation has NOT yet started.
