# M2 implementation status

Frozen plan: 7a59205c550af5cc36a2c233513fc21b4f780e64.
Phase base: d6a20c988027bdc25aeddc041cc16849bc259ad6.
Status: RUN_3_M2_5_CANDIDATE; M2 remains open.

## Accepted checkpoints

### Run 1: M2-1 through M2-3

REVIEW_ACCEPTED at exact SHA
95d64b2c4b64b0f4381009e38d00c1a698f5a86c.

### Run 2: M2-4 CHECK-3

REVIEW_ACCEPTED after independent hardening at exact SHA
5ad6fd505fec16af2496a4526a06c9ada3b64333.

GitHub exact-SHA validation run 35584469393 passed format, full Agentic PDCA
tests, analyzer severity policy, architecture gate, ancestry/diff integrity and
clean-checkout validation. The hardening binds the exact Control Plane lineage
candidate and independently verifies DO handoff commits, diff statistics,
targeted tests, architecture gates, gate results and evidence references.

## Run 3: M2-5 ACT-2 bounded repairs

RUN_3_PACKET.json is anchored to the accepted M2-4 SHA.

The candidate ACT-2 controller:
- routes only retry, repair or escalate;
- binds decisions to trusted task, lineage, packet approval and repair budget;
- requires exact trusted REVIEW_REPAIRABLE evidence for repairs;
- requires trusted transient-infrastructure evidence for retry;
- keeps retry on the same candidate SHA and consumes no repair budget;
- rejects repeated identical retry and repair strategies;
- reserves repair budget before mutation authorization;
- tracks per-class and aggregate category balances;
- keys budget/history by lineage rather than repair-agent identity;
- prevents higher stale/replayed snapshots from replenishing spent balance;
- records root cause, strategy, evidence, requested paths and remaining budget;
- rejects F6/F8/F9/F10 and invalid F7 autonomous repair;
- has no mutation executor and no closure route.

Current limitation: ACT-2 state is process-lifetime rather than durable
cross-process storage. M2-6 adversarial expansion, Pilot A lifecycle proof and
Pilot B remain pending.
