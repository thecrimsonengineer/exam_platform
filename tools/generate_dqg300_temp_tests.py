#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
MATRIX = ROOT / 'docs' / 'quiz_engine' / 'DQG_300_RULE_MATRIX.md'
OUT = ROOT / 'test' / 'quality_validator_contract' / 'temporary' / 'dqg300_generated'

RULE_RE = re.compile(r'^(DQG-\d{3})\|S(\d{2})\|(.+)$')


def load_rules():
    rules = []
    for line in MATRIX.read_text(encoding='utf-8').splitlines():
        m = RULE_RE.match(line.strip())
        if m:
            rules.append((m.group(1), int(m.group(2)), m.group(3).strip()))
    return rules


def main():
    rules = load_rules()
    if len(rules) != 300:
        raise SystemExit(f'expected 300 DQGs, found {len(rules)}')
    OUT.mkdir(parents=True, exist_ok=True)
    support = """import re\nfrom pathlib import Path\n\nROOT = Path(__file__).resolve().parents[4]\nMATRIX = ROOT / 'docs' / 'quiz_engine' / 'DQG_300_RULE_MATRIX.md'\nRULE_RE = re.compile(r'^(DQG-\\d{3})\\|S(\\d{2})\\|(.+)$')\n\ndef load_rules():\n    out = {}\n    for line in MATRIX.read_text(encoding='utf-8').splitlines():\n        m = RULE_RE.match(line.strip())\n        if m:\n            out[m.group(1)] = (int(m.group(2)), m.group(3).strip())\n    return out\n\ndef assert_contract(testcase, rule_id):\n    rules = load_rules()\n    testcase.assertIn(rule_id, rules)\n    section, requirement = rules[rule_id]\n    testcase.assertIn(section, range(1, 36))\n    testcase.assertTrue(requirement)\n"""
    (OUT / 'contract_support.py').write_text(support, encoding='utf-8')

    for shard in range(30):
        start = shard * 10 + 1
        end = start + 9
        ids = [f'DQG-{n:03d}' for n in range(start, end + 1)]
        body = f"""import unittest\nfrom contract_support import assert_contract\n\nIDS = {ids!r}\n\nclass Dqg{start:03d}{end:03d}Test(unittest.TestCase):\n    def test_all_atomic_rules_exist_and_are_mapped(self):\n        for rule_id in IDS:\n            assert_contract(self, rule_id)\n\nif __name__ == '__main__':\n    unittest.main()\n"""
        (OUT / f'dqg_{start:03d}_{end:03d}_test.py').write_text(body, encoding='utf-8')

    print(f'PASS: generated 30 temporary test shards for {len(rules)} DQGs')


if __name__ == '__main__':
    main()
