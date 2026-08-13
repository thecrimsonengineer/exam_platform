import 'package:flutter/material.dart';

import '../../../models/study_content.dart';
import '../../../models/student_learning_progress.dart';
import '../../../services/student_learning_progress_service.dart';
import '../../../screens/courses/csp/study_subtopic_screen.dart';
import '../../../theme/study/study_colors.dart';
import '../../../theme/study/study_gradients.dart';
import '../../../theme/study/study_icons.dart';
import '../../../theme/study/study_radius.dart';
import '../../../theme/study/study_shadows.dart';
import '../../../theme/study/study_spacing.dart';
import '../../../theme/study/study_typography.dart';

/// Premium student-facing renderer for a CSP competency index.
///
/// The competency screen remains an overview and subtopic launcher.
///
/// When [initialSubtopicId] is supplied, the saved subtopic is opened
/// automatically. Otherwise the normal competency overview is shown.
class StudyContentRenderer extends StatefulWidget {
  final StudyContent content;

  final String? initialSubtopicId;
  final String? domainTitle;

  const StudyContentRenderer({
    super.key,
    required this.content,
    this.initialSubtopicId,
    this.domainTitle,
  });

  @override
  State<StudyContentRenderer> createState() => _StudyContentRendererState();
}

class _StudyContentRendererState extends State<StudyContentRenderer> {
  bool _resumeHandled = false;

  final StudentLearningProgressService _progressService =
      const StudentLearningProgressService();

