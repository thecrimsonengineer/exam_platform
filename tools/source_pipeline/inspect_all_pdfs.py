import json
from pathlib import Path
from datetime import datetime
import pymupdf

SOURCE_DIR = Path(r"C:\NAVEED\CSP11_Sources")
INVENTORY_PATH = Path("docs/source_pipeline/SRC-001_to_SRC-048_inventory.json")
OUTPUT_PATH = Path("docs/source_pipeline/SRC-001_to_SRC-048_pdf_inspection.json")

with INVENTORY_PATH.open("r", encoding="utf-8") as f:
    inventory = json.load(f)

results = []

for source in inventory:
    source_id = source["source_id"]
    pdf_path = SOURCE_DIR / source["filename"]

    result = {
        "source_id": source_id,
        "filename": source["filename"],
        "full_path": str(pdf_path),
        "inspection_status": "PENDING",
        "page_count": None,
        "metadata": {},
        "pages_with_text": 0,
        "pages_without_text": 0,
        "text_page_ratio": 0,
        "total_text_characters": 0,
        "first_text_page": None,
        "first_text_page_sample": "",
        "pages_without_text_sample": [],
        "document_type": None,
        "error": None,
    }

    try:
        doc = pymupdf.open(pdf_path)

        result["page_count"] = len(doc)
        result["metadata"] = doc.metadata or {}

        no_text_pages = []

        for page_number, page in enumerate(doc, start=1):
            text = page.get_text("text").strip()

            if text:
                result["pages_with_text"] += 1
                result["total_text_characters"] += len(text)

                if result["first_text_page"] is None:
                    result["first_text_page"] = page_number
                    result["first_text_page_sample"] = text[:3000]
            else:
                result["pages_without_text"] += 1
                no_text_pages.append(page_number)

        if result["page_count"]:
            result["text_page_ratio"] = round(
                result["pages_with_text"] / result["page_count"], 4
            )

        result["pages_without_text_sample"] = no_text_pages[:25]

        if result["text_page_ratio"] >= 0.80:
            result["document_type"] = "TEXT_READABLE"
        elif result["text_page_ratio"] > 0:
            result["document_type"] = "PARTIALLY_TEXT_READABLE"
        else:
            result["document_type"] = "SCANNED_OR_IMAGE_ONLY"

        result["inspection_status"] = "PASS"

        doc.close()

    except Exception as exc:
        result["inspection_status"] = "ERROR"
        result["error"] = f"{type(exc).__name__}: {exc}"

    results.append(result)

    print(
        f"{source_id}: "
        f"{result['inspection_status']} | "
        f"pages={result['page_count']} | "
        f"text_ratio={result['text_page_ratio']} | "
        f"type={result['document_type']}"
    )

output = {
    "pipeline": "CSP11 Source-to-Domain Knowledge Pipeline",
    "stage": "L1.2 PDF Inspection",
    "generated_at": datetime.now().isoformat(timespec="seconds"),
    "source_directory": str(SOURCE_DIR),
    "source_count": len(results),
    "inspection_results": results,
}

with OUTPUT_PATH.open("w", encoding="utf-8") as f:
    json.dump(output, f, indent=2, ensure_ascii=False)

print()
print("===== INSPECTION COMPLETE =====")
print(f"Sources inspected: {len(results)}")
print(f"Output: {OUTPUT_PATH}")
print(
    "PASS:",
    sum(1 for r in results if r["inspection_status"] == "PASS")
)
print(
    "ERROR:",
    sum(1 for r in results if r["inspection_status"] == "ERROR")
)
print(
    "TEXT READABLE:",
    sum(1 for r in results if r["document_type"] == "TEXT_READABLE")
)
print(
    "PARTIALLY TEXT READABLE:",
    sum(1 for r in results if r["document_type"] == "PARTIALLY_TEXT_READABLE")
)
print(
    "SCANNED/IMAGE ONLY:",
    sum(1 for r in results if r["document_type"] == "SCANNED_OR_IMAGE_ONLY")
)
