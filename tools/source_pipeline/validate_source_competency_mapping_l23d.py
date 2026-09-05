from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
DOCS = ROOT / "docs" / "source_pipeline"

BLUEPRINT_PATH = DOCS / "CSP11_canonical_blueprint.json"
BLUEPRINT_VALIDATION_PATH = DOCS / "CSP11_canonical_blueprint_validation.json"
SOURCE_CONTROL_PATH = DOCS / "CSP11_source_control.json"
CANDIDATES_PATH = DOCS / "CSP11_source_to_competency_candidates.json"

MAPPING_PATH = DOCS / "CSP11_source_to_competency_mapping_l23d.json"
VALIDATION_PATH = DOCS / "CSP11_source_to_competency_mapping_l23d_validation.json"

PIPELINE = "CSP11 Source-to-Domain Knowledge Pipeline"
STAGE = "L2.3-D"

EXPECTED_SCHEMA = "L2.3-D.1"
EXPECTED_MAPPING_COUNT = 272
EXPECTED_AUTHORITATIVE_COUNT = 46
EXPECTED_COMPETENCY_COUNT = 47
EXPECTED_SOURCE_UNIVERSE = 48

EXPECTED_EXCLUDED = {"SRC-003", "SRC-014"}

ALLOWED_MAPPING_STATUSES = {
    "CANDIDATE",
    "ACCEPTED",
    "REJECTED",
    "HOLD",
}

ALLOWED_CONFIDENCE = {"HIGH", "MEDIUM", "LOW"}

RESERVED_HUMAN_STATUSES = {
    "ACCEPTED",
    "REJECTED",
    "HOLD",
}


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)

    if not isinstance(value, dict):
        raise ValueError(f"Expected JSON object: {path}")

    return value


def add_issue(
    issues: list[dict[str, Any]],
    code: str,
    message: str,
) -> None:
    issues.append(
        {
            "code": code,
            "message": message,
        }
    )


def add_warning(
    warnings: list[dict[str, Any]],
    code: str,
    message: str,
) -> None:
    warnings.append(
        {
            "code": code,
            "message": message,
        }
    )


def canonical_competencies(
    blueprint: dict[str, Any],
) -> dict[str, str]:
    result: dict[str, str] = {}

    for domain in blueprint.get("domains", []):
        domain_id = domain.get("domain_id")

        for competency in domain.get("competencies", []):
            competency_id = competency.get("competency_id")

            if competency_id:
                result[competency_id] = domain_id

    return result


def validate_source_control(
    source_control: dict[str, Any],
    issues: list[dict[str, Any]],
) -> tuple[set[str], set[str]]:
    authoritative = set(
        source_control.get("authoritative_source_ids", [])
    )
    excluded = set(
        source_control.get("excluded_source_ids", [])
    )

    if source_control.get("schema_version") != "L2.3-SC.1":
        add_issue(
            issues,
            "SOURCE_CONTROL_SCHEMA_INVALID",
            "Source control schema must be L2.3-SC.1.",
        )

    if len(authoritative) != EXPECTED_AUTHORITATIVE_COUNT:
        add_issue(
            issues,
            "AUTHORITATIVE_SOURCE_COUNT_INVALID",
            (
                "Expected 46 authoritative sources, found "
                f"{len(authoritative)}."
            ),
        )

    if len(excluded) != 2:
        add_issue(
            issues,
            "EXCLUDED_SOURCE_COUNT_INVALID",
            f"Expected 2 excluded sources, found {len(excluded)}.",
        )

    if authoritative & excluded:
        add_issue(
            issues,
            "SOURCE_BOUNDARY_OVERLAP",
            "Authoritative and excluded source sets overlap.",
        )

    if len(authoritative | excluded) != EXPECTED_SOURCE_UNIVERSE:
        add_issue(
            issues,
            "SOURCE_UNIVERSE_INVALID",
            "Source-control universe must contain exactly 48 sources.",
        )

    if excluded != EXPECTED_EXCLUDED:
        add_issue(
            issues,
            "EXCLUDED_SOURCE_IDS_INVALID",
            (
                "Excluded source IDs do not match the frozen boundary: "
                "SRC-003 and SRC-014."
            ),
        )

    return authoritative, excluded


