from pathlib import Path
from l23c_hardening import (
    SignalDefinition,
    SignalMatch,
    build_taxonomy,
    match_signals,
    score_candidate,
    classify_candidate,
    count_independent_groups,
    PHRASE_INDEPENDENCE_FAMILIES,
    phrase_independence_group,
    validate_phrase_independence_registry,
    collapse_hierarchy,
    has_negative_context,
    tokenize,
    token_aware_positions,
    evidence_proximity,
    serialize_match,
    canonical_page_positions,
    competitor_analysis,
    final_score_with_competitor_adjustment,
)
import json
import subprocess
import sys
import tempfile

def signal(
    signal_id,
    label,
    phrase,
    classification="direct",
    specificity_weight=1.0,
    independence_group="test",
    hierarchy_parent=None,
    aliases=(),
    competency_id="test_c01",
):
    return SignalDefinition(
        signal_id=signal_id,
        competency_id=competency_id,
        label=label,
        phrase=phrase,
        classification=classification,
        specificity_weight=specificity_weight,
        independence_group=independence_group,
        hierarchy_parent=hierarchy_parent,
        aliases=aliases,
    )


def phrase_position(text, phrase):
    tokens = tokenize(text)
    phrase_tokens = tokenize(phrase)

    for index in range(len(tokens) - len(phrase_tokens) + 1):
        if tokens[index:index + len(phrase_tokens)] == phrase_tokens:
            return index

    raise AssertionError(
        f"Phrase '{phrase}' was not found in test text."
    )


def test_taxonomy_builds():
    signal_map = {
        "test_c01": {
            "label": "Failure modes and effects",
            "phrases": [
                "failure modes and effects",
            ],
        },
    }

    taxonomy = build_taxonomy(signal_map)

    assert taxonomy
    assert len(taxonomy) == 1
    assert taxonomy[0].label == "Failure modes and effects"
    assert taxonomy[0].phrase == "failure modes and effects"
    assert taxonomy[0].competency_id == "test_c01"


def test_negative_context_detected():
    text = "The section does not discuss failure modes and effects."

    position = phrase_position(
        text,
        "failure modes and effects",
    )

    assert has_negative_context(
        text,
        "failure modes and effects",
        position,
    )


def test_negative_context_not_false_positive():
    text = "The assessment discusses failure modes and effects."

    position = phrase_position(
        text,
        "failure modes and effects",
    )

    assert not has_negative_context(
        text,
        "failure modes and effects",
        position,
    )


def test_hierarchy_collapse_is_deterministic():
    signal_map = {
        "test_c01": {
            "label": "Failure modes",
            "phrases": [
                "failure modes",
            ],
        },
        "test_c02": {
            "label": "Failure modes and effects",
            "phrases": [
                "failure modes and effects",
            ],
        },
    }

    taxonomy = build_taxonomy(signal_map)

    parent = next(
        item.signal_id
        for item in taxonomy
        if item.label == "Failure modes"
    )

    child = next(
        item.signal_id
        for item in taxonomy
        if item.label == "Failure modes and effects"
    )

    definitions = [
        signal(
            parent,
            "test_c01",
            "Failure modes",
            "failure modes",
            independence_group="failure",
        ),
        signal(
            child,
            "test_c02",
            "Failure modes and effects",
            "failure modes and effects",
            independence_group="failure",
            hierarchy_parent=parent,
        ),
    ]

    page_records = [
        {
            "page": 1,
            "text": "The study examines failure modes and effects.",
        }
    ]

    matches = match_signals(page_records, definitions)
    collapsed1 = collapse_hierarchy(matches)
    collapsed2 = collapse_hierarchy(matches)

    assert collapsed1 == collapsed2
    assert len(collapsed1) >= 1
    assert len(collapsed1) <= len(matches)



def test_canonical_page_positions_deduplicates_and_sorts():
    page_positions = (
        (7, 40),
        (4, 20),
        (7, 40),
        (4, 10),
        (7, 20),
        (4, 20),
    )

    assert canonical_page_positions(page_positions) == (
        (4, 10),
        (4, 20),
        (7, 20),
        (7, 40),
    )


