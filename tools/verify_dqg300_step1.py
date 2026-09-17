#!/usr/bin/env python3
from pathlib import Path
from collections import Counter
import hashlib
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
MATRIX = ROOT / 'docs' / 'quiz_engine' / 'DQG_300_RULE_MATRIX.md'
SOURCE = ROOT / 'docs' / 'quiz_engine' / 'CSP11_QUIZ_QUALITY_VALIDATOR_FREEZE_CANDIDATE.md'
GENERATED = ROOT / 'test' / 'quality_validator_contract' / 'temporary' / 'dqg300_generated'
EXPECTED_SOURCE_BLOB = '68b4fe0a132c8cc7ebd095aa7340a6ee4bb29b4b'
RULE_RE = re.compile(r'^(DQG-\d{3})\|S(\d{2})\|(.+)$')


def git_blob_sha(data: bytes) -> str:
    return hashlib.sha1(f'blob {len(data)}\0'.encode() + data).hexdigest()


def fail(message):
    print(f'FAIL: {message}')
    raise SystemExit(1)


def load_rules():
    rules = []
    for line in MATRIX.read_text(encoding='utf-8').splitlines():
        m = RULE_RE.match(line.strip())
        if m:
            rules.append((m.group(1), int(m.group(2)), m.group(3).strip()))
    return rules


def main():
    rules = load_rules()
    ids = [r[0] for r in rules]
    expected = [f'DQG-{i:03d}' for i in range(1, 301)]
    if ids != expected:
        fail('DQG IDs must be exactly contiguous DQG-001..DQG-300')
    if len(set(ids)) != 300:
        fail('duplicate DQG IDs found')
    sections = [r[1] for r in rules]
    if set(sections) != set(range(1, 36)):
        fail('all 35 freeze-candidate sections must be covered')
    if any(Counter(sections)[n] == 0 for n in range(1, 36)):
        fail('one or more source sections have zero DQG coverage')
    if any(not r[2] for r in rules):
        fail('empty atomic requirement found')
    if 'every DQG-001 through DQG-299 passes' not in rules[-1][2]:
        fail('DQG-300 is not the derived final aggregate')

    source = SOURCE.read_text(encoding='utf-8')
    for n in range(1, 36):
        if f'## {n}.' not in source:
            fail(f'freeze candidate section {n} missing')
    source_blob = git_blob_sha(SOURCE.read_bytes())
    if source_blob != EXPECTED_SOURCE_BLOB:
        fail(f'freeze candidate drifted: {source_blob} != {EXPECTED_SOURCE_BLOB}')

    anchors = [
        'Question Difficulty Level = DQ6', 'DQS = 100/100',
        'Distractor 1 Plausibility = 5/5', 'Distractor 2 Plausibility = 5/5',
        'Distractor 3 Plausibility = 5/5',
        'Distractor 1 Truth Component Score = 4/4',
        'Distractor 2 Truth Component Score = 4/4',
        'Distractor 3 Truth Component Score = 4/4',
        'KEY ↔ D1 = 4', 'KEY ↔ D2 = 4', 'KEY ↔ D3 = 4',
        'BLOCK_COUNT = 0', 'FAIL_COUNT = 0', 'WARNING_COUNT = 0',
        'DEFENSIBLE BEST ANSWERS', 'Exactly 1', 'DISTRACTORS', 'Exactly 3',
        'no validator implementation should weaken or reinterpret these thresholds'
    ]
    for anchor in anchors:
        if anchor not in source:
            fail(f'critical source anchor missing: {anchor}')

    requirements = ' '.join(r[2] for r in rules).lower()
    for fragment in [
        'plausibility is exactly 5/5', 'truth component score is exactly 4/4',
        'dqs is exactly 100/100', 'confusability equals exactly 4',
        'no competent sme can reasonably defend', 'no reduced-quality question is publishable',
        'zero unresolved warnings', 'no manual override or reduced-quality route may exist'
    ]:
        if fragment not in requirements:
            fail(f'critical requirement missing from 300-DQG matrix: {fragment}')

    shards = sorted(GENERATED.glob('dqg_*_test.py')) if GENERATED.exists() else []
    if len(shards) != 30:
        fail(f'expected 30 generated temporary test shards, found {len(shards)}')
    seen = set()
    for shard in shards:
        seen.update(re.findall(r'DQG-\d{3}', shard.read_text(encoding='utf-8')))
    if seen != set(expected):
        fail('generated test shards do not collectively cover all 300 DQGs')

    print('PASS: Step 1 DQG300 audit')
    print('PASS: 300 contiguous unique atomic rules')
    print('PASS: all 35 freeze-candidate sections covered')
    print('PASS: source Git blob pinned and critical thresholds preserved')
    print('PASS: 30 temporary test shards cover DQG-001..DQG-300')
    print('PASS: DQG-300 is derived aggregate')


if __name__ == '__main__':
    main()
