"""
L2.3-A deterministic source-content evidence schema.

This module defines and validates the output contract for
L2.3-A Source-Content Evidence Extraction.

It performs no PDF extraction and no CSP11 competency interpretation.
"""

from __future__ import annotations

from typing import Any


SCHEMA_VERSION = "L2.3-A.1"
PIPELINE_NAME = "CSP11 Source-to-Domain Knowledge Pipeline"
STAGE_NAME = "L2.3-A Source-Content Evidence Extraction"

EXTRACTION_STATUSES = {
    "TEXT_EXTRACTED",
    "NO_EXTRACTABLE_TEXT",
}


def validate_evidence_document(document: dict[str, Any]) -> list[str]:
    """Validate the deterministic L2.3-A evidence document structure."""
    errors: list[str] = []

    required_top_level = {
        "pipeline",
        "stage",
        "schema_version",
        "source_count",
        "extraction_summary",
        "extraction_policy",
        "source_evidence",
    }

    missing = sorted(required_top_level - set(document))
    for field in missing:
        errors.append(f"Missing top-level field: {field}")

    if errors:
        return errors

    if document["pipeline"] != PIPELINE_NAME:
        errors.append("Invalid pipeline value.")

    if document["stage"] != STAGE_NAME:
        errors.append("Invalid stage value.")

    if document["schema_version"] != SCHEMA_VERSION:
        errors.append("Invalid schema_version.")

    if not isinstance(document["source_count"], int):
        errors.append("source_count must be an integer.")

    if not isinstance(document["source_evidence"], list):
        errors.append("source_evidence must be an array.")
        return errors

    source_ids: list[str] = []

    for index, source in enumerate(document["source_evidence"]):
        prefix = f"source_evidence[{index}]"

        if not isinstance(source, dict):
            errors.append(f"{prefix} must be an object.")
            continue

        required_source = {
            "source_id",
            "filename",
            "source_extraction_status",
            "page_count",
            "pages_with_text",
            "pages_without_text",
            "text_page_ratio",
            "evidence_pages",
        }

        for field in sorted(required_source - set(source)):
            errors.append(f"{prefix} missing field: {field}")

        source_id = source.get("source_id")

        if not isinstance(source_id, str) or not source_id.strip():
            errors.append(f"{prefix}.source_id must be a non-empty string.")
        else:
            source_ids.append(source_id)

        if source.get("source_extraction_status") not in EXTRACTION_STATUSES:
            errors.append(
                f"{prefix}.source_extraction_status has an invalid value."
            )

        if not isinstance(source.get("filename"), str):
            errors.append(f"{prefix}.filename must be a string.")

        for field in (
            "page_count",
            "pages_with_text",
            "pages_without_text",
        ):
            if not isinstance(source.get(field), int):
                errors.append(f"{prefix}.{field} must be an integer.")

        if not isinstance(source.get("text_page_ratio"), (int, float)):
            errors.append(f"{prefix}.text_page_ratio must be numeric.")

        evidence_pages = source.get("evidence_pages")

        if not isinstance(evidence_pages, list):
            errors.append(f"{prefix}.evidence_pages must be an array.")
            continue

        page_numbers: list[int] = []

        for page_index, evidence in enumerate(evidence_pages):
            eprefix = f"{prefix}.evidence_pages[{page_index}]"

            if not isinstance(evidence, dict):
                errors.append(f"{eprefix} must be an object.")
                continue

            required_evidence = {
                "page_number",
                "extraction_status",
                "text_character_count",
                "text",
            }

            for field in sorted(required_evidence - set(evidence)):
                errors.append(f"{eprefix} missing field: {field}")

            page_number = evidence.get("page_number")

            if not isinstance(page_number, int) or page_number < 1:
                errors.append(
                    f"{eprefix}.page_number must be a positive integer."
                )
            else:
                page_numbers.append(page_number)

            if evidence.get("extraction_status") != "TEXT_EXTRACTED":
                errors.append(
                    f"{eprefix}.extraction_status must be TEXT_EXTRACTED."
                )

            text = evidence.get("text")

            if not isinstance(text, str):
                errors.append(f"{eprefix}.text must be a string.")
            elif not text.strip():
                errors.append(f"{eprefix}.text must not be empty.")

            if not isinstance(evidence.get("text_character_count"), int):
                errors.append(
                    f"{eprefix}.text_character_count must be an integer."
                )

        if page_numbers != sorted(page_numbers):
            errors.append(
                f"{prefix}.evidence_pages are not ordered by page_number."
            )

        if len(page_numbers) != len(set(page_numbers)):
            errors.append(
                f"{prefix} contains duplicate evidence page numbers."
            )

    if source_ids != sorted(source_ids):
        errors.append("source_evidence is not ordered by source_id.")

    if len(source_ids) != len(set(source_ids)):
        errors.append("Duplicate source_id detected.")

    if document.get("source_count") != len(source_ids):
        errors.append(
            "source_count does not match source_evidence length."
        )

    policy = document.get("extraction_policy")

    if not isinstance(policy, dict):
        errors.append("extraction_policy must be an object.")
    else:
        required_policy = {
            "extraction_engine",
            "page_level_provenance",
            "full_text_extraction",
            "text_only",
            "competency_interpretation",
            "automatic_mapping",
            "automatic_confirmation",
        }

        for field in sorted(required_policy - set(policy)):
            errors.append(f"Missing extraction_policy field: {field}")

        if policy.get("extraction_engine") != "PyMuPDF":
            errors.append("extraction_engine must be PyMuPDF.")

        for field in (
            "page_level_provenance",
            "full_text_extraction",
            "text_only",
            "competency_interpretation",
            "automatic_mapping",
            "automatic_confirmation",
        ):
            if field in policy and not isinstance(policy[field], bool):
                errors.append(
                    f"extraction_policy.{field} must be boolean."
                )

        if policy.get("competency_interpretation") is not False:
            errors.append(
                "competency_interpretation must be false."
            )

        if policy.get("automatic_mapping") is not False:
            errors.append("automatic_mapping must be false.")

        if policy.get("automatic_confirmation") is not False:
            errors.append("automatic_confirmation must be false.")

    return errors


def build_empty_document() -> dict[str, Any]:
    """Return the deterministic A3 schema container."""
    return {
        "pipeline": PIPELINE_NAME,
        "stage": STAGE_NAME,
        "schema_version": SCHEMA_VERSION,
        "source_count": 0,
        "extraction_summary": {
            "sources_processed": 0,
            "sources_with_extractable_text": 0,
            "sources_without_extractable_text": 0,
            "pages_processed": 0,
            "evidence_pages": 0,
        },
        "extraction_policy": {
            "extraction_engine": "PyMuPDF",
            "page_level_provenance": True,
            "full_text_extraction": True,
            "text_only": True,
            "competency_interpretation": False,
            "automatic_mapping": False,
            "automatic_confirmation": False,
        },
        "source_evidence": [],
    }