def test_canonical_page_positions_is_order_independent():
    first = (
        (9, 500),
        (4, 20),
        (9, 100),
        (4, 20),
    )

    second = (
        (4, 20),
        (9, 100),
        (4, 20),
        (9, 500),
    )

    assert canonical_page_positions(first) == (
        canonical_page_positions(second)
    )


def test_match_occurrences_equal_unique_page_position_count():
    signal_map = {
        "test_c01": {
            "label": "Failure modes",
            "phrases": [
                "failure modes",
            ],
        },
    }

    taxonomy = build_taxonomy(signal_map)

    page_records = [
        {
            "page_number": 4,
            "text": "Failure modes are documented.",
        },
        {
            "page_number": 4,
            "text": "Failure modes are documented.",
        },
        {
            "page_number": 7,
            "text": "Failure modes are reviewed.",
        },
    ]

    matches = match_signals(page_records, taxonomy)

    assert len(matches) == 1

    match = matches[0]

    assert match.page_positions == (
        (4, 0),
        (7, 0),
    )

    assert match.pages == (4, 7)
    assert match.occurrences == 2
    assert match.positions == (0, 0)


def test_duplicate_occurrences_do_not_create_independent_groups():
    page_positions = (
        (2, 10),
        (2, 10),
        (2, 10),
        (8, 10),
        (8, 10),
    )

    canonical = canonical_page_positions(page_positions)

    assert canonical == (
        (2, 10),
        (8, 10),
    )

    repeated_match = SignalMatch(
        signal_id="test_c01__failure_modes__01",
        competency_id="test_c01",
        label="Failure modes",
        phrase="failure modes",
        classification="distinctive",
        specificity_weight=1.0,
        independence_group="test_c01::failure_modes",
        hierarchy_parent=None,
        hierarchy_role="primary",
        hierarchy_collapsed=False,
        negative_context=False,
        pages=(2, 8),
        occurrences=len(canonical),
        positions=tuple(
            position
            for _, position in canonical
        ),
        page_positions=canonical,
        proximity=1.0,
    )

    assert repeated_match.occurrences == 2
    assert count_independent_groups([repeated_match]) == 1


def test_match_signals_preserves_page_position_pairs():
    signal_map = {
        "test_c01": {
            "label": "Failure modes",
            "phrases": [
                "failure modes",
            ],
        },
    }

    taxonomy = build_taxonomy(signal_map)

    page_records = [
        {
            "page_number": 7,
            "text": (
                "Failure modes are discussed. "
                "Failure modes are reviewed."
            ),
        },
        {
            "page_number": 4,
            "text": "Failure modes are documented.",
        },
    ]

    matches = match_signals(page_records, taxonomy)

    assert len(matches) == 1

    match = matches[0]

    assert match.pages == (4, 7)
    assert match.occurrences == 3
    page_7_text = (
        "Failure modes are discussed. "
        "Failure modes are reviewed."
    )

    expected_page_7_positions = tuple(
        token_aware_positions(page_7_text, "failure modes")
    )

    assert expected_page_7_positions == (0, 4)

    assert match.page_positions == (
        (4, phrase_position(
            "Failure modes are documented.",
            "failure modes",
        )),
        (7, 0),
        (7, 4),
    )


def test_repeated_phrase_across_pages_remains_one_independent_group():
    page_positions = (
        (2, 0),
        (8, 0),
        (12, 0),
    )

    repeated_match = SignalMatch(
        signal_id="test_c01__failure_modes__01",
        competency_id="test_c01",
        label="Failure modes",
        phrase="failure modes",
        classification="distinctive",
        specificity_weight=1.0,
        independence_group="test_c01::failure_modes",
        hierarchy_parent=None,
        hierarchy_role="primary",
        hierarchy_collapsed=False,
        negative_context=False,
        pages=(2, 8, 12),
        occurrences=3,
        positions=(0, 0, 0),
        page_positions=page_positions,
        proximity=1.0,
    )

    assert repeated_match.occurrences == 3
    assert repeated_match.pages == (2, 8, 12)
    assert repeated_match.page_positions == page_positions

    # Repeated occurrences of the same phrase, even across
    # multiple pages, represent one independent evidence group.
    assert count_independent_groups([repeated_match]) == 1


