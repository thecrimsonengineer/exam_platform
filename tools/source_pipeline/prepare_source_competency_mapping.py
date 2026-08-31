import json
import re
from pathlib import Path
from datetime import datetime


# ================================================================
# PATHS
# ================================================================

ROOT = Path(__file__).resolve().parents[2]

BLUEPRINT_PATH = (
    ROOT / "docs/source_pipeline/CSP11_canonical_blueprint.json"
)

BLUEPRINT_VALIDATION_PATH = (
    ROOT / "docs/source_pipeline/CSP11_canonical_blueprint_validation.json"
)

DECISIONS_PATH = (
    ROOT / "docs/source_pipeline/SRC-001_to_SRC-048_bibliographic_decisions.json"
)

EVIDENCE_PATH = (
    ROOT / "docs/source_pipeline/SRC-001_to_SRC-048_bibliographic_evidence.json"
)

OUTPUT_PATH = (
    ROOT / "docs/source_pipeline/CSP11_source_to_competency_mapping.json"
)


# ================================================================
# CONTROLLED VALUES
# ================================================================

ALLOWED_MAPPING_STATUSES = {
    "candidate",
    "pending_human_review",
    "confirmed",
    "excluded",
}

# L2.3 is a preparation stage.
# Newly generated mappings may NEVER be automatically confirmed.
GENERATED_MAPPING_STATUS = "pending_human_review"


# ================================================================
# ISSUE COLLECTION
# ================================================================

errors = []
warnings = []


def error(code, message, **extra):
    item = {
        "code": code,
        "message": message,
    }
    item.update(extra)
    errors.append(item)


def warning(code, message, **extra):
    item = {
        "code": code,
        "message": message,
    }
    item.update(extra)
    warnings.append(item)


# ================================================================
# FILE LOADING
# ================================================================

def load_json(path, error_code, description):
    if not path.exists():
        error(
            error_code,
            f"{description} is missing.",
            path=str(path),
        )
        return {}

    try:
        with path.open("r", encoding="utf-8") as handle:
            return json.load(handle)
    except (json.JSONDecodeError, OSError) as exc:
        error(
            error_code,
            f"{description} could not be loaded as valid JSON.",
            path=str(path),
            detail=str(exc),
        )
        return {}


blueprint = load_json(
    BLUEPRINT_PATH,
    "L23-E001",
    "Canonical CSP11 blueprint",
)

blueprint_validation = load_json(
    BLUEPRINT_VALIDATION_PATH,
    "L23-E002",
    "L2.2 blueprint validation output",
)

decisions = load_json(
    DECISIONS_PATH,
    "L23-E003",
    "Bibliographic decisions input",
)

evidence = load_json(
    EVIDENCE_PATH,
    "L23-E004",
    "Bibliographic evidence input",
)


# ================================================================
# L2.2 VALIDATION GATE
# ================================================================

validation_summary = (
    blueprint_validation.get("summary", {})
    if isinstance(blueprint_validation, dict)
    else {}
)

if validation_summary.get("overall_status") != "VALID":
    error(
        "L23-E002",
        "L2.2 CSP11 blueprint validation is not VALID.",
        status=validation_summary.get("overall_status"),
    )


# ================================================================
# CANONICAL BLUEPRINT EXTRACTION
# ================================================================

domains = (
    blueprint.get("domains", [])
    if isinstance(blueprint, dict)
    else []
)

canonical_competencies = {}
canonical_domains = {}

for domain in domains:

    if not isinstance(domain, dict):
        continue

    domain_id = domain.get("domain_id")
    domain_name = domain.get("name")
    weight = domain.get("weight_percent")

    if isinstance(domain_id, str):
        canonical_domains[domain_id] = {
            "domain_id": domain_id,
            "domain_number": domain.get("domain_number"),
            "name": domain_name,
            "weight_percent": weight,
        }

    competencies = domain.get("competencies", [])

    if not isinstance(competencies, list):
        continue

    for competency in competencies:

        if not isinstance(competency, dict):
            continue

        competency_id = competency.get("competency_id")

        if not isinstance(competency_id, str):
            continue

        canonical_competencies[competency_id] = {
            "competency_id": competency_id,
            "number": competency.get("number"),
            "statement": competency.get("statement"),
            "domain_id": domain_id,
            "domain_name": domain_name,
            "domain_weight_percent": weight,
        }


