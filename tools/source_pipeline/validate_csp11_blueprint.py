import json
import re
from pathlib import Path
from datetime import datetime

INPUT_PATH = Path(
    "docs/source_pipeline/CSP11_canonical_blueprint.json"
)

OUTPUT_PATH = Path(
    "docs/source_pipeline/CSP11_canonical_blueprint_validation.json"
)

with INPUT_PATH.open("r", encoding="utf-8") as f:
    blueprint = json.load(f)


# ================================================================
# CANONICAL CSP11 DOMAIN AUTHORITY
# ================================================================

EXPECTED_DOMAINS = [
    {
        "domain_number": 1,
        "name": "Advanced Application of Safety Principles",
        "weight": 25,
    },
    {
        "domain_number": 2,
        "name": "Program Management",
        "weight": 25,
    },
    {
        "domain_number": 3,
        "name": "Risk Management",
        "weight": 15,
    },
    {
        "domain_number": 4,
        "name": "Emergency Management",
        "weight": 9,
    },
    {
        "domain_number": 5,
        "name": "Environmental Management",
        "weight": 6,
    },
    {
        "domain_number": 6,
        "name": "Occupational Health and Applied Science",
        "weight": 10,
    },
    {
        "domain_number": 7,
        "name": "Training",
        "weight": 10,
    },
]

EXPECTED_DOMAIN_NAMES = {
    item["name"] for item in EXPECTED_DOMAINS
}

EXPECTED_WEIGHTS = {
    item["name"]: item["weight"]
    for item in EXPECTED_DOMAINS
}


# ================================================================
# VALIDATION HELPERS
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
# TOP-LEVEL STRUCTURE
# ================================================================

if not isinstance(blueprint, dict):
    error(
        "L22-E001",
        "Canonical blueprint must be a JSON object."
    )
    blueprint = {}

required_top_level_fields = {
    "pipeline",
    "stage",
    "blueprint",
    "domains",
}

missing_top_level = sorted(
    required_top_level_fields - set(blueprint.keys())
)

if missing_top_level:
    error(
        "L22-E002",
        "Missing required top-level blueprint fields.",
        fields=missing_top_level,
    )


# ================================================================
# BLUEPRINT METADATA
# ================================================================

blueprint_metadata = blueprint.get("blueprint", {})
blueprint_version = blueprint_metadata.get("version")

if not isinstance(blueprint_version, str) or not blueprint_version.strip():
    error(
        "L22-E003",
        "blueprint_version must be a non-empty string."
    )

effective_date = blueprint_metadata.get("effective_date")

if not isinstance(effective_date, str) or not effective_date.strip():
    error(
        "L22-E004",
        "effective_date must be a non-empty string."
    )
else:
    try:
        datetime.strptime(effective_date, "%Y-%m-%d")
    except ValueError:
        error(
            "L22-E005",
            "effective_date must use YYYY-MM-DD format.",
            value=effective_date,
        )


# ================================================================
# DOMAIN STRUCTURE
# ================================================================

domains = blueprint.get("domains", [])

if not isinstance(domains, list):
    error(
        "L22-E006",
        "domains must be an array."
    )
    domains = []

if len(domains) != 7:
    error(
        "L22-E007",
        "Canonical CSP11 blueprint must contain exactly 7 domains.",
        actual=len(domains),
        expected=7,
    )


domain_names = []
domain_weights = []
domain_ids = []

for index, domain in enumerate(domains, start=1):

    if not isinstance(domain, dict):
        error(
            "L22-E008",
            "Domain entry must be an object.",
            index=index,
        )
        continue

    domain_id = domain.get("domain_id")
    domain_name = domain.get("name")
    domain_weight = domain.get("weight_percent")

    if domain_id is not None:
        domain_ids.append(domain_id)

    if domain_name is not None:
        domain_names.append(domain_name)

    if domain_weight is not None:
        domain_weights.append(domain_weight)

    if not isinstance(domain_id, str) or not domain_id.strip():
        error(
            "L22-E009",
            "Domain must have a non-empty domain_id.",
            index=index,
        )

    if not isinstance(domain_name, str) or not domain_name.strip():
        error(
            "L22-E010",
            "Domain must have a non-empty name.",
            index=index,
        )
        continue

    if domain_name not in EXPECTED_DOMAIN_NAMES:
        error(
            "L22-E011",
            "Domain is not one of the seven canonical CSP11 domains.",
            domain=domain_name,
        )

    if domain_name in EXPECTED_WEIGHTS:

        expected_weight = EXPECTED_WEIGHTS[domain_name]

        if domain_weight != expected_weight:
            error(
                "L22-E012",
                "Domain weight does not match canonical CSP11 weight.",
                domain=domain_name,
                expected=expected_weight,
                actual=domain_weight,
            )

    if not isinstance(domain_weight, (int, float)):
        error(
            "L22-E013",
            "Domain weight must be numeric.",
            domain=domain_name,
            value=domain_weight,
        )
    elif domain_weight <= 0:
        error(
            "L22-E014",
            "Domain weight must be greater than zero.",
            domain=domain_name,
            value=domain_weight,
        )