def test_page_aware_proximity_does_not_cross_pages():
    first = SignalMatch(
        signal_id="a",
        competency_id="test_c01",
        label="Failure modes",
        phrase="failure modes",
        classification="distinctive",
        specificity_weight=1.0,
        independence_group="test_c01::failure",
        hierarchy_parent=None,
        hierarchy_role="primary",
        hierarchy_collapsed=False,
        negative_context=False,
        pages=(4,),
        occurrences=1,
        positions=(500,),
        page_positions=((4, 500),),
        proximity=1.0,
    )

    second = SignalMatch(
        signal_id="b",
        competency_id="test_c02",
        label="Risk assessment",
        phrase="risk assessment",
        classification="distinctive",
        specificity_weight=1.0,
        independence_group="test_c02::risk",
        hierarchy_parent=None,
        hierarchy_role="primary",
        hierarchy_collapsed=False,
        negative_context=False,
        pages=(9,),
        occurrences=1,
        positions=(510,),
        page_positions=((9, 510),),
        proximity=1.0,
    )

    # The numeric positions are close, but they belong to different
    # pages. Therefore they must not receive close-position scoring.
    result = evidence_proximity([first, second])

    assert result == 0.25


def test_page_aware_proximity_uses_matching_page_positions():
    first = SignalMatch(
        signal_id="a",
        competency_id="test_c01",
        label="Failure modes",
        phrase="failure modes",
        classification="distinctive",
        specificity_weight=1.0,
        independence_group="test_c01::failure",
        hierarchy_parent=None,
        hierarchy_role="primary",
        hierarchy_collapsed=False,
        negative_context=False,
        pages=(4, 9),
        occurrences=2,
        positions=(20, 500),
        page_positions=((4, 20), (9, 500)),
        proximity=1.0,
    )

    second = SignalMatch(
        signal_id="b",
        competency_id="test_c02",
        label="Risk assessment",
        phrase="risk assessment",
        classification="distinctive",
        specificity_weight=1.0,
        independence_group="test_c02::risk",
        hierarchy_parent=None,
        hierarchy_role="primary",
        hierarchy_collapsed=False,
        negative_context=False,
        pages=(4, 9),
        occurrences=2,
        positions=(100, 510),
        page_positions=((4, 100), (9, 510)),
        proximity=1.0,
    )

    result = evidence_proximity([first, second])

    # Page 4 has positions 20 and 100, while page 9 has
    # positions 500 and 510. The closest same-page pair is
    # page 9 with a distance of 10.
    assert result == 1.25



def test_cross_signal_same_physical_occurrence_does_not_create_proximity():
    first = SignalMatch(
        signal_id="a", competency_id="test_c01", label="Evidence",
        phrase="signal a", classification="distinctive",
        specificity_weight=1.0, independence_group="test_c01::family",
        hierarchy_parent=None, hierarchy_role="none", hierarchy_collapsed=False,
        negative_context=False, pages=(7,), occurrences=1, positions=(500,),
        page_positions=((7, 500),), proximity=1.0,
    )
    second = SignalMatch(
        signal_id="b", competency_id="test_c01", label="Evidence",
        phrase="signal b", classification="distinctive",
        specificity_weight=1.0, independence_group="test_c01::family",
        hierarchy_parent=None, hierarchy_role="none", hierarchy_collapsed=False,
        negative_context=False, pages=(7,), occurrences=1, positions=(500,),
        page_positions=((7, 500),), proximity=1.0,
    )

    # A and B identify the same physical evidence occurrence. They are
    # already in the same independence family, so they must not gain
    # additional proximity merely because two signal definitions matched it.
    assert evidence_proximity([first, second]) == 0.0


