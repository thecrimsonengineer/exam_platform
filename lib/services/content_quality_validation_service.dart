import '../models/content_quality_report.dart';

class ContentQualityValidationService {
  const ContentQualityValidationService();

  ContentQualityReport validate({
    required String title,
    required String content,
    required String competencyId,
    required String sourceId,
    int minimumCharacters = 80,
  }) {
    final issues = <ContentQualityIssue>[];

    if (title.trim().isEmpty) {
      issues.add(
        const ContentQualityIssue(
          code: 'MISSING_TITLE',
          message: 'A content title is required.',
          blocking: true,
        ),
      );
    }

    if (content.trim().isEmpty) {
      issues.add(
        const ContentQualityIssue(
          code: 'MISSING_CONTENT',
          message: 'Content text is required.',
          blocking: true,
        ),
      );
    } else if (content.trim().length < minimumCharacters) {
      issues.add(
        ContentQualityIssue(
          code: 'CONTENT_TOO_SHORT',
          message:
              'Content should contain at least $minimumCharacters characters.',
          blocking: true,
        ),
      );
    }

    if (competencyId.trim().isEmpty) {
      issues.add(
        const ContentQualityIssue(
          code: 'MISSING_COMPETENCY',
          message: 'A CSP11 competency mapping is required.',
          blocking: true,
        ),
      );
    }

    if (sourceId.trim().isEmpty) {
      issues.add(
        const ContentQualityIssue(
          code: 'MISSING_SOURCE',
          message: 'A source reference is required.',
          blocking: true,
        ),
      );
    }

    return ContentQualityReport(issues: issues);
  }
}
