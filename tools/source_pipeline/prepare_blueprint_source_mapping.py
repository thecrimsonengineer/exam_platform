"""Prepare the non-authoritative L2.3 CSP11 blueprint-to-source mapping layer."""

import json
from datetime import datetime
from pathlib import Path

DOCS = Path("docs/source_pipeline")
BLUEPRINT_PATH = DOCS / "CSP11_canonical_blueprint.json"
INVENTORY_PATH = DOCS / "SRC-001_to_SRC-048_inventory.json"
METADATA_PATH = DOCS / "SRC-001_to_SRC-048_metadata.json"
CLASSIFICATION_PATH = DOCS / "SRC-001_to_SRC-048_bibliographic_classification.json"
EVIDENCE_PATH = DOCS / "SRC-001_to_SRC-048_bibliographic_evidence.json"
CANDIDATES_PATH = DOCS / "SRC-001_to_SRC-048_bibliographic_candidates.json"
DECISIONS_PATH = DOCS / "SRC-001_to_SRC-048_bibliographic_decisions.json"
DECISION_VALIDATION_PATH = DOCS / "SRC-001_to_SRC-048_bibliographic_decision_validation.json"
OUTPUT_PATH = DOCS / "CSP11_blueprint_source_mapping.json"


def load_json(path):
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def record_ids(data, field):
    records = data.get(field, []) if isinstance(data, dict) else data
    if not isinstance(records, list):
        raise ValueError(f"{field} must be a list in its source artifact.")
    ids = [record.get("source_id") for record in records if isinstance(record, dict)]
    if any(not isinstance(source_id, str) or not source_id for source_id in ids):
        raise ValueError(f"{field} contains an invalid source_id.")
    if len(ids) != len(set(ids)):
        raise ValueError(f"{field} contains duplicate source_id values.")
    return set(ids)


blueprint = load_json(BLUEPRINT_PATH)
inventory = load_json(INVENTORY_PATH)
metadata = load_json(METADATA_PATH)
classification = load_json(CLASSIFICATION_PATH)
evidence = load_json(EVIDENCE_PATH)
candidates = load_json(CANDIDATES_PATH)
decisions = load_json(DECISIONS_PATH)
decision_validation = load_json(DECISION_VALIDATION_PATH)

domains = blueprint.get("domains", [])
competency_count = sum(len(domain.get("competencies", [])) for domain in domains if isinstance(domain, dict))
if len(domains) != 7 or competency_count != 47:
    raise ValueError("Canonical CSP11 blueprint must contain 7 domains and 47 competencies.")

inventory_ids = record_ids(inventory, "inventory")
metadata_ids = record_ids(metadata, "metadata_results")
classification_ids = record_ids(classification, "classification_results")
evidence_ids = record_ids(evidence, "evidence_results")
candidate_ids = record_ids(candidates, "candidate_results")
decision_ids = record_ids(decisions, "decision_records")

if decision_validation.get("summary", {}).get("overall_status") != "VALID":
    raise ValueError("Bibliographic decision validation must be VALID before L2.3 preparation.")
if decision_validation.get("actual_record_count") != len(decision_ids):
    raise ValueError("Bibliographic decision validation record count disagrees with decisions.")

# L1.7's valid decision records define the current usable source population.
for label, ids in {"inventory": inventory_ids, "metadata": metadata_ids, "classification": classification_ids, "evidence": evidence_ids, "candidates": candidate_ids}.items():
    missing = sorted(decision_ids - ids)
    if missing:
        raise ValueError(f"Current source records are missing from {label}: {missing}")

blueprint_metadata = blueprint.get("blueprint", {})
source_ids = sorted(decision_ids)
output = {
    "pipeline": "CSP11 Source-to-Domain Knowledge Pipeline",
    "stage": "L2.3 Blueprint-to-Source Mapping Preparation",
    "generated_at": datetime.now().isoformat(timespec="seconds"),
    "blueprint_reference": {"version": blueprint_metadata.get("version"), "effective_date": blueprint_metadata.get("effective_date"), "path": str(BLUEPRINT_PATH).replace("\\", "/")},
    "mapping_policy": {
        "human_authority_preserved": True,
        "candidate_mapping_is_not_confirmed_coverage": True,
        "accepted_mapping_requires_human_review": True,
        "zero_candidate_mappings_allowed": True,
        "unknown_sources_block_progression": True,
        "unknown_competencies_block_progression": True,
        "domain_must_match_canonical_competency_parent": True,
        "automatic_reclassification_prohibited": True,
        "automatic_coverage_assignment_prohibited": True,
    },
    "source_reference": {
        "actual_source_count": len(source_ids),
        "source_ids": source_ids,
        "record_authority": "L1.7 valid bibliographic decision records",
        "inventory_reference": str(INVENTORY_PATH).replace("\\", "/"),
        "decision_validation_reference": str(DECISION_VALIDATION_PATH).replace("\\", "/"),
    },
    "blueprint_reference_summary": {"domain_count": len(domains), "competency_count": competency_count},
    "mapping_status_definitions": {
        "CANDIDATE": "An automated or analytical process identified a possible relationship; it is not confirmed coverage.",
        "REVIEW_REQUIRED": "The relationship requires human evaluation before it can be accepted.",
        "ACCEPTED": "A human-authorized mapping has been confirmed and may count as confirmed mapping coverage.",
        "REJECTED": "A human reviewer determined that the relationship is not appropriate.",
        "HOLD": "The relationship cannot currently be resolved and requires later review.",
    },
    "mapping_record_schema": {
        "relationship_key": "source_id + competency_id",
        "required_fields": ["mapping_id", "source_id", "domain_id", "competency_id", "mapping_status", "mapping_basis", "candidate_confidence", "candidate_evidence_reference", "human_decision", "reviewer", "review_date", "review_notes"],
    },
    "mappings": [],
}

with OUTPUT_PATH.open("w", encoding="utf-8") as handle:
    json.dump(output, handle, indent=2, ensure_ascii=False)
    handle.write("\n")

print("===== L2.3 BLUEPRINT-TO-SOURCE MAPPING PREPARATION =====")
print(f"Sources: {len(source_ids)}")
print(f"Competencies: {competency_count}")
print("Mappings: 0")
print("Candidate mappings: 0")
print("Review-required mappings: 0")
print(f"Output: {OUTPUT_PATH}")
