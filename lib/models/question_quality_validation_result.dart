enum QuestionQualityStatus { pass, block }

class DqgRuleResult {
  final String id;
  final bool passed;
  final String message;

  const DqgRuleResult({
    required this.id,
    required this.passed,
    required this.message,
  });
}

class QuestionQualityValidationResult {
  final QuestionQualityStatus status;
  final int dqs;
  final Map<String, int> dqsCategories;
  final List<DqgRuleResult> rules;
  final int blockCount;
  final int failCount;
  final int warningCount;

  const QuestionQualityValidationResult({
    required this.status,
    required this.dqs,
    required this.dqsCategories,
    required this.rules,
    required this.blockCount,
    required this.failCount,
    required this.warningCount,
  });

  bool get isPublishable =>
      status == QuestionQualityStatus.pass &&
      dqs == 100 &&
      blockCount == 0 &&
      failCount == 0 &&
      warningCount == 0 &&
      rules.length == 64 &&
      rules.every((rule) => rule.passed);

  DqgRuleResult rule(String id) {
    return rules.firstWhere(
      (rule) => rule.id == id,
      orElse: () => throw StateError('Unknown DQG rule: $id'),
    );
  }
}
