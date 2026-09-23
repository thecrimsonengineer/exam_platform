# CSP11 LSP-Q13 - Persistent Learner Catalogue Repository and Runtime Binding

## Status

**IMPLEMENTED / VALIDATION CHECKPOINT**

Program: LSP-Q

Checkpoint: LSP-Q13

Branch: phase-l4-scenario-population

Baseline Q12 closure commit: d1451a777a32527eecbf5c8b5ca3b57edab6402a

## Purpose

LSP-Q13 moves the Q11/Q12 publication and catalogue contracts onto the app's existing Firebase/Firestore production stack and binds the learner LAB runtime to those persistent repositories.

Q13 does not create another backend.

The branch already uses Firebase Authentication and Cloud Firestore for authenticated learner and admin data, so LAB persistence follows the same stack.

## Persistent collections

Q13 adds two versioned immutable Firestore collections.

### labPublishedVersions

Stores the exact Q11 immutable published LAB snapshot.

Document ID:

labId__versionId

Stored fields include:

- schemaVersion
- labId
- versionId
- lifecycle
- publishedJson
- publishedAt
- reviewerId
- validationAuthority
- DQG300 certificate JSON
- L4L certificate JSON
- L4N publish-evidence certificate JSON
- snapshot fingerprint
- server creation timestamp

Persistent writes require the complete automated Q11 evidence chain. Manual or incomplete snapshots are rejected by the repository before Firestore write.

### labLearnerCatalogue

Stores the explicit Q12 learner catalogue record.

Document ID:

labId__versionId

The document contains only learner-safe catalogue metadata and the validated Q8 learner presentation package.

It does not contain DQG scores, internal Story Gates, state variables, draft source paths or publication diagnostics.

## Firestore security boundary

Firestore remains fail closed.

Published technical LAB versions:

- authenticated learners may GET an exact PUBLISHED version
- learners may not LIST the technical collection
- admins may GET/LIST
- only admins may CREATE a valid Q11 automated version
- UPDATE and DELETE are denied

Learner catalogue:

- authenticated users may GET/LIST available catalogue entries
- only admins may CREATE valid catalogue entries
- UPDATE and DELETE are denied

Document keys are pinned to labId__versionId.

The Q11 validation authority is pinned to:

LSP-Q11-POPULATION-AUTO

## Persistent repository contracts

Q13 adds:

lib/features/lab/lab_firestore_repositories.dart

FirestoreLabPublishedRepository implements LabPublishedRepository.

FirestoreLabLearnerCatalogueRepository implements LabLearnerCatalogueRepository.

Both use create-once transaction semantics. Existing LAB/version identities cannot be overwritten.

Loaded published versions are revalidated through the frozen immutable repository contract before being returned.

Loaded catalogue records are rebuilt through the Q12 validating persistence constructor.

## Runtime binding

Q13 adds:

lib/features/lab/lab_runtime_binding.dart

LabLearnerRuntimeBinding composes:

FirestoreLabPublishedRepository
+
FirestoreLabLearnerCatalogueRepository
+
LabLearnerControlledDeliveryService

The learner runtime therefore obtains:

catalogue list -> exact labId/versionId -> immutable published package -> matching Q8 presentation

No draft asset path is involved in cloud delivery.

## Learner UI binding

The production LAB tab now opens:

LabLibraryScreen.persistent()

The persistent library lists only Firestore learner-catalogue entries.

When the learner opens a scenario, Q13 reloads the exact controlled delivery before navigation.

The verified LabPackage is then carried through:

Scenario Library
-> Scenario Briefing
-> Mode Selection
-> LAB Player

The player uses the verified published package directly.

It does not fall back to a bundled JSON asset for a persistent catalogue scenario.

The original bundled confined-space reference path remains available through the default non-persistent LabLibraryScreen and existing test/reference flows.

## Presentation mapping

Q13 adapts a Q12 catalogue entry into the existing learner scenario presentation model.

The adapter uses:

- technical published title
- learner summary
- focus tags
- estimated time
- decision count label
- role
- situation
- objective
- people involved
- known facts
- evidence presentation
- Decision titles
- consequence narration
- ending narration

Internal validation metadata remains hidden.

Reference-specific permit/isolation/gas/rescue status fields are not imposed on unrelated population scenarios. Persistent scenarios show only generic scenario time until a future authored learner-safe status schema exists.

## Test coverage

test/lab_quality/lsp_q13_persistent_runtime_binding_test.dart verifies:

- Q11 published versions round-trip through Firestore
- persistent published versions remain immutable
- Q12 learner catalogue entries round-trip through Firestore
- persistent catalogue entries remain immutable
- runtime binding lists and loads exact persistent versions
- the persistent learner library opens the scenario briefing
- the verified published package reaches the LAB player
- Firestore rules preserve admin-only writes
- Firestore rules preserve immutable version semantics
- the production LAB tab uses the persistent learner library

All Q1-Q12 and full repository regressions remain mandatory.

## Out of scope

LSP-Q13 does not:

- auto-seed the ten Q10 candidates into production Firestore
- auto-admit all ten LABs to the learner catalogue
- implement staged percentage rollout
- implement learner entitlement groups
- add offline LAB caching
- add catalogue search/filtering
- delete or mutate immutable published versions

## Next authorized action

LSP-Q14 - Controlled Production Population Seed and Learner Release Verification.
