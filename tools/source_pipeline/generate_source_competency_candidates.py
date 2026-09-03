import json
import re
from pathlib import Path
from datetime import datetime

from l23c_hardening import (
    MAX_EVIDENCE_PAGES,
    build_taxonomy,
    classify_candidate,
    competitor_analysis,
    final_score_with_competitor_adjustment,
    match_signals,
    score_candidate,
    serialize_match,
)


ROOT = Path(__file__).resolve().parents[2]

BLUEPRINT_PATH = ROOT / "docs/source_pipeline/CSP11_canonical_blueprint.json"
BLUEPRINT_VALIDATION_PATH = ROOT / "docs/source_pipeline/CSP11_canonical_blueprint_validation.json"
EVIDENCE_PATH = ROOT / "docs/source_pipeline/CSP11_source_content_evidence.json"
DECISIONS_PATH = ROOT / "docs/source_pipeline/SRC-001_to_SRC-048_bibliographic_decisions.json"
L23B_PATH = ROOT / "docs/source_pipeline/CSP11_source_to_competency_mapping.json"
OUTPUT_PATH = ROOT / "docs/source_pipeline/CSP11_source_to_competency_candidates.json"


errors = []
warnings = []


def add_error(code, message, **extra):
    item = {"code": code, "message": message}
    item.update(extra)
    errors.append(item)


def add_warning(code, message, **extra):
    item = {"code": code, "message": message}
    item.update(extra)
    warnings.append(item)


def load_json(path, code, description):
    if not path.exists():
        add_error(code, f"{description} is missing.", path=str(path))
        return {}

    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError) as exc:
        add_error(
            code,
            f"{description} could not be loaded as valid JSON.",
            path=str(path),
            detail=str(exc),
        )
        return {}


def normalize(text):
    text = text.lower()
    text = re.sub(r"[^a-z0-9]+", " ", text)
    return re.sub(r"\s+", " ", text).strip()


def contains_phrase(text, phrase):
    return phrase in text


