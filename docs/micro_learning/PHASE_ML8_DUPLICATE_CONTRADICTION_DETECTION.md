# CSP11 Phase ML-8 - Duplicate / Contradiction Detection

Status: IMPLEMENTED  
Parent: `docs/micro_learning/PHASE_ML7_STARTUP_PEDAGOGY_READABILITY_ACCESSIBILITY_GATES.md`  
Branch: `phase-ml8-duplicate-contradiction-detection`

## Purpose

ML-8 protects the MicroFact bank as a corpus.

ML-1 through ML-7 answer whether one MicroFact is individually acceptable.

ML-8 asks:

> Can this fact coexist safely with the other active MicroFacts without creating duplicate learning, conflicting claims, stale waivers or unresolved contradictions?

No bulk production fact bank may be authored before ML-8 closes.

## Core rule

A fact is not corpus-safe merely because it is individually correct.

The corpus must also prevent:

- exact duplicates;
- disguised near-duplicates;
- conflicting polarity;
- conflicting legal status;
- conflicting numerical values in the same unit/context;
- edition/revision drift on the same source location;
- multiple active versions of one MicroFact ID;
- stale adjudication reuse;
- orphaned adjudication records;
- unresolved human-review candidates.

## No runtime AI or embedding dependency

ML-8 uses deterministic local comparison.

It adds:

- no LLM comparison;
- no vector database;
- no embeddings API;
- no Firebase read;
- no Supabase read;
- no HTTP lookup;
- no semantic-cloud service.

The detector is intentionally explainable and reproducible.

## Delivered artifacts

- `content/micro_learning/duplicate_contradiction_policy_v1.json`
- `content/micro_learning/corpus_comparison_evidence_schema_v1.json`
- `lib/services/micro_learning/duplicate_contradiction_policy_validator.dart`
- `lib/services/micro_learning/micro_fact_corpus_comparison.dart`
- `lib/services/micro_learning/corpus_comparison_evidence_validator.dart`
- `lib/services/micro_learning/micro_fact_corpus_integrity_validator.dart`
- ML-8 corpus fixtures
- ML-8 policy/comparison/evidence/corpus tests
- `tool/validate_micro_learning_corpus_integrity_gates.dart`
- this closure document
- exact-SHA ML-8 workflow

## Corpus lifecycle scope

Comparison-eligible statuses are:

```text
draft
review
validated
published
review_due
```

Excluded from active pair comparison:

```text
superseded
withdrawn
rejected
```

Only one comparison-eligible version of a given `microFactId` may exist at once.

Multiple active versions fail closed.

## Deterministic text normalization

ML-8 normalization:

- lowercases text;
- strips punctuation for token comparison;
- collapses wording to deterministic tokens;
- removes a frozen list of common stop words;
- preserves numbers;
- preserves safety/legal polarity terms.

Protected terms include:

```text
no
not
never
without
cannot
must
shall
required
prohibited
may
```

Negation is never treated as disposable stop-word noise.

## Exact duplicates

Exact duplicates cannot be waived by human adjudication.

ML-8 blocks when two different active MicroFacts have:

- identical normalized `displayText`;
- identical normalized `shortVariant`;
- identical raw display-text SHA-256.

This is a hard corpus error.

## Near-duplicate detection

ML-8 uses token-set Jaccard similarity.

Frozen thresholds:

```text
displayText Jaccard >= 0.80
shortVariant Jaccard >= 0.85
minimum concept Jaccard >= 0.50
```

A second concept-assisted path detects likely rewrites when:

- concept sets are exactly equal;
- categories are equal;
- display-text Jaccard >= 0.60.

These are review candidates rather than automatic duplicate verdicts.

## Same-source overlap

A pair also becomes a review candidate when it has:

- the same approved source authority;
- the same source locator;
- sufficient concept overlap;
- display-text overlap >= 0.50.

This helps prevent one source clause from being repackaged into several cosmetically different startup facts.

## Polarity conflicts

ML-8 compares preserved negation signals.

When two facts have:

- concept overlap >= 0.50;
- display overlap >= 0.65;
- opposite presence of negative polarity;

the pair receives:

```text
polarity_conflict
```

This is a review candidate.

