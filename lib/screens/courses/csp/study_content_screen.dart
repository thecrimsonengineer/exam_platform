import 'package:flutter/material.dart';

import '../../../models/study_content.dart';
import '../../../services/study_content_loader.dart';
import '../../../theme/study/study_colors.dart';
import '../../../theme/study/study_radius.dart';
import '../../../theme/study/study_shadows.dart';
import '../../../theme/study/study_spacing.dart';
import '../../../theme/study/study_typography.dart';
import '../../../widgets/csp/study_content/study_content_renderer.dart';

/// Production student-facing screen for CSP Study Content.
///
/// Responsibilities:
/// - Load a competency through StudyContentLoader.
/// - Handle loading, error, and empty states.
/// - Provide the student-facing page shell.
/// - Pass the loaded StudyContent to StudyContentRenderer.
///
/// This screen intentionally contains no content-rendering logic.
/// StudyContentRenderer remains responsible for displaying the
/// structured learning content.
class StudyContentScreen extends StatefulWidget {
  final String domainId;
  final String competencyId;

  /// Optional title displayed while the content is loading.
  final String? loadingTitle;

  const StudyContentScreen({
    super.key,
    required this.domainId,
    required this.competencyId,
    this.loadingTitle,
  });

  @override
  State<StudyContentScreen> createState() => _StudyContentScreenState();
}

class _StudyContentScreenState extends State<StudyContentScreen> {
  final StudyContentLoader _loader = const StudyContentLoader();

  late Future<StudyContent> _contentFuture;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  @override
  void didUpdateWidget(covariant StudyContentScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.domainId != widget.domainId ||
        oldWidget.competencyId != widget.competencyId) {
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
    return Scaffold(
      backgroundColor: StudyColors.background,
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
      backgroundColor: StudyColors.surface,
      foregroundColor: StudyColors.textPrimary,
      centerTitle: false,
      titleSpacing: StudySpacing.pageHorizontal,
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
    if (content.subtopics.isEmpty) {
      return _buildEmptyState(
        context,
        message: 'This competency does not contain any study content yet.',
      );
    }

    return StudyContentRenderer(content: content);
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
                  color: StudyColors.surface,
                  borderRadius: StudyRadius.large,
                  border: Border.all(color: StudyColors.border),
                  boxShadow: StudyShadows.soft,
                ),
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
              constraints: const BoxConstraints(maxWidth: 680),
              child: Container(
                padding: const EdgeInsets.all(StudySpacing.cardPaddingLarge),
                decoration: BoxDecoration(
                  color: StudyColors.surface,
                  borderRadius: StudyRadius.large,
                  border: Border.all(color: StudyColors.border),
                  boxShadow: StudyShadows.soft,
                ),
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
                      'The requested competency could not be loaded. '
                      'Please try again.',
                      textAlign: TextAlign.center,
                      style: StudyTypography.bodySecondary.copyWith(
                        color: StudyColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: StudySpacing.lg),
                    _buildErrorDetails(error),
                    const SizedBox(height: StudySpacing.lg),
                    FilledButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh_rounded, size: 19),
                      label: const Text('Try Again'),
                      style: FilledButton.styleFrom(
                        backgroundColor: StudyColors.primary,
                        foregroundColor: StudyColors.textOnPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 13,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: StudyRadius.medium,
                        ),
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

  Widget _buildErrorDetails(Object? error) {
    if (error == null) {
      return const SizedBox.shrink();
    }

    final message = error.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(StudySpacing.md),
      decoration: BoxDecoration(
        color: StudyColors.surfaceSoft,
        borderRadius: StudyRadius.medium,
        border: Border.all(color: StudyColors.border),
      ),
      child: SelectableText(
        message,
        style: StudyTypography.caption.copyWith(
          color: StudyColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    String message = 'No study content is available.',
  }) {
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
                  color: StudyColors.surface,
                  borderRadius: StudyRadius.large,
                  border: Border.all(color: StudyColors.border),
                  boxShadow: StudyShadows.soft,
                ),
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
      },
    );
  }
}
