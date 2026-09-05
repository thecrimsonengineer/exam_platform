import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]

BLUEPRINT_PATH = ROOT / "docs/source_pipeline/CSP11_canonical_blueprint.json"
BLUEPRINT_VALIDATION_PATH = ROOT / "docs/source_pipeline/CSP11_canonical_blueprint_validation.json"
EVIDENCE_PATH = ROOT / "docs/source_pipeline/CSP11_source_content_evidence.json"
SOURCE_CONTROL_PATH = ROOT / "docs/source_pipeline/CSP11_source_control.json"
DECISIONS_PATH = ROOT / "docs/source_pipeline/SRC-001_to_SRC-048_bibliographic_decisions.json"
L23B_PATH = ROOT / "docs/source_pipeline/CSP11_source_to_competency_mapping.json"
OUTPUT_PATH = ROOT / "docs/source_pipeline/CSP11_source_to_competency_candidates.json"


errors = []
warnings = []


def error(code, message, **extra):
    item = {"code": code, "message": message}
    item.update(extra)
    errors.append(item)


def warning(code, message, **extra):
    item = {"code": code, "message": message}
    item.update(extra)
    warnings.append(item)


def load(path, code, description):
    if not path.exists():
        error(code, f"{description} is missing.", path=str(path))
        return {}

    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError) as exc:
        error(
            code,
            f"{description} is not valid JSON.",
            path=str(path),
            detail=str(exc),
        )
        return {}


required_inputs = [
    (BLUEPRINT_PATH, "L23C-V001", "Canonical blueprint"),
    (BLUEPRINT_VALIDATION_PATH, "L23C-V002", "Blueprint validation"),
    (EVIDENCE_PATH, "L23C-V003", "Source content evidence"),
    (SOURCE_CONTROL_PATH, "L23C-V090", "CSP11 source control"),
    (DECISIONS_PATH, "L23C-V004", "Bibliographic decisions"),
    (L23B_PATH, "L23C-V005", "L2.3-B mapping contract"),
]

loaded = {
    path: load(path, code, description)
    for path, code, description in required_inputs
}

blueprint = loaded[BLUEPRINT_PATH]
blueprint_validation = loaded[BLUEPRINT_VALIDATION_PATH]
evidence = loaded[EVIDENCE_PATH]
source_control = loaded[SOURCE_CONTROL_PATH]
decisions = loaded[DECISIONS_PATH]
l23b = loaded[L23B_PATH]


if not OUTPUT_PATH.exists():
    error(
        "L23C-V006",
        "Generated L2.3-C output is missing.",
        path=str(OUTPUT_PATH),
    )
    output = {}
else:
    output = load(
        OUTPUT_PATH,
        "L23C-V007",
        "Generated L2.3-C output",
    )


# Blueprint validation
domains = blueprint.get("domains", [])

if len(domains) != 7:
    error(
        "L23C-V008",
        "Blueprint must contain exactly 7 domains.",
        actual=len(domains),
        expected=7,
    )


canonical = {}

for domain in domains:
    if not isinstance(domain, dict):
        error("L23C-V009", "Domain is not an object.")
        continue

    domain_id = domain.get("domain_id")

    for competency in domain.get("competencies", []):
        if not isinstance(competency, dict):
            error("L23C-V010", "Competency is not an object.")
            continue

        cid = competency.get("competency_id")

        if not isinstance(cid, str):
            error(
                "L23C-V011",
                "Competency ID is not a string.",
            )
            continue

        if not re.fullmatch(r"d\d{2}_c\d{2}", cid):
            error(
                "L23C-V012",
                "Invalid competency ID format.",
                competency_id=cid,
            )

        if cid in canonical:
            error(
                "L23C-V013",
                "Duplicate canonical competency ID.",
                competency_id=cid,
            )

        canonical[cid] = domain_id


if len(canonical) != 47:
    error(
        "L23C-V014",
        "Canonical competency count must equal 47.",
        actual=len(canonical),
        expected=47,
    )


