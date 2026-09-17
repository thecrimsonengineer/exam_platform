#!/usr/bin/env python3
from pathlib import Path
import hashlib
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def blob_sha(path: Path) -> str:
    data = path.read_bytes()
    return hashlib.sha1(f'blob {len(data)}\0'.encode() + data).hexdigest()


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{label}: expected exactly one target, found {count}')
    return text.replace(old, new, 1)


def main() -> None:
    validator_path = ROOT / 'lib/services/dqg300_question_quality_validator.dart'
    qbs_path = ROOT / 'lib/services/question_bank_service.dart'

    expected = {
        validator_path: '4143211c6663545ec5dd47686b69ff257c6eb753',
        qbs_path: '3b42f563b3be0517c20b761a35b35d4d007ee74d',
    }
    for path, sha in expected.items():
        actual = blob_sha(path)
        if actual != sha:
            raise SystemExit(
                f'Guard failed for {path.relative_to(ROOT)}: expected {sha}, got {actual}'
            )

    validator = validator_path.read_text(encoding='utf-8')
    validator = replace_once(
        validator,
        """  static final RegExp _genericSuperiority = RegExp(\n    r'^(less appropriate|not the best answer|incorrect)\\.?$',\n    caseSensitive: false,\n  );""",
        """  static final RegExp _genericSuperiority = RegExp(\n    r'^(?:d[123]\\s+is\\s+)?(?:less appropriate|not the best answer|incorrect)\\.?$',\n    caseSensitive: false,\n  );""",
        'generic superiority detector',
    )
    validator_path.write_text(validator, encoding='utf-8')

    qbs = qbs_path.read_text(encoding='utf-8')
    qbs = replace_once(
        qbs,
        """import '../models/question.dart';\nimport 'cloud_question_repository.dart';\nimport 'local_question_repository.dart';\nimport 'question_quality_validator.dart';""",
        """import '../models/question.dart';\nimport '../models/question_quality_evidence.dart';\nimport '../models/question_quality_validation_result.dart';\nimport 'cloud_question_repository.dart';\nimport 'dqg300_question_quality_validator.dart';\nimport 'local_question_repository.dart';\nimport 'question_quality_validator.dart';""",
        'strict imports',
    )
    qbs = replace_once(
        qbs,
        """  QuestionQualityValidator get _validator => QuestionQualityValidator(\n    answerLengthCheckEnabled: answerLengthCheckEnabled,\n  );""",
        """  QuestionQualityValidator get _validator => QuestionQualityValidator(\n    answerLengthCheckEnabled: answerLengthCheckEnabled,\n  );\n\n  static const Dqg300QuestionQualityValidator _dqg300Validator =\n      Dqg300QuestionQualityValidator();\n\n  QuestionQualityValidationResult requireDqg300PublicationPass(\n    Question question,\n    QuestionQualityEvidence? qualityEvidence,\n  ) {\n    if (qualityEvidence == null) {\n      throw StateError(\n        'DQG300 publication evidence is required. Missing evidence blocks publication.',\n      );\n    }\n\n    final result = _dqg300Validator.validate(\n      question: question,\n      evidence: qualityEvidence,\n    );\n\n    if (!result.isPublishable ||\n        result.dqs != 100 ||\n        result.passedRuleCount != 300 ||\n        result.failedRuleCount != 0) {\n      final failedRules = result.rules\n          .where((rule) => !rule.passed)\n          .map((rule) => rule.ruleId)\n          .join(', ');\n      throw StateError(\n        'DQG300 publication BLOCK: DQS ${result.dqs}/100; '\n        '${result.passedRuleCount}/300 gates passed; failed gates: $failedRules',\n      );\n    }\n\n    return result;\n  }""",
        'strict publication helper',
    )

    qbs = replace_once(
        qbs,
        """  Future<QuestionPreparedBatchPublishResult> publishPreparedBatch(\n    List<Question> questions,\n  ) async {""",
        """  Future<QuestionPreparedBatchPublishResult> publishPreparedBatch(\n    List<Question> questions, {\n    Map<int, QuestionQualityEvidence>? qualityEvidenceByQuestionId,\n  }) async {""",
        'bulk signature',
    )
    qbs = replace_once(
        qbs,
        """      final issues = validate(question);\n      final errors = issues.where((issue) => issue.isError).toList();\n      if (errors.isNotEmpty) {\n        throw StateError(errors.map((issue) => issue.message).join('\\n'));\n      }\n\n      final matches = _repository.questions""",
        """      final qualityEvidence = qualityEvidenceByQuestionId?[question.id];\n      requireDqg300PublicationPass(question, qualityEvidence);\n\n      final issues = validate(question);\n      final errors = issues.where((issue) => issue.isError).toList();\n      if (errors.isNotEmpty) {\n        throw StateError(errors.map((issue) => issue.message).join('\\n'));\n      }\n\n      final matches = _repository.questions""",
        'bulk strict preflight',
    )
    qbs = replace_once(
        qbs,
        """          _PreparedBulkQuestion(\n            question: question,\n            existingStatus: null,\n            reused: false,\n          ),""",
        """          _PreparedBulkQuestion(\n            question: question,\n            existingStatus: null,\n            reused: false,\n            qualityEvidence: qualityEvidence!,\n          ),""",
        'new bulk item evidence',
    )
    qbs = replace_once(
        qbs,
        """        _PreparedBulkQuestion(\n          question: Question.fromJson({\n            ...question.toJson(),\n            'id': existing.id,\n          }),\n          existingStatus: existing.status,\n          reused: true,\n        ),""",
        """        _PreparedBulkQuestion(\n          question: Question.fromJson({\n            ...question.toJson(),\n            'id': existing.id,\n          }),\n          existingStatus: existing.status,\n          reused: true,\n          qualityEvidence: qualityEvidence!,\n        ),""",
        'reused bulk item evidence',
    )
    qbs = replace_once(
        qbs,
        """      await _publishPreparedQuestion(\n        item.question,\n        existingStatus: item.existingStatus,\n      );""",
        """      await _publishPreparedQuestion(\n        item.question,\n        existingStatus: item.existingStatus,\n        qualityEvidence: item.qualityEvidence,\n      );""",
        'bulk publish evidence pass-through',
    )
    qbs = replace_once(
        qbs,
        """  Future<void> _publishPreparedQuestion(\n    Question question, {\n    required String? existingStatus,\n  }) async {\n    final normalizedStatus = existingStatus?.trim().toLowerCase() ?? '';""",
        """  Future<void> _publishPreparedQuestion(\n    Question question, {\n    required String? existingStatus,\n    required QuestionQualityEvidence qualityEvidence,\n  }) async {\n    requireDqg300PublicationPass(question, qualityEvidence);\n    final normalizedStatus = existingStatus?.trim().toLowerCase() ?? '';""",
        'private bulk recheck',
    )

    qbs = replace_once(
        qbs,
        """  Future<List<QuestionQualityIssue>> validateForPublication(\n    Question question,\n  ) async {\n    if (_normalizedStatus(question) != 'review') {""",
        """  Future<List<QuestionQualityIssue>> validateForPublication(\n    Question question, {\n    QuestionQualityEvidence? qualityEvidence,\n  }) async {\n    if (_normalizedStatus(question) != 'review') {""",
        'validateForPublication signature',
    )
    qbs = replace_once(
        qbs,
        """    final issues = validate(question);\n\n    if (issues.any((issue) => issue.isError)) {""",
        """    requireDqg300PublicationPass(question, qualityEvidence);\n    final issues = validate(question);\n\n    if (issues.any((issue) => issue.isError)) {""",
        'validateForPublication strict gate',
    )
    qbs = replace_once(
        qbs,
        """  Future<void> publish(Question question) async {\n    if (_normalizedStatus(question) != 'validated') {""",
        """  Future<void> publish(\n    Question question, {\n    QuestionQualityEvidence? qualityEvidence,\n  }) async {\n    if (_normalizedStatus(question) != 'validated') {""",
        'publish signature',
    )
    qbs = replace_once(
        qbs,
        """    final issues = validate(question);\n\n    if (issues.any((issue) => issue.isError)) {\n      throw StateError(issues.map((issue) => issue.message).join('\\n'));\n    }\n\n    final publishedQuestion = randomizeOptions(""",
        """    requireDqg300PublicationPass(question, qualityEvidence);\n    final issues = validate(question);\n\n    if (issues.any((issue) => issue.isError)) {\n      throw StateError(issues.map((issue) => issue.message).join('\\n'));\n    }\n\n    final publishedQuestion = randomizeOptions(""",
        'publish strict gate',
    )
    qbs = replace_once(
        qbs,
        """class _PreparedBulkQuestion {\n  final Question question;\n  final String? existingStatus;\n  final bool reused;\n\n  const _PreparedBulkQuestion({\n    required this.question,\n    required this.existingStatus,\n    required this.reused,\n  });\n}""",
        """class _PreparedBulkQuestion {\n  final Question question;\n  final String? existingStatus;\n  final bool reused;\n  final QuestionQualityEvidence qualityEvidence;\n\n  const _PreparedBulkQuestion({\n    required this.question,\n    required this.existingStatus,\n    required this.reused,\n    required this.qualityEvidence,\n  });\n}""",
        'prepared bulk evidence field',
    )
    qbs_path.write_text(qbs, encoding='utf-8')

    subprocess.run(
        ['dart', 'format', str(validator_path), str(qbs_path)],
        cwd=ROOT,
        check=True,
    )
    print('PASS: strict DQG300 superiority detector and publication gates applied')


if __name__ == '__main__':
    main()
