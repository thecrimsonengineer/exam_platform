"""Deterministically validate the L2.3 blueprint-to-source mapping layer."""

import json
from collections import Counter
from datetime import datetime
from pathlib import Path

DOCS = Path("docs/source_pipeline")
BLUEPRINT_PATH = DOCS / "CSP11_canonical_blueprint.json"
INVENTORY_PATH = DOCS / "SRC-001_to_SRC-048_inventory.json"
DECISIONS_PATH = DOCS / "SRC-001_to_SRC-048_bibliographic_decisions.json"
DECISION_VALIDATION_PATH = DOCS / "SRC-001_to_SRC-048_bibliographic_decision_validation.json"
INPUT_PATH = DOCS / "CSP11_blueprint_source_mapping.json"
OUTPUT_PATH = DOCS / "CSP11_blueprint_source_mapping_validation.json"
STATUSES = ["CANDIDATE", "REVIEW_REQUIRED", "ACCEPTED", "REJECTED", "HOLD"]
RESOLVED = {"ACCEPTED": "ACCEPT", "REJECTED": "REJECT", "HOLD": "HOLD"}


def load(path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        return {"__load_error__": str(exc)}


errors, warnings = [], []


def error(code, message, **details):
    errors.append({"code": code, "message": message, **details})


blueprint, inventory = load(BLUEPRINT_PATH), load(INVENTORY_PATH)
decisions, decision_validation, data = load(DECISIONS_PATH), load(DECISION_VALIDATION_PATH), load(INPUT_PATH)
if "__load_error__" in data:
    error("L23-E001", "Mapping input cannot be loaded as JSON.", detail=data["__load_error__"])
    data = {}
if "__load_error__" in blueprint:
    error("L23-E002", "Canonical blueprint cannot be loaded as JSON.")
    blueprint = {}

parents = {}
domains = blueprint.get("domains", [])
if not isinstance(domains, list):
    error("L23-E003", "Canonical blueprint domains must be a list.")
    domains = []
for domain in domains:
    if not isinstance(domain, dict):
        error("L23-E004", "Canonical blueprint contains a malformed domain record.")
        continue
    for competency in domain.get("competencies", []):
        if not isinstance(competency, dict) or not competency.get("competency_id"):
            error("L23-E005", "Canonical blueprint contains a malformed competency record.")
            continue
        cid = competency["competency_id"]
        if cid in parents:
            error("L23-E006", "Canonical blueprint contains a duplicate competency ID.", competency_id=cid)
        parents[cid] = domain.get("domain_id")
if len(domains) != 7 or len(parents) != 47:
    error("L23-E007", "Canonical blueprint integrity requires exactly 7 domains and 47 competencies.", domain_count=len(domains), competency_count=len(parents))

inventory_ids = [r.get("source_id") for r in inventory if isinstance(r, dict)] if isinstance(inventory, list) else []
if len(inventory_ids) != len(set(inventory_ids)):
    error("L23-E008", "Source inventory contains duplicate source IDs.")
decision_records = decisions.get("decision_records", []) if isinstance(decisions, dict) else []
decision_ids = [r.get("source_id") for r in decision_records if isinstance(r, dict)]
if len(decision_ids) != len(set(decision_ids)) or not all(isinstance(x, str) and x for x in decision_ids):
    error("L23-E009", "Bibliographic decisions contain invalid or duplicate source IDs.")
if decision_validation.get("summary", {}).get("overall_status") != "VALID":
    error("L23-E010", "Bibliographic decision validation must be VALID.")
if decision_validation.get("actual_record_count") != len(decision_ids):
    error("L23-E011", "Decision validation count does not match decision records.")
source_ids = set(decision_ids)
if not source_ids.issubset(set(inventory_ids)):
    error("L23-E012", "Current decision records include IDs absent from inventory.", source_ids=sorted(source_ids - set(inventory_ids)))

required_top = {"pipeline", "stage", "blueprint_reference", "mapping_policy", "source_reference", "blueprint_reference_summary", "mapping_status_definitions", "mapping_record_schema", "mappings"}
missing = sorted(required_top - set(data))
if missing:
    error("L23-E013", "Mapping file is missing required top-level fields.", fields=missing)
policy = data.get("mapping_policy")
expected_policy = {"human_authority_preserved": True, "candidate_mapping_is_not_confirmed_coverage": True, "accepted_mapping_requires_human_review": True, "zero_candidate_mappings_allowed": True, "unknown_sources_block_progression": True, "unknown_competencies_block_progression": True, "domain_must_match_canonical_competency_parent": True, "automatic_reclassification_prohibited": True, "automatic_coverage_assignment_prohibited": True}
if not isinstance(policy, dict):
    error("L23-E014", "mapping_policy must be an object.")
else:
    for key, value in expected_policy.items():
        if policy.get(key) is not value:
            error("L23-E015", "Mapping policy safeguard is missing or false.", field=key)
source_reference = data.get("source_reference", {})
if not isinstance(source_reference, dict) or source_reference.get("source_ids") != sorted(source_ids):
    error("L23-E016", "source_reference.source_ids must match current usable source records.")
if not isinstance(source_reference, dict) or source_reference.get("actual_source_count") != len(source_ids):
    error("L23-E017", "source_reference.actual_source_count is inconsistent.")
summary_reference = data.get("blueprint_reference_summary", {})
if not isinstance(summary_reference, dict) or summary_reference.get("domain_count") != 7 or summary_reference.get("competency_count") != 47:
    error("L23-E018", "Blueprint reference summary must report 7 domains and 47 competencies.")
definitions = data.get("mapping_status_definitions")
if not isinstance(definitions, dict) or sorted(definitions) != sorted(STATUSES):
    error("L23-E019", "Mapping status definitions must contain the controlled vocabulary exactly.")

mappings = data.get("mappings", [])
if not isinstance(mappings, list):
    error("L23-E020", "mappings must be a list.")
    mappings = []
required_fields = ["mapping_id", "source_id", "domain_id", "competency_id", "mapping_status", "mapping_basis", "candidate_confidence", "candidate_evidence_reference", "human_decision", "reviewer", "review_date", "review_notes"]
relationship_keys, mapping_ids, counts, previous = [], [], Counter(), None
for index, record in enumerate(mappings):
    where = {"mapping_index": index}
    if not isinstance(record, dict):
        error("L23-E021", "Mapping record must be an object.", **where)
        continue
    absent = [field for field in required_fields if field not in record]
    if absent:
        error("L23-E022", "Mapping record is missing required fields.", fields=absent, **where)
    sid, cid, did, status = record.get("source_id"), record.get("competency_id"), record.get("domain_id"), record.get("mapping_status")
    mapping_id = record.get("mapping_id")
    if not isinstance(mapping_id, str) or not mapping_id.strip():
        error("L23-E023", "mapping_id must be a non-empty string.", **where)
    else:
        mapping_ids.append(mapping_id)
    if sid not in source_ids:
        error("L23-E024", "Mapping references an unknown or non-current source ID.", source_id=sid, **where)
    if cid not in parents:
        error("L23-E025", "Mapping references an unknown CSP11 competency ID.", competency_id=cid, **where)
    elif did != parents[cid]:
        error("L23-E026", "Mapping domain does not match canonical competency parent.", competency_id=cid, domain_id=did, canonical_domain_id=parents[cid], **where)
    if status not in STATUSES:
        error("L23-E027", "Mapping uses an invalid controlled status.", mapping_status=status, **where)
    else:
        counts[status] += 1
    if not isinstance(record.get("mapping_basis"), str) or not record["mapping_basis"].strip():
        error("L23-E028", "mapping_basis must be a non-empty provenance statement.", **where)
    if record.get("candidate_confidence") not in {"HIGH", "MEDIUM", "LOW", None}:
        error("L23-E029", "candidate_confidence must be HIGH, MEDIUM, LOW, or null.", **where)
    if not isinstance(record.get("candidate_evidence_reference"), (str, type(None))):
        error("L23-E030", "candidate_evidence_reference must be a string or null.", **where)
    relationship_keys.append((sid, cid))
    sort_key = (str(sid), str(cid))
    if previous is not None and sort_key < previous:
        error("L23-E031", "Mappings must be ordered by source_id and competency_id.", **where)
    previous = sort_key
    human, reviewer, review_date, notes = record.get("human_decision"), record.get("reviewer"), record.get("review_date"), record.get("review_notes")
    if status in {"CANDIDATE", "REVIEW_REQUIRED"} and any(item is not None for item in (human, reviewer, review_date, notes)):
        error("L23-E032", "Candidate and review-required mappings must remain undecided.", **where)
    if status in RESOLVED:
        if human != RESOLVED[status]:
            error("L23-E033", "Resolved status requires its matching human decision.", required_decision=RESOLVED[status], **where)
        if not isinstance(reviewer, str) or not reviewer.strip():
            error("L23-E034", "Resolved mapping requires a human reviewer.", **where)
        try:
            datetime.strptime(review_date, "%Y-%m-%d")
        except (TypeError, ValueError):
            error("L23-E035", "Resolved mapping requires an ISO review date.", **where)
    if status == "ACCEPTED" and human != "ACCEPT":
        error("L23-E036", "Only human-authorized ACCEPT decisions may produce ACCEPTED mappings.", **where)

duplicates = sorted(key for key, count in Counter(relationship_keys).items() if count > 1)
if duplicates:
    error("L23-E037", "Duplicate source-to-competency relationships are not allowed.", relationship_keys=[list(key) for key in duplicates])
duplicate_ids = sorted(value for value, count in Counter(mapping_ids).items() if count > 1)
if duplicate_ids:
    error("L23-E038", "Duplicate mapping_id values are not allowed.", mapping_ids=duplicate_ids)

accepted, candidate, review_required = counts["ACCEPTED"], counts["CANDIDATE"], counts["REVIEW_REQUIRED"]
output = {
    "pipeline": "CSP11 Source-to-Domain Knowledge Pipeline",
    "stage": "L2.3 Blueprint-to-Source Mapping Validation Gate",
    "generated_at": datetime.now().isoformat(timespec="seconds"),
    "validation_policy": {"validator_does_not_modify_mapping": True, "candidate_mapping_is_not_confirmed_coverage": True, "accepted_mapping_requires_human_authority": True, "canonical_blueprint_is_authoritative": True, "current_valid_bibliographic_records_define_source_population": True},
    "summary": {"overall_status": "INVALID" if errors else "VALID", "blocking_issues": len(errors), "warnings": len(warnings), "source_count": len(source_ids), "competency_count": len(parents), "mapping_count": len(mappings), "accepted_mapping_count": accepted, "candidate_mapping_count": candidate, "review_required_mapping_count": review_required, "rejected_mapping_count": counts["REJECTED"], "hold_mapping_count": counts["HOLD"], "confirmed_mapping_count": accepted, "candidate_mappings_are_confirmed_coverage": False},
    "issues": errors,
    "warnings": warnings,
}
OUTPUT_PATH.write_text(json.dumps(output, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print("===== L2.3 BLUEPRINT-TO-SOURCE MAPPING VALIDATION =====")
print(f"Sources: {len(source_ids)}")
print(f"Competencies: {len(parents)}")
print(f"Mappings: {len(mappings)}")
print(f"Candidate mappings: {candidate}")
print(f"Review-required mappings: {review_required}")
print(f"Accepted mappings: {accepted}")
print(f"Blocking issues: {len(errors)}")
print(f"Warnings: {len(warnings)}")
print(f"OVERALL STATUS: {output['summary']['overall_status']}")
print(f"Output: {OUTPUT_PATH}")
raise SystemExit(0 if not errors else 1)
