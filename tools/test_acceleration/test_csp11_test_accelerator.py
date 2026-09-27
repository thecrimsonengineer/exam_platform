#!/usr/bin/env python3

import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest


MODULE_PATH = Path(__file__).with_name("csp11_test_accelerator.py")
SPEC = importlib.util.spec_from_file_location("csp11_test_accelerator", MODULE_PATH)
assert SPEC and SPEC.loader
ACCEL = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ACCEL)


def _git(root: Path, *args: str) -> str:
    result = subprocess.run(
        ["git", *args],
        cwd=root,
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    return result.stdout.strip()


class AcceleratorTests(unittest.TestCase):
    def _repo(self) -> tuple[tempfile.TemporaryDirectory, Path]:
        temp = tempfile.TemporaryDirectory()
        root = Path(temp.name)
        _git(root, "init")
        _git(root, "config", "user.email", "test@example.com")
        _git(root, "config", "user.name", "CSP11 Test")
        return temp, root

    def _write(self, root: Path, path: str, content: str) -> None:
        target = root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")

    def test_transitive_impact_reaches_importing_widget_test(self) -> None:
        temp, root = self._repo()
        self.addCleanup(temp.cleanup)

        self._write(root, "lib/services/foo.dart", "class Foo {}\n")
        self._write(
            root,
            "lib/screens/a.dart",
            "import 'package:exam_platform/services/foo.dart';\nclass A {}\n",
        )
        self._write(
            root,
            "test/screens/a_test.dart",
            "import 'package:exam_platform/screens/a.dart';\nvoid main() {}\n",
        )
        self._write(root, "test/architecture/smoke_test.dart", "void main() {}\n")
        for index in range(8):
            self._write(
                root,
                f"test/unrelated/u{index}_test.dart",
                "void main() {}\n",
            )

        _git(root, "add", ".")
        _git(root, "commit", "-m", "base")
        base = _git(root, "rev-parse", "HEAD")

        self._write(root, "lib/services/foo.dart", "class Foo { int x = 1; }\n")
        _git(root, "add", ".")
        _git(root, "commit", "-m", "change")
        head = _git(root, "rev-parse", "HEAD")

        profile = {
            "schema_version": 1,
            "full_triggers": [],
            "broad_triggers": [],
            "smoke_test_prefixes": ["test/architecture/"],
            "broad_test_prefixes": [],
            "path_mappings": [],
            "include_smoke_in_impacted": True,
        }
        plan = ACCEL.select_tests(
            root,
            "impacted",
            base,
            head,
            profile,
            {"schema_version": 1, "tests": {}},
        )

        self.assertEqual("impacted", plan["mode_effective"])
        self.assertIn("test/screens/a_test.dart", plan["tests"])
        self.assertIn("test/architecture/smoke_test.dart", plan["tests"])
        self.assertNotIn("test/unrelated/u0_test.dart", plan["tests"])

    def test_full_trigger_escalates_to_full_suite(self) -> None:
        temp, root = self._repo()
        self.addCleanup(temp.cleanup)

        self._write(root, "pubspec.lock", "v1\n")
        for index in range(4):
            self._write(root, f"test/t{index}_test.dart", "void main() {}\n")
        _git(root, "add", ".")
        _git(root, "commit", "-m", "base")
        base = _git(root, "rev-parse", "HEAD")

        self._write(root, "pubspec.lock", "v2\n")
        _git(root, "add", ".")
        _git(root, "commit", "-m", "dependency change")
        head = _git(root, "rev-parse", "HEAD")

        profile = {
            "schema_version": 1,
            "full_triggers": ["pubspec.lock"],
            "broad_triggers": [],
            "smoke_test_prefixes": [],
            "broad_test_prefixes": [],
            "path_mappings": [],
            "include_smoke_in_impacted": True,
        }
        plan = ACCEL.select_tests(
            root,
            "impacted",
            base,
            head,
            profile,
            {"schema_version": 1, "tests": {}},
        )

        self.assertEqual("full", plan["mode_effective"])
        self.assertEqual(4, plan["selected_test_count"])

    def test_worktree_mode_detects_tracked_and_untracked_edits(self) -> None:
        temp, root = self._repo()
        self.addCleanup(temp.cleanup)

        self._write(root, "lib/a.dart", "const value = 1;\n")
        _git(root, "add", ".")
        _git(root, "commit", "-m", "base")

        self._write(root, "lib/a.dart", "const value = 2;\n")
        self._write(root, "lib/new_file.dart", "const fresh = true;\n")

        changed = ACCEL.changed_files(root, "HEAD", "WORKTREE")

        self.assertEqual(["lib/a.dart", "lib/new_file.dart"], changed)
        self.assertEqual(_git(root, "rev-parse", "HEAD"), ACCEL.resolve_ref(root, "WORKTREE"))

    def test_lpt_sharding_balances_slowest_tests_first(self) -> None:
        plan = {
            "tests": ["a", "b", "c", "d"],
            "estimates": {"a": 10.0, "b": 8.0, "c": 4.0, "d": 2.0},
        }
        result = ACCEL.shard_plan(plan, "2")
        loads = sorted(float(shard["estimated_seconds"]) for shard in result["shards"])
        self.assertEqual([12.0, 12.0], loads)

    def test_timing_merge_uses_exponential_learning(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            previous = root / "timings.json"
            delta = root / "delta.json"
            output = root / "merged.json"
            previous.write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "tests": {
                            "test/a_test.dart": {"seconds": 10.0, "samples": 2}
                        },
                    }
                ),
                encoding="utf-8",
            )
            delta.write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "tests": {
                            "test/a_test.dart": {"seconds": 20.0, "samples": 1}
                        },
                    }
                ),
                encoding="utf-8",
            )

            merged = ACCEL.merge_timings(previous, [str(delta)], output)

            self.assertAlmostEqual(
                13.5,
                merged["tests"]["test/a_test.dart"]["seconds"],
                places=2,
            )
            self.assertEqual(3, merged["tests"]["test/a_test.dart"]["samples"])

    def test_chunking_honors_file_limit(self) -> None:
        chunks = ACCEL._chunk_tests(
            [f"test/t{index}_test.dart" for index in range(7)],
            max_files=3,
        )
        self.assertEqual([3, 3, 1], [len(chunk) for chunk in chunks])


if __name__ == "__main__":
    unittest.main()