validation_summary = blueprint_validation.get("summary", {})

if validation_summary.get("overall_status") != "VALID":
    error(
        "L23C-V015",
        "Blueprint validation input is not VALID.",
        status=validation_summary.get("overall_status"),
    )


# A4 evidence population
evidence_records = evidence.get("source_evidence", [])

if not isinstance(evidence_records, list):
    error(
        "L23C-V016",
        "source_evidence must be a list.",
    )
    evidence_records = []


evidence_ids = []

for record in evidence_records:
    if not isinstance(record, dict):
        error("L23C-V017", "Evidence source record is not an object.")
        continue

    sid = record.get("source_id")

    if not isinstance(sid, str):
        error(
            "L23C-V018",
            "Evidence source_id must be a string.",
        )
        continue

    evidence_ids.append(sid)


if len(evidence_ids) != len(set(evidence_ids)):
    error(
        "L23C-V019",
        "Duplicate source IDs in evidence input.",
    )


evidence_by_id = {
    r.get("source_id"): r
    for r in evidence_records
    if isinstance(r, dict)
}


# Independent source-control boundary validation.
EXPECTED_SOURCE_IDS = [f"SRC-{i:03d}" for i in range(1, 49)]
EXPECTED_EXCLUDED_SOURCE_IDS = {"SRC-003", "SRC-014"}
authoritative_source_ids = set()
excluded_source_ids = set()

source_control_records = (
    source_control.get("source_control", [])
    if isinstance(source_control, dict)
    else []
)

if not isinstance(source_control_records, list):
    error("L23C-V091", "Source-control source_control field must be a list.")
    source_control_records = []

source_control_ids = [
    record.get("source_id")
    for record in source_control_records
    if isinstance(record, dict)
]

if len(source_control_records) != 48 or len(source_control_ids) != 48 or len(set(source_control_ids)) != 48 or sorted(source_control_ids) != EXPECTED_SOURCE_IDS:
    error("L23C-V092", "Source-control universe must contain exactly SRC-001 through SRC-048.")

if len(evidence_ids) != 48 or len(set(evidence_ids)) != 48 or sorted(evidence_ids) != EXPECTED_SOURCE_IDS:
    error("L23C-V093", "A4 evidence universe must contain exactly SRC-001 through SRC-048.")

for record in source_control_records:
    if not isinstance(record, dict):
        error("L23C-V094", "Source-control record is not an object.")
        continue

    sid = record.get("source_id")
    eligibility = record.get("source_eligibility")
    allowed = record.get("candidate_generation_allowed")

    if eligibility not in {"AUTHORITATIVE", "EXCLUDED"}:
        error("L23C-V095", "Invalid source eligibility in source-control artifact.", source_id=sid, eligibility=eligibility)
        continue

    if allowed is not (eligibility == "AUTHORITATIVE"):
        error("L23C-V096", "candidate_generation_allowed disagrees with source eligibility.", source_id=sid)

    if eligibility == "AUTHORITATIVE":
        authoritative_source_ids.add(sid)
    else:
        excluded_source_ids.add(sid)

if len(authoritative_source_ids) != 46:
    error("L23C-V097", "Source-control artifact must define exactly 46 authoritative sources.", actual=len(authoritative_source_ids), expected=46)

if excluded_source_ids != EXPECTED_EXCLUDED_SOURCE_IDS:
    error("L23C-V098", "Excluded source set must be exactly SRC-003 and SRC-014.", actual=sorted(excluded_source_ids), expected=sorted(EXPECTED_EXCLUDED_SOURCE_IDS))

