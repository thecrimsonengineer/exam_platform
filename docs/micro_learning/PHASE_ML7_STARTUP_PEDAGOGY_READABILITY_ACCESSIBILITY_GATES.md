# CSP11 Phase ML-7 - Startup Pedagogy / Readability / Accessibility Gates

Status: IMPLEMENTED  
Parent: `docs/micro_learning/PHASE_ML6_CANONICAL_CURRICULUM_MAPPING_GATES.md`  
Branch: `phase-ml7-startup-pedagogy-readability-accessibility-gates`

## Purpose

ML-7 determines whether an otherwise valid MicroFact is suitable for a short startup learning surface.

ML-1 through ML-6 establish authority, structure, sourcing, factual/legal semantics, rights/provenance and curriculum placement.

ML-7 asks:

> Can a learner understand this fact quickly and accurately without needing animation, color, an icon, a gesture, hidden context or a long reading window?

ML-7 does not redesign the startup screen. It establishes content eligibility rules before the first production fact bank is authored.

## Delivered artifacts

- `content/micro_learning/startup_pedagogy_policy_v1.json`
- `content/micro_learning/startup_pedagogy_evidence_schema_v1.json`
- `lib/services/micro_learning/startup_text_metrics.dart`
- `lib/services/micro_learning/startup_pedagogy_policy_validator.dart`
- `lib/services/micro_learning/startup_pedagogy_evidence_validator.dart`
- `lib/services/micro_learning/micro_fact_startup_suitability_gate_validator.dart`
- `test/fixtures/micro_learning/valid_startup_pedagogy_evidence_v1.json`
- ML-7 policy, evidence, metric, fact-gate and startup-contract tests
- `tool/validate_micro_learning_startup_suitability_gates.dart`
- this closure document

## Startup contract alignment

ML-7 is bound to the existing startup-motion implementation:

```text
Full motion        4800 ms
Reduced motion      250 ms
Fail-open ceiling  7000 ms
```

Micro-learning may not:

- add artificial startup delay;
- block startup completion;
- add a fact-only network read;
- depend on Lottie completion;
- depend on animation to communicate meaning.

The short variant is the primary startup copy.

The full `displayText` remains useful for later detail surfaces and review evidence.

## Frozen text limits

These limits are CSP11 product controls. They are not claimed as universal laws of pedagogy.

### Full displayText

- minimum 6 words
- maximum 32 words
- maximum 260 characters
- maximum 2 sentences
- maximum declared read time 10 seconds

### Startup shortVariant

For every `startupEligible=true` fact:

- shortVariant is mandatory
- minimum 4 words
- maximum 18 words
- maximum 140 characters
- maximum 1 sentence
- maximum computed read time 6 seconds
- must contain fewer words than displayText
- may contain at most 75% of the full-text word count

This forces genuine compression rather than relabeling the same sentence as “short”.

## Reading-time metric

ML-7 uses a deterministic product metric:

```text
150 words per minute
computed seconds = ceil(words × 60 / 150)
```

`estimatedReadSeconds` must remain within two seconds of that computed value.

This is a validation heuristic for consistency. It is not a claim that every learner reads at 150 wpm.

## Plain-text startup copy

Startup copy may not contain:

- line breaks
- tabs
- HTML
- Markdown links
- raw URLs
- emoji
- bullet/list prefixes
- `Source:` / `Reference:` style prefixes
- repeated spaces
- repeated punctuation

Source attribution remains in structured provenance metadata rather than being jammed into the few seconds available for startup learning.

## Parenthetical and punctuation control

Startup copy is limited to one parenthetical group.

Question-form text is reserved for:

```text
think_about_it
```

Other categories must use declarative startup wording.

## All-caps jargon gate

Unknown all-caps tokens fail closed.

A frozen allowlist covers common safety and CSP abbreviations such as:

- CSP
- OSHA
- NIOSH
- ANSI
- ASSP
- ISO
- NFPA
- ACGIH
- AIHA
- EPA
- DOT
- PHMSA
- FMCSA
- FEMA
- DHS
- NIMS
- ICS
- CCPS
- NSC
- PPE
- PSM
- LOTO
- NEC
- BEST

This avoids startup copy such as unexplained internal acronyms.

A later content revision may amend the frozen allowlist deliberately if a legitimate abbreviation is required.

## Visual independence

A MicroFact must make sense without:

- color;
- icon recognition;
- animation;
- position;
- touch gestures.

Blocked language includes patterns such as:

