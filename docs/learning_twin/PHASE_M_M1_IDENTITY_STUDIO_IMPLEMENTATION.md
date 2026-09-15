# CSP11 Phase M1 - Twin Identity Studio implementation

## Scope

This patch deliberately advances the frozen Phase M roadmap through the safe part of M1:

- M1.1 - isolated Twin Identity Studio
- M1.2 - multiple in-memory avatar_maker candidate capture plus a professional reference-expression set
- M1.3 - real learner-size previews on light and dark surfaces

It does **not** perform M1.4 or M1.5.

M1.4 requires explicit human approval of one canonical identity. M1.5 may only freeze the canonical SVG/JSON/manifest after that approval.

## Frozen boundaries preserved

The patch does not modify the frozen M0 spike files. It does not modify `lib/main.dart`, production bottom navigation, Firebase services, learner persistence, quiz/exam logic, audio, voice or TTS.

The new studio uses the existing exact `avatar_maker: 1.8.0` authoring dependency and `NonPersistentAvatarMakerController`. Candidate captures remain memory-only.

## Professional reference assets

The four files under `assets/learning_twin/candidates/` are high-fidelity reference SVG containers derived from user-supplied professional-coat illustrations:

- neutral/default
- explaining/teaching
- success/encouragement
- full-body/hero

They use transparent embedded raster data inside SVG containers to preserve the supplied artwork faithfully. This makes them useful for M1 comparison and learner-size testing, but they are explicitly marked **raster-backed** and **non-canonical**. They are not a substitute for the eventual approved canonical vector export.

`reference_manifest.json` records SHA-256 hashes and the non-canonical status.

## Alternate entry point

Run the studio without touching production navigation:

```powershell
flutter run -d edge -t lib\spikes\learning_twin\twin_identity_studio_main.dart
```

## Validation expected from the apply script

The supplied PowerShell gate performs:

1. exact branch and expected-head checks
2. M0 closure-tag verification
3. clean-tree check
4. asset hash verification
5. `git apply --check`
6. patch application plus candidate asset copy
7. `flutter pub get`
8. Dart formatting
9. `flutter analyze --no-fatal-infos`
10. M0 and M1 spike tests
11. full Flutter test suite
12. `git diff --check`
13. isolated web build of the M1 entry point unless skipped explicitly

No commit, push or production merge is performed.

## Next decision

Open the M1 studio and compare the professional reference identity against one or more captured maker candidates at the supplied learner sizes. Once one identity is explicitly approved, M1.4 can be recorded and M1.5 can create the true canonical `naveed_twin.svg`, `naveed_twin.json` and `twin_manifest.json`.