# ================================================================
# DOMAIN DUPLICATES / COMPLETENESS
# ================================================================

duplicate_domain_ids = sorted({
    value
    for value in domain_ids
    if domain_ids.count(value) > 1
})

if duplicate_domain_ids:
    error(
        "L22-E015",
        "Duplicate domain_id values detected.",
        domain_ids=duplicate_domain_ids,
    )


duplicate_domain_names = sorted({
    value
    for value in domain_names
    if domain_names.count(value) > 1
})

if duplicate_domain_names:
    error(
        "L22-E016",
        "Duplicate domain names detected.",
        domain_names=duplicate_domain_names,
    )


missing_domains = sorted(
    EXPECTED_DOMAIN_NAMES - set(domain_names)
)

if missing_domains:
    error(
        "L22-E017",
        "One or more canonical CSP11 domains are missing.",
        domains=missing_domains,
    )


unexpected_domains = sorted(
    set(domain_names) - EXPECTED_DOMAIN_NAMES
)

if unexpected_domains:
    error(
        "L22-E018",
        "Unexpected domains detected.",
        domains=unexpected_domains,
    )


# ================================================================
# DOMAIN WEIGHT TOTAL
# ================================================================

numeric_weights = [
    value
    for value in domain_weights
    if isinstance(value, (int, float))
]

weight_total = sum(numeric_weights)

if weight_total != 100:
    error(
        "L22-E019",
        "Canonical domain weights must total exactly 100%.",
        actual=weight_total,
        expected=100,
    )


# ================================================================
# COMPETENCY HIERARCHY
# ================================================================

all_competencies = []
competency_parent_domains = {}

for domain in domains:

    if not isinstance(domain, dict):
        continue

    domain_id = domain.get("domain_id")
    domain_name = domain.get("name")

    competencies = domain.get("competencies")

    if competencies is None:
        error(
            "L22-E020",
            "Domain is missing its authoritative competency hierarchy.",
            domain=domain_name,
            domain_id=domain_id,
        )
        continue

    if not isinstance(competencies, list):
        error(
            "L22-E021",
            "Domain competencies must be an array.",
            domain=domain_name,
            domain_id=domain_id,
        )
        continue

    if len(competencies) == 0:
        error(
            "L22-E022",
            "Domain contains no competencies.",
            domain=domain_name,
            domain_id=domain_id,
        )

    for competency in competencies:

        if not isinstance(competency, dict):
            error(
                "L22-E023",
                "Competency entry must be an object.",
                domain=domain_name,
            )
            continue

        competency_id = competency.get("competency_id")
        competency_statement = competency.get("statement")

        if not isinstance(competency_id, str) or not competency_id.strip():
            error(
                "L22-E024",
                "Competency must have a non-empty competency_id.",
                domain=domain_name,
            )
            continue

        if not isinstance(competency_statement, str) or not competency_statement.strip():
            error(
                "L22-E025",
                "Competency must have a non-empty statement.",
                competency_id=competency_id,
                domain=domain_name,
            )

        all_competencies.append(competency)

        if competency_id in competency_parent_domains:
            error(
                "L22-E026",
                "Competency appears under more than one domain.",
                competency_id=competency_id,
                first_domain=competency_parent_domains[competency_id],
                second_domain=domain_id,
            )
        else:
            competency_parent_domains[competency_id] = domain_id


# ================================================================
# COMPETENCY COUNT
# ================================================================

competency_count = len(all_competencies)

if competency_count != 47:
    error(
        "L22-E027",
        "Canonical CSP11 blueprint must contain exactly 47 competencies.",
        actual=competency_count,
        expected=47,
    )


# ================================================================
# COMPETENCY ID UNIQUENESS
# ================================================================

competency_ids = [
    competency.get("competency_id")
    for competency in all_competencies
    if isinstance(competency, dict)
    and competency.get("competency_id") is not None
]

duplicate_competency_ids = sorted({
    value
    for value in competency_ids
    if competency_ids.count(value) > 1
})

if duplicate_competency_ids:
    error(
        "L22-E028",
        "Duplicate competency_id values detected.",
        competency_ids=duplicate_competency_ids,
    )


