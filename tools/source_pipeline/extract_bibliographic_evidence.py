import json
from pathlib import Path
from datetime import datetime
import re

INPUT_PATH = Path(
    "docs/source_pipeline/SRC-001_to_SRC-048_bibliographic_review.json"
)

OUTPUT_PATH = Path(
    "docs/source_pipeline/SRC-001_to_SRC-048_bibliographic_evidence.json"
)

with INPUT_PATH.open("r", encoding="utf-8") as f:
    review_data = json.load(f)

results = []

for source in review_data["review_results"]:

    pages = source.get("sample_pages", [])

    combined_text = "\n".join(
        page.get("text", "")
        for page in pages
    )

    text_lower = combined_text.lower()

    evidence = {
        "source_id": source["source_id"],
        "filename": source["filename"],

        "pdf_metadata": {
            "title": source.get("current_title"),
            "authors": source.get("current_authors"),
            "subject": source.get("current_subject"),
            "keywords": source.get("current_keywords"),
        },

        "page_count": source.get("page_count"),

        "sampled_page_count": len(pages),

        "text_evidence": {
            "total_characters": len(combined_text),
            "first_nonempty_page": None,
            "first_nonempty_page_text": "",
        },

        "bibliographic_signals": {
            "title_terms_found": [],
            "author_terms_found": [],
            "edition_terms_found": [],
            "publisher_terms_found": [],
            "identifier_terms_found": [],
            "year_candidates": [],
            "organisation_signals": [],
            "regulatory_signals": [],
        },

        "candidate_source_type": None,

        "review_status": "PENDING_HUMAN_REVIEW",
    }

    for page in pages:
        text = page.get("text", "").strip()

        if text:
            evidence["text_evidence"]["first_nonempty_page"] = (
                page.get("page_number")
            )
            evidence["text_evidence"]["first_nonempty_page_text"] = text[:12000]
            break

    signal_patterns = {
        "title_terms_found": [
            r"\btitle\b",
            r"\bbook\b",
            r"\bmanual\b",
            r"\bguide\b",
            r"\bhandbook\b",
            r"\breport\b",
            r"\bstandard\b",
        ],
        "author_terms_found": [
            r"\bauthor\b",
            r"\bby\b",
            r"\bauthored by\b",
            r"\bwritten by\b",
        ],
        "edition_terms_found": [
            r"\b\d+(st|nd|rd|th)\s+edition\b",
            r"\bedition\b",
            r"\brevised edition\b",
            r"\brevision\b",
            r"\bversion\b",
        ],
        "publisher_terms_found": [
            r"\bpublished by\b",
            r"\bpublisher\b",
            r"\bpublishing\b",
        ],
        "identifier_terms_found": [
            r"\bisbn\b",
            r"\bissn\b",
            r"\bdoi\b",
        ],
    }

    for field, patterns in signal_patterns.items():
        for pattern in patterns:
            if re.search(pattern, text_lower):
                evidence["bibliographic_signals"][field].append(pattern)

    years = sorted(
        set(
            re.findall(
                r"\b(?:19|20)\d{2}\b",
                combined_text
            )
        )
    )

    evidence["bibliographic_signals"]["year_candidates"] = years

    organisation_patterns = [
        "occupational safety",
        "occupational health",
        "health and safety",
        "safety administration",
        "government",
        "ministry",
        "department",
        "agency",
        "institute",
        "organisation",
        "organization",
        "international labour",
        "international labor",
        "standards",
    ]

    for term in organisation_patterns:
        if term in text_lower:
            evidence["bibliographic_signals"]["organisation_signals"].append(
                term
            )

    regulatory_patterns = [
        "regulation",
        "regulations",
        "regulatory",
        "code of practice",
        "guidance",
        "standard",
        "statutory",
        "legislation",
        "directive",
    ]

    for term in regulatory_patterns:
        if term in text_lower:
            evidence["bibliographic_signals"]["regulatory_signals"].append(
                term
            )

    results.append(evidence)

output = {
    "pipeline": "CSP11 Source-to-Domain Knowledge Pipeline",
    "stage": "L1.5.1 Bibliographic Evidence Extraction",
    "generated_at": datetime.now().isoformat(timespec="seconds"),
    "source_count": len(results),
    "method": (
        "Evidence extraction only. Detected terms and candidates are "
        "signals for human review and are not treated as final "
        "bibliographic classifications."
    ),
    "evidence_results": results,
}

with OUTPUT_PATH.open("w", encoding="utf-8") as f:
    json.dump(output, f, indent=2, ensure_ascii=False)

print("===== L1.5.1 BIBLIOGRAPHIC EVIDENCE EXTRACTION =====")
print(f"Sources processed: {len(results)}")

print(
    "Sources with sampled text:",
    sum(
        1
        for r in results
        if r["text_evidence"]["total_characters"] > 0
    )
)

print(
    "Sources with year candidates:",
    sum(
        1
        for r in results
        if r["bibliographic_signals"]["year_candidates"]
    )
)

print(
    "Sources with organisation signals:",
    sum(
        1
        for r in results
        if r["bibliographic_signals"]["organisation_signals"]
    )
)

print(
    "Sources with regulatory signals:",
    sum(
        1
        for r in results
        if r["bibliographic_signals"]["regulatory_signals"]
    )
)

print(f"Output: {OUTPUT_PATH}")
