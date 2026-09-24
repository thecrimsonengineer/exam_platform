# FCP Competency-Run Execution Amendment

Status: FROZEN FOR FCP-2 AND LATER DOMAIN PRODUCTION  
Effective from: FCP-2  
Recovery base: `phase-fcp1-d01-closed@45d00a95dc6d8cb9e7c06db6df57bb71c5e17fe2`

## Decision

Beginning with FCP-2, one competency equals one production run.

Each competency run is independently recoverable and must be green before the next competency begins.

## Run contract

```text
canonical competency
→ concept inventory
→ concept resolution
→ source verification
→ learner-ready package
→ deterministic JSON round trip
→ FCQ100
→ provenance validation
→ duplicate report
→ coverage report
→ source report
→ validation summary
→ frozen Flashcard Core regression
→ full repository regression
→ immutable checkpoint
```

## FCP-2 run map

```text
FCP-2A  d02_c01
FCP-2B  d02_c02
FCP-2C  d02_c03
FCP-2D  d02_c04
FCP-2E  d02_c05
FCP-2F  d02_c06
FCP-2G  d02_c07
FCP-2H  d02_c08
FCP-2I  d02_c09
FCP-2J  d02_c10
FCP-2K  d02_c11
FCP-2L  d02_c12
FCP-2M  d02_c13
FCP-2N  d02_c14
```

Checkpoint naming is `phase-fcp2<letter>-d02-c<nn>-closed`.

FCP-2N also runs the cumulative D02 domain gate. After it passes, the same verified state may be checkpointed as `phase-fcp2-d02-closed`.

A closed competency checkpoint is immutable. Later cross-competency issues are recorded for FCP-8 unless a blocking defect requires an explicit corrective run.
