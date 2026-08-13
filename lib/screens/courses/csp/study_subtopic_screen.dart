import 'package:flutter/material.dart';

import '../../../models/study_content.dart';
import '../../../models/student_learning_progress.dart';
import '../../../services/student_learning_progress_service.dart';
import '../../../theme/study/study_colors.dart';
import '../../../theme/study/study_gradients.dart';
import '../../../theme/study/study_icons.dart';
import '../../../theme/study/study_radius.dart';
import '../../../theme/study/study_shadows.dart';
import '../../../theme/study/study_spacing.dart';
import '../../../theme/study/study_typography.dart';
import '../../../widgets/csp/study_content/study_content_navigation.dart';
import '../../../widgets/csp/study_content/study_subtopic_renderer.dart';

/// Student-facing screen for one CSP competency subtopic.
///
/// Each subtopic is presented as its own screen so a competency does not
/// become one very long document. Previous/next navigation keeps the
/// learning flow continuous.
class StudySubtopicScreen extends StatefulWidget {
  final StudyContent content;
  final int subtopicIndex;
  final String? domainTitle;

  const StudySubtopicScreen({
    super.key,
    required this.content,
    required this.subtopicIndex,
    this.domainTitle,
  });

  @override
  State<StudySubtopicScreen> createState() => _StudySubtopicScreenState();
}

class _StudySubtopicScreenState extends State<StudySubtopicScreen> {
  final StudentLearningProgressService _progressService =
      const StudentLearningProgressService();

  late Future<StudentSubtopicProgress?> _progressFuture;

  @override
  void initState() {
    super.initState();
    _progressFuture = _openAndLoadProgress();
  }