- shown above
- shown below
- as shown
- the icon
- watch the animation
- tap the
- click the
- swipe
- the highlighted

This supports screen readers and reduced-motion presentation.

## Reduced-motion equivalence

The existing startup system disables Lottie and ambient motion in reduced mode.

ML-7 therefore requires human confirmation that:

```text
reducedMotionEquivalentConfirmed = true
```

The learning meaning cannot live only inside movement.

## Screen-reader independence

The evidence record separately requires:

```text
screenReaderStandaloneConfirmed = true
visualIndependenceConfirmed = true
plainLanguageAccessibleConfirmed = true
noForcedInteractionConfirmed = true
```

This does not replace the later ML-16 runtime accessibility phase.

ML-7 validates content suitability. ML-16 will validate the final rendered component and semantics behavior.

## No forced interaction

Startup facts are informational.

They may not require the learner to:

- tap;
- click;
- swipe;
- answer before continuing;
- respond within a timer;
- interact to reveal essential meaning.

The application continues whenever secure startup is ready.

## Assessment leakage

These assessment sensitivities are blocked from startup eligibility:

```text
high
block_during_linked_assessment
```

The deterministic text gate also blocks obvious answer-key language such as:

```text
the correct answer is...
the best answer is...
option B is...
choose option C
```

Human pedagogy evidence additionally requires:

```text
assessmentLeakageReviewed = true
```

ML-7 therefore reduces the risk that passive startup exposure gives away linked assessment content.

## Precision preservation

The short variant must remain pedagogically simpler without becoming technically weaker.

Human pedagogy review requires:

- singleConceptConfirmed
- standaloneMeaningConfirmed
- cognitiveLoadAcceptable
- jargonLoadAcceptable
- shortVariantMeaningPreserved
- precisionPreserved
- assessmentLeakageReviewed

For safety-critical, numerical, medium-simplification-risk or high-simplification-risk claims, precision and short-copy meaning confirmation are explicitly rechecked.

ML-4 remains responsible for legal-status semantics.

ML-7 does not replace ML-4 with a readability shortcut.

## Dual human review

A passing startup evidence record contains two distinct review tracks.

### Pedagogy review

Approved roles:

- pedagogy_reviewer
- content_governance_reviewer
- subject_matter_reviewer

### Accessibility review

Approved roles:

- accessibility_reviewer
- content_governance_reviewer

Both tracks must be `pass` for startup-eligible validated/published content.

The same trained content-governance reviewer may perform both attestations, but they remain separate checks in the evidence record.

## Exact content fingerprint

ML-7 evidence binds to:

- microFactId
- contentVersion
- pedagogyPolicyVersion
- SHA-256 of displayText
- SHA-256 of shortVariant
- estimatedReadSeconds
- recomputed word counts
- recomputed sentence counts
- recomputed read-time metrics

Changing even one learner-facing string invalidates the old review evidence.

This prevents a copy edit from retaining stale pedagogy/accessibility approval.

## Evidence chronology

ML-7 rejects evidence when:

- startup review occurs after the final MicroFact review;
- evidence was already overdue at final review;
- evidence is older than the frozen 365-day maximum.

For startup-eligible validated and published facts:

- pedagogy evidence must pass;
- accessibility evidence must pass;
- MicroFact `review.pedagogyStatus` must pass;
- MicroFact `review.uiStatus` must pass.

## Non-startup MicroFacts

If:

```text
runtime.startupEligible = false
```

ML-7 does not require a startup pedagogy evidence record.

The fact still remains subject to ML-1 through ML-6 and whatever non-startup quality rules apply elsewhere.

This keeps the gate scoped to the loading-screen use case.

## Local-only behavior

ML-7 adds no runtime dependency.

It introduces:

- no Firebase read;
- no Supabase read;
- no HTTP call;
- no remote readability service;
- no runtime LLM judgment.

All deterministic checks can run locally.

## What machines check

ML-7 deterministically checks:

- word count
- character count
- sentence count
- computed read time
- declared read-time consistency
- short-copy compression
- plain-text cleanliness
- parenthetical load
- repeated punctuation
- category/question-form compatibility
- all-caps jargon allowlist
- visual-dependency phrases
- obvious answer-key language
- assessment sensitivity
- exact evidence fingerprints
- exact stored metric consistency
- review chronology
- evidence age

## What remains human-reviewed

ML-7 does not pretend an algorithm can reliably prove:

