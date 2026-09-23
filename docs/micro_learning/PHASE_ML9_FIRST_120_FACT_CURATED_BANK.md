# CSP11 Phase ML-9 - First 120-Fact Curated Bank

Status: IN PROGRESS  
Parent: `docs/micro_learning/PHASE_ML8_DUPLICATE_CONTRADICTION_DETECTION.md`  
Branch: `phase-ml9-first-120-fact-curated-bank`  
Parent recovery point: `cad3cd44983ba5385704b552ae476cb01ac9e938`

## Purpose

ML-9 creates the first production MicroFact corpus for CSP11.

The target is 120 authoritative, startup-suitable facts. The number is not a permission to lower quality. A weak fact remains unpublishable even when a bucket is under target.

ML-9 inherits every ML-0 through ML-8 invariant.

## Non-negotiable boundary

AI may draft candidate wording and metadata.

AI is never a source and may not self-certify human review.

A candidate drafted in ML-9 begins fail-closed:

```text
status = review
runtime.startupEligible = false
review channels = pending
```

Promotion to `validated` or `published` requires the evidence and human-review contracts already frozen in ML-5, ML-6, ML-7 and ML-8.

## Curated distribution

The initial planning distribution is exactly 120 slots:

| Bucket | Count | MicroFact category |
|---|---:|---|
| Occupational safety | 25 | safety_insight |
| Industrial hygiene | 20 | ih_insight |
| Process safety | 15 | process_safety_insight |
| Fire / electrical | 12 | fire_electrical_insight |
| Management systems | 12 | management_insight |
| Environmental | 10 | environmental_insight |
| Emergency management | 8 | emergency_insight |
| Transportation / fleet | 6 | transport_insight |
| CSP reasoning | 6 | csp_tip |
| Evidence-based learning | 6 | learning_tip |

These are planning buckets. They do not override source fitness, curriculum truth, ML-8 duplicate detection, or human review.

## Curriculum mapping rule

The frozen ML-6 curriculum registry currently provides authoritative domain and competency identities.

The topic/subtopic navigation registry is not populated for MicroFact use.

Therefore ML-9 may:

- map a fact to an authoritative domain and competency;
- leave topicId and subtopicId null;
- use general scope where a fact is genuinely cross-curriculum;
- never invent a topic or subtopic ID.

Mapped facts still require ML-6 human mapping evidence before validation or publication.

## Production workflow

ML-9 runs in six controlled stages.

### ML-9A - Bank contract and 120-slot manifest

Freeze:

- target count;
- bucket allocation;
- stable planned IDs;
- candidate lifecycle behavior;
- publication exit criteria;
- batch size;
- review boundary.

### ML-9B - Candidate authoring

Author candidates in batches of 10.

Every candidate must have:

- one approved ML-1 authority;
- first-party HTTPS provenance;
- source class permitted for that authority;
- independent wording;
- a single startup-scale teaching point;
- CSP curriculum placement or justified general scope;
- legal-status metadata;
- assessment-sensitivity metadata;
- at least two tags.

Candidate facts remain non-startup and non-published.

### ML-9C - Gate evidence

For candidates selected for release, build and validate:

- ML-5 rights evidence;
- ML-6 curriculum evidence for mapped facts;
- ML-7 pedagogy and accessibility evidence.

Human-review flags remain false until a real reviewer completes the review.

### ML-9D - Whole-corpus ML-8 pass

After every accepted batch:

- run exact duplicate detection;
- run near-duplicate detection;
- run polarity conflict detection;
- run legal-status conflict detection;
- run numerical conflict detection;
- run edition-drift detection;
- inspect concentration signals.

Any ML-8 review candidate must be human-adjudicated before publication.

### ML-9E - Human review

A real reviewer must complete the applicable technical, source, curriculum, rights, pedagogy and accessibility checks.

ML-9 tooling must never generate a fake human approval.

### ML-9F - Publication freeze

ML-9 closes only when:

- exactly 120 production facts are accepted;
- all 120 are published;
- all 120 are startup eligible;
- all required review channels pass;
- all evidence bindings match current content;
- ML-8 whole-corpus validation has no unresolved issue;
- source verification is current;
- the exact closing SHA is recorded and frozen.

## Authoring batches

The frozen batch size is 10.

The expected sequence is:

```text
candidate batch
  -> ML-1..ML-7 individual gates
  -> ML-8 whole-corpus comparison
  -> human review/evidence
  -> accepted batch freeze
  -> next batch
```

The corpus is rechecked as a whole. A fact that was distinct in batch 1 may become a duplicate when batch 7 is added.

## Stable identities

The initial manifest reserves:

```text
mf_ml9_001
...
mf_ml9_120
```

A reserved slot is not itself a MicroFact and is not publishable content.

If a candidate is rejected, the slot may receive rewritten content under the same planned identity only before publication. Once a MicroFact identity is published, normal contentVersion and supersession rules apply.

## Source use

Only the frozen ML-1 Authority Registry is eligible.

Source selection is claim-driven. No authority receives a quota merely for visual balance.

ML-8 concentration signals remain visible so the bank does not accidentally become a one-source echo chamber.

## Copyright

Original paraphrase remains the preferred treatment.

ML-9 must not populate the bank by copying:

- standards clauses;
- tables;
- diagrams;
- checklists;
- question-bank material;
- answer keys;
- book paragraphs;
- paywalled source text.

Rights-sensitive professional and standards sources retain the ML-5 human-review requirement.

