# CSP11 Agentic PDCA Governance v1.0 - Freeze Manifest

**Freeze authorization:** Explicit human instruction to freeze the approved PDCA governance.  
**Governance version:** v1.0  
**Source design branch:** `agentic-pdca-design`  
**Source design SHA:** `e938d777551166cc72a3627af5523706fafcc272`  
**Closed checkpoint branch:** `agentic-pdca-governance-v1-closed`  
**Implementation status:** NOT STARTED

## Normative frozen set

- `docs/agentic/v1/CANONICAL_CONTROL_MODEL.md`
- `docs/agentic/v1/PLAN.md`
- `docs/agentic/v1/DO.md`
- `docs/agentic/v1/CHECK.md`
- `docs/agentic/v1/ACT.md`
- `docs/agentic/v1/PHASE_AUTOPILOT_CONTRACT.md`
- `docs/agentic/v1/README.md`

## Supporting audit evidence retained in repository history

- Cross-PDCA consistency audit
- Adversarial cross-state audit
- Final PDCA conformance audit

## Frozen core invariants

- Prior frozen capabilities are PRESERVE BY DEFAULT.
- The phase is the intended autonomous execution unit at sufficient system maturity.
- Normal agents cannot declare or create phase closure autonomously.
- Candidate Green, Review Accepted, Closure Eligible, and Closed remain distinct.
- Trusted Judge Set cannot be silently weakened by the candidate.
- Repair budgets are lineage-based and centrally controlled.
- Security/data incidents bypass normal repair.
- Exact-SHA human approval is required for final phase closure.
- ACT feeds verified learning into the next PLAN.
- Governance changes require a new approved governance version.

## Operational caveat

This freeze establishes the **design contract**. It does not claim operational proof.

The first implementation must begin at low maturity and prove the controls through executable tests before higher autonomy is enabled.