SIGNAL_MAP = {
    'd07_c06': {
        'label': 'adult learning',
        'phrases': [
            'adult learning',
            'visual auditory',
            'reading and writing',
            'kinesthetic',
        ],
    },
    'd02_c08': {
        'label': 'audit systems',
        'phrases': [
            'iso 14000',
            'iso 45001',
            'iso 19011',
            'ansi z10',
            'audit systems',
        ],
    },
    'd02_c01': {
        'label': 'benchmarks gap analysis',
        'phrases': [
            'gap analysis',
            'established benchmarks',
        ],
    },
    'd02_c11': {
        'label': 'budgeting finance',
        'phrases': [
            'return on investment',
            'cost benefit analysis',
            'budget development',
            'procurement process',
            'resourcing',
        ],
    },
    'd06_c05': {
        'label': 'chemistry containment',
        'phrases': [
            'containment volumes',
            'hazardous materials storage requirements',
        ],
    },
    'd01_c03': {
        'label': 'common workplace hazards',
        'phrases': [
            'confined spaces',
            'lockout tagout',
            'working around water',
            'caught in',
            'struck by',
            'excavation',
        ],
    },
    'd07_c03': {
        'label': 'continuous improvement training',
        'phrases': [
            'continuous improvement',
            'implement training programs',
        ],
    },
    'd02_c14': {
        'label': 'data analysis',
        'phrases': [
            'sampling data',
            'mean median mode',
            'confidence intervals',
            'pareto analysis',
            'probabilities',
            'exposure',
            'release concentrations',
        ],
    },
    'd04_c02': {
        'label': 'disaster response recovery',
        'phrases': [
            'incident command',
            'business continuity',
            'contingency plans',
        ],
    },
    'd02_c10': {
        'label': 'document retention',
        'phrases': [
            'document retention',
            'training records',
            'exposure records',
            'maintenance records',
            'audit results',
            'trade secrets',
            'personal information',
        ],
    },
    'd07_c05': {
        'label': 'education training methods',
        'phrases': [
            'classroom',
            'online',
            'simulation',
            'computer based',
            'artificial intelligence',
            'coaching',
            'on the job training',
        ],
    },
    'd02_c03': {
        'label': 'ehs culture',
        'phrases': [
            'ehs culture',
            'safety culture',
        ],
    },
    'd04_c01': {
        'label': 'emergency response plan',
        'phrases': [
            'emergency response plan',
            'severe weather',
            'natural disasters',
            'chemical spills',
            'utilities systems',
            'cyber security',
        ],
    },
    'd05_c05': {
        'label': 'environmental issues',
        'phrases': [
            'aging infrastructure',
            'asbestos',
            'air pollution',
            'climate change',
            'environmental social governance',
        ],
    },
    'd06_c04': {
        'label': 'ergonomics human factors',
        'phrases': [
            'ergonomics',
            'human factors',
            'visual acuity',
            'body mechanics',
            'anthropometrics',
            'fatigue management',
            'vibration',
        ],
    },
    'd01_c04': {
        'label': 'facility life safety',
        'phrases': [
            'life safety',
            'floor loading',
            'occupancy loads',
            'public space safety',
        ],
    },
    'd03_c03': {
        'label': 'financial risk mitigation',
        'phrases': [
            'risk avoidance',
            'risk retention',
            'risk sharing',
            'risk transfer',
            'loss prevention',
            'loss reduction',
        ],
    },
    'd04_c03': {
        'label': 'fire prevention protection suppression',
        'phrases': [
            'fire prevention',
            'fire protection',
            'fire suppression',
        ],
    },
    'd01_c05': {
        'label': 'fleet safety',
        'phrases': [
            'fleet safety',
            'driver and equipment safety',
            'gps monitoring',
            'telematics',
            'hybrid vehicles',
            'fuel systems',
            'driving under the influence',
            'fatigue',
        ],
    },
    'd05_c02': {
        'label': 'hazardous materials management',
        'phrases': [
            'ghs classification',
            'hazardous materials',
            'storage and handling',
            'hazardous waste storage',
            'waste disposal',
        ],
    },
    'd04_c04': {
        'label': 'hazardous materials transportation',
        'phrases': [
            'transportation',
            'security of hazardous materials',
        ],
    },
    'd02_c04': {
        'label': 'incident investigation',
        'phrases': [
            'incident investigation',
            'root causes',
            'corrective actions',
        ],
    },
    'd02_c12': {
        'label': 'leadership techniques',
        'phrases': [
            'leadership theories',
            'motivation',
            'discipline',
            'authority responsibility accountability',
            'communication styles',
        ],
    },
    'd02_c07': {
        'label': 'leading lagging indicators',
        'phrases': [
            'leading indicators',
            'lagging indicators',
        ],
    },
    'd02_c05': {
        'label': 'management of change',
        'phrases': [
            'management of change',
        ],
    },
    'd01_c06': {
        'label': 'materials handling',
        'phrases': [
            'materials handling',
            'powered industrial trucks',
            'aerial lifts',
            'hand trucks',
            'rigging',
            'manual handling',
        ],
    },
    'd06_c01': {
        'label': 'occupational exposure',
        'phrases': [
            'occupational exposures',
            'measurement sampling analysis',
            'sds',
            'radiation',
            'noise',
            'biological hazards',
            'indoor air quality',
            'ventilation',
            'nanoparticles',
            'combustible dust',
            'silica',
            'hot work',
            'cold and heat stress',
            'laser',
        ],
    },
    'd02_c02': {
        'label': 'performance standards',
        'phrases': [
            'performance standards',
            'plan of action',
        ],
    },
    'd06_c06': {
        'label': 'physics',
        'phrases': [
            'forms of energy',
            'weights',
            'forces',
            'stresses',
        ],
    },
    'd05_c01': {
        'label': 'pollution prevention',
        'phrases': [
            'pollution prevention',
            'spill containment',
            'abatement',
        ],
    },
    'd01_c01': {
        'label': 'prevention through design',
        'phrases': [
            'prevention through design',
            'avoidance elimination substitution',
            'safety design criteria',
        ],
    },
    'd01_c02': {
        'label': 'process safety',
        'phrases': [
            'process safety',
            'pressure relief',
            'chemical compatibility',
            'management of change',
            'process flow diagrams',
        ],
    },
    'd02_c13': {
        'label': 'project management',
        'phrases': [
            'project management',
            'raci charts',
            'project timelines',
        ],
    },
    'd06_c02': {
        'label': 'public health epidemiology',
        'phrases': [
            'public health',
            'epidemiology',
            'infectious disease',
            'risk factors',
            'statistics',
        ],
    },
    'd03_c01': {
        'label': 'risk evaluation',
        'phrases': [
            'safety risk evaluation',
            'identifying analyzing evaluating',
            'monitoring risk',
            'communicating risk',
        ],
    },
    'd03_c02': {
        'label': 'risk management strategies',
        'phrases': [
            'job hazard analysis',
            'process hazard analysis',
            'hierarchy of controls',
            'risk analysis',
        ],
    },
    'd03_c04': {
        'label': 'risk ranking',
        'phrases': [
            'risk ranking',
            'emergency preparedness',
            'fire prevention',
            'hazardous materials management',
            'environmental compliance',
        ],
    },
    'd05_c04': {
        'label': 'sustainability',
        'phrases': [
            'sustainability',
            'supply chain',
            'reduce reuse recycle',
        ],
    },
    'd02_c06': {
        'label': 'system safety analysis',
        'phrases': [
            'fault tree analysis',
            'failure modes and effects analysis',
            'fmea',
            'safety case',
            'risk summation',
        ],
    },
    'd01_c07': {
        'label': 'tools machines equipment',
        'phrases': [
            'power tools',
            'hand tools',
            'ladders',
            'grinders',
            'hydraulics',
            'robotics',
        ],
    },
    'd06_c03': {
        'label': 'toxicology',
        'phrases': [
            'toxicology',
            'exposure control plans',
            'ld50',
            'lc50',
            'mutagens',
            'carcinogens',
            'teratogens',
            'ototoxins',
        ],
    },
    'd07_c04': {
        'label': 'training effectiveness',
        'phrases': [
            'effectiveness of training',
            'on the job compliance',
            'feedback',
            'assessments',
            'demonstrations',
            'quizzes',
        ],
    },
    'd07_c01': {
        'label': 'training needs assessment',
        'phrases': [
            'needs assessment',
            'worker training',
            'competencies and qualifications',
        ],
    },
    'd07_c02': {
        'label': 'training program development',
        'phrases': [
            'training programs',
            'training materials',
            'learning styles',
            'presentation methods',
        ],
    },
    'd05_c03': {
        'label': 'waste management',
        'phrases': [
            'universal waste',
            'recycling',
            'spill clean up',
            'labeling',
            'remediation',
        ],
    },
    'd04_c05': {
        'label': 'workplace violence',
        'phrases': [
            'workplace violence prevention',
        ],
    },
}

