import json
from pathlib import Path
from datetime import datetime
import pymupdf

SOURCE_DIR = Path(r"C:\NAVEED\CSP11_Sources")
METADATA_PATH = Path("docs/source_pipeline/SRC-001_to_SRC-048_metadata.json")
OUTPUT_PATH = Path("docs/source_pipeline/SRC-001_to_SRC-048_bibliographic_review.json")

with METADATA_PATH.open("r", encoding="utf-8") as f:
    metadata_data = json.load(f)

review_results = []

for source in metadata_data["metadata_results"]:
    if not source["manual_review_required"]:
        continue

    source_id = source["source_id"]
    pdf_path = SOURCE_DIR / source["filename"]

    result = {
        "source_id": source_id,
        "filename": source["filename"],
        "full_path": str(pdf_path),
        "current_title": source.get("title"),
        "current_authors": source.get("authors"),
        "current_subject": source.get("subject"),
        "current_keywords": source.get("keywords"),
        "page_count": source.get("page_count"),
        "reason": source.get("notes"),
        "sample_pages": []
    }

    try:
        doc = pymupdf.open(pdf_path)

        max_pages = min(8, len(doc))

        for page_number in range(max_pages):
            page = doc[page_number]

            text = page.get_text("text").strip()

            result["sample_pages"].append({
                "page_number": page_number + 1,
                "text_characters": len(text),
                "text": text[:12000]
            })

        doc.close()

        result["inspection_status"] = "PASS"

    except Exception as exc:
        result["inspection_status"] = "ERROR"
        result["error"] = f"{type(exc).__name__}: {exc}"

    review_results.append(result)

output = {
    "pipeline": "CSP11 Source-to-Domain Knowledge Pipeline",
    "stage": "L1.4 Bibliographic Review Preparation",
    "generated_at": datetime.now().isoformat(timespec="seconds"),
    "review_count": len(review_results),
    "review_results": review_results
}

with OUTPUT_PATH.open("w", encoding="utf-8") as f:
    json.dump(output, f, indent=2, ensure_ascii=False)

print("===== L1.4 BIBLIOGRAPHIC REVIEW PREPARATION =====")
print(f"Sources requiring review: {len(review_results)}")
print(
    "Successfully sampled:",
    sum(1 for r in review_results if r["inspection_status"] == "PASS")
)
print(
    "Errors:",
    sum(1 for r in review_results if r["inspection_status"] == "ERROR")
)
print(f"Output: {OUTPUT_PATH}")
