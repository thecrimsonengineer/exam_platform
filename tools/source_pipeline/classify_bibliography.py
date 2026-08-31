import json
from pathlib import Path
from datetime import datetime

INPUT_PATH = Path(
    "docs/source_pipeline/SRC-001_to_SRC-048_bibliographic_review.json"
)

OUTPUT_PATH = Path(
    "docs/source_pipeline/SRC-001_to_SRC-048_bibliographic_classification.json"
)

with INPUT_PATH.open("r", encoding="utf-8") as f:
    review_data = json.load(f)

results = []

for source in review_data["review_results"]:

    source_id = source["source_id"]

    combined_text = "\n".join(
        page.get("text", "")
        for page in source.get("sample_pages", [])
    ).strip()

    classification = {
        "source_id": source_id,
        "filename": source["filename"],

        "current_pdf_metadata": {
            "title": source.get("current_title"),
            "authors": source.get("current_authors"),
            "subject": source.get("current_subject"),
            "keywords": source.get("current_keywords"),
        },

        "page_count": source.get("page_count"),

        "evidence": {
            "sampled_pages": len(source.get("sample_pages", [])),
            "sample_text_characters": len(combined_text),
            "has_extractable_sample_text": bool(combined_text),
        },

        "bibliographic_classification": {
            "source_type": "UNCLASSIFIED",
            "title": None,
            "author_or_organisation": None,
            "edition_or_version": None,
            "publisher": None,
            "publication_year": None,
            "isbn_or_identifier": None,
            "official_or_regulatory_source": None,
            "confidence": "UNASSESSED",
        },

        "review_flags": [],

        "classification_status": "PENDING_HUMAN_REVIEW",
    }

    if not combined_text:
        classification["review_flags"].append(
            "No extractable text found in sampled pages."
        )

    if source.get("current_title"):
        classification["review_flags"].append(
            "PDF metadata contains a title that should be checked against visible source evidence."
        )

    if source.get("current_authors"):
        classification["review_flags"].append(
            "PDF metadata contains author information that should be checked against visible source evidence."
        )

    if source.get("current_title") and source.get("current_authors"):
        classification["bibliographic_classification"]["confidence"] = (
            "METADATA_AVAILABLE_VERIFY"
        )

    results.append(classification)

output = {
    "pipeline": "CSP11 Source-to-Domain Knowledge Pipeline",
    "stage": "L1.5 Bibliographic Review and Source Classification",
    "generated_at": datetime.now().isoformat(timespec="seconds"),
    "input_source_count": review_data["review_count"],
    "classification_count": len(results),
    "method": (
        "Structured bibliographic classification prepared from "
        "PDF metadata and sampled-page evidence. Missing values are "
        "left null until supported by source evidence or human review."
    ),
    "classification_results": results,
}

with OUTPUT_PATH.open("w", encoding="utf-8") as f:
    json.dump(output, f, indent=2, ensure_ascii=False)

print("===== L1.5 BIBLIOGRAPHIC CLASSIFICATION STARTED =====")
print(f"Sources received: {review_data['review_count']}")
print(f"Classification records created: {len(results)}")

print(
    "Metadata title available:",
    sum(
        1
        for r in results
        if r["current_pdf_metadata"]["title"]
    )
)

print(
    "Metadata author available:",
    sum(
        1
        for r in results
        if r["current_pdf_metadata"]["authors"]
    )
)

print(
    "Awaiting human review:",
    sum(
        1
        for r in results
        if r["classification_status"] == "PENDING_HUMAN_REVIEW"
    )
)

print(f"Output: {OUTPUT_PATH}")
