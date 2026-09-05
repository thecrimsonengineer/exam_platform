from __future__ import annotations

import importlib.util
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
TOOLS = ROOT / "tools" / "source_pipeline"

GENERATOR = TOOLS / "generate_source_competency_mapping_l23d.py"
VALIDATOR = TOOLS / "validate_source_competency_mapping_l23d.py"
TESTS = TOOLS / "test_l23d_mapping.py"


def run_python(script: Path) -> None:
    print(f"\n===== RUNNING {script.name} =====")

    result = subprocess.run(
        [sys.executable, str(script)],
        cwd=ROOT,
        text=True,
    )

    if result.returncode != 0:
        raise SystemExit(
            f"{script.name} failed with exit code "
            f"{result.returncode}."
        )


def main() -> None:
    print("===== L2.3-D REGRESSION =====")

    for script in (GENERATOR, VALIDATOR, TESTS):
        if not script.exists():
            raise SystemExit(
                f"Required L2.3-D script not found: {script}"
            )

    run_python(GENERATOR)
    run_python(VALIDATOR)
    run_python(TESTS)

    print("\n===== L2.3-D REGRESSION COMPLETE =====")
    print("Generator: PASS")
    print("Validator: PASS")
    print("Tests: PASS")


if __name__ == "__main__":
    main()