def test_cross_signal_same_physical_occurrence_does_not_change_candidate_score():
    def make_match(signal_id, phrase, weight, group):
        return SignalMatch(
            signal_id=signal_id, competency_id="test_c01", label="Evidence",
            phrase=phrase, classification="distinctive",
            specificity_weight=weight, independence_group=group,
            hierarchy_parent=None, hierarchy_role="none", hierarchy_collapsed=False,
            negative_context=False, pages=(7,), occurrences=1, positions=(500,),
            page_positions=((7, 500),), proximity=1.0,
        )

    single = make_match("a", "signal a", 1.5, "test_c01::family")
    duplicate = make_match("b", "signal b", 1.0, "test_c01::family")

    baseline = score_candidate([single])
    duplicated = score_candidate([single, duplicate])

    assert duplicated["independence_score"] == baseline["independence_score"]
    assert duplicated["page_support_score"] == baseline["page_support_score"]
    assert duplicated["proximity_score"] == baseline["proximity_score"]
    assert duplicated["raw_score"] == baseline["raw_score"]

def test_page_position_serialization_is_deterministic():
    signal_map = {
        "test_c01": {
            "label": "Failure modes",
            "phrases": [
                "failure modes",
            ],
        },
    }

    taxonomy = build_taxonomy(signal_map)

    page_records = [
        {
            "page_number": 9,
            "text": "Failure modes are reviewed.",
        },
        {
            "page_number": 4,
            "text": "Failure modes are documented.",
        },
    ]

    matches1 = match_signals(page_records, taxonomy)
    matches2 = match_signals(list(reversed(page_records)), taxonomy)

    assert matches1 == matches2

    serialized = serialize_match(matches1[0])

    assert serialized["page_positions"] == [
        {
            "page_number": 4,
            "position": phrase_position(
                "Failure modes are documented.",
                "failure modes",
            ),
        },
        {
            "page_number": 9,
            "position": phrase_position(
                "Failure modes are reviewed.",
                "failure modes",
            ),
        },
    ]


def test_collapse_hierarchy_preserves_page_positions():
    original = SignalMatch(
        signal_id="test_c01__failure_modes__01",
        competency_id="test_c01",
        label="Failure modes",
        phrase="failure modes",
        classification="distinctive",
        specificity_weight=1.0,
        independence_group="test_c01::failure_modes",
        hierarchy_parent=None,
        hierarchy_role="specific",
        hierarchy_collapsed=False,
        negative_context=False,
        pages=(4, 7),
        occurrences=2,
        positions=(10, 30),
        page_positions=((4, 10), (7, 30)),
        proximity=1.0,
    )

    collapsed = collapse_hierarchy([original])

    assert len(collapsed) == 1
    assert collapsed[0].pages == (4, 7)
    assert collapsed[0].positions == (10, 30)
    assert collapsed[0].page_positions == (
        (4, 10),
        (7, 30),
    )


def test_scoring_is_deterministic():
    signal_map = {
        "test_c01": {
            "label": "Failure modes and effects",
            "phrases": [
                "failure modes and effects",
            ],
        },
        "test_c02": {
            "label": "Risk assessment",
            "phrases": [
                "risk assessment",
            ],
        },
        "test_c03": {
            "label": "Hazard identification",
            "phrases": [
                "hazard identification",
            ],
        },
    }

    taxonomy = build_taxonomy(signal_map)

    page_records = [
        {
            "page": 1,
            "text": (
                "Failure modes and effects were examined. "
                "Risk assessment and hazard identification were also considered."
            ),
        }
    ]

    matches = match_signals(page_records, taxonomy)

    result1 = score_candidate(matches)
    result2 = score_candidate(matches)

    assert result1 == result2
    assert result1["raw_score"] >= 0