def validate_upstream(
    blueprint: dict[str, Any],
    blueprint_validation: dict[str, Any],
    source_control: dict[str, Any],
    candidates: dict[str, Any],
    issues: list[dict[str, Any]],
) -> tuple[dict[str, str], set[str], set[str]]:
    if blueprint.get("pipeline") != PIPELINE:
        add_issue(
            issues,
            "BLUEPRINT_PIPELINE_MISMATCH",
            "Canonical blueprint pipeline mismatch.",
        )

    validation_summary = blueprint_validation.get("summary", {})

    if validation_summary.get("overall_status") != "VALID":
        add_issue(
            issues,
            "BLUEPRINT_VALIDATION_INVALID",
            "Canonical blueprint validation is not VALID.",
        )

    if candidates.get("schema_version") != "L2.3-C.1":
        add_issue(
            issues,
            "L23C_SCHEMA_INVALID",
            "L2.3-C candidate schema must be L2.3-C.1.",
        )

    candidate_summary = candidates.get("summary", {})

    if candidate_summary.get("overall_status") != "VALID":
        add_issue(
            issues,
            "L23C_VALIDATION_INVALID",
            "L2.3-C candidate validation status must be VALID.",
        )

    authoritative, excluded = validate_source_control(
        source_control,
        issues,
    )

    competencies = canonical_competencies(blueprint)

    if len(competencies) != EXPECTED_COMPETENCY_COUNT:
        add_issue(
            issues,
            "COMPETENCY_COUNT_INVALID",
            (
                "Expected 47 canonical competencies, found "
                f"{len(competencies)}."
            ),
        )

    return competencies, authoritative, excluded