HARDENED_TAXONOMY = build_taxonomy(SIGNAL_MAP)



blueprint = load_json(
    BLUEPRINT_PATH,
    "L23C-E001",
    "Canonical CSP11 blueprint",
)

blueprint_validation = load_json(
    BLUEPRINT_VALIDATION_PATH,
    "L23C-E002",
    "Blueprint validation",
)

evidence = load_json(
    EVIDENCE_PATH,
    "L23C-E003",
    "Source content evidence",
)

decisions = load_json(
    DECISIONS_PATH,
    "L23C-E004",
    "Bibliographic decisions",
)

l23b = load_json(
    L23B_PATH,
    "L23C-E005",
    "L2.3-B mapping contract",
)


validation_summary = (
    blueprint_validation.get("summary", {})
    if isinstance(blueprint_validation, dict)
    else {}
)

if validation_summary.get("overall_status") != "VALID":
    add_error(
        "L23C-E006",
        "Canonical blueprint validation is not VALID.",
        status=validation_summary.get("overall_status"),
    )


domains = blueprint.get("domains", []) if isinstance(blueprint, dict) else []

if len(domains) != 7:
    add_error(
        "L23C-E007",
        "Canonical blueprint must contain exactly 7 domains.",
        actual=len(domains),
        expected=7,
    )


competencies = []

