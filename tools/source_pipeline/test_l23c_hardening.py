from l23c_hardening import (
    SignalDefinition,
    build_taxonomy,
    match_signals,
    score_candidate,
    classify_candidate,
    collapse_hierarchy,
    has_negative_context,
    tokenize,
)


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
