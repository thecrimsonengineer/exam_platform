import '../services/question_quality_validator.dart';

/// Structured result of validating a CSP11 question.
///
/// H0.1 introduces a single report object between the validation engine
/// and its callers. Detailed field/code/severity metadata will be added
/// in H0.2.
class QuestionValidationReport {
  final List<QuestionQualityIssue> issues;

  const QuestionValidationReport({
    required this.issues,
  });

  /// True when no blocking validation errors exist.
  bool get passed => errors.isEmpty;

  /// True when at least one blocking validation error exists.
  bool get blocked => errors.isNotEmpty;

  /// Blocking validation errors.
  List<QuestionQualityIssue> get errors =>
      issues.where((issue) => issue.isError).toList(growable: false);

  /// Non-blocking quality warnings.
  List<QuestionQualityIssue> get warnings =>
      issues.where((issue) => !issue.isError).toList(growable: false);

  int get errorCount => errors.length;

  int get warningCount => warnings.length;

  int get issueCount => issues.length;

  /// Short summary suitable for Admin Studio.
  String get summary {
    if (blocked) {
      return 'BLOCKED • $issueCount ISSUE${issueCount == 1 ? '' : 'S'}';
    }

    if (warningCount > 0) {
      return 'PASSED • $warningCount WARNING${warningCount == 1 ? '' : 'S'}';
    }

    return 'PASSED • NO ISSUES';
  }
}
