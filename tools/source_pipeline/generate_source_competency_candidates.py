import json
import re
from pathlib import Path
from datetime import datetime


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


def build_signals(statement):
    """
    Conservative topic signals manually derived from the canonical
    CSP11 competency statement. Generic standalone terms are excluded.
    """
    s = normalize(statement)

    signal_map = {
        "prevention through design": [
            "prevention through design",
            "avoidance elimination substitution",
            "safety design criteria",
        ],
        "process safety": [
            "process safety",
            "pressure relief",
            "chemical compatibility",
            "management of change",
            "process flow diagrams",
        ],
        "common workplace hazards": [
            "confined spaces",
            "lockout tagout",
            "working around water",
            "caught in",
            "struck by",
            "excavation",
        ],
        "facility life safety": [
            "life safety",
            "floor loading",
            "occupancy loads",
            "public space safety",
        ],
        "fleet safety": [
            "fleet safety",
            "driver and equipment safety",
            "gps monitoring",
            "telematics",
            "hybrid vehicles",
            "fuel systems",
            "driving under the influence",
            "fatigue",
        ],
        "materials handling": [
            "materials handling",
            "powered industrial trucks",
            "aerial lifts",
            "hand trucks",
            "rigging",
            "manual handling",
        ],
        "tools machines equipment": [
            "power tools",
            "hand tools",
            "ladders",
            "grinders",
            "hydraulics",
            "robotics",
        ],
        "benchmarks gap analysis": [
            "gap analysis",
            "established benchmarks",
        ],
        "performance standards": [
            "performance standards",
            "plan of action",
        ],
        "ehs culture": [
            "ehs culture",
            "safety culture",
        ],
        "incident investigation": [
            "incident investigation",
            "root causes",
            "corrective actions",
        ],
        "management of change": [
            "management of change",
        ],
        "system safety analysis": [
            "fault tree analysis",
            "failure modes and effects analysis",
            "fmea",
            "safety case",
            "risk summation",
        ],
        "leading lagging indicators": [
            "leading indicators",
            "lagging indicators",
        ],
        "audit systems": [
            "iso 14000",
            "iso 45001",
            "iso 19011",
            "ansi z10",
            "audit systems",
        ],
        "document retention": [
            "document retention",
            "training records",
            "exposure records",
            "maintenance records",
            "audit results",
            "trade secrets",
            "personal information",
        ],
        "budgeting finance": [
            "return on investment",
            "cost benefit analysis",
            "budget development",
            "procurement process",
            "resourcing",
        ],
        "leadership techniques": [
            "leadership theories",
            "motivation",
            "discipline",
            "authority responsibility accountability",
            "communication styles",
        ],
        "project management": [
            "project management",
            "raci charts",
            "project timelines",
        ],
        "data analysis": [
            "sampling data",
            "mean median mode",
            "confidence intervals",
            "pareto analysis",
            "probabilities",
            "exposure",
            "release concentrations",
        ],
        "risk evaluation": [
            "safety risk evaluation",
            "identifying analyzing evaluating",
            "monitoring risk",
            "communicating risk",
        ],
        "risk management strategies": [
            "job hazard analysis",
            "process hazard analysis",
            "hierarchy of controls",
            "risk analysis",
        ],
        "financial risk mitigation": [
            "risk avoidance",
            "risk retention",
            "risk sharing",
            "risk transfer",
            "loss prevention",
            "loss reduction",
        ],
        "risk ranking": [
            "risk ranking",
            "emergency preparedness",
            "fire prevention",
            "hazardous materials management",
            "environmental compliance",
        ],
        "emergency response plan": [
            "emergency response plan",
            "severe weather",
            "natural disasters",
            "chemical spills",
            "utilities systems",
            "cyber security",
        ],
        "disaster response recovery": [
            "incident command",
            "business continuity",
            "contingency plans",
        ],
        "fire prevention protection suppression": [
            "fire prevention",
            "fire protection",
            "fire suppression",
        ],
        "hazardous materials transportation": [
            "transportation",
            "security of hazardous materials",
        ],
        "workplace violence": [
            "workplace violence prevention",
        ],
        "pollution prevention": [
            "pollution prevention",
            "spill containment",
            "abatement",
        ],
        "hazardous materials management": [
            "ghs classification",
            "hazardous materials",
            "storage and handling",
            "hazardous waste storage",
            "waste disposal",
        ],
        "waste management": [
            "universal waste",
            "recycling",
            "spill clean up",
            "labeling",
            "remediation",
        ],
        "sustainability": [
            "sustainability",
            "supply chain",
            "reduce reuse recycle",
        ],
        "environmental issues": [
            "aging infrastructure",
            "asbestos",
            "air pollution",
            "climate change",
            "environmental social governance",
        ],
        "occupational exposure": [
            "occupational exposures",
            "measurement sampling analysis",
            "sds",
            "radiation",
            "noise",
            "biological hazards",
            "indoor air quality",
            "ventilation",
            "nanoparticles",
            "combustible dust",
            "silica",
            "hot work",
            "cold and heat stress",
            "laser",
        ],
        "public health epidemiology": [
            "public health",
            "epidemiology",
            "infectious disease",
            "risk factors",
            "statistics",
        ],
        "toxicology": [
            "toxicology",
            "exposure control plans",
            "ld50",
            "lc50",
            "mutagens",
            "carcinogens",
            "teratogens",
            "ototoxins",
        ],
        "ergonomics human factors": [
            "ergonomics",
            "human factors",
            "visual acuity",
            "body mechanics",
            "anthropometrics",
            "fatigue management",
            "vibration",
        ],
        "chemistry containment": [
            "containment volumes",
            "hazardous materials storage requirements",
        ],
        "physics": [
            "forms of energy",
            "weights",
            "forces",
            "stresses",
        ],
        "training needs assessment": [
            "needs assessment",
            "worker training",
            "competencies and qualifications",
        ],
        "training program development": [
            "training programs",
            "training materials",
            "learning styles",
            "presentation methods",
        ],
        "continuous improvement training": [
            "continuous improvement",
            "implement training programs",
        ],
        "training effectiveness": [
            "effectiveness of training",
            "on the job compliance",
            "feedback",
            "assessments",
            "demonstrations",
            "quizzes",
        ],
        "education training methods": [
            "classroom",
            "online",
            "simulation",
            "computer based",
            "artificial intelligence",
            "coaching",
            "on the job training",
        ],
        "adult learning": [
            "adult learning",
            "visual auditory",
            "reading and writing",
            "kinesthetic",
        ],
    }

    return [
        (label, phrase)
        for label, phrases in signal_map.items()
        for phrase in phrases
        if phrase in s
    ]


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
# Conservative candidate generation
# ----------------------------------------------------------------