def validate_mapping_record(
    record: Any,
    index: int,
    competencies: dict[str, str],
    authoritative: set[str],
    excluded: set[str],
    issues: list[dict[str, Any]],
    seen_relationships: set[tuple[str, str]],
) -> None:
    if not isinstance(record, dict):
        add_issue(
            issues,
            "MALFORMED_MAPPING_RECORD",
            f"Mapping index {index} is not an object.",
        )
        return

    required_fields = [
        "mapping_id",
        "source_id",
        "domain_id",
        "competency_id",
        "mapping_status",
        "mapping_basis",
        "candidate_confidence",
        "candidate_evidence_reference",
        "human_decision",
        "reviewer",
        "review_date",
        "review_notes",
    ]

    for field in required_fields:
        if field not in record:
            add_issue(
                issues,
                "MISSING_MAPPING_FIELD",
                f"Mapping index {index} is missing field '{field}'.",
            )

    source_id = record.get("source_id")
    competency_id = record.get("competency_id")
    domain_id = record.get("domain_id")
    mapping_status = record.get("mapping_status")
    mapping_id = record.get("mapping_id")
    confidence = record.get("candidate_confidence")
    evidence_reference = record.get(
        "candidate_evidence_reference"
    )

    if not isinstance(source_id, str) or not source_id:
        add_issue(
            issues,
            "INVALID_SOURCE_ID",
            f"Mapping index {index} has an invalid source_id.",
        )
    elif source_id not in authoritative:
        add_issue(
            issues,
            "NON_AUTHORITATIVE_SOURCE",
            f"{source_id} is not an authoritative source.",
        )

    if source_id in excluded:
        add_issue(
            issues,
            "EXCLUDED_SOURCE_MAPPED",
            f"{source_id} is excluded but appears in a mapping.",
        )

    if not isinstance(competency_id, str) or not competency_id:
        add_issue(
            issues,
            "INVALID_COMPETENCY_ID",
            f"Mapping index {index} has an invalid competency_id.",
        )
    elif competency_id not in competencies:
        add_issue(
            issues,
            "NON_CANONICAL_COMPETENCY",
            f"{competency_id} is not a canonical competency.",
        )

    if (
        isinstance(competency_id, str)
        and competency_id in competencies
        and domain_id != competencies[competency_id]
    ):
        add_issue(
            issues,
            "DOMAIN_COMPETENCY_MISMATCH",
            (
                f"{source_id} / {competency_id} has domain "
                f"{domain_id}, expected {competencies[competency_id]}."
            ),
        )

    if (
        isinstance(source_id, str)
        and isinstance(competency_id, str)
        and source_id
        and competency_id
    ):
        relationship = (source_id, competency_id)

        if relationship in seen_relationships:
            add_issue(
                issues,
                "DUPLICATE_RELATIONSHIP",
                (
                    f"Duplicate relationship: "
                    f"{source_id} / {competency_id}."
                ),
            )

        seen_relationships.add(relationship)

        expected_mapping_id = (
            f"MAP-{source_id}-{competency_id}"
        )

        if mapping_id != expected_mapping_id:
            add_issue(
                issues,
                "MAPPING_ID_INVALID",
                (
                    f"Invalid mapping_id for {source_id} / "
                    f"{competency_id}: {mapping_id}"
                ),
            )

        expected_reference = (
            "CSP11_source_to_competency_candidates.json"
            f"::{source_id}::{competency_id}"
        )

        if evidence_reference != expected_reference:
            add_issue(
                issues,
                "EVIDENCE_REFERENCE_INVALID",
                (
                    f"Invalid candidate evidence reference for "
                    f"{source_id} / {competency_id}."
                ),
            )

    if mapping_status not in ALLOWED_MAPPING_STATUSES:
        add_issue(
            issues,
            "INVALID_MAPPING_STATUS",
            (
                f"Invalid mapping status for {source_id} / "
                f"{competency_id}: {mapping_status}"
            ),
        )

    if mapping_status != "CANDIDATE":
        add_issue(
            issues,
            "NON_GENERATED_STATUS",
            (
                f"L2.3-D generator must not automatically resolve "
                f"{source_id} / {competency_id} to {mapping_status}."
            ),
        )

    if confidence not in ALLOWED_CONFIDENCE:
        add_issue(
            issues,
            "INVALID_CANDIDATE_CONFIDENCE",
            (
                f"Invalid candidate confidence for {source_id} / "
                f"{competency_id}: {confidence}"
            ),
        )

    if record.get("mapping_basis") != (
        "L2.3-C validated evidence-based candidate; human review required."
    ):
        add_issue(
            issues,
            "MAPPING_BASIS_INVALID",
            (
                f"Invalid mapping basis for {source_id} / "
                f"{competency_id}."
            ),
        )

    for field in (
        "human_decision",
        "reviewer",
        "review_date",
        "review_notes",
    ):
        if record.get(field) is not None:
            add_issue(
                issues,
                "HUMAN_METADATA_PRESENT",
                (
                    f"Generated candidate {source_id} / "
                    f"{competency_id} contains human field '{field}'."
                ),
            )

    if mapping_status in RESERVED_HUMAN_STATUSES:
        add_issue(
            issues,
            "UNAUTHORIZED_HUMAN_STATUS",
            (
                f"Human-resolution status {mapping_status} appeared "
                f"without human review."
            ),
        )


def validate_deterministic_order(
    mappings: list[Any],
    issues: list[dict[str, Any]],
) -> None:
    actual = [
        (
            record.get("source_id"),
            record.get("competency_id"),
        )
        for record in mappings
        if isinstance(record, dict)
    ]

    expected = sorted(actual)

    if actual != expected:
        add_issue(
            issues,
            "NON_DETERMINISTIC_ORDER",
            "Mappings are not ordered by source_id and competency_id.",
        )


