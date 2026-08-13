import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_radius.dart';
import '../../../app/app_spacing.dart';
import '../../../app/app_text_styles.dart';
import '../../../services/study_content_loader.dart';
import '../../../services/student_learning_position_service.dart';
import 'study_content_screen.dart';

class CompetencyScreen extends StatefulWidget {
  final String domainId;
  final int domainNumber;
  final String domainTitle;

  final String competencyId;
  final String title;

  final String? initialSubtopicId;
  final String? initialSubtopicTitle;

  const CompetencyScreen({
    super.key,
    required this.domainId,
    required this.domainNumber,
    required this.domainTitle,
    required this.competencyId,
    required this.title,
    this.initialSubtopicId,
    this.initialSubtopicTitle,
  });

  @override
  State<CompetencyScreen> createState() => _CompetencyScreenState();
}

class _CompetencyScreenState extends State<CompetencyScreen> {
  final StudyContentLoader _loader = const StudyContentLoader();

  final StudentLearningPositionService _positionService =
      const StudentLearningPositionService();

  Future<dynamic>? _contentFuture;

  @override
  void initState() {
    super.initState();

    _contentFuture = _loadContent();

    _saveCompetencyPosition();
  }

  Future<dynamic> _loadContent() async {
    return _loader.loadStudyContent(
      domainId: widget.domainId,
      competencyId: widget.competencyId,
    );
  }

  Future<void> _saveCompetencyPosition({
    String? subtopicId,
    String? subtopicTitle,
  }) async {
    await _positionService.savePosition(
      domainId: widget.domainId,
      domainNumber: widget.domainNumber,
      domainTitle: widget.domainTitle,
      competencyId: widget.competencyId,
      competencyTitle: widget.title,
      subtopicId: subtopicId ?? widget.initialSubtopicId,
      subtopicTitle: subtopicTitle ?? widget.initialSubtopicTitle,
    );
  }

  void _openStudyContent({String? subtopicId, String? subtopicTitle}) {
    _saveCompetencyPosition(
      subtopicId: subtopicId,
      subtopicTitle: subtopicTitle,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudyContentScreen(
          domainId: widget.domainId,
          competencyId: widget.competencyId,
          domainTitle: widget.domainTitle,
          loadingTitle: widget.title,
          initialSubtopicId: subtopicId ?? widget.initialSubtopicId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.title, style: AppTextStyles.subtitle),
      ),
      body: SafeArea(
        child: FutureBuilder<dynamic>(
          future: _contentFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _loading();
            }

            if (snapshot.hasError) {
              return _message(
                icon: Icons.cloud_off_rounded,
                title: 'Content unavailable',
                message:
                    'Published learning content could not be loaded right now.',
              );
            }

            final content = snapshot.data;

            if (content == null) {
              return _message(
                icon: Icons.auto_stories_outlined,
                title: 'Content is being prepared',
                message:
                    'Published learning content for this learning area is not available yet.',
              );
            }

            final subtopics = content.subtopics ?? [];

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.lg,
                    AppSpacing.page,
                    AppSpacing.xl,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildHeader(content),
                      const SizedBox(height: AppSpacing.lg),
                      _buildStudyButton(),
                      const SizedBox(height: AppSpacing.xl),
                      Text('Topics', style: AppTextStyles.title),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Select a topic to begin studying.',
                        style: AppTextStyles.body,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (subtopics.isEmpty)
                        _message(
                          icon: Icons.menu_book_outlined,
                          title: 'No topics available',
                          message:
                              'Published topics for this learning area will appear here when available.',
                        )
                      else
                        ...subtopics.asMap().entries.map((entry) {
                          final subtopic = entry.value;

                          final title = _subtopicTitle(subtopic);

                          final id = _subtopicId(subtopic);

                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: _topicCard(subtopic, entry.key, id, title),
                          );
                        }),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic content) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.large),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.78),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LEARNING AREA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Study the published topics in this learning area.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _openStudyContent,
        icon: const Icon(Icons.menu_book_rounded),
        label: const Text('START STUDY'),
      ),
    );
  }

  Widget _topicCard(dynamic subtopic, int index, String? id, String title) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () {
          _openStudyContent(subtopicId: id, subtopicTitle: title);
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.card),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(title, style: AppTextStyles.subtitle)),
              const Icon(Icons.arrow_forward_ios_rounded, size: 15),
            ],
          ),
        ),
      ),
    );
  }

  String _subtopicTitle(dynamic subtopic) {
    try {
      final value = subtopic.title;

      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    } catch (_) {}

    return 'Topic';
  }

  String? _subtopicId(dynamic subtopic) {
    try {
      final value = subtopic.id;

      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    } catch (_) {}

    return null;
  }

  Widget _loading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _message({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.page),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary, size: 30),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.subtitle),
                    const SizedBox(height: AppSpacing.xs),
                    Text(message, style: AppTextStyles.body),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
