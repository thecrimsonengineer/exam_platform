import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../../models/study_content.dart';
import '../../../services/study_content/content_import_service.dart';
import '../../../theme/study/study_colors.dart';
import '../../../theme/study/study_radius.dart';
import '../../../theme/study/study_shadows.dart';
import '../../../theme/study/study_typography.dart';

class ContentImportPanel extends StatefulWidget {
  final ValueChanged<StudyContent>? onImported;

  const ContentImportPanel({super.key, this.onImported});

  @override
  State<ContentImportPanel> createState() => _ContentImportPanelState();
}

class _ContentImportPanelState extends State<ContentImportPanel> {
  final TextEditingController _jsonController = TextEditingController();

  final _importService = const ContentImportService();

  ContentImportResult? _result;
  bool _isImporting = false;
  bool _isPickingFile = false;
  String? _selectedFileName;
  int? _selectedFileSize;

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _pickJsonFile() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isPickingFile = true;
    });

    try {
      const jsonTypeGroup = XTypeGroup(
        label: 'JSON files',
        extensions: <String>['json'],
        mimeTypes: <String>['application/json'],
      );

      final XFile? file = await openFile(
        acceptedTypeGroups: <XTypeGroup>[jsonTypeGroup],
      );

      if (!mounted || file == null) {
        return;
      }

      final bytes = await file.readAsBytes();
      final jsonText = utf8.decode(bytes, allowMalformed: false);

      if (!mounted) {
        return;
      }

      setState(() {
        _jsonController.text = jsonText;
        _selectedFileName = file.name;
        _selectedFileSize = bytes.length;
        _result = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Loaded ${file.name}. Ready to validate and import.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on FormatException {
      _showFileError(
        'The selected file is not valid UTF-8 JSON text.',
      );
    } catch (error) {
      _showFileError('Unable to load the JSON file.\n$error');
    } finally {
      if (mounted) {
        setState(() {
          _isPickingFile = false;
        });
      }
    }
  }

  void _showFileError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _importContent() {
    FocusScope.of(context).unfocus();

    setState(() {
      _isImporting = true;
      _result = null;
    });

    final result = _importService.importJson(_jsonController.text);

    setState(() {
      _result = result;
      _isImporting = false;
    });

    if (result.isSuccessful && result.content != null) {
      widget.onImported?.call(result.content!);
    }
  }

  void _clearContent() {
    _jsonController.clear();

    setState(() {
      _result = null;
      _selectedFileName = null;
      _selectedFileSize = null;
    });
  }

  void _loadExample() {
    _jsonController.text = _exampleJson;

    setState(() {
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeading(),
        const SizedBox(height: 24),
        _buildImportCard(),
        if (_result != null) ...[
          const SizedBox(height: 20),
          _buildAnalysisCard(),
        ],
      ],
    );
  }

  Widget _buildPageHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'IMPORT',
          style: StudyTypography.eyebrow.copyWith(color: StudyColors.primary),
        ),
        const SizedBox(height: 6),
        Text(
          'Import Complete Content',
          style: StudyTypography.heroTitle.copyWith(
            color: StudyColors.textPrimary,
            fontSize: 30,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Paste one complete CSP11 competency package and let the '
          'Studio analyze, validate and structure it automatically.',
          style: StudyTypography.bodySecondary.copyWith(fontSize: 14.5),
        ),
      ],
    );
  }

  Widget _buildImportCard() {
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
          _buildCardHeader(),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInstructionBanner(),
                const SizedBox(height: 18),
                _buildJsonEditor(),
                const SizedBox(height: 18),
                _buildActionRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: StudyColors.surfaceSoft,
        border: Border(bottom: BorderSide(color: StudyColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: StudyColors.primaryLight,
              borderRadius: StudyRadius.medium,
            ),
            child: const Icon(
              Icons.data_object_rounded,
              color: StudyColors.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complete Content Package',
                  style: StudyTypography.subSectionTitle,
                ),
                SizedBox(height: 3),
                Text(
                  'Deterministic JSON importer',
                  style: StudyTypography.bodySecondary,
                ),
              ],
            ),
          ),
          _buildJsonStatus(),
        ],
      ),
    );
  }

  Widget _buildJsonStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: StudyColors.primaryLight,
        borderRadius: StudyRadius.pillRadius,
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 14,
            color: StudyColors.primary,
          ),
          SizedBox(width: 6),
          Text(
            'JSON',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: StudyColors.primary,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StudyColors.infoLight,
        borderRadius: StudyRadius.medium,
        border: Border.all(color: StudyColors.info.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: StudyColors.info,
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Import a complete CSP11 package',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: StudyColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Paste JSON directly or upload a .json file. Both paths use the same deterministic importer and validation pipeline.',
                      style: StudyTypography.bodySecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildFileUploadArea(),
        ],
      ),
    );
  }

  Widget _buildFileUploadArea() {
    final hasFile = _selectedFileName != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.medium,
        border: Border.all(
          color: hasFile
              ? StudyColors.success.withValues(alpha: 0.35)
              : StudyColors.border,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;

          final fileInfo = Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: hasFile
                      ? StudyColors.successLight
                      : StudyColors.primaryLight,
                  borderRadius: StudyRadius.medium,
                ),
                child: Icon(
                  hasFile
                      ? Icons.check_circle_rounded
                      : Icons.upload_file_rounded,
                  color: hasFile
                      ? StudyColors.success
                      : StudyColors.primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasFile ? _selectedFileName! : 'JSON file upload',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: StudyColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasFile
                          ? '${_formatFileSize(_selectedFileSize ?? 0)} • Ready to import'
                          : 'Choose a .json file from this device or computer',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StudyTypography.bodySecondary.copyWith(
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final button = OutlinedButton.icon(
            onPressed: _isPickingFile ? null : _pickJsonFile,
            icon: _isPickingFile
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.folder_open_rounded, size: 16),
            label: Text(_isPickingFile ? 'Opening...' : 'Choose JSON File'),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                fileInfo,
                const SizedBox(height: 10),
                button,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: fileInfo),
              const SizedBox(width: 14),
              button,
            ],
          );
        },
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Widget _buildJsonEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('CONTENT JSON', style: StudyTypography.eyebrow),
            const Spacer(),
            TextButton.icon(
              onPressed: _loadExample,
              icon: const Icon(Icons.auto_awesome_rounded, size: 15),
              label: const Text('Load Example'),
            ),
            const SizedBox(width: 4),
            TextButton.icon(
              onPressed: _clearContent,
              icon: const Icon(Icons.clear_rounded, size: 15),
              label: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 440,
          decoration: BoxDecoration(
            color: const Color(0xFF10151C),
            borderRadius: StudyRadius.medium,
            border: Border.all(color: StudyColors.border),
          ),
          child: TextField(
            controller: _jsonController,
            expands: true,
            maxLines: null,
            minLines: null,
            textAlignVertical: TextAlignVertical.top,
            style: const TextStyle(
              color: Color(0xFFE6EDF3),
              fontSize: 13,
              height: 1.55,
              fontFamily: 'monospace',
            ),
            decoration: const InputDecoration(
              hintText:
                  '{\n'
                  '  "id": "domain_07_01",\n'
                  '  "domainId": "domain_07",\n'
                  '  ...\n'
                  '}',
              hintStyle: TextStyle(
                color: Color(0xFF6B7280),
                fontFamily: 'monospace',
              ),
              contentPadding: EdgeInsets.all(18),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Expected root object: StudyContent JSON',
          style: StudyTypography.bodySecondary,
        ),
      ],
    );
  }

  Widget _buildActionRow() {
    return Row(
      children: [
        FilledButton.icon(
          onPressed: _isImporting ? null : _importContent,
          icon: _isImporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.file_download_rounded, size: 18),
          label: Text(_isImporting ? 'Importing...' : 'Import Content'),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Nothing is published automatically. Imported content '
            'must pass validation before it can move forward.',
            style: StudyTypography.bodySecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisCard() {
    final result = _result!;
    final content = result.content;

    if (content == null) {
      return _buildErrorCard(result);
    }

    final statistics = _ContentStatistics.fromContent(content);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnalysisHeader(result),
            const SizedBox(height: 20),
            _buildStatistics(statistics),
            if (result.issues.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildIssues(result),
            ],
            const SizedBox(height: 20),
            _buildResultBanner(result),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisHeader(ContentImportResult result) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: result.hasErrors
                ? StudyColors.dangerLight
                : StudyColors.successLight,
            borderRadius: StudyRadius.medium,
          ),
          child: Icon(
            result.hasErrors ? Icons.warning_rounded : Icons.analytics_rounded,
            color: result.hasErrors ? StudyColors.danger : StudyColors.success,
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Content Analysis', style: StudyTypography.subSectionTitle),
              SizedBox(height: 3),
              Text(
                'Parsed structure and validation results',
                style: StudyTypography.bodySecondary,
              ),
            ],
          ),
        ),
        _buildIssueCount(result.errorCount, 'Errors', StudyColors.danger),
        const SizedBox(width: 8),
        _buildIssueCount(result.warningCount, 'Warnings', StudyColors.warning),
      ],
    );
  }

  Widget _buildIssueCount(int count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: StudyRadius.pillRadius,
      ),
      child: Text(
        '$count $label',
        style: StudyTypography.label.copyWith(color: color),
      ),
    );
  }

  Widget _buildStatistics(_ContentStatistics statistics) {
    final cards = [
      _StatisticItem(
        label: 'Subtopics',
        value: statistics.subtopics,
        icon: Icons.account_tree_rounded,
      ),
      _StatisticItem(
        label: 'Main Topics',
        value: statistics.mainTopics,
        icon: Icons.menu_book_rounded,
      ),
      _StatisticItem(
        label: 'Content Blocks',
        value: statistics.blocks,
        icon: Icons.view_agenda_rounded,
      ),
      _StatisticItem(
        label: 'Learning Objectives',
        value: statistics.learningObjectives,
        icon: Icons.flag_rounded,
      ),
      _StatisticItem(
        label: 'Examples',
        value: statistics.examples,
        icon: Icons.lightbulb_outline_rounded,
      ),
      _StatisticItem(
        label: 'Case Studies',
        value: statistics.caseStudies,
        icon: Icons.business_center_outlined,
      ),
      _StatisticItem(
        label: 'References',
        value: statistics.references,
        icon: Icons.menu_book_outlined,
      ),
      _StatisticItem(
        label: 'Quiz References',
        value: statistics.quizReferences,
        icon: Icons.quiz_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final columns = width >= 900
            ? 4
            : width >= 600
            ? 2
            : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemBuilder: (context, index) {
            return _buildStatisticCard(cards[index]);
          },
        );
      },
    );
  }

  Widget _buildStatisticCard(_StatisticItem item) {
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
              color: StudyColors.primaryLight,
              borderRadius: StudyRadius.small,
            ),
            child: Icon(item.icon, size: 18, color: StudyColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item.value}', style: StudyTypography.cardTitle),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StudyTypography.bodySecondary.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssues(ContentImportResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('VALIDATION ISSUES', style: StudyTypography.eyebrow),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: StudyColors.surfaceSoft,
            borderRadius: StudyRadius.medium,
            border: Border.all(color: StudyColors.border),
          ),
          child: Column(
            children: [
              for (var index = 0; index < result.issues.length; index++) ...[
                _buildIssueRow(result.issues[index]),
                if (index != result.issues.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIssueRow(ContentImportIssue issue) {
    final isError = issue.severity == ContentImportIssueSeverity.error;

    final color = isError ? StudyColors.danger : StudyColors.warning;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.warning_amber_rounded,
            size: 19,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(issue.message, style: StudyTypography.body),
                if (issue.path != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    issue.path!,
                    style: StudyTypography.bodySecondary.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 11,
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

  Widget _buildResultBanner(ContentImportResult result) {
    if (result.hasErrors) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: StudyColors.dangerLight,
          borderRadius: StudyRadius.medium,
          border: Border.all(color: StudyColors.danger.withValues(alpha: 0.18)),
        ),
        child: const Row(
          children: [
            Icon(Icons.block_rounded, color: StudyColors.danger),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Import completed, but errors must be fixed '
                'before this content can proceed to publishing.',
                style: StudyTypography.body,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StudyColors.successLight,
        borderRadius: StudyRadius.medium,
        border: Border.all(color: StudyColors.success.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: StudyColors.success),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Content imported successfully. The structured '
              'StudyContent object is ready for the next stage.',
              style: StudyTypography.body,
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Structure Inspector will be connected next.'),
                ),
              );
            },
            icon: const Icon(Icons.account_tree_rounded, size: 16),
            label: const Text('Inspect Structure'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(ContentImportResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: StudyColors.dangerLight,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.danger.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: StudyColors.danger),
              SizedBox(width: 10),
              Text('Import Failed', style: StudyTypography.subSectionTitle),
            ],
          ),
          const SizedBox(height: 14),
          for (final issue in result.issues)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                issue.path == null
                    ? issue.message
                    : '${issue.message} (${issue.path})',
                style: StudyTypography.body,
              ),
            ),
        ],
      ),
    );
  }
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

