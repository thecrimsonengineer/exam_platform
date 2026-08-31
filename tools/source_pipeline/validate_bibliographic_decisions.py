import json
from pathlib import Path
from datetime import datetime

INPUT_PATH = Path(
    "docs/source_pipeline/SRC-001_to_SRC-048_bibliographic_decisions.json"
)

OUTPUT_PATH = Path(
    "docs/source_pipeline/SRC-001_to_SRC-048_bibliographic_decision_validation.json"
)

with INPUT_PATH.open("r", encoding="utf-8") as f:
    data = json.load(f)

allowed_decisions = {
    "PENDING",
    "ACCEPT",
    "MODIFY",
    "REJECT",
    "HOLD",
}

completed_decisions = {
    "ACCEPT",
    "MODIFY",
    "REJECT",
    "HOLD",
}

allowed_source_types = {
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
    "UNCLASSIFIED",
}

required_top_level_fields = {
    "source_id",
    "filename",
    "page_count",
    "candidate_confidence",
    "candidate_evidence",
    "pdf_metadata_reference",
    "human_decision",
    "decision_rules",
    "review_status",
}

required_decision_fields = {
    "source_type",
    "title",
    "author_or_organisation",
    "edition_or_version",
    "publisher",
    "publication_year",
    "isbn_or_identifier",
    "official_or_regulatory_source",
    "decision",
    "reviewer",
    "review_date",
    "review_notes",
}

allowed_review_statuses = {
    "PENDING_HUMAN_REVIEW",
    "REVIEWED",
    "FINAL",
}

results = []

for record in data.get("decision_records", []):

    source_id = record.get("source_id")
    issues = []
    warnings = []

    # ------------------------------------------------------------
    # TOP-LEVEL STRUCTURE
    # ------------------------------------------------------------

    missing_fields = sorted(
        required_top_level_fields - set(record.keys())
    )

    if missing_fields:
        issues.append({
            "code": "L17-E001",
            "message": "Missing required top-level fields.",
            "fields": missing_fields,
        })

    # ------------------------------------------------------------
    # SOURCE ID
    # ------------------------------------------------------------

    if not isinstance(source_id, str) or not source_id.strip():
        issues.append({
            "code": "L17-E002",
            "message": "source_id must be a non-empty string.",
        })

    # ------------------------------------------------------------
    # PAGE COUNT
    # ------------------------------------------------------------

    page_count = record.get("page_count")

    if not isinstance(page_count, int) or page_count <= 0:
        issues.append({
            "code": "L17-E003",
            "message": "page_count must be a positive integer.",
        })

    # ------------------------------------------------------------
    # HUMAN DECISION STRUCTURE
    # ------------------------------------------------------------

    human_decision = record.get("human_decision")

    if not isinstance(human_decision, dict):
        issues.append({
            "code": "L17-E004",
            "message": "human_decision must be an object.",
        })
        human_decision = {}

    missing_decision_fields = sorted(
        required_decision_fields - set(human_decision.keys())
    )

    if missing_decision_fields:
        issues.append({
            "code": "L17-E005",
            "message": "Missing required human decision fields.",
            "fields": missing_decision_fields,
        })

    decision = human_decision.get("decision")
    source_type = human_decision.get("source_type")
    reviewer = human_decision.get("reviewer")
    review_date = human_decision.get("review_date")
    review_notes = human_decision.get("review_notes")

    review_status = record.get("review_status")

    # ------------------------------------------------------------
    # DECISION VALUE
    # ------------------------------------------------------------

    if decision not in allowed_decisions:
        issues.append({
            "code": "L17-E006",
            "message": "Invalid human decision value.",
            "value": decision,
        })

    # ------------------------------------------------------------
    # SOURCE TYPE
    # ------------------------------------------------------------

    if source_type is not None and source_type not in allowed_source_types:
        issues.append({
            "code": "L17-E007",
            "message": "Invalid source_type value.",
            "value": source_type,
        })

    # ------------------------------------------------------------
    # REVIEW STATUS
    # ------------------------------------------------------------

    if review_status not in allowed_review_statuses:
        issues.append({
            "code": "L17-E019",
            "message": "Invalid review_status value.",
            "value": review_status,
        })

    # ------------------------------------------------------------
    # PENDING STATE
    # ------------------------------------------------------------

    if decision == "PENDING":

        if review_status != "PENDING_HUMAN_REVIEW":
            issues.append({
                "code": "L17-E015",
                "message": (
                    "PENDING decision requires "
                    "PENDING_HUMAN_REVIEW status."
                ),
            })

        if reviewer not in (None, ""):
            warnings.append({
                "code": "L17-W001",
                "message": (
                    "Pending review record contains reviewer metadata."
                ),
            })

        if review_date not in (None, ""):
            warnings.append({
                "code": "L17-W002",
                "message": (
                    "Pending review record contains review_date."
                ),
            })

    # ------------------------------------------------------------
    # COMPLETED DECISION REQUIREMENTS
    # ------------------------------------------------------------

    if decision in completed_decisions:

        if not reviewer:
            issues.append({
                "code": "L17-E008",
                "message": (
                    f"{decision} decision requires reviewer."
                ),
            })

        if not review_date:
            issues.append({
                "code": "L17-E009",
                "message": (
                    f"{decision} decision requires review_date."
                ),
            })

        if source_type in {None, "UNCLASSIFIED"}:
            issues.append({
                "code": "L17-E010",
                "message": (
                    f"{decision} decision requires a classified "
                    "source_type."
                ),
            })

        if review_status == "PENDING_HUMAN_REVIEW":
            issues.append({
                "code": "L17-E020",
                "message": (
                    f"{decision} decision cannot remain in "
                    "PENDING_HUMAN_REVIEW status."
                ),
            })

    # ------------------------------------------------------------
    # MODIFY REQUIREMENTS
    # ------------------------------------------------------------

    if decision == "MODIFY" and not review_notes:
        issues.append({
            "code": "L17-E011",
            "message": "MODIFY decision requires review_notes.",
        })

    # ------------------------------------------------------------
    # REJECT / HOLD REQUIREMENTS
    # ------------------------------------------------------------

    if decision in {"REJECT", "HOLD"}:

        if not review_notes:
            issues.append({
                "code": "L17-E014",
                "message": (
                    f"{decision} decision requires review_notes."
                ),
            })

    # ------------------------------------------------------------
    # COMPLETED REVIEW STATUS
    # ------------------------------------------------------------

    if review_status in {"REVIEWED", "FINAL"}:

        if decision == "PENDING":
            issues.append({
                "code": "L17-E021",
                "message": (
                    "Reviewed or final records cannot have "
                    "a PENDING decision."
                ),
            })

    # ------------------------------------------------------------
    # CANDIDATE EVIDENCE PRESERVATION
    # ------------------------------------------------------------

    candidate_evidence = record.get("candidate_evidence")

    if not isinstance(candidate_evidence, dict):
        issues.append({
            "code": "L17-E016",
            "message": "candidate_evidence must be an object.",
        })

    # ------------------------------------------------------------
    # DECISION RULES
    # ------------------------------------------------------------

    rules = record.get("decision_rules")

    if not isinstance(rules, dict):
        issues.append({
            "code": "L17-E017",
            "message": "decision_rules must be an object.",
        })

    else:

        expected_rules = {
            "accepted_values_must_be_supported": True,
            "candidate_values_are_not_final_facts": True,
            "pdf_metadata_is_not_automatically_authoritative": True,
            "human_review_required_before_final_classification": True,
            "uncertain_values_must_remain_null": True,
        }

        for key, expected_value in expected_rules.items():

            if rules.get(key) is not expected_value:

                issues.append({
                    "code": "L17-E018",
                    "message": (
                        f"Decision rule '{key}' must be "
                        f"{expected_value}."
                    ),
                })

    # ------------------------------------------------------------
    # FINAL STATUS SAFETY
    # ------------------------------------------------------------

    if review_status == "FINAL":

        if decision not in completed_decisions:
            issues.append({
                "code": "L17-E022",
                "message": (
                    "FINAL review_status requires a completed "
                    "decision."
                ),
            })

    # ------------------------------------------------------------
    # RECORD RESULT
    # ------------------------------------------------------------

    status = "INVALID" if issues else "VALID"

    results.append({
        "source_id": source_id,
        "status": status,
        "blocking_issue_count": len(issues),
        "warning_count": len(warnings),
        "issues": issues,
        "warnings": warnings,
    })