for domain in domains:
    if not isinstance(domain, dict):
        add_error("L23C-E008", "Domain record is not an object.")
        continue

    domain_id = domain.get("domain_id")

    for competency in domain.get("competencies", []):
        if not isinstance(competency, dict):
            add_error("L23C-E009", "Competency record is not an object.")
            continue

        competency_id = competency.get("competency_id")

        if not isinstance(competency_id, str):
            add_error(
                "L23C-E010",
                "Competency ID is not a string.",
                competency_id=competency_id,
            )
            continue

        if not re.fullmatch(r"d\d{2}_c\d{2}", competency_id):
            add_error(
                "L23C-E011",
                "Invalid competency ID format.",
                competency_id=competency_id,
            )

        competencies.append({
            "competency_id": competency_id,
            "domain_id": domain_id,
            "domain_name": domain.get("name"),
            "statement": competency.get("statement", ""),
        })


if len(competencies) != 47:
    add_error(
        "L23C-E012",
        "Canonical competency count must equal 47.",
        actual=len(competencies),
        expected=47,
    )


competency_by_id = {
    c["competency_id"]: c
    for c in competencies
}


evidence_records = (
    evidence.get("source_evidence", [])
    if isinstance(evidence, dict)
    else []
)

if not isinstance(evidence_records, list):
    evidence_records = []
    add_error(
        "L23C-E013",
        "source_evidence must be a list.",
    )


source_ids = [
    r.get("source_id")
    for r in evidence_records
    if isinstance(r, dict)
]

if len(source_ids) != len(set(source_ids)):
    duplicates = sorted(
        sid for sid in set(source_ids)
        if source_ids.count(sid) > 1
    )
    add_error(
        "L23C-E014",
        "Duplicate source IDs detected in A4 evidence.",
        source_ids=duplicates,
    )


# ----------------------------------------------------------------
# Controlled L2.3-C candidate generation
# ----------------------------------------------------------------

source_candidates = []
candidate_pairs = set()

