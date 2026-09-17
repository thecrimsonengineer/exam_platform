#!/usr/bin/env python3
from pathlib import Path
import hashlib
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def blob_sha(path: Path) -> str:
    data = path.read_bytes()
    return hashlib.sha1(f'blob {len(data)}\0'.encode() + data).hexdigest()


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{label}: expected exactly one target, found {count}')
    return text.replace(old, new, 1)


def replace_exact_count(
    text: str,
    old: str,
    new: str,
    expected_count: int,
    label: str,
) -> str:
    count = text.count(old)
    if count != expected_count:
        raise SystemExit(
            f'{label}: expected exactly {expected_count} targets, found {count}'
        )
    return text.replace(old, new)


def main() -> None:
    qbs_path = ROOT / 'lib/services/question_bank_service.dart'
    validator_path = ROOT / 'lib/services/dqg300_question_quality_validator.dart'

    expected = {
        qbs_path: '6af6fff438c3e6a8c2e63fd382ce1f75e6381b85',
        validator_path: '359715c9be1a2014764c09edae54e6530efe4594',
    }
    for path, expected_sha in expected.items():
        actual = blob_sha(path)
        if actual != expected_sha:
            raise SystemExit(
                f'Guard failed for {path.relative_to(ROOT)}: '
                f'expected {expected_sha}, got {actual}'
            )

    qbs = qbs_path.read_text(encoding='utf-8')

    qbs = replace_once(
        qbs,
        """  /// The existing H0.3 quality validator is used without modification.\n  ///\n  /// Warning-only questions are allowed to become VALIDATED.\n  /// Questions containing quality errors remain in REVIEW and are rejected.""",
        """  /// Final lifecycle advancement requires both the frozen DQG300 gate\n  /// and a clean legacy authoring-linter result. Any unresolved issue,\n  /// including a warning, blocks VALIDATED and PUBLISHED status.""",
        'publication documentation',
    )

    qbs = replace_once(
        qbs,
        """      final issues = validate(question);\n      final errors = issues.where((issue) => issue.isError).toList();\n      if (errors.isNotEmpty) {\n        throw StateError(errors.map((issue) => issue.message).join('\\n'));\n      }""",
        """      final issues = validate(question);\n      if (issues.isNotEmpty) {\n        throw StateError(issues.map((issue) => issue.message).join('\\n'));\n      }""",
        'bulk unresolved-issue gate',
    )

    qbs = replace_exact_count(
        qbs,
        """    if (issues.any((issue) => issue.isError)) {\n      throw StateError(issues.map((issue) => issue.message).join('\\n'));\n    }""",
        """    if (issues.isNotEmpty) {\n      throw StateError(issues.map((issue) => issue.message).join('\\n'));\n    }""",
        2,
        'single-question unresolved-issue gates',
    )

    qbs_path.write_text(qbs, encoding='utf-8')
    subprocess.run(['dart', 'format', str(qbs_path)], cwd=ROOT, check=True)
    print('PASS: all unresolved authoring quality issues now block final lifecycle advancement')


if __name__ == '__main__':
    main()
