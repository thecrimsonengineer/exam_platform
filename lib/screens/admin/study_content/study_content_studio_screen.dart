import 'package:flutter/material.dart';
import '../../../models/question.dart';
import '../../../models/studio_question_context.dart';
import '../../../services/question_bank_service.dart';
import '../../../services/quiz_service.dart';
import '../../../services/study_content/content_import_service.dart';
import '../../../services/study_content/content_repository_service.dart';
import '../../../services/study_content/content_validator.dart';

import '../../../models/study_content.dart';
import '../../../services/study_content/local_study_content_repository.dart';
import '../../../theme/study/study_colors.dart';
import '../../../theme/study/study_radius.dart';
import '../../../theme/study/study_shadows.dart';
import '../../../theme/study/study_spacing.dart';
import '../../../theme/study/study_typography.dart';
import '../../../widgets/admin/study_content/content_import_panel.dart';
import '../../../widgets/admin/study_content/content_preview_panel.dart';
import '../../../widgets/admin/study_content/content_validation_panel.dart';
import '../../../widgets/admin/study_content/editor/subtopic/subtopic_editor_panel.dart';
import '../../../widgets/admin/study_content/editor/main_content/main_content_editor_panel.dart';
import '../../../widgets/admin/study_content/structure/content_structure_panel.dart';
import '../../courses/csp/study_content_screen.dart';
import '../question_bank_screen.dart';

class StudyContentStudioScreen extends StatefulWidget {
  final StudyContent? initialContent;
  final int? initialQuestionId;

  const StudyContentStudioScreen({
    super.key,
    this.initialContent,
    this.initialQuestionId,
  });

  @override
  State<StudyContentStudioScreen> createState() =>
      _StudyContentStudioScreenState();
}

class _StudyContentStudioScreenState extends State<StudyContentStudioScreen> {
  int _selectedSection = 0;

  final LocalStudyContentRepository _repository = LocalStudyContentRepository();
  final ContentRepositoryService _contentRepositoryService =
      ContentRepositoryService();
  final QuestionBankService _questionService = QuestionBankService();

  StudyContent? _importedContent;

  List<Question> _practiceQuestions = <Question>[];
  bool _loadingPracticeQuestions = false;
  String? _resolvedPracticeQuizId;
  int? _focusedPracticeQuestionId;

  int _overviewQuestionCount = 0;
  int _overviewPublishedCount = 0;
  bool _overviewQuizReady = false;

  int? _selectedSubtopicIndex;
  int? _selectedMainContentIndex;

  List<StudyContent> _savedDrafts = <StudyContent>[];
  List<StudyContent> _publishedContent = <StudyContent>[];
  bool _loadingDrafts = false;
  bool _loadingPublished = false;

  String get _contentStatus =>
      _importedContent?.status.toLowerCase() ?? 'draft';

  bool get _isDraft => _contentStatus == 'draft';

  bool get _isReview => _contentStatus == 'review';

  bool get _isValidated => _contentStatus == 'validated';

  bool get _isValidationReady {
    final content = _importedContent;

    if (content == null) {
      return false;
    }

    final issues = const ContentValidator().validate(content);

    return !issues.any(
      (issue) => issue.severity == ContentImportIssueSeverity.error,
    );
  }

