#!/usr/bin/env python3
"""CSP11 adaptive Flutter test accelerator.

Selects impacted tests from Git changes, balances them using learned timings,
runs shards with a single Flutter test process per batch, and continuously
improves future shard balance from JSON reporter timings.
"""

from __future__ import annotations

import argparse
import concurrent.futures
import datetime as dt
import fnmatch
import glob
import json
import os
from pathlib import Path
import re
import posixpath
import shlex
import subprocess
import sys
import time
from typing import Any, Iterable

SCHEMA_VERSION = 1
PACKAGE_NAME = "exam_platform"
IMPORT_RE = re.compile(
    r"""^\s*(?:import|export|part)\s+['\"]([^'\"]+)['\"]""",
    re.MULTILINE,
)
DEFAULT_TIMING_SECONDS = 1.0
EMA_ALPHA = 0.35
FULL_SELECTION_THRESHOLD = 0.65


def _now_iso() -> str:
    return dt.datetime.now(dt.timezone.utc).isoformat()


def _norm(path: str | Path) -> str:
    text = posixpath.normpath(Path(path).as_posix())
    while text.startswith("./"):
        text = text[2:]
    return text


def _run_git(root: Path, args: list[str], *, check: bool = True) -> str:
    result = subprocess.run(
        ["git", *args],
        cwd=root,
        check=check,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    return result.stdout.strip()


def resolve_ref(root: Path, ref: str) -> str:
    return _run_git(root, ["rev-parse", ref])


def changed_files(root: Path, base: str, head: str) -> list[str]:
    try:
        output = _run_git(root, ["diff", "--name-only", f"{base}...{head}"])
    except subprocess.CalledProcessError:
        output = _run_git(root, ["diff", "--name-only", base, head])
    return sorted({_norm(line) for line in output.splitlines() if line.strip()})


def discover_tests(root: Path) -> list[str]:
    tests: list[str] = []
    test_root = root / "test"
    if not test_root.exists():
        return tests
    for path in test_root.rglob("*_test.dart"):
        if path.is_file():
            tests.append(_norm(path.relative_to(root)))
    return sorted(tests)


def load_profile(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        data = json.load(handle)
    if data.get("schema_version") != SCHEMA_VERSION:
        raise ValueError(
            f"Unsupported profile schema {data.get('schema_version')}; "
            f"expected {SCHEMA_VERSION}."
        )
    return data


def load_timings(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {
            "schema_version": SCHEMA_VERSION,
            "updated_at": _now_iso(),
            "tests": {},
        }
    try:
        with path.open("r", encoding="utf-8") as handle:
            data = json.load(handle)
    except (OSError, json.JSONDecodeError):
        return {
            "schema_version": SCHEMA_VERSION,
            "updated_at": _now_iso(),
            "tests": {},
        }
    if data.get("schema_version") != SCHEMA_VERSION:
        return {
            "schema_version": SCHEMA_VERSION,
            "updated_at": _now_iso(),
            "tests": {},
        }
    data.setdefault("tests", {})
    return data


def _matches_any(path: str, patterns: Iterable[str]) -> bool:
    return any(fnmatch.fnmatch(path, pattern) for pattern in patterns)


def _paths_with_prefix(tests: Iterable[str], prefixes: Iterable[str]) -> set[str]:
    prefixes_tuple = tuple(_norm(p) for p in prefixes)
    return {test for test in tests if test.startswith(prefixes_tuple)}


def _resolve_import(source: str, importer: str) -> str | None:
    if source.startswith("dart:"):
        return None
    if source.startswith(f"package:{PACKAGE_NAME}/"):
        return "lib/" + source.split("/", 1)[1]
    if source.startswith("package:"):
        return None
    if "://" in source:
        return None
    candidate = Path(importer).parent / source
    return _norm(candidate)


def build_reverse_import_graph(root: Path) -> dict[str, set[str]]:
    reverse: dict[str, set[str]] = {}
    dart_files: list[Path] = []
    for base in ("lib", "test"):
        base_path = root / base
        if base_path.exists():
            dart_files.extend(path for path in base_path.rglob("*.dart") if path.is_file())

    for path in dart_files:
        rel = _norm(path.relative_to(root))
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        for source in IMPORT_RE.findall(text):
            resolved = _resolve_import(source, rel)
            if not resolved:
                continue
            reverse.setdefault(resolved, set()).add(rel)
    return reverse


def transitive_impacted_tests(
    changed: Iterable[str],
    reverse_graph: dict[str, set[str]],
    all_tests: set[str],
) -> set[str]:
    queue = [path for path in changed if path.endswith(".dart")]
    seen = set(queue)
    selected: set[str] = set()

    while queue:
        current = queue.pop()
        if current in all_tests:
            selected.add(current)
        for importer in reverse_graph.get(current, ()):
            if importer in seen:
                continue
            seen.add(importer)
            if importer in all_tests:
                selected.add(importer)
            queue.append(importer)
    return selected


def _token_similarity_candidates(changed_path: str, tests: Iterable[str]) -> set[str]:
    source = Path(changed_path)
    stem = source.stem.lower()
    if stem.endswith("_test"):
        stem = stem[:-5]
    source_tokens = {
        token
        for token in re.split(r"[_\-/]+", changed_path.lower())
        if len(token) >= 4 and token not in {"dart", "lib", "test", "screens"}
    }
    selected: set[str] = set()
    for test in tests:
        test_lower = test.lower()
        if stem and len(stem) >= 5 and stem in test_lower:
            selected.add(test)
            continue
        test_tokens = set(re.split(r"[_\-/]+", test_lower))
        if len(source_tokens & test_tokens) >= 2:
            selected.add(test)
    return selected


def select_tests(
    root: Path,
    mode: str,
    base: str,
    head: str,
    profile: dict[str, Any],
    timings: dict[str, Any],
) -> dict[str, Any]:
    tests = discover_tests(root)
    all_tests = set(tests)
    changed = changed_files(root, base, head)
    reasons: list[str] = []

    if mode == "full":
        selected = set(tests)
        effective_mode = "full"
        reasons.append("full mode requested")
    else:
        selected: set[str] = set()
        effective_mode = mode

        full_patterns = profile.get("full_triggers", [])
        full_hits = [path for path in changed if _matches_any(path, full_patterns)]
        if full_hits:
            selected = set(tests)
            effective_mode = "full"
            reasons.append("full-suite trigger changed: " + ", ".join(full_hits[:8]))
        else:
            for test in tests:
                if test in changed:
                    selected.add(test)

            smoke_prefixes = profile.get("smoke_test_prefixes", [])
            smoke_tests = _paths_with_prefix(tests, smoke_prefixes)

            if mode == "smoke":
                selected |= smoke_tests
                reasons.append("smoke profile selected")
            else:
                reverse_graph = build_reverse_import_graph(root)
                transitive = transitive_impacted_tests(changed, reverse_graph, all_tests)
                if transitive:
                    selected |= transitive
                    reasons.append(f"{len(transitive)} transitive Dart dependency tests")

                path_mappings = profile.get("path_mappings", [])
                for mapping in path_mappings:
                    source_prefixes = tuple(
                        _norm(prefix) for prefix in mapping.get("source_prefixes", [])
                    )
                    if any(path.startswith(source_prefixes) for path in changed):
                        mapped = _paths_with_prefix(tests, mapping.get("test_prefixes", []))
                        if mapped:
                            selected |= mapped
                            reasons.append(
                                f"mapped {mapping.get('name', 'path group')} "
                                f"to {len(mapped)} tests"
                            )

                broad_patterns = profile.get("broad_triggers", [])
                broad_hits = [path for path in changed if _matches_any(path, broad_patterns)]
                if broad_hits:
                    broad_tests = _paths_with_prefix(
                        tests, profile.get("broad_test_prefixes", [])
                    )
                    selected |= broad_tests
                    reasons.append("broad safety expansion: " + ", ".join(broad_hits[:8]))

                for path in changed:
                    if path.startswith(("lib/", "content/", "assets/")):
                        selected |= _token_similarity_candidates(path, tests)

                if profile.get("include_smoke_in_impacted", True):
                    selected |= smoke_tests
                    if smoke_tests:
                        reasons.append(f"{len(smoke_tests)} smoke safety tests")

                if not selected and any(
                    path.startswith(("lib/", "content/", "assets/", "firestore"))
                    for path in changed
                ):
                    selected |= smoke_tests
                    reasons.append("no direct match; smoke fallback applied")

            if tests and len(selected) / len(tests) >= FULL_SELECTION_THRESHOLD:
                selected = set(tests)
                effective_mode = "full"
                reasons.append(
                    f"selection crossed {int(FULL_SELECTION_THRESHOLD * 100)}% "
                    "threshold; full suite is cheaper/safer"
                )

    selected_sorted = sorted(selected)
    estimates = {test: estimate_seconds(root, test, timings) for test in selected_sorted}

    return {
        "schema_version": SCHEMA_VERSION,
        "generated_at": _now_iso(),
        "mode_requested": mode,
        "mode_effective": effective_mode,
        "base": resolve_ref(root, base),
        "head": resolve_ref(root, head),
        "changed_files": changed,
        "discovered_test_count": len(tests),
        "selected_test_count": len(selected_sorted),
        "selection_ratio": round(len(selected_sorted) / len(tests), 4) if tests else 0.0,
        "reasons": reasons,
        "tests": selected_sorted,
        "estimates": estimates,
    }


def estimate_seconds(root: Path, test: str, timings: dict[str, Any]) -> float:
    record = timings.get("tests", {}).get(test)
    if isinstance(record, dict):
        seconds = record.get("seconds")
        if isinstance(seconds, (int, float)) and seconds > 0:
            return float(seconds)

    path = root / test
    try:
        size = path.stat().st_size
    except OSError:
        size = 4000
    estimate = 0.45 + min(size / 4500.0, 4.5)
    if any(token in test for token in ("/integration/", "/production/", "/lab_quality/")):
        estimate *= 1.6
    return round(max(DEFAULT_TIMING_SECONDS, estimate), 3)


def auto_shard_count(selected_count: int, total_estimate: float) -> int:
    if selected_count <= 6 or total_estimate <= 12:
        return 1
    if selected_count <= 24 or total_estimate <= 40:
        return 2
    return 4


def shard_plan(plan: dict[str, Any], requested_shards: str) -> dict[str, Any]:
    tests = list(plan["tests"])
    estimates = plan["estimates"]
    total = sum(float(estimates[test]) for test in tests)
    if requested_shards == "auto":
        shard_count = auto_shard_count(len(tests), total)
    else:
        shard_count = max(1, int(requested_shards))
    shard_count = min(shard_count, max(1, len(tests))) if tests else 1

    shards = [
        {"index": index, "estimated_seconds": 0.0, "tests": []}
        for index in range(shard_count)
    ]
    for test in sorted(tests, key=lambda item: (-float(estimates[item]), item)):
        target = min(
            shards,
            key=lambda shard: (float(shard["estimated_seconds"]), shard["index"]),
        )
        target["tests"].append(test)
        target["estimated_seconds"] = round(
            float(target["estimated_seconds"]) + float(estimates[test]), 3
        )

    plan["estimated_total_seconds"] = round(total, 3)
    plan["shard_count"] = shard_count
    plan["shards"] = shards
    return plan


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(data, handle, indent=2, sort_keys=True)
        handle.write("\n")


def _github_output(path: str | None, plan: dict[str, Any]) -> None:
    if not path:
        return
    matrix = [shard["index"] for shard in plan["shards"] if shard["tests"]]
    lines = {
        "matrix": json.dumps(matrix, separators=(",", ":")),
        "selected_count": str(plan["selected_test_count"]),
        "mode_effective": plan["mode_effective"],
        "shard_count": str(len(matrix)),
    }
    with open(path, "a", encoding="utf-8") as handle:
        for key, value in lines.items():
            handle.write(f"{key}={value}\n")


def print_plan_summary(plan: dict[str, Any]) -> None:
    print("CSP11 Adaptive Test Plan")
    print(f"  mode: {plan['mode_requested']} -> {plan['mode_effective']}")
    print(
        f"  tests: {plan['selected_test_count']}/{plan['discovered_test_count']} "
        f"({plan['selection_ratio'] * 100:.1f}%)"
    )
    print(
        f"  predicted test work: {plan.get('estimated_total_seconds', 0.0):.1f}s "
        f"across {plan.get('shard_count', 0)} shard(s)"
    )
    for reason in plan.get("reasons", []):
        print(f"  reason: {reason}")
    for shard in plan.get("shards", []):
        if shard["tests"]:
            print(
                f"  shard {shard['index']}: {len(shard['tests'])} tests, "
                f"~{float(shard['estimated_seconds']):.1f}s"
            )


def _chunk_tests(tests: list[str], max_files: int, max_chars: int = 22000) -> list[list[str]]:
    chunks: list[list[str]] = []
    current: list[str] = []
    current_chars = 0
    for test in tests:
        cost = len(test) + 1
        if current and (len(current) >= max_files or current_chars + cost > max_chars):
            chunks.append(current)
            current = []
            current_chars = 0
        current.append(test)
        current_chars += cost
    if current:
        chunks.append(current)
    return chunks


def _run_flutter_batch(
    root: Path,
    tests: list[str],
    concurrency: int,
    log_path: Path,
) -> tuple[int, dict[str, float], float, list[str]]:
    command = [
        "flutter",
        "test",
        "--reporter",
        "json",
        "--concurrency",
        str(max(1, concurrency)),
        *tests,
    ]
    print("+ " + " ".join(shlex.quote(part) for part in command))
    log_path.parent.mkdir(parents=True, exist_ok=True)

    suites: dict[int, str] = {}
    starts: dict[int, tuple[int | None, int]] = {}
    durations: dict[str, float] = {}
    failures: list[str] = []
    started = time.perf_counter()

    with log_path.open("w", encoding="utf-8") as log:
        process = subprocess.Popen(
            command,
            cwd=root,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            bufsize=1,
        )
        assert process.stdout is not None
        for raw_line in process.stdout:
            log.write(raw_line)
            line = raw_line.strip()
            try:
                event = json.loads(line)
            except json.JSONDecodeError:
                if line:
                    print(line)
                continue

            event_type = event.get("type")
            event_time = int(event.get("time", 0))
            if event_type == "suite":
                suite = event.get("suite", {})
                suite_id = suite.get("id")
                path = suite.get("path")
                if isinstance(suite_id, int) and isinstance(path, str):
                    try:
                        rel = _norm(Path(path).resolve().relative_to(root.resolve()))
                    except (ValueError, OSError):
                        rel = _norm(path)
                    suites[suite_id] = rel
            elif event_type == "testStart":
                test_data = event.get("test", {})
                test_id = test_data.get("id")
                suite_id = test_data.get("suiteID")
                if isinstance(test_id, int):
                    starts[test_id] = (
                        suite_id if isinstance(suite_id, int) else None,
                        event_time,
                    )
            elif event_type == "testDone":
                test_id = event.get("testID")
                result = event.get("result")
                if isinstance(test_id, int) and test_id in starts:
                    suite_id, start_time = starts.pop(test_id)
                    if suite_id is not None and suite_id in suites:
                        path = suites[suite_id]
                        elapsed = max(0.001, (event_time - start_time) / 1000.0)
                        durations[path] = durations.get(path, 0.0) + elapsed
                if result in {"failure", "error"}:
                    failures.append(str(test_id))

        return_code = process.wait()

    wall = time.perf_counter() - started
    missing = [test for test in tests if test not in durations]
    if missing:
        fallback = max(0.1, wall / max(1, len(tests)))
        for test in missing:
            durations[test] = fallback

    return return_code, durations, wall, failures


def run_shard(
    root: Path,
    plan_path: Path,
    shard_index: int,
    delta_path: Path,
    concurrency: int,
    max_files_per_process: int,
    log_dir: Path,
) -> int:
    with plan_path.open("r", encoding="utf-8") as handle:
        plan = json.load(handle)

    matching = [s for s in plan.get("shards", []) if int(s["index"]) == shard_index]
    if not matching:
        raise ValueError(f"Shard {shard_index} not found in {plan_path}")
    tests = list(matching[0].get("tests", []))
    if not tests:
        print(f"Shard {shard_index}: no tests selected.")
        write_json(
            delta_path,
            {
                "schema_version": SCHEMA_VERSION,
                "generated_at": _now_iso(),
                "tests": {},
            },
        )
        return 0

    combined: dict[str, float] = {}
    total_wall = 0.0
    failures: list[str] = []
    return_code = 0
    batches = _chunk_tests(tests, max_files=max_files_per_process)

    print(
        f"Shard {shard_index}: {len(tests)} tests in {len(batches)} "
        f"Flutter process batch(es)."
    )
    for batch_index, batch in enumerate(batches):
        code, durations, wall, batch_failures = _run_flutter_batch(
            root,
            batch,
            concurrency,
            log_dir / f"shard-{shard_index}-batch-{batch_index}.jsonl",
        )
        total_wall += wall
        for path, seconds in durations.items():
            combined[path] = combined.get(path, 0.0) + float(seconds)
        failures.extend(batch_failures)
        if code != 0:
            return_code = code
            break

    write_json(
        delta_path,
        {
            "schema_version": SCHEMA_VERSION,
            "generated_at": _now_iso(),
            "shard": shard_index,
            "wall_seconds": round(total_wall, 3),
            "tests": {
                path: {"seconds": round(seconds, 3), "samples": 1}
                for path, seconds in sorted(combined.items())
            },
        },
    )

    print(
        f"Shard {shard_index} finished in {total_wall:.1f}s "
        f"with exit code {return_code}."
    )
    if failures:
        print(f"Shard {shard_index}: {len(failures)} failing test event(s).")
    return return_code


def merge_timings(
    previous_path: Path,
    delta_globs: list[str],
    output_path: Path,
) -> dict[str, Any]:
    previous = load_timings(previous_path)
    merged = {
        "schema_version": SCHEMA_VERSION,
        "updated_at": _now_iso(),
        "tests": dict(previous.get("tests", {})),
    }

    delta_paths: list[Path] = []
    for pattern in delta_globs:
        delta_paths.extend(Path(path) for path in glob.glob(pattern, recursive=True))

    for path in sorted(set(delta_paths)):
        if not path.is_file():
            continue
        try:
            with path.open("r", encoding="utf-8") as handle:
                delta = json.load(handle)
        except (OSError, json.JSONDecodeError):
            continue
        for test, incoming in delta.get("tests", {}).items():
            seconds = float(incoming.get("seconds", DEFAULT_TIMING_SECONDS))
            old = merged["tests"].get(test)
            if isinstance(old, dict) and float(old.get("seconds", 0.0)) > 0:
                old_seconds = float(old["seconds"])
                new_seconds = EMA_ALPHA * seconds + (1 - EMA_ALPHA) * old_seconds
                samples = int(old.get("samples", 0)) + int(incoming.get("samples", 1))
            else:
                new_seconds = seconds
                samples = int(incoming.get("samples", 1))
            merged["tests"][test] = {
                "seconds": round(max(0.05, new_seconds), 3),
                "samples": samples,
            }

    write_json(output_path, merged)
    return merged


def local_run(
    root: Path,
    args: argparse.Namespace,
    profile: dict[str, Any],
    timings: dict[str, Any],
) -> int:
    plan = select_tests(root, args.mode, args.base, args.head, profile, timings)
    shard_plan(plan, args.shards)
    plan_path = root / ".csp11" / "test-plan.json"
    write_json(plan_path, plan)
    print_plan_summary(plan)

    active = [s for s in plan["shards"] if s["tests"]]
    if not active:
        print("No tests selected.")
        return 0

    delta_paths: list[Path] = []

    def _worker(shard: dict[str, Any]) -> tuple[int, Path]:
        index = int(shard["index"])
        delta = root / ".csp11" / f"timing-delta-{index}.json"
        code = run_shard(
            root,
            plan_path,
            index,
            delta,
            args.concurrency,
            args.max_files_per_process,
            root / ".csp11" / "test-logs",
        )
        return code, delta

    max_workers = min(max(1, args.workers), len(active))
    codes: list[int] = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = [executor.submit(_worker, shard) for shard in active]
        for future in concurrent.futures.as_completed(futures):
            code, delta = future.result()
            codes.append(code)
            delta_paths.append(delta)

    merge_timings(
        Path(args.timings),
        [str(path) for path in delta_paths],
        Path(args.timings),
    )
    return 0 if all(code == 0 for code in codes) else 1


def create_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Adaptive, impact-aware Flutter test acceleration for CSP11."
    )
    parser.add_argument("--root", default=".", help="Repository root (default: current directory).")
    sub = parser.add_subparsers(dest="command", required=True)

    plan = sub.add_parser("plan", help="Build an impact-aware test plan.")
    plan.add_argument("--base", default="HEAD~1")
    plan.add_argument("--head", default="HEAD")
    plan.add_argument("--mode", choices=("impacted", "smoke", "full"), default="impacted")
    plan.add_argument("--shards", default="auto")
    plan.add_argument("--profile", default="tools/test_acceleration/profile.json")
    plan.add_argument("--timings", default=".csp11/test_timings.json")
    plan.add_argument("--output", default=".csp11/test-plan.json")
    plan.add_argument("--github-output")

    run = sub.add_parser("run-shard", help="Run one planned shard and emit timing data.")
    run.add_argument("--plan", default=".csp11/test-plan.json")
    run.add_argument("--shard", type=int, required=True)
    run.add_argument("--delta", required=True)
    run.add_argument("--concurrency", type=int, default=2)
    run.add_argument("--max-files-per-process", type=int, default=96)
    run.add_argument("--log-dir", default=".csp11/test-logs")

    merge = sub.add_parser("merge-timings", help="Merge timing deltas with EMA learning.")
    merge.add_argument("--previous", default=".csp11/test_timings.json")
    merge.add_argument("--delta", action="append", required=True)
    merge.add_argument("--output", default=".csp11/test_timings.json")

    local = sub.add_parser("local", help="Plan and run adaptive tests locally.")
    local.add_argument("--base", default="HEAD~1")
    local.add_argument("--head", default="HEAD")
    local.add_argument("--mode", choices=("impacted", "smoke", "full"), default="impacted")
    local.add_argument("--shards", default="auto")
    local.add_argument("--workers", type=int, default=1)
    local.add_argument("--concurrency", type=int, default=4)
    local.add_argument("--max-files-per-process", type=int, default=96)
    local.add_argument("--profile", default="tools/test_acceleration/profile.json")
    local.add_argument("--timings", default=".csp11/test_timings.json")

    stats = sub.add_parser("stats", help="Show learned timing statistics.")
    stats.add_argument("--timings", default=".csp11/test_timings.json")
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = create_parser()
    args = parser.parse_args(argv)
    root = Path(args.root).resolve()

    if args.command == "plan":
        profile = load_profile(root / args.profile)
        timings = load_timings(root / args.timings)
        plan = select_tests(root, args.mode, args.base, args.head, profile, timings)
        shard_plan(plan, args.shards)
        output = root / args.output
        write_json(output, plan)
        print_plan_summary(plan)
        _github_output(args.github_output, plan)
        return 0

    if args.command == "run-shard":
        return run_shard(
            root,
            root / args.plan,
            args.shard,
            root / args.delta,
            args.concurrency,
            args.max_files_per_process,
            root / args.log_dir,
        )

    if args.command == "merge-timings":
        merge_timings(root / args.previous, args.delta, root / args.output)
        return 0

    if args.command == "local":
        profile = load_profile(root / args.profile)
        timings = load_timings(root / args.timings)
        args.timings = str(root / args.timings)
        return local_run(root, args, profile, timings)

    if args.command == "stats":
        timings = load_timings(root / args.timings)
        records = timings.get("tests", {})
        total = sum(float(item.get("seconds", 0.0)) for item in records.values())
        print(f"Learned test files: {len(records)}")
        print(f"Learned cumulative work estimate: {total:.1f}s")
        slowest = sorted(
            records.items(),
            key=lambda item: float(item[1].get("seconds", 0.0)),
            reverse=True,
        )[:15]
        for path, record in slowest:
            print(
                f"{float(record.get('seconds', 0.0)):7.2f}s  "
                f"{int(record.get('samples', 0)):3d} samples  {path}"
            )
        return 0

    parser.error("Unknown command")
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
