import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parents[2]
CANONICAL = ROOT / "docs" / "source_pipeline" / "CSP11_canonical_blueprint.json"
GENERATOR = ROOT / "tools" / "source_pipeline" / "generate_csp11_dart_registry.py"
CURRENT_REGISTRY = ROOT / "lib" / "data" / "csp11_blueprint.dart"


def load_canonical():
    with CANONICAL.open("r", encoding="utf-8-sig") as handle:
        return json.load(handle)


def run_generator(output):
    result = subprocess.run(
        [
            sys.executable,
            str(GENERATOR),
            "--input",
            str(CANONICAL),
            "--output",
            str(output),
        ],
        cwd=ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )

    assert result.returncode == 0, (
        "Generator failed.\n"
        f"STDOUT:\n{result.stdout}\n"
        f"STDERR:\n{result.stderr}"
    )


def test_canonical_structure():
    data = load_canonical()

    assert data["status"] == "CANONICAL"

    domains = data["domains"]

    assert len(domains) == 7

    assert [
        domain["domain_id"]
        for domain in domains
    ] == [f"d{i:02d}" for i in range(1, 8)]

    competencies = [
        competency
        for domain in domains
        for competency in domain["competencies"]
    ]

    assert len(competencies) == 47

    ids = [
        competency["competency_id"]
        for competency in competencies
    ]

    assert len(ids) == len(set(ids))


def test_deterministic_output():
    with tempfile.TemporaryDirectory() as temp:
        first = Path(temp) / "registry1.dart"
        second = Path(temp) / "registry2.dart"

        run_generator(first)
        run_generator(second)

        first_bytes = first.read_bytes()
        second_bytes = second.read_bytes()

        assert first_bytes == second_bytes

        assert hashlib.sha256(first_bytes).digest() == (
            hashlib.sha256(second_bytes).digest()
        )


def test_canonical_statements_are_present_exactly():
    data = load_canonical()

    with tempfile.TemporaryDirectory() as temp:
        output = Path(temp) / "registry.dart"

        run_generator(output)

        text = output.read_text(encoding="utf-8")

        for domain in data["domains"]:
            assert domain["domain_id"] in text
            assert domain["name"] in text

            for competency in domain["competencies"]:
                assert competency["competency_id"] in text
                assert competency["statement"] in text


def test_required_api_is_preserved():
    with tempfile.TemporaryDirectory() as temp:
        output = Path(temp) / "registry.dart"

        run_generator(output)

        text = output.read_text(encoding="utf-8")

        required = [
            "class Csp11Competency",
            "class Csp11Domain",
            "const List<Csp11Domain> csp11Domains",
            "Csp11Domain? domainForId",
            "Csp11Domain? domainForContentId",
            "Csp11Domain domainForNumber",
            "Csp11Competency? competencyForId",
            "List<Csp11Competency> competenciesForDomain",
            "Csp11Competency? competencyForDomainAndNumber",
        ]

        for symbol in required:
            assert symbol in text, f"Missing API: {symbol}"


def test_legacy_domain_compatibility_is_preserved():
    with tempfile.TemporaryDirectory() as temp:
        output = Path(temp) / "registry.dart"

        run_generator(output)

        text = output.read_text(encoding="utf-8")

        assert "'domain_${domain.number.toString().padLeft(2, '0')}'" in text
        assert "'domain${domain.number}'" in text
        assert "normalized.replaceAll('domain', '')" in text


def test_current_registry_is_not_modified():
    before = CURRENT_REGISTRY.read_bytes()

    with tempfile.TemporaryDirectory() as temp:
        output = Path(temp) / "registry.dart"
        run_generator(output)

    after = CURRENT_REGISTRY.read_bytes()

    assert before == after


if __name__ == "__main__":
    tests = [
        test_canonical_structure,
        test_deterministic_output,
        test_canonical_statements_are_present_exactly,
        test_required_api_is_preserved,
        test_legacy_domain_compatibility_is_preserved,
        test_current_registry_is_not_modified,
    ]

    for test in tests:
        test()
        print(f"PASS: {test.__name__}")

    print("")
    print("L23E-1B REGRESSION TESTS PASSED")
