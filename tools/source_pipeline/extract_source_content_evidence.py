"""
L2.3-A deterministic source-content evidence extractor.

This module extracts source PDF text at page level.

It does NOT:
- interpret CSP11 competencies
- classify source content
- perform competency mapping
- generate mapping candidates
- confirm mappings
- modify the CSP11 blueprint
- modify bibliographic outputs

Pipeline:
    PDF -> page-level source evidence

L2.3-B competency mapping is deliberately outside this module.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import sys

import pymupdf

ROOT = Path(__file__).resolve().parents[2]

if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.source_pipeline.l23a_evidence_schema import (
    SCHEMA_VERSION,
    build_empty_document,
    validate_evidence_document,
)


ROOT = Path(__file__).resolve().parents[2]

SOURCE_DIR = Path(r"C:\NAVEED\CSP11_Sources")

INSPECTION_PATH = (
    ROOT
    / "docs/source_pipeline/SRC-001_to_SRC-048_pdf_inspection.json"
)

OUTPUT_PATH = (
    ROOT
    / "docs/source_pipeline/CSP11_source_content_evidence.json"
)


EXTRACTION_ENGINE = "PyMuPDF"
TEXT_EXTRACTION_MODE = "text"
TEXT_SORT = True


def load_json(path: Path) -> dict[str, Any]:
    """Load a JSON object from disk."""
    if not path.exists():
        raise FileNotFoundError(
            f"Required input not found: {path}"
        )

    with path.open(
        "r",
        encoding="utf-8",
    ) as handle:
        data = json.load(handle)

    if not isinstance(data, dict):
        raise ValueError(
            f"Expected JSON object: {path}"
        )

    return data


def normalize_text(text: str) -> str:
    """
    Normalize extracted page text deterministically.

    Blank lines are removed and whitespace within each
    remaining line is normalized.
    """
    lines: list[str] = []

    for raw_line in text.splitlines():
        normalized_line = " ".join(
            raw_line.split()
        )

        if normalized_line:
            lines.append(normalized_line)

    return "\n".join(lines)


def extract_source(
    inspection_record: dict[str, Any],
) -> dict[str, Any]:
    """
    Extract page-level text evidence for one inspected source.

    No competency interpretation or mapping is performed.
    """

    source_id = inspection_record["source_id"]
    filename = inspection_record["filename"]

    pdf_path = SOURCE_DIR / filename

    source_record: dict[str, Any] = {
        "source_id": source_id,
        "filename": filename,
        "source_extraction_status": (
            "NO_EXTRACTABLE_TEXT"
        ),
        "page_count": int(
            inspection_record.get("page_count") or 0
        ),
        "pages_with_text": 0,
        "pages_without_text": 0,
        "text_page_ratio": 0.0,
        "evidence_pages": [],
    }

    if not pdf_path.exists():
        raise FileNotFoundError(
            f"{source_id}: source PDF not found: "
            f"{pdf_path}"
        )

    with pymupdf.open(pdf_path) as document:

        actual_page_count = len(document)

        source_record["page_count"] = (
            actual_page_count
        )

        for page_index, page in enumerate(document):

            page_number = page_index + 1

            raw_text = page.get_text(
                TEXT_EXTRACTION_MODE,
                sort=TEXT_SORT,
            )

            text = normalize_text(raw_text)

            if not text:
                source_record[
                    "pages_without_text"
                ] += 1
                continue

            source_record[
                "pages_with_text"
            ] += 1

            evidence_page = {
                "page_number": page_number,
                "extraction_status": (
                    "TEXT_EXTRACTED"
                ),
                "text_character_count": len(text),
                "text": text,
            }

            source_record[
                "evidence_pages"
            ].append(evidence_page)

        if actual_page_count > 0:
            source_record[
                "text_page_ratio"
            ] = round(
                source_record[
                    "pages_with_text"
                ]
                / actual_page_count,
                4,
            )

        if source_record[
            "pages_with_text"
        ] > 0:
            source_record[
                "source_extraction_status"
            ] = "TEXT_EXTRACTED"
        else:
            source_record[
                "source_extraction_status"
            ] = "NO_EXTRACTABLE_TEXT"

    return source_record


def main() -> None:
    """Run deterministic L2.3-A source extraction."""

    print(
        "===== L2.3-A SOURCE CONTENT EVIDENCE EXTRACTION ====="
    )

    inspection = load_json(
        INSPECTION_PATH
    )

    inspection_results = inspection.get(
        "inspection_results",
        [],
    )

    if not isinstance(
        inspection_results,
        list,
    ):
        raise ValueError(
            "inspection_results must be a list."
        )

    document = build_empty_document()

    results: list[dict[str, Any]] = []

    ordered_records = sorted(
        inspection_results,
        key=lambda record: record["source_id"],
    )

    for inspection_record in ordered_records:

        if not isinstance(
            inspection_record,
            dict,
        ):
            raise ValueError(
                "Invalid inspection record."
            )

        results.append(
            extract_source(
                inspection_record
            )
        )

    document[
        "source_count"
    ] = len(results)

    document[
        "source_evidence"
    ] = results

    sources_with_text = sum(
        1
        for source in results
        if source[
            "source_extraction_status"
        ]
        == "TEXT_EXTRACTED"
    )

    sources_without_text = sum(
        1
        for source in results
        if source[
            "source_extraction_status"
        ]
        == "NO_EXTRACTABLE_TEXT"
    )

    pages_processed = sum(
        source["page_count"]
        for source in results
    )

    evidence_pages = sum(
        len(source["evidence_pages"])
        for source in results
    )

    document[
        "extraction_summary"
    ] = {
        "sources_processed": len(results),
        "sources_with_extractable_text": (
            sources_with_text
        ),
        "sources_without_extractable_text": (
            sources_without_text
        ),
        "pages_processed": pages_processed,
        "evidence_pages": evidence_pages,
    }

    validation_errors = (
        validate_evidence_document(
            document
        )
    )

    if validation_errors:

        print(
            "===== A3 CONTRACT VALIDATION FAILED ====="
        )

        for error in validation_errors:
            print(
                f"ERROR: {error}"
            )

        raise SystemExit(1)

    OUTPUT_PATH.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    with OUTPUT_PATH.open(
        "w",
        encoding="utf-8",
        newline="\n",
    ) as handle:

        json.dump(
            document,
            handle,
            indent=2,
            ensure_ascii=False,
        )

        handle.write("\n")

    print(
        f"Schema version: {SCHEMA_VERSION}"
    )

    print(
        f"Sources processed: {len(results)}"
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
        f"Pages processed: {pages_processed}"
    )

    print(
        f"Evidence pages: {evidence_pages}"
    )

    print(
        "A3 schema validation: PASS"
    )

    print(
        f"Output: {OUTPUT_PATH}"
    )

    print(
        "Competency interpretation: NOT PERFORMED"
    )

    print(
        "Competency mapping: NOT PERFORMED"
    )


if __name__ == "__main__":
    main()