  @override
  void didUpdateWidget(covariant StudySubtopicScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.content.id != widget.content.id ||
        oldWidget.content.version != widget.content.version ||
        oldWidget.subtopicIndex != widget.subtopicIndex) {
      setState(() {
        _progressFuture = _openAndLoadProgress();
      });
    }
  }

  Future<StudentSubtopicProgress?> _openAndLoadProgress() async {
    final subtopics = widget.content.subtopics;

    if (subtopics.isEmpty ||
        widget.subtopicIndex < 0 ||
        widget.subtopicIndex >= subtopics.length) {
      return null;
    }

    final subtopic = subtopics[widget.subtopicIndex];
    final domain = _getDomainNumber(widget.content.domainId);

    await _progressService.markInProgress(
      domainId: widget.content.domainId,
      domainNumber: domain,
      domainTitle: widget.domainTitle ?? '',
      competencyId: widget.content.competencyId,
      competencyTitle: widget.content.title,
      subtopicId: subtopic.id,
      subtopicTitle: subtopic.title,
      studyContentId: widget.content.id,
      studyContentVersion: widget.content.version,
    );

    return _progressService.loadSubtopicProgress(
      subtopicId: subtopic.id,
      expectedContentVersion: widget.content.version,
    );
  }

  Future<void> _completeSubtopic() async {
    final subtopics = widget.content.subtopics;

    if (subtopics.isEmpty ||
        widget.subtopicIndex < 0 ||
        widget.subtopicIndex >= subtopics.length) {
      return;
    }

    final subtopic = subtopics[widget.subtopicIndex];
    final domain = _getDomainNumber(widget.content.domainId);

    await _progressService.completeSubtopic(
      domainId: widget.content.domainId,
      domainNumber: domain,
      domainTitle: widget.domainTitle ?? '',
      competencyId: widget.content.competencyId,
      competencyTitle: widget.content.title,
      subtopicId: subtopic.id,
      subtopicTitle: subtopic.title,
      studyContentId: widget.content.id,
      studyContentVersion: widget.content.version,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _progressFuture = _progressService.loadSubtopicProgress(
        subtopicId: subtopic.id,
        expectedContentVersion: widget.content.version,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final subtopics = widget.content.subtopics;

    if (subtopics.isEmpty ||
        widget.subtopicIndex < 0 ||
        widget.subtopicIndex >= subtopics.length) {
      return const Scaffold(
        body: Center(child: Text('Study subtopic is unavailable.')),
      );
    }

    final subtopic = subtopics[widget.subtopicIndex];
    final domain = _getDomainNumber(widget.content.domainId);
    final hasPrevious = widget.subtopicIndex > 0;
    final hasNext = widget.subtopicIndex < subtopics.length - 1;
    final progress = (widget.subtopicIndex + 1) / subtopics.length;

    return Scaffold(
      backgroundColor: StudyColors.background,
      appBar: _buildAppBar(context, subtopic),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 900;

                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: 36,
                    left: isDesktop
                        ? StudySpacing.pageHorizontalDesktop
                        : StudySpacing.pageHorizontal,
                    right: isDesktop
                        ? StudySpacing.pageHorizontalDesktop
                        : StudySpacing.pageHorizontal,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: StudySpacing.maxContentWidth,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSubtopicHero(
                            subtopic: subtopic,
                            domain: domain,
                            index: widget.subtopicIndex,
                            total: subtopics.length,
                            isDesktop: isDesktop,
                          ),
                          const SizedBox(height: 24),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(isDesktop ? 28 : 20),
                            decoration: BoxDecoration(
                              color: StudyColors.surface,
                              borderRadius: StudyRadius.large,
                              border: Border.all(color: StudyColors.border),
                              boxShadow: StudyShadows.soft,
                            ),
                            child: StudySubtopicRenderer(
                              subtopic: subtopic,
                              domain: domain,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Phase 2: Subtopic completion.
                          FutureBuilder<StudentSubtopicProgress?>(
                            future: _progressFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox.shrink();
                              }

                              return _buildCompletionPanel(snapshot.data);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          StudyContentNavigation(
            progress: progress,
            previousLabel: hasPrevious
                ? 'Previous Subtopic'
                : 'Competency Overview',
            nextLabel: hasNext ? 'Next Subtopic' : 'Back to Competency',
            onPrevious: hasPrevious
                ? () => _openSubtopic(context, widget.subtopicIndex - 1)
                : () => Navigator.of(context).pop(),
            onNext: hasNext
                ? () => _openSubtopic(context, widget.subtopicIndex + 1)
                : () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionPanel(StudentSubtopicProgress? progress) {
    final completed = progress?.state == StudentLearningState.completed;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;

        final content = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: completed
                    ? const Color(0xFFD2F2DE)
                    : StudyColors.primaryLight,
                borderRadius: StudyRadius.medium,
              ),
              child: Icon(
                completed ? Icons.check_circle_rounded : Icons.flag_rounded,
                color: completed
                    ? const Color(0xFF1F8A4C)
                    : StudyColors.primary,
                size: 23,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    completed ? 'SUBTOPIC COMPLETED' : 'FINISH THIS SUBTOPIC',
                    style: StudyTypography.eyebrow.copyWith(
                      color: completed
                          ? const Color(0xFF1F8A4C)
                          : StudyColors.primary,
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    completed
                        ? 'This learning section is recorded as completed.'
                        : 'Mark this subtopic complete after you have finished studying it.',
                    style: StudyTypography.bodySecondary,
                  ),
                  if (completed && progress?.completedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Completed ${_formatCompletedDate(progress!.completedAt!)}',
                      style: StudyTypography.caption.copyWith(
                        color: const Color(0xFF4E6A59),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );

        final button = SizedBox(
          width: compact ? double.infinity : null,
          child: FilledButton.icon(
            onPressed: _completeSubtopic,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('COMPLETE SUBTOPIC'),
          ),
        );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: completed ? const Color(0xFFEAF8F0) : StudyColors.surface,
            borderRadius: StudyRadius.large,
            border: Border.all(
              color: completed ? const Color(0xFFB9E7CA) : StudyColors.border,
            ),
            boxShadow: completed ? null : StudyShadows.soft,
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    content,
                    if (!completed) ...[const SizedBox(height: 16), button],
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: content),
                    if (!completed) ...[const SizedBox(width: 16), button],
                  ],
                ),
        );
      },
    );
  }

  String _formatCompletedDate(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();

    return '$day/$month/$year';
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    StudySubtopic subtopic,
  ) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: StudyColors.surface,
      foregroundColor: StudyColors.textPrimary,
      titleSpacing: StudySpacing.pageHorizontal,
      leading: IconButton(
        tooltip: 'Back to Competency',
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_rounded, size: 21),
      ),
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: StudyColors.primaryLight,
              borderRadius: StudyRadius.small,
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              size: 19,
              color: StudyColors.primary,
            ),
          ),
          const SizedBox(width: StudySpacing.sm),
          Expanded(
            child: Text(
              subtopic.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: StudyTypography.cardTitle.copyWith(
                color: StudyColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtopicHero({
    required StudySubtopic subtopic,
    required int domain,
    required int index,
    required int total,
    required bool isDesktop,
  }) {
    final title = subtopic.title.trim().isEmpty
        ? 'Study Subtopic'
        : subtopic.title.trim();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: StudyGradients.hero,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: StudyShadows.soft,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isDesktop ? 30 : 22,
          isDesktop ? 30 : 24,
          isDesktop ? 30 : 22,
          isDesktop ? 28 : 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'DOMAIN ${domain.toString().padLeft(2, '0')}',
                  style: StudyTypography.eyebrow.copyWith(
                    color: Colors.white.withValues(alpha: 0.68),
                  ),
                ),
                const SizedBox(width: 9),
                Icon(
                  StudyIcons.next,
                  size: 15,
                  color: Colors.white.withValues(alpha: 0.42),
                ),
                const SizedBox(width: 9),
                Text(
                  'COMPETENCY ${widget.content.competencyNumber}',
                  style: StudyTypography.eyebrow.copyWith(
                    color: Colors.white.withValues(alpha: 0.68),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: StudyRadius.medium,
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              ),
              child: Text(
                '${index + 1}'.padLeft(2, '0'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: StudyTypography.heroTitle.copyWith(
                color: Colors.white,
                fontSize: isDesktop ? 34 : 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Subtopic ${index + 1} of $total',
              style: StudyTypography.bodyLarge.copyWith(
                color: Colors.white.withValues(alpha: 0.78),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSubtopic(BuildContext context, int index) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => StudySubtopicScreen(
          content: widget.content,
          subtopicIndex: index,
          domainTitle: widget.domainTitle,
        ),
      ),
    );
  }

  int _getDomainNumber(String domainId) {
    final match = RegExp(r'\d+').firstMatch(domainId);

    if (match == null) {
      return 0;
    }

    return int.tryParse(match.group(0)!) ?? 0;
  }
}