- that the fact teaches exactly one coherent concept;
- that a learner can understand the meaning without hidden context;
- that technical jargon load is appropriate;
- that shortening preserved nuance;
- that cognitive load is acceptable;
- that screen-reader wording is genuinely understandable;
- that reduced-motion wording communicates equivalent meaning;
- that a safety-critical simplification preserved necessary precision.

Those judgments remain explicit human attestations.

## Cross-surface contract tests

ML-7 tests bind the policy to the existing startup implementation.

They verify:

- full startup duration remains 4800 ms;
- reduced startup duration remains 250 ms;
- the startup screen retains its seven-second fail-open ceiling;
- reduced mode has Lottie disabled;
- reduced mode has ambient animation disabled;
- ML-7 requires reduced-motion meaning equivalence.

A startup-motion change that invalidates these assumptions must update ML-7 deliberately rather than silently.

## Test coverage

ML-7 includes adversarial coverage for:

- unknown policy fields;
- artificial startup delay;
- runtime network-read enabling;
- short-copy word-limit weakening;
- short-copy compression weakening;
- HTML enabling;
- motion-dependent meaning;
- assessment-sensitivity weakening;
- precision-review weakening;
- reduced-motion equivalence weakening;
- evidence-age weakening;
- drift-rule weakening;
- deterministic word/sentence/read-time metrics;
- source/format clutter detection;
- answer-key detection;
- valid evidence;
- unknown evidence fields;
- invalid hashes;
- partial metrics;
- failed human pedagogy attestations;
- failed human accessibility attestations;
- unapproved reviewer roles;
- reversed review dates;
- wrong policy version;
- valid startup MicroFact;
- non-startup evidence exemption;
- missing startup evidence;
- missing short variant;
- excessive short copy;
- insufficient short-copy compression;
- excessive full text;
- inconsistent estimated read time;
- line breaks;
- unknown all-caps jargon;
- visual-position dependency;
- question form outside reflective category;
- answer-key language;
- high assessment sensitivity;
- evidence replay across facts;
- display-text fingerprint drift;
- metric drift;
- MicroFact pedagogy/UI review state;
- dual-review pass requirement;
- startup review after final review;
- stale evidence;
- safety-critical precision review;
- formal fail-closed evidence schema;
- live startup timing contract alignment.

## Deliberately deferred

ML-7 does not implement:

- duplicate/contradiction detection - ML-8;
- production fact-bank authoring - ML-9;
- local production repository - ML-10;
- intelligent selector - ML-11;
- final MicroFactCard UI - ML-12;
- MicroFact animation choreography - ML-13;
- learner-state weighting - ML-14;
- impression history - ML-15;
- final rendered accessibility acceptance - ML-16.

## Verification

From repository root:

```powershell
dart run tool/validate_micro_learning_startup_suitability_gates.dart
```

Expected output begins:

```text
ML-7 STARTUP PEDAGOGY / READABILITY / ACCESSIBILITY GATES VALID
```

## Exit criteria

- [x] Frozen startup pedagogy policy created.
- [x] ML-7 bound to current startup timing contract.
- [x] No artificial startup delay permitted.
- [x] No runtime fact-only network read permitted.
- [x] Full-text word/character/sentence limits frozen.
- [x] Short-copy word/character/sentence limits frozen.
- [x] Deterministic reading-time metric frozen.
- [x] Short-copy compression enforced.
- [x] Plain-text-only startup copy enforced.
- [x] Unknown all-caps jargon blocked.
- [x] Visual-dependency language blocked.
- [x] Assessment answer-key language blocked.
- [x] High-sensitivity assessment content blocked.
- [x] Separate pedagogy evidence schema created.
- [x] SHA-256 learner-text fingerprint enforced.
- [x] Stored metrics recomputed from actual text.
- [x] Human pedagogy review required.
- [x] Human accessibility review required.
- [x] Safety-critical precision preservation reviewed.
- [x] Reduced-motion equivalence reviewed.
- [x] Screen-reader independence reviewed.
- [x] Evidence chronology and freshness enforced.
- [x] ML-1 through ML-6 remain prerequisites.
- [x] Existing startup reduced-motion behavior preserved.
- [x] No production MicroFacts generated.
- [x] No startup UI changed.
- [x] No backend path added.

## Next run

ML-8 - Duplicate / Contradiction Detection.

ML-8 should prevent the future 120-fact bank from accumulating near-duplicates, contradictory claims, stale superseded wording or concept collisions that would confuse learners.