for source in sorted(
    evidence_records,
    key=lambda x: x.get("source_id", ""),
):
    if not isinstance(source, dict):
        add_error("L23C-E015", "Source evidence record is not an object.")
        continue

    source_id = source.get("source_id")
    filename = source.get("filename")
    extraction_status = source.get("source_extraction_status")
    evidence_pages = source.get("evidence_pages", [])

    if extraction_status == "NO_EXTRACTABLE_TEXT":
        source_candidates.append({
            "source_id": source_id,
            "filename": filename,
            "extraction_status": extraction_status,
            "evidence_page_count": len(evidence_pages),
            "candidate_mappings": [],
            "human_review_required": True,
        })

        add_warning(
            "L23C-W001",
            "Source has no machine-readable text evidence; "
            "automatic competency generation skipped.",
            source_id=source_id,
        )
        continue

    page_records = []

    for page in evidence_pages:
        if not isinstance(page, dict):
            continue

        text_value = page.get("text")

        if not isinstance(text_value, str) or not text_value.strip():
            continue

        page_records.append({
            "page_number": page.get("page_number"),
            "text": text_value,
        })

    # ------------------------------------------------------------
    # First pass: match and score every competency.
    # Competitor analysis requires the complete deterministic
    # competency score set before candidate classification.
    # ------------------------------------------------------------

    competency_results = []

    for competency in competencies:
        matches = match_signals(
            page_records,
            HARDENED_TAXONOMY,
        )

        # Signal ownership is explicit in SignalDefinition and SignalMatch.
        competency_matches = [
            match
            for match in matches
            if match.competency_id == competency["competency_id"]
        ]

        if not competency_matches:
            continue

        scoring = score_candidate(competency_matches)

        competency_results.append({
            "competency": competency,
            "matches": competency_matches,
            "scoring": scoring,
        })

    # ------------------------------------------------------------
    # Second pass: deterministic competitor analysis and final score.
    # ------------------------------------------------------------

    scored_candidates = [
        (
            item["competency"]["competency_id"],
            item["scoring"]["raw_score"],
        )
        for item in competency_results
    ]

    scored_candidates.sort(key=lambda item: item[0])

    candidate_mappings = []

    for item in sorted(
        competency_results,
        key=lambda x: x["competency"]["competency_id"],
    ):
        competency = item["competency"]
        matches = item["matches"]
        scoring = item["scoring"]

        competitor_info = competitor_analysis(
            competency["competency_id"],
            scoring["raw_score"],
            scored_candidates,
        )

        final_score, competitor_adjustment = (
            final_score_with_competitor_adjustment(
                scoring["raw_score"],
                competitor_info,
            )
        )

        independent_signal_count = len(
            {
                match.independence_group
                for match in matches
            }
        )

        non_generic_signal_count = sum(
            1
            for match in matches
            if match.classification != "generic"
        )

        confidence = classify_candidate(
            final_score,
            independent_signal_count,
            competitor_info["stronger_competitor_count"],
            non_generic_signal_count,
        )

        if confidence is None:
            continue

        selected_pages = sorted({
            page
            for match in matches
            for page in match.pages
        })[:MAX_EVIDENCE_PAGES]

        evidence_basis = []

        for page_number in selected_pages:
            page = next(
                (
                    item_page
                    for item_page in page_records
                    if item_page["page_number"] == page_number
                ),
                None,
            )

            if page:
                evidence_basis.append({
                    "page_number": page["page_number"],
                    "supporting_text": page["text"],
                })

        if not evidence_basis:
            add_error(
                "L23C-E016",
                "Generated candidate has no evidence basis.",
                source_id=source_id,
                competency_id=competency["competency_id"],
            )
            continue

        pair = (
            source_id,
            competency["competency_id"],
        )

        if pair in candidate_pairs:
            add_error(
                "L23C-E017",
                "Duplicate source-to-competency mapping generated.",
                source_id=source_id,
                competency_id=competency["competency_id"],
            )
            continue

        candidate_pairs.add(pair)

        matched_signals = [
            serialize_match(match)
            for match in matches
        ]

        rationale = (
            "Candidate generated from controlled L2.3-C signal alignment. "
            f"Raw score {scoring['raw_score']:.3f}; "
            f"competitor adjustment {competitor_adjustment:.3f}; "
            f"final score {final_score:.3f}. "
            f"{len(matches)} hardened signal match(es) across "
             f"{len(selected_pages)} "
            "evidence page(s). "
            "The mapping remains a candidate and requires human review."
        )

        candidate_mappings.append({
            "source_id": source_id,
            "competency_id": competency["competency_id"],
            "domain_id": competency["domain_id"],
            "mapping_status": "candidate",
            "confidence": confidence,
            "score": final_score,
            "matched_signals": matched_signals,
            "evidence_basis": evidence_basis,
            "rationale": rationale,
            "human_review_required": True,
        })

    candidate_mappings.sort(
        key=lambda x: x["competency_id"]
    )

    if not candidate_mappings:
        add_warning(
            "L23C-W002",
            "No conservative competency candidate generated for source.",
            source_id=source_id,
        )

    source_candidates.append({
        "source_id": source_id,
        "filename": filename,
        "extraction_status": extraction_status,
        "evidence_page_count": len(evidence_pages),
        "candidate_mappings": candidate_mappings,
        "human_review_required": True,
    })


candidate_count = sum(
    len(record["candidate_mappings"])
    for record in source_candidates
)

unmapped_source_count = sum(
    1
    for record in source_candidates
    if not record["candidate_mappings"]
)


# Validate generated candidates internally.
for source in source_candidates:
    for mapping in source["candidate_mappings"]:

        if mapping["mapping_status"] == "confirmed":
            add_error(
                "L23C-E018",
                "Confirmed mapping detected in L2.3-C output.",
                source_id=source["source_id"],
                competency_id=mapping["competency_id"],
            )

        if mapping["competency_id"] not in competency_by_id:
            add_error(
                "L23C-E019",
                "Generated mapping references unknown competency.",
                source_id=source["source_id"],
                competency_id=mapping["competency_id"],
            )

        if not mapping.get("evidence_basis"):
            add_error(
                "L23C-E020",
                "Generated mapping is missing evidence_basis.",
                source_id=source["source_id"],
                competency_id=mapping["competency_id"],
            )

        for evidence_item in mapping.get("evidence_basis", []):
            if "page_number" not in evidence_item:
                add_error(
                    "L23C-E021",
                    "Evidence basis is missing page number.",
                    source_id=source["source_id"],
                    competency_id=mapping["competency_id"],
                )

            if not isinstance(
                evidence_item.get("supporting_text"),
                str
            ) or not evidence_item["supporting_text"].strip():
                add_error(
                    "L23C-E022",
                    "Evidence basis is missing supporting text.",
                    source_id=source["source_id"],
                    competency_id=mapping["competency_id"],
                )


