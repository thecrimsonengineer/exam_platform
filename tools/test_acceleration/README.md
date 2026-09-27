# CSP11 Adaptive Test Acceleration

This system makes normal development runs fast without weakening release gates.

## What it does

1. **Impact selection**  
   Reads `git diff`, follows Dart imports transitively, detects changed tests, and applies CSP11 path mappings.

2. **Risk escalation**  
   Dependency, platform, Firebase, root-app, repository, and rules changes automatically expand the test scope. High-risk dependency changes force the full suite.

3. **Smoke safety floor**  
   Architecture and navigation contracts stay in normal impacted runs even when the direct change is elsewhere.

4. **Timing-aware sharding**  
   Tests are distributed using learned historical durations instead of simple file counts. Slow tests are placed first using LPT bin-packing so shards finish at roughly the same time.

5. **Continuous learning**  
   `flutter test --reporter json` timing data is merged with an exponential moving average. The more the system runs, the better its shard estimates become.

6. **One Flutter process per batch**  
   Selected tests are grouped together instead of launching `flutter test` repeatedly for every file. This reduces compiler/startup overhead.

## Fast local use on Naveed's Windows machine

From the repository root:

```powershell
.\tools\test_acceleration\csp11_fast_test.ps1
```

That runs the tests impacted by your current staged, unstaged, and untracked working-tree changes.

Useful modes:

```powershell
# Current working-tree changes, normal development default
.\tools\test_acceleration\csp11_fast_test.ps1 -Mode impacted

# Very small safety suite
.\tools\test_acceleration\csp11_fast_test.ps1 -Mode smoke

# Complete Flutter regression suite
.\tools\test_acceleration\csp11_fast_test.ps1 -Mode full

# Compare a phase against a frozen checkpoint
.\tools\test_acceleration\csp11_fast_test.ps1 `
  -Base phase-global-navigation-animation-closed `
  -Head HEAD `
  -Mode impacted
```

`-Workers` defaults to 1 locally to avoid multiple Flutter processes fighting over the same build cache. `-Concurrency 4` still lets Flutter parallelize tests inside the process. Increase `-Workers` only if the machine has enough RAM/CPU and concurrent Flutter test processes are stable.

## Direct Python commands

Create a plan only:

```bash
python tools/test_acceleration/csp11_test_accelerator.py plan \
  --base HEAD~1 \
  --head HEAD \
  --mode impacted \
  --shards auto
```

Show learned timing data:

```bash
python tools/test_acceleration/csp11_test_accelerator.py stats
```

Run the full suite through the accelerator:

```bash
python tools/test_acceleration/csp11_test_accelerator.py local \
  --mode full \
  --shards 4
```

## CI behavior

`.github/workflows/adaptive_test_acceleration.yml`:

- plans once;
- restores the latest timing history;
- dynamically creates only the required test shards;
- runs shards in parallel on separate GitHub runners;
- uploads raw JSON test logs and timing deltas;
- merges timing deltas after the run;
- saves the improved timing model for the next run.

The workflow defaults to `impacted` mode. A manual dispatch can force `smoke` or `full`.

## Safety rule

This accelerator is intended to replace repeated full regressions during active development, not final release evidence.

Use:

- `impacted` for normal code/content iteration;
- `smoke` for tiny non-runtime changes;
- `full` for phase closure, production release, major dependency/platform changes, or whenever the risk profile demands it.

The profile lives in `tools/test_acceleration/profile.json` and can be expanded as CSP11 gains new subsystems.
