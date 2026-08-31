import json
from pathlib import Path
from datetime import datetime
import re

INPUT_PATH = Path(
    "docs/source_pipeline/SRC-001_to_SRC-048_bibliographic_evidence.json"
)

OUTPUT_PATH = Path(
    "docs/source_pipeline/SRC-001_to_SRC-048_bibliographic_candidates.json"
)

with INPUT_PATH.open("r", encoding="utf-8") as f:
    evidence_data = json.load(f)

results = []

def clean_line(line):
    return re.sub(r"\s+", " ", line).strip()

def useful_lines(text):
    lines = []

    for raw in text.splitlines():
        line = clean_line(raw)

        if not line:
            continue

        if len(line) < 2:
            continue

        lines.append(line)

    return lines

for source in evidence_data["evidence_results"]:

    text = source["text_evidence"].get(
        "first_nonempty_page_text",
        ""
    )

    lines = useful_lines(text)

    combined_text = "\n".join(
        page_text
        for page_text in [text]
    )

    candidate = {
        "source_id": source["source_id"],
        "filename": source["filename"],

        "pdf_metadata": source.get("pdf_metadata", {}),

        "page_count": source.get("page_count"),

        "evidence_summary": {
            "sampled_page_count": source.get("sampled_page_count"),
            "sample_text_characters": source["text_evidence"].get(
                "total_characters", 0
            ),
            "first_nonempty_page": source["text_evidence"].get(
                "first_nonempty_page"
            ),
        },

        "candidates": {
            "title_candidates": [],
            "author_or_organisation_candidates": [],
            "edition_or_version_candidates": [],
            "publisher_candidates": [],
            "publication_year_candidates": [],
            "identifier_candidates": [],
        },

        "supporting_evidence": [],

        "candidate_confidence": "LOW",

        "review_status": "PENDING_HUMAN_REVIEW",
    }

    # ------------------------------------------------------------
    # TITLE CANDIDATES
    # ------------------------------------------------------------

    title_keywords = [
        "job hazard analysis",
        "risk assessment",
        "occupational safety",
        "occupational health",
        "health and safety",
        "safety management",
        "safety handbook",
        "safety manual",
        "safety guide",
        "standard",
        "guideline",
        "guidance",
        "code of practice",
        "technical report",
        "practice",
        "engineering",
        "industrial hygiene",
    ]

    for line in lines[:80]:

        lower = line.lower()

        if any(keyword in lower for keyword in title_keywords):

            if len(line) <= 250:
                candidate["candidates"]["title_candidates"].append({
                    "value": line,
                    "source": "sampled_page_text",
                    "confidence": "MEDIUM"
                })

    # Preserve PDF metadata title as a candidate, never as final truth.

    metadata_title = source.get("pdf_metadata", {}).get("title")

    if metadata_title:

        candidate["candidates"]["title_candidates"].append({
            "value": metadata_title,
            "source": "pdf_metadata",
            "confidence": "MEDIUM"
        })

    # ------------------------------------------------------------
    # AUTHOR / ORGANISATION CANDIDATES
    # ------------------------------------------------------------

    author_patterns = [
        r"^\s*by\s+(.+)$",
        r"^\s*author\s*[:\-]\s*(.+)$",
        r"^\s*authors\s*[:\-]\s*(.+)$",
        r"^\s*prepared\s+by\s+(.+)$",
        r"^\s*written\s+by\s+(.+)$",
        r"^\s*developed\s+by\s+(.+)$",
    ]

    for line in lines[:100]:

        for pattern in author_patterns:

            match = re.search(
                pattern,
                line,
                flags=re.IGNORECASE
            )

            if match:

                value = clean_line(match.group(1))

                if 2 <= len(value) <= 250:

                    candidate[
                        "candidates"
                    ][
                        "author_or_organisation_candidates"
                    ].append({
                        "value": value,
                        "source": "sampled_page_text",
                        "confidence": "HIGH"
                    })

    metadata_author = source.get(
        "pdf_metadata", {}
    ).get("authors")

    if metadata_author:

        candidate[
            "candidates"
        ][
            "author_or_organisation_candidates"
        ].append({
            "value": metadata_author,
            "source": "pdf_metadata",
            "confidence": "MEDIUM"
        })

    # ------------------------------------------------------------
    # EDITION / VERSION
    # ------------------------------------------------------------

    edition_patterns = [
        r"\b\d+(?:st|nd|rd|th)\s+edition\b",
        r"\b(?:first|second|third|fourth|fifth|sixth|seventh|eighth|ninth|tenth)\s+edition\b",
        r"\bedition\s+\d+\b",
        r"\bversion\s+[A-Za-z0-9.\-]+\b",
        r"\brev(?:ision)?\.?\s+[A-Za-z0-9.\-]+\b",
    ]

    for pattern in edition_patterns:

        for match in re.finditer(
            pattern,
            combined_text,
            flags=re.IGNORECASE
        ):

            value = clean_line(match.group(0))

            candidate[
                "candidates"
            ][
                "edition_or_version_candidates"
            ].append({
                "value": value,
                "source": "sampled_page_text",
                "confidence": "MEDIUM"
            })

    # ------------------------------------------------------------
    # PUBLICATION YEARS
    # ------------------------------------------------------------

    year_matches = sorted(
        set(
            re.findall(
                r"\b(?:19|20)\d{2}\b",
                combined_text
            )
        )
    )

    for year in year_matches:

        candidate[
            "candidates"
        ][
            "publication_year_candidates"
        ].append({
            "value": year,
            "source": "sampled_page_text",
            "confidence": "LOW"
        })

    # ------------------------------------------------------------
    # ISBN / ISSN / DOI
    # ------------------------------------------------------------

    identifier_patterns = [
        r"\bISBN(?:-1[03])?\s*[:\-]?\s*[0-9Xx][0-9Xx\-\s]{8,25}",
        r"\bISSN\s*[:\-]?\s*\d{4}[\-\s]\d{3}[\dXx]",
        r"\b10\.\d{4,9}/[-._;()/:A-Za-z0-9]+\b",
    ]

    for pattern in identifier_patterns:

        for match in re.finditer(
            pattern,
            combined_text,
            flags=re.IGNORECASE
        ):

            value = clean_line(match.group(0))

            candidate[
                "candidates"
            ][
                "identifier_candidates"
            ].append({
                "value": value,
                "source": "sampled_page_text",
                "confidence": "HIGH"
            })

    # ------------------------------------------------------------
    # PUBLISHER CANDIDATES
    # ------------------------------------------------------------

    publisher_patterns = [
        r"published\s+by\s+(.+)",
        r"publisher\s*[:\-]\s*(.+)",
        r"publishing\s+(.+)",
    ]

    for line in lines[:100]:

        for pattern in publisher_patterns:

            match = re.search(
                pattern,
                line,
                flags=re.IGNORECASE
            )

            if match:

                value = clean_line(match.group(1))

                if 2 <= len(value) <= 250:

                    candidate[
                        "candidates"
                    ][
                        "publisher_candidates"
                    ].append({
                        "value": value,
                        "source": "sampled_page_text",
                        "confidence": "HIGH"
                    })

    # ------------------------------------------------------------
    # SUPPORTING EVIDENCE
    # ------------------------------------------------------------

    for line_number, line in enumerate(lines[:40], start=1):

        candidate["supporting_evidence"].append({
            "sample_line": line_number,
            "text": line[:500]
        })

    # ------------------------------------------------------------
    # DEDUPLICATION
    # ------------------------------------------------------------

    for field in candidate["candidates"]:

        seen = set()
        unique_values = []

        for item in candidate["candidates"][field]:

            key = (
                item["value"]
                .strip()
                .lower()
            )

            if key in seen:
                continue

            seen.add(key)
            unique_values.append(item)

        candidate["candidates"][field] = unique_values

    # ------------------------------------------------------------
    # OVERALL CONFIDENCE
    # ------------------------------------------------------------

    high_count = sum(
        1
        for field in candidate["candidates"].values()
        for item in field
        if item["confidence"] == "HIGH"
    )

    medium_count = sum(
        1
        for field in candidate["candidates"].values()
        for item in field
        if item["confidence"] == "MEDIUM"
    )

    if high_count >= 2:
        candidate["candidate_confidence"] = "HIGH"
    elif high_count >= 1 or medium_count >= 2:
        candidate["candidate_confidence"] = "MEDIUM"
    else:
        candidate["candidate_confidence"] = "LOW"

    results.append(candidate)

