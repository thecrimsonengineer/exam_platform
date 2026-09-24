# CSP11 REL-GOV-8 GitHub Release-Candidate CI Contract

Status: IMPLEMENTED CANDIDATE
Phase: REL-GOV-8
Repository: thecrimsonengineer/exam_platform
Base checkpoint: phase-rel-gov7-release-evidence-closed
Base commit: 44cff317f2728380e702bca9e65ad3e7dee9b122
Date: 2026-09-24

## 1. Purpose

REL-GOV-8 turns the frozen REL-GOV contracts into a manually initiated GitHub Actions release-candidate pipeline.

It builds governed candidate artifacts and evidence. It does not publish them.

## 2. Trigger

The initial trigger is only:

```
workflow_dispatch
```

There is no push or pull-request trigger.

A human explicitly chooses the Git ref from which the workflow is dispatched.

The workflow then checks out the immutable `github.sha` for that dispatch. It does not re-resolve a moving branch tip later in the job.

## 3. Permissions

The workflow declares:

```
permissions:
  contents: read
```

Checkout uses:

```
persist-credentials: false
```

REL-GOV-8 therefore does not require repository-write credentials.

## 4. Frozen toolchain

The candidate environment policy pins:

```
Repository                thecrimsonengineer/exam_platform
Flutter                   3.44.9
Dart                      3.12.2
Java runtime              17.0.16
Gradle                    9.1.0
Android Gradle Plugin     9.0.1
Kotlin                    2.3.20
Java target               17
Kotlin JVM target         17
Runner OS                 linux
Runner architecture       X64
```

The build-environment inspector captures the actual runtime evidence.

The candidate-input assembler applies REL-GOV-6 validation against the frozen toolchain policy before generating an admissible input.

Runner OS patch version remains evidence but is intentionally not pinned.

## 5. Pipeline

The frozen sequence is:

```
manual dispatch
-> reject empty build selection
-> exact SHA checkout
-> pinned Java
-> pinned Flutter
-> locked dependency validation
-> governed version validation
-> format gate
-> analyze gate
-> dedicated REL-GOV regression
-> full Flutter regression
-> repository identity and cleanliness gate
-> selected candidate builds
-> candidate input assembly
-> REL-GOV-7 evidence generation
-> require ADMISSIBLE
-> REL-GOV-7 evidence verification
-> evidence and candidate artifact upload
```

A failing step stops the job.

## 6. Dependency gate

The workflow uses:

```
flutter pub get --enforce-lockfile
```

and then requires no diff in:

```
pubspec.yaml
pubspec.lock
```

The dependency evidence subsequently records the SHA-256 identity of both files through REL-GOV-6 and REL-GOV-7.

## 7. Repository gate

Before candidate builds, the workflow proves:

- checked-out HEAD equals `GITHUB_SHA`
- tracked diff is empty
- Git porcelain status is empty

The typed candidate-input assembler performs a second provenance check after builds.

The second check permits detached HEAD because exact-SHA Actions checkout is expected, but it still requires:

- correct repository identity
- exact expected commit SHA
- clean worktree

## 8. Candidate build selection

Manual inputs select:

```
build_android
build_web
```

At least one must be true.

Android produces:

```
build/release-candidate/csp11-android-release.apk
```

Web produces:

```
build/release-candidate/csp11-web-release.tar.gz
```

The Web archive uses stable file ordering, epoch mtime, numeric ownership and fixed ownership metadata.

Windows is not built in REL-GOV-8 because the initial governed job runs on Ubuntu.

## 9. Android signing status

The current repository still configures the Android release build with the debug signing configuration.

REL-GOV-8 therefore treats its Android APK only as a governed release-candidate artifact.

It is not represented as Google Play ready or production signed.

Production signing and public publication remain outside this phase.

## 10. Candidate evidence input

The helper:

```
tool/release_governance/release_candidate_input.dart
```

collects:

- repository provenance
- build-environment fingerprint
- governed version
- artifact inventory and SHA-256
- test evidence
- application component checkpoint
- canonical admission-gate evidence references

It rejects repository drift, environment drift, an empty artifact inventory and malformed candidate parameters.

## 11. Admission

REL-GOV-8 does not invent a new admission decision.

It builds the canonical 17 REL-GOV gate records and passes them to the REL-GOV-7 generator.

REL-GOV-7 then calls the frozen REL-GOV-4 admission policy.

The workflow explicitly requires:

```
decision=ADMISSIBLE
```

before evidence upload.

## 12. Evidence bundle

The uploaded GitHub Actions artifact contains:

```
build/release-candidate/
build/release-evidence/
build/release-governance-input/candidate_input.json
build/release-governance-input/ci_evidence/
```

The final 11-file `build/release-evidence/` directory remains subject to the REL-GOV-7 exact package-shape verifier.

CI logs and gate transcripts are kept outside that exact package so they do not invalidate its deterministic shape.

## 13. Explicit non-publication boundary

REL-GOV-8 does not:

- create a GitHub Release
- create or push a Git tag
- push commits
- deploy Firebase
- deploy Supabase
- upload to Google Play
- upload to an app store
- deploy the Web build publicly
- alter production data or infrastructure

The workflow only uploads a private GitHub Actions workflow artifact for later governed review.

## 14. Exit criteria

REL-GOV-8 may close only when:

```
base checkpoint exact
manual-only workflow present
read-only permissions present
exact-SHA checkout present
toolchain policy frozen
dependency lock gate present
format gate present
analyzer gate present
REL-GOV regression present
full Flutter regression present
repository gate present
selected candidate build controls present
artifact inventory and SHA-256 binding present
REL-GOV-7 generation present
ADMISSIBLE requirement present
evidence verification present
Actions artifact upload present
publication commands absent
workflow contract tests green
format green
analyzer green
full REL-GOV regression green
repository diff limited to REL-GOV-8
blocking implementation failures = 0
```

Closure checkpoint:

```
phase-rel-gov8-release-candidate-ci-closed
```

Next frozen phase:

```
REL-GOV-9 -> Release Candidate Review and Recovery Contract
```
