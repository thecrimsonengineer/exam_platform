import sys

sys.path.insert(0, "tools/source_pipeline")

import test_l23c_hardening as tests

TESTS = [
    tests.test_taxonomy_builds,
    tests.test_negative_context_detected,
    tests.test_negative_context_not_false_positive,
    tests.test_hierarchy_collapse_is_deterministic,
    tests.test_scoring_is_deterministic,
    tests.test_classification_thresholds_are_deterministic,
]

passed = 0

for test in TESTS:
    test()
    print("PASS:", test.__name__)
    passed += 1

print(f"RESULT: {passed}/{len(TESTS)} tests passed")

if passed != len(TESTS):
    raise SystemExit(1)