  final List<_StudioSection> _sections = const [
    _StudioSection(
      title: 'Content Overview',
      subtitle: 'Competency information',
      icon: Icons.dashboard_rounded,
    ),
    _StudioSection(
      title: 'Import Complete Content',
      subtitle: 'Import a full competency package',
      icon: Icons.file_download_rounded,
    ),
    _StudioSection(
      title: 'Subtopics',
      subtitle: 'Inspect and edit subtopics',
      icon: Icons.account_tree_rounded,
    ),
    _StudioSection(
      title: 'Main Content',
      subtitle: 'Create educational content',
      icon: Icons.menu_book_rounded,
    ),
    _StudioSection(
      title: 'Content Blocks',
      subtitle: 'Add rich learning blocks',
      icon: Icons.view_agenda_rounded,
    ),
    _StudioSection(
      title: 'Practice Questions',
      subtitle: 'Connect CSP quizzes',
      icon: Icons.quiz_rounded,
    ),
    _StudioSection(
      title: 'Validation',
      subtitle: 'Check content readiness',
      icon: Icons.verified_rounded,
    ),
    _StudioSection(
      title: 'Preview',
      subtitle: 'Student-facing preview',
      icon: Icons.visibility_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();

    final initial = widget.initialContent;

    if (initial != null) {
      _importedContent = initial;

      final initialQuestionId = widget.initialQuestionId;
      final selectedIndex = initial.subtopics.isEmpty ? null : 0;

      _selectedSection = initialQuestionId == null ? 0 : 5;
      _selectedSubtopicIndex = selectedIndex;
      _focusedPracticeQuestionId = initialQuestionId;
      _selectedMainContentIndex =
          selectedIndex != null &&
              initial.subtopics[selectedIndex].mainContent.isNotEmpty
          ? 0
          : null;
    }

    _initializeQuestionService();
    _loadRepositoryContent();
  }

  Future<void> _initializeQuestionService() async {
    try {
      await _questionService.initialize();

      final initialQuestionId = widget.initialQuestionId;
      final content = _importedContent;

      if (initialQuestionId != null && content != null) {
        final targetQuestion = _questionService
            .allManagedQuestions()
            .cast<Question?>()
            .firstWhere(
              (question) => question?.id == initialQuestionId,
              orElse: () => null,
            );

        if (targetQuestion != null) {
          final targetSubtopicIndex = content.subtopics.indexWhere(
            (subtopic) => subtopic.id == targetQuestion.subtopicId,
          );

          if (targetSubtopicIndex >= 0 && mounted) {
            setState(() {
              _selectedSection = 5;
              _selectedSubtopicIndex = targetSubtopicIndex;
              _focusedPracticeQuestionId = targetQuestion.id;
            });
          }
        }
      }

      await _refreshPracticeQuestions();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to initialize Practice Questions.\n$error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 700;

    if (isMobile) {
      return _buildMobileScaffold();
    }

    // Desktop layout is intentionally unchanged.
    return Scaffold(
      backgroundColor: StudyColors.background,
      body: SafeArea(
        child: Row(
          children: [
            _buildSidebar(),
            Expanded(child: _buildWorkspace()),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileScaffold() {
    return Scaffold(
      backgroundColor: StudyColors.background,
      drawer: Drawer(
        width: MediaQuery.sizeOf(context).width > 360 ? 320 : 292,
        backgroundColor: StudyColors.surface,
        child: SafeArea(child: _buildSidebar()),
      ),
      appBar: _buildMobileAppBar(),
      body: SafeArea(top: false, child: _buildEditorArea()),
    );
  }

  PreferredSizeWidget _buildMobileAppBar() {
    final imported = _importedContent != null;
    final section = _sections[_selectedSection];

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: StudyColors.surface,
      foregroundColor: StudyColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 4,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Study Content Studio',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            section.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: StudyColors.textSecondary,
              height: 1.1,
            ),
          ),
        ],
      ),
      actions: [
        if (imported)
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Center(child: _buildCompactMobileStatus()),
          ),
        _buildMobileActionMenu(imported),
      ],
    );
  }

  Widget _buildCompactMobileStatus() {
    final status = _contentStatus;
    final isPublished = status == 'published';
    final color = isPublished ? StudyColors.success : StudyColors.primary;

    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileActionMenu(bool imported) {
    return PopupMenuButton<String>(
      tooltip: 'Studio actions',
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (value) {
        switch (value) {
          case 'home':
            _returnToAdminHome();
            break;
          case 'student':
            _openStudentPortal();
            break;
          case 'preview':
            _openPreview();
            break;
          case 'save':
            _saveDraft();
            break;
          case 'review':
            _sendToReview();
            break;
          case 'validate':
            _validateContent();
            break;
          case 'publish':
            _publishContent();
            break;
        }
      },
      itemBuilder: (context) {
        return [
          const PopupMenuItem<String>(
            value: 'home',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.home_rounded),
              title: Text('Admin Home'),
            ),
          ),
          const PopupMenuItem<String>(
            value: 'student',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.school_rounded),
              title: Text('Student Portal'),
            ),
          ),
          PopupMenuItem<String>(
            value: 'preview',
            enabled: imported,
            child: const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.visibility_rounded),
              title: Text('Preview'),
            ),
          ),
          if (imported && _isDraft) ...[
            const PopupMenuItem<String>(
              value: 'save',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.save_rounded),
                title: Text('Save Draft'),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'review',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.rate_review_rounded),
                title: Text('Send to Review'),
              ),
            ),
          ],
          if (imported && _isReview)
            const PopupMenuItem<String>(
              value: 'validate',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.verified_rounded),
                title: Text('Validate'),
              ),
            ),
          if (imported && _isValidated)
            PopupMenuItem<String>(
              value: 'publish',
              enabled: _isValidationReady,
              child: const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.publish_rounded),
                title: Text('Publish'),
              ),
            ),
        ];
      },
    );
  }

  // ==========================================================
  // SIDEBAR
  // ==========================================================

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: StudyColors.surface,
        border: Border(right: BorderSide(color: StudyColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStudioBrand(),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _sections.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                return _buildSidebarItem(index, _sections[index]);
              },
            ),
          ),
          _buildSidebarFooter(),
        ],
      ),
    );
  }

  Widget _buildStudioBrand() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [StudyColors.primary, StudyColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 26),
          SizedBox(height: 12),
          Text(
            'CONTENT STUDIO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'CSP11 Study Content',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, _StudioSection section) {
    final selected = _selectedSection == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedSection = index;
          });

          // On Android, selecting a section also closes the navigation drawer.
          if (MediaQuery.sizeOf(context).width < 700 &&
              Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
        borderRadius: StudyRadius.medium,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? StudyColors.primaryLight : Colors.transparent,
            borderRadius: StudyRadius.medium,
            border: Border.all(
              color: selected
                  ? StudyColors.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? StudyColors.primary
                      : StudyColors.surfaceSoft,
                  borderRadius: StudyRadius.small,
                ),
                child: Icon(
                  section.icon,
                  size: 19,
                  color: selected ? Colors.white : StudyColors.textSecondary,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StudyTypography.label.copyWith(
                        color: selected
                            ? StudyColors.primary
                            : StudyColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      section.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StudyTypography.bodySecondary.copyWith(
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarFooter() {
    final imported = _importedContent != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: StudyColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: imported
                  ? StudyColors.successLight
                  : StudyColors.surfaceSoft,
              borderRadius: StudyRadius.small,
            ),
            child: Icon(
              imported ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
              size: 19,
              color: imported ? StudyColors.success : StudyColors.textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Repository', style: StudyTypography.label),
                const SizedBox(height: 2),
                Text(
                  imported ? 'Content loaded' : 'Ready',
                  style: StudyTypography.bodySecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // WORKSPACE
  // ==========================================================

  Widget _buildWorkspace() {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(child: _buildEditorArea()),
      ],
    );
  }

  Widget _buildTopBar() {
    final imported = _importedContent != null;

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 26),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        border: Border(bottom: BorderSide(color: StudyColors.border)),
        boxShadow: StudyShadows.soft,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 400,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Study Content Studio',
                    style: StudyTypography.sectionTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Create and publish CSP11 learning content',
                    style: StudyTypography.bodySecondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildStatusBadge(imported),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: _returnToAdminHome,
              icon: const Icon(Icons.home_rounded, size: 17),
              label: const Text('Admin Home'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _openStudentPortal,
              icon: const Icon(Icons.school_rounded, size: 17),
              label: const Text('Student Portal'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: imported ? _openPreview : null,
              icon: const Icon(Icons.visibility_rounded, size: 17),
              label: const Text('Preview'),
            ),
            if (imported && _isDraft) ...[
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: imported ? _saveDraft : null,
                icon: const Icon(Icons.save_rounded, size: 17),
                label: const Text('Save Draft'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: imported ? _sendToReview : null,
                icon: const Icon(Icons.rate_review_rounded, size: 17),
                label: const Text('Send to Review'),
              ),
            ],
            if (imported && _isReview) ...[
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _validateContent,
                icon: const Icon(Icons.verified_rounded, size: 17),
                label: const Text('Validate'),
              ),
            ],
            if (imported && _isValidated) ...[
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _isValidationReady ? _publishContent : null,
                icon: const Icon(Icons.publish_rounded, size: 17),
                label: const Text('Publish'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool imported) {
    if (!imported) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: StudyColors.warningLight,
          borderRadius: StudyRadius.pillRadius,
          border: Border.all(
            color: StudyColors.warning.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.circle, size: 8, color: StudyColors.warning),
            const SizedBox(width: 7),
            Text(
              'NO CONTENT',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: StudyColors.warning,
                letterSpacing: 0.7,
              ),
            ),
          ],
        ),
      );
    }

    final status = _contentStatus;

    late final Color color;
    late final Color background;
    late final String text;
    late final IconData icon;

    switch (status) {
      case 'review':
        color = StudyColors.warning;
        background = StudyColors.warningLight;
        text = 'REVIEW';
        icon = Icons.rate_review_rounded;
        break;

      case 'published':
        color = StudyColors.success;
        background = StudyColors.successLight;
        text = 'PUBLISHED';
        icon = Icons.verified_rounded;
        break;

      case 'archived':
        color = StudyColors.textSecondary;
        background = StudyColors.surfaceSoft;
        text = 'ARCHIVED';
        icon = Icons.archive_rounded;
        break;

      case 'draft':
      default:
        color = StudyColors.primary;
        background = StudyColors.primaryLight;
        text = 'DRAFT';
        icon = Icons.edit_note_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: StudyRadius.pillRadius,
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 7),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // EDITOR AREA
  // ==========================================================

  Widget _buildEditorArea() {
    if (_selectedSection == 7) {
      return ContentPreviewPanel(
        content: _importedContent,
        onExit: () {
          setState(() {
            _selectedSection = 0;
          });
        },
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 700;
    final horizontalPadding = isMobile
        ? 14.0
        : StudySpacing.pageHorizontalDesktop;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        isMobile ? 14 : StudySpacing.pageHorizontalDesktop,
        horizontalPadding,
        isMobile ? 24 : StudySpacing.pageHorizontalDesktop,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: _buildCurrentSection(),
        ),
      ),
    );
  }

  Widget _buildCurrentSection() {
    switch (_selectedSection) {
      case 0:
        return _buildOverviewEditor();

      case 1:
        return ContentImportPanel(onImported: _handleCompleteContentImport);

      case 2:
        return _buildSubtopicsWorkspace();

      case 3:
        return _buildMainContentWorkspace();

      case 4:
        return _buildPlaceholderEditor(
          'Content Block Builder',
          'Add and reorder rich content blocks.',
          Icons.view_agenda_rounded,
        );

      case 5:
        return _buildPracticeQuestionsWorkspace();

      case 6:
        return ContentValidationPanel(content: _importedContent);

      case 7:
        return ContentPreviewPanel(
          content: _importedContent,
          onExit: () {
            setState(() {
              _selectedSection = 0;
            });
          },
        );

      default:
        return _buildOverviewEditor();
    }
  }

  Future<void> _handleCompleteContentImport(ContentImportResult result) async {
    final content = result.content;

    if (content == null) {
      return;
    }

    try {
      await _questionService.initialize();

      for (final question in result.questions) {
        await _questionService.saveDraft(question);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _importedContent = content;
        _selectedSubtopicIndex = content.subtopics.isEmpty ? null : 0;
        _selectedMainContentIndex =
            content.subtopics.isNotEmpty &&
                content.subtopics.first.mainContent.isNotEmpty
            ? 0
            : null;
        _resolvedPracticeQuizId = null;
      });

      await _refreshPracticeQuestions();

      if (!mounted) {
        return;
      }

      final questionCount = result.questions.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            questionCount == 0
                ? 'Content imported successfully. No questions were supplied.'
                : 'Content imported successfully. $questionCount question${questionCount == 1 ? '' : 's'} added to the Question Bank.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save imported questions.\n$error')),
      );
    }
  }

  // ==========================================================
  // PRACTICE QUESTIONS WORKSPACE
  // ==========================================================

  Widget _buildPracticeQuestionsWorkspace() {
    final content = _importedContent;

    if (content == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeading(
            eyebrow: 'ASSESSMENT',
            title: 'Practice Questions',
            description:
                'Connect the managed CSP11 question bank to the selected '
                'subtopic.',
          ),
          const SizedBox(height: 24),
          _buildNoImportedPracticeQuestionsState(),
        ],
      );
    }

    if (content.subtopics.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeading(
            eyebrow: 'ASSESSMENT',
            title: 'Practice Questions',
            description:
                'A dedicated subtopic quiz requires at least five '
                'published questions.',
          ),
          const SizedBox(height: 24),
          _buildNoPracticeSubtopicsState(),
        ],
      );
    }

    _ensureSelectedSubtopicIsValid();

    final selectedIndex = _selectedSubtopicIndex ?? 0;
    final subtopic = content.subtopics[selectedIndex];
    final quizId = _practiceQuizId(content, subtopic);
    final isLinked = subtopic.quizzes.any((quiz) => quiz.quizId == quizId);
    final questionCount = _practiceQuestions.length;
    final publishedCount = _practiceQuestions
        .where((question) => question.status.toLowerCase() == 'published')
        .length;
    final ready = questionCount >= 5 && publishedCount >= 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeading(
          eyebrow: 'ASSESSMENT',
          title: 'Practice Questions',
          description:
              'Connect the managed CSP11 question bank to the selected '
              'subtopic. A dedicated subtopic quiz requires at least five '
              'published questions.',
        ),
        const SizedBox(height: 22),
        _buildPracticeSubtopicSelector(),
        const SizedBox(height: 22),
        _buildPracticeQuizSummary(
          subtopic: subtopic,
          quizId: quizId,
          questionCount: questionCount,
          publishedCount: publishedCount,
          isLinked: isLinked,
          ready: ready,
        ),
        const SizedBox(height: 22),
        _buildPracticeQuestionList(
          questions: _practiceQuestions,
          quizId: quizId,
        ),
        const SizedBox(height: 22),
        _buildPracticeLinkCard(
          quizId: quizId,
          ready: ready,
          isLinked: isLinked,
        ),
      ],
    );
  }

  String _practiceQuizId(StudyContent content, StudySubtopic subtopic) {
    final context = StudioQuestionContext.fromContent(
      content: content,
      subtopic: subtopic,
    );

    final resolvedQuizId = _resolvedPracticeQuizId?.trim() ?? '';
    if (resolvedQuizId.isNotEmpty) {
      return resolvedQuizId;
    }

    return context.quizId;
  }

  void _scheduleFocusPracticeQuestion(int questionId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final targetContext = _practiceQuestionKeys[questionId]?.currentContext;

      if (targetContext != null) {
        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          alignment: 0.12,
        );
      }
    });
  }

  final Map<int, GlobalKey> _practiceQuestionKeys = <int, GlobalKey>{};

  void _openQuestionInQuestionBank(Question question) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuestionBankScreen(initialQuestionId: question.id),
      ),
    );
  }

  Future<void> _refreshPracticeQuestions() async {
    final content = _importedContent;
    final index = _selectedSubtopicIndex;

    if (content == null ||
        index == null ||
        index < 0 ||
        index >= content.subtopics.length) {
      if (mounted) {
        setState(() {
          _practiceQuestions = <Question>[];
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _loadingPracticeQuestions = true;
      });
    }

    try {
      await _questionService.initialize();

      final subtopic = content.subtopics[index];

      final linkedQuizId = subtopic.quizzes
          .map((quiz) => quiz.quizId.trim())
          .firstWhere((quizId) => quizId.isNotEmpty, orElse: () => '');

      String resolvedQuizId = linkedQuizId;

      if (resolvedQuizId.isEmpty) {
        final candidates = _questionService
            .allManagedQuestions()
            .where(
              (question) =>
                  question.subtopicId == subtopic.id &&
                  question.status.toLowerCase() == 'published',
            )
            .toList();

        if (candidates.isNotEmpty) {
          final counts = <String, int>{};
          for (final question in candidates) {
            final candidateQuizId = question.quizId.trim();
            if (candidateQuizId.isNotEmpty) {
              counts[candidateQuizId] = (counts[candidateQuizId] ?? 0) + 1;
            }
          }

          if (counts.isNotEmpty) {
            final sortedQuizIds = counts.entries.toList()
              ..sort((a, b) {
                final countComparison = b.value.compareTo(a.value);
                if (countComparison != 0) {
                  return countComparison;
                }
                return a.key.compareTo(b.key);
              });
            resolvedQuizId = sortedQuizIds.first.key;
          }
        }
      }

      if (resolvedQuizId.isEmpty) {
        resolvedQuizId = StudioQuestionContext.canonicalQuizId(
          content.id,
          subtopic.id,
        );
      }

      final questions = _questionService.byQuizId(resolvedQuizId)
        ..sort((a, b) => a.id.compareTo(b.id));

      final overviewStats = _calculateOverviewQuizStatistics(content);

      if (!mounted) {
        return;
      }

      setState(() {
        _resolvedPracticeQuizId = resolvedQuizId;
        _practiceQuestions = questions;
        _loadingPracticeQuestions = false;
        _overviewQuestionCount = overviewStats.questionCount;
        _overviewPublishedCount = overviewStats.publishedCount;
        _overviewQuizReady = overviewStats.ready;
      });

      final focusedQuestionId = _focusedPracticeQuestionId;
      if (focusedQuestionId != null &&
          questions.any((question) => question.id == focusedQuestionId)) {
        _scheduleFocusPracticeQuestion(focusedQuestionId);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _practiceQuestions = <Question>[];
        _loadingPracticeQuestions = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load Practice Questions.\n$error')),
      );
    }
  }

  Widget _buildPracticeSubtopicSelector() {
    final content = _importedContent!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;

          final selector = DropdownButtonFormField<int>(
            initialValue: _selectedSubtopicIndex,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Select Subtopic',
              prefixIcon: const Icon(Icons.account_tree_rounded),
              filled: true,
              fillColor: StudyColors.surfaceSoft,
              border: OutlineInputBorder(
                borderRadius: StudyRadius.medium,
                borderSide: BorderSide(color: StudyColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: StudyRadius.medium,
                borderSide: BorderSide(color: StudyColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: StudyRadius.medium,
                borderSide: BorderSide(color: StudyColors.primary, width: 1.3),
              ),
            ),
            items: List.generate(content.subtopics.length, (index) {
              final subtopic = content.subtopics[index];

              return DropdownMenuItem<int>(
                value: index,
                child: Text(
                  '${index + 1}. ${subtopic.title}',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _selectedSubtopicIndex = value;
                _selectedMainContentIndex = 0;
                _resolvedPracticeQuizId = null;
                _focusedPracticeQuestionId = null;
              });

              _refreshPracticeQuestions();
            },
          );

          final count = Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: StudyColors.primary.withValues(alpha: 0.07),
              borderRadius: StudyRadius.pillRadius,
            ),
            child: Text(
              '${content.subtopics.length} subtopics',
              style: StudyTypography.label.copyWith(
                color: StudyColors.primary,
                fontSize: 11,
              ),
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Choose the subtopic to configure',
                        style: StudyTypography.subSectionTitle,
                      ),
                    ),
                    count,
                  ],
                ),
                const SizedBox(height: 14),
                selector,
              ],
            );
          }

          return Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose the subtopic to configure',
                      style: StudyTypography.subSectionTitle,
                    ),
                    SizedBox(height: 3),
                    Text(
                      'The quiz reference will be stored on this subtopic.',
                      style: StudyTypography.bodySecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(width: 360, child: selector),
              const SizedBox(width: 10),
              count,
            ],
          );
        },
      ),
    );
  }

  Widget _buildPracticeQuizSummary({
    required StudySubtopic subtopic,
    required String quizId,
    required int questionCount,
    required int publishedCount,
    required bool isLinked,
    required bool ready,
  }) {
    return _buildEditorCard(
      title: 'Quiz Readiness',
      icon: Icons.quiz_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900
                  ? 4
                  : constraints.maxWidth >= 560
                  ? 2
                  : 1;

              final metrics = [
                _PracticeMetric(
                  value: '$questionCount',
                  label: 'Questions',
                  icon: Icons.help_outline_rounded,
                  color: questionCount >= 5
                      ? StudyColors.success
                      : StudyColors.warning,
                ),
                _PracticeMetric(
                  value: '$publishedCount',
                  label: 'Published',
                  icon: Icons.verified_rounded,
                  color: publishedCount >= 5
                      ? StudyColors.success
                      : StudyColors.warning,
                ),
                _PracticeMetric(
                  value: isLinked ? 'LINKED' : 'NOT LINKED',
                  label: 'Content Link',
                  icon: isLinked ? Icons.link_rounded : Icons.link_off_rounded,
                  color: isLinked
                      ? StudyColors.success
                      : StudyColors.textSecondary,
                ),
                _PracticeMetric(
                  value: ready ? 'READY' : 'INCOMPLETE',
                  label: 'Quiz Status',
                  icon: ready
                      ? Icons.check_circle_rounded
                      : Icons.pending_rounded,
                  color: ready ? StudyColors.success : StudyColors.warning,
                ),
              ];

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: metrics.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: columns == 1 ? 5.5 : 2.3,
                ),
                itemBuilder: (context, index) {
                  return _buildPracticeMetric(metrics[index]);
                },
              );
            },
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: StudyColors.surfaceSoft,
              borderRadius: StudyRadius.medium,
              border: Border.all(color: StudyColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SELECTED SUBTOPIC',
                  style: StudyTypography.eyebrow.copyWith(fontSize: 9),
                ),
                const SizedBox(height: 5),
                Text(
                  subtopic.title,
                  style: StudyTypography.cardTitle.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 10),
                Text(
                  'QUIZ ID',
                  style: StudyTypography.eyebrow.copyWith(fontSize: 9),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  quizId,
                  style: StudyTypography.body.copyWith(
                    color: StudyColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeMetric(_PracticeMetric metric) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StudyColors.surfaceSoft,
        borderRadius: StudyRadius.medium,
        border: Border.all(color: StudyColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: metric.color.withValues(alpha: 0.09),
              borderRadius: StudyRadius.small,
            ),
            child: Icon(metric.icon, size: 18, color: metric.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StudyTypography.cardTitle.copyWith(
                    fontSize: 15,
                    color: metric.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StudyTypography.bodySecondary.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeQuestionList({
    required List<Question> questions,
    required String quizId,
  }) {
    return _buildEditorCard(
      title: 'Managed Question Set',
      icon: Icons.library_books_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Questions assigned to this quiz are read from the '
                  'central QuestionBankService.',
                  style: StudyTypography.bodySecondary,
                ),
              ),
              IconButton(
                tooltip: 'Refresh questions',
                onPressed: _loadingPracticeQuestions
                    ? null
                    : _refreshPracticeQuestions,
                icon: _loadingPracticeQuestions
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_loadingPracticeQuestions && questions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (questions.isEmpty)
            _buildPracticeEmptyQuestionsState(quizId)
          else
            Column(
              children: [
                for (var index = 0; index < questions.length; index++)
                  _buildPracticeQuestionRow(questions[index], index),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPracticeQuestionRow(Question question, int index) {
    final published = question.status.toLowerCase() == 'published';
    final statusColor = published ? StudyColors.success : StudyColors.warning;

    final rowKey = _practiceQuestionKeys.putIfAbsent(
      question.id,
      () => GlobalKey(),
    );
    final focused = _focusedPracticeQuestionId == question.id;

    return KeyedSubtree(
      key: rowKey,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(
          bottom: index == _practiceQuestions.length - 1 ? 0 : 10,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: focused ? StudyColors.primaryLight : StudyColors.surfaceSoft,
          borderRadius: StudyRadius.medium,
          border: Border.all(color: StudyColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: StudyColors.primaryLight,
                borderRadius: StudyRadius.small,
              ),
              child: Text(
                '${index + 1}',
                style: StudyTypography.label.copyWith(
                  color: StudyColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.question,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: StudyTypography.label.copyWith(fontSize: 12.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Question ID ${question.id}',
                    style: StudyTypography.bodySecondary.copyWith(fontSize: 10),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _openQuestionInQuestionBank(question),
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('Open in Question Bank'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.09),
                borderRadius: StudyRadius.pillRadius,
              ),
              child: Text(
                published ? 'PUBLISHED' : 'DRAFT',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPracticeEmptyQuestionsState(String quizId) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: StudyColors.surfaceSoft,
        borderRadius: StudyRadius.medium,
        border: Border.all(color: StudyColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.quiz_outlined,
            size: 42,
            color: StudyColors.textSecondary,
          ),
          const SizedBox(height: 12),
          const Text(
            'No managed questions found',
            style: StudyTypography.cardTitle,
          ),
          const SizedBox(height: 6),
          Text(
            'The Question Bank does not currently contain questions for '
            '$quizId.',
            textAlign: TextAlign.center,
            style: StudyTypography.bodySecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeLinkCard({
    required String quizId,
    required bool ready,
    required bool isLinked,
  }) {
    final canLink = ready && !isLinked && _isDraft;

    String message;

    if (isLinked) {
      message =
          'This quiz is already linked to the selected subtopic. '
          'The reference is stored in StudyContent as a QuizReference.';
    } else if (!_isDraft) {
      message =
          'Quiz linking is available only while the content version is '
          'in Draft. Create or open a draft version before linking.';
    } else if (!ready) {
      message =
          'Complete the dedicated quiz requirement first: at least five '
          'published questions are required.';
    } else {
      message =
          'Link this quiz to the selected subtopic. '
          'The questions remain in the central question repository.';
    }

    return _buildEditorCard(
      title: isLinked ? 'Quiz Linked' : 'Link Practice Quiz',
      icon: isLinked ? Icons.link_rounded : Icons.add_link_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isLinked
                  ? StudyColors.successLight
                  : StudyColors.surfaceSoft,
              borderRadius: StudyRadius.medium,
              border: Border.all(
                color: isLinked
                    ? StudyColors.success.withValues(alpha: 0.18)
                    : StudyColors.border,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isLinked
                      ? Icons.check_circle_rounded
                      : ready
                      ? Icons.info_outline_rounded
                      : Icons.warning_amber_rounded,
                  color: isLinked
                      ? StudyColors.success
                      : ready
                      ? StudyColors.primary
                      : StudyColors.warning,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(message, style: StudyTypography.bodySecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(
                    quizId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StudyTypography.body.copyWith(
                      color: StudyColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (!isLinked)
                  FilledButton.icon(
                    onPressed: canLink ? _linkPracticeQuiz : null,
                    icon: const Icon(Icons.link_rounded, size: 17),
                    label: const Text('Link Quiz'),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.check_rounded, size: 17),
                    label: const Text('Already Linked'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _linkPracticeQuiz() async {
    final content = _importedContent;
    final index = _selectedSubtopicIndex;

    if (content == null ||
        index == null ||
        index < 0 ||
        index >= content.subtopics.length) {
      return;
    }

    if (!_isDraft) {
      _showPracticeMessage(
        'Open a Draft content version before linking a practice quiz.',
      );
      return;
    }

    final subtopic = content.subtopics[index];
    final quizId = _practiceQuizId(content, subtopic);

    final publishedCount = _practiceQuestions
        .where((question) => question.status.toLowerCase() == 'published')
        .length;

    if (!QuizService.hasMinimumPublishedQuestions(publishedCount)) {
      _showPracticeMessage(
        'The subtopic must have at least 5 published questions '
        'before the quiz can be linked.',
      );
      return;
    }

    if (subtopic.quizzes.any((quiz) => quiz.quizId == quizId)) {
      _showPracticeMessage('This quiz is already linked to the subtopic.');
      return;
    }

    final updatedSubtopic = StudySubtopic(
      id: subtopic.id,
      title: subtopic.title,
      learningObjectives: List<String>.from(subtopic.learningObjectives),
      mainContent: List<MainContentTopic>.from(subtopic.mainContent),
      keyPoints: List<ContentEntry>.from(subtopic.keyPoints),
      examples: List<ContentEntry>.from(subtopic.examples),
      caseStudies: List<ContentEntry>.from(subtopic.caseStudies),
      formulas: List<ContentEntry>.from(subtopic.formulas),
      references: List<ContentEntry>.from(subtopic.references),
      examTips: List<ContentEntry>.from(subtopic.examTips),
      commonMistakes: List<ContentEntry>.from(subtopic.commonMistakes),
      keyTakeaways: List<ContentEntry>.from(subtopic.keyTakeaways),
      quizzes: [
        ...subtopic.quizzes,
        QuizReference(quizId: quizId),
      ],
    );

    final updatedSubtopics = List<StudySubtopic>.from(content.subtopics);
    updatedSubtopics[index] = updatedSubtopic;

    final updatedContent = StudyContent(
      id: content.id,
      domainId: content.domainId,
      competencyId: content.competencyId,
      competencyNumber: content.competencyNumber,
      title: content.title,
      status: content.status,
      version: content.version,
      subtopics: updatedSubtopics,
    );

    try {
      await _repository.saveDraft(updatedContent);

      if (!mounted) {
        return;
      }

      setState(() {
        _importedContent = updatedContent;
      });

      await _loadDrafts();
      await _refreshPracticeQuestions();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Practice quiz linked successfully. '
            'Continue through the normal review and validation workflow.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to link practice quiz.\n$error')),
      );
    }
  }

  void _showPracticeMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildNoImportedPracticeQuestionsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: Column(
        children: [
          const Icon(Icons.quiz_outlined, size: 44, color: StudyColors.primary),
          const SizedBox(height: 14),
          const Text('No content imported', style: StudyTypography.cardTitle),
          const SizedBox(height: 7),
          const Text(
            'Import or open a CSP11 competency before connecting its '
            'subtopic practice quizzes.',
            textAlign: TextAlign.center,
            style: StudyTypography.bodySecondary,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () {
              setState(() {
                _selectedSection = 1;
              });
            },
            icon: const Icon(Icons.file_download_rounded, size: 17),
            label: const Text('Import Content'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPracticeSubtopicsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: const Column(
        children: [
          Icon(
            Icons.account_tree_outlined,
            size: 44,
            color: StudyColors.textSecondary,
          ),
          SizedBox(height: 14),
          Text('No subtopics found', style: StudyTypography.cardTitle),
          SizedBox(height: 7),
          Text(
            'Create or import a subtopic before configuring its '
            'practice quiz.',
            textAlign: TextAlign.center,
            style: StudyTypography.bodySecondary,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SUBTOPICS WORKSPACE
  // ==========================================================

  Widget _buildSubtopicsWorkspace() {
    final content = _importedContent;

    if (content == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeading(
            eyebrow: 'CONTENT STRUCTURE',
            title: 'Subtopics',
            description:
                'Import a CSP11 competency before inspecting or '
                'editing its subtopics.',
          ),
          const SizedBox(height: 24),
          _buildNoImportedSubtopicState(),
        ],
      );
    }

    if (content.subtopics.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeading(
            eyebrow: 'CONTENT STRUCTURE',
            title: 'Subtopics',
            description:
                'No subtopics are currently available in this competency.',
          ),
          const SizedBox(height: 24),
          _buildNoSubtopicsState(),
        ],
      );
    }

    _ensureSelectedSubtopicIsValid();

    final selectedIndex = _selectedSubtopicIndex ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeading(
          eyebrow: 'CONTENT STRUCTURE',
          title: 'Subtopics',
          description:
              'Inspect the imported hierarchy and edit individual '
              'subtopics without changing the underlying content architecture.',
        ),
        const SizedBox(height: 22),
        _buildSubtopicSelector(),
        const SizedBox(height: 22),
        _buildStructureInspectorCard(),
        const SizedBox(height: 22),
        _buildSubtopicEditorCard(content.subtopics[selectedIndex]),
      ],
    );
  }

  void _ensureSelectedSubtopicIsValid() {
    final count = _importedContent?.subtopics.length ?? 0;

    if (count == 0) {
      _selectedSubtopicIndex = null;
      return;
    }

    if (_selectedSubtopicIndex == null || _selectedSubtopicIndex! >= count) {
      _selectedSubtopicIndex = 0;
    }
  }

  Widget _buildSubtopicSelector() {
    final content = _importedContent!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;

          final selector = DropdownButtonFormField<int>(
            initialValue: _selectedSubtopicIndex,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Select Subtopic',
              prefixIcon: const Icon(Icons.account_tree_rounded),
              filled: true,
              fillColor: StudyColors.surfaceSoft,
              border: OutlineInputBorder(
                borderRadius: StudyRadius.medium,
                borderSide: BorderSide(color: StudyColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: StudyRadius.medium,
                borderSide: BorderSide(color: StudyColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: StudyRadius.medium,
                borderSide: BorderSide(color: StudyColors.primary, width: 1.3),
              ),
            ),
            items: List.generate(content.subtopics.length, (index) {
              final subtopic = content.subtopics[index];

              return DropdownMenuItem<int>(
                value: index,
                child: Text(
                  '${index + 1}. ${subtopic.title}',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _selectedSubtopicIndex = value;
                _selectedMainContentIndex = 0;
                _resolvedPracticeQuizId = null;
              });
              _refreshPracticeQuestions();
            },
          );

          final count = Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: StudyColors.primary.withValues(alpha: 0.07),
              borderRadius: StudyRadius.pillRadius,
            ),
            child: Text(
              '${content.subtopics.length} subtopics',
              style: StudyTypography.label.copyWith(
                color: StudyColors.primary,
                fontSize: 11,
              ),
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Edit a specific subtopic',
                        style: StudyTypography.subSectionTitle,
                      ),
                    ),
                    count,
                  ],
                ),
                const SizedBox(height: 14),
                selector,
              ],
            );
          }

          return Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit a specific subtopic',
                      style: StudyTypography.subSectionTitle,
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Select a subtopic to load it into the editor.',
                      style: StudyTypography.bodySecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(width: 360, child: selector),
              const SizedBox(width: 10),
              count,
            ],
          );
        },
      ),
    );
  }

  // ==========================================================
  // MAIN CONTENT WORKSPACE
  // ==========================================================

  Widget _buildMainContentWorkspace() {
    final content = _importedContent;

    if (content == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeading(
            eyebrow: 'CONTENT BUILDER',
            title: 'Main Content',
            description:
                'Import a CSP11 competency before creating or editing main content topics.',
          ),
          const SizedBox(height: 24),
          _buildNoImportedMainContentState(),
        ],
      );
    }

    if (content.subtopics.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeading(
            eyebrow: 'CONTENT BUILDER',
            title: 'Main Content',
            description:
                'Create educational topics inside the competency subtopic hierarchy.',
          ),
          const SizedBox(height: 24),
          _buildNoMainContentSubtopicsState(),
        ],
      );
    }

    _ensureSelectedSubtopicIsValid();

    final selectedSubtopicIndex = _selectedSubtopicIndex ?? 0;
    final subtopic = content.subtopics[selectedSubtopicIndex];

    _ensureSelectedMainContentIsValid(subtopic);

    final mainContentIndex = _selectedMainContentIndex;
    final topics = subtopic.mainContent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeading(
          eyebrow: 'CONTENT BUILDER',
          title: 'Main Content',
          description:
              'Create and edit the educational topics within the selected subtopic while preserving the structured content hierarchy.',
        ),
        const SizedBox(height: 22),
        _buildMainContentSubtopicSelector(),
        const SizedBox(height: 22),
        _buildMainContentTopicList(subtopic),
        const SizedBox(height: 22),
        if (mainContentIndex != null &&
            mainContentIndex >= 0 &&
            mainContentIndex < topics.length)
          _buildMainContentEditorCard(topics[mainContentIndex])
        else
          _buildNoSelectedMainContentState(),
      ],
    );
  }

  void _ensureSelectedMainContentIsValid(StudySubtopic subtopic) {
    final count = subtopic.mainContent.length;

    if (count == 0) {
      _selectedMainContentIndex = null;
      return;
    }

    if (_selectedMainContentIndex == null ||
        _selectedMainContentIndex! < 0 ||
        _selectedMainContentIndex! >= count) {
      _selectedMainContentIndex = 0;
    }
  }

  Widget _buildMainContentSubtopicSelector() {
    final content = _importedContent!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;

          final selector = DropdownButtonFormField<int>(
            initialValue: _selectedSubtopicIndex,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Select Subtopic',
              prefixIcon: const Icon(Icons.account_tree_rounded),
              filled: true,
              fillColor: StudyColors.surfaceSoft,
              border: OutlineInputBorder(
                borderRadius: StudyRadius.medium,
                borderSide: BorderSide(color: StudyColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: StudyRadius.medium,
                borderSide: BorderSide(color: StudyColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: StudyRadius.medium,
                borderSide: BorderSide(color: StudyColors.primary, width: 1.3),
              ),
            ),
            items: List.generate(content.subtopics.length, (index) {
              final subtopic = content.subtopics[index];

              return DropdownMenuItem<int>(
                value: index,
                child: Text(
                  '${index + 1}. ${subtopic.title}',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _selectedSubtopicIndex = value;
                _selectedMainContentIndex = 0;
                _resolvedPracticeQuizId = null;
              });
            },
          );

          final selectedIndex = _selectedSubtopicIndex ?? 0;
          final selectedSubtopic = content.subtopics[selectedIndex];

          final count = Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: StudyColors.primary.withValues(alpha: 0.07),
              borderRadius: StudyRadius.pillRadius,
            ),
            child: Text(
              '${selectedSubtopic.mainContent.length} topics',
              style: StudyTypography.label.copyWith(
                color: StudyColors.primary,
                fontSize: 11,
              ),
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Select a subtopic',
                        style: StudyTypography.subSectionTitle,
                      ),
                    ),
                    count,
                  ],
                ),
                const SizedBox(height: 14),
                selector,
              ],
            );
          }

          return Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select a subtopic',
                      style: StudyTypography.subSectionTitle,
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Main content topics belong to the selected subtopic.',
                      style: StudyTypography.bodySecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(width: 360, child: selector),
              const SizedBox(width: 10),
              count,
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainContentTopicList(StudySubtopic subtopic) {
    final topics = subtopic.mainContent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Main Content Topics',
                      style: StudyTypography.subSectionTitle,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${topics.length} topic${topics.length == 1 ? '' : 's'} in ${subtopic.title}',
                      style: StudyTypography.bodySecondary,
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _addMainContentTopic,
                icon: const Icon(Icons.add_rounded, size: 17),
                label: const Text('Add Main Content'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (topics.isEmpty)
            _buildNoMainContentTopicsState()
          else
            Column(
              children: [
                for (var index = 0; index < topics.length; index++)
                  _buildMainContentTopicRow(topics[index], index),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMainContentTopicRow(MainContentTopic topic, int index) {
    final selected = _selectedMainContentIndex == index;

    final currentSubtopic =
        _importedContent!.subtopics[_selectedSubtopicIndex ?? 0];

    final isLast = index == currentSubtopic.mainContent.length - 1;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: isLast ? 0 : 9),
      decoration: BoxDecoration(
        color: selected ? StudyColors.primaryLight : StudyColors.surfaceSoft,
        borderRadius: StudyRadius.medium,
        border: Border.all(
          color: selected
              ? StudyColors.primary.withValues(alpha: 0.18)
              : StudyColors.border,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedMainContentIndex = index;
            });
          },
          borderRadius: StudyRadius.medium,
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? StudyColors.primary
                        : StudyColors.background,
                    borderRadius: StudyRadius.small,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: StudyTypography.label.copyWith(
                      color: selected ? Colors.white : StudyColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: StudyTypography.label.copyWith(fontSize: 12.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${topic.blocks.length} block${topic.blocks.length == 1 ? '' : 's'}  •  '
                        '${topic.quizzes.length} quiz reference${topic.quizzes.length == 1 ? '' : 's'}',
                        style: StudyTypography.bodySecondary.copyWith(
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  size: 19,
                  color: selected
                      ? StudyColors.primary
                      : StudyColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContentEditorCard(MainContentTopic topic) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: StudyColors.background,
        borderRadius: StudyRadius.large,
      ),
      child: MainContentEditorPanel(
        topic: topic,
        onSave: _handleMainContentSave,
        onCancel: _handleMainContentCancel,
      ),
    );
  }

  Widget _buildNoSelectedMainContentState() {
    return _buildEditorCard(
      title: 'Main Content Editor',
      icon: Icons.menu_book_rounded,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: StudyColors.surfaceSoft,
          borderRadius: StudyRadius.medium,
          border: Border.all(color: StudyColors.border),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.touch_app_rounded,
              size: 40,
              color: StudyColors.textSecondary,
            ),
            SizedBox(height: 12),
            Text(
              'Select a main content topic',
              style: StudyTypography.cardTitle,
            ),
            SizedBox(height: 6),
            Text(
              'Select an existing topic above or add a new one.',
              textAlign: TextAlign.center,
              style: StudyTypography.bodySecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoMainContentTopicsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: StudyColors.surfaceSoft,
        borderRadius: StudyRadius.medium,
        border: Border.all(color: StudyColors.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 40,
            color: StudyColors.textSecondary,
          ),
          SizedBox(height: 12),
          Text('No main content topics yet', style: StudyTypography.cardTitle),
          SizedBox(height: 6),
          Text(
            'Use Add Main Content to create the first educational topic.',
            textAlign: TextAlign.center,
            style: StudyTypography.bodySecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildNoImportedMainContentState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.menu_book_outlined,
            size: 44,
            color: StudyColors.primary,
          ),
          const SizedBox(height: 14),
          const Text('No content imported', style: StudyTypography.cardTitle),
          const SizedBox(height: 7),
          const Text(
            'Use Import Complete Content to load a competency before creating main content.',
            textAlign: TextAlign.center,
            style: StudyTypography.bodySecondary,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () {
              setState(() {
                _selectedSection = 1;
              });
            },
            icon: const Icon(Icons.file_download_rounded, size: 17),
            label: const Text('Import Content'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMainContentSubtopicsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: const Column(
        children: [
          Icon(
            Icons.account_tree_outlined,
            size: 44,
            color: StudyColors.textSecondary,
          ),
          SizedBox(height: 14),
          Text('No subtopics found', style: StudyTypography.cardTitle),
          SizedBox(height: 7),
          Text(
            'Create or import a subtopic before adding main content topics.',
            textAlign: TextAlign.center,
            style: StudyTypography.bodySecondary,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // MAIN CONTENT SAVE FLOW
  // ==========================================================

  void _handleMainContentSave(MainContentTopic updatedTopic) {
    final content = _importedContent;

    if (content == null) {
      return;
    }

    final subtopicIndex = _selectedSubtopicIndex;

    if (subtopicIndex == null ||
        subtopicIndex < 0 ||
        subtopicIndex >= content.subtopics.length) {
      return;
    }

    final subtopic = content.subtopics[subtopicIndex];
    final topicIndex = _selectedMainContentIndex;

    if (topicIndex == null ||
        topicIndex < 0 ||
        topicIndex >= subtopic.mainContent.length) {
      return;
    }

    final updatedMainContent = List<MainContentTopic>.from(
      subtopic.mainContent,
    );

    updatedMainContent[topicIndex] = updatedTopic;

    final updatedSubtopic = StudySubtopic(
      id: subtopic.id,
      title: subtopic.title,
      learningObjectives: List<String>.from(subtopic.learningObjectives),
      mainContent: updatedMainContent,
      keyPoints: List<ContentEntry>.from(subtopic.keyPoints),
      examples: List<ContentEntry>.from(subtopic.examples),
      caseStudies: List<ContentEntry>.from(subtopic.caseStudies),
      formulas: List<ContentEntry>.from(subtopic.formulas),
      references: List<ContentEntry>.from(subtopic.references),
      examTips: List<ContentEntry>.from(subtopic.examTips),
      commonMistakes: List<ContentEntry>.from(subtopic.commonMistakes),
      keyTakeaways: List<ContentEntry>.from(subtopic.keyTakeaways),
      quizzes: List<QuizReference>.from(subtopic.quizzes),
    );

    _replaceSubtopic(subtopicIndex, updatedSubtopic);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Main content topic updated successfully.')),
    );
  }

  void _handleMainContentCancel() {
    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Main content editing cancelled.')),
    );
  }

  void _addMainContentTopic() {
    final content = _importedContent;

    if (content == null) {
      return;
    }

    final subtopicIndex = _selectedSubtopicIndex;

    if (subtopicIndex == null ||
        subtopicIndex < 0 ||
        subtopicIndex >= content.subtopics.length) {
      return;
    }

    final subtopic = content.subtopics[subtopicIndex];

    final newTopic = MainContentTopic(
      id: _generateMainContentId(subtopic, subtopic.mainContent.length),
      title: 'New Main Content Topic',
      blocks: const [],
      quizzes: const [],
    );

    final updatedMainContent = List<MainContentTopic>.from(subtopic.mainContent)
      ..add(newTopic);

    final updatedSubtopic = StudySubtopic(
      id: subtopic.id,
      title: subtopic.title,
      learningObjectives: List<String>.from(subtopic.learningObjectives),
      mainContent: updatedMainContent,
      keyPoints: List<ContentEntry>.from(subtopic.keyPoints),
      examples: List<ContentEntry>.from(subtopic.examples),
      caseStudies: List<ContentEntry>.from(subtopic.caseStudies),
      formulas: List<ContentEntry>.from(subtopic.formulas),
      references: List<ContentEntry>.from(subtopic.references),
      examTips: List<ContentEntry>.from(subtopic.examTips),
      commonMistakes: List<ContentEntry>.from(subtopic.commonMistakes),
      keyTakeaways: List<ContentEntry>.from(subtopic.keyTakeaways),
      quizzes: List<QuizReference>.from(subtopic.quizzes),
    );

    _replaceSubtopic(subtopicIndex, updatedSubtopic);

    setState(() {
      _selectedMainContentIndex = updatedMainContent.length - 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('New main content topic created.')),
    );
  }

  String _generateMainContentId(StudySubtopic subtopic, int index) {
    final base = subtopic.id.trim().isEmpty ? 'subtopic' : subtopic.id.trim();

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    return '${base}_topic_${index + 1}_$timestamp';
  }

  void _replaceSubtopic(int subtopicIndex, StudySubtopic updatedSubtopic) {
    final content = _importedContent;

    if (content == null) {
      return;
    }

    final updatedSubtopics = List<StudySubtopic>.from(content.subtopics);

    updatedSubtopics[subtopicIndex] = updatedSubtopic;

    final updatedContent = StudyContent(
      id: content.id,
      version: content.version,
      domainId: content.domainId,
      competencyId: content.competencyId,
      competencyNumber: content.competencyNumber,
      title: content.title,
      status: content.status,
      subtopics: updatedSubtopics,
    );

    setState(() {
      _importedContent = updatedContent;
    });
  }

  Widget _buildStructureInspectorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: StudyColors.background,
        borderRadius: StudyRadius.large,
      ),
      child: ContentStructurePanel(content: _importedContent),
    );
  }

  Widget _buildSubtopicEditorCard(StudySubtopic subtopic) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: StudyColors.background,
        borderRadius: StudyRadius.large,
      ),
      child: SubtopicEditorPanel(
        subtopic: subtopic,
        onSave: _handleSubtopicSave,
        onCancel: _handleSubtopicCancel,
      ),
    );
  }

  // ==========================================================
  // SUBTOPIC SAVE FLOW
  // ==========================================================

  void _handleSubtopicSave(StudySubtopic updatedSubtopic) {
    final content = _importedContent;

    if (content == null) {
      return;
    }

    final index = _selectedSubtopicIndex;

    if (index == null || index < 0 || index >= content.subtopics.length) {
      return;
    }

    final updatedSubtopics = List<StudySubtopic>.from(content.subtopics);

    updatedSubtopics[index] = updatedSubtopic;

    final updatedContent = StudyContent(
      id: content.id,
      version: content.version,
      domainId: content.domainId,
      competencyId: content.competencyId,
      competencyNumber: content.competencyNumber,
      title: content.title,
      status: content.status,
      subtopics: updatedSubtopics,
    );

    setState(() {
      _importedContent = updatedContent;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subtopic updated successfully.')),
    );
  }

  void _handleSubtopicCancel() {
    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subtopic editing cancelled.')),
    );
  }

  // ==========================================================
  // EMPTY STATES
  // ==========================================================

  Widget _buildNoImportedSubtopicState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_tree_outlined,
            size: 44,
            color: StudyColors.primary,
          ),
          const SizedBox(height: 14),
          const Text('No content imported', style: StudyTypography.cardTitle),
          const SizedBox(height: 7),
          Text(
            'Use Import Complete Content to load a competency '
            'before opening the Subtopic Editor.',
            textAlign: TextAlign.center,
            style: StudyTypography.bodySecondary,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () {
              setState(() {
                _selectedSection = 1;
              });
            },
            icon: const Icon(Icons.file_download_rounded, size: 17),
            label: const Text('Import Content'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSubtopicsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: const Column(
        children: [
          Icon(
            Icons.account_tree_outlined,
            size: 44,
            color: StudyColors.textSecondary,
          ),
          SizedBox(height: 14),
          Text('No subtopics found', style: StudyTypography.cardTitle),
          SizedBox(height: 7),
          Text(
            'The imported competency does not contain any subtopics.',
            textAlign: TextAlign.center,
            style: StudyTypography.bodySecondary,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PREMIUM CONTENT OVERVIEW
  // ==========================================================

  Widget _buildOverviewEditor() {
    final content = _importedContent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (content != null) _buildImportedHero(content) else _buildEmptyHero(),
        const SizedBox(height: 22),
        if (content != null) _buildOverviewMetrics(content),
        if (content != null) const SizedBox(height: 22),
        _buildEditorCard(
          title: 'Competency Information',
          icon: Icons.info_outline_rounded,
          child: _buildCompetencyInformation(content),
        ),
        const SizedBox(height: 20),
        _buildSavedDraftsCard(),
        const SizedBox(height: 20),
        _buildPublishedContentCard(),
        const SizedBox(height: 20),
        if (content != null)
          _buildStructureSnapshot(content)
        else
          _buildEmptyAnalysis(),
        const SizedBox(height: 20),
        _buildEditorCard(
          title: 'Publishing Information',
          icon: Icons.publish_rounded,
          child: _buildPublishingInformation(content),
        ),
      ],
    );
  }

  Widget _buildImportedHero(StudyContent content) {
    final subtitle =
        'Domain ${content.domainId}  •  '
        'Competency ${content.competencyId}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [StudyColors.primary, StudyColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: StudyRadius.large,
        boxShadow: StudyShadows.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: StudyRadius.medium,
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const Spacer(),
              _buildHeroStatus(content.status),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'CSP11 COMPETENCY',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            content.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeroMeta('CONTENT ID', content.id),
                const SizedBox(width: 24),
                _buildHeroMeta('VERSION', 'v${content.version}'),
                const SizedBox(width: 24),
                _buildHeroMeta('COMPETENCY', '${content.competencyNumber}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [StudyColors.primary, StudyColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: StudyRadius.large,
        boxShadow: StudyShadows.medium,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
          SizedBox(height: 18),
          Text(
            'CSP11 STUDY CONTENT',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Build your next competency',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Import a complete content package to begin.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStatus(String status) {
    final normalized = status.toLowerCase();

    final isPublished = normalized == 'published';

    final color = isPublished ? StudyColors.success : StudyColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: StudyRadius.pillRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 7),
          Text(
            status.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMeta(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // OVERVIEW METRICS
  // ==========================================================

  Widget _buildOverviewMetrics(StudyContent content) {
    final statistics = _ContentStatistics.fromContent(content);

    final metrics = [
      _OverviewMetric(
        value: '${statistics.subtopics}',
        label: 'Subtopics',
        icon: Icons.account_tree_rounded,
      ),
      _OverviewMetric(
        value: '${statistics.mainTopics}',
        label: 'Main Topics',
        icon: Icons.menu_book_rounded,
      ),
      _OverviewMetric(
        value: '${statistics.blocks}',
        label: 'Content Blocks',
        icon: Icons.view_agenda_rounded,
      ),
      _OverviewMetric(
        value: '${statistics.learningObjectives}',
        label: 'Objectives',
        icon: Icons.flag_rounded,
      ),
      _OverviewMetric(
        value: '${statistics.quizReferences}',
        label: 'Quiz Links',
        icon: Icons.quiz_rounded,
      ),
      _OverviewMetric(
        value: '$_overviewQuestionCount',
        label: 'Questions',
        icon: Icons.help_outline_rounded,
      ),
      _OverviewMetric(
        value: '$_overviewPublishedCount',
        label: 'Published',
        icon: Icons.publish_rounded,
      ),
      _OverviewMetric(
        value: _overviewQuizReady ? 'READY' : 'INCOMPLETE',
        label: 'Quiz Status',
        icon: _overviewQuizReady
            ? Icons.check_circle_rounded
            : Icons.warning_amber_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 4
            : constraints.maxWidth >= 720
            ? 3
            : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.25,
          ),
          itemBuilder: (context, index) {
            return _buildOverviewMetric(metrics[index]);
          },
        );
      },
    );
  }

  _OverviewQuizStatistics _calculateOverviewQuizStatistics(
    StudyContent content,
  ) {
    var questionCount = 0;
    var publishedCount = 0;
    var expectedQuestionCount = 0;
    var ready = content.subtopics.isNotEmpty;

    for (final subtopic in content.subtopics) {
      expectedQuestionCount += 5;

      final quizId = _resolveExistingQuizIdForOverview(content, subtopic);

      if (quizId.isEmpty) {
        ready = false;
        continue;
      }

      final questions = _questionService.byQuizId(quizId);
      final subtopicQuestionCount = questions.length;
      final subtopicPublishedCount = questions
          .where((question) => question.status.toLowerCase() == 'published')
          .length;

      questionCount += subtopicQuestionCount;
      publishedCount += subtopicPublishedCount;

      if (!QuizService.hasMinimumPublishedQuestions(subtopicPublishedCount)) {
        ready = false;
      }
    }

    return _OverviewQuizStatistics(
      questionCount: questionCount,
      publishedCount: publishedCount,
      expectedQuestionCount: expectedQuestionCount,
      ready: ready,
    );
  }

  String _resolveExistingQuizIdForOverview(
    StudyContent content,
    StudySubtopic subtopic,
  ) {
    final linkedQuizId = subtopic.quizzes
        .map((quiz) => quiz.quizId.trim())
        .firstWhere((quizId) => quizId.isNotEmpty, orElse: () => '');

    if (linkedQuizId.isNotEmpty) {
      return linkedQuizId;
    }

    final resolvedQuizId = _resolvedPracticeQuizId?.trim() ?? '';
    if (resolvedQuizId.isNotEmpty &&
        _questionService
            .byQuizId(resolvedQuizId)
            .any((question) => question.subtopicId == subtopic.id)) {
      return resolvedQuizId;
    }

    final candidates = _questionService
        .allManagedQuestions()
        .where(
          (question) =>
              question.subtopicId == subtopic.id &&
              question.status.toLowerCase() == 'published',
        )
        .toList();

    if (candidates.isNotEmpty) {
      final counts = <String, int>{};
      for (final question in candidates) {
        final candidateQuizId = question.quizId.trim();
        if (candidateQuizId.isNotEmpty) {
          counts[candidateQuizId] = (counts[candidateQuizId] ?? 0) + 1;
        }
      }

      if (counts.isNotEmpty) {
        final sortedQuizIds = counts.entries.toList()
          ..sort((a, b) {
            final countComparison = b.value.compareTo(a.value);
            if (countComparison != 0) {
              return countComparison;
            }
            return a.key.compareTo(b.key);
          });
        return sortedQuizIds.first.key;
      }
    }

    return '${content.id}_${subtopic.id}_quiz';
  }

  Widget _buildOverviewMetric(_OverviewMetric metric) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.medium,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: StudyColors.primaryLight,
              borderRadius: StudyRadius.small,
            ),
            child: Icon(metric.icon, size: 18, color: StudyColors.primary),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.value,
                  style: StudyTypography.cardTitle.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 2),
                Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StudyTypography.bodySecondary.copyWith(fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // COMPETENCY INFORMATION
  // ==========================================================

  Widget _buildCompetencyInformation(StudyContent? content) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 760;

        final fields = [
          _InfoField(
            label: 'Domain ID',
            value: content?.domainId ?? '',
            hint: 'domain_07',
          ),
          _InfoField(
            label: 'Competency ID',
            value: content?.competencyId ?? '',
            hint: 'domain_07_01',
          ),
          _InfoField(
            label: 'Competency Number',
            value: content == null ? '' : '${content.competencyNumber}',
            hint: '1',
          ),
          _InfoField(
            label: 'Title',
            value: content?.title ?? '',
            hint: 'Enter competency title',
          ),
        ];

        if (!twoColumns) {
          return Column(
            children: [
              for (var i = 0; i < fields.length; i++) ...[
                _buildInfoField(fields[i]),
                if (i != fields.length - 1) const SizedBox(height: 14),
              ],
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildInfoField(fields[0])),
                const SizedBox(width: 14),
                Expanded(child: _buildInfoField(fields[1])),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                SizedBox(width: 220, child: _buildInfoField(fields[2])),
                const SizedBox(width: 14),
                Expanded(child: _buildInfoField(fields[3])),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoField(_InfoField field) {
    final hasValue = field.value.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: hasValue ? StudyColors.surfaceSoft : StudyColors.background,
        borderRadius: StudyRadius.medium,
        border: Border.all(color: StudyColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label.toUpperCase(),
            style: StudyTypography.eyebrow.copyWith(
              fontSize: 9,
              color: StudyColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasValue ? field.value : field.hint,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: StudyTypography.body.copyWith(
              color: hasValue
                  ? StudyColors.textPrimary
                  : StudyColors.textSecondary,
              fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // STRUCTURE SNAPSHOT
  // ==========================================================

  Widget _buildStructureSnapshot(StudyContent content) {
    return _buildEditorCard(
      title: 'Content Structure',
      icon: Icons.account_tree_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Current learning architecture',
                  style: StudyTypography.bodySecondary,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedSection = 2;
                  });
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('Open Subtopics'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < content.subtopics.length; index++)
            _buildSubtopicSnapshot(content.subtopics[index], index),
        ],
      ),
    );
  }

  Widget _buildSubtopicSnapshot(StudySubtopic subtopic, int index) {
    var blocks = 0;

    for (final topic in subtopic.mainContent) {
      blocks += topic.blocks.length;
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(
        bottom: index == _importedContent!.subtopics.length - 1 ? 0 : 10,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StudyColors.surfaceSoft,
        borderRadius: StudyRadius.medium,
        border: Border.all(color: StudyColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: StudyColors.primaryLight,
              borderRadius: StudyRadius.small,
            ),
            child: Text(
              '${index + 1}',
              style: StudyTypography.label.copyWith(color: StudyColors.primary),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtopic.title,
                  style: StudyTypography.label.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '${subtopic.mainContent.length} main topics  •  '
                  '$blocks content blocks  •  '
                  '${subtopic.learningObjectives.length} objectives',
                  style: StudyTypography.bodySecondary.copyWith(fontSize: 10.5),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: StudyColors.textSecondary,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PUBLISHING
  // ==========================================================

  Widget _buildPublishingInformation(StudyContent? content) {
    return Column(
      children: [
        _buildInfoRow(
          'Status',
          content?.status ?? 'draft',
          content == null ? StudyColors.warning : _statusColor(content.status),
        ),
        const Divider(height: 26),
        _buildInfoRow(
          'Version',
          content == null ? '1' : '${content.version}',
          StudyColors.primary,
        ),
        const Divider(height: 26),
        _buildInfoRow(
          'Content ID',
          content?.id ?? 'Not assigned',
          content == null ? StudyColors.textSecondary : StudyColors.success,
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'published':
        return StudyColors.success;
      case 'review':
        return StudyColors.info;
      case 'archived':
        return StudyColors.textSecondary;
      default:
        return StudyColors.warning;
    }
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Row(
      children: [
        Expanded(child: Text(label, style: StudyTypography.bodySecondary)),
        Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: StudyRadius.pillRadius,
          ),
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: StudyTypography.label.copyWith(color: color),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // EMPTY ANALYSIS
  // ==========================================================

  Widget _buildEmptyAnalysis() {
    return _buildEditorCard(
      title: 'Content Structure',
      icon: Icons.analytics_rounded,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: StudyColors.surfaceSoft,
          borderRadius: StudyRadius.medium,
          border: Border.all(color: StudyColors.border),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.data_object_rounded,
              size: 38,
              color: StudyColors.textSecondary,
            ),
            SizedBox(height: 12),
            Text('No content imported yet', style: StudyTypography.cardTitle),
            SizedBox(height: 6),
            Text(
              'Use Import Complete Content to load a '
              'CSP11 competency package.',
              textAlign: TextAlign.center,
              style: StudyTypography.bodySecondary,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // GENERIC EDITOR CARD
  // ==========================================================

  Widget _buildEditorCard({
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
          Padding(padding: const EdgeInsets.all(22), child: child),
        ],
      ),
    );
  }

  // ==========================================================
  // PLACEHOLDER BUILDERS
  // ==========================================================

  Widget _buildPlaceholderEditor(
    String title,
    String description,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeading(
          eyebrow: 'CONTENT BUILDER',
          title: title,
          description: description,
        ),
        const SizedBox(height: 24),
        _buildEditorCard(
          title: 'Builder Ready',
          icon: icon,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: StudyColors.surfaceSoft,
              borderRadius: StudyRadius.medium,
              border: Border.all(color: StudyColors.border),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 42,
                  color: StudyColors.primary,
                ),
                SizedBox(height: 14),
                Text(
                  'Content builder coming next',
                  style: StudyTypography.cardTitle,
                ),
                SizedBox(height: 6),
                Text(
                  'The structured editor will be added here.',
                  textAlign: TextAlign.center,
                  style: StudyTypography.bodySecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageHeading({
    required String eyebrow,
    required String title,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: StudyTypography.eyebrow.copyWith(color: StudyColors.primary),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: StudyTypography.heroTitle.copyWith(
            color: StudyColors.textPrimary,
            fontSize: 30,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          description,
          style: StudyTypography.bodySecondary.copyWith(fontSize: 14.5),
        ),
      ],
    );
  }

  // ==========================================================
  // ACTIONS
  // ==========================================================

  void _returnToAdminHome() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _openStudentPortal() {
    final content = _importedContent;

    if (content == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No competency is currently loaded.')),
      );
      return;
    }

    if (content.status.toLowerCase() != 'published') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Student Portal is available after this competency is published.',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StudyContentScreen(
          domainId: content.domainId,
          competencyId: content.competencyId,
          loadingTitle: content.title,
        ),
      ),
    );
  }

  void _openPreview() {
    setState(() {
      _selectedSection = 7;
    });
  }

  Future<void> _loadRepositoryContent() async {
    await Future.wait([_loadDrafts(), _loadPublishedContent()]);

    if (!mounted || _importedContent != null) {
      return;
    }

    if (_savedDrafts.isNotEmpty) {
      await _openDraft(_savedDrafts.first, showMessage: false);
      return;
    }

    if (_publishedContent.isNotEmpty) {
      await _openPublished(_publishedContent.first, showMessage: false);
    }
  }

  Future<void> _loadDrafts() async {
    if (_loadingDrafts) {
      return;
    }

    setState(() {
      _loadingDrafts = true;
    });

    try {
      final drafts = await _repository.loadDrafts();

      if (!mounted) {
        return;
      }

      setState(() {
        _savedDrafts = drafts;
        _loadingDrafts = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingDrafts = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to load drafts.\n$error')));
    }
  }

  Future<void> _loadPublishedContent() async {
    if (_loadingPublished) {
      return;
    }

    setState(() {
      _loadingPublished = true;
    });

    try {
      final published = await _repository.loadPublished();

      if (!mounted) {
        return;
      }

      setState(() {
        _publishedContent = published;
        _loadingPublished = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingPublished = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load published content.\n$error')),
      );
    }
  }

  StudyContent _withStatus(StudyContent content, String status) {
    final json = Map<String, dynamic>.from(content.toJson());

    json['status'] = status;

    return StudyContent.fromJson(json);
  }

  Future<void> _saveDraft() async {
    final content = _importedContent;

    if (content == null) {
      return;
    }

    if (content.status.toLowerCase() == 'published' ||
        content.status.toLowerCase() == 'archived') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Published and archived versions cannot be edited directly.',
          ),
        ),
      );
      return;
    }

    if (!_isDraft) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only Draft content can be saved using Save Draft.'),
        ),
      );

      return;
    }

    try {
      await _repository.saveDraft(content);
      await _loadDrafts();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft saved successfully.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save draft.\\n$error')));
    }
  }

  Future<void> _sendToReview() async {
    final content = _importedContent;

    if (content == null || !_isDraft) {
      return;
    }

    final reviewedContent = _withStatus(content, 'review');

    try {
      await _repository.saveDraft(reviewedContent);

      if (!mounted) {
        return;
      }

      setState(() {
        _importedContent = reviewedContent;
      });

      await _loadDrafts();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content moved to Review successfully.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to move content to Review.\\n$error')),
      );
    }
  }

  Future<void> _validateContent() async {
    final content = _importedContent;

    if (content == null || !_isReview) {
      return;
    }

    final issues = const ContentValidator().validate(content);
    final hasErrors = issues.any(
      (issue) => issue.severity == ContentImportIssueSeverity.error,
    );

    if (hasErrors) {
      setState(() {
        _selectedSection = 6;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Validation failed. Resolve all validation errors first.',
          ),
        ),
      );

      return;
    }

    try {
      await _repository.updateDraftStatus(content.id, 'validated');

      final validated = _withStatus(content, 'validated');

      if (!mounted) return;

      setState(() {
        _importedContent = validated;
      });

      await _loadDrafts();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Validation passed. Content is now VALIDATED.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to validate content.\\n$error')),
      );
    }
  }

  Future<void> _publishContent() async {
    final content = _importedContent;

    if (content == null || !_isValidated) {
      return;
    }

    if (!_isValidationReady) {
      setState(() {
        _selectedSection = 6;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Publishing is blocked. Resolve all validation errors first.',
          ),
        ),
      );

      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Publish content?'),
          content: Text(
            'Publish "${content.title}" to the student-facing repository?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.publish_rounded),
              label: const Text('Publish'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _repository.publish(content);

      final publishedContent = _withStatus(content, 'published');

      if (!mounted) {
        return;
      }

      setState(() {
        _importedContent = publishedContent;
      });

      await _loadPublishedContent();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content published successfully.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to publish content.\\n$error')),
      );
    }
  }

  Future<void> _openDraft(StudyContent draft, {bool showMessage = true}) async {
    setState(() {
      _importedContent = draft;
      _selectedSubtopicIndex = draft.subtopics.isEmpty ? null : 0;
      _selectedMainContentIndex =
          draft.subtopics.isNotEmpty &&
              draft.subtopics.first.mainContent.isNotEmpty
          ? 0
          : null;
      _selectedSection = 0;
      _resolvedPracticeQuizId = null;
    });

    await _refreshPracticeQuestions();

    if (!mounted) {
      return;
    }

    if (showMessage) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Draft loaded: ${draft.title}')));
    }
  }

  Future<void> _openPublished(
    StudyContent content, {
    bool showMessage = true,
  }) async {
    final published = _withStatus(content, 'published');

    setState(() {
      _importedContent = published;
      _selectedSubtopicIndex = published.subtopics.isEmpty ? null : 0;
      _selectedMainContentIndex =
          published.subtopics.isNotEmpty &&
              published.subtopics.first.mainContent.isNotEmpty
          ? 0
          : null;
      _selectedSection = 0;
      _resolvedPracticeQuizId = null;
    });

    await _refreshPracticeQuestions();

    if (!mounted) {
      return;
    }

    if (showMessage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Published content loaded: ${content.title}')),
      );
    }
  }

  Future<void> _createRevision(StudyContent published) async {
    if (published.status.toLowerCase() != 'published') {
      return;
    }

    try {
      final draftRevision = await _contentRepositoryService.createRevision(
        published,
      );

      await _loadDrafts();

      if (!mounted) {
        return;
      }

      await _openDraft(draftRevision, showMessage: false);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Revision created: '
            '${draftRevision.title} v${draftRevision.version}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to create revision.\n$error')),
      );
    }
  }

  Future<void> _deleteDraft(StudyContent draft) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete draft?'),
          content: Text(
            'Delete "${draft.title}" from saved drafts? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _repository.deleteDraft(draft.id);
      await _loadDrafts();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Draft deleted: ${draft.title}')));
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete draft.\n$error')),
      );
    }
  }

  Future<void> _deletePublished(StudyContent published) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete published content?'),
          content: Text(
            'Delete \"${published.title}\" v${published.version} from the published repository? '
            'Students will no longer be able to access this published version. This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _repository.deletePublished(published.id);
      await _loadPublishedContent();

      if (!mounted) {
        return;
      }

      if (_importedContent?.id == published.id) {
        setState(() {
          _importedContent = null;
          _selectedSubtopicIndex = null;
          _selectedMainContentIndex = null;
          _selectedSection = 0;
          _resolvedPracticeQuizId = null;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Published content deleted: ${published.title} v${published.version}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete published content.\n$error')),
      );
    }
  }

  Widget _buildSavedDraftsCard() {
    return _buildEditorCard(
      title: 'Saved Drafts',
      icon: Icons.folder_copy_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Drafts stored in the local content repository',
                  style: StudyTypography.bodySecondary,
                ),
              ),
              IconButton(
                tooltip: 'Refresh drafts',
                onPressed: _loadingDrafts ? null : _loadDrafts,
                icon: _loadingDrafts
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loadingDrafts && _savedDrafts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_savedDrafts.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: StudyColors.surfaceSoft,
                borderRadius: StudyRadius.medium,
                border: Border.all(color: StudyColors.border),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 36,
                    color: StudyColors.textSecondary,
                  ),
                  SizedBox(height: 10),
                  Text('No saved drafts', style: StudyTypography.cardTitle),
                  SizedBox(height: 5),
                  Text(
                    'Save an imported competency to make it available here after restarting the app.',
                    textAlign: TextAlign.center,
                    style: StudyTypography.bodySecondary,
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                for (var index = 0; index < _savedDrafts.length; index++)
                  _buildSavedDraftRow(_savedDrafts[index], index),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPublishedContentCard() {
    return _buildEditorCard(
      title: 'Published Content',
      icon: Icons.cloud_done_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Content currently available in the published repository',
                  style: StudyTypography.bodySecondary,
                ),
              ),
              IconButton(
                tooltip: 'Refresh published content',
                onPressed: _loadingPublished ? null : _loadPublishedContent,
                icon: _loadingPublished
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loadingPublished && _publishedContent.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_publishedContent.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: StudyColors.surfaceSoft,
                borderRadius: StudyRadius.medium,
                border: Border.all(color: StudyColors.border),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 36,
                    color: StudyColors.textSecondary,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'No published content',
                    style: StudyTypography.cardTitle,
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Published competencies will appear here after they are released.',
                    textAlign: TextAlign.center,
                    style: StudyTypography.bodySecondary,
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                for (var index = 0; index < _publishedContent.length; index++)
                  _buildPublishedContentRow(_publishedContent[index], index),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPublishedContentRow(StudyContent content, int index) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(
        bottom: index == _publishedContent.length - 1 ? 0 : 10,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StudyColors.surfaceSoft,
        borderRadius: StudyRadius.medium,
        border: Border.all(color: StudyColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: StudyColors.successLight,
                borderRadius: StudyRadius.small,
              ),
              child: const Icon(
                Icons.verified_rounded,
                color: StudyColors.success,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StudyTypography.label.copyWith(fontSize: 12.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Competency ${content.competencyNumber}  •  '
                    '${content.competencyId}  •  v${content.version}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StudyTypography.bodySecondary.copyWith(
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: StudyColors.successLight,
                borderRadius: StudyRadius.pillRadius,
              ),
              child: const Text(
                'PUBLISHED',
                style: TextStyle(
                  color: StudyColors.success,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _openPublished(content),
              icon: const Icon(Icons.visibility_rounded, size: 16),
              label: const Text('Open'),
            ),
            const SizedBox(width: 6),
            OutlinedButton.icon(
              onPressed: () => _createRevision(content),
              icon: const Icon(Icons.fork_right_rounded, size: 16),
              label: const Text('Create Revision'),
            ),
            const SizedBox(width: 6),
            OutlinedButton.icon(
              onPressed: () => _deletePublished(content),
              icon: const Icon(Icons.delete_outline_rounded, size: 16),
              label: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedDraftRow(StudyContent draft, int index) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(
        bottom: index == _savedDrafts.length - 1 ? 0 : 10,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StudyColors.surfaceSoft,
        borderRadius: StudyRadius.medium,
        border: Border.all(color: StudyColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: StudyColors.primaryLight,
                borderRadius: StudyRadius.small,
              ),
              child: const Icon(
                Icons.description_rounded,
                color: StudyColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    draft.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StudyTypography.label.copyWith(fontSize: 12.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Competency ${draft.competencyNumber}  •  ${draft.competencyId}  •  v${draft.version}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StudyTypography.bodySecondary.copyWith(
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () => _openDraft(draft),
              icon: const Icon(Icons.folder_open_rounded, size: 16),
              label: const Text('Open'),
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Delete draft',
              onPressed: () => _deleteDraft(draft),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SUPPORTING MODELS
// ============================================================

class _StudioSection {
  final String title;
  final String subtitle;
  final IconData icon;

  const _StudioSection({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _OverviewQuizStatistics {
  final int questionCount;
  final int publishedCount;
  final int expectedQuestionCount;
  final bool ready;

  const _OverviewQuizStatistics({
    required this.questionCount,
    required this.publishedCount,
    required this.expectedQuestionCount,
    required this.ready,
  });
}

class _OverviewMetric {
  final String value;
  final String label;
  final IconData icon;

  const _OverviewMetric({
    required this.value,
    required this.label,
    required this.icon,
  });
}

class _InfoField {
  final String label;
  final String value;
  final String hint;

  const _InfoField({
    required this.label,
    required this.value,
    required this.hint,
  });
}

class _PracticeMetric {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _PracticeMetric({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _ContentStatistics {
  final int subtopics;
  final int mainTopics;
  final int blocks;
  final int learningObjectives;
  final int examples;
  final int caseStudies;
  final int references;
  final int quizReferences;

  const _ContentStatistics({
    required this.subtopics,
    required this.mainTopics,
    required this.blocks,
    required this.learningObjectives,
    required this.examples,
    required this.caseStudies,
    required this.references,
    required this.quizReferences,
  });

  factory _ContentStatistics.fromContent(StudyContent content) {
    var mainTopics = 0;
    var blocks = 0;
    var learningObjectives = 0;
    var examples = 0;
    var caseStudies = 0;
    var references = 0;
    var quizReferences = 0;

    for (final subtopic in content.subtopics) {
      learningObjectives += subtopic.learningObjectives.length;

      examples += subtopic.examples.length;

      caseStudies += subtopic.caseStudies.length;

      references += subtopic.references.length;

      quizReferences += subtopic.quizzes.length;

      for (final topic in subtopic.mainContent) {
        mainTopics++;
        blocks += topic.blocks.length;
        quizReferences += topic.quizzes.length;
      }
    }

    return _ContentStatistics(
      subtopics: content.subtopics.length,
      mainTopics: mainTopics,
      blocks: blocks,
      learningObjectives: learningObjectives,
      examples: examples,
      caseStudies: caseStudies,
      references: references,
      quizReferences: quizReferences,
    );
  }
}