## Numerical claims

Numerical claims are allowed only when the exact source locator and context support them.

They receive enhanced review under ML-4 and remain subject to ML-8 numeric-conflict detection.

A safer non-numerical fact is preferable to a decontextualized number.

## Current state

ML-9A begins with:

- dedicated branch created from the exact ML-8 closed SHA;
- frozen curated-bank policy;
- 120-slot manifest;
- no production fact marked as human-reviewed;
- no startup eligibility granted by ML-9A.

## Exit criteria

- [x] ML-9 branch created from exact ML-8 closure.
- [x] 120-slot distribution frozen.
- [x] Stable planned MicroFact IDs reserved.
- [x] Candidate lifecycle boundary frozen.
- [x] No invented topic/subtopic mapping allowed.
- [x] Human-review boundary preserved.
- [x] Release requires whole-corpus ML-8 pass.
- [ ] 120 candidate facts authored.
- [ ] Individual ML-1 through ML-7 gates passed as applicable.
- [ ] ML-8 corpus candidates adjudicated.
- [ ] Required human reviews completed.
- [ ] 120 facts published and startup eligible.
- [ ] Exact closing SHA frozen.

## ML-9B batch progress

### Batch 01

- 10 candidate facts authored.
- Cumulative candidate count: 10.
- Candidates remain in `review`.
- Startup eligibility remains false.
- Human technical approval remains pending.

### Batch 02

- 10 additional candidate facts authored.
- Cumulative candidate count: 20.
- Batch spans occupational safety, industrial hygiene, process safety, fire/electrical, management systems, environmental management, emergency management, transportation/fleet, CSP reasoning, and evidence-based learning.
- First-party source provenance was populated from the frozen authority registry.
- ML-7 startup text precheck passed for all Batch 02 candidates.
- Current 20-candidate ML-8 deterministic precheck reports zero exact duplicates and zero unresolved review candidates.
- One false edition-drift signal was prevented by making the Prevention through Design source locator page-specific rather than weakening ML-8.
- The environmental startup copy was rewritten to avoid an abbreviation outside the frozen ML-7 whitelist.
- The learning-tip candidate was rebound to the NIOSH page that directly states the systematic-review findings.
- No candidate is validated, published, or startup eligible.
- No automated process has asserted human review.

Batch 02 review artifacts:

- `content/micro_learning/review/ml9_batch_02_review_ledger.json`
- `content/micro_learning/review/ml9_batch_02_precheck.json`

### Batch 03

- 10 additional candidate facts authored.
- Cumulative candidate count: 30.
- Batch covers confined-space evaluation, respiratory protection, process mechanical integrity, extinguisher readiness, worker participation, hazardous-waste container management, NIMS command and coordination, fleet maintenance, evidence synthesis, and job-training analysis.
- All Batch 03 candidates remain in `review`.
- Startup eligibility remains false.
- Human technical approval remains pending.
- Frozen startup text precheck passed.
- Cumulative ML-8 field-level precheck scanned 435 pairs across 30 candidates.
- Exact duplicate count: 0.
- Unresolved ML-8 review-candidate count: 0.
- Repository CLI validation remains mandatory before ML-9 closure.

Batch 03 review artifacts:

- `content/micro_learning/review/ml9_batch_03_review_ledger.json`
- `content/micro_learning/review/ml9_batch_03_precheck.json`

### Batch 04

- 10 additional candidate facts authored.
- Cumulative candidate count: 40.
- Batch covers powered industrial truck competence, engineering controls, pre-startup safety review, electrical guarding, program evaluation, hazardous-waste labeling, emergency personnel qualification, distracted driving, occupational risk assessment, and audience-adapted training.
- All Batch 04 candidates remain in `review`.
- Startup eligibility remains false.
- Human technical approval remains pending.
- Two ML-4 category/source conflicts were caught and corrected before freeze:
  - `mf_ml9_111` now uses NIOSH occupational risk-assessment material with `legalStatus: not_applicable`.
  - `mf_ml9_117` now uses NIOSH ergonomics-training material with `legalStatus: not_applicable`.
- Batch 04 startup text precheck passed.
- Cumulative ML-8 field-level precheck scanned 780 unique pairs across 40 candidates.
- Exact duplicate count: 0.
- Unresolved ML-8 review-candidate count: 0.
- A reusable candidate-bank validator and dedicated ML-9 GitHub Actions workflow now exist.
- GitHub Actions exact-SHA validation passed for the 40-candidate bank: 40 facts, 780 pair comparisons, 0 ML-8 review candidates, and 0 automated publication approvals.
- ML-8 reported 1 non-blocking concentration signal: SRC-01 / OSHA contributes 17 of 40 candidates (42.5%), above the 40% composition-review threshold.
- Batch 05 should diversify authority use where source fitness permits; the concentration signal does not weaken or block technically justified OSHA facts.
- Human technical, curriculum, rights, pedagogy, and accessibility review remains pending.

Batch 04 review and validation artifacts:

- `content/micro_learning/review/ml9_batch_04_review_ledger.json`
- `content/micro_learning/review/ml9_batch_04_precheck.json`
- `tool/validate_ml9_candidate_bank.dart`
- `.github/workflows/ml9_candidate_bank_validation.yml`

## Next action

ML-9B Batch 05 - author the next 10 review-state candidates, then rerun candidate-gate, startup-text and whole-corpus ML-8 validation against all 50 candidates.
