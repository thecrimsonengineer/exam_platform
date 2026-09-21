# Agentic PDCA M1-001 Mechanical Preparation

Base: `94d060e37358915d03a2375ebc3af54808633e15`
Maturity: M1 = DO-1 + CHECK-1/2 + ACT-1

This slice prepares, but does not execute, low-risk mechanical automation.

## DO-1 eligibility

The classifier accepts only:

- formatting;
- imports;
- simple analyzer fixes;
- safe test-harness corrections.

Feature behavior, architecture, security, backend, and other non-mechanical work is escalated. Test weakening, unknown actions, invalid base identities, and paths outside the declared allow-list are rejected fail-closed.

## Action plans

An accepted plan records the task ID, lineage ID, exact base SHA, allowed paths, action class, planned command/action, expected changed paths, and required validation gates. Plans explicitly state that execution is not performed.

## Boundary

M1-001 does not execute commands, mutate Git, issue leases, route repairs, authorize protected actions, weaken tests, or close phases. M0 observation controls remain unchanged and protected capabilities remain unavailable.
