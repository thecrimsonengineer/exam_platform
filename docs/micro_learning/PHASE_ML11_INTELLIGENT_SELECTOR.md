# CSP11 Phase ML-11 — Intelligent MicroFact Selector

Status: IN PROGRESS

Base recovery point: `phase-ml10-local-runtime-repository-closed`

Working branch: `phase-ml11-intelligent-selector`

## Objective

Select one startup MicroFact from the ML-10 local eligible corpus using deterministic rotation and conservative diversity rules without adding network reads, persistence, learner-state scoring, or UI ownership.

## Phase boundary

ML-11 owns selection logic only.

It does not own:

- MicroFact persistence or impression-history storage;
- learner mastery/readiness weighting;
- startup card rendering;
- startup animation choreography;
- authentication/navigation;
- remote content refresh.

Those remain assigned to later ML phases.

## Inputs

The selector accepts:

- the ordered ML-10 locally eligible MicroFact list;
- a deterministic `rotationOrdinal`;
- optional recent MicroFact IDs supplied by a future history layer;
- optional active-assessment concept IDs.

## Hard eligibility boundary

The selector independently refuses facts unless:

```text
status == published
runtime.startupEligible == true
```

ML-10 remains the authoritative local repository and freshness gate.

## Assessment leakage rule

If an active-assessment concept overlaps a fact's linked assessment concepts and the fact has any non-`none` assessment sensitivity, the fact is excluded.

If all candidates are blocked by assessment overlap, ML-11 returns no fact.

It does not weaken this rule to fill a startup slot.

## Repetition rule

ML-11 accepts up to 12 recent unique MicroFact IDs.

When alternatives exist, those IDs are excluded.

If every assessment-safe candidate is recent, ML-11 may reuse the corpus rather than return no fact. The result records:

```text
ML11_RECENCY_FALLBACK
```

Persistent impression history remains ML-15.

## Diversity rule

Recent history is used only as an input signal.

Candidate ordering prefers lower recent exposure to:

1. category;
2. source authority;
3. curriculum concepts.

The final tie-break remains deterministic.

## Rotation rule

With no recent-history or assessment exclusions, one complete rotation cycle must expose each eligible fact exactly once.

The frozen ML-10 release corpus therefore requires:

```text
rotationOrdinal 0..119 -> 120 unique MicroFacts
```

The selector builds a deterministic balanced ordering that:

- avoids consecutive categories when alternatives exist;
- avoids consecutive source authorities within the selected category when alternatives exist;
- proportionally spreads larger categories across the cycle;
- uses stable MicroFact IDs as the final deterministic tie-break.

No random-number generator is used.

## Runtime behavior

```text
ML-10 eligible list
        |
        v
runtime state filter
        |
        v
active-assessment exclusion
        |
        v
recent-ID suppression
        |
        v
category/source/concept diversity score
        |
        v
deterministic rotation ordinal
        |
        v
one MicroFact / no_fact
```

## Diagnostics

Possible selector diagnostics include:

- `ML11_NO_RUNTIME_ELIGIBLE_FACT`
- `ML11_NO_ASSESSMENT_SAFE_FACT`
- `ML11_RECENCY_FALLBACK`

Diagnostics contain no learner PII and no source-content excerpts.

## Tests

Unit validation covers:

- deterministic replay;
- complete-cycle uniqueness;
- recent-ID suppression;
- category/source diversity;
- active-assessment exclusion;
- no-fact behavior when all facts conflict with active assessment;
- bounded recency fallback;
- rejection of non-published or startup-disabled facts.

Runtime-corpus validation loads the real ML-10 bundle and requires:

- 120 eligible facts;
- 120 unique selections across ordinals 0 through 119;
- all 10 production categories represented.

## ML-11 exit criteria

- [ ] selector is pure and deterministic;
- [ ] zero network or persistence dependencies are introduced;
- [ ] 120-fact real-corpus cycle covers all 120 exactly once;
- [ ] assessment overlap fails closed;
- [ ] recent IDs are suppressed when alternatives exist;
- [ ] category/source/concept diversity is deterministic;
- [ ] empty or invalid runtime pools return no fact;
- [ ] ML-10 repository regression remains green;
- [ ] startup independence regression remains green;
- [ ] exact closing SHA is validated;
- [ ] immutable ML-11 recovery branch is created.

## Next phase

ML-12 — Startup MicroFactCard.

ML-12 may consume the ML-11 selection result and render it on startup. It must never hold navigation for reading completion and must preserve the existing startup watchdog and fail-open behavior.