overall_status = "INVALID" if errors else "VALID"

output = {
    "pipeline": "CSP11 Source-to-Domain Knowledge Pipeline",
    "stage": "L2.3-C Evidence-Based Source-to-Competency Candidate Generation",
    "generated_at": datetime.now().isoformat(timespec="seconds"),
    "schema_version": "L2.3-C.1",

    "input_references": {
        "canonical_blueprint": str(
            BLUEPRINT_PATH.relative_to(ROOT)
        ),
        "blueprint_validation": str(
            BLUEPRINT_VALIDATION_PATH.relative_to(ROOT)
        ),
        "source_content_evidence": str(
            EVIDENCE_PATH.relative_to(ROOT)
        ),
        "bibliographic_decisions": str(
            DECISIONS_PATH.relative_to(ROOT)
        ),
        "l23b_mapping_contract": str(
            L23B_PATH.relative_to(ROOT)
        ),
    },

    "mapping_policy": {
        "canonical_blueprint_is_authoritative": True,
        "source_content_evidence_is_substantive_basis": True,
        "bibliographic_metadata_is_not_competency_evidence": True,
        "conservative_candidate_generation": True,
        "single_generic_keyword_is_insufficient": True,
        "no_automatic_confirmation": True,
        "human_review_required": True,
        "no_competency_creation": True,
        "no_automatic_reclassification": True,
        "no_padding": True,
        "no_extractable_text_sources_are_not_mapped": True,
        "candidate_status_only": True,
        "default_mapping_status": "candidate",
    },

    "source_count": len(source_candidates),
    "competency_count": len(competencies),
    "candidate_count": candidate_count,
    "pending_human_review_count": candidate_count,
    "unmapped_source_count": unmapped_source_count,

    "source_candidates": source_candidates,

    "summary": {
        "overall_status": overall_status,
        "source_count": len(source_candidates),
        "competency_count": len(competencies),
        "candidate_count": candidate_count,
        "pending_human_review_count": candidate_count,
        "unmapped_source_count": unmapped_source_count,
        "blocking_issues": len(errors),
        "warnings": len(warnings),
    },

    "issues": errors,
    "warnings": warnings,
}


OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)

try:
    serialized = json.dumps(
        output,
        indent=2,
        ensure_ascii=False,
    )
    round_trip = json.loads(serialized)

    if round_trip != output:
        add_error(
            "L23C-E023",
            "Output JSON failed serialization round-trip validation.",
        )

except (TypeError, ValueError) as exc:
    add_error(
        "L23C-E023",
        "Output JSON failed serialization.",
        detail=str(exc),
    )


output["summary"]["overall_status"] = (
    "INVALID" if errors else "VALID"
)
output["summary"]["blocking_issues"] = len(errors)
output["summary"]["warnings"] = len(warnings)
output["issues"] = errors
output["warnings"] = warnings

OUTPUT_PATH.write_text(
    json.dumps(
        output,
        indent=2,
        ensure_ascii=False,
    ) + "\n",
    encoding="utf-8",
    newline="\n",
)

print("===== L2.3-C GENERATOR =====")
print("Sources:", len(source_candidates))
print("Competencies:", len(competencies))
print("Candidates:", candidate_count)
print("Unmapped sources:", unmapped_source_count)
print("Blocking issues:", len(errors))
print("Warnings:", len(warnings))
print("OVERALL STATUS:", "INVALID" if errors else "VALID")
print("Output:", OUTPUT_PATH)
