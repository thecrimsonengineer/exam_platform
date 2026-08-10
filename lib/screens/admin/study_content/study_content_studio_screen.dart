import 'package:flutter/material.dart';

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

class StudyContentStudioScreen extends StatefulWidget {
  const StudyContentStudioScreen({super.key});

  @override
  State<StudyContentStudioScreen> createState() =>
      _StudyContentStudioScreenState();
}

class _StudyContentStudioScreenState extends State<StudyContentStudioScreen> {
  int _selectedSection = 0;

  final LocalStudyContentRepository _repository = LocalStudyContentRepository();

  StudyContent? _importedContent;

  int? _selectedSubtopicIndex;
  int? _selectedMainContentIndex;

  List<StudyContent> _savedDrafts = <StudyContent>[];
  bool _loadingDrafts = false;

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
    _loadDrafts();
  }

  @override
  Widget build(BuildContext context) {
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
      child: Row(
        children: [
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Study Content Studio',
                  style: StudyTypography.sectionTitle,
                ),
                SizedBox(height: 3),
                Text(
                  'Create and publish CSP11 learning content',
                  style: StudyTypography.bodySecondary,
                ),
              ],
            ),
          ),
          _buildStatusBadge(imported),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: imported ? _openPreview : null,
            icon: const Icon(Icons.visibility_rounded, size: 17),
            label: const Text('Preview'),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: imported ? _saveDraft : null,
            icon: const Icon(Icons.save_rounded, size: 17),
            label: const Text('Save Draft'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool imported) {
    final color = imported ? StudyColors.success : StudyColors.warning;

    final background = imported
        ? StudyColors.successLight
        : StudyColors.warningLight;

    final text = imported ? 'IMPORTED' : 'DRAFT';

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
          Icon(Icons.circle, size: 8, color: color),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(StudySpacing.pageHorizontalDesktop),
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
        return ContentImportPanel(
          onImported: (content) {
            setState(() {
              _importedContent = content;
              _selectedSubtopicIndex = content.subtopics.isEmpty ? null : 0;
            });
          },
        );

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
        return _buildPlaceholderEditor(
          'Practice Questions',
          'Connect practice quizzes to the learning content.',
          Icons.quiz_rounded,
        );

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
              });
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
          Row(
            children: [
              _buildHeroMeta('CONTENT ID', content.id),
              const SizedBox(width: 24),
              _buildHeroMeta('VERSION', 'v${content.version}'),
              const SizedBox(width: 24),
              _buildHeroMeta('COMPETENCY', '${content.competencyNumber}'),
            ],
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
        value: statistics.subtopics,
        label: 'Subtopics',
        icon: Icons.account_tree_rounded,
      ),
      _OverviewMetric(
        value: statistics.mainTopics,
        label: 'Main Topics',
        icon: Icons.menu_book_rounded,
      ),
      _OverviewMetric(
        value: statistics.blocks,
        label: 'Content Blocks',
        icon: Icons.view_agenda_rounded,
      ),
      _OverviewMetric(
        value: statistics.learningObjectives,
        label: 'Objectives',
        icon: Icons.flag_rounded,
      ),
      _OverviewMetric(
        value: statistics.quizReferences,
        label: 'Quiz Links',
        icon: Icons.quiz_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 5
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
                  '${metric.value}',
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

  void _openPreview() {
    setState(() {
      _selectedSection = 7;
    });
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

  Future<void> _saveDraft() async {
    final content = _importedContent;

    if (content == null) {
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
      ).showSnackBar(SnackBar(content: Text('Unable to save draft.\n$error')));
    }
  }

  Future<void> _openDraft(StudyContent draft) async {
    setState(() {
      _importedContent = draft;
      _selectedSubtopicIndex = draft.subtopics.isEmpty ? null : 0;
      _selectedMainContentIndex =
          draft.subtopics.isNotEmpty &&
              draft.subtopics.first.mainContent.isNotEmpty
          ? 0
          : null;
      _selectedSection = 0;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Draft loaded: ${draft.title}')));
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
      child: Row(
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
          Expanded(
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
                  style: StudyTypography.bodySecondary.copyWith(fontSize: 10.5),
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

class _OverviewMetric {
  final int value;
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
