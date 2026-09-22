# Home R + Startup Motion Integration Closure

Status: FINAL INTEGRATION FREEZE CANDIDATE  
Phase: INT-R9 — Final Freeze + APK Delivery  
Working branch: `phase-home-startup-integration`

## Frozen lineage

Home R source:

- branch: `phase-home-r-closed`
- SHA: `243d9fdf93c55775321468eb17ce85cd3b7c557f`

Startup Motion source:

- branch: `phase-startup-motion-closed`
- SHA: `9c1697b1d01c8db85fe535bc77ea6b6aa6f39565`

Integration checkpoints:

- INT-R0: `949c12ceb0ce314fc9ab7c6673f046d8f36c7b6e`
- INT-R1: `0b27805ab6fe39ca023bdbcc6f2e180cca29c6ea`
- INT-R2: `633b37481551d595814408fd71d060b4661f5232`
- INT-R3: `1b9ea556640727a3c96a48f06e6fca987f5ab68a`
- INT-R4: `2cf55605cc526bdbae6ed974702e92826f28b1a5`
- INT-R5: `59932d84645008f215123dfb9400562c148779ad`
- INT-R6: `3437e069a0ae2a93305868eed1b4664c33a3eff8`
- INT-R7: `8147b397a601789a1190ddd53dc4cb219745602c`
- INT-R8: `774d591ecdbb871831551413fa004b352abb1e57`

## R8 release evidence

GitHub Actions run:

`35746986454`

Result: SUCCESS

The exact R8 SHA passed:

- integrated Startup → learner shell → Home R render gate
- strict integration formatting
- integrated analyzer scope
- Startup release-render smoke
- reduced-motion / fail-open / lifecycle hardening
- R5 behavioral seam
- R4 packaging contracts
- Android release APK build and packaged Startup asset verification
- Web release build and packaged Startup asset verification
- Windows release build and packaged Startup asset verification
- dedicated R8 platform closure job

## Integrated runtime architecture

```text
Application bootstrap
    ↓
single MaterialApp
    ↓
Csp11StartupScreen
    ↓
AuthGate
    ↓
LearnerAuthorizedShell
    ↓
BottomNavigationScreen
    ↓
HOME-R
```

There is one application root, one learner shell, and one Home destination.

Startup Motion remains a temporary presentation layer and does not own learner planning, completion, quiz state, or learning-position mutation.

## Final Home contract

```text
Hero
↓
Search CSP Content
↓
Continue CSP
↓
Today’s Plan
  Learn
  Practice
  Remember
↓
Progress Intelligence
↓
Exam Readiness
```

Bookmarks remain under:

`Settings → Learning & Progress`

Removed Home shortcuts remain removed.

## Responsive fixes captured during integration

INT-R7 exposed and fixed two real narrow-viewport render defects:

1. the Home loading row now flexes correctly on narrow mobile widths in light and dark Home
2. LAB scenario metadata now wraps instead of overflowing horizontally

Both fixes were covered by the integrated render/navigation verification.

## APK delivery contract

The INT-R9 APK workflow must build the Android release APK from the exact final freeze candidate SHA and verify:

- R8 SHA is an ancestor
- Home R and Startup Motion source SHAs are ancestors
- no production file changed after R8
- integrated Startup → Home render/navigation still passes
- `flutter build apk --release` succeeds
- the APK is non-empty
- `assets/flutter_assets/assets/startup/csp11_startup_master.json` is packaged
- the packaged Startup asset retains `CSP11 Startup Master SM-1`
- the APK itself is uploaded as a GitHub Actions artifact

## Android signing boundary

The current Android release configuration still uses the debug signing configuration.

Therefore the generated APK proves release-mode Flutter/AOT compilation, packaging, Startup asset inclusion, and integrated runtime compatibility. It is suitable for installation/testing but is not claimed to be Play Store production-signing ready.

## Final freeze policy

After the INT-R9 APK workflow is green on the exact final SHA:

- create `phase-home-startup-integration-closed` at that exact SHA
- do not develop directly on the closed branch
- preserve `phase-home-startup-integration-r8-closed` as the platform-recovery checkpoint
- preserve Home R and Startup Motion closed branches unchanged
- future work must branch from the final closed integration checkpoint

## Non-goals

This integration closure does not:

- configure Play Store production signing
- merge unrelated Phase L, Phase M, or other parallel feature branches
- redesign Home R
- redesign Startup Motion
- change learner planning authority
- reintroduce learner Firestore read paths

## Closure condition

INT-R9 is complete only when the exact final SHA has a green APK-delivery workflow and the final closed branch points to that same SHA.
