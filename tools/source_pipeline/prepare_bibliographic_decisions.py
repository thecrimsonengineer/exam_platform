import json
from pathlib import Path
from datetime import datetime

INPUT_PATH = Path(
    "docs/source_pipeline/SRC-001_to_SRC-048_bibliographic_candidates.json"
)

OUTPUT_PATH = Path(
    "docs/source_pipeline/SRC-001_to_SRC-048_bibliographic_decisions.json"
)

with INPUT_PATH.open("r", encoding="utf-8") as f:
    candidate_data = json.load(f)

results = []

for source in candidate_data["candidate_results"]:

    candidates = source.get("candidates", {})
    metadata = source.get("pdf_metadata", {})

    title_candidates = candidates.get("title_candidates", [])
    author_candidates = candidates.get(
        "author_or_organisation_candidates", []
    )
    edition_candidates = candidates.get(
        "edition_or_version_candidates", []
    )
    publisher_candidates = candidates.get(
        "publisher_candidates", []
    )
    year_candidates = candidates.get(
        "publication_year_candidates", []
    )
    identifier_candidates = candidates.get(
        "identifier_candidates", []
    )

    result = {
        "source_id": source["source_id"],
        "filename": source["filename"],
        "page_count": source.get("page_count"),

        "candidate_confidence": source.get(
            "candidate_confidence",
            "LOW"
        ),

        "candidate_evidence": {
            "title_candidates": title_candidates,
            "author_or_organisation_candidates": author_candidates,
            "edition_or_version_candidates": edition_candidates,
            "publisher_candidates": publisher_candidates,
            "publication_year_candidates": year_candidates,
            "identifier_candidates": identifier_candidates,
        },

        "pdf_metadata_reference": {
            "title": metadata.get("title"),
            "authors": metadata.get("authors"),
            "subject": metadata.get("subject"),
            "keywords": metadata.get("keywords"),
        },

        "human_decision": {
            "source_type": None,
            "title": None,
            "author_or_organisation": None,
            "edition_or_version": None,
            "publisher": None,
            "publication_year": None,
            "isbn_or_identifier": None,
            "official_or_regulatory_source": None,

            "decision": "PENDING",
            "reviewer": None,
            "review_date": None,
            "review_notes": None,
        },

        "decision_rules": {
            "accepted_values_must_be_supported": True,
            "candidate_values_are_not_final_facts": True,
            "pdf_metadata_is_not_automatically_authoritative": True,
            "human_review_required_before_final_classification": True,
            "uncertain_values_must_remain_null": True,
        },

        "review_status": "PENDING_HUMAN_REVIEW",
    }

    results.append(result)


output = {
    "pipeline": "CSP11 Source-to-Domain Knowledge Pipeline",
    "stage": "L1.6 Human-Reviewable Bibliographic Decision Records",
    "generated_at": datetime.now().isoformat(timespec="seconds"),

    "input_source_count": candidate_data["source_count"],
    "decision_record_count": len(results),

    "purpose": (
        "Provide a controlled decision layer for human validation "
        "of bibliographic identity before CSP11 source mapping. "
        "Candidate evidence is preserved separately from final "
        "human-approved bibliographic facts."
    ),

    "workflow": [
        "Review candidate evidence.",
        "Compare candidates against visible source evidence.",
        "Enter only bibliographic values supported by evidence.",
        "Leave uncertain fields null.",
        "Assign source type.",
        "Determine whether the source is official or regulatory.",
        "Record reviewer and review date.",
        "Set decision to ACCEPT, MODIFY, REJECT, or HOLD.",
        "Only accepted or modified records may proceed to final source classification."
    ],

    "allowed_decisions": [
        "ACCEPT",
        "MODIFY",
        "REJECT",
        "HOLD"
    ],

    "allowed_source_types": [
        "TEXTBOOK",
        "PROFESSIONAL_BOOK",
        "ACADEMIC_BOOK",
        "ACADEMIC_ARTICLE",
        "TECHNICAL_REPORT",
        "GOVERNMENT_PUBLICATION",
        "REGULATORY_DOCUMENT",
        "PROFESSIONAL_BODY_PUBLICATION",
        "INTERNATIONAL_ORGANISATION_PUBLICATION",
        "STANDARD",
        "GUIDANCE",
        "CODE_OF_PRACTICE",
        "WEBSITE_OR_WEB_DOCUMENT",
        "OTHER",
        "UNCLASSIFIED"
    ],

    "decision_records": results,
}


with OUTPUT_PATH.open("w", encoding="utf-8") as f:
    json.dump(
        output,
        f,
        indent=2,
        ensure_ascii=False
    )


print("===== L1.6 HUMAN-REVIEWABLE BIBLIOGRAPHIC DECISIONS =====")
print(f"Sources received: {candidate_data['source_count']}")
print(f"Decision records created: {len(results)}")

print(
    "Pending human review:",
    sum(
        1
        for r in results
        if r["review_status"] == "PENDING_HUMAN_REVIEW"
    )
)

print(
    "ACCEPT decisions:",
    sum(
        1
        for r in results
        if r["human_decision"]["decision"] == "ACCEPT"
    )
)

print(
    "MODIFY decisions:",
    sum(
        1
        for r in results
        if r["human_decision"]["decision"] == "MODIFY"
    )
)

print(
    "REJECT decisions:",
    sum(
        1
        for r in results
        if r["human_decision"]["decision"] == "REJECT"
    )
)

print(
    "HOLD decisions:",
    sum(
        1
        for r in results
        if r["human_decision"]["decision"] == "HOLD"
    )
)

print(f"Output: {OUTPUT_PATH}")