# ================================================================
# CANONICAL COMPETENCY VALIDATION
# ================================================================

for competency_id, competency in canonical_competencies.items():

    if not re.fullmatch(r"d\d{2}_c\d{2}", competency_id):
        error(
            "L23-E009",
            "Invalid canonical competency ID format.",
            competency_id=competency_id,
        )


expected_competency_count = 47

if len(canonical_competencies) != expected_competency_count:
    error(
        "L23-E010",
        "Canonical competency count does not equal 47.",
        actual=len(canonical_competencies),
        expected=expected_competency_count,
    )


# ================================================================
# SOURCE DECISION EXTRACTION
# ================================================================

decision_records = (
    decisions.get("decision_records", [])
    if isinstance(decisions, dict)
    else []
)

if not isinstance(decision_records, list):
    decision_records = []

decision_source_ids = []
decision_by_source_id = {}

for record in decision_records:

    if not isinstance(record, dict):
        continue

    source_id = record.get("source_id")

    if isinstance(source_id, str):
        decision_source_ids.append(source_id)
        decision_by_source_id[source_id] = record


# ================================================================
# SOURCE EVIDENCE EXTRACTION
# ================================================================

evidence_results = (
    evidence.get("evidence_results", [])
    if isinstance(evidence, dict)
    else []
)

if not isinstance(evidence_results, list):
    evidence_results = []

evidence_source_ids = []
evidence_by_source_id = {}

for record in evidence_results:

    if not isinstance(record, dict):
        continue

    source_id = record.get("source_id")

    if isinstance(source_id, str):
        evidence_source_ids.append(source_id)
        evidence_by_source_id[source_id] = record


# ================================================================
# SOURCE COUNT VALIDATION
# ================================================================

expected_source_count = 25

if len(decision_records) != expected_source_count:
    error(
        "L23-E005",
        "Bibliographic decision source count does not equal 25.",
        actual=len(decision_records),
        expected=expected_source_count,
    )

if len(evidence_results) != expected_source_count:
    error(
        "L23-E005",
        "Bibliographic evidence source count does not equal 25.",
        actual=len(evidence_results),
        expected=expected_source_count,
    )


# ================================================================
# DUPLICATE SOURCE VALIDATION
# ================================================================

duplicate_decision_ids = sorted({
    source_id
    for source_id in decision_source_ids
    if decision_source_ids.count(source_id) > 1
})

if duplicate_decision_ids:
    error(
        "L23-E006",
        "Duplicate source IDs detected in bibliographic decisions.",
        source_ids=duplicate_decision_ids,
    )


duplicate_evidence_ids = sorted({
    source_id
    for source_id in evidence_source_ids
    if evidence_source_ids.count(source_id) > 1
})

if duplicate_evidence_ids:
    error(
        "L23-E006",
        "Duplicate source IDs detected in bibliographic evidence.",
        source_ids=duplicate_evidence_ids,
    )


# ================================================================
# SOURCE CROSS-REFERENCE VALIDATION
# ================================================================

decision_id_set = set(decision_source_ids)
evidence_id_set = set(evidence_source_ids)

missing_from_evidence = sorted(
    decision_id_set - evidence_id_set
)

if missing_from_evidence:
    error(
        "L23-E007",
        "Source exists in bibliographic decisions but is missing from evidence.",
        source_ids=missing_from_evidence,
    )


missing_from_decisions = sorted(
    evidence_id_set - decision_id_set
)

if missing_from_decisions:
    error(
        "L23-E008",
        "Source exists in bibliographic evidence but is missing from decisions.",
        source_ids=missing_from_decisions,
    )


# ================================================================
# DETERMINISTIC SOURCE ORDER
# ================================================================

ordered_source_ids = sorted(
    decision_id_set | evidence_id_set
)