def test_classification_thresholds_are_deterministic():
    assert classify_candidate(0.0, 0, 0, 0) is None
    assert classify_candidate(6.5, 1, 0, 2) is None
    assert classify_candidate(6.5, 2, 0, 0) is None
    assert classify_candidate(3.5, 2, 0, 1) == "medium"
    assert classify_candidate(6.0, 3, 0, 1) == "high"

    results = [
        classify_candidate(3.5, 2, 0, 1),
        classify_candidate(3.5, 2, 0, 1),
        classify_candidate(3.5, 2, 0, 1),
    ]
    assert results == ["medium", "medium", "medium"]

def test_phrase_independence_groups_are_controlled_and_scoped():
    signal_map = {
        "d01_c03": {
            "label": "common workplace hazards",
            "phrases": [
                "confined spaces",
                "lockout tagout",
                "working around water",
                "caught in",
                "struck by",
                "excavation",
            ],
        },
    }

    taxonomy = build_taxonomy(signal_map)
    groups = {item.phrase: item.independence_group for item in taxonomy}

    assert groups["caught in"] == groups["struck by"]
    assert groups["caught in"] != groups["confined spaces"]
    assert groups["confined spaces"] != groups["lockout tagout"]
    assert groups["excavation"] != groups["lockout tagout"]
    assert groups["confined spaces"].startswith("d01_c03::")


def test_unassigned_phrase_uses_non_independent_default_group():
    signal_map = {
        "test_c01": {
            "label": "Test competency",
            "phrases": ["unassigned phrase"],
        },
    }

    taxonomy = build_taxonomy(signal_map)
    assert taxonomy[0].independence_group == "test_c01::default"


def test_count_independent_groups_excludes_default_and_deduplicates():
    def make_match(signal_id, group):
        return SignalMatch(
            signal_id=signal_id,
            competency_id="test_c01",
            label="Test competency",
            phrase=signal_id,
            classification="direct",
            specificity_weight=1.0,
            independence_group=group,
            hierarchy_parent=None,
            hierarchy_role="none",
            hierarchy_collapsed=False,
            negative_context=False,
            pages=(1,),
            occurrences=1,
            positions=(1,),
            proximity=0.0,
        )

    matches = [
        make_match("default_a", "test_c01::default"),
        make_match("family_a", "test_c01::family_a"),
        make_match("family_a_duplicate", "test_c01::family_a"),
        make_match("family_b", "test_c01::family_b"),
        make_match("default_b", "test_c01::default"),
    ]

    assert count_independent_groups(matches) == 2


def test_count_independent_groups_boundary_values():
    def make_match(signal_id, group):
        return SignalMatch(
            signal_id=signal_id,
            competency_id="test_c01",
            label="Test competency",
            phrase=signal_id,
            classification="direct",
            specificity_weight=1.0,
            independence_group=group,
            hierarchy_parent=None,
            hierarchy_role="none",
            hierarchy_collapsed=False,
            negative_context=False,
            pages=(1,),
            occurrences=1,
            positions=(1,),
            proximity=0.0,
        )

    assert count_independent_groups([]) == 0

    assert count_independent_groups([
        make_match("default", "test_c01::default"),
    ]) == 0

    assert count_independent_groups([
        make_match("family_a", "test_c01::family_a"),
    ]) == 1

    assert count_independent_groups([
        make_match("family_a", "test_c01::family_a"),
        make_match("default", "test_c01::default"),
    ]) == 1

    assert count_independent_groups([
        make_match("family_a", "test_c01::family_a"),
        make_match("family_b", "test_c01::family_b"),
    ]) == 2

    assert count_independent_groups([
        make_match("family_a", "test_c01::family_a"),
        make_match("family_b", "test_c01::family_b"),
        make_match("family_c", "test_c01::family_c"),
        make_match("default", "test_c01::default"),
    ]) == 3


