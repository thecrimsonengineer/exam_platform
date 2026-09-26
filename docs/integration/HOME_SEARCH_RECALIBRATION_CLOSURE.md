# Home Search Recalibration Closure

Status: CLOSED CANDIDATE

## Baseline

The work begins from the immutable integrated application checkpoint:

```text
phase-lab-fcc-fcp12-integrated-closed
f0f02da4f7e56df439f836962944b16f5bd572bb
```

Working branch:

```text
phase-home-search-recalibration
```

## Root cause

The Home search presentation remained in the frozen Home information architecture, but its default runtime still depended on `StudyContentLoader.loadPublishedContent()`.

FR10E deliberately retired broad learner StudyContent reads. The former default path therefore failed closed with `UnsupportedError` in the protected learner runtime.

The recalibration does not restore broad client reads.

## Protected runtime architecture

Production Home search now follows:

```text
Firebase-authenticated learner
-> online authorization boundary
-> current Firebase ID token
-> Supabase learner-content-search Edge Function
-> service-role-only search_published_study_content RPC
-> precomputed published_study_search_index
-> bounded search results
-> exact Domain / Competency / Topic / Subtopic navigation
```

The Edge Function independently verifies Firebase JWT issuer, audience and signature. Missing or malformed Firebase tokens fail closed.

The search RPC and search-index table are not executable/readable by `anon` or `authenticated`; they remain behind the server-side boundary.

## Published search authority

The index is built only from current immutable content packages in `published_packages` and their exact `metadata.sourceVersion` rows in `content_versions`.

Current production index:

```text
47 published competency packages
16,194 indexed learner-facing search fields
```

The index includes learner-facing:

- subtopic titles
- learning objectives
- main content
- key points
- key takeaways
- exam tips
- workplace examples
- common mistakes
- case studies
- formulas
- learner-visible references
- topic context
- competency context
- Domain context

`CSP source traceability` reference payloads remain excluded from learner search.

## Ranking recalibration

Ranking is deterministic and favors direct learner intent:

```text
Subtopic title        1100
Learning objective     940
Main content           840
Key point              820
Key takeaway           810
Exam tip               790
Workplace example      770
Common mistake         750
Case study              740
Formula                 720
Topic context           700
Reference               650
Competency title        640
Competency ID           620
Domain title            580
Domain ID               560
```

Match bonuses:

```text
exact normalized match       +500
starts-with phrase           +420
whole phrase                 +340
all-token prefix match       +220
compact punctuation match    +180
```

Normalization covers case, punctuation, ampersands and Unicode subscript digits, so searches such as `H2S` can match learner content containing `H₂S` and `lockout` can match punctuation variants such as `lock-out`.

Context-only matches are capped to avoid flooding the result list.

## Interaction recalibration

The Home search panel now:

- waits for at least two characters
- debounces typing by 240 ms
- removes stale results immediately when the query changes
- ignores late responses from superseded queries
- keeps Clear available while a request is active
- cancels visible state on Clear so an old response cannot reappear
- supports immediate keyboard Search submission
- provides a visible Retry action after transport/backend errors
- preserves the result set when navigation temporarily removes focus
- limits the learner result list to eight by default
- preserves the frozen Home placement in both light and dark themes

## Navigation

Search results preserve canonical route identity.

Light Home binds exact Domain, Competency, Topic and Subtopic.

Dark Home preserves its frozen routing seam and binds the exact Domain, Competency and Subtopic; the dark study renderer resolves the target subtopic inside its published competency payload.

Returning from a search result refreshes Home learning state.

## Production performance hardening

The first live implementation traversed every published JSON payload on each search and exceeded the PostgREST statement timeout.

The final runtime moves that expensive traversal into `refresh_published_study_search_index()` and performs learner queries against the precomputed table.

Production index inventory after refresh:

```text
indexed rows: 16,194
competencies: 47
subtopics: 1,227
```

A production `EXPLAIN ANALYZE` for `hierarchy of controls` completed in approximately 815 ms at the database layer, well below the previous timeout path.

The refresh function is service-role-only and is the controlled synchronization point to run after future content publication changes.

## Automated validation

Primary green run:

```text
GitHub Actions run: 36241119427
Result: SUCCESS
```

Passed:

- canonical formatting
- scoped Flutter analyzer
- 12 search-ranking/service regressions
- 4 search interaction regressions
- 4 light/dark Home search contract regressions
- 6 frozen Home R9 information-architecture regressions
- 4 StudyContent loader regressions
- learner public configuration gate
- live Firebase-authenticated Home search production smoke
- diff hygiene

## Live learner production smoke

The production smoke created a disposable Firebase learner, exercised the same Supabase search boundary used by the app, validated result identities and relevance, and deleted the learner afterward.

```text
HOME_SEARCH_FAIL_CLOSED=PASS
HOME_SEARCH_AUTH=PASS
HOME_SEARCH_RESULTS=PASS
HOME_SEARCH_ROUTE_IDENTITIES=PASS
HOME_SEARCH_RELEVANCE=PASS
HOME_SEARCH_PRODUCTION_SMOKE=SUCCESS
HOME_SEARCH_TEMP_LEARNER_CLEANUP=PASS
```

## Freeze rule

After this closure document itself passes the Home Search Recalibration Validation workflow, create:

```text
phase-home-search-recalibration-closed
```

Future search enhancements begin from that closed checkpoint. The completed LAB, FCC and FCP1/FCP2 phases remain closed and are not reopened by this work.
