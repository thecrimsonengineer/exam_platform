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

OUTPUT_PATH = DOCS / "CSP11_source_to_competency_mapping_l23d.json"


PIPELINE = "CSP11 Source-to-Domain Knowledge Pipeline"
STAGE = "L2.3-D"

MAPPING_STATUS = "CANDIDATE"
MAPPING_BASIS = (
    "L2.3-C validated evidence-based candidate; human review required."
)

EXPECTED_SOURCE_UNIVERSE = 48
EXPECTED_AUTHORITATIVE_COUNT = 46
EXPECTED_COMPETENCY_COUNT = 47

EXCLUDED_SOURCE_IDS = {"SRC-003", "SRC-014"}


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)

    if not isinstance(value, dict):
        raise ValueError(f"Expected JSON object: {path}")

    return value


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def canonical_competencies(blueprint: dict[str, Any]) -> dict[str, str]:
    result: dict[str, str] = {}

    for domain in blueprint.get("domains", []):
        domain_id = domain.get("domain_id")

        for competency in domain.get("competencies", []):
            competency_id = competency.get("competency_id")

            if competency_id:
                result[competency_id] = domain_id

    return result


def source_control_ids(source_control: dict[str, Any]) -> tuple[set[str], set[str]]:
    authoritative = set(source_control.get("authoritative_source_ids", []))
    excluded = set(source_control.get("excluded_source_ids", []))

    return authoritative, excluded


def validate_upstream(
    blueprint: dict[str, Any],
    blueprint_validation: dict[str, Any],
    source_control: dict[str, Any],
    candidates: dict[str, Any],
) -> tuple[dict[str, str], set[str], set[str]]:
    require(
        blueprint.get("pipeline") == PIPELINE,
        "Canonical blueprint pipeline mismatch.",
    )

    validation_summary = blueprint_validation.get("summary", {})
    require(
        validation_summary.get("overall_status") == "VALID",
        "Canonical blueprint validation is not VALID.",
    )

    require(
        source_control.get("schema_version") == "L2.3-SC.1",
        "Source control schema must be L2.3-SC.1.",
    )

    require(
        candidates.get("schema_version") == "L2.3-C.1",
        "L2.3-C candidate schema must be L2.3-C.1.",
    )

    candidate_summary = candidates.get("summary", {})
    require(
        candidate_summary.get("overall_status") == "VALID",
        "L2.3-C candidate validation status must be VALID.",
    )

    authoritative, excluded = source_control_ids(source_control)

    require(
        len(authoritative) == EXPECTED_AUTHORITATIVE_COUNT,
        "Unexpected authoritative source count.",
    )
    require(
        len(excluded) == 2,
        "Unexpected excluded source count.",
    )
    require(
        authoritative.isdisjoint(excluded),
        "Authoritative and excluded source sets overlap.",
    )
    require(
        len(authoritative | excluded) == EXPECTED_SOURCE_UNIVERSE,
        "Source control universe is not 48 sources.",
    )
    require(
        excluded == EXCLUDED_SOURCE_IDS,
        "Excluded source IDs do not match the frozen source-control boundary.",
    )

    competencies = canonical_competencies(blueprint)

    require(
        len(competencies) == EXPECTED_COMPETENCY_COUNT,
        "Unexpected canonical competency count.",
    )

    return competencies, authoritative, excluded


def candidate_records(candidates: dict[str, Any]):
    for source_record in candidates.get("source_candidates", []):
        source_id = source_record.get("source_id")

        for candidate in source_record.get("candidate_mappings", []):
            yield source_id, source_record, candidate


def build_mapping_id(source_id: str, competency_id: str) -> str:
    return f"MAP-{source_id}-{competency_id}"


def build_evidence_reference(source_id: str, competency_id: str) -> str:
    return (
        "CSP11_source_to_competency_candidates.json"
        f"::{source_id}::{competency_id}"
    )