# ================================================================
# COMPETENCY ID FORMAT
# ================================================================

for competency_id in competency_ids:

    if not re.fullmatch(r"d\d{2}_c\d{2}", competency_id):
        error(
            "L22-E029",
            "Competency ID does not follow canonical dXX_cXX format.",
            competency_id=competency_id,
        )


# ================================================================
# DOMAIN / COMPETENCY ID CONSISTENCY
# ================================================================

for domain in domains:

    if not isinstance(domain, dict):
        continue

    domain_id = domain.get("domain_id")

    if not isinstance(domain_id, str):
        continue

    domain_match = re.fullmatch(r"d(\d{2})", domain_id)

    if not domain_match:
        warning(
            "L22-W001",
            "Domain ID does not follow the expected dXX format.",
            domain_id=domain_id,
        )
        continue

    expected_prefix = f"d{domain_match.group(1)}_c"

    for competency in domain.get("competencies", []):

        if not isinstance(competency, dict):
            continue

        competency_id = competency.get("competency_id")

        if (
            isinstance(competency_id, str)
            and not competency_id.startswith(expected_prefix)
        ):
            error(
                "L22-E030",
                "Competency ID does not belong to its parent domain.",
                competency_id=competency_id,
                domain_id=domain_id,
            )


# ================================================================
# COMPETENCY ORPHAN CHECK
# ================================================================

orphan_competencies = [
    competency.get("competency_id")
    for competency in all_competencies
    if competency.get("competency_id") not in competency_parent_domains
]

if orphan_competencies:
    error(
        "L22-E031",
        "Orphan competencies detected.",
        competency_ids=orphan_competencies,
    )


# ================================================================
# OPTIONAL DECLARED COUNTS
# ================================================================

declared_domain_count = blueprint.get("domain_count")

if declared_domain_count is not None:

    if declared_domain_count != 7:
        error(
            "L22-E032",
            "Declared domain_count does not equal 7.",
            actual=declared_domain_count,
            expected=7,
        )


declared_competency_count = blueprint.get("competency_count")

if declared_competency_count is not None:

    if declared_competency_count != 47:
        error(
            "L22-E033",
            "Declared competency_count does not equal 47.",
            actual=declared_competency_count,
            expected=47,
        )


# ================================================================
# NO AUTOMATIC REPAIR POLICY
# ================================================================

validation_policy = {
    "canonical_blueprint_is_authoritative": True,
    "domain_weights_are_fixed": True,
    "exactly_seven_domains_required": True,
    "exactly_forty_seven_competencies_required": True,
    "competencies_must_have_single_parent_domain": True,
    "competency_ids_must_be_unique": True,
    "competency_id_format_required": "dXX_cXX",
    "invalid_structure_blocks_progression": True,
    "validator_does_not_modify_blueprint": True,
    "validator_does_not_invent_competencies": True,
    "validator_does_not_reclassify_competencies": True,
}


# ================================================================
# FINAL RESULT
# ================================================================

overall_status = "INVALID" if errors else "VALID"

output = {
    "pipeline": "CSP11 Source-to-Domain Knowledge Pipeline",
    "stage": "L2.2 CSP11 Blueprint Validation and Integrity Gate",
    "generated_at": datetime.now().isoformat(timespec="seconds"),

    "blueprint_reference": {
        "version": blueprint_version,
        "effective_date": effective_date,
    },

    "validation_policy": validation_policy,

    "canonical_domain_expectation": {
        "domain_count": 7,
        "weight_total": 100,
        "domains": EXPECTED_DOMAINS,
    },

    "observed_structure": {
        "domain_count": len(domains),
        "competency_count": competency_count,
        "weight_total": weight_total,
        "unique_domain_ids": len(set(domain_ids)),
        "unique_domain_names": len(set(domain_names)),
        "unique_competency_ids": len(set(competency_ids)),
    },

    "summary": {
        "overall_status": overall_status,
        "blocking_issues": len(errors),
        "warnings": len(warnings),
    },

    "issues": errors,
    "warnings": warnings,
}

with OUTPUT_PATH.open("w", encoding="utf-8") as f:
    json.dump(
        output,
        f,
        indent=2,
        ensure_ascii=False,
    )


print("===== L2.2 CSP11 BLUEPRINT VALIDATION =====")
print(f"Domains: {len(domains)}")
print(f"Competencies: {competency_count}")
print(f"Weight total: {weight_total}%")
print(f"Blocking issues: {len(errors)}")
print(f"Warnings: {len(warnings)}")
print(f"OVERALL STATUS: {overall_status}")
print(f"Output: {OUTPUT_PATH}")