if isinstance(source_control, dict):
    if source_control.get("authoritative_source_ids") != sorted(authoritative_source_ids):
        error("L23C-V099", "Top-level authoritative_source_ids is inconsistent with source-control records.")

    if source_control.get("excluded_source_ids") != sorted(excluded_source_ids):
        error("L23C-V100", "Top-level excluded_source_ids is inconsistent with source-control records.")

    source_universe = source_control.get("source_universe")
    expected_counts = {
        "inventory_source_count": 48,
        "content_evidence_source_count": 48,
        "controlled_source_count": 48,
        "authoritative_source_count": 46,
        "excluded_source_count": 2,
    }
    if not isinstance(source_universe, dict) or any(source_universe.get(key) != value for key, value in expected_counts.items()):
        error("L23C-V101", "Source-control universe counts are inconsistent with the frozen 48/46/2 boundary.")

    policy = source_control.get("policy")
    required_true_policy = [
        "source_eligibility_is_separate_from_bibliographic_review",
        "source_eligibility_is_separate_from_competency_mapping_review",
        "excluded_sources_are_preserved_for_provenance",
        "excluded_sources_are_not_candidate_generation_inputs",
        "authoritative_sources_are_not_automatically_competency_mapped",
        "human_review_remains_required_for_competency_mapping",
        "fail_closed_on_source_universe_mismatch",
    ]
    if not isinstance(policy, dict) or any(policy.get(key) is not True for key in required_true_policy):
        error("L23C-V102", "Source-control policy does not satisfy the frozen eligibility boundary.")


# Output structure
required_top = [
    "pipeline",
    "stage",
    "generated_at",
    "schema_version",
    "input_references",
    "mapping_policy",
    "source_count",
    "competency_count",
    "candidate_count",
    "pending_human_review_count",
    "unmapped_source_count",
    "source_candidates",
    "summary",
    "issues",
    "warnings",
]

if output:
    for key in required_top:
        if key not in output:
            error(
                "L23C-V020",
                "Required output field is missing.",
                field=key,
            )

    if output.get("schema_version") != "L2.3-C.1":
        error(
            "L23C-V021",
            "Invalid schema version.",
            actual=output.get("schema_version"),
        )


source_candidates = (
    output.get("source_candidates", [])
    if isinstance(output, dict)
    else []
)

if not isinstance(source_candidates, list):
    error(
        "L23C-V022",
        "source_candidates must be a list.",
    )
    source_candidates = []


output_source_ids = [
    r.get("source_id")
    for r in source_candidates
    if isinstance(r, dict)
]

if output_source_ids != sorted(output_source_ids):
    error(
        "L23C-V023",
        "Source ordering is not deterministic.",
    )


if len(output_source_ids) != len(set(output_source_ids)):
    error(
        "L23C-V024",
        "Duplicate source IDs in generated output.",
    )


if len(source_candidates) != len(authoritative_source_ids):
    error(
        "L23C-V025",
        "Output source count does not equal authoritative source-control population.",
        output=len(source_candidates),
        authoritative=len(authoritative_source_ids),
    )


if set(output_source_ids) != authoritative_source_ids:
    error(
        "L23C-V026",
        "Output source population does not match authoritative source-control population.",
        missing=sorted(authoritative_source_ids - set(output_source_ids)),
        unexpected=sorted(set(output_source_ids) - authoritative_source_ids),
    )


pairs = set()
actual_candidate_count = 0
actual_unmapped_count = 0
actual_pending_count = 0


# Hardened signal contract constants. These are intentionally duplicated
# here so validation remains independent from generator implementation.
ALLOWED_SIGNAL_CLASSES = {"generic", "contextual", "distinctive"}
ALLOWED_HIERARCHY_ROLES = {"primary", "parent", "child", "alias"}
ALLOWED_CONFIDENCES = {"high", "medium", "low"}
REQUIRED_MATCH_FIELDS = [
    "signal_id",
    "competency_id",
    "signal",
    "phrase",
    "classification",
    "specificity_weight",
    "independence_group",
    "hierarchy_parent",
    "hierarchy_role",
    "hierarchy_collapsed",
    "negative_context",
    "pages",
    "occurrences",
    "positions",
    "page_positions",
    "proximity",
]


