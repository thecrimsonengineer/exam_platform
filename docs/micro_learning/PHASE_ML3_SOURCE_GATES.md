# CSP11 Phase ML-3 — Source Gates

Status: IMPLEMENTED  
Parent: `docs/micro_learning/PHASE_ML2_MICROFACT_SCHEMA.md`  
Branch: `phase-ml3-source-gates`

## Purpose

ML-3 connects MicroFact provenance to the frozen ML-1 Authority Registry.

ML-2 proved that provenance fields have the correct shape. ML-3 decides whether the referenced source is actually inside CSP11's approved authority boundary.

This run is deterministic and local. It performs no web request, DNS lookup, backend read or runtime network call.

## Delivered artifacts

- `lib/services/micro_learning/micro_fact_source_gate_validator.dart`
- `test/micro_learning/micro_fact_source_gate_validator_test.dart`
- `tool/validate_micro_learning_source_gates.dart`
- `docs/micro_learning/PHASE_ML3_SOURCE_GATES.md`

## Prerequisite composition

ML-3 fails closed unless both frozen prerequisites are already valid:

1. ML-1 Authority Registry validation
2. ML-2 MicroFact schema validation

A structurally invalid fact cannot be promoted by the source gate.

A malformed or weakened registry cannot be used to approve a fact.

## Registry-version binding

MicroFact v1 is bound to:

```text
Authority Registry 1.0.0
```

ML-3 rejects a registry with another version even when its JSON remains structurally valid.

This prevents the meaning of an approved `SRC-##` reference from changing silently beneath already-reviewed facts.

## Source membership gate

`provenance.sourceRegistryId` must resolve to one of the exact frozen ML-1 authority entries.

A well-shaped identifier such as `SRC-99` is still rejected when it is not present in the authority registry.

No implicit source family is accepted.

## First-party host gate

The source URL must:

- be absolute HTTPS;
- contain no embedded credentials;
- resolve syntactically to a host;
- match an official host registered for the selected authority, or a true subdomain of that host.

For example, for an authority host `osha.gov`:

```text
https://osha.gov/...             PASS
https://www.osha.gov/...         PASS
https://osha.gov.evil.example/   BLOCK
https://osha.gov-example.com/    BLOCK
https://example.com/osha/...     BLOCK
```

The comparison uses hostname boundaries. A string merely containing the trusted domain is not enough.

This is the primary ML-3 protection against substituting a blog, training provider, search result, forum, AI page or other secondary source while retaining an approved `SRC-##` label.

## Source-class compatibility gate

Each ML-1 authority lists its own permitted source classes.

ML-3 requires:

```text
MicroFact sourceClass ∈ Authority permittedSourceClasses
```

Examples:

- an OSHA source may not be labelled `professional_guideline`;
- NIOSH may not be labelled `federal_regulation`;
- ISO may not be labelled `environmental_regulation`;
- CCPS may not be labelled `federal_regulation`.

The deeper question of whether the wording and legal status accurately represent the specific source remains ML-4.

## Registry policy gate

ML-3 refuses a registry if the frozen source-policy foundation is weakened.

The source policy must continue to preserve:

- `failClosed=true`;
- `firstPartyOnly=true`;
- `unlistedAuthorityDisposition=block`;
- `secondarySummaryAsPrimarySource=false`;
- `aiIsAuthority=false`.

The ML-1 validator also remains a prerequisite and protects the rest of the frozen registry structure.

## Authority-state defense

The selected authority must remain active and first-party sourcing must remain required.

ML-1 currently freezes every registry authority as active with first-party sourcing required. ML-3 repeats these checks defensively so future registry evolution cannot silently weaken source trust.

## Verification chronology

ML-3 requires a fact's `sourceVerifiedAt` date to be on or after the selected authority entry's registry `verifiedAt` date.

This ensures a fact is not represented as verified against an authority registry state that did not yet exist.

When `sourcePublishedAt` is supplied, it must not be later than `sourceVerifiedAt`.

A source cannot logically have been verified before its stated publication date.

## All-authority coverage

The focused ML-3 tests dynamically exercise all 15 frozen authority families.

For each registry authority, the test creates a structurally valid MicroFact using:

- that authority's own `SRC-##`;
- one of its permitted source classes;
- one of its official first-party entry points;
- its registry verification date.

This protects ML-3 from accidentally becoming an OSHA-only validator.

## Threat cases explicitly tested

ML-3 tests include:

- unknown but well-shaped `SRC-99`;
- source-class mismatch;
- secondary-source substitution;
- trusted-domain suffix spoof;
- trusted-domain prefix spoof;
- valid registered subdomain;
- embedded URL credentials;
- weakened registry policy;
- wrong registry version;
- source verification predating registry verification;
- source publication after source verification;
- structurally invalid MicroFact;
- malformed registry JSON.

## Boundaries deliberately deferred to ML-4

ML-3 does not decide whether:

- a specific OSHA page is a regulation versus guidance;
- a NIOSH recommendation is described with correct non-regulatory wording;
- an ACGIH value has been misrepresented as an OSHA PEL;
- a consensus standard is falsely described as law;
- a legal-status field is compatible with the actual source class;
- jurisdiction wording is complete or accurate.

Those are factual and legal-status gates for ML-4.

## Boundaries deliberately deferred beyond ML-4

ML-3 also does not implement:

- copyright/provenance evidence rules — ML-5;
- canonical curriculum existence checks — ML-6;
- pedagogical/readability gates — ML-7;
- duplicate/contradiction detection — ML-8;
- production fact authoring — ML-9;
- runtime repository or startup UI — ML-10 onward.

## Verification

From repository root:

```powershell
dart run tool/validate_micro_learning_source_gates.dart
flutter test test/micro_learning/micro_fact_source_gate_validator_test.dart
```

Expected CLI output begins:

```text
ML-3 SOURCE GATES VALID
```

## Exit criteria

- [x] ML-1 registry validity is a prerequisite.
- [x] ML-2 MicroFact validity is a prerequisite.
- [x] Registry version binding is enforced.
- [x] `SRC-##` membership is enforced.
- [x] First-party HTTPS host matching is enforced.
- [x] True subdomains are accepted.
- [x] Domain-prefix/suffix spoofing is rejected.
- [x] Authority/source-class compatibility is enforced.
- [x] Weakened registry policy fails closed.
- [x] Authority active/first-party state is checked defensively.
- [x] Source verification chronology is enforced.
- [x] All 15 authority families are exercised by tests.
- [x] No external network request is added.
- [x] No production micro-facts are generated.
- [x] No startup UI is changed.
- [x] No backend path is added.

## Next run

ML-4 — Factual / Legal-Status Gates.

ML-4 must validate claim wording and legal-status semantics against the selected authority and source class without weakening ML-1 through ML-3.