output = {
    "pipeline": "CSP11 Source-to-Domain Knowledge Pipeline",
    "stage": "L1.5.2 Evidence-Based Bibliographic Candidate Extraction",
    "generated_at": datetime.now().isoformat(timespec="seconds"),
    "source_count": len(results),
    "method": (
        "Candidate extraction from sampled source evidence and PDF "
        "metadata. Candidates are not final bibliographic facts. "
        "Human review remains authoritative."
    ),
    "candidate_results": results,
}

with OUTPUT_PATH.open("w", encoding="utf-8") as f:
    json.dump(
        output,
        f,
        indent=2,
        ensure_ascii=False
    )

print("===== L1.5.2 BIBLIOGRAPHIC CANDIDATE EXTRACTION =====")
print(f"Sources processed: {len(results)}")

print(
    "HIGH confidence:",
    sum(
        1
        for r in results
        if r["candidate_confidence"] == "HIGH"
    )
)

print(
    "MEDIUM confidence:",
    sum(
        1
        for r in results
        if r["candidate_confidence"] == "MEDIUM"
    )
)

print(
    "LOW confidence:",
    sum(
        1
        for r in results
        if r["candidate_confidence"] == "LOW"
    )
)

print(
    "Sources with title candidates:",
    sum(
        1
        for r in results
        if r["candidates"]["title_candidates"]
    )
)

print(
    "Sources with author/organisation candidates:",
    sum(
        1
        for r in results
        if r["candidates"]["author_or_organisation_candidates"]
    )
)

print(
    "Sources with identifier candidates:",
    sum(
        1
        for r in results
        if r["candidates"]["identifier_candidates"]
    )
)

print(f"Output: {OUTPUT_PATH}")