def test_default_group_does_not_count_as_independent_evidence():
    def make_match(signal_id, phrase, weight, group, position):
        return SignalMatch(
            signal_id=signal_id,
            competency_id="test_c01",
            label="Test competency",
            phrase=phrase,
            classification="direct",
            specificity_weight=weight,
            independence_group=group,
            hierarchy_parent=None,
            hierarchy_role="none",
            hierarchy_collapsed=False,
            negative_context=False,
            pages=(1,),
            occurrences=1,
            positions=(position,),
            proximity=0.0,
        )

    matches = [
        make_match("default", "broad signal", 1.0, "test_c01::default", 1),
        make_match("family_a", "specific signal a", 1.75, "test_c01::family_a", 3),
        make_match("family_a_2", "specific signal a2", 1.0, "test_c01::family_a", 5),
        make_match("family_b", "specific signal b", 1.75, "test_c01::family_b", 7),
    ]

    result = score_candidate(matches)
    assert result["independence_score"] == 2.0


def test_registry_validation_rejects_unknown_phrase():
    original = dict(PHRASE_INDEPENDENCE_FAMILIES)
    try:
        PHRASE_INDEPENDENCE_FAMILIES[("d01_c03", "not registered")] = "invalid"
        signal_map = {
            "d01_c03": {
                "label": "common workplace hazards",
                "phrases": [
                    "confined spaces",
                    "lockout tagout",
                    "working around water",
                    "caught in",
                    "struck by",
                    "excavation",
                ],
            },
        }

        try:
            validate_phrase_independence_registry(signal_map)
        except ValueError as exc:
            assert "not present" in str(exc)
        else:
            raise AssertionError("Registry validation accepted an unknown phrase.")
    finally:
        PHRASE_INDEPENDENCE_FAMILIES.clear()
        PHRASE_INDEPENDENCE_FAMILIES.update(original)


def test_phrase_independence_registry_is_deterministic():
    phrases = (
        "confined spaces",
        "lockout tagout",
        "caught in",
        "struck by",
        "unmapped phrase",
    )

    first = [
        phrase_independence_group(
            "d01_c03",
            "common workplace hazards",
            phrase,
        )
        for phrase in phrases
    ]

    second = [
        phrase_independence_group(
            "d01_c03",
            "common workplace hazards",
            phrase,
        )
        for phrase in phrases
    ]

    assert first == second
    assert first == [
        "d01_c03::confined_space",
        "d01_c03::hazardous_energy",
        "d01_c03::mechanical_contact",
        "d01_c03::mechanical_contact",
        "d01_c03::default",
    ]

def test_cross_signal_distinct_physical_occurrences_still_create_proximity():
    first = SignalMatch(
        signal_id="a", competency_id="test_c01", label="Evidence",
        phrase="signal a", classification="distinctive",
        specificity_weight=1.0, independence_group="test_c01::family",
        hierarchy_parent=None, hierarchy_role="none", hierarchy_collapsed=False,
        negative_context=False, pages=(7,), occurrences=1, positions=(500,),
        page_positions=((7, 500),), proximity=1.0,
    )
    second = SignalMatch(
        signal_id="b", competency_id="test_c01", label="Evidence",
        phrase="signal b", classification="distinctive",
        specificity_weight=1.0, independence_group="test_c01::family",
        hierarchy_parent=None, hierarchy_role="none", hierarchy_collapsed=False,
        negative_context=False, pages=(7,), occurrences=1, positions=(510,),
        page_positions=((7, 510),), proximity=1.0,
    )

    assert evidence_proximity([first, second]) == 1.25


def test_cross_signal_shared_and_distinct_occurrences_use_distinct_coordinates():
    first = SignalMatch(
        signal_id="a", competency_id="test_c01", label="Evidence",
        phrase="signal a", classification="distinctive",
        specificity_weight=1.0, independence_group="test_c01::family",
        hierarchy_parent=None, hierarchy_role="none", hierarchy_collapsed=False,
        negative_context=False, pages=(7,), occurrences=2,
        positions=(500, 510),
        page_positions=((7, 500), (7, 510)), proximity=1.0,
    )
    second = SignalMatch(
        signal_id="b", competency_id="test_c01", label="Evidence",
        phrase="signal b", classification="distinctive",
        specificity_weight=1.0, independence_group="test_c01::family",
        hierarchy_parent=None, hierarchy_role="none", hierarchy_collapsed=False,
        negative_context=False, pages=(7,), occurrences=2,
        positions=(500, 530),
        page_positions=((7, 500), (7, 530)), proximity=1.0,
    )

    assert evidence_proximity([first, second]) == 1.25


