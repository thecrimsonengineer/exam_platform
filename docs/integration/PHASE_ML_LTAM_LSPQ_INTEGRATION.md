# CSP11 ML-LTAM × LSP-Q Integration

Status: FROZEN FOR IMPLEMENTATION

Working branch: `phase-ml-ltam-lspq-integration`

## Frozen source checkpoints

ML-LTAM source:

```text
phase-ml-ltam-integration-closed
49d0f7d69d8338e3bb09b12444c09a641886e67a
validation run 35955880471
```

LSP-Q source:

```text
phase-lsp-q17-closed
af0dfd673daee2e7081e7c35828c88ae9a43aca4
validation run 35954257324
```

Historical merge base:

```text
56cf3031709ca2ff9da81d48d8ede47bb589ee51
```

## Integration objective

Create one validated CSP11 baseline containing the frozen ML-1 through ML-13 runtime, the closed ML-LTAM presentation bridge, and the complete LSP-Q0 through LSP-Q17 production LAB stack.

This phase is an integration and preservation phase. It must not redesign either frozen source stream.

## ML-14 hold rule

The existing branch:

```text
phase-ml14-learner-state-weighting
```

must not advance from its current SHA while this integration remains open.

ML-14 may continue only after:

```text
phase-ml-ltam-lspq-integration-closed
```

exists and has a successful exact-SHA cross-stream validation run.

At that point ML-14 must be restarted or rebased from the closed combined integration checkpoint. No ML-14 implementation commit may be based solely on the old ML-LTAM checkpoint.

## Frozen ownership boundaries

ML owns MicroFact wording, authority, provenance, publication state, startup eligibility, local runtime repository, deterministic selection, assessment leakage blocking, and startup choreography.

Learning Twin owns the canonical avatar identity, avatar assets, static fallback, and future LTAM motion policy and renderer.

LSP-Q owns canonical LAB question parsing, evidence-backed rationale, H0.3 and DQG300 quality gates, learner presentation validation, population manifest, publication, learner catalogue, persistent LAB repositories, production seed, release closure, release operator, deployment preflight, and immutable acceptance.

## Frozen invariants

- 120 production MicroFacts remain unchanged.
- Learning Twin domain files remain unchanged during this integration.
- MicroFact surfaces remain static until LTAM-4/5 are implemented and validated.
- 10 production LAB scenarios remain preserved.
- 50 LAB decisions remain preserved.
- Firebase production environment remains `firebase_project:csp11-exam-platform`.
- Frozen LSP release ID remains `phase_l_population_v1_q15_release_v1`.
- CI must never execute the live Q17 acceptance action.
- Q17 acceptance remains an explicit authenticated administrator action.
- No LAB repository read becomes a startup dependency.
- No LAB outcome may influence ML selection in this phase.
- No MicroFact state may influence LAB decisions in this phase.

## Integration strategy

The working branch is created from the ML-LTAM closed SHA.

LSP-Q17 is then merged with full history preservation. Squashing and manual reconstruction of Q1-Q17 are forbidden.

Repository comparison at planning time showed the two frozen streams were diverged but had no overlapping post-base changed files. Any merge conflict is therefore treated as a stop condition requiring explicit inspection.

## Implementation sequence

```text
INT-LQ0  Freeze source identities, boundaries and ML-14 hold
INT-LQ1  History-preserving LSP-Q17 convergence
INT-LQ2  Static and compile compatibility
INT-LQ3  LSP-Q1-Q17 preservation regression
INT-LQ4  ML-LTAM preservation regression
INT-LQ5  Shared runtime seam validation
INT-LQ6  Firebase and security convergence
INT-LQ7  Dedicated cross-stream CI and full repository regression
INT-LQ8  Exact-SHA freeze and closed recovery branch
```

## Closure rule

The phase closes only after the exact final integration SHA passes the dedicated cross-stream workflow including LSP-Q1-Q17, Studio regressions, ML runtime regressions, Learning Twin regressions, startup motion/handoff, Firestore contract checks, full repository regression, diff hygiene, and formatting.

Final recovery branch:

```text
phase-ml-ltam-lspq-integration-closed
```

Only after that branch exists may ML-14 move forward.
