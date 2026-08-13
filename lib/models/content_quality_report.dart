class ContentQualityIssue {
  final String code;
  final String message;
  final bool blocking;

  const ContentQualityIssue({
    required this.code,
    required this.message,
    required this.blocking,
  });
}

class ContentQualityReport {
  final List<ContentQualityIssue> issues;

  const ContentQualityReport({
    required this.issues,
  });

  bool get passed =>
      issues.every((issue) => !issue.blocking);
}
