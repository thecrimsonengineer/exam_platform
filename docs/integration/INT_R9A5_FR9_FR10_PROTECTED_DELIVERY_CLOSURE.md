# INT-R9A5 FR9 / FR10 Protected Delivery Regression Closure

## Status

**CLOSURE CANDIDATE**

Working branch:

`phase-home-startup-integration-auth-hotfix-r9a5`

R9A4 recovery checkpoint:

`phase-home-startup-integration-auth-hotfix-r9a4-closed`

R9A4 closure SHA:

`a84132b41bd94cb75531a3efe7d53243970a8329`

Validated R9A5 candidate SHA:

`23b5fb4c7c54dedd2f83350166841ec4f47eef2d`

Successful GitHub Actions run:

`35811344254`

Workflow:

`INT-R9A5 FR9 FR10 Protected Delivery Regression`

## Purpose

INT-R9A5 verifies that the authorization packaging hotfix did not weaken or bypass the frozen FR9 protected question-delivery path or the frozen FR10 protected StudyContent-delivery path.

This run is validation-only. No learner runtime code, delivery gateway code, cache policy, Home behavior, Startup behavior, or authorization behavior was changed.

## Regression results

The exact-SHA workflow passed all of the following gates:

1. frozen Home + Startup integration ancestry;
2. R9A4 authorization-hotfix ancestry;
3. dependency lockfile stability;
4. repository analysis using the inherited FR analyzer policy;
5. FR8 online authorization boundary replay;
6. FR9 protected question package validation;
7. FR9 UID-scoped protected question cache;
8. FR9 Edge gateway security architecture;
9. FR9 QuizService cutover;
10. FR9 practice-mode cutover;
11. FR10 protected StudyContent package validation;
12. FR10 UID-scoped protected content-package cache;
13. FR10 delivery-service and session-refresh regressions;
14. FR10 content gateway security;
15. FR10 StudyContentLoader cutover;
16. FR10 canonical navigation and broad-read retirement;
17. FR10 final closure architecture gate;
18. live production missing-token and malformed-token fail-closed checks for both FR9 and FR10 operations;
19. sanitized evidence upload;
20. clean repository verification.

All passed.

## Security properties reconfirmed

The green workflow reconfirms:

`FR8_AUTHORIZATION_BOUNDARY_REPLAYED=true`

`FR9_PACKAGE_INTEGRITY_REPLAYED=true`

`FR9_UID_SCOPED_CACHE_REPLAYED=true`

`FR9_QUIZ_AND_PRACTICE_CUTOVER_REPLAYED=true`

`FR10_PACKAGE_INTEGRITY_REPLAYED=true`

`FR10_UID_SCOPED_CACHE_REPLAYED=true`

`FR10_DELIVERY_SERVICE_REPLAYED=true`

`FR10_BROAD_READ_RETIREMENT_REPLAYED=true`

`FR10_CLOSURE_GATE_REPLAYED=true`

`FR9_MISSING_TOKEN_FAILS_CLOSED=true`

`FR9_MALFORMED_TOKEN_FAILS_CLOSED=true`

`FR10_MISSING_TOKEN_FAILS_CLOSED=true`

`FR10_MALFORMED_TOKEN_FAILS_CLOSED=true`

`PRODUCTION_RUNTIME_CHANGED=false`

`SERVER_SECRET_REQUIRED=false`

## Evidence artifact

Artifact name:

`INT-R9A5-protected-delivery-evidence`

Artifact ID:

`10730025945`

Artifact digest:

`sha256:0c53e875c419a38075bc6b62810ae143fe77d65f720c3b92bf8cdf2d67f11009`

## Harness corrections during execution

Two early workflow attempts stopped before proving the protected-delivery chain.

First, the new R9A5 workflow used `flutter analyze` while the frozen FR workflow uses `flutter analyze --no-fatal-infos`. The repository contains pre-existing informational lints, so the R9A5 harness was aligned to the frozen FR analyzer policy. No Dart production source was changed.

Second, the initial R9A5 workflow referenced a nonexistent test path:

`test/services/questions/learner_question_package_delivery_service_test.dart`

The frozen tree does not contain that file. The invalid invocation was removed after confirming that all intended FR9 architecture, package, cache, gateway, QuizService, and practice-mode tests exist. No production source was changed.

## Closure rule

This closure document is itself included in the R9A5 workflow trigger.

INT-R9A5 is fully closed only after this closure commit receives a successful exact-SHA R9A5 workflow run. After that exact-SHA pass, freeze:

`phase-home-startup-integration-auth-hotfix-r9a5-closed`

at the closure commit and do not advance it.

Next planned run after closure:

**INT-R9A6 — Integrated Release Candidate Regression**