The detector does not claim that all negation differences are contradictions. Human review decides whether the pair may coexist.

## Legal-status conflicts

A pair receives:

```text
legal_status_conflict
```

when:

- legal statuses differ;
- concept overlap >= 0.75;
- display overlap >= 0.40;
- jurisdiction context is comparable.

This is especially important for preventing confusion such as presenting a recommendation and a binding requirement as though they were equivalent.

The detector creates the candidate. It does not replace the ML-4 legal-status gate or human judgment.

## Numerical conflicts

ML-8 extracts supported number/unit signatures.

Supported unit families include:

- %
- ppm
- ppb
- mg/m3
- mg/m³
- dBA
- dB
- °C / °F
- volts / kV
- psi
- feet / metres
- seconds / minutes / hours / days

A numerical conflict candidate requires:

- both facts declare `numericalClaim=true`;
- concept overlap >= 0.50;
- text overlap >= 0.40;
- comparable jurisdiction;
- the same normalized unit appears in both;
- the values for that unit differ.

ML-8 does not perform automatic unit conversion.

For example:

```text
90 dBA vs 85 dBA
```

may become a conflict candidate.

```text
90 dBA vs 85 ppm
```

is not automatically compared as the same measurement.

No automatic numeric reconciliation is permitted.

## Edition drift

When two facts point to the same authority and same source locator but identify different editions/revisions, ML-8 creates:

```text
edition_drift
```

Human review must determine whether:

- both remain valid in different contexts;
- one supersedes the other;
- one should be withdrawn;
- both should be rewritten.

## Pairwise adjudication

Non-exact review candidates require a separate adjudication record.

The evidence binds to:

- ML-8 policy version;
- canonical pair key;
- exact left MicroFact ID/version;
- exact right MicroFact ID/version;
- SHA-256 comparison fingerprint of each fact;
- exact deterministic signal set;
- human decision;
- reviewer role;
- rationale;
- review date;
- next-review date.

Example pair key:

```text
mf_fact_a@1||mf_fact_b@1
```

Ordering is lexical and canonical.

## Comparison fingerprint

The fingerprint includes comparison-relevant fields such as:

- MicroFact ID;
- content version;
- category;
- display text;
- short variant;
- concept IDs;
- source registry ID;
- source class;
- source locator;
- edition/revision;
- legal status;
- jurisdiction;
- numerical-claim flag.

A relevant change invalidates old pair evidence.

## Allowed coexistence decisions

Passing pair decisions are:

```text
distinct_valid
scope_difference_valid
source_context_difference_valid
```

These mean a human reviewer confirmed that both facts may remain.

## Blocking human decisions

Blocking decisions are:

```text
duplicate_block
contradiction_block
merge_required
supersession_required
```

Even when the review record itself is complete and signed off, these decisions make the corpus invalid until the content is corrected.

Human review records a verdict. It does not turn a confirmed duplicate into an allowed duplicate.

## Exact signal-set binding

Adjudication evidence must contain the exact deterministic signal set generated for the current pair.

If the detector originally saw:

```text
near_duplicate
concept_assisted_duplicate
same_source_locator_overlap
```

and the text later changes so that only one signal remains, the old evidence is stale.

The old decision cannot be silently reused.

## Adjudication chronology

Passing adjudication requires:

- approved human reviewer role;
- humanReviewed = true;
- non-empty rationale;
- valid review date;
- valid next-review date.

The adjudication cannot predate the latest individual fact review.

Maximum adjudication validity is 365 days.

## Orphaned evidence

ML-8 rejects adjudication records that no longer correspond to a current review candidate.

This prevents old waivers from accumulating invisibly after facts are rewritten or removed.

## Active-version collision

Two comparison-eligible records with the same `microFactId` fail:

```text
ML8_ACTIVE_VERSION_COLLISION
```

Historical superseded/withdrawn/rejected records do not participate in the active pair scan.

## Concentration audit

ML-8 also reports corpus concentration.

These signals are intentionally non-blocking in ML-8:

- exact concept set appears 4 or more times;
- same source locator appears 3 or more times;
- one authority exceeds 40% of a corpus containing at least 20 facts.

Reasons:

- ML-8 is responsible for overlap/conflict integrity;
- ML-9 owns initial-bank composition;
- ML-11 owns runtime diversity;
- multiple legitimate facts may share a broad concept or authority.

