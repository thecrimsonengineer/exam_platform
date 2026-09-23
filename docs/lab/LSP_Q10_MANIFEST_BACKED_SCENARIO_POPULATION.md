# CSP11 LSP-Q10 - Manifest-Backed Scenario Population

## Status

**IMPLEMENTED / VALIDATION CHECKPOINT**

Program: LSP-Q

Checkpoint: LSP-Q10

Branch: phase-l4-scenario-population

Baseline Q9 formatter commit: 501290041b9a6bf63421c6963461ef7a1b18f260

## Purpose

LSP-Q10 populates the Q9 manifest with the frozen real Phase L scenario set.

Population size:

- 10 LABs
- 50 Decision Nodes
- 200 Decision options
- 14,950 stored atomic DQG rule-evidence records
- 10 technical LAB packages
- 10 DQG300 evidence bundles
- 10 Q8 learner-presentation packages

No placeholder LAB or synthetic empty evidence package is introduced.

## Population layout

The canonical manifest is:

content/lab_population/manifest.json

Each LAB/version is stored as one three-artifact directory:

content/lab_population/<labId>/<versionId>/technical.json
content/lab_population/<labId>/<versionId>/dqg300_evidence.json
content/lab_population/<labId>/<versionId>/learner_presentation.json

The Q9 manifest is the only population index.

## Frozen population

The ten LAB identities are:

1. hot_work_hydrocarbon_simops
2. mobile_crane_critical_lift
3. excavation_buried_services
4. electrical_loto_stored_energy
5. work_at_height_offshore_module
6. chemical_transfer_corrosive_solvent
7. hydrocarbon_line_breaking
8. flammable_tank_truck_loading
9. pneumatic_pressure_test
10. scaffold_erection_overhead_power

Every entry is version v1.

## Controlled migration from the frozen source package

The original population artifacts were created before Q7 and Q8 reached their final wire contracts.

Q10 therefore performs two deterministic compatibility migrations only.

### DQG300 Decision signatures

The historical evidence bundles pinned the same technical Decisions but encoded Decision quality in signatures as:

OPTIMAL
DEFENSIBLE
WEAK
CRITICAL

The current frozen Q7 signer uses the parsed Dart enum names:

optimal
defensible
weak
critical

Q10 regenerates only the 50 Decision-signature strings from the unchanged technical Decisions.

No question evidence, rule evidence, DQS input, distractor evidence, source evidence, BEST-answer truth, option text or Decision mechanics are regenerated.

### Learner presentation evidence details

The historical combined learner-presentation file stores each evidence details field as an array of learner-facing lines.

The frozen Q8 individual package contract accepts one text field.

Q10 joins each existing details array with newline separators and splits the combined ten-record source into ten individual Q8 packages.

No learner-facing statement is invented or deleted.

### Strict H0.3 option-surface repair

The first exact population regression identified five Decisions where the BEST option was uniquely the longest. Q5 correctly blocked those Decisions even though their DQG300 semantic results remained DQS 100 with all 300 rules passing.

Q10 repairs only the affected distractor wording so the BEST answer is no longer uniquely longest:

- chemical_transfer_corrosive_solvent / exposure_control_decision
- hydrocarbon_line_breaking / release_decision
- pneumatic_pressure_test / rupture_decision
- pneumatic_pressure_test / closeout_decision
- scaffold_erection_overhead_power / material_handling_decision

For each repair Q10 updates the repeated distractor scenarioEvidence text, character/word surface metrics and the pinned Decision signature.

The distractor's original technical flaw is preserved. BEST-answer flags, Decision quality classes and technical mechanics are unchanged.

## Technical package preservation

Technical LAB story mechanics remain frozen. Q10 does not change:

- Decision prompts
- BEST-answer flags
- Decision quality
- consequences
- state mutations
- Story Gates
- endings
- evidence truth
- source truth
- competency mappings
- lifecycle

Five distractor option strings receive only the strict-H0.3 surface-balance repairs listed above.

The manifest remains a reference layer only.

## DQG authority

Q10 does not replace any earlier Decision-quality layer.

Every populated LAB must pass:

Canonical parser
AND strict H0.3
AND DQG300 semantic authority
AND DQS 100

The Q10 regression runs the frozen LabDecisionQualityGate against all 50 populated Decisions.

## Presentation authority

Every learner presentation must pass the frozen Q8 mapping validator through the Q9 population binding validator.

A population entry therefore fails if presentation identity, Decision IDs, consequence IDs, evidence IDs or ending IDs drift from the technical LAB.

## Source provenance

Frozen source archive SHA-256:

c759ea4bd7b29c7b098c96a34059a1ad14fc0c3a88cc05c15eae2ad868be5efb

Frozen combined learner-presentation SHA-256:

76b15913c03bc8ef4d7528fabb9dbc38743242a1245864ffbb3db5e174b83dcb

The deterministic migration audit is stored at:

content/lab_population/migration_report.json

## Test coverage

test/lab_quality/lsp_q10_manifest_backed_scenario_population_test.dart verifies:

- manifest ID and exact ten-LAB set
- every three-artifact Q9 binding
- every Q8 learner-presentation mapping
- all 50 Decisions through the combined Q4-Q7 quality gate
- exactly 50 Decisions
- exactly 200 options
- exactly 14,950 stored atomic DQG rule-evidence records

The existing Q1 through Q9, frozen H0.3, Studio and full-repository regressions remain mandatory.

## Out of scope

LSP-Q10 does not:

- publish the populated LABs
- expose them in the learner scenario library
- change LAB1000 lifecycle behavior
- change runtime loading
- rewrite technical scenario content
- weaken DQG300
- alter Q8 learner presentation authority

Population is now repository-backed and validation-backed. Learner delivery remains a later checkpoint.

## Next authorized action

LSP-Q11 - Population Publication Gate and Repository Admission.