def finite_number(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool) and value == value


def validate_hardened_match(match, source_id, competency_id):
    if not isinstance(match, dict):
        error(
            "L23C-V056",
            "Matched signal must be an object.",
            source_id=source_id,
            competency_id=competency_id,
        )
        return

    for field in REQUIRED_MATCH_FIELDS:
        if field not in match:
            error(
                "L23C-V057",
                "Hardened matched signal field is missing.",
                source_id=source_id,
                competency_id=competency_id,
                field=field,
            )

    if match.get("competency_id") != competency_id:
        error(
            "L23C-V058",
            "Matched signal competency_id does not match candidate competency.",
            source_id=source_id,
            competency_id=competency_id,
        )

    if match.get("classification") not in ALLOWED_SIGNAL_CLASSES:
        error(
            "L23C-V059",
            "Invalid hardened signal classification.",
            source_id=source_id,
            competency_id=competency_id,
        )

    weight = match.get("specificity_weight")
    if not finite_number(weight) or weight <= 0:
        error(
            "L23C-V060",
            "Invalid specificity weight.",
            source_id=source_id,
            competency_id=competency_id,
        )

    group = match.get("independence_group")
    if not isinstance(group, str) or not group.strip():
        error(
            "L23C-V061",
            "Invalid independence group.",
            source_id=source_id,
            competency_id=competency_id,
        )

    if match.get("hierarchy_role") not in ALLOWED_HIERARCHY_ROLES:
        error(
            "L23C-V062",
            "Invalid hierarchy role.",
            source_id=source_id,
            competency_id=competency_id,
        )

    if not isinstance(match.get("hierarchy_collapsed"), bool):
        error(
            "L23C-V063",
            "hierarchy_collapsed must be boolean.",
            source_id=source_id,
            competency_id=competency_id,
        )

    if not isinstance(match.get("negative_context"), bool):
        error(
            "L23C-V064",
            "negative_context must be boolean.",
            source_id=source_id,
            competency_id=competency_id,
        )

    pages = match.get("pages")
    positions = match.get("positions")
    page_positions = match.get("page_positions")
    occurrences = match.get("occurrences")

    if not isinstance(pages, list) or pages != sorted(set(pages)):
        error(
            "L23C-V065",
            "Signal pages are not canonical deterministic data.",
            source_id=source_id,
            competency_id=competency_id,
        )

    canonical_pairs = []
    if not isinstance(page_positions, list):
        error(
            "L23C-V067",
            "page_positions must be a list.",
            source_id=source_id,
            competency_id=competency_id,
        )
    else:
        for pair in page_positions:
            if not isinstance(pair, dict):
                error(
                    "L23C-V068",
                    "page_positions entry must be an object.",
                    source_id=source_id,
                    competency_id=competency_id,
                )
                continue
            page = pair.get("page_number")
            position = pair.get("position")
            if not isinstance(page, int) or isinstance(page, bool) or not isinstance(position, int) or isinstance(position, bool):
                error(
                    "L23C-V069",
                    "page_positions must contain integer coordinates.",
                    source_id=source_id,
                    competency_id=competency_id,
                )
                continue
            canonical_pairs.append((page, position))

        if canonical_pairs != sorted(set(canonical_pairs)):
            error(
                "L23C-V066",
                "Physical signal coordinates are not deterministically canonical.",
                source_id=source_id,
                competency_id=competency_id,
            )

    if isinstance(occurrences, int) and not isinstance(occurrences, bool):
        if occurrences != len(set(canonical_pairs)):
            error(
                "L23C-V071",
                "Signal occurrences do not equal unique physical evidence coordinates.",
                source_id=source_id,
                competency_id=competency_id,
            )
    else:
        error(
            "L23C-V072",
            "Signal occurrences must be an integer.",
            source_id=source_id,
            competency_id=competency_id,
        )

    derived_pages = sorted({page for page, _ in canonical_pairs})
    if pages != derived_pages:
        error(
            "L23C-V073",
            "Signal pages do not match page_positions.",
            source_id=source_id,
            competency_id=competency_id,
        )

    derived_positions = [position for _, position in canonical_pairs]
    if positions != derived_positions:
        error(
            "L23C-V074",
            "Signal positions do not match page_positions.",
            source_id=source_id,
            competency_id=competency_id,
        )

    proximity = match.get("proximity")
    if not finite_number(proximity) or proximity < 0:
        error(
            "L23C-V075",
            "Invalid signal proximity value.",
            source_id=source_id,
            competency_id=competency_id,
        )