def validate_relationship_completeness(
    mappings: list[Any],
    candidates: dict[str, Any],
    authoritative: set[str],
    issues: list[dict[str, Any]],
) -> set[tuple[str, str]]:
    candidate_relationships: set[tuple[str, str]] = set()

    for source_record in candidates.get("source_candidates", []):
        source_id = source_record.get("source_id")

        if source_id not in authoritative:
            continue

        for candidate in source_record.get(
            "candidate_mappings",
            [],
        ):
            if not isinstance(candidate, dict):
                continue

            competency_id = candidate.get("competency_id")

            if isinstance(competency_id, str):
                candidate_relationships.add(
                    (source_id, competency_id)
                )

    mapping_relationships: set[tuple[str, str]] = set()

    for record in mappings:
        if not isinstance(record, dict):
            continue

        source_id = record.get("source_id")
        competency_id = record.get("competency_id")

        if isinstance(source_id, str) and isinstance(
            competency_id,
            str,
        ):
            mapping_relationships.add(
                (source_id, competency_id)
            )

    missing = candidate_relationships - mapping_relationships
    extra = mapping_relationships - candidate_relationships

    if missing:
        add_issue(
            issues,
            "MISSING_UPSTREAM_RELATIONSHIPS",
            f"{len(missing)} L2.3-C relationships are missing.",
        )

    if extra:
        add_issue(
            issues,
            "UNEXPECTED_RELATIONSHIPS",
            f"{len(extra)} relationships are not present in L2.3-C.",
        )

    return mapping_relationships