# ================================================================
# GLOBAL VALIDATION
# ================================================================

source_ids = [
    record.get("source_id")
    for record in data.get("decision_records", [])
]

duplicate_ids = sorted({
    source_id
    for source_id in source_ids
    if source_id is not None
    and source_ids.count(source_id) > 1
})

global_issues = []

if duplicate_ids:

    global_issues.append({
        "code": "L17-E023",
        "message": "Duplicate source_id values detected.",
        "source_ids": duplicate_ids,
    })

expected_count = data.get("input_source_count")
actual_count = len(data.get("decision_records", []))

if expected_count != actual_count:

    global_issues.append({
        "code": "L17-E024",
        "message": (
            "Input source count does not match "
            "decision record count."
        ),
        "expected": expected_count,
        "actual": actual_count,
    })

invalid_count = sum(
    1
    for result in results
    if result["status"] == "INVALID"
)

warning_count = sum(
    result["warning_count"]
    for result in results
)

blocking_issue_count = sum(
    result["blocking_issue_count"]
    for result in results
)

overall_status = (
    "INVALID"
    if invalid_count > 0 or global_issues
    else "VALID"
)

output = {

    "pipeline": "CSP11 Source-to-Domain Knowledge Pipeline",

    "stage": "L1.7 Bibliographic Decision Validation Gate",

    "generated_at": datetime.now().isoformat(
        timespec="seconds"
    ),

    "validation_policy": {

        "purpose": (
            "Validate bibliographic decision records "
            "deterministically without assigning or "
            "inventing bibliographic facts."
        ),

        "human_authority_preserved": True,

        "candidate_evidence_not_final_fact": True,

        "uncertain_values_remain_null": True,

        "invalid_records_block_progression": True,

        "pending_decision_is_valid_pre_review_state": True,
    },

    "input_source_count": expected_count,

    "actual_record_count": actual_count,

    "summary": {

        "overall_status": overall_status,

        "valid_records": actual_count - invalid_count,

        "invalid_records": invalid_count,

        "blocking_issues": blocking_issue_count,

        "warnings": warning_count,

        "global_issues": len(global_issues),
    },

    "global_issues": global_issues,

    "record_results": results,
}

with OUTPUT_PATH.open("w", encoding="utf-8") as f:

    json.dump(
        output,
        f,
        indent=2,
        ensure_ascii=False
    )

print("===== L1.7 BIBLIOGRAPHIC DECISION VALIDATION GATE =====")
print(f"Input records: {actual_count}")
print(f"Valid records: {actual_count - invalid_count}")
print(f"Invalid records: {invalid_count}")
print(f"Blocking issues: {blocking_issue_count}")
print(f"Warnings: {warning_count}")
print(f"Global issues: {len(global_issues)}")
print(f"OVERALL STATUS: {overall_status}")
print(f"Output: {OUTPUT_PATH}")