def validate_scoring_contract(mapping, source_id, competency_id):
    scoring = mapping.get("scoring")
    competitor = mapping.get("competitor_analysis")

    if not isinstance(scoring, dict):
        error(
            "L23C-V076",
            "Candidate scoring block is missing or invalid.",
            source_id=source_id,
            competency_id=competency_id,
        )
        return

    required = [
        "specificity_score",
        "independence_score",
        "proximity_score",
        "page_support_score",
        "raw_score",
        "competitor_adjustment",
        "final_score",
    ]

    for field in required:
        if not finite_number(scoring.get(field)):
            error(
                "L23C-V077",
                "Candidate scoring field is missing or non-numeric.",
                source_id=source_id,
                competency_id=competency_id,
                field=field,
            )

    if isinstance(competitor, dict):
        stronger = competitor.get("stronger_competitor_count")
        margin = competitor.get("material_competitor_margin")
        adjustment = scoring.get("competitor_adjustment")

        if not isinstance(stronger, int) or isinstance(stronger, bool) or stronger < 0:
            error(
                "L23C-V078",
                "Invalid stronger competitor count.",
                source_id=source_id,
                competency_id=competency_id,
            )
        if not finite_number(margin) or margin < 0:
            error(
                "L23C-V079",
                "Invalid material competitor margin.",
                source_id=source_id,
                competency_id=competency_id,
            )
        if finite_number(adjustment) and isinstance(stronger, int) and not isinstance(stronger, bool):
            expected_adjustment = -min(stronger * 0.50, 1.50)
            if round(adjustment, 3) != round(expected_adjustment, 3):
                error(
                    "L23C-V080",
                    "Competitor adjustment is inconsistent with stronger competitor count.",
                    source_id=source_id,
                    competency_id=competency_id,
                )
    else:
        error(
            "L23C-V081",
            "Candidate competitor_analysis block is missing or invalid.",
            source_id=source_id,
            competency_id=competency_id,
        )

    raw = scoring.get("raw_score")
    adjustment = scoring.get("competitor_adjustment")
    final = scoring.get("final_score")
    score = mapping.get("score")

    if all(finite_number(x) for x in (raw, adjustment, final, score)):
        if round(raw + adjustment, 3) != round(final, 3):
            error(
                "L23C-V082",
                "Final score does not equal raw score plus competitor adjustment.",
                source_id=source_id,
                competency_id=competency_id,
            )
        if round(final, 3) != round(score, 3):
            error(
                "L23C-V083",
                "Mapping score does not equal scoring.final_score.",
                source_id=source_id,
                competency_id=competency_id,
            )



