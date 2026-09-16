import 'package:exam_platform/features/learning_twin/integration/learning_twin_competency_guidance.dart';
import 'package:flutter/material.dart';

import '../../../models/study_content.dart';
import '../../../models/student_learning_progress.dart';
import '../../../services/student_learning_progress_service.dart';
import '../../../services/student_learning_progress_session_cache.dart';
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
/// Frozen learner hierarchy:
/// Competency -> Topic accordion -> Subtopic -> Learning content.
///
/// Topics remain concept-level navigation units. Subtopic progress remains the
/// persisted unit; topic completion is always derived from child subtopics.
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
  bool _topicSelectionInitialized = false;
  int _expandedTopicIndex = 0;

  final StudentLearningProgressService _progressService =
      const StudentLearningProgressService();

  Map<String, StudentSubtopicProgress> _progressBySubtopicId =
      <String, StudentSubtopicProgress>{};

  @override
  void initState() {
    super.initState();

    if (!_applyCachedProgress()) {
      _loadProgress();
    }
  }

  @override
  void didUpdateWidget(covariant StudyContentRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);

    final contentChanged =
        oldWidget.content.id != widget.content.id ||
        oldWidget.content.version != widget.content.version;

    final resumeTargetChanged =
        oldWidget.initialSubtopicId != widget.initialSubtopicId;

    if (contentChanged) {
      _topicSelectionInitialized = false;
      _expandedTopicIndex = 0;
      _resumeHandled = false;

      if (!_applyCachedProgress()) {
        _loadProgress();
      }
    } else if (resumeTargetChanged) {
      _resumeHandled = false;
    }
  }

  bool _applyCachedProgress() {
    final progress = StudentLearningProgressSessionCache.peek();

    if (progress == null) {
      return false;
    }

    _progressBySubtopicId = progress;

    if (!_topicSelectionInitialized) {
      _expandedTopicIndex = _preferredTopicIndex(progress);
      _topicSelectionInitialized = true;
    }

    return true;
  }

  Future<void> _loadProgress() async {
    final progress = await StudentLearningProgressSessionCache.load(
      loader: _progressService.loadAllProgress,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _progressBySubtopicId = progress;

      if (!_topicSelectionInitialized) {
        _expandedTopicIndex = _preferredTopicIndex(progress);
        _topicSelectionInitialized = true;
      }
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
    final topics = widget.content.topics;
    final subtopicCount = _orderedSubtopics().length;

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
                          _buildOverviewCard(
                            topicCount: topics.length,
                            subtopicCount: subtopicCount,
                          ),
                          const SizedBox(height: 16),
                          LearningTwinCompetencyGuidance(
                            domainId: widget.content.domainId,
                            competencyId: widget.content.competencyId,
                          ),
                          const SizedBox(height: 26),
                          _buildSectionHeader(topics.length),
                          const SizedBox(height: 14),
                          ...topics.asMap().entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _buildTopicAccordionCard(
                                context,
                                topic: entry.value,
                                topicIndex: entry.key,
                                totalTopics: topics.length,
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

    final subtopics = _orderedSubtopics();
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
        builder: (_) => StudySubtopicScreen(
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
                  'CSP11 \u2022 DOMAIN ${domain.toString().padLeft(2, '0')}',
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
                  'Competency ${widget.content.competencyNumber} \u2022 Choose a topic to explore its subtopics',
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
                      icon: StudyIcons.book,
                      label: 'TOPICS',
                      value: '${widget.content.topics.length}',
                    ),
                    _buildHeroStat(
                      icon: StudyIcons.subtopic,
                      label: 'SUBTOPICS',
                      value: '${_orderedSubtopics().length}',
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

  Widget _buildOverviewCard({
    required int topicCount,
    required int subtopicCount,
  }) {
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
                  '$topicCount ${topicCount == 1 ? 'topic' : 'topics'} \u2022 '
                  '$subtopicCount ${subtopicCount == 1 ? 'subtopic' : 'subtopics'}',
                  style: StudyTypography.subSectionTitle,
                ),
                const SizedBox(height: 5),
                Text(
                  'Open a topic to reveal its learning sections. Your progress '
                  'is tracked at subtopic level and topic completion is derived '
                  'automatically.',
                  style: StudyTypography.bodySecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(int topicCount) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOPICS & SUBTOPICS',
                style: StudyTypography.eyebrow.copyWith(
                  color: StudyColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text('Choose a topic', style: StudyTypography.sectionTitle),
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
            '$topicCount ${topicCount == 1 ? 'TOPIC' : 'TOPICS'}',
            style: StudyTypography.eyebrow.copyWith(
              color: StudyColors.textSecondary,
              fontSize: 9,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopicAccordionCard(
    BuildContext context, {
    required StudyTopic topic,
    required int topicIndex,
    required int totalTopics,
  }) {
    final isExpanded = _expandedTopicIndex == topicIndex;
    final subtopicCount = topic.subtopics.length;
    final completedCount = _completedSubtopicCount(topic);
    final completionRatio = _topicCompletionRatio(topic);
    final isCompleted = subtopicCount > 0 && completedCount == subtopicCount;

    return Container(
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(
          color: isExpanded
              ? StudyColors.primary.withValues(alpha: 0.34)
              : StudyColors.border,
          width: isExpanded ? 1.25 : 1,
        ),
        boxShadow: isExpanded ? StudyShadows.soft : const [],
      ),
      child: ClipRRect(
        borderRadius: StudyRadius.large,
        child: Column(
          children: [
            Material(
              color: isExpanded
                  ? StudyColors.primaryLight.withValues(alpha: 0.42)
                  : StudyColors.surface,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _topicSelectionInitialized = true;
                    _expandedTopicIndex = isExpanded ? -1 : topicIndex;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: StudyGradients.heroSoft,
                          borderRadius: StudyRadius.medium,
                        ),
                        child: Text(
                          'T${(topicIndex + 1).toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOPIC ${topicIndex + 1} OF $totalTopics',
                              style: StudyTypography.eyebrow.copyWith(
                                color: StudyColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              topic.title.trim().isEmpty
                                  ? 'Untitled Topic'
                                  : topic.title,
                              style: StudyTypography.subSectionTitle.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 7,
                              children: [
                                _buildMetaChip(
                                  '$subtopicCount '
                                  '${subtopicCount == 1 ? 'subtopic' : 'subtopics'}',
                                ),
                                if (subtopicCount > 0)
                                  _buildMetaChip(
                                    '$completedCount/$subtopicCount complete',
                                  ),
                                if (isCompleted)
                                  _buildStatusChip(
                                    label: 'Completed',
                                    icon: Icons.check_circle_rounded,
                                    foreground: const Color(0xFF1F8A4C),
                                    background: const Color(0xFFEAF8F0),
                                    border: const Color(0xFFB9E7CA),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isExpanded
                                ? StudyColors.primary
                                : StudyColors.primaryLight,
                            borderRadius: StudyRadius.medium,
                          ),
                          child: Icon(
                            Icons.expand_more_rounded,
                            color: isExpanded
                                ? Colors.white
                                : StudyColors.primary,
                            size: 23,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: !isExpanded
                  ? const SizedBox.shrink()
                  : Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                      color: StudyColors.surface,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          _buildTopicProgress(
                            completedCount: completedCount,
                            totalCount: subtopicCount,
                            ratio: completionRatio,
                          ),
                          if (subtopicCount > 0) ...[
                            const SizedBox(height: 16),
                            ...topic.subtopics.asMap().entries.map(
                              (entry) => Padding(
                                padding: EdgeInsets.only(
                                  bottom:
                                      entry.key == topic.subtopics.length - 1
                                      ? 0
                                      : 10,
                                ),
                                child: _buildSubtopicCard(
                                  context,
                                  subtopic: entry.value,
                                  topicIndex: topicIndex,
                                  subtopicIndex: entry.key,
                                  totalInTopic: subtopicCount,
                                ),
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 14),
                            Text(
                              'No subtopics are available in this topic yet.',
                              style: StudyTypography.bodySecondary,
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicProgress({
    required int completedCount,
    required int totalCount,
    required double ratio,
  }) {
    final percent = (ratio * 100).round();

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'TOPIC PROGRESS',
                    style: StudyTypography.eyebrow.copyWith(
                      color: StudyColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    totalCount == 0
                        ? 'No sections'
                        : '$completedCount of $totalCount complete',
                    style: StudyTypography.caption.copyWith(
                      color: StudyColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: StudyRadius.pillRadius,
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 7,
                  backgroundColor: StudyColors.surfaceSoft,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    StudyColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (totalCount > 0) ...[
          const SizedBox(width: 14),
          Container(
            constraints: const BoxConstraints(minWidth: 52),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: StudyColors.primaryLight,
              borderRadius: StudyRadius.medium,
              border: Border.all(
                color: StudyColors.primary.withValues(alpha: 0.12),
              ),
            ),
            child: Text(
              '$percent%',
              style: StudyTypography.caption.copyWith(
                color: StudyColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubtopicCard(
    BuildContext context, {
    required StudySubtopic subtopic,
    required int topicIndex,
    required int subtopicIndex,
    required int totalInTopic,
  }) {
    final blockCount = subtopic.blocks.length;
    final objectiveCount = subtopic.learningObjectives.length;
    final quizCount = _subtopicQuizCount(subtopic);
    final globalIndex = _globalSubtopicIndex(topicIndex, subtopicIndex);

    return Material(
      color: StudyColors.surfaceSoft,
      borderRadius: StudyRadius.medium,
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StudySubtopicScreen(
                content: widget.content,
                subtopicIndex: globalIndex,
                domainTitle: widget.domainTitle,
              ),
            ),
          );

          await _loadProgress();
        },
        borderRadius: StudyRadius.medium,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: StudyRadius.medium,
            border: Border.all(color: StudyColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: StudyColors.surface,
                  borderRadius: StudyRadius.small,
                  border: Border.all(color: StudyColors.border),
                ),
                child: Text(
                  '${subtopicIndex + 1}'.padLeft(2, '0'),
                  style: TextStyle(
                    color: StudyColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SUBTOPIC ${subtopicIndex + 1} OF $totalInTopic',
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
                        _buildMetaChip('$blockCount content blocks'),
                        _buildMetaChip('$objectiveCount objectives'),
                        if (quizCount > 0)
                          _buildMetaChip('$quizCount practice links'),
                        _buildProgressStatus(subtopic.id),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: StudyColors.primaryLight,
                  borderRadius: StudyRadius.medium,
                ),
                child: const Icon(
                  StudyIcons.next,
                  color: StudyColors.primary,
                  size: 19,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressStatus(String subtopicId) {
    final state =
        _progressBySubtopicId[subtopicId]?.state ??
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

  int _preferredTopicIndex(Map<String, StudentSubtopicProgress> progress) {
    final savedId = widget.initialSubtopicId;

    if (savedId != null && savedId.trim().isNotEmpty) {
      for (
        var topicIndex = 0;
        topicIndex < widget.content.topics.length;
        topicIndex++
      ) {
        final topic = widget.content.topics[topicIndex];

        if (topic.subtopics.any((subtopic) => subtopic.id == savedId)) {
          return topicIndex;
        }
      }
    }

    for (
      var topicIndex = 0;
      topicIndex < widget.content.topics.length;
      topicIndex++
    ) {
      final topic = widget.content.topics[topicIndex];

      if (topic.subtopics.isEmpty) {
        continue;
      }

      final hasIncomplete = topic.subtopics.any(
        (subtopic) =>
            (progress[subtopic.id]?.state ?? StudentLearningState.notStarted) !=
            StudentLearningState.completed,
      );

      if (hasIncomplete) {
        return topicIndex;
      }
    }

    return 0;
  }

  int _completedSubtopicCount(StudyTopic topic) {
    return topic.subtopics.where((subtopic) {
      return (_progressBySubtopicId[subtopic.id]?.state ??
              StudentLearningState.notStarted) ==
          StudentLearningState.completed;
    }).length;
  }

  double _topicCompletionRatio(StudyTopic topic) {
    if (topic.subtopics.isEmpty) {
      return 0;
    }

    return _completedSubtopicCount(topic) / topic.subtopics.length;
  }

  int _globalSubtopicIndex(int topicIndex, int subtopicIndex) {
    var index = subtopicIndex;

    for (var i = 0; i < topicIndex; i++) {
      index += widget.content.topics[i].subtopics.length;
    }

    return index;
  }

  List<StudySubtopic> _orderedSubtopics() {
    return [for (final topic in widget.content.topics) ...topic.subtopics];
  }

  int _quizCount() {
    return _orderedSubtopics().fold<int>(
      0,
      (sum, subtopic) => sum + _subtopicQuizCount(subtopic),
    );
  }

  int _subtopicQuizCount(StudySubtopic subtopic) {
    return subtopic.quizzes.length;
  }

  int _getDomainNumber(String domainId) {
    final match = RegExp(r'\d+').firstMatch(domainId);

    if (match == null) {
      return 0;
    }

    return int.tryParse(match.group(0)!) ?? 0;
  }
}
