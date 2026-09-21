# Agentic PDCA validation harness

This branch is isolated validation infrastructure. It is not merged into M2 candidates.

Update TARGET_SHA and BASE_SHA to request deterministic validation. The workflow detaches at the exact target SHA and verifies ancestry, format, the full agentic PDCA test suite, analyzer severity policy, architecture gate, diff integrity, and clean-worktree state.

Current request:
- target: c5fa12f2441871caab5164be05eaa443c18d2cef
- base: 7a59205c550af5cc36a2c233513fc21b4f780e64
