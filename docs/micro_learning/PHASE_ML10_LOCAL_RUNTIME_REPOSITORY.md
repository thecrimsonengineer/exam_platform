# CSP11 Phase ML-10 — Local Runtime Repository

Status: IN PROGRESS

Base recovery point: `phase-ml9f-publication-freeze-closed`

Working branch: `phase-ml10-runtime-consumption-rotation`

## Objective

Make the frozen ML-9F 120-fact production corpus available to startup through a single local Flutter asset with zero fact-only network reads.

ML-10 owns local runtime packaging and local eligibility loading only. Intelligent selection and repetition control remain ML-11 responsibilities.

## Frozen boundaries

1. Production source content remains the closed ML-9F corpus.
2. ML-10 must not rewrite MicroFact wording, provenance, curriculum mapping, review evidence, or lifecycle state.
3. Startup fact retrieval must use bundled assets only.
4. No Firebase, Supabase, HTTP, or other backend read may be introduced solely to obtain a startup fact.
5. Repository failure collapses to a no-fact state.
6. Structural bundle corruption fails closed.
7. Review-due or stale facts are excluded locally without blocking startup.
8. Only `published` plus `startupEligible=true` facts may be returned.
9. The repository must preserve deterministic ordering for ML-11.
10. Startup navigation remains owned by the secure auth path.

## Runtime bundle

Generated artifact:

```text
content/micro_learning/ml10_runtime_bundle_v1.json
```

The bundle is generated from:

```text
content/micro_learning/ml9f_production_manifest_v1.json
content/micro_learning/facts/*.json
```

The generator is deterministic and supports byte-stability verification:

```powershell
dart run tool/generate_ml10_runtime_bundle.dart
dart run tool/generate_ml10_runtime_bundle.dart --check
```

## Repository

Runtime service:

```text
lib/services/micro_learning/local_micro_fact_repository.dart
```

The repository performs exactly one local asset read for the MicroFact bundle.

It validates:

- bundle schema/version identity;
- frozen ML-9F publication SHA binding;
- exactly 120 bundled records;
- MicroFact v1 schema;
- unique MicroFact IDs;
- published lifecycle;
- startup eligibility;
- all final fact-review statuses;
- source verification chronology;
- review-due chronology;
- maximum 365-day source-verification age.

Expected runtime behavior:

```text
valid + current fact -> eligible list
review due / stale  -> exclude fact
bundle corruption   -> zero eligible facts
asset read failure  -> zero eligible facts
```

No repository error owns navigation or startup failure.

## ML-10 exit criteria

- [ ] deterministic runtime bundle generated from ML-9F;
- [ ] byte-stability gate passes;
- [ ] one-read local repository implemented;
- [ ] exactly 120 current facts load at the release checkpoint;
- [ ] stale fact exclusion is tested;
- [ ] corrupted fact causes fail-closed empty result;
- [ ] asset failure causes fail-soft no-fact result;
- [ ] startup regression remains green;
- [ ] exact closing SHA validated;
- [ ] immutable ML-10 recovery branch created.

## Next phase

ML-11 — Intelligent Selector.

ML-11 will consume the ordered eligible list from ML-10 and add deterministic rotation, diversity, assessment-sensitivity exclusion, and repetition rules. It must not add a network dependency.