def build_mappings(
    candidates: dict[str, Any],
    competencies: dict[str, str],
    authoritative: set[str],
    excluded: set[str],
) -> tuple[list[dict[str, Any]], list[str]]:
    relationships: dict[tuple[str, str], dict[str, Any]] = {}
    unmapped_sources = set(authoritative)

    for source_id, source_record, candidate in candidate_records(candidates):
        require(
            source_id in authoritative,
            f"Candidate references non-authoritative source: {source_id}",
        )
        require(
            source_id not in excluded,
            f"Excluded source appeared in candidates: {source_id}",
        )

        require(
            isinstance(candidate, dict),
            f"Malformed candidate for {source_id}.",
        )

        competency_id = candidate.get("competency_id")
        domain_id = candidate.get("domain_id")
        mapping_status = candidate.get("mapping_status")
        confidence = candidate.get("confidence")
        evidence_basis = candidate.get("evidence_basis")

        require(
            isinstance(competency_id, str) and competency_id,
            f"Missing competency_id for {source_id}.",
        )
        require(
            competency_id in competencies,
            f"Invalid canonical competency: {competency_id}",
        )

        expected_domain = competencies[competency_id]

        require(
            domain_id == expected_domain,
            (
                f"Domain mismatch for {source_id} / {competency_id}: "
                f"{domain_id} != {expected_domain}"
            ),
        )

        require(
            mapping_status == "candidate",
            (
                f"Upstream candidate status must be 'candidate' for "
                f"{source_id} / {competency_id}."
            ),
        )

        require(
            confidence in {"high", "medium", "low"},
            f"Invalid confidence for {source_id} / {competency_id}.",
        )

        require(
            isinstance(evidence_basis, list) and evidence_basis,
            f"Missing evidence basis for {source_id} / {competency_id}.",
        )

        for evidence in evidence_basis:
            require(
                isinstance(evidence, dict),
                f"Malformed evidence basis for {source_id} / {competency_id}.",
            )
            require(
                isinstance(evidence.get("page_number"), int)
                and evidence.get("page_number") >= 1,
                f"Invalid evidence page for {source_id} / {competency_id}.",
            )
            require(
                isinstance(evidence.get("supporting_text"), str)
                and evidence.get("supporting_text").strip(),
                f"Missing supporting text for {source_id} / {competency_id}.",
            )

        relationship = (source_id, competency_id)

        require(
            relationship not in relationships,
            (
                f"Duplicate relationship detected: "
                f"{source_id} / {competency_id}"
            ),
        )

        relationships[relationship] = {
            "mapping_id": build_mapping_id(source_id, competency_id),
            "source_id": source_id,
            "domain_id": domain_id,
            "competency_id": competency_id,
            "mapping_status": MAPPING_STATUS,
            "mapping_basis": MAPPING_BASIS,
            "candidate_confidence": confidence.upper(),
            "candidate_evidence_reference": build_evidence_reference(
                source_id,
                competency_id,
            ),
            "human_decision": None,
            "reviewer": None,
            "review_date": None,
            "review_notes": None,
        }

        unmapped_sources.discard(source_id)

    mappings = [
        relationships[key]
        for key in sorted(relationships, key=lambda item: (item[0], item[1]))
    ]

    return mappings, sorted(unmapped_sources)


