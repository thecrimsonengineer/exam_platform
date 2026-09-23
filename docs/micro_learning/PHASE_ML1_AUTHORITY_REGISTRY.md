# CSP11 Phase ML-1 — Authority Registry

Status: IMPLEMENTED  
Parent: `docs/micro_learning/PHASE_ML0_ARCHITECTURE_FREEZE.md`  
Branch: `phase-ml1-authority-registry`

## Purpose

ML-1 converts the ML-0 source whitelist into a machine-readable, fail-closed authority registry.

This run does not create micro-facts, the MicroFact schema, startup UI, selector logic, backend synchronization, or general micro-fact source-gate enforcement.

## Delivered artifacts

- `content/micro_learning/authority_registry_v1.json`
- `lib/services/micro_learning/authority_registry_validator.dart`
- `tool/validate_micro_learning_authority_registry.dart`
- `test/micro_learning/authority_registry_validator_test.dart`

## Frozen authority families

The registry contains exactly 15 source families:

1. OSHA / U.S. Department of Labor
2. NIOSH / CDC
3. ANSI / ASSP standards
4. ISO
5. NFPA
6. ACGIH
7. AIHA
8. EPA
9. DOT / PHMSA / FMCSA
10. FEMA / DHS / NIMS / ICS
11. AIChE / CCPS
12. National Safety Council
13. ASSP professional literature
14. FM / FM Global
15. UL Standards & Engagement / UL Solutions

No unlisted source family is valid.

## Fail-closed policy

ML-1 freezes these rules:

- first-party sources only;
- AI is never an authority;
- an unlisted authority is blocked;
- a secondary summary cannot replace an available primary authority;
- authority type is mandatory;
- source/claim class is mandatory;
- jurisdiction must be retained when material;
- edition or revision context must be retained when applicable;
- a source verification date is mandatory.

## Registry metadata

Each authority entry records:

- stable `SRC-##` identifier;
- canonical and display names;
- authority kind;
- regulatory-authority flag;
- jurisdiction scopes;
- official first-party hosts;
- official HTTPS entry points;
- permitted source classes;
- permitted subject areas;
- edition/revision policy;
- review cadence;
- source verification date;
- prohibited attribution patterns.

## Frozen source classes

- `federal_regulation`
- `regulatory_interpretation`
- `enforcement_or_compliance_guidance`
- `government_recommendation`
- `research_or_prevention_guidance`
- `consensus_standard`
- `international_standard`
- `professional_guideline`
- `professional_framework`
- `environmental_regulation`
- `transportation_regulation`
- `emergency_management_framework`
- `process_safety_framework`
- `loss_prevention_guidance`
- `testing_or_certification_standard`

These classes are not legally equivalent. Later fact validation must preserve the distinction.

## Frozen edition policies

- `continuous_regulatory_check`
- `revision_tracked`
- `annual_or_revision_check`
- `publication_specific`

Exact fact-level freshness handling remains a later quality-gate responsibility.

## Protected semantic distinctions

The registry is designed to prevent:

- NIOSH recommendations from being presented as OSHA requirements;
- ACGIH TLVs/BEIs from being presented as OSHA PELs;
- ANSI/ASSP, ISO, NFPA or UL standards from being presented as federal law without an applicable adoption/legal source;
- CCPS RBPS from being treated as interchangeable with OSHA PSM;
- FM loss-prevention guidance from being presented as statutory compliance;
- UL listing/certification from being presented as regulatory approval;
- FEMA/NIMS/ICS concepts from being presented as OSHA regulation.

## Validator behavior

The ML-1 validator rejects, among other conditions:

- malformed registry JSON;
- weakened fail-closed policy;
- missing frozen authority families;
- additional unapproved authority families;
- duplicate authority IDs;
- invalid official-host syntax;
- entry points outside declared first-party hosts;
- unknown source classes;
- disabled first-party requirements;
- unknown edition policies;
- invalid review cadence;
- absent or malformed verification dates.

## Runtime boundary

The registry is deliberately not wired into startup assets in ML-1.

Runtime repository wiring belongs to ML-10. Fact provenance enforcement begins only after ML-2 establishes the MicroFact schema and ML-3 implements source gates.

## Verification

From repository root:

```powershell
dart run tool/validate_micro_learning_authority_registry.dart
flutter test test/micro_learning/authority_registry_validator_test.dart
```

Expected CLI result:

```text
ML-1 authority registry VALID
Approved authority families: 15
```

## Exit criteria

- [x] Exactly 15 frozen authority families represented.
- [x] Stable registry IDs defined.
- [x] First-party hosts and entry points recorded.
- [x] Regulatory-authority distinction recorded.
- [x] Jurisdiction scopes recorded.
- [x] Permitted source classes frozen.
- [x] Permitted subject areas recorded.
- [x] Edition/revision policy recorded.
- [x] Review cadence recorded.
- [x] Prohibited authority distortions recorded.
- [x] Fail-closed validator implemented.
- [x] Negative validator tests defined.
- [x] No micro-facts generated.
- [x] No startup runtime behavior changed.
- [x] No backend read/write path added.

## Next run

ML-2 — MicroFact Schema.

ML-2 must define the versioned fact object that references `sourceRegistryId` from this registry and may not weaken ML-0 or ML-1.
