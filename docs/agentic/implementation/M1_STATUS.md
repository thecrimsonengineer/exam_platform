# Agentic PDCA M1 Status

Status: CHECK_REVIEW_ACCEPTED; analyzer normalized; exact-SHA final CHECK pending. M1 is not closed.
Independent review: CHECK_REVIEW_ACCEPTED
Maturity: M1 = DO-1 + CHECK-1/2 + ACT-1
M0 base: `94d060e37358915d03a2375ebc3af54808633e15`
V3 input: `ea0f51a948366a82f5f44bf75e57f9374e11be47`
Publication branch: `agentic-pdca-m1-001`

## Final binding repair

- CHECK identity: the runner receives a trusted repository and fixed expected candidate/base identities at construction. A CHECK request supplies no candidate facts, comparison facts, or dirty paths. Repository HEAD supplies the evidence identity. Pre/post HEAD, merge-base, and dirty tracked state must satisfy the contract; failed preconditions prevent command execution.
- CHECK working directory: every fixed gate uses the same direct process invocation with `workingDirectory: repository.root` and `runInShell: false`. Flutter gates invoke the installed Flutter tools snapshot through Dart, avoiding Windows batch-shell execution. No request controls executable, arguments, or working directory.
- CHECK-2: both scan paths use `M1RepositoryPathGuard`; canonical glob descendants are accepted, sibling/prefix tricks, traversal, absolute paths and backslashes are rejected. Unknown dirty tracked paths block even inside the allow-list. Generated validation paths are available separately through `generatedSideEffects`; CHECK-1 records them in evidence. Git reads staged and unstaged tracked paths separately using NUL delimiters, including cancelling index/worktree edits.
- DO-1: actual repository ref must equal the requested lease branch and be nonempty. Trusted lineage task, lineage ID and current SHA must match the request. Repository HEAD, lease expected HEAD and requested expected HEAD must agree, with exact approved M0 ancestry. FORMAT rechecks HEAD, branch and ancestry immediately before mutation.
- ACT-1: a central process-lifetime repair-budget store initializes each lineage once from the trusted M0 budget snapshot. New stores/controllers and writer handles share its authoritative balance and history. Reinitializing with the original snapshot does not replenish it. Unknown lineages fail closed. Same-SHA infrastructure retries consume zero; a mechanical repair requires a different exact candidate SHA and consumes one. Unsupported failure classes escalate; there is no closure route.
- Architecture gate: the fixed test executes the authority, CHECK and path boundary suites, plus M0 capability denial, actual ACT routing, unsupported executor operations and traversal denial. It includes a real CHECK formatter process that leaves an unformatted fixture unchanged, and a denied DO-1 FORMAT call.

## Validation evidence before commit

- Agentic suite: 75 passing test executions, including boundary cases repeated by the dedicated architecture gate.
- Original M0 regression: all 19 tests passed; original M0 test file unchanged.
- Dart format: 16 files, zero further changes.
- Policy proof in a fresh checkout at `ea803e8ab7e0274bbe40b03e6c7de184594cbf86`: `flutter analyze --no-fatal-infos --fatal-warnings` returned exit 0, 409 infos, 0 warnings, 0 errors.
- Analyzer policy: infos advisory; warnings blocking; errors blocking. The fixed ANALYZE argument list and evidence command use these exact flags. No request can supply flags; nonzero trusted analyzer exits still produce CHECK red.
- No informational lint cleanup, suppression, or analysis_options.yaml change.
- `git diff --check`: passed.
- Merge-base: exact approved M0 SHA.
- Only the three authorized directory trees contain repair changes.
- Seven known Flutter registration paths appeared dirty with no semantic diff; restoration is restricted to those exact paths.
- The committed SHA must additionally be validated in a fresh disposable checkout after all commits and publication; final SHA, checkout results and remote equality are reported with delivery, not inferred from this precommit record.

## Remaining limitations

- The trusted composition root owns repository/command adapters, approved identities, M0 snapshots and SDK environment. They are not untrusted request fields.
- Budget authority is shared within one Dart isolate/process lifetime. Durable cross-process or distributed budget coordination is not implemented; restarting the host requires an authoritative current snapshot. This does not claim M2 persistence.
- FORMAT is the only implemented mutation. Import, analyzer and harness transformations remain explicitly unsupported by the executor.
- Repository reads and execution are sequential checks, not an OS-level atomic repository lock.
- Generated-file restoration belongs to the external validation harness; CHECK itself does not repair or restore files.
- Repository-wide informational analyzer findings remain. Informational severity is advisory under the accepted M1 analyzer policy; warnings and errors remain fatal.

M1 remains open and unprotected. No M1 closed branch, closure authority, M2 work, or protected capability is introduced.
