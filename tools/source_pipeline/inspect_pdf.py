import json
from pathlib import Path
import pymupdf

SOURCE_DIR = Path(r"C:\NAVEED\CSP11_Sources")
SOURCE_ID = "SRC-001"

inventory_path = Path("docs/source_pipeline/SRC-001_to_SRC-048_inventory.json")

with inventory_path.open("r", encoding="utf-8") as f:
    inventory = json.load(f)

source = next(item for item in inventory if item["source_id"] == SOURCE_ID)
pdf_path = SOURCE_DIR / source["filename"]

doc = pymupdf.open(pdf_path)

metadata = doc.metadata or {}
page_count = len(doc)

first_page_text = ""
if page_count > 0:
    first_page_text = doc[0].get_text("text").strip()

total_text_chars = 0
pages_with_text = 0

for page in doc:
    text = page.get_text("text").strip()
    if text:
        pages_with_text += 1
        total_text_chars += len(text)

text_ratio = pages_with_text / page_count if page_count else 0

result = {
    "source_id": SOURCE_ID,
    "filename": source["filename"],
    "full_path": str(pdf_path),
    "page_count": page_count,
    "metadata": metadata,
    "pages_with_text": pages_with_text,
    "total_text_characters": total_text_chars,
    "text_page_ratio": round(text_ratio, 4),
    "document_type": (
        "TEXT_READABLE"
        if text_ratio >= 0.80
        else "PARTIALLY_TEXT_READABLE"
        if text_ratio > 0
        else "SCANNED_OR_IMAGE_ONLY"
    ),
    "first_page_text_sample": first_page_text[:3000],
}

print(json.dumps(result, indent=2, ensure_ascii=False))

doc.close()
