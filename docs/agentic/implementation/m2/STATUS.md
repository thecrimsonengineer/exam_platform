# M2 implementation status

Frozen plan: 7a59205c550af5cc36a2c233513fc21b4f780e64.
Phase base: d6a20c988027bdc25aeddc041cc16849bc259ad6.
Status: CHECK_REVIEW_ACCEPTED; exact-SHA final CHECK pending; M2 remains open.

## M2 maturity target

M2 = DO-2 + CHECK-2/3 + ACT-2.

No M3 or M4 capability is authorized by this checkpoint.

## Accepted checkpoints

### M2-1 through M2-3

Task packet, bounded authority and deterministic handoff are accepted.

Run 1 final accepted checkpoint:
95d64b2c4b64b0f4381009e38d00c1a698f5a86c.

The initial review found two trust-boundary defects:
- caller-shaped human approval;
- missing trusted task-registry binding.

Both were repaired before acceptance.

### M2-4 CHECK-3 independent reviewer

Accepted after hardening at:
5ad6fd505fec16af2496a4526a06c9ada3b64333.

CHECK-3:
- is read-only;
- binds exact candidate and Control Plane lineage;
- independently verifies DO handoff evidence;
- invokes integrity checking;
- rejects Builder self-review;
- exposes only REVIEW_ACCEPTED, REVIEW_REPAIRABLE or REVIEW_ESCALATE.

### M2-5 ACT-2 bounded repair routing

Accepted at:
5a7c524dc481168931f09521b4ec6ce97ef65495.

ACT-2:
- routes only retry, repair or escalate;
- owns lineage-scoped repair budgets;
- does not reset budget when controller or repair agent changes;
- distinguishes same-SHA retry from new-SHA repair;
- rejects zero-budget and forbidden classes;
- rejects repeated identical repair/retry strategies;
- has no closure route.

### M2-6 adversarial and integrity hardening

Accepted at:
d5357ea04d5760554690dd5e10b52f23506bb3a0.

Coverage includes:
- packet mutation;
- stale/expired approval;
- self-review;
- cancellation;
- protected and traversal paths;
- skipped tests;
- dependency/config drift;
- patch inventory mismatch;
- assertion weakening;
- secret-like material;
- cross-state DO/CHECK/ACT evidence failures.

GitHub validation run 35586178938 passed all M2-6 gates.

### M2-7 Pilot A

Pilot A lifecycle proof is accepted at:
8ada71ce7b86f52a6916d1b6102a27933efba5b0.

GitHub exact-SHA validation run 35586629747 passed all gates.

Pilot A proved:
- approved packet -> DO-2 authority;
- first candidate -> deterministic handoff;
- CHECK-3 REVIEW_REPAIRABLE;
- ACT-2 F4 repair authorization and budget consumption;
- new candidate SHA;
- fresh handoff/evidence;
- CHECK-3 REVIEW_ACCEPTED;
- stale first-candidate evidence rejected;
- no autonomous closure route.

## M2-8/M2-9 Pilot B

Task:
M2-PILOT-B-FC8-A11Y-1.

Approved packet proposal commit:
65f9bc9a96836962a06d02ac26f1167f8ccc76ca.

Approved canonical packet hash:
8e4c2c3da43390f65ea207500159c26e2b90da1aae615002e495600400ecb1f8.

Approved task base:
8ada71ce7b86f52a6916d1b6102a27933efba5b0.

Explicit human approval was supplied in chat on 2026-09-21 and persisted in
repository status at:
644828cd5dd495f2f4deeccdeaf9178ac8a07f76.

The packet JSON was not mutated after approval, preserving the approved hash.

### Pilot B implementation

Accepted candidate:
45da604bb6886d5746023d754dbf760fffdc5592.

Production change:
- three semantics-only lines in
  lib/screens/flashcards/widgets/flashcard_card_view.dart;
- actionable source footer now exposes:
  "Activate to view source details.";
- non-actionable source footer exposes no action hint;
- visible UI and source navigation behavior remain unchanged.

Required Pilot B net paths exactly match the approved packet:
- docs/agentic/implementation/m2/PILOT_B_PACKET.json
- docs/agentic/implementation/m2/STATUS.md
- lib/screens/flashcards/widgets/flashcard_card_view.dart
- test/features/flashcards/ui/flashcard_card_accessibility_test.dart

### Pilot B repair history

An early candidate was reverted because repository approval evidence had not
yet been persisted. It is not accepted evidence.

After approval binding, the implementation itself required no behavioral
repair.

Two F5 test-harness repairs were used:
1. align semantics assertions with Flutter's merged FlipCard semantics node;
2. explicitly dispose SemanticsHandle instances before Flutter end-of-test
   verification.

F5 remains within its packet budget.

### Pilot B validation

GitHub exact-SHA validation run 35588375793 passed:
- exact candidate checkout and ancestry;
- formatting;
- 136 Agentic PDCA tests;
- Flashcard accessibility widget test;
- existing Flashcard review-player regression;
- FC6 architecture test;
- FC7 architecture test;
- analyzer with warnings/errors fatal;
- M1 architecture gate;
- diff integrity;
- known generated-file restoration only;
- clean exact-SHA checkout.

Independent CHECK-3 result:
REVIEW_ACCEPTED.

## M2 final closure preparation

All frozen M2 capability requirements are implemented:
- canonical task packet;
- DO-2 bounded authority;
- deterministic handoff;
- retained/hardened CHECK-2;
- independent read-only CHECK-3;
- ACT-2 bounded repair routing and lineage budgets;
- adversarial cross-state coverage;
- accepted Pilot A;
- accepted real application Pilot B.

The final status-bearing SHA created by this status update must now undergo a
fresh exact-SHA final CHECK across the whole M2 phase from M1 closed.

If that final CHECK is green and no new finding appears, the permitted state is:

CHECK_REVIEW_ACCEPTED
-> CHECK_FINAL_GREEN
-> ACT_CLOSURE_ELIGIBLE
-> ACT_HUMAN_CLOSURE_PENDING

Only explicit human approval bound to that exact final SHA may permit
agentic-pdca-m2-closed creation/protection and ACT_CLOSED.

No production merge is implied by M2 closure.
