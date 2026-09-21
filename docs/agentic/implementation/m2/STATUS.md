# M2 implementation status

Frozen plan: 7a59205c550af5cc36a2c233513fc21b4f780e64.
Phase base: d6a20c988027bdc25aeddc041cc16849bc259ad6.
Status: RUN_1_REVIEW_REPAIR_COMMITTED; local validation pending; M2 remains open.

## Run 1: M2-1 through M2-3

- M2-1 remains unchanged: strict immutable task packet, canonical scope validation, canonical JSON and SHA-256 identity, and bounded repair declarations.
- M2-2 repair: human approval authority is now resolved only from trustedState.humanApprovals by exact packet identity. A caller-created approval object cannot grant authority. The trusted task registry must contain exactly one PlanTaskSnapshot matching M2 phase, branch, base SHA, risk, allowed/forbidden paths, targeted tests, stop conditions and governance version.
- M2-2 continues to reuse M1 lineage, writer lease, fencing, branch, ancestry and repository checks. The packet itself was not revised, so its approved hash remains unchanged.
- M2-3 remains deterministic and unchanged: trusted repository inventory plus exact packet/candidate gate receipts are required for DO_HANDOFF.

## Independent review

The first committed candidate at 3d5e9b24c50775ca90ba18e7027de942765052cc was REVIEW_REPAIRABLE.

Findings repaired here:

1. Caller-shaped HumanApprovalSnapshot could previously be presented through M2ApprovedManifest.
2. M2 authority previously did not require the packet to match the trusted Control Plane task registry.

The repair intentionally leaves human_approval_reference as a descriptive audit reference because the already-authorized packet uses descriptive text rather than an approval ID. Runtime authority instead requires exactly one active trusted approval matching approval type, task ID, packet hash, packet revision and governance version.

## Validation state

The prior candidate had 97 passing PDCA test executions and analyzer exit 0 with 409 infos, 0 warnings and 0 errors.

This review repair adds adversarial coverage for:

- absent and duplicate trusted approval records;
- forged hash, revision and approval type;
- revoked, future, expired and time-revoked approvals;
- caller-shaped approval objects that are absent from trustedState;
- missing and duplicate task registry entries;
- phase, branch, base, risk, scope, tests, stop-condition and governance mismatches;
- future-observed task state;
- revised packet reuse against original approval/task state.

Local formatter, targeted/full tests, analyzer and diff-check must be rerun on the committed repair SHA before REVIEW_ACCEPTED.

## Remaining limitations

Authority remains a preflight control, not an OS sandbox or mutation executor. Repository reads are drift-checked rather than transactionally locked. Gate-receipt provenance is a trusted interface whose concrete lifecycle remains to be completed before Pilot A acceptance. M2-4, M2-5, M2-6, Pilot A lifecycle repair, and Pilot B remain pending.

No application code, backend, dependencies, frozen governance, M1 controls, M2 packet revision, M2 closure or M2-4 implementation is authorized by this repair.