for source in source_candidates:

    sid = source.get("source_id")
    evidence_record = evidence_by_id.get(sid)

    if evidence_record is None:
        error(
            "L23C-V027",
            "Output references unknown evidence source.",
            source_id=sid,
        )
        continue

    extraction_status = source.get("extraction_status")

    if extraction_status != evidence_record.get(
        "source_extraction_status"
    ):
        error(
            "L23C-V028",
            "Extraction status does not match evidence input.",
            source_id=sid,
        )

    mappings = source.get("candidate_mappings", [])

    if not isinstance(mappings, list):
        error(
            "L23C-V029",
            "candidate_mappings must be a list.",
            source_id=sid,
        )
        mappings = []

    if source.get("human_review_required") is not True:
        error(
            "L23C-V030",
            "Source must require human review.",
            source_id=sid,
        )

    if not mappings:
        actual_unmapped_count += 1

    previous_cid = None

    for mapping in mappings:

        actual_candidate_count += 1
        actual_pending_count += 1

        if not isinstance(mapping, dict):
            error(
                "L23C-V031",
                "Candidate mapping must be an object.",
                source_id=sid,
            )
            continue

        required_mapping_fields = [
            "source_id",
            "competency_id",
            "domain_id",
            "mapping_status",
            "confidence",
            "score",
            "matched_signals",
            "evidence_basis",
            "rationale",
            "human_review_required",
        ]

        for field in required_mapping_fields:
            if field not in mapping:
                error(
                    "L23C-V032",
                    "Required mapping field is missing.",
                    source_id=sid,
                    field=field,
                )

        cid = mapping.get("competency_id")

        if previous_cid is not None and cid < previous_cid:
            error(
                "L23C-V033",
                "Competency mappings are not deterministically ordered.",
                source_id=sid,
            )

        previous_cid = cid

        if mapping.get("source_id") != sid:
            error(
                "L23C-V034",
                "Mapping source_id does not match containing source.",
                source_id=sid,
            )

        if cid not in canonical:
            error(
                "L23C-V035",
                "Mapping references unknown competency.",
                source_id=sid,
                competency_id=cid,
            )
        else:
            if mapping.get("domain_id") != canonical[cid]:
                error(
                    "L23C-V036",
                    "Mapping domain_id does not match canonical competency.",
                    source_id=sid,
                    competency_id=cid,
                )

        pair = (sid, cid)

        if pair in pairs:
            error(
                "L23C-V037",
                "Duplicate source-to-competency mapping.",
                source_id=sid,
                competency_id=cid,
            )

        pairs.add(pair)

        if mapping.get("mapping_status") != "candidate":
            error(
                "L23C-V038",
                "Only candidate mapping status is allowed.",
                source_id=sid,
                competency_id=cid,
                status=mapping.get("mapping_status"),
            )

        if mapping.get("mapping_status") == "confirmed":
            error(
                "L23C-V039",
                "Confirmed mapping is prohibited.",
                source_id=sid,
                competency_id=cid,
            )

        if mapping.get("human_review_required") is not True:
            error(
                "L23C-V040",
                "Every candidate requires human review.",
                source_id=sid,
                competency_id=cid,
            )

        confidence = mapping.get("confidence")

        if confidence not in ALLOWED_CONFIDENCES:
            error(
                "L23C-V084",
                "Invalid candidate confidence classification.",
                source_id=sid,
                competency_id=cid,
            )

        matches = mapping.get("matched_signals")
        if not isinstance(matches, list) or not matches:
            error(
                "L23C-V085",
                "Candidate must contain at least one hardened matched signal.",
                source_id=sid,
                competency_id=cid,
            )
        else:
            for match in matches:
                validate_hardened_match(match, sid, cid)

        validate_scoring_contract(mapping, sid, cid)

        evidence_basis = mapping.get("evidence_basis")

        if not isinstance(evidence_basis, list) or not evidence_basis:
            error(
                "L23C-V041",
                "Candidate has empty evidence_basis.",
                source_id=sid,
                competency_id=cid,
            )
        else:
            for item in evidence_basis:

                if not isinstance(item, dict):
                    error(
                        "L23C-V042",
                        "Evidence basis item must be an object.",
                        source_id=sid,
                        competency_id=cid,
                    )
                    continue

                page_number = item.get("page_number")
                text = item.get("supporting_text")

                if page_number is None:
                    error(
                        "L23C-V043",
                        "Evidence basis lacks page number.",
                        source_id=sid,
                        competency_id=cid,
                    )

                if not isinstance(text, str) or not text.strip():
                    error(
                        "L23C-V044",
                        "Evidence basis lacks supporting extracted text.",
                        source_id=sid,
                        competency_id=cid,
                    )

                # Verify evidence text actually exists in A4 evidence.
                matching_page = next(
                    (
                        p
                        for p in evidence_record.get(
                            "evidence_pages",
                            []
                        )
                        if isinstance(p, dict)
                        and p.get("page_number") == page_number
                    ),
                    None,
                )

                if matching_page is None:
                    error(
                        "L23C-V045",
                        "Evidence basis references a page not present in A4 evidence.",
                        source_id=sid,
                        competency_id=cid,
                        page_number=page_number,
                    )
                elif matching_page.get("text") != text:
                    error(
                        "L23C-V046",
                        "Stored supporting text does not exactly match A4 evidence.",
                        source_id=sid,
                        competency_id=cid,
                        page_number=page_number,
                    )

    if extraction_status == "NO_EXTRACTABLE_TEXT" and mappings:
        error(
            "L23C-V047",
            "NO_EXTRACTABLE_TEXT source has automatic candidates.",
            source_id=sid,
        )


