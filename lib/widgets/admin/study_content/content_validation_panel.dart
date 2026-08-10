import 'package:flutter/material.dart';

import '../../../models/study_content.dart';
import '../../../services/study_content/content_import_service.dart';
import '../../../services/study_content/content_validator.dart';
import '../../../theme/study/study_colors.dart';
import '../../../theme/study/study_radius.dart';
import '../../../theme/study/study_shadows.dart';
import '../../../theme/study/study_typography.dart';

class ContentValidationPanel extends StatelessWidget {
  final StudyContent? content;

  const ContentValidationPanel({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final studyContent = content;

    if (studyContent == null) {
      return _emptyState();
    }

    final issues = const ContentValidator().validate(studyContent);

    final errors = issues
        .where((item) => item.severity == ContentImportIssueSeverity.error)
        .toList();

    final warnings = issues
        .where((item) => item.severity == ContentImportIssueSeverity.warning)
        .toList();

    final ready = errors.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(ready),

        const SizedBox(height: 24),

        _summaryCard(
          ready: ready,
          errors: errors.length,
          warnings: warnings.length,
        ),

        const SizedBox(height: 20),

        _sectionCard(
          title: 'STRUCTURE',
          icon: Icons.account_tree_rounded,
          child: _structureChecks(studyContent),
        ),

        const SizedBox(height: 18),

        _sectionCard(
          title: 'IDENTIFIERS',
          icon: Icons.fingerprint_rounded,
          child: _identifierChecks(studyContent),
        ),

        const SizedBox(height: 18),

        _sectionCard(
          title: 'ISSUES',
          icon: Icons.fact_check_rounded,
          child: issues.isEmpty
              ? _issueRow(
                  severity: null,
                  message: 'No validation issues were detected.',
                )
              : Column(children: issues.map(_issueWidget).toList()),
        ),
      ],
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _heading(bool ready) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'VALIDATION',
          style: StudyTypography.eyebrow.copyWith(color: StudyColors.primary),
        ),

        const SizedBox(height: 6),

        Text(
          'Content Validation',
          style: StudyTypography.heroTitle.copyWith(
            color: StudyColors.textPrimary,
            fontSize: 30,
          ),
        ),

        const SizedBox(height: 7),

        Text(
          ready
              ? 'The imported competency has passed the structural validation gate.'
              : 'Resolve the errors below before this competency can be considered publish-ready.',
          style: StudyTypography.bodySecondary.copyWith(fontSize: 14.5),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _summaryCard({
    required bool ready,
    required int errors,
    required int warnings,
  }) {
    final color = ready ? StudyColors.success : StudyColors.danger;

    final background = ready
        ? StudyColors.successLight
        : StudyColors.dangerLight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: background,
        borderRadius: StudyRadius.large,
        border: Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: StudyShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: StudyRadius.medium,
            ),
            child: Icon(
              ready ? Icons.verified_rounded : Icons.error_outline_rounded,
              color: color,
              size: 25,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ready ? 'VALIDATION PASSED' : 'ACTION REQUIRED',
                  style: StudyTypography.cardTitle.copyWith(color: color),
                ),

                const SizedBox(height: 4),

                Text(
                  ready
                      ? 'No blocking structural errors were found.'
                      : 'Publishing must remain blocked until errors are fixed.',
                  style: StudyTypography.bodySecondary,
                ),
              ],
            ),
          ),

          _countChip(value: errors, label: 'Errors', color: StudyColors.danger),

          const SizedBox(width: 8),

          _countChip(
            value: warnings,
            label: 'Warnings',
            color: StudyColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _countChip({
    required int value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: StudyColors.surface.withValues(alpha: 0.82),
        borderRadius: StudyRadius.pillRadius,
      ),
      child: Text(
        '$value $label',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: StudyColors.surfaceSoft,
              border: Border(bottom: BorderSide(color: StudyColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: StudyColors.primaryLight,
                    borderRadius: StudyRadius.medium,
                  ),
                  child: Icon(icon, color: StudyColors.primary, size: 19),
                ),

                const SizedBox(width: 11),

                Text(title, style: StudyTypography.subSectionTitle),
              ],
            ),
          ),

          Padding(padding: const EdgeInsets.all(20), child: child),
        ],
      ),
    );
  }

  // ============================================================
  // STRUCTURE CHECKS
  // ============================================================

  Widget _structureChecks(StudyContent content) {
    final mainTopics = content.subtopics.fold<int>(
      0,
      (sum, item) => sum + item.mainContent.length,
    );

    final blocks = content.subtopics.fold<int>(
      0,
      (sum, subtopic) =>
          sum +
          subtopic.mainContent.fold<int>(
            0,
            (topicSum, topic) => topicSum + topic.blocks.length,
          ),
    );

    return Column(
      children: [
        _passRow('Competency exists', content.title.trim().isNotEmpty),

        _passRow('Subtopics detected', content.subtopics.isNotEmpty),

        _passRow('Main content topics', mainTopics > 0),

        _passRow('Content blocks', blocks > 0),
      ],
    );
  }

  // ============================================================
  // IDENTIFIER CHECKS
  // ============================================================

  Widget _identifierChecks(StudyContent content) {
    final subtopicIds = content.subtopics
        .map((item) => item.id)
        .where((item) => item.trim().isNotEmpty)
        .toSet();

    return Column(
      children: [
        _passRow('Competency ID', content.competencyId.trim().isNotEmpty),

        _passRow(
          'Subtopic IDs',
          subtopicIds.length == content.subtopics.length,
        ),

        _passRow(
          'Topic IDs',
          content.subtopics.every(
            (subtopic) =>
                subtopic.mainContent
                    .map((topic) => topic.id)
                    .where((id) => id.trim().isNotEmpty)
                    .length ==
                subtopic.mainContent.length,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PASS / CHECK ROW
  // ============================================================

  Widget _passRow(String label, bool passed) {
    final color = passed ? StudyColors.success : StudyColors.danger;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle_rounded : Icons.error_rounded,
            size: 19,
            color: color,
          ),

          const SizedBox(width: 10),

          Expanded(child: Text(label, style: StudyTypography.body)),

          Text(
            passed ? 'PASS' : 'CHECK',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ISSUE WIDGET
  // ============================================================

  Widget _issueWidget(ContentImportIssue issue) {
    final isError = issue.severity == ContentImportIssueSeverity.error;

    return _issueRow(
      severity: isError ? StudyColors.danger : StudyColors.warning,
      message: issue.message,
      path: issue.path,
    );
  }

  Widget _issueRow({
    required Color? severity,
    required String message,
    String? path,
  }) {
    final color = severity ?? StudyColors.success;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.055),
        borderRadius: StudyRadius.medium,
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            severity == null
                ? Icons.check_circle_rounded
                : severity == StudyColors.danger
                ? Icons.error_rounded
                : Icons.warning_rounded,
            color: color,
            size: 18,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: StudyTypography.body),

                if (path != null && path.isNotEmpty) ...[
                  const SizedBox(height: 4),

                  Text(
                    path,
                    style: StudyTypography.eyebrow.copyWith(
                      color: StudyColors.textSecondary,
                      fontSize: 9,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.verified_rounded, size: 44, color: StudyColors.primary),

          SizedBox(height: 14),

          Text(
            'Import content before validating',
            style: StudyTypography.cardTitle,
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 6),

          Text(
            'The validation gate works on the parsed StudyContent model.',
            style: StudyTypography.bodySecondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