The concentration report gives later phases evidence without turning broad educational coverage into a false contradiction.

## ML-8 blocking outcomes

A corpus fails when it contains:

- structurally invalid MicroFacts;
- more than one active version of an ID;
- exact duplicate pair;
- unresolved review candidate;
- missing adjudication;
- malformed adjudication;
- duplicate adjudication for a pair;
- fact/version mismatch;
- fingerprint drift;
- signal-set drift;
- pending/failed human review;
- human block/merge/supersession decision;
- adjudication predating fact review;
- adjudication validity >365 days;
- orphan adjudication.

## What ML-8 does not claim

ML-8 does not pretend deterministic token similarity can prove semantic equivalence.

It does not automatically decide that:

- similar wording means the same technical claim;
- different numbers are necessarily contradictory;
- different standards cannot coexist;
- different legal statuses always conflict;
- a negated phrase always represents the opposite technical rule.

Instead:

```text
deterministic candidate detection
        ↓
human adjudication
        ↓
bound evidence
        ↓
allow coexistence or block corpus
```

## Test coverage

ML-8 tests include:

- frozen policy validity;
- nested policy tampering;
- exact-duplicate weakening;
- similarity-threshold weakening;
- negation-token weakening;
- automatic numeric reconciliation;
- unresolved contradiction weakening;
- human-review disabling;
- signal-set binding disabling;
- drift invalidation weakening;
- deterministic normalization;
- exact duplicate detection;
- near-duplicate detection;
- concept-assisted duplicate detection;
- polarity conflict;
- legal-status conflict;
- numerical conflict;
- unit mismatch non-reconciliation;
- edition drift;
- deterministic pair key;
- deterministic comparison fingerprint;
- valid adjudication evidence;
- canonical pair ordering;
- invalid fingerprints;
- unknown/duplicate signals;
- invalid reviewer roles;
- review-date ordering;
- exact duplicate hard block;
- missing adjudication;
- valid coexistence adjudication;
- confirmed duplicate block;
- pending review;
- fingerprint drift;
- signal drift;
- orphan adjudication;
- active-version collision;
- superseded-record exclusion;
- numeric conflict;
- legal-status coexistence decision;
- polarity contradiction block;
- concept concentration audit;
- authority concentration audit;
- adjudication expiry;
- adjudication chronology;
- fail-closed evidence schema.

## Deliberately deferred

ML-8 does not:

- author the production 120-fact bank;
- alter the startup UI;
- store facts in a runtime repository;
- select which fact appears;
- track impression history;
- implement learner personalization.

Those remain ML-9 onward.

## Verification

From repository root:

```powershell
dart run tool/validate_micro_learning_corpus_integrity_gates.dart
```

Expected output begins:

```text
ML-8 DUPLICATE / CONTRADICTION DETECTION VALID
```

## Exit criteria

- [x] Frozen ML-8 policy created.
- [x] Deterministic local normalization created.
- [x] Exact duplicates hard-blocked.
- [x] Near-duplicate candidate detection created.
- [x] Concept-assisted overlap detection created.
- [x] Same-source overlap detection created.
- [x] Polarity-conflict detection created.
- [x] Legal-status conflict detection created.
- [x] Numerical conflict detection created.
- [x] No automatic unit conversion.
- [x] Edition-drift detection created.
- [x] Human pairwise adjudication schema created.
- [x] Canonical pair ordering enforced.
- [x] Exact fact fingerprints enforced.
- [x] Exact signal-set binding enforced.
- [x] Blocking and coexistence decisions separated.
- [x] Adjudication chronology enforced.
- [x] Adjudication expiry enforced.
- [x] Orphan evidence rejected.
- [x] Active-version collisions rejected.
- [x] Superseded/withdrawn/rejected records excluded from active comparison.
- [x] Concentration audit created.
- [x] Concentration audit remains non-blocking in ML-8.
- [x] No runtime AI added.
- [x] No backend read added.
- [x] No production MicroFacts generated.
- [x] No startup UI changed.

## Next run

ML-9 - First 120-Fact Curated Bank.

ML-9 may begin only after ML-8 closes green on one exact SHA.