def main() -> None:
    blueprint = load_json(BLUEPRINT_PATH)
    blueprint_validation = load_json(BLUEPRINT_VALIDATION_PATH)
    source_control = load_json(SOURCE_CONTROL_PATH)
    candidates = load_json(CANDIDATES_PATH)

    competencies, authoritative, excluded = validate_upstream(
        blueprint,
        blueprint_validation,
        source_control,
        candidates,
    )

    mappings, unmapped_sources = build_mappings(
        candidates,
        competencies,
        authoritative,
        excluded,
    )

    require(
        len(mappings) == candidates.get("candidate_count"),
        (
            "Generated mapping count does not match upstream candidate count: "
            f"{len(mappings)} != {candidates.get('candidate_count')}"
        ),
    )

    result = {
        "pipeline": PIPELINE,
        "stage": STAGE,
        "generated_at": None,
        "schema_version": "L2.3-D.1",
        "input_references": {
            "canonical_blueprint": "CSP11_canonical_blueprint.json",
            "canonical_blueprint_validation": (
                "CSP11_canonical_blueprint_validation.json"
            ),
            "source_control": "CSP11_source_control.json",
            "l23c_candidates": (
                "CSP11_source_to_competency_candidates.json"
            ),
        },
        "mapping_policy": {
            "relationship_identity": [
                "source_id",
                "competency_id",
            ],
            "generated_status": "CANDIDATE",
            "human_review_required": True,
            "accepted_does_not_equal_complete_competency_coverage": True,
            "deterministic_order": [
                "source_id",
                "competency_id",
            ],
            "automatic_human_decisions": False,
        },
        "source_reference": {
            "source_universe_count": EXPECTED_SOURCE_UNIVERSE,
            "authoritative_source_count": len(authoritative),
            "excluded_source_count": len(excluded),
            "authoritative_source_ids": sorted(authoritative),
            "excluded_source_ids": sorted(excluded),
        },
        "blueprint_reference": {
            "competency_count": len(competencies),
            "canonical_competency_ids": sorted(competencies),
        },
        "status_definitions": {
            "CANDIDATE": (
                "Generated from a validated L2.3-C candidate relationship "
                "and awaiting human review."
            ),
            "ACCEPTED": (
                "Reserved for a human-approved relationship. "
                "Not generated automatically by L2.3-D."
            ),
            "REJECTED": (
                "Reserved for a human-rejected relationship. "
                "Not generated automatically by L2.3-D."
            ),
            "HOLD": (
                "Reserved for a human-held relationship. "
                "Not generated automatically by L2.3-D."
            ),
        },
        "mapping_schema": {
            "required_fields": [
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
            ],
            "human_fields_initially_null": [
                "human_decision",
                "reviewer",
                "review_date",
                "review_notes",
            ],
        },
        "counts": {
            "mapping_count": len(mappings),
            "candidate_mapping_count": len(mappings),
            "accepted_mapping_count": 0,
            "rejected_mapping_count": 0,
            "hold_mapping_count": 0,
            "resolved_mapping_count": 0,
            "unmapped_authoritative_source_count": len(unmapped_sources),
        },
        "mappings": mappings,
        "summary": {
            "overall_status": "VALID",
            "source_count": len(authoritative),
            "competency_count": len(competencies),
            "mapping_count": len(mappings),
            "candidate_mapping_count": len(mappings),
            "pending_human_review_count": len(mappings),
            "resolved_mapping_count": 0,
            "unmapped_authoritative_source_count": len(unmapped_sources),
            "unmapped_authoritative_source_ids": unmapped_sources,
            "blocking_issues": 0,
            "warnings": len(unmapped_sources),
            "candidate_relationships_do_not_confirm_coverage": True,
        },
        "issues": [],
        "warnings": [
            (
                f"Authoritative source {source_id} has no generated "
                "L2.3-D candidate mapping."
            )
            for source_id in unmapped_sources
        ],
    }

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)

    with OUTPUT_PATH.open("w", encoding="utf-8", newline="\n") as handle:
        json.dump(result, handle, indent=2, ensure_ascii=False)
        handle.write("\n")

    print("L2.3-D mapping generation complete.")
    print(f"Output: {OUTPUT_PATH}")
    print(f"Mappings: {len(mappings)}")
    print(f"Unmapped authoritative sources: {len(unmapped_sources)}")
    print("Status: CANDIDATE")
    print("Human decisions generated: 0")


if __name__ == "__main__":
    main()