class _StatisticItem {
  final String label;
  final int value;
  final IconData icon;

  const _StatisticItem({
    required this.label,
    required this.value,
    required this.icon,
  });
}

const String _exampleJson = '''
{
  "id": "domain_07_01",
  "domainId": "domain_07",
  "competencyId": "domain_07_01",
  "competencyNumber": 1,
  "title": "Training Needs Assessment",
  "status": "draft",
  "version": 1,
  "subtopics": [
    {
      "id": "domain_07_01_01",
      "title": "Training Needs Analysis",
      "learningObjectives": [
        "Explain the purpose of a training needs analysis.",
        "Identify factors that indicate a need for worker training."
      ],
      "mainContent": [
        {
          "id": "topic_001",
          "title": "What is Training Needs Analysis?",
          "blocks": [
            {
              "id": "block_001",
              "type": "heading",
              "data": {
                "title": "Definition",
                "level": 2
              }
            },
            {
              "id": "block_002",
              "type": "text",
              "data": {
                "content": "Training needs analysis is a systematic process used to identify gaps between current and required worker knowledge, skills and competencies."
              }
            }
          ],
          "quizzes": [
            {
              "quizId": "d07_topic_001_quiz"
            }
          ]
        }
      ],
      "keyPoints": [],
      "examples": [],
      "caseStudies": [],
      "formulas": [],
      "references": [],
      "examTips": [],
      "commonMistakes": [],
      "keyTakeaways": [],
      "quizzes": []
    }
  ]
}
''';
