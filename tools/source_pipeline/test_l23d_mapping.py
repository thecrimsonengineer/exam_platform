from __future__ import annotations

import copy
import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DOCS = ROOT / "docs" / "source_pipeline"

BLUEPRINT_PATH = DOCS / "CSP11_canonical_blueprint.json"
BLUEPRINT_VALIDATION_PATH = DOCS / "CSP11_canonical_blueprint_validation.json"
SOURCE_CONTROL_PATH = DOCS / "CSP11_source_control.json"
CANDIDATES_PATH = DOCS / "CSP11_source_to_competency_candidates.json"

MAPPING_PATH = DOCS / "CSP11_source_to_competency_mapping_l23d.json"


GENERATOR_MODULE = (
    ROOT
    / "tools"
    / "source_pipeline"
    / "generate_source_competency_mapping_l23d.py"
)

VALIDATOR_MODULE = (
    ROOT
    / "tools"
    / "source_pipeline"
    / "validate_source_competency_mapping_l23d.py"
)


def load_module(path: Path, name: str):
    import importlib.util

    spec = importlib.util.spec_from_file_location(name, path)

    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load module: {path}")

    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)

    return module


generator = load_module(
    GENERATOR_MODULE,
    "l23d_generator_test_module",
)

validator = load_module(
    VALIDATOR_MODULE,
    "l23d_validator_test_module",
)


def load_json(path: Path):
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def assert_true(condition, message):
    if not condition:
        raise AssertionError(message)


def test_valid_272_mapping_set():
    blueprint = load_json(BLUEPRINT_PATH)
    blueprint_validation = load_json(BLUEPRINT_VALIDATION_PATH)
    source_control = load_json(SOURCE_CONTROL_PATH)
    candidates = load_json(CANDIDATES_PATH)

    competencies, authoritative, excluded = generator.validate_upstream(
        blueprint,
        blueprint_validation,
        source_control,
        candidates,
    )

    mappings, unmapped = generator.build_mappings(
        candidates,
        competencies,
        authoritative,
        excluded,
    )

    assert_true(
        len(mappings) == 272,
        f"Expected 272 mappings, found {len(mappings)}.",
    )

    assert_true(
        len(unmapped) == 4,
        f"Expected 4 unmapped sources, found {len(unmapped)}.",
    )

    assert_true(
        all(
            mapping["mapping_status"] == "CANDIDATE"
            for mapping in mappings
        ),
        "Every generated mapping must have CANDIDATE status.",
    )

    assert_true(
        all(
            mapping["human_decision"] is None
            and mapping["reviewer"] is None
            and mapping["review_date"] is None
            and mapping["review_notes"] is None
            for mapping in mappings
        ),
        "Human-review fields must remain null.",
    )


def test_mapping_id_determinism():
    mapping_id = generator.build_mapping_id(
        "SRC-001",
        "d01_c03",
    )

    assert_true(
        mapping_id == "MAP-SRC-001-d01_c03",
        f"Unexpected deterministic mapping ID: {mapping_id}",
    )


def test_evidence_reference_determinism():
    reference = generator.build_evidence_reference(
        "SRC-001",
        "d01_c03",
    )

    expected = (
        "CSP11_source_to_competency_candidates.json"
        "::SRC-001::d01_c03"
    )

    assert_true(
        reference == expected,
        f"Unexpected evidence reference: {reference}",
    )


def test_duplicate_relationship_is_blocked():
    blueprint = load_json(BLUEPRINT_PATH)
    blueprint_validation = load_json(BLUEPRINT_VALIDATION_PATH)
    source_control = load_json(SOURCE_CONTROL_PATH)
    candidates = load_json(CANDIDATES_PATH)

    duplicate_candidates = copy.deepcopy(candidates)

    first_source = duplicate_candidates["source_candidates"][0]
    first_candidate = first_source["candidate_mappings"][0]

    first_source["candidate_mappings"].append(
        copy.deepcopy(first_candidate)
    )

    competencies, authoritative, excluded = generator.validate_upstream(
        blueprint,
        blueprint_validation,
        source_control,
        duplicate_candidates,
    )

    try:
        generator.build_mappings(
            duplicate_candidates,
            competencies,
            authoritative,
            excluded,
        )
    except ValueError as exc:
        assert_true(
            "Duplicate relationship" in str(exc),
            f"Wrong duplicate error: {exc}",
        )
        return

    raise AssertionError(
        "Duplicate relationship was not rejected."
    )


def test_excluded_source_is_blocked():
    blueprint = load_json(BLUEPRINT_PATH)
    blueprint_validation = load_json(BLUEPRINT_VALIDATION_PATH)
    source_control = load_json(SOURCE_CONTROL_PATH)
    candidates = load_json(CANDIDATES_PATH)

    invalid_candidates = copy.deepcopy(candidates)

    invalid_candidates["source_candidates"][0]["source_id"] = "SRC-003"

    competencies, authoritative, excluded = generator.validate_upstream(
        blueprint,
        blueprint_validation,
        source_control,
        invalid_candidates,
    )

    try:
        generator.build_mappings(
            invalid_candidates,
            competencies,
            authoritative,
            excluded,
        )
    except ValueError as exc:
        assert_true(
            "non-authoritative source" in str(exc).lower()
            or "excluded source" in str(exc).lower(),
            f"Wrong excluded-source error: {exc}",
        )
        return

    raise AssertionError(
        "Excluded source was not rejected."
    )