def main() -> None:
    issues: list[dict[str, Any]] = []
    warnings: list[dict[str, Any]] = []

    blueprint = load_json(BLUEPRINT_PATH)
    blueprint_validation = load_json(
        BLUEPRINT_VALIDATION_PATH
    )
    source_control = load_json(SOURCE_CONTROL_PATH)
    candidates = load_json(CANDIDATES_PATH)
    mapping = load_json(MAPPING_PATH)

    competencies, authoritative, excluded = validate_upstream(
        blueprint,
        blueprint_validation,
        source_control,
        candidates,
        issues,
    )

    if mapping.get("pipeline") != PIPELINE:
        add_issue(
            issues,
            "MAPPING_PIPELINE_MISMATCH",
            "L2.3-D mapping pipeline mismatch.",
        )

    if mapping.get("stage") != STAGE:
        add_issue(
            issues,
            "MAPPING_STAGE_MISMATCH",
            "Mapping stage must be L2.3-D.",
        )

    if mapping.get("schema_version") != EXPECTED_SCHEMA:
        add_issue(
            issues,
            "MAPPING_SCHEMA_INVALID",
            f"Expected schema {EXPECTED_SCHEMA}.",
        )

    if mapping.get("generated_at") is not None:
        add_issue(
            issues,
            "NON_DETERMINISTIC_TIMESTAMP",
            "generated_at must be null for deterministic output.",
        )

    mappings = mapping.get("mappings")

    if not isinstance(mappings, list):
        add_issue(
            issues,
            "MAPPINGS_NOT_ARRAY",
            "The mappings field must be an array.",
        )
        mappings = []

    seen_relationships: set[tuple[str, str]] = set()

    for index, record in enumerate(mappings):
        validate_mapping_record(
            record,
            index,
            competencies,
            authoritative,
            excluded,
            issues,
            seen_relationships,
        )

    validate_deterministic_order(
        mappings,
        issues,
    )

    relationship_set = validate_relationship_completeness(
        mappings,
        candidates,
        authoritative,
        issues,
    )

    actual_candidate_count = sum(
        1
        for record in mappings
        if isinstance(record, dict)
        and record.get("mapping_status") == "CANDIDATE"
    )

    actual_resolved_count = sum(
        1
        for record in mappings
        if isinstance(record, dict)
        and record.get("mapping_status") in RESERVED_HUMAN_STATUSES
    )

    source_ids_with_mappings = {
        record.get("source_id")
        for record in mappings
        if isinstance(record, dict)
        and isinstance(record.get("source_id"), str)
    }

    unmapped_sources = sorted(
        authoritative - source_ids_with_mappings
    )

    if len(mappings) != EXPECTED_MAPPING_COUNT:
        add_issue(
            issues,
            "MAPPING_COUNT_INVALID",
            (
                f"Expected {EXPECTED_MAPPING_COUNT} mappings, "
                f"found {len(mappings)}."
            ),
        )

    if actual_candidate_count != EXPECTED_MAPPING_COUNT:
        add_issue(
            issues,
            "CANDIDATE_COUNT_INVALID",
            (
                f"Expected {EXPECTED_MAPPING_COUNT} CANDIDATE mappings, "
                f"found {actual_candidate_count}."
            ),
        )

    if actual_resolved_count != 0:
        add_issue(
            issues,
            "RESOLVED_COUNT_INVALID",
            (
                "L2.3-D must contain zero automatically resolved "
                "mappings."
            ),
        )

    if len(unmapped_sources) != 4:
        add_issue(
            issues,
            "UNMAPPED_SOURCE_COUNT_INVALID",
            (
                f"Expected 4 unmapped authoritative sources, "
                f"found {len(unmapped_sources)}."
            ),
        )

    expected_summary = mapping.get("summary", {})

    if expected_summary.get("overall_status") != "VALID":
        add_issue(
            issues,
            "SUMMARY_STATUS_INVALID",
            "Mapping summary overall_status must be VALID.",
        )

    if expected_summary.get("candidate_relationships_do_not_confirm_coverage") is not True:
        add_issue(
            issues,
            "COVERAGE_FLAG_INVALID",
            (
                "Mapping artifact must explicitly state that candidate "
                "relationships do not confirm coverage."
            ),
        )

    if not issues:
        status = "VALID"
    else:
        status = "INVALID"

    result = {
        "pipeline": PIPELINE,
        "stage": STAGE,
        "schema_version": "L2.3-D.V1",
        "validated_artifact": "CSP11_source_to_competency_mapping_l23d.json",
        "overall_status": status,
        "counts": {
            "source_count": len(authoritative),
            "competency_count": len(competencies),
            "mapping_count": len(mappings),
            "candidate_mapping_count": actual_candidate_count,
            "resolved_mapping_count": actual_resolved_count,
            "unmapped_authoritative_source_count": len(unmapped_sources),
            "relationship_count_checked": len(relationship_set),
        },
        "expected_counts": {
            "source_count": EXPECTED_AUTHORITATIVE_COUNT,
            "competency_count": EXPECTED_COMPETENCY_COUNT,
            "mapping_count": EXPECTED_MAPPING_COUNT,
            "candidate_mapping_count": EXPECTED_MAPPING_COUNT,
            "resolved_mapping_count": 0,
            "unmapped_authoritative_source_count": 4,
        },
        "unmapped_authoritative_source_ids": unmapped_sources,
        "blocking_issues": issues,
        "warnings": warnings,
        "quality_gate": {
            "source_control_boundary_verified": True,
            "canonical_competency_boundary_verified": True,
            "upstream_l23c_validity_required": True,
            "relationship_identity_verified": True,
            "mapping_id_determinism_verified": True,
            "evidence_reference_determinism_verified": True,
            "human_review_fields_null_for_candidates": True,
            "automatic_acceptance_prohibited": True,
            "candidate_status_only_for_generated_records": True,
            "candidate_relationships_do_not_confirm_coverage": True,
            "deterministic_order_verified": not any(
                issue["code"] == "NON_DETERMINISTIC_ORDER"
                for issue in issues
            ),
        },
    }

    VALIDATION_PATH.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    with VALIDATION_PATH.open(
        "w",
        encoding="utf-8",
        newline="\n",
    ) as handle:
        json.dump(
            result,
            handle,
            indent=2,
            ensure_ascii=False,
        )
        handle.write("\n")

    print("L2.3-D validation complete.")
    print(f"Status: {status}")
    print(f"Mappings checked: {len(mappings)}")
    print(f"Candidate mappings: {actual_candidate_count}")
    print(f"Resolved mappings: {actual_resolved_count}")
    print(
        "Unmapped authoritative sources: "
        f"{len(unmapped_sources)}"
    )
    print(f"Blocking issues: {len(issues)}")
    print(f"Warnings: {len(warnings)}")
    print(f"Validation artifact: {VALIDATION_PATH}")

    if issues:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
