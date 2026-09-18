import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';

import '../../../models/study_content.dart';
import '../../../services/study_content_loader.dart';
import '../../../theme/study/study_colors_dark.dart';
import '../../../theme/study/study_radius.dart';
import '../../../theme/study/study_shadows.dart';
import '../../../theme/study/study_spacing.dart';
import '../../../theme/study/study_typography.dart';
import '../../../widgets/csp/study_content/study_content_renderer_dark.dart';

class DarkStudyContentScreen extends StatefulWidget {
  final String domainId;
  final String competencyId;
  final String? domainTitle;

  final String? loadingTitle;

  final String? initialTopicId;
  final String? initialSubtopicId;

  const DarkStudyContentScreen({
    super.key,
    required this.domainId,
    required this.competencyId,
    this.domainTitle,
    this.loadingTitle,
    this.initialTopicId,
    this.initialSubtopicId,
  });

  @override
  State<DarkStudyContentScreen> createState() => _DarkStudyContentScreenState();
}

class _DarkStudyContentScreenState extends State<DarkStudyContentScreen> {
  final StudyContentLoader _loader = const StudyContentLoader();

  late Future<StudyContent> _contentFuture;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  @override
  void didUpdateWidget(covariant DarkStudyContentScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.domainId != widget.domainId ||
        oldWidget.competencyId != widget.competencyId ||
        oldWidget.initialTopicId != widget.initialTopicId ||
        oldWidget.initialSubtopicId != widget.initialSubtopicId) {
      _loadContent();
    }
  }

  void _loadContent() {
    _contentFuture = _loader.loadStudyContent(
      domainId: widget.domainId,
      competencyId: widget.competencyId,
    );
  }

  void _retry() {
    setState(_loadContent);
  }

  @override
  Widget build(BuildContext context) {
    return StudentGlassScaffold(
      backgroundColor: DarkStudyColors.background,
      appBar: _buildAppBar(context),
      body: FutureBuilder<StudyContent>(
        future: _contentFuture,
        builder: (BuildContext context, AsyncSnapshot<StudyContent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState(context);
          }

          if (snapshot.hasError) {
            return _buildErrorState(context, snapshot.error);
          }

          if (!snapshot.hasData) {
            return _buildEmptyState(context);
          }

          return _buildStudyContent(context, snapshot.data!);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: DarkStudyColors.surface,
      foregroundColor: DarkStudyColors.textPrimary,
      centerTitle: false,
      titleSpacing: StudySpacing.pageHorizontal,
      leading: IconButton(
        tooltip: 'Back',
        onPressed: () {
          Navigator.of(context).pop();
        },
        icon: const Icon(Icons.arrow_back_rounded, size: 21),
      ),
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: DarkStudyColors.primaryLight,
              borderRadius: StudyRadius.small,
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              size: 19,
              color: DarkStudyColors.primary,
            ),
          ),
          const SizedBox(width: StudySpacing.sm),
          Flexible(
            child: FutureBuilder<StudyContent>(
              future: _contentFuture,
              builder:
                  (BuildContext context, AsyncSnapshot<StudyContent> snapshot) {
                    final title = snapshot.hasData
                        ? snapshot.data!.title
                        : widget.loadingTitle ?? 'Study Content';

                    return Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StudyTypography.cardTitle.copyWith(
                        color: DarkStudyColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyContent(BuildContext context, StudyContent content) {
    final hasSubtopics = content.topics.any(
      (topic) => topic.subtopics.isNotEmpty,
    );

    if (!hasSubtopics) {
      return _buildEmptyState(
        context,
        message: 'This competency does not contain any study content yet.',
      );
    }

    return DarkStudyContentRenderer(
      content: content,
      initialTopicId: widget.initialTopicId,
      initialSubtopicId: widget.initialSubtopicId,
      domainTitle: widget.domainTitle,
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        return Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop
                  ? StudySpacing.pageHorizontalDesktop
                  : StudySpacing.pageHorizontal,
              vertical: StudySpacing.xxxl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Container(
                padding: const EdgeInsets.all(StudySpacing.cardPaddingLarge),
                decoration: BoxDecoration(
                  color: DarkStudyColors.surface,
                  borderRadius: StudyRadius.large,
                  border: Border.all(color: DarkStudyColors.border),
                  boxShadow: StudyShadows.soft,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: DarkStudyColors.primaryLight,
                        borderRadius: StudyRadius.medium,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              DarkStudyColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: StudySpacing.lg),
                    Text(
                      'Preparing your study content',
                      textAlign: TextAlign.center,
                      style: StudyTypography.cardTitle.copyWith(
                        color: DarkStudyColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: StudySpacing.xs),
                    Text(
                      'Loading the latest structured learning content.',
                      textAlign: TextAlign.center,
                      style: StudyTypography.bodySecondary.copyWith(
                        color: DarkStudyColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context, Object? error) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(StudySpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Container(
            padding: const EdgeInsets.all(StudySpacing.cardPaddingLarge),
            decoration: BoxDecoration(
              color: DarkStudyColors.surface,
              borderRadius: StudyRadius.large,
              border: Border.all(color: DarkStudyColors.border),
              boxShadow: StudyShadows.soft,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: DarkStudyColors.dangerLight,
                    borderRadius: StudyRadius.medium,
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    size: 30,
                    color: DarkStudyColors.danger,
                  ),
                ),
                const SizedBox(height: StudySpacing.lg),
                Text(
                  'Unable to load study content',
                  textAlign: TextAlign.center,
                  style: StudyTypography.cardTitle.copyWith(
                    color: DarkStudyColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: StudySpacing.xs),
                Text(
                  'The requested competency could not be loaded. Please try again.',
                  textAlign: TextAlign.center,
                  style: StudyTypography.bodySecondary.copyWith(
                    color: DarkStudyColors.textSecondary,
                  ),
                ),
                const SizedBox(height: StudySpacing.lg),
                FilledButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh_rounded, size: 19),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    String message = 'No study content is available.',
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(StudySpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Container(
            padding: const EdgeInsets.all(StudySpacing.cardPaddingLarge),
            decoration: BoxDecoration(
              color: DarkStudyColors.surface,
              borderRadius: StudyRadius.large,
              border: Border.all(color: DarkStudyColors.border),
              boxShadow: StudyShadows.soft,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: DarkStudyColors.surfaceSoft,
                    borderRadius: StudyRadius.medium,
                  ),
                  child: const Icon(
                    Icons.menu_book_outlined,
                    size: 30,
                    color: DarkStudyColors.textMuted,
                  ),
                ),
                const SizedBox(height: StudySpacing.lg),
                Text(
                  'Study content unavailable',
                  textAlign: TextAlign.center,
                  style: StudyTypography.cardTitle.copyWith(
                    color: DarkStudyColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: StudySpacing.xs),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: StudyTypography.bodySecondary.copyWith(
                    color: DarkStudyColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