# Independent summary validation
if output:
    if output.get("source_count") != len(authoritative_source_ids):
        error(
            "L23C-V048",
            "Output source_count disagrees with authoritative source-control population.",
        )

    if output.get("competency_count") != 47:
        error(
            "L23C-V049",
            "Output competency_count must equal 47.",
        )

    if output.get("candidate_count") != actual_candidate_count:
        error(
            "L23C-V050",
            "Output candidate_count disagrees with actual mappings.",
            reported=output.get("candidate_count"),
            actual=actual_candidate_count,
        )

    if output.get("pending_human_review_count") != actual_pending_count:
        error(
            "L23C-V051",
            "Pending human review count disagrees with actual mappings.",
        )

    if output.get("unmapped_source_count") != actual_unmapped_count:
        error(
            "L23C-V052",
            "Unmapped source count disagrees with actual records.",
        )


# Explicitly validate no-extractable-text population.
for sid, source in evidence_by_id.items():
    if source.get("source_extraction_status") == "NO_EXTRACTABLE_TEXT":
        record = next(
            (
                r for r in source_candidates
                if r.get("source_id") == sid
            ),
            None,
        )

        if record and record.get("candidate_mappings"):
            error(
                "L23C-V053",
                "NO_EXTRACTABLE_TEXT source must remain automatically unmapped.",
                source_id=sid,
            )


# Output serialization round trip.
if OUTPUT_PATH.exists():
    try:
        raw = OUTPUT_PATH.read_text(encoding="utf-8")
        parsed = json.loads(raw)
        round_trip = json.loads(json.dumps(parsed, ensure_ascii=False))

        if round_trip != parsed:
            error(
                "L23C-V054",
                "Generated output failed JSON round-trip validation.",
            )

    except (json.JSONDecodeError, OSError, TypeError, ValueError) as exc:
        error(
            "L23C-V055",
            "Generated output cannot be round-tripped as JSON.",
            detail=str(exc),
        )


result = "PASS" if not errors else "FAIL"

print("===== L2.3-C INDEPENDENT VALIDATOR =====")
print("Evidence sources:", len(evidence_records))
print("Authoritative generation sources:", len(authoritative_source_ids))
print("Excluded preserved sources:", len(excluded_source_ids))
print("Competencies:", len(canonical))
print("Candidates:", actual_candidate_count)
print("Unmapped sources:", actual_unmapped_count)
print("Blocking issues:", len(errors))
print("Warnings:", len(warnings))
print("VALIDATION RESULT:", result)

if errors:
    print("")
    print("===== BLOCKING ISSUES =====")
    print(json.dumps(errors, indent=2, ensure_ascii=False))

if warnings:
    print("")
    print("===== WARNINGS =====")
    print(json.dumps(warnings, indent=2, ensure_ascii=False))

raise SystemExit(0 if not errors else 1)