source_candidates = []
candidate_pairs = set()

for source in sorted(
    evidence_records,
    key=lambda x: x.get("source_id", "")
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

        text = page.get("text")

        if not isinstance(text, str) or not text.strip():
            continue

        page_records.append({
            "page_number": page.get("page_number"),
            "text": text,
            "normalized": normalize(text),
        })

    candidate_mappings = []

    for competency in competencies:
        signals = build_signals(competency["statement"])

        matched = []

        for label, phrase in signals:
            phrase_norm = normalize(phrase)

            supporting_pages = [
                page
                for page in page_records
                if contains_phrase(page["normalized"], phrase_norm)
            ]

            if supporting_pages:
                matched.append({
                    "signal": label,
                    "phrase": phrase,
                    "pages": [
                        page["page_number"]
                        for page in supporting_pages
                    ],
                    "occurrences": len(supporting_pages),
                })

        if not matched:
            continue

        # Conservative score:
        # multi-signal evidence is strongly preferred.
        distinct_signals = len(matched)
        supporting_page_count = len({
            page
            for item in matched
            for page in item["pages"]
        })

        score = (
            distinct_signals * 2.0
            + min(supporting_page_count, 5) * 0.5
        )

        # Require either:
        #   2+ independent signals
        # OR
        #   1 highly distinctive multi-word signal.
        qualifying = (
            distinct_signals >= 2
            or any(
                len(item["phrase"].split()) >= 3
                for item in matched
            )
        )

        if not qualifying:
            continue

        # Conservative threshold.
        if score < 2.5:
            continue

        evidence_basis = []

        selected_pages = sorted({
            page
            for item in matched
            for page in item["pages"]
        })

        for page_number in selected_pages[:6]:
            page = next(
                (
                    item for item in page_records
                    if item["page_number"] == page_number
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

        if distinct_signals >= 3 or score >= 6:
            confidence = "high"
        elif distinct_signals >= 2 or score >= 3.5:
            confidence = "medium"
        else:
            confidence = "low"

        matched_signals = [
            {
                "signal": item["signal"],
                "phrase": item["phrase"],
                "pages": item["pages"],
                "occurrences": item["occurrences"],
            }
            for item in matched
        ]

        rationale = (
            "Candidate generated from meaningful source-content alignment "
            f"with {distinct_signals} controlled topical signal(s) across "
            f"{supporting_page_count} evidence page(s). "
            "The mapping remains a candidate and requires human review."
        )

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

        candidate_mappings.append({
            "source_id": source_id,
            "competency_id": competency["competency_id"],
            "domain_id": competency["domain_id"],
            "mapping_status": "candidate",
            "confidence": confidence,
            "score": round(score, 3),
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
