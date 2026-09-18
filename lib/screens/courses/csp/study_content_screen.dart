import 'dart:async';

import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';

import '../../../models/study_content.dart';
import '../../../services/study_content_loader.dart';
import '../../../theme/study/study_colors.dart';
import '../../../theme/study/study_radius.dart';
import '../../../theme/study/study_spacing.dart';
import '../../../theme/study/study_typography.dart';
import '../../../widgets/csp/study_content/study_content_renderer.dart';

class StudyContentScreen extends StatefulWidget {
  final String domainId;
  final String competencyId;
  final String? domainTitle;

  final String? loadingTitle;

  final String? initialTopicId;
  final String? initialSubtopicId;

  const StudyContentScreen({
    super.key,
    required this.domainId,
    required this.competencyId,
    this.domainTitle,
    this.loadingTitle,
    this.initialTopicId,
    this.initialSubtopicId,
  });

  @override
  State<StudyContentScreen> createState() => _StudyContentScreenState();
}

class _StudyContentScreenState extends State<StudyContentScreen> {
  final StudyContentLoader _loader = const StudyContentLoader();

  late Future<StudyContent> _contentFuture;
  StudyContent? _visibleContent;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  @override
  void didUpdateWidget(covariant StudyContentScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.domainId != widget.domainId ||
        oldWidget.competencyId != widget.competencyId ||
        oldWidget.initialTopicId != widget.initialTopicId ||
        oldWidget.initialSubtopicId != widget.initialSubtopicId) {
      _loadContent();
    }
  }

  void _loadContent() {
    final sessionContent = _loader.peekSessionStudyContent(
      domainId: widget.domainId,
      competencyId: widget.competencyId,
    );

    if (sessionContent == null) {
      _visibleContent = null;
      _contentFuture = _loader.loadStudyContent(
        domainId: widget.domainId,
        competencyId: widget.competencyId,
      );
      return;
    }

    // P4A: render cloud-verified process memory in this very first build.
    // Do not wrap a RAM hit in Future.value()/FutureBuilder.
    _visibleContent = sessionContent;

    // Revalidate only this competency in the background.
    unawaited(
      _refreshSessionContent(
        visibleContent: sessionContent,
        domainId: widget.domainId,
        competencyId: widget.competencyId,
      ),
    );
  }

  Future<void> _refreshSessionContent({
    required StudyContent visibleContent,
    required String domainId,
    required String competencyId,
  }) async {
    try {
      final refreshed = await _loader.refreshStudyContent(
        domainId: domainId,
        competencyId: competencyId,
      );

      if (!mounted ||
          widget.domainId != domainId ||
          widget.competencyId != competencyId) {
        return;
      }

      final changed =
          refreshed.id != visibleContent.id ||
          refreshed.version != visibleContent.version;

      if (!changed) {
        return;
      }

      setState(() {
        _visibleContent = refreshed;
      });
    } catch (_) {
      // Current-session RAM content was already verified from the published
      // cloud boundary. A transient refresh failure must not blank the screen.
    }
  }

  void _retry() {
    setState(() {
      _visibleContent = null;
      _loadContent();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StudentGlassScaffold(
      backgroundColor: StudyColors.background,
      appBar: _buildAppBar(context),
      body: _visibleContent != null
          ? _buildStudyContent(context, _visibleContent!)
          : FutureBuilder<StudyContent>(
              future: _contentFuture,
              builder:
                  (BuildContext context, AsyncSnapshot<StudyContent> snapshot) {
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
      backgroundColor: StudyColors.surface,
      foregroundColor: StudyColors.textPrimary,
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
          Flexible(
            child: _visibleContent != null
                ? Text(
                    _visibleContent!.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StudyTypography.cardTitle.copyWith(
                      color: StudyColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : FutureBuilder<StudyContent>(
                    future: _contentFuture,
                    builder:
                        (
                          BuildContext context,
                          AsyncSnapshot<StudyContent> snapshot,
                        ) {
                          final title = snapshot.hasData
                              ? snapshot.data!.title
                              : widget.loadingTitle ?? 'Study Content';

                          return Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: StudyTypography.cardTitle.copyWith(
                              color: StudyColors.textPrimary,
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

    return StudyContentRenderer(
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
              child: StudentGlassSurface(
                padding: const EdgeInsets.all(StudySpacing.cardPaddingLarge),
                borderRadius: StudyRadius.large,
                tint: StudyColors.surface.withValues(alpha: 0.50),
                borderColor: StudyColors.border.withValues(alpha: 0.72),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: StudyColors.primaryLight,
                        borderRadius: StudyRadius.medium,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              StudyColors.primary,
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
                        color: StudyColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: StudySpacing.xs),
                    Text(
                      'Loading the latest structured learning content.',
                      textAlign: TextAlign.center,
                      style: StudyTypography.bodySecondary.copyWith(
                        color: StudyColors.textSecondary,
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
          child: StudentGlassSurface(
            padding: const EdgeInsets.all(StudySpacing.cardPaddingLarge),
            borderRadius: StudyRadius.large,
            tint: StudyColors.surface.withValues(alpha: 0.50),
            borderColor: StudyColors.border.withValues(alpha: 0.72),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: StudyColors.dangerLight,
                    borderRadius: StudyRadius.medium,
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    size: 30,
                    color: StudyColors.danger,
                  ),
                ),
                const SizedBox(height: StudySpacing.lg),
                Text(
                  'Unable to load study content',
                  textAlign: TextAlign.center,
                  style: StudyTypography.cardTitle.copyWith(
                    color: StudyColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: StudySpacing.xs),
                Text(
                  'The requested competency could not be loaded. Please try again.',
                  textAlign: TextAlign.center,
                  style: StudyTypography.bodySecondary.copyWith(
                    color: StudyColors.textSecondary,
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
          child: StudentGlassSurface(
            padding: const EdgeInsets.all(StudySpacing.cardPaddingLarge),
            borderRadius: StudyRadius.large,
            tint: StudyColors.surface.withValues(alpha: 0.50),
            borderColor: StudyColors.border.withValues(alpha: 0.72),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: StudyColors.surfaceSoft,
                    borderRadius: StudyRadius.medium,
                  ),
                  child: const Icon(
                    Icons.menu_book_outlined,
                    size: 30,
                    color: StudyColors.textMuted,
                  ),
                ),
                const SizedBox(height: StudySpacing.lg),
                Text(
                  'Study content unavailable',
                  textAlign: TextAlign.center,
                  style: StudyTypography.cardTitle.copyWith(
                    color: StudyColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: StudySpacing.xs),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: StudyTypography.bodySecondary.copyWith(
                    color: StudyColors.textSecondary,
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
