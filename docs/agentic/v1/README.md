# CSP11 Agentic PDCA Governance v1.0

**Status:** FROZEN  
**Source design branch:** `agentic-pdca-design`  
**Source design SHA:** `e938d777551166cc72a3627af5523706fafcc272`  
**Normative closed branch:** `agentic-pdca-governance-v1-closed`

This directory is the frozen v1.0 governance set for the CSP11 agentic engineering system.

## Normative documents

1. `CANONICAL_CONTROL_MODEL.md`
2. `PLAN.md`
3. `DO.md`
4. `CHECK.md`
5. `ACT.md`
6. `PHASE_AUTOPILOT_CONTRACT.md`

The Canonical Control Model governs state ownership, authority hierarchy, repair budgets, approvals, validation tiers, judge integrity, closure semantics, adversarial hardening, PDCA conformance, and the relationship between all stage documents.

The Phase Autopilot Contract makes the **phase** the primary autonomous execution unit once the implementation reaches the required maturity. Its target successful stop state is `ACT_HUMAN_CLOSURE_PENDING`.

## Frozen design intent

A user should ultimately be able to give a phase-level instruction such as:

~~~text
Start/continue Phase X
~~~

and the system will:

~~~text
recover latest frozen baseline
→ inventory and preserve prior capabilities
→ build the phase task graph
→ dispatch isolated agents
→ validate each task
→ repair bounded failures
→ integrate accepted work
→ run current + inherited regression gates
→ independently review
→ prepare status/evidence
→ validate exact final SHA
→ stop at ACT_HUMAN_CLOSURE_PENDING
~~~

Final phase closure remains bound to explicit human approval of the exact validated SHA.

## Change control

This v1.0 governance is frozen.

Future changes require:

~~~text
governance proposal
→ evidence
→ review
→ explicit human approval
→ new governance version
~~~

Do not edit this v1.0 set in place to make a current phase easier to pass.
