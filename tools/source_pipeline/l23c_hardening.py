"""
L2.3-C Controlled Signal-Taxonomy Hardening Engine

Deterministic, rule-based implementation for the frozen L2.3-C pipeline.

No network, LLM, embeddings, randomness, probabilistic model,
or external dependency is used.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Dict, List, Sequence, Tuple


# ================================================================
# DETERMINISTIC CONFIGURATION
# ================================================================

SIGNAL_CLASS_GENERIC = "generic"
SIGNAL_CLASS_CONTEXTUAL = "contextual"
SIGNAL_CLASS_DISTINCTIVE = "distinctive"

SPECIFICITY_WEIGHTS = {
    SIGNAL_CLASS_GENERIC: 0.50,
    SIGNAL_CLASS_CONTEXTUAL: 1.00,
    SIGNAL_CLASS_DISTINCTIVE: 1.75,
}

MIN_CANDIDATE_SCORE = 2.50
MEDIUM_CONFIDENCE_SCORE = 3.50
HIGH_CONFIDENCE_SCORE = 6.00

MIN_INDEPENDENT_SIGNALS = 2

VERY_CLOSE_TOKEN_DISTANCE = 12
CLOSE_TOKEN_DISTANCE = 30

MATERIAL_COMPETITOR_MARGIN = 1.50
COMPETITOR_SCORE_PENALTY = 0.50
MAX_COMPETITOR_PENALTY = 1.50

MAX_EVIDENCE_PAGES = 6


# ================================================================
# GENERIC SIGNAL TAXONOMY
# ================================================================

GENERIC_SIGNAL_PHRASES = {
    "exposure",
    "fire prevention",
    "hazardous materials",
    "training programs",
    "management of change",
    "risk analysis",
    "statistics",
    "forces",
    "stresses",
}


# ================================================================
# NEGATIVE CONTEXT
# ================================================================

NEGATIVE_SINGLE_WORDS = {
    "not",
    "no",
    "without",
    "excluded",
    "exclude",
    "excluding",
    "outside",
}

NEGATIVE_PHRASES = (
    ("unrelated", "to"),
    ("not", "related", "to"),
    ("does", "not", "involve"),
    ("does", "not", "include"),
    ("rather", "than"),
    ("instead", "of"),
)

# Deterministic post-signal negation patterns.
NEGATION_FOLLOWING = (
    ("not",),
    ("never",),
    ("rarely",),
)

NEGATIVE_WINDOW = 6


# ================================================================
# DATA STRUCTURES
# ================================================================

@dataclass(frozen=True)
class SignalDefinition:
    signal_id: str
    competency_id: str
    label: str
    phrase: str
    classification: str
    specificity_weight: float
    independence_group: str
    hierarchy_parent: str | None = None
    aliases: Tuple[str, ...] = ()


@dataclass(frozen=True)
class SignalMatch:
    signal_id: str
    competency_id: str
    label: str
    phrase: str
    classification: str
    specificity_weight: float
    independence_group: str
    hierarchy_parent: str | None
    hierarchy_role: str
    hierarchy_collapsed: bool
    negative_context: bool
    pages: Tuple[int, ...]
    occurrences: int
    positions: Tuple[int, ...]
    page_positions: Tuple[Tuple[int, int], ...] = ()
    proximity: float = 0.0


# ================================================================
# NORMALIZATION
# ================================================================

def normalize_text(text: str) -> str:
    if not isinstance(text, str):
        return ""

    text = text.lower()
    text = re.sub(r"[^a-z0-9]+", " ", text)
    return re.sub(r"\s+", " ", text).strip()


def tokenize(text: str) -> List[str]:
    return normalize_text(text).split()


def phrase_tokens(phrase: str) -> List[str]:
    return normalize_text(phrase).split()


# ================================================================
# TOKEN-AWARE MATCHING
# ================================================================

def token_aware_positions(text: str, phrase: str) -> List[int]:
    """
    Return token indexes where the complete phrase occurs.

    Raw substring matching is deliberately prohibited.
    """

    tokens = tokenize(text)
    target = phrase_tokens(phrase)

    if not target or len(target) > len(tokens):
        return []

    width = len(target)
    positions: List[int] = []

    for index in range(len(tokens) - width + 1):
        if tokens[index:index + width] == target:
            positions.append(index)

    return positions


def token_aware_match(text: str, phrase: str) -> bool:
    return bool(token_aware_positions(text, phrase))


# ================================================================
# SIGNAL CLASSIFICATION
# ================================================================

BROAD_CONTEXTUAL_LABELS = {
    "process safety",
    "common workplace hazards",
    "fleet safety",
    "materials handling",
    "tools machines equipment",
    "performance standards",
    "ehs culture",
    "leadership techniques",
    "project management",
    "data analysis",
    "risk evaluation",
    "risk ranking",
    "sustainability",
    "physics",
    "training needs assessment",
    "training program development",
    "training effectiveness",
    "education training methods",
    "adult learning",
}


def classify_signal(label: str, phrase: str) -> str:
    normalized = normalize_text(phrase)

    if normalized in GENERIC_SIGNAL_PHRASES:
        return SIGNAL_CLASS_GENERIC

    if len(normalized.split()) >= 3:
        return SIGNAL_CLASS_DISTINCTIVE

    if label in BROAD_CONTEXTUAL_LABELS:
        return SIGNAL_CLASS_CONTEXTUAL

    return SIGNAL_CLASS_CONTEXTUAL


# ================================================================
# SIGNAL INDEPENDENCE
# ================================================================

# H1.1 STEP 2.4: PHRASE-LEVEL INDEPENDENCE HARDENING
#
# Independence is scoped to a competency and assigned at phrase level.
# An explicitly assigned phrase belongs to a controlled evidence family.
# An unassigned phrase receives the competency-level default group and
# contributes to specificity, but it does not count as an independent
# evidence family. This prevents phrase volume or a broad competency label
# from masquerading as independent evidence.
#
# The registry is keyed by (competency_id, phrase), so a phrase reused in
# another competency cannot silently inherit an independence family.
# Closely related phrases deliberately share a family. Only clearly
# different evidence dimensions receive separate families.
PHRASE_INDEPENDENCE_FAMILIES = {
    ("d01_c03", "confined spaces"): "confined_space",
    ("d01_c03", "lockout tagout"): "hazardous_energy",
    ("d01_c03", "working around water"): "water_hazards",
    ("d01_c03", "caught in"): "mechanical_contact",
    ("d01_c03", "struck by"): "mechanical_contact",
    ("d01_c03", "excavation"): "excavation",

    ("d01_c05", "gps monitoring"): "fleet_monitoring",
    ("d01_c05", "telematics"): "fleet_monitoring",
    ("d01_c05", "hybrid vehicles"): "vehicle_systems",
    ("d01_c05", "fuel systems"): "vehicle_systems",
    ("d01_c05", "driving under the influence"): "driver_factors",
    ("d01_c05", "fatigue"): "driver_factors",

    ("d01_c06", "powered industrial trucks"): "powered_equipment",
    ("d01_c06", "aerial lifts"): "powered_equipment",
    ("d01_c06", "hand trucks"): "manual_equipment",
    ("d01_c06", "manual handling"): "manual_handling",
    ("d01_c06", "rigging"): "rigging",

    ("d01_c07", "power tools"): "tools",
    ("d01_c07", "hand tools"): "tools",
    ("d01_c07", "grinders"): "tools",
    ("d01_c07", "ladders"): "access_equipment",
    ("d01_c07", "hydraulics"): "equipment_systems",
    ("d01_c07", "robotics"): "automation_systems",

    ("d02_c04", "incident investigation"): "investigation_process",
    ("d02_c04", "root causes"): "causal_analysis",
    ("d02_c04", "corrective actions"): "corrective_action",

    ("d02_c14", "sampling data"): "data_collection",
    ("d02_c14", "mean median mode"): "descriptive_statistics",
    ("d02_c14", "confidence intervals"): "inferential_statistics",
    ("d02_c14", "pareto analysis"): "analytical_methods",
    ("d02_c14", "probabilities"): "probability_methods",
    ("d02_c14", "exposure"): "exposure_data",
    ("d02_c14", "release concentrations"): "exposure_data",

    ("d03_c02", "job hazard analysis"): "hazard_analysis_methods",
    ("d03_c02", "process hazard analysis"): "hazard_analysis_methods",
    ("d03_c02", "hierarchy of controls"): "control_framework",
    ("d03_c02", "risk analysis"): "risk_analysis_methods",

    ("d03_c03", "risk avoidance"): "risk_strategy",
    ("d03_c03", "risk retention"): "risk_strategy",
    ("d03_c03", "risk sharing"): "risk_strategy",
    ("d03_c03", "risk transfer"): "risk_strategy",
    ("d03_c03", "loss prevention"): "loss_control",
    ("d03_c03", "loss reduction"): "loss_control",

    ("d04_c01", "severe weather"): "natural_hazards",
    ("d04_c01", "natural disasters"): "natural_hazards",
    ("d04_c01", "chemical spills"): "hazardous_release",
    ("d04_c01", "utilities systems"): "critical_utilities",
    ("d04_c01", "cyber security"): "cyber_response",

    ("d06_c01", "measurement sampling analysis"): "exposure_assessment",
    ("d06_c01", "sds"): "chemical_information",
    ("d06_c01", "radiation"): "physical_agents",
    ("d06_c01", "noise"): "physical_agents",
    ("d06_c01", "biological hazards"): "biological_hazards",
    ("d06_c01", "indoor air quality"): "indoor_air",
    ("d06_c01", "ventilation"): "indoor_air",
    ("d06_c01", "nanoparticles"): "particulates",
    ("d06_c01", "combustible dust"): "particulates",
    ("d06_c01", "silica"): "particulates",
    ("d06_c01", "hot work"): "thermal_hazards",
    ("d06_c01", "cold and heat stress"): "thermal_hazards",
    ("d06_c01", "laser"): "physical_agents",

    ("d06_c03", "exposure control plans"): "exposure_controls",
    ("d06_c03", "ld50"): "toxicity_metrics",
    ("d06_c03", "lc50"): "toxicity_metrics",
    ("d06_c03", "mutagens"): "toxic_endpoints",
    ("d06_c03", "carcinogens"): "toxic_endpoints",
    ("d06_c03", "teratogens"): "toxic_endpoints",
    ("d06_c03", "ototoxins"): "toxic_endpoints",

    ("d06_c04", "visual acuity"): "visual_factors",
    ("d06_c04", "body mechanics"): "biomechanics",
    ("d06_c04", "anthropometrics"): "biomechanics",
    ("d06_c04", "fatigue management"): "fatigue",
    ("d06_c04", "vibration"): "physical_exposure",

    ("d07_c04", "effectiveness of training"): "effectiveness_outcome",
    ("d07_c04", "on the job compliance"): "workplace_application",
    ("d07_c04", "feedback"): "feedback",
    ("d07_c04", "assessments"): "assessment_methods",
    ("d07_c04", "demonstrations"): "assessment_methods",
    ("d07_c04", "quizzes"): "assessment_methods",

    ("d07_c05", "classroom"): "delivery_modes",
    ("d07_c05", "online"): "delivery_modes",
    ("d07_c05", "simulation"): "experiential_methods",
    ("d07_c05", "computer based"): "technology_methods",
    ("d07_c05", "artificial intelligence"): "technology_methods",
    ("d07_c05", "coaching"): "workplace_methods",
    ("d07_c05", "on the job training"): "workplace_methods",
}


def phrase_independence_group(
    competency_id: str,
    label: str,
    phrase: str,
) -> str:
    normalized_phrase = normalize_text(phrase)
    family = PHRASE_INDEPENDENCE_FAMILIES.get(
        (competency_id, normalized_phrase)
    )

    if family is None:
        return f"{competency_id}::default"

    normalized_family = normalize_text(family).replace(" ", "_")
    return f"{competency_id}::{normalized_family}"


def validate_phrase_independence_registry(
    signal_map: Dict[str, Dict],
    *,
    strict: bool = False,
) -> None:
    known_phrases = {
        (competency_id, normalize_text(phrase))
        for competency_id, entry in signal_map.items()
        if isinstance(entry, dict)
        for phrase in entry.get("phrases", [])
    }

    for key, family in PHRASE_INDEPENDENCE_FAMILIES.items():
        if not isinstance(key, tuple) or len(key) != 2:
            raise TypeError(
                "Phrase independence registry keys must be "
                "(competency_id, phrase) tuples."
            )

        competency_id, phrase = key
        if competency_id not in signal_map:
            if strict:
                raise ValueError(
                    f"Phrase independence registry references unknown competency "
                    f"{competency_id!r}."
                )
            continue

        if (competency_id, normalize_text(phrase)) not in known_phrases:
            raise ValueError(
                f"Phrase independence registry references phrase {phrase!r} "
                f"not present under {competency_id!r}."
            )

        if not isinstance(family, str) or not normalize_text(family):
            raise ValueError(
                f"Phrase independence family for {competency_id!r} / "
                f"{phrase!r} must be a non-empty string."
            )


# ================================================================
# TAXONOMY CONSTRUCTION
# ================================================================

def build_taxonomy(
    signal_map: Dict[str, Dict],
) -> List[SignalDefinition]:
    """Build deterministic signal definitions with explicit ownership."""

    definitions: List[SignalDefinition] = []

    validate_phrase_independence_registry(signal_map)

    for competency_id in sorted(signal_map):
        entry = signal_map[competency_id]

        if not isinstance(entry, dict):
            raise TypeError(
                f"Signal registry entry for {competency_id!r} must be a mapping."
            )

        label = entry.get("label")
        phrases = entry.get("phrases", [])

        if not isinstance(label, str):
            raise TypeError(
                f"Signal registry label for {competency_id!r} must be a string."
            )

        if not isinstance(phrases, Sequence) or isinstance(phrases, (str, bytes)):
            raise TypeError(
                f"Signal registry phrases for {competency_id!r} must be a sequence."
            )

        for index, phrase in enumerate(phrases, 1):
            normalized_phrase = normalize_text(phrase)

            if not normalized_phrase:
                continue

            classification = classify_signal(
                label,
                normalized_phrase,
            )

            signal_id = (
                f"{competency_id}__"
                f"{re.sub(r'[^a-z0-9]+', '_', label.lower()).strip('_')}"
                f"__{index:02d}"
            )

            definitions.append(
                SignalDefinition(
                    signal_id=signal_id,
                    competency_id=competency_id,
                    label=label,
                    phrase=normalized_phrase,
                    classification=classification,
                    specificity_weight=SPECIFICITY_WEIGHTS[
                        classification
                    ],
                    independence_group=phrase_independence_group(
                        competency_id,
                        label,
                        normalized_phrase,
                    ),
                )
            )

    return definitions


# ================================================================
# PHRASE HIERARCHY
# ================================================================

EXPLICIT_ALIAS_GROUPS = (
    frozenset({
        "failure modes and effects analysis",
        "fmea",
    }),
)


def hierarchy_group(phrase: str) -> frozenset[str] | None:
    normalized = normalize_text(phrase)

    for group in EXPLICIT_ALIAS_GROUPS:
        if normalized in group:
            return group

    return None


def collapse_hierarchy(
    matches: Sequence[SignalMatch],
) -> List[SignalMatch]:

    result: List[SignalMatch] = []
    processed_groups = set()

    for current in matches:

        group = hierarchy_group(current.phrase)

        if group is None:
            result.append(current)
            continue

        if group in processed_groups:
            continue

        processed_groups.add(group)

        related = [
            item
            for item in matches
            if normalize_text(item.phrase) in group
        ]

        winner = sorted(
            related,
            key=lambda item: (
                -len(phrase_tokens(item.phrase)),
                -item.specificity_weight,
                item.phrase,
                item.signal_id,
            ),
        )[0]

        result.append(
            SignalMatch(
                signal_id=winner.signal_id,
                competency_id=winner.competency_id,
                label=winner.label,
                phrase=winner.phrase,
                classification=winner.classification,
                specificity_weight=winner.specificity_weight,
                independence_group=winner.independence_group,
                hierarchy_parent=winner.hierarchy_parent,
                hierarchy_role="specific",
                hierarchy_collapsed=True,
                negative_context=winner.negative_context,
                pages=winner.pages,
                occurrences=winner.occurrences,
                positions=winner.positions,
                page_positions=winner.page_positions,
                proximity=winner.proximity,
            )
        )

    return result


# ================================================================
# NEGATIVE CONTEXT
# ================================================================

def _matches_suffix(
    tokens: Sequence[str],
    position: int,
    pattern: Sequence[str],
) -> bool:

    if position < len(pattern):
        return False

    return list(tokens[position - len(pattern):position]) == list(pattern)


def _matches_prefix(
    tokens: Sequence[str],
    end_position: int,
    pattern: Sequence[str],
) -> bool:

    end = end_position + len(pattern)

    if end > len(tokens):
        return False

    return list(tokens[end_position:end]) == list(pattern)


def has_negative_context(
    text: str,
    phrase: str,
    token_position: int,
    window: int = NEGATIVE_WINDOW,
) -> bool:

    tokens = tokenize(text)
    target = phrase_tokens(phrase)

    if not target:
        return False

    phrase_end = token_position + len(target)

    start = max(0, token_position - window)
    before = tokens[start:token_position]

    # Negative wording immediately before the signal.
    for word in NEGATIVE_SINGLE_WORDS:
        if before and before[-1] == word:
            return True

    for pattern in NEGATIVE_PHRASES:
        if _matches_suffix(
            tokens,
            token_position,
            pattern,
        ):
            return True

    # Controlled negative constructions occurring immediately before
    # the signal, such as "does not discuss X" or "does not include X".
    preceding_negative_constructions = (
        ("does", "not", "discuss"),
        ("does", "not", "involve"),
        ("does", "not", "include"),
        ("does", "not", "address"),
        ("does", "not", "cover"),
        ("does", "not", "consider"),
        ("does", "not", "examine"),
        ("does", "not", "assess"),
        ("does", "not", "concern"),
        ("did", "not", "discuss"),
        ("did", "not", "involve"),
        ("did", "not", "include"),
        ("did", "not", "address"),
        ("did", "not", "cover"),
        ("did", "not", "consider"),
        ("did", "not", "examine"),
        ("did", "not", "assess"),
        ("did", "not", "concern"),
    )

    for pattern in preceding_negative_constructions:
        if _matches_suffix(
            tokens,
            token_position,
            pattern,
        ):
            return True

    # Negative wording immediately after the signal.
    after_end = min(
        len(tokens),
        phrase_end + window,
    )
    after = tokens[phrase_end:after_end]

    for pattern in NEGATION_FOLLOWING:
        if after[:len(pattern)] == list(pattern):
            return True

    # Handle common constructions such as:
    # "management of change was not required"
    # "fire prevention is not applicable"
    following_negative_patterns = (
        ("was", "not"),
        ("is", "not"),
        ("are", "not"),
        ("were", "not"),
        ("does", "not"),
        ("did", "not"),
        ("not", "required"),
        ("not", "applicable"),
        ("not", "relevant"),
        ("not", "involved"),
        ("not", "included"),
    )

    for pattern in following_negative_patterns:
        for index in range(
            0,
            max(0, len(after) - len(pattern) + 1),
        ):
            if after[index:index + len(pattern)] == list(pattern):
                return True

    # Explicit unrelated-context constructions.
    context_window = (
        before
        + target
        + after
    )

    for index in range(
        max(0, len(context_window) - window),
        len(context_window),
    ):
        for pattern in NEGATIVE_PHRASES:
            if (
                context_window[index:index + len(pattern)]
                == list(pattern)
            ):
                return True

    return False


# ================================================================
# PROXIMITY
# ================================================================

def proximity_score(
    positions: Sequence[int],
) -> float:

    if not positions:
        return 0.0

    if len(positions) == 1:
        return 1.0

    ordered = sorted(positions)

    distances = [
        ordered[index + 1] - ordered[index]
        for index in range(len(ordered) - 1)
    ]

    minimum_distance = min(distances)

    if minimum_distance <= VERY_CLOSE_TOKEN_DISTANCE:
        return 1.25

    if minimum_distance <= CLOSE_TOKEN_DISTANCE:
        return 1.00

    return 0.75


def canonical_page_positions(
    page_positions: Sequence[Tuple[int, int]],
) -> Tuple[Tuple[int, int], ...]:
    """Return deterministic unique page-position evidence occurrences.

    A physical evidence occurrence is identified by its page number and
    token position. Duplicate coordinates represent the same occurrence
    and therefore collapse to one canonical entry.
    """
    normalized = {
        (page_number, position)
        for page_number, position in page_positions
        if isinstance(page_number, int) and isinstance(position, int)
    }

    return tuple(sorted(normalized))


def page_aware_proximity_score(
    page_positions: Sequence[Tuple[int, int]],
) -> float:
    """Return deterministic proximity for occurrences on one or more pages.

    Token positions are comparable only within the same page. Evidence on
    different pages must not become artificially close because their token
    offsets happen to have similar numeric values.
    """

    if not page_positions:
        return 0.0

    by_page: Dict[int, List[int]] = {}

    for page_number, position in page_positions:
        by_page.setdefault(page_number, []).append(position)

    if not by_page:
        return 0.0

    page_scores: List[float] = []

    for page_number in sorted(by_page):
        positions = sorted(by_page[page_number])

        if len(positions) == 1:
            page_scores.append(1.0)
            continue

        distances = [
            positions[index + 1] - positions[index]
            for index in range(len(positions) - 1)
        ]

        minimum_distance = min(distances)

        if minimum_distance <= VERY_CLOSE_TOKEN_DISTANCE:
            page_scores.append(1.25)
        elif minimum_distance <= CLOSE_TOKEN_DISTANCE:
            page_scores.append(1.00)
        else:
            page_scores.append(0.75)

    return round(
        sum(page_scores) / len(page_scores),
        3,
    )


def evidence_proximity(
    matches: Sequence[SignalMatch],
) -> float:

    if len(matches) < 2:
        return 0.0

    scores: List[float] = []

    for index, first in enumerate(matches):
        for second in matches[index + 1:]:

            common_pages = set(first.pages).intersection(
                second.pages
            )

            if not common_pages:
                scores.append(0.25)
                continue

            common_page_positions = []
            shared_physical_occurrence = False

            for page_number in sorted(common_pages):
                first_positions = [
                    position
                    for page, position in first.page_positions
                    if page == page_number
                ]
                second_positions = [
                    position
                    for page, position in second.page_positions
                    if page == page_number
                ]

                if not first_positions or not second_positions:
                    continue

                if set(first_positions).intersection(second_positions):
                    shared_physical_occurrence = True

                distinct_distances = [
                    abs(first_position - second_position)
                    for first_position in first_positions
                    for second_position in second_positions
                    if first_position != second_position
                ]

                if distinct_distances:
                    common_page_positions.append(min(distinct_distances))

            if not common_page_positions:
                if shared_physical_occurrence:
                    continue
                scores.append(0.75)
                continue

            distance = min(common_page_positions)

            if distance <= VERY_CLOSE_TOKEN_DISTANCE:
                scores.append(1.25)
            elif distance <= CLOSE_TOKEN_DISTANCE:
                scores.append(1.00)
            else:
                scores.append(0.75)

    if not scores:
        return 0.0

    return round(
        sum(scores) / len(scores),
        3,
    )

def match_signals(
    page_records: Sequence[Dict],
    definitions: Sequence[SignalDefinition],
) -> List[SignalMatch]:

    matches: List[SignalMatch] = []

    for definition in definitions:

        pages: List[int] = []
        positions: List[int] = []
        page_positions: List[Tuple[int, int]] = []
        positive_occurrences = 0

        for page in page_records:

            text = page.get("text", "")
            page_number = page.get("page_number")

            if not isinstance(text, str):
                continue

            raw_positions = token_aware_positions(
                text,
                definition.phrase,
            )

            if not raw_positions:
                continue

            positive_positions = [
                position
                for position in raw_positions
                if not has_negative_context(
                    text,
                    definition.phrase,
                    position,
                )
            ]

            if not positive_positions:
                continue

            pages.append(page_number)

            for position in positive_positions:
                positions.append(position)
                page_positions.append(
                    (page_number, position)
                )

            positive_occurrences += len(
                positive_positions
            )

        if not pages:
            continue

        canonical_positions = canonical_page_positions(
            page_positions
        )

        matches.append(
            SignalMatch(
                signal_id=definition.signal_id,
                competency_id=definition.competency_id,
                label=definition.label,
                phrase=definition.phrase,
                classification=definition.classification,
                specificity_weight=definition.specificity_weight,
                independence_group=definition.independence_group,
                hierarchy_parent=definition.hierarchy_parent,
                hierarchy_role="primary",
                hierarchy_collapsed=False,
                negative_context=False,
                pages=tuple(sorted({
                    page_number
                    for page_number, _ in canonical_positions
                })),
                occurrences=len(canonical_positions),
                positions=tuple(
                    position
                    for _, position in canonical_positions
                ),
                page_positions=canonical_positions,
                proximity=page_aware_proximity_score(
                    canonical_positions
                ),
            )
        )

    return collapse_hierarchy(matches)


# ================================================================
# INDEPENDENCE
# ================================================================

def independent_groups(
    matches: Sequence[SignalMatch],
) -> Dict[str, List[SignalMatch]]:

    groups: Dict[str, List[SignalMatch]] = {}

    for match in matches:
        groups.setdefault(
            match.independence_group,
            [],
        ).append(match)

    return groups


def count_independent_groups(
    matches: Sequence[SignalMatch],
) -> int:
    """Return the number of unique non-default evidence groups."""

    return sum(
        1
        for group_id in independent_groups(matches)
        if not group_id.endswith("::default")
    )


# ================================================================
# SCORING
# ================================================================

def score_candidate(
    matches: Sequence[SignalMatch],
) -> Dict:

    groups = independent_groups(matches)

    specificity_score = sum(
        max(
            item.specificity_weight
            for item in group
        )
        for group in groups.values()
    )

    independent_group_count = count_independent_groups(matches)

    independence_score = min(
        independent_group_count * 1.00,
        4.00,
    )

    proximity = evidence_proximity(matches)

    supporting_pages = sorted({
        page
        for item in matches
        for page in item.pages
    })

    page_support_score = min(
        len(supporting_pages),
        5,
    ) * 0.25

    raw_score = (
        specificity_score
        + independence_score
        + proximity
        + page_support_score
    )

    return {
        "specificity_score": round(
            specificity_score,
            3,
        ),
        "independence_score": round(
            independence_score,
            3,
        ),
        "proximity_score": round(
            proximity,
            3,
        ),
        "page_support_score": round(
            page_support_score,
            3,
        ),
        "raw_score": round(
            raw_score,
            3,
        ),
    }


# ================================================================
# COMPETITOR DETECTION
# ================================================================

def competitor_analysis(
    competency_id: str,
    score: float,
    scored_candidates: Sequence[Tuple[str, float]],
) -> Dict:

    competitors = [
        (cid, other_score)
        for cid, other_score in scored_candidates
        if cid != competency_id
    ]

    stronger = [
        (cid, other_score)
        for cid, other_score in competitors
        if other_score >= (
            score + MATERIAL_COMPETITOR_MARGIN
        )
    ]

    ordered = sorted(
        competitors,
        key=lambda item: (
            -item[1],
            item[0],
        ),
    )

    if ordered:
        strongest_id, strongest_score = ordered[0]
        margin = round(
            score - strongest_score,
            3,
        )
    else:
        strongest_id = None
        strongest_score = None
        margin = None

    return {
        "competitor_count": len(competitors),
        "stronger_competitor_count": len(stronger),
        "strongest_competitor_competency_id": strongest_id,
        "strongest_competitor_score": (
            round(
                strongest_score,
                3,
            )
            if strongest_score is not None
            else None
        ),
        "score_margin": margin,
        "material_competitor_margin": (
            MATERIAL_COMPETITOR_MARGIN
        ),
    }


def final_score_with_competitor_adjustment(
    raw_score: float,
    competitor_info: Dict,
) -> Tuple[float, float]:

    stronger_count = int(
        competitor_info.get(
            "stronger_competitor_count",
            0,
        )
    )

    adjustment = min(
        stronger_count * COMPETITOR_SCORE_PENALTY,
        MAX_COMPETITOR_PENALTY,
    )

    return (
        round(
            raw_score - adjustment,
            3,
        ),
        round(
            -adjustment,
            3,
        ),
    )


# ================================================================
# CLASSIFICATION
# ================================================================

MIN_NON_GENERIC_SIGNALS = 1


def classify_candidate(
    final_score: float,
    independent_signal_count: int,
    stronger_competitor_count: int,
    non_generic_signal_count: int,
) -> str | None:

    if final_score < MIN_CANDIDATE_SCORE:
        return None

    if independent_signal_count < MIN_INDEPENDENT_SIGNALS:
        return None

    if non_generic_signal_count < MIN_NON_GENERIC_SIGNALS:
        return None

    if (
        independent_signal_count >= 3
        and final_score >= HIGH_CONFIDENCE_SCORE
        and stronger_competitor_count == 0
    ):
        return "high"

    if final_score >= MEDIUM_CONFIDENCE_SCORE:
        return "medium"

    return "low"


# ================================================================
# SERIALIZATION
# ================================================================

def serialize_match(
    match: SignalMatch,
) -> Dict:

    return {
        "signal_id": match.signal_id,
        "competency_id": match.competency_id,
        "signal": match.label,
        "phrase": match.phrase,
        "classification": match.classification,
        "specificity_weight": match.specificity_weight,
        "independence_group": match.independence_group,
        "hierarchy_parent": match.hierarchy_parent,
        "hierarchy_role": match.hierarchy_role,
        "hierarchy_collapsed": match.hierarchy_collapsed,
        "negative_context": match.negative_context,
        "pages": list(match.pages),
        "occurrences": match.occurrences,
        "positions": list(match.positions),
        "page_positions": [
            {
                "page_number": page_number,
                "position": position,
            }
            for page_number, position in match.page_positions
        ],
        "proximity": match.proximity,
    }


__all__ = [
    "SIGNAL_CLASS_GENERIC",
    "SIGNAL_CLASS_CONTEXTUAL",
    "SIGNAL_CLASS_DISTINCTIVE",
    "SPECIFICITY_WEIGHTS",
    "MIN_CANDIDATE_SCORE",
    "MEDIUM_CONFIDENCE_SCORE",
    "HIGH_CONFIDENCE_SCORE",
    "MIN_INDEPENDENT_SIGNALS",
    "count_independent_groups",
    "VERY_CLOSE_TOKEN_DISTANCE",
    "CLOSE_TOKEN_DISTANCE",
    "MATERIAL_COMPETITOR_MARGIN",
    "COMPETITOR_SCORE_PENALTY",
    "MAX_COMPETITOR_PENALTY",
    "MAX_EVIDENCE_PAGES",
    "SignalDefinition",
    "SignalMatch",
    "normalize_text",
    "tokenize",
    "phrase_tokens",
    "token_aware_positions",
    "token_aware_match",
    "canonical_page_positions",
    "classify_signal",
    "PHRASE_INDEPENDENCE_FAMILIES",
    "independence_group",
    "phrase_independence_group",
    "validate_phrase_independence_registry",
    "build_taxonomy",
    "hierarchy_group",
    "collapse_hierarchy",
    "has_negative_context",
    "proximity_score",
    "evidence_proximity",
    "match_signals",
    "independent_groups",
    "score_candidate",
    "competitor_analysis",
    "final_score_with_competitor_adjustment",
    "classify_candidate",
    "serialize_match",
]
