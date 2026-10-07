# CSP11 REL-GOV-1 Versioning and Release Identity Contract

Status: IMPLEMENTATION IN PROGRESS
Phase: REL-GOV-1
Parent checkpoint: phase-rel-gov0-governance-freeze-closed
Parent SHA: edc5a51456b1c06635b67e0a73d2d22f6358315b

## Contract

CSP11 governed versions use:

```
MAJOR.MINOR.PATCH+BUILD
```

Examples:

```
1.0.0+1
1.0.1+2
1.1.0+3
2.0.0+100
```

## Rules

1. MAJOR, MINOR, PATCH and BUILD are base-10 non-negative integers.
2. MAJOR, MINOR and PATCH may not contain leading zeroes unless the value is exactly 0.
3. BUILD may not contain leading zeroes unless the value is exactly 0.
4. A governed version must include +BUILD.
5. Prefixes such as v1.0.0+1 are invalid.
6. Whitespace is invalid.
7. Pre-release suffixes are outside the initial REL-GOV-1 version parser. Release-candidate identity is expressed separately through releaseId.
8. versionName is MAJOR.MINOR.PATCH.
9. fullVersion is MAJOR.MINOR.PATCH+BUILD.
10. Release identity is deterministic from parsed version plus explicit candidate ordinal.

## Release ID

Release candidate IDs use:

```
csp11-MAJOR.MINOR.PATCH-rc.N
```

where N is a positive integer.

Example:

```
csp11-1.2.0-rc.1
```

## Build progression

For governed sequential releases, a new build number must be greater than the previous governed build number.

```
newBuild > previousBuild
```

Equality or regression is invalid.

## Machine identity fields

REL-GOV-1 provides:
- major
- minor
- patch
- buildNumber
- versionName
- fullVersion
- releaseId

Git SHA, tree SHA and manifest SHA-256 are added by later REL-GOV runs.

## Blocking conditions

The following are blocking:
- malformed version
- missing build number
- leading zero
- negative-like syntax
- unexpected prefix
- whitespace
- non-numeric component
- candidate ordinal less than 1
- non-increasing governed build number

## Next checkpoint

```
phase-rel-gov1-version-contract-closed
```
