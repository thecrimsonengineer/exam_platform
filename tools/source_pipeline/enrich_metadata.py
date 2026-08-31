import json
from pathlib import Path
from datetime import datetime
import pymupdf

SOURCE_DIR = Path(r"C:\NAVEED\CSP11_Sources")
INVENTORY_PATH = Path("docs/source_pipeline/SRC-001_to_SRC-048_inventory.json")
INSPECTION_PATH = Path("docs/source_pipeline/SRC-001_to_SRC-048_pdf_inspection.json")
METADATA_PATH = Path("docs/source_pipeline/SRC-001_to_SRC-048_metadata.json")

with INVENTORY_PATH.open("r", encoding="utf-8") as f:
    inventory = json.load(f)

with INSPECTION_PATH.open("r", encoding="utf-8") as f:
    inspection_data = json.load(f)

inspection_by_id = {
    item["source_id"]: item
    for item in inspection_data["inspection_results"]
}

results = []

for source in inventory:
    source_id = source["source_id"]
    inspection = inspection_by_id[source_id]

    metadata = inspection.get("metadata") or {}

    pdf_path = SOURCE_DIR / source["filename"]

    result = {
        "source_id": source_id,
        "filename": source["filename"],
        "full_path": str(pdf_path),
        "size_bytes": source["size_bytes"],
        "size_mb": source["size_mb"],
        "last_modified": source["last_modified"],

        "title": metadata.get("title") or None,
        "authors": metadata.get("author") or None,
        "subject": metadata.get("subject") or None,
        "keywords": metadata.get("keywords") or None,
        "creator": metadata.get("creator") or None,
        "producer": metadata.get("producer") or None,

        "creation_date": metadata.get("creationDate") or None,
        "modification_date": metadata.get("modDate") or None,

        "page_count": inspection.get("page_count"),
        "document_type": inspection.get("document_type"),
        "pages_with_text": inspection.get("pages_with_text"),
        "pages_without_text": inspection.get("pages_without_text"),
        "text_page_ratio": inspection.get("text_page_ratio"),
        "total_text_characters": inspection.get("total_text_characters"),

        "metadata_status": "PDF_METADATA_EXTRACTED",
        "manual_review_required": False,
        "notes": None,
    }

    if not result["title"] or not result["authors"]:
        result["manual_review_required"] = True
        result["notes"] = "Title and/or author not available in PDF metadata."

    if result["document_type"] == "SCANNED_OR_IMAGE_ONLY":
        result["manual_review_required"] = True
        result["notes"] = (
            (result["notes"] + " " if result["notes"] else "")
            + "Scanned/image-only source requires OCR or alternate extraction handling."
        )

    results.append(result)

    print(
        f"{source_id}: "
        f"title={'YES' if result['title'] else 'NO'} | "
        f"author={'YES' if result['authors'] else 'NO'} | "
        f"pages={result['page_count']} | "
        f"type={result['document_type']} | "
        f"review={'YES' if result['manual_review_required'] else 'NO'}"
    )

output = {
    "pipeline": "CSP11 Source-to-Domain Knowledge Pipeline",
    "stage": "L1.3 Source Metadata Enrichment",
    "generated_at": datetime.now().isoformat(timespec="seconds"),
    "source_directory": str(SOURCE_DIR),
    "source_count": len(results),
    "metadata_results": results,
}

with METADATA_PATH.open("w", encoding="utf-8") as f:
    json.dump(output, f, indent=2, ensure_ascii=False)

print()
print("===== L1.3 METADATA ENRICHMENT COMPLETE =====")
print(f"Sources processed: {len(results)}")
print(
    "Manual review required:",
    sum(1 for r in results if r["manual_review_required"])
)
print(
    "Metadata with title:",
    sum(1 for r in results if r["title"])
)
print(
    "Metadata with author:",
    sum(1 for r in results if r["authors"])
)
print(f"Output: {METADATA_PATH}")
