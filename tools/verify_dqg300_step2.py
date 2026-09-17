#!/usr/bin/env python3
from pathlib import Path
import hashlib
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
MATRIX = ROOT / 'docs/quiz_engine/DQG_300_RULE_MATRIX.md'
SPEC = ROOT / 'docs/quiz_engine/CSP11_QUIZ_QUALITY_VALIDATOR_FREEZE_CANDIDATE.md'
VALIDATOR = ROOT / 'lib/services/dqg300_question_quality_validator.dart'
EVIDENCE = ROOT / 'lib/models/question_quality_evidence.dart'
RESULT = ROOT / 'lib/models/question_quality_validation_result.dart'
TEST_DIR = ROOT / 'test/quality_validator_contract/dqg300'

EXPECTED_MATRIX_BLOB = '2927a23e24e6fc274629851a15110ba602d927a0'
EXPECTED_SPEC_BLOB = '68b4fe0a132c8cc7ebd095aa7340a6ee4bb29b4b'


def git_blob_sha(path: Path) -> str:
    data = path.read_bytes()
    header = f'blob {len(data)}\0'.encode()
    return hashlib.sha1(header + data).hexdigest()


def fail(message: str):
    print(f'FAIL: {message}')
    sys.exit(1)


if git_blob_sha(MATRIX) != EXPECTED_MATRIX_BLOB:
    fail('Step 1 DQG300 matrix changed after closure')
if git_blob_sha(SPEC) != EXPECTED_SPEC_BLOB:
    fail('freeze-candidate specification changed after Step 1 closure')

matrix_text = MATRIX.read_text(encoding='utf-8')
ids = re.findall(r'^(DQG-\d{3})\|S\d{2}\|', matrix_text, flags=re.M)
expected = [f'DQG-{i:03d}' for i in range(1, 301)]
if ids != expected:
    fail('DQG matrix is not exactly contiguous DQG-001..DQG-300')

validator = VALIDATOR.read_text(encoding='utf-8')
evidence = EVIDENCE.read_text(encoding='utf-8')
result = RESULT.read_text(encoding='utf-8')

if 'const Dqg300QuestionQualityValidator();' not in validator:
    fail('strict validator constructor must remain parameterless')
if "static const bool publicationOverrideSupported = false;" not in validator:
    fail('strict validator must hard-code publication override support to false')
if 'answerLengthCheckEnabled' in validator:
    fail('legacy answer-length toggle leaked into strict DQG300 validator')
code_only = '\n'.join(line.split('//', 1)[0] for line in validator.splitlines())
if re.search(r'\b(?:bypass|tolerance)\b', code_only, flags=re.I):
    fail('bypass/tolerance control found in strict validator code')

cases = [int(x) for x in re.findall(r'^\s*case\s+(\d+):', validator, flags=re.M)]
duplicates = sorted({value for value in cases if cases.count(value) > 1})
if duplicates:
    fail(f'duplicate machine switch cases: {duplicates}')
if 'for (var number = 1; number <= 299; number++)' not in validator:
    fail('validator must evaluate every atomic DQG-001..DQG-299')
if 'proofPass && machinePass' not in validator:
    fail('structured proof may never override a failed machine check')
if 'e.ruleEvidence.length == 299' not in validator:
    fail('structured evidence ledger must contain exactly 299 atomic records')
if 'record != null && record.isComplete && record.satisfied' not in validator:
    fail('missing, incomplete, or failed structured evidence must fail closed')

for name in [
    'plausibility',
    'truthComponent',
    'dq6Compliance',
    'scenarioIntegration',
    'misconceptionTargeting',
    'singleFatalFlaw',
    'confusability',
    'parity',
    'eliminationResistance',
    'superiorityAmbiguity',
]:
    if f"'{name}':" not in validator:
        fail(f'missing frozen DQS category {name}')

if re.search(r'\bfinal\s+int\s+dqs\s*;', evidence):
    fail('caller-supplied DQS field exists in QuestionQualityEvidence')
if 'QuestionQualityStatus status' in result and 'required QuestionQualityStatus' in result:
    fail('caller can directly supply final PASS/BLOCK status')
if "ruleId: 'DQG-300'" not in result:
    fail('DQG-300 is not derived by the validation result model')
if 'atomicRules.every((rule) => rule.passed)' not in result:
    fail('DQG-300 is not tied to every atomic rule')

test_files = list(TEST_DIR.rglob('*_test.dart'))
if len(test_files) < 4:
    fail('expected DQG300 runtime test suite is incomplete')
for path in test_files:
    text = path.read_text(encoding='utf-8')
    if '@Skip' in text or 'skip:' in text:
        fail(f'skipped test detected: {path}')

atomic = (TEST_DIR / 'dqg300_atomic_mutation_test.dart').read_text(encoding='utf-8')
if 'for (var i = 1; i <= 299; i++)' not in atomic:
    fail('atomic mutation suite does not cover DQG-001..DQG-299')
if "result.rule('DQG-300').passed" not in atomic:
    fail('atomic mutation suite does not require aggregate DQG-300 to block')

print('PASS: Step 2 static integrity audit')
print('PASS: Step 1 matrix and freeze candidate unchanged')
print('PASS: all 299 atomic DQGs evaluated with proof AND machine checks; DQG-300 derived')
print('PASS: no strict-validator toggle, bypass, tolerance, or caller-supplied DQS/status')
print('PASS: all 10 frozen DQS categories present')
print('PASS: no skipped DQG300 runtime tests')
