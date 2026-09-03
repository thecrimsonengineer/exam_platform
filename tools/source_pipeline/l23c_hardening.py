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
    proximity: float


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

INDEPENDENCE_OVERRIDES = {
    # All signals in these conceptual families are one evidence group.
    "system safety analysis": "system_safety_analysis",
    "data analysis": "data_analysis",
    "risk evaluation": "risk_evaluation",
    "risk management strategies": "risk_management",
    "risk ranking": "risk_ranking",
    "training needs assessment": "training_needs",
    "training program development": "training_development",
    "training effectiveness": "training_effectiveness",
    "education training methods": "training_methods",
    "adult learning": "adult_learning",
}


def independence_group(label: str) -> str:
    if label in INDEPENDENCE_OVERRIDES:
        return INDEPENDENCE_OVERRIDES[label]

    return re.sub(
        r"[^a-z0-9]+",
        "_",
        label.lower(),
    ).strip("_")


# ================================================================
# TAXONOMY CONSTRUCTION
# ================================================================

def build_taxonomy(
    signal_map: Dict[str, Dict],
) -> List[SignalDefinition]:
    """Build deterministic signal definitions with explicit ownership."""

    definitions: List[SignalDefinition] = []

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
                    independence_group=independence_group(label),
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

            if not first.positions or not second.positions:
                scores.append(0.75)
                continue

            distance = min(
                abs(a - b)
                for a in first.positions
                for b in second.positions
            )

            if distance <= VERY_CLOSE_TOKEN_DISTANCE:
                scores.append(1.25)
            elif distance <= CLOSE_TOKEN_DISTANCE:
                scores.append(1.00)
            else:
                scores.append(0.75)

    return round(
        sum(scores) / len(scores),
        3,
    )


# ================================================================
# MATCHING
# ================================================================

def match_signals(
    page_records: Sequence[Dict],
    definitions: Sequence[SignalDefinition],
) -> List[SignalMatch]:

    matches: List[SignalMatch] = []

    for definition in definitions:

        pages: List[int] = []
        positions: List[int] = []
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
            positions.extend(positive_positions)
            positive_occurrences += len(
                positive_positions
            )

        if not pages:
            continue

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
                pages=tuple(sorted(set(pages))),
                occurrences=positive_occurrences,
                positions=tuple(sorted(positions)),
                proximity=proximity_score(positions),
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

    independence_score = min(
        len(groups) * 1.00,
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
    "classify_signal",
    "independence_group",
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