# ================================================================
# L2.3 MAPPING PREPARATION
# ================================================================

source_mappings = []

mapping_candidate_count = 0
pending_review_count = 0


for source_id in ordered_source_ids:

    decision_record = decision_by_source_id.get(
        source_id,
        {},
    )

    evidence_record = evidence_by_source_id.get(
        source_id,
        {},
    )

    filename = (
        decision_record.get("filename")
        or evidence_record.get("filename")
    )

    review_status = (
        decision_record.get("review_status")
        or evidence_record.get("review_status")
        or "UNKNOWN"
    )

    human_decision = decision_record.get(
        "human_decision",
        {},
    )

    candidate_evidence = decision_record.get(
        "candidate_evidence",
        {},
    )

    candidate_confidence = decision_record.get(
        "candidate_confidence"
    )

    evidence_basis = []

    # Preserve actual source evidence available at this stage.
    text_evidence = evidence_record.get(
        "text_evidence",
        {},
    )

    if isinstance(text_evidence, dict):

        first_page_text = text_evidence.get(
            "first_nonempty_page_text"
        )

        if isinstance(first_page_text, str) and first_page_text.strip():

            evidence_basis.append({
                "type": "sampled_page_text",
                "page": text_evidence.get(
                    "first_nonempty_page"
                ),
                "text": first_page_text,
            })

    bibliographic_signals = evidence_record.get(
        "bibliographic_signals",
        {},
    )

    if isinstance(bibliographic_signals, dict):

        year_candidates = bibliographic_signals.get(
            "year_candidates",
            [],
        )

        if year_candidates:
            evidence_basis.append({
                "type": "bibliographic_year_candidates",
                "values": year_candidates,
            })

    # IMPORTANT:
    # No competency is automatically assigned here.
    # L2.3 creates the controlled mapping container.
    competency_mappings = []

    # Bibliographic review warnings.
    if review_status == "PENDING_HUMAN_REVIEW":
        pending_review_count += 1

        warning(
            "L23-W001",
            "Source remains pending human bibliographic review.",
            source_id=source_id,
        )

    if candidate_confidence == "LOW":
        warning(
            "L23-W002",
            "Source contains low-confidence bibliographic evidence.",
            source_id=source_id,
        )

    if not competency_mappings:
        warning(
            "L23-W003",
            "Source has no automatically generated competency mappings; "
            "human review is required.",
            source_id=source_id,
        )

    source_mappings.append({
        "source_id": source_id,
        "filename": filename,
        "source_review_status": review_status,
        "bibliographic_review": {
            "decision": human_decision.get("decision"),
            "candidate_confidence": candidate_confidence,
            "candidate_evidence_available": bool(
                candidate_evidence
            ),
        },
        "competency_mappings": competency_mappings,
        "human_review_required": True,
        "automatic_mapping_performed": False,
    })


# ================================================================
# MAPPING VALIDATION
# ================================================================

for source_record in source_mappings:

    source_id = source_record.get("source_id")

    mappings = source_record.get(
        "competency_mappings",
        [],
    )

    seen_competency_ids = set()

    for mapping in mappings:

        if not isinstance(mapping, dict):
            error(
                "L23-E009",
                "Competency mapping must be an object.",
                source_id=source_id,
            )
            continue

        competency_id = mapping.get("competency_id")

        if not isinstance(competency_id, str):
            error(
                "L23-E009",
                "Mapping competency_id must be a string.",
                source_id=source_id,
            )
            continue

        if not re.fullmatch(
            r"d\d{2}_c\d{2}",
            competency_id,
        ):
            error(
                "L23-E009",
                "Mapping competency ID does not follow dXX_cXX format.",
                source_id=source_id,
                competency_id=competency_id,
            )

        if competency_id not in canonical_competencies:
            error(
                "L23-E010",
                "Mapping references a competency not present "
                "in the canonical blueprint.",
                source_id=source_id,
                competency_id=competency_id,
            )

        if competency_id in seen_competency_ids:
            error(
                "L23-E011",
                "Duplicate competency mapping within source.",
                source_id=source_id,
                competency_id=competency_id,
            )

        seen_competency_ids.add(competency_id)

        status = mapping.get("mapping_status")

        if status not in ALLOWED_MAPPING_STATUSES:
            error(
                "L23-E013",
                "Invalid mapping status.",
                source_id=source_id,
                competency_id=competency_id,
                status=status,
            )

        if status == "confirmed":
            error(
                "L23-E014",
                "Automatic confirmation detected in L2.3.",
                source_id=source_id,
                competency_id=competency_id,
            )

        mapping_evidence = mapping.get(
            "evidence_basis"
        )

        if not isinstance(mapping_evidence, list) or not mapping_evidence:
            error(
                "L23-E012",
                "Non-empty mapping is missing evidence basis.",
                source_id=source_id,
                competency_id=competency_id,
            )