def test_cross_signal_same_occurrence_on_different_pages_does_not_create_pair():
    first = SignalMatch(
        signal_id="a", competency_id="test_c01", label="Evidence",
        phrase="signal a", classification="distinctive",
        specificity_weight=1.0, independence_group="test_c01::family",
        hierarchy_parent=None, hierarchy_role="none", hierarchy_collapsed=False,
        negative_context=False, pages=(7,), occurrences=1, positions=(500,),
        page_positions=((7, 500),), proximity=1.0,
    )
    second = SignalMatch(
        signal_id="b", competency_id="test_c01", label="Evidence",
        phrase="signal b", classification="distinctive",
        specificity_weight=1.0, independence_group="test_c01::family",
        hierarchy_parent=None, hierarchy_role="none", hierarchy_collapsed=False,
        negative_context=False, pages=(8,), occurrences=1, positions=(500,),
        page_positions=((8, 500),), proximity=1.0,
    )

    assert evidence_proximity([first, second]) == 0.25

def test_distinctive_signal_can_produce_positive_evidence():
    definitions = [
        SignalDefinition(
            signal_id="d01_c01_s01",
            competency_id="d01_c01",
            label="prevention through design",
            phrase="prevention through design",
            classification="distinctive",
            specificity_weight=2.5,
            independence_group="d01_c01::ptd",
        ),
    ]
    matches = match_signals(
        [{"page_number": 1, "text": "Prevention through design was applied."}],
        definitions,
    )
    assert len(matches) == 1
    assert matches[0].competency_id == "d01_c01"
    assert matches[0].occurrences == 1
    assert matches[0].classification == "distinctive"


def test_competitor_detection_identifies_materially_stronger_candidate():
    result = competitor_analysis(
        "d01_c01",
        3.0,
        [("d01_c01", 3.0), ("d02_c01", 4.0), ("d03_c01", 2.0)],
    )
    assert result["stronger_competitor_count"] == 0
    assert result["strongest_competitor_competency_id"] == "d02_c01"
    assert result["score_margin"] == -1.0


def test_competitor_adjustment_is_deterministic():
    competitor = {"stronger_competitor_count": 1}
    assert final_score_with_competitor_adjustment(5.0, competitor) == (4.5, -0.5)
    assert final_score_with_competitor_adjustment(5.0, competitor) == (4.5, -0.5)


def test_low_evidence_is_rejected_at_admission_threshold():
    assert classify_candidate(2.49, 2, 0, 1) is None
    assert classify_candidate(2.50, 2, 0, 1) == "low"


def test_high_confidence_requires_no_stronger_competitor():
    assert classify_candidate(6.0, 3, 0, 1) == "high"
    assert classify_candidate(6.0, 3, 1, 1) == "medium"

def test_source_control_defines_frozen_48_46_2_boundary():
    import json
    from pathlib import Path

    root = Path(__file__).resolve().parents[2]
    path = root / "docs" / "source_pipeline" / "CSP11_source_control.json"
    data = json.loads(path.read_text(encoding="utf-8"))

    records = data["source_control"]
    expected_ids = [f"SRC-{i:03d}" for i in range(1, 49)]
    assert [record["source_id"] for record in records] == expected_ids

    authoritative = [record["source_id"] for record in records if record["source_eligibility"] == "AUTHORITATIVE"]
    excluded = [record["source_id"] for record in records if record["source_eligibility"] == "EXCLUDED"]

    assert len(authoritative) == 46
    assert excluded == ["SRC-003", "SRC-014"]
    assert data["authoritative_source_ids"] == authoritative
    assert data["excluded_source_ids"] == excluded


def test_source_control_candidate_generation_flags_match_eligibility():
    import json
    from pathlib import Path

    root = Path(__file__).resolve().parents[2]
    data = json.loads((root / "docs" / "source_pipeline" / "CSP11_source_control.json").read_text(encoding="utf-8"))

    for record in data["source_control"]:
        assert record["candidate_generation_allowed"] is (record["source_eligibility"] == "AUTHORITATIVE")