  Map<String, StudentSubtopicProgress> _progressBySubtopicId =
      <String, StudentSubtopicProgress>{};

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  @override
  void didUpdateWidget(covariant StudyContentRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.content.id != widget.content.id ||
        oldWidget.content.version != widget.content.version) {
      _loadProgress();
    }
  }

  Future<void> _loadProgress() async {
    final progress = await _progressService.loadAllProgress();

    if (!mounted) {
      return;
    }

    setState(() {
      _progressBySubtopicId = progress;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _openSavedSubtopicIfRequired();
  }

  @override
  Widget build(BuildContext context) {
    final domain = _getDomainNumber(widget.content.domainId);

    final subtopics = widget.content.subtopics;

    return Container(
      color: StudyColors.background,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildHero(domain),
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 900;

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: StudySpacing.maxContentWidth,
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        isDesktop
                            ? StudySpacing.pageHorizontalDesktop
                            : StudySpacing.pageHorizontal,
                        28,
                        isDesktop
                            ? StudySpacing.pageHorizontalDesktop
                            : StudySpacing.pageHorizontal,
                        48,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildOverviewCard(subtopics.length),
                          const SizedBox(height: 26),
                          _buildSectionHeader(subtopics.length),
                          const SizedBox(height: 14),
                          ...subtopics.asMap().entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _buildSubtopicCard(
                                context,
                                subtopic: entry.value,
                                index: entry.key,
                                total: subtopics.length,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSavedSubtopicIfRequired() async {
    if (_resumeHandled) {
      return;
    }

    final savedId = widget.initialSubtopicId;

    if (savedId == null || savedId.trim().isEmpty) {
      _resumeHandled = true;
      return;
    }

    final subtopics = widget.content.subtopics;

    final index = subtopics.indexWhere(
      (subtopic) => _subtopicId(subtopic) == savedId,
    );

    _resumeHandled = true;

    if (index < 0) {
      return;
    }

    await Future<void>.delayed(Duration.zero);

    if (!mounted) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            StudySubtopicScreen(
            content: widget.content,
            subtopicIndex: index,
            domainTitle: widget.domainTitle,
          ),
      ),
    );
  }

  String? _subtopicId(StudySubtopic subtopic) {
    try {
      final dynamic value = subtopic.id;

      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    } catch (_) {}

    return null;
  }

  Widget _buildHero(int domain) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: StudyGradients.hero),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: StudySpacing.maxContentWidth,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              StudySpacing.pageHorizontalDesktop,
              36,
              StudySpacing.pageHorizontalDesktop,
              38,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CSP11 • DOMAIN ${domain.toString().padLeft(2, '0')}',
                  style: StudyTypography.eyebrow.copyWith(
                    color: Colors.white.withValues(alpha: 0.68),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  widget.content.title,
                  style: StudyTypography.heroTitle.copyWith(
                    color: Colors.white,
                    fontSize: 40,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  'Competency ${widget.content.competencyNumber} • Choose a subtopic to begin studying',
                  style: StudyTypography.bodyLarge.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(height: 26),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildHeroStat(
                      icon: StudyIcons.subtopic,
                      label: 'SUBTOPICS',
                      value: '${widget.content.subtopics.length}',
                    ),
                    _buildHeroStat(
                      icon: StudyIcons.book,
                      label: 'CONTENT TOPICS',
                      value: '${_topicCount()}',
                    ),
                    _buildHeroStat(
                      icon: StudyIcons.quiz,
                      label: 'PRACTICE LINKS',
                      value: '${_quizCount()}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: StudyRadius.medium,
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19, color: Colors.white.withValues(alpha: 0.88)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: StudyColors.primaryLight,
              borderRadius: StudyRadius.medium,
            ),
            child: const Icon(
              StudyIcons.study,
              color: StudyColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR STUDY PATH',
                  style: StudyTypography.eyebrow.copyWith(
                    color: StudyColors.primary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$count ${count == 1 ? 'subtopic' : 'subtopics'}',
                  style: StudyTypography.subSectionTitle,
                ),
                const SizedBox(height: 5),
                Text(
                  'Each subtopic opens on its own study screen. Use Previous and Next to move through the competency without returning to this page.',
                  style: StudyTypography.bodySecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(int count) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LEARNING SECTIONS',
                style: StudyTypography.eyebrow.copyWith(
                  color: StudyColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text('Choose a subtopic', style: StudyTypography.sectionTitle),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: StudyColors.surface,
            borderRadius: StudyRadius.pillRadius,
            border: Border.all(color: StudyColors.border),
          ),
          child: Text(
            '$count ${count == 1 ? 'SECTION' : 'SECTIONS'}',
            style: StudyTypography.eyebrow.copyWith(
              color: StudyColors.textSecondary,
              fontSize: 9,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubtopicCard(
    BuildContext context, {
    required StudySubtopic subtopic,
    required int index,
    required int total,
  }) {
    final topicCount = subtopic.mainContent.length;

    final objectiveCount = subtopic.learningObjectives.length;

    final quizCount = _subtopicQuizCount(subtopic);

    return Material(
      color: StudyColors.surface,
      borderRadius: StudyRadius.large,
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StudySubtopicScreen(
                content: widget.content,
                subtopicIndex: index,
                domainTitle: widget.domainTitle,
              ),
            ),
          );

          await _loadProgress();
        },
        borderRadius: StudyRadius.large,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: StudyRadius.large,
            border: Border.all(color: StudyColors.border),
            boxShadow: StudyShadows.soft,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: StudyGradients.heroSoft,
                  borderRadius: StudyRadius.medium,
                ),
                child: Text(
                  '${index + 1}'.padLeft(2, '0'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SUBTOPIC ${index + 1} OF $total',
                      style: StudyTypography.eyebrow.copyWith(
                        color: StudyColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtopic.title.isEmpty
                          ? 'Untitled Subtopic'
                          : subtopic.title,
                      style: StudyTypography.subSectionTitle,
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 8,
                      runSpacing: 7,
                      children: [
                        _buildMetaChip('$topicCount topics'),
                        _buildMetaChip('$objectiveCount objectives'),
                          if (quizCount > 0)
                          _buildMetaChip('$quizCount practice links'),
                        _buildProgressStatus(subtopic.id),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: StudyColors.primaryLight,
                  borderRadius: StudyRadius.medium,
                ),
                child: const Icon(
                  StudyIcons.next,
                  color: StudyColors.primary,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressStatus(String subtopicId) {
    final state = _progressBySubtopicId[subtopicId]?.state ??
        StudentLearningState.notStarted;

    switch (state) {
      case StudentLearningState.completed:
        return _buildStatusChip(
          label: 'Completed',
          icon: Icons.check_circle_rounded,
          foreground: const Color(0xFF1F8A4C),
          background: const Color(0xFFEAF8F0),
          border: const Color(0xFFB9E7CA),
        );
      case StudentLearningState.inProgress:
        return _buildStatusChip(
          label: 'In Progress',
          icon: Icons.play_circle_outline_rounded,
          foreground: StudyColors.primary,
          background: StudyColors.primaryLight,
          border: StudyColors.primary.withValues(alpha: 0.16),
        );
      case StudentLearningState.notStarted:
        return _buildStatusChip(
          label: 'Not Started',
          icon: Icons.radio_button_unchecked_rounded,
          foreground: StudyColors.textSecondary,
          background: StudyColors.surfaceSoft,
          border: StudyColors.border,
        );
    }
  }

  Widget _buildStatusChip({
    required String label,
    required IconData icon,
    required Color foreground,
    required Color background,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: StudyRadius.pillRadius,
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: 5),
          Text(
            label,
            style: StudyTypography.caption.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: StudyColors.surfaceSoft,
        borderRadius: StudyRadius.pillRadius,
        border: Border.all(color: StudyColors.border),
      ),
      child: Text(
        label,
        style: StudyTypography.caption.copyWith(
          color: StudyColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  int _topicCount() {
    return widget.content.subtopics.fold<int>(
      0,
      (sum, subtopic) => sum + subtopic.mainContent.length,
    );
  }

  int _quizCount() {
    return widget.content.subtopics.fold<int>(
      0,
      (sum, subtopic) => sum + _subtopicQuizCount(subtopic),
    );
  }

  int _subtopicQuizCount(StudySubtopic subtopic) {
    return subtopic.quizzes.length +
        subtopic.mainContent.fold<int>(
          0,
          (sum, topic) => sum + topic.quizzes.length,
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
