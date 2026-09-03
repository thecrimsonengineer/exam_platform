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
