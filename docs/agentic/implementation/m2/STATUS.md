# M2 implementation status

Frozen plan: 7a59205c550af5cc36a2c233513fc21b4f780e64.
Phase base: d6a20c988027bdc25aeddc041cc16849bc259ad6.
Status: M2_PILOT_B_APPROVAL_PENDING; M2 remains open.

## Accepted governance checkpoints

- M2-1 through M2-3: REVIEW_ACCEPTED.
- M2-4 CHECK-3: REVIEW_ACCEPTED after independent hardening.
- M2-5 ACT-2: REVIEW_ACCEPTED.
- M2-6 adversarial/integrity hardening: REVIEW_ACCEPTED at
  d5357ea04d5760554690dd5e10b52f23506bb3a0.
- M2-7 Pilot A lifecycle proof: REVIEW_ACCEPTED at
  8ada71ce7b86f52a6916d1b6102a27933efba5b0 after GitHub exact-SHA
  validation run 35586629747 passed all gates.

## M2-8 Pilot B proposal

Pilot B is deliberately a real application change from the already-open FC8
hardening backlog, while remaining extremely narrow.

Feature:
Flashcard source-footer accessibility hardening.

Current behavior:
- the visible source footer is already present;
- when onSourceTap is provided, Semantics marks the footer as a button;
- the screen-reader label is the source label;
- no explicit action hint tells a screen-reader user what activating the
  source footer will do.

Proposed bounded behavior:
- keep all visible UI unchanged;
- keep current tap/navigation behavior unchanged;
- when onSourceTap is non-null, expose semantic hint:
  "Activate to view source details.";
- when onSourceTap is null, expose no button action and no action hint;
- add focused widget accessibility regression tests.

Allowed application path:
- lib/screens/flashcards/widgets/flashcard_card_view.dart

Allowed test path:
- test/features/flashcards/ui/flashcard_card_accessibility_test.dart

No other application files are authorized.

This packet is not approved yet. No lib/** mutation may occur until explicit
human approval is bound to this exact packet/commit.