def test_source_control_preserves_excluded_sources_but_blocks_generation():
    import json
    from pathlib import Path

    root = Path(__file__).resolve().parents[2]
    data = json.loads((root / "docs" / "source_pipeline" / "CSP11_source_control.json").read_text(encoding="utf-8"))
    records = {record["source_id"]: record for record in data["source_control"]}

    for sid in ("SRC-003", "SRC-014"):
        record = records[sid]
        assert record["inventory_present"] is True
        assert record["content_evidence_present"] is True
        assert record["source_eligibility"] == "EXCLUDED"
        assert record["candidate_generation_allowed"] is False


def _run_validator_with_temporary_output(output_mutator):
    root = Path(__file__).resolve().parents[2]
    validator_path = (
        root
        / "tools"
        / "source_pipeline"
        / "validate_source_competency_candidates.py"
    )
    output_path = (
        root
        / "docs"
        / "source_pipeline"
        / "CSP11_source_to_competency_candidates.json"
    )

    with tempfile.TemporaryDirectory(
        prefix="l23c_validator_position_"
    ) as temp_dir:
        temp_root = Path(temp_dir)
        temporary_output = temp_root / "candidates.json"
        temporary_validator = (
            root
            / "tools"
            / "source_pipeline"
            / f"_l23c_validator_test_{temporary_output.stem}.py"
        )

        output_data = json.loads(
            output_path.read_text(encoding="utf-8")
        )

        output_mutator(output_data)

        temporary_output.write_text(
            json.dumps(output_data, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )

        validator_source = validator_path.read_text(
            encoding="utf-8"
        )

        output_literal = repr(str(temporary_output))
        validator_source = validator_source.replace(
            'OUTPUT_PATH = ROOT / "docs/source_pipeline/CSP11_source_to_competency_candidates.json"',
            f"OUTPUT_PATH = Path({output_literal})",
            1,
        )

        temporary_validator.write_text(
            validator_source,
            encoding="utf-8",
        )

        try:
            result = subprocess.run(
                [sys.executable, str(temporary_validator)],
                cwd=str(root),
                capture_output=True,
                text=True,
            )
        finally:
            temporary_validator.unlink(missing_ok=True)

        return result


def _first_hardened_match(output_data):
    for source_record in output_data.get("source_candidates", []):
        for mapping in source_record.get("candidate_mappings", []):
            matches = mapping.get("matched_signals", [])
            if matches:
                return matches[0]

    raise AssertionError(
        "No hardened matched signal was found in candidate output."
    )


def test_validator_accepts_cross_page_projected_positions():
    def mutate(output_data):
        match = _first_hardened_match(output_data)

        match["page_positions"] = [
            {
                "page_number": 112,
                "position": 56,
            },
            {
                "page_number": 136,
                "position": 491,
            },
            {
                "page_number": 145,
                "position": 238,
            },
        ]
        match["pages"] = [112, 136, 145]
        match["occurrences"] = 3
        match["positions"] = [56, 491, 238]

    result = _run_validator_with_temporary_output(mutate)

    assert result.returncode == 0, result.stdout + result.stderr
    assert "L23C-V066" not in result.stdout
    assert "L23C-V073" not in result.stdout
    assert "L23C-V074" not in result.stdout


def test_validator_rejects_noncanonical_physical_coordinates():
    def mutate(output_data):
        match = _first_hardened_match(output_data)

        match["page_positions"] = [
            {
                "page_number": 145,
                "position": 238,
            },
            {
                "page_number": 112,
                "position": 56,
            },
            {
                "page_number": 136,
                "position": 491,
            },
        ]
        match["pages"] = [112, 136, 145]
        match["occurrences"] = 3
        match["positions"] = [238, 56, 491]

    result = _run_validator_with_temporary_output(mutate)

    assert result.returncode != 0
    assert "L23C-V066" in result.stdout