def test_domain_mismatch_is_blocked():
    blueprint = load_json(BLUEPRINT_PATH)
    blueprint_validation = load_json(BLUEPRINT_VALIDATION_PATH)
    source_control = load_json(SOURCE_CONTROL_PATH)
    candidates = load_json(CANDIDATES_PATH)

    invalid_candidates = copy.deepcopy(candidates)

    candidate = (
        invalid_candidates["source_candidates"][0]
        ["candidate_mappings"][0]
    )

    candidate["domain_id"] = "d07"

    competencies, authoritative, excluded = generator.validate_upstream(
        blueprint,
        blueprint_validation,
        source_control,
        invalid_candidates,
    )

    try:
        generator.build_mappings(
            invalid_candidates,
            competencies,
            authoritative,
            excluded,
        )
    except ValueError as exc:
        assert_true(
            "Domain mismatch" in str(exc),
            f"Wrong domain-mismatch error: {exc}",
        )
        return

    raise AssertionError(
        "Domain mismatch was not rejected."
    )


def test_human_metadata_on_candidate_is_blocked():
    mapping = load_json(MAPPING_PATH)

    test_record = copy.deepcopy(
        mapping["mappings"][0]
    )

    test_record["reviewer"] = "TEST"

    issues = []
    seen_relationships = set()

    blueprint = load_json(BLUEPRINT_PATH)
    competencies = generator.canonical_competencies(
        blueprint
    )

    source_control = load_json(SOURCE_CONTROL_PATH)
    authoritative = set(
        source_control["authoritative_source_ids"]
    )
    excluded = set(
        source_control["excluded_source_ids"]
    )

    validator.validate_mapping_record(
        test_record,
        0,
        competencies,
        authoritative,
        excluded,
        issues,
        seen_relationships,
    )

    codes = {
        issue["code"]
        for issue in issues
    }

    assert_true(
        "HUMAN_METADATA_PRESENT" in codes,
        "Human metadata on a candidate was not blocked.",
    )


def test_acceptance_without_human_decision_is_blocked():
    mapping = load_json(MAPPING_PATH)

    test_record = copy.deepcopy(
        mapping["mappings"][0]
    )

    test_record["mapping_status"] = "ACCEPTED"

    issues = []
    seen_relationships = set()

    blueprint = load_json(BLUEPRINT_PATH)
    competencies = generator.canonical_competencies(
        blueprint
    )

    source_control = load_json(SOURCE_CONTROL_PATH)
    authoritative = set(
        source_control["authoritative_source_ids"]
    )
    excluded = set(
        source_control["excluded_source_ids"]
    )

    validator.validate_mapping_record(
        test_record,
        0,
        competencies,
        authoritative,
        excluded,
        issues,
        seen_relationships,
    )

    codes = {
        issue["code"]
        for issue in issues
    }

    assert_true(
        "NON_GENERATED_STATUS" in codes,
        "Automatic acceptance was not blocked.",
    )


def test_mapping_order_is_deterministic():
    mapping = load_json(MAPPING_PATH)

    mappings = mapping["mappings"]

    actual = [
        (
            record["source_id"],
            record["competency_id"],
        )
        for record in mappings
    ]

    assert_true(
        actual == sorted(actual),
        "Mappings are not deterministically ordered.",
    )


def test_generator_output_is_deterministic():
    blueprint = load_json(BLUEPRINT_PATH)
    blueprint_validation = load_json(BLUEPRINT_VALIDATION_PATH)
    source_control = load_json(SOURCE_CONTROL_PATH)
    candidates = load_json(CANDIDATES_PATH)

    competencies, authoritative, excluded = generator.validate_upstream(
        blueprint,
        blueprint_validation,
        source_control,
        candidates,
    )

    first, first_unmapped = generator.build_mappings(
        candidates,
        competencies,
        authoritative,
        excluded,
    )

    second, second_unmapped = generator.build_mappings(
        candidates,
        competencies,
        authoritative,
        excluded,
    )

    assert_true(
        first == second,
        "Repeated generation produced different mapping records.",
    )

    assert_true(
        first_unmapped == second_unmapped,
        "Repeated generation produced different unmapped-source results.",
    )


def run_tests():
    tests = [
        test_valid_272_mapping_set,
        test_mapping_id_determinism,
        test_evidence_reference_determinism,
        test_duplicate_relationship_is_blocked,
        test_excluded_source_is_blocked,
        test_domain_mismatch_is_blocked,
        test_human_metadata_on_candidate_is_blocked,
        test_acceptance_without_human_decision_is_blocked,
        test_mapping_order_is_deterministic,
        test_generator_output_is_deterministic,
    ]

    passed = 0

    for test in tests:
        test()
        passed += 1
        print(f"PASS: {test.__name__}")

    print()
    print(f"L2.3-D tests passed: {passed}/{len(tests)}")


if __name__ == "__main__":
    run_tests()
