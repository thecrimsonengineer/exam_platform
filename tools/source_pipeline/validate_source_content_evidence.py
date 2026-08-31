from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]

if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.source_pipeline.l23a_evidence_schema import (
    SCHEMA_VERSION,
    STAGE_NAME,
    validate_evidence_document,
)


ROOT = Path(__file__).resolve().parents[2]

OUTPUT_PATH = (
    ROOT
    / "docs/source_pipeline/CSP11_source_content_evidence.json"
)

INSPECTION_PATH = (
    ROOT
    / "docs/source_pipeline/SRC-001_to_SRC-048_pdf_inspection.json"
)


FORBIDDEN_MAPPING_FIELDS = {
    "competency_id",
    "mapping_status",
    "mapping_confidence",
    "candidate_reason",
    "candidate_competency",
    "confirmed_mapping",
}


def load_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        raise FileNotFoundError(
            f"Required file not found: {path}"
        )

    with path.open(
        "r",
        encoding="utf-8",
    ) as handle:
        return json.load(handle)


def fail(message: str) -> None:
    print(f"FAIL: {message}")
    raise SystemExit(1)


def main() -> None:

    print(
        "===== L2.3-A A3-ALIGNED REGRESSION VALIDATION ====="
    )

    if not OUTPUT_PATH.exists():
        fail(
            "A4 output does not exist."
        )

    output = load_json(
        OUTPUT_PATH
    )

    inspection = load_json(
        INSPECTION_PATH
    )

    print(
        f"Schema version: "
        f"{output.get('schema_version')}"
    )

    print(
        f"Pipeline stage: "
        f"{output.get('stage')}"
    )

    # ---------------------------------------------------------
    # A3 AUTHORITATIVE SCHEMA VALIDATION
    # ---------------------------------------------------------

    errors = validate_evidence_document(
        output
    )

    if errors:

        for error in errors:
            print(
                f"SCHEMA ERROR: {error}"
            )

        fail(
            "A3 schema validation failed."
        )

    if output.get(
        "schema_version"
    ) != SCHEMA_VERSION:

        fail(
            "Unexpected schema version."
        )

    if output.get(
        "stage"
    ) != STAGE_NAME:

        fail(
            "Unexpected pipeline stage."
        )

    # ---------------------------------------------------------
    # SOURCE COUNT REGRESSION
    # ---------------------------------------------------------

    expected_sources = len(
        inspection.get(
            "inspection_results",
            [],
        )
    )

    actual_sources = len(
        output["source_evidence"]
    )

    if actual_sources != expected_sources:

        fail(
            "Source count mismatch: "
            f"expected {expected_sources}, "
            f"got {actual_sources}"
        )

    # ---------------------------------------------------------
    # SOURCE-LEVEL CONTRACT
    # ---------------------------------------------------------

    total_evidence_pages = 0
    total_pages_processed = 0
    sources_with_text = 0
    sources_without_text = 0

    evidence_ids: list[str] = []

    for source in output[
        "source_evidence"
    ]:

        source_id = source[
            "source_id"
        ]

        page_count = source[
            "page_count"
        ]

        pages_with_text = source[
            "pages_with_text"
        ]

        pages_without_text = source[
            "pages_without_text"
        ]

        evidence_pages = source[
            "evidence_pages"
        ]

        total_pages_processed += page_count
        total_evidence_pages += len(
            evidence_pages
        )

        if pages_with_text + pages_without_text != page_count:

            fail(
                f"{source_id}: page count arithmetic "
                "mismatch."
            )

        if len(evidence_pages) != pages_with_text:

            fail(
                f"{source_id}: evidence page count "
                "does not match pages_with_text."
            )

        status = source[
            "source_extraction_status"
        ]

        if status == "TEXT_EXTRACTED":

            sources_with_text += 1

            if pages_with_text == 0:

                fail(
                    f"{source_id}: TEXT_EXTRACTED "
                    "but pages_with_text is zero."
                )

        elif status == "NO_EXTRACTABLE_TEXT":

            sources_without_text += 1

            if pages_with_text != 0:

                fail(
                    f"{source_id}: NO_EXTRACTABLE_TEXT "
                    "but pages_with_text is non-zero."
                )

            if evidence_pages:

                fail(
                    f"{source_id}: NO_EXTRACTABLE_TEXT "
                    "but evidence pages exist."
                )

        else:

            fail(
                f"{source_id}: invalid "
                "source_extraction_status "
                f"{status!r}"
            )

        # -----------------------------------------------------
        # PAGE-LEVEL CONTRACT
        # -----------------------------------------------------

        previous_page = 0

        for evidence in evidence_pages:

            page_number = evidence[
                "page_number"
            ]

            if page_number <= previous_page:

                fail(
                    f"{source_id}: evidence pages "
                    "are not strictly ordered."
                )

            previous_page = page_number

            if evidence[
                "extraction_status"
            ] != "TEXT_EXTRACTED":

                fail(
                    f"{source_id} page "
                    f"{page_number}: invalid "
                    "extraction_status."
                )

            text = evidence[
                "text"
            ]

            if not isinstance(
                text,
                str,
            ) or not text.strip():

                fail(
                    f"{source_id} page "
                    f"{page_number}: empty text."
                )

            character_count = evidence[
                "text_character_count"
            ]

            if character_count != len(text):

                fail(
                    f"{source_id} page "
                    f"{page_number}: text_character_count "
                    "mismatch."
                )

            evidence_id = (
                f"{source_id}"
                f"-P{page_number:04d}"
            )

            evidence_ids.append(
                evidence_id
            )

    # ---------------------------------------------------------
    # GLOBAL EVIDENCE UNIQUENESS
    # ---------------------------------------------------------

    if len(evidence_ids) != len(
        set(evidence_ids)
    ):

        fail(
            "Duplicate evidence page IDs detected."
        )

    # ---------------------------------------------------------
    # EXTRACTION SUMMARY REGRESSION
    # ---------------------------------------------------------

    summary = output[
        "extraction_summary"
    ]

    if summary[
        "sources_processed"
    ] != actual_sources:

        fail(
            "extraction_summary.sources_processed "
            "mismatch."
        )

    if summary[
        "sources_with_extractable_text"
    ] != sources_with_text:

        fail(
            "extraction_summary.sources_with_extractable_text "
            "mismatch."
        )

    if summary[
        "sources_without_extractable_text"
    ] != sources_without_text:

        fail(
            "extraction_summary.sources_without_extractable_text "
            "mismatch."
        )

    if summary[
        "pages_processed"
    ] != total_pages_processed:

        fail(
            "extraction_summary.pages_processed "
            "mismatch."
        )

    if summary[
        "evidence_pages"
    ] != total_evidence_pages:

        fail(
            "extraction_summary.evidence_pages "
            "mismatch."
        )

    # ---------------------------------------------------------
    # A3 EXTRACTION POLICY
    # ---------------------------------------------------------

    policy = output[
        "extraction_policy"
    ]

    required_policy = {
        "extraction_engine": "PyMuPDF",
        "page_level_provenance": True,
        "full_text_extraction": True,
        "text_only": True,
        "competency_interpretation": False,
        "automatic_mapping": False,
        "automatic_confirmation": False,
    }

    for key, expected in required_policy.items():

        actual = policy.get(key)

        if actual != expected:

            fail(
                f"Policy violation: {key} "
                f"expected {expected!r}, "
                f"got {actual!r}"
            )

    # ---------------------------------------------------------
    # MAPPING CONTAMINATION CHECK
    # ---------------------------------------------------------

    def scan_for_mapping_fields(
        value: Any,
        path: str = "root",
    ) -> None:

        if isinstance(
            value,
            dict,
        ):

            for key, child in value.items():

                if key in FORBIDDEN_MAPPING_FIELDS:

                    fail(
                        f"Mapping field detected at "
                        f"{path}.{key}"
                    )

                scan_for_mapping_fields(
                    child,
                    f"{path}.{key}",
                )

        elif isinstance(
            value,
            list,
        ):

            for index, child in enumerate(
                value
            ):

                scan_for_mapping_fields(
                    child,
                    f"{path}[{index}]",
                )

    scan_for_mapping_fields(
        output
    )

    # ---------------------------------------------------------
    # JSON SERIALIZATION ROUND-TRIP
    # ---------------------------------------------------------

    serialized = json.dumps(
        output,
        indent=2,
        ensure_ascii=False,
    )

    reloaded = json.loads(
        serialized
    )

    reload_errors = (
        validate_evidence_document(
            reloaded
        )
    )

    if reload_errors:

        for error in reload_errors:
            print(
                f"ROUND-TRIP SCHEMA ERROR: {error}"
            )

        fail(
            "Serialization round-trip failed."
        )

    # ---------------------------------------------------------
    # FINAL RESULT
    # ---------------------------------------------------------

    print("")
    print(
        "===== A4 REGRESSION SUMMARY ====="
    )

    print(
        "Schema validation: PASS"
    )

    print(
        "Source count:",
        actual_sources,
    )

    print(
        "Sources with extractable text:",
        sources_with_text,
    )

    print(
        "Sources without extractable text:",
        sources_without_text,
    )

    print(
        "Pages processed:",
        total_pages_processed,
    )

    print(
        "Evidence pages:",
        total_evidence_pages,
    )

    print(
        "Duplicate evidence pages: 0"
    )

    print(
        "Mapping fields: 0"
    )

    print(
        "A3 extraction policy: PASS"
    )

    print(
        "Serialization round-trip: PASS"
    )

    print(
        "===== A4 REGRESSION RESULT: PASS ====="
    )


if __name__ == "__main__":
    main()

