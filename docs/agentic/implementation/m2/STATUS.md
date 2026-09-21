# M2 implementation status

Frozen plan: `7a59205c550af5cc36a2c233513fc21b4f780e64`.
Phase base: `d6a20c988027bdc25aeddc041cc16849bc259ad6`.
Status: RUN_1_CANDIDATE; M2 remains open.

## Run 1: M2-1 through M2-3

- M2-1: strict immutable task packet, required fields, canonical scope validation, conservative Pilot A envelope, canonical JSON and SHA-256 identity; bounded repair-class budget declarations. Parsing never grants authorization.
- M2-2: approved packet manifest bound to an exact hash/revision and trusted human approval snapshot; reuses M1 mechanical authority's branch, lineage, lease and fencing checks as a precondition for bounded Pilot A feature authority. Detects dirty tracked/untracked state, cancellation, conflicting writers, stale approvals, wrong ancestry and branch movement. No general command or mutation executor.
- M2-3: deterministic handoff using trusted repository inventory, commit list, diff statistics and exact packet/candidate gate receipts. Missing, stale or red receipts result in CHECK_NOT_READY. A handoff is not review acceptance.
- M1 repository/path/authority/gate implementations remain unchanged. The M2 workspace composes the M1 repository and adds fixed read-only Git operations for untracked files and handoff inventory, with raw path consistency checks.

## Validation before candidate commit

- Targeted and full PDCA tests: 97 passing executions, including 22 new M2 tests and all existing 75 M0/M1 executions.
- A disposable synthetic Git repository verifies staged/unstaged cancellation, untracked files, commit lists and changed-file inventory.
- Analyzer: exit 0; 409 infos, 0 warnings, 0 errors with `--no-fatal-infos --fatal-warnings`.
- Formatter and diff check pass.
- Independent read-only review is pending at the committed candidate SHA; no self-issued REVIEW_ACCEPTED.

## Trust and limitations

This run implements the control contracts and authority preflight. Runtime composition must provide trusted M0 state, current approvals/leases and gate receipts; JSON from a Builder is never such authority. Test approvals and receipts are explicitly synthetic. No live M0 approval or lease event is fabricated for this bootstrap implementation.

The conservative packet validator accepts explicit M2 Dart file paths and canonical directory `/**` patterns within the M2 documentation subtree. It rejects broader implementation globs and application paths. Pilot B is unavailable until separately authorized and implemented.

Authority is a preflight decision, not an OS sandbox or file writer. Repository reads are checked for drift but are not atomic locks. No durable authority/repair store, automatic feature executor, reviewer verdict pipeline or autonomous closure is claimed.

M2-4 (review contract), M2-5 (ACT-2), the remaining M2-6 adversarial cases and M2-7 lifecycle pilot remain for the next bounded run. Pilot A's intentional controlled repair loop has not yet run. M2-8 requires separate human authorization of a concrete application packet after Pilot A passes. No application, backend, dependency, frozen-governance or M1 control changes are included.
