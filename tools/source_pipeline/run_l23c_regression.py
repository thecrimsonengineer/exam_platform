import sys

sys.path.insert(0, "tools/source_pipeline")

import test_l23c_hardening as tests

TESTS = [
    getattr(tests, name)
    for name in sorted(dir(tests))
    if name.startswith("test_") and callable(getattr(tests, name))
]

passed = 0
failed = 0

for test in TESTS:
    try:
        test()
    except Exception as exc:
        failed += 1
        print("FAIL:", test.__name__, "->", repr(exc))
    else:
        print("PASS:", test.__name__)
        passed += 1

print(f"RESULT: {passed}/{len(TESTS)} tests passed")

if failed or passed != len(TESTS):
    raise SystemExit(1)