# ================================================================
# FINAL OUTPUT
# ================================================================

blueprint_metadata = (
    blueprint.get("blueprint", {})
    if isinstance(blueprint, dict)
    else {}
)

overall_status = "INVALID" if errors else "VALID"

output = {
    "pipeline": "CSP11 Source-to-Domain Knowledge Pipeline",
    "stage": "L2.3 CSP11 Source-to-Competency Mapping Preparation",
    "generated_at": datetime.now().isoformat(timespec="seconds"),

    "blueprint_reference": {
        "name": blueprint_metadata.get("name"),
        "version": blueprint_metadata.get("version"),
        "effective_date": blueprint_metadata.get(
            "effective_date"
        ),
        "issuing_body": blueprint_metadata.get(
            "issuing_body"
        ),
    },

    "input_references": {
        "canonical_blueprint": str(
            BLUEPRINT_PATH.relative_to(ROOT)
        ),
        "blueprint_validation": str(
            BLUEPRINT_VALIDATION_PATH.relative_to(ROOT)
        ),
        "bibliographic_decisions": str(
            DECISIONS_PATH.relative_to(ROOT)
        ),
        "bibliographic_evidence": str(
            EVIDENCE_PATH.relative_to(ROOT)
        ),
    },

    "source_count": len(source_mappings),
    "competency_count": len(canonical_competencies),

    "mapping_policy": {
        "canonical_blueprint_is_authoritative": True,
        "source_mapping_requires_evidence": True,
        "candidate_evidence_is_not_final_fact": True,
        "human_review_required": True,
        "automatic_competency_creation": False,
        "automatic_reclassification": False,
        "automatic_confirmation": False,
        "new_mapping_default_status": GENERATED_MAPPING_STATUS,
    },

    "canonical_domains": list(
        canonical_domains.values()
    ),

    "canonical_competencies": list(
        canonical_competencies.values()
    ),

    "source_mappings": source_mappings,

    "summary": {
        "overall_status": overall_status,
        "source_count": len(source_mappings),
        "competency_count": len(canonical_competencies),
        "mapping_candidate_count": mapping_candidate_count,
        "pending_review_count": pending_review_count,
        "blocking_issues": len(errors),
        "warnings": len(warnings),
    },

    "issues": errors,
    "warnings": warnings,
}


# ================================================================
# WRITE OUTPUT
# ================================================================

OUTPUT_PATH.parent.mkdir(
    parents=True,
    exist_ok=True,
)

with OUTPUT_PATH.open(
    "w",
    encoding="utf-8",
    newline="\n",
) as handle:

    json.dump(
        output,
        handle,
        indent=2,
        ensure_ascii=False,
    )

    handle.write("\n")


# ================================================================
# CONSOLE REPORT
# ================================================================

print("===== L2.3 CSP11 SOURCE-TO-COMPETENCY MAPPING =====")
print(f"Sources: {len(source_mappings)}")
print(f"Competencies: {len(canonical_competencies)}")
print(f"Mapping candidates: {mapping_candidate_count}")
print(f"Pending review: {pending_review_count}")
print(f"Blocking issues: {len(errors)}")
print(f"Warnings: {len(warnings)}")
print(f"OVERALL STATUS: {overall_status}")
print(f"Output: {OUTPUT_PATH}")

