import 'package:flutter/material.dart';

import '../../../data/csp11_blueprint.dart';
import '../../../models/content_repository.dart';
import '../../../theme/study/study_colors.dart';
import '../../../theme/study/study_radius.dart';
import '../../../theme/study/study_shadows.dart';
import '../../../theme/study/study_typography.dart';

class RepositoryVersionScreen extends StatelessWidget {
  final ContentPackageSummary package;

  const RepositoryVersionScreen({super.key, required this.package});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StudyColors.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: StudyColors.surface,
        foregroundColor: StudyColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version Inspector',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 2),
            Text(
              'Read-only content version inspection',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: StudyColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildMetadata(),
                const SizedBox(height: 16),
                _buildStructure(),
                const SizedBox(height: 16),
                _buildSubtopics(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final domain = domainForContentId(package.content.domainId);
    final content = package.content;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: StudyColors.primary,
                  borderRadius: StudyRadius.medium,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'VER',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '${content.version}.0',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COMPETENCY ${content.competencyNumber}',
                      style: StudyTypography.eyebrow.copyWith(
                        color: StudyColors.primary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(content.title, style: StudyTypography.sectionTitle),
                    const SizedBox(height: 5),
                    Text(
                      domain == null
                          ? content.domainId
                          : 'Domain ${domain.number} • '
                                '${domain.title}',
                      style: StudyTypography.bodySecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _statusBadge(package.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadata() {
    final content = package.content;

    return _section(
      title: 'VERSION METADATA',
      child: Column(
        children: [
          _metadataRow('Package ID', content.id),
          _metadataRow('Competency ID', content.competencyId),
          _metadataRow('Competency Number', '${content.competencyNumber}'),
          _metadataRow('Domain ID', content.domainId),
          _metadataRow('Version', '${content.version}.0'),
          _metadataRow('Lifecycle', package.status.toUpperCase()),
          _metadataRow(
            'Completeness',
            '${(package.completeness * 100).round()}%',
          ),
        ],
      ),
    );
  }

  Widget _metadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 155,
            child: Text(label, style: StudyTypography.caption),
          ),
          Expanded(
            child: Text(
              value,
              style: StudyTypography.caption.copyWith(
                color: StudyColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStructure() {
    final content = package.content;

    var mainTopics = 0;
    var blocks = 0;
    var objectives = 0;
    var examples = 0;
    var caseStudies = 0;
    var references = 0;
    var quizLinks = 0;

    for (final subtopic in content.subtopics) {
      objectives += subtopic.learningObjectives.length;
      examples += subtopic.examples.length;
      caseStudies += subtopic.caseStudies.length;
      references += subtopic.references.length;
      quizLinks += subtopic.quizzes.length;

      for (final topic in subtopic.mainContent) {
        mainTopics++;
        blocks += topic.blocks.length;
        quizLinks += topic.quizzes.length;
      }
    }

    return _section(
      title: 'VERSION CONTENT STRUCTURE',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _stat('Subtopics', content.subtopics.length),
          _stat('Main Topics', mainTopics),
          _stat('Content Blocks', blocks),
          _stat('Objectives', objectives),
          _stat('Examples', examples),
          _stat('Case Studies', caseStudies),
          _stat('References', references),
          _stat('Quiz Links', quizLinks),
          _stat('Questions', package.questionCount),
        ],
      ),
    );
  }

  Widget _stat(String label, int value) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StudyColors.surfaceSoft,
        borderRadius: StudyRadius.medium,
        border: Border.all(color: StudyColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: StudyTypography.caption),
          const SizedBox(height: 4),
          Text('$value', style: StudyTypography.cardTitle),
        ],
      ),
    );
  }

  Widget _buildSubtopics() {
    final subtopics = package.content.subtopics;

    return _section(
      title: 'SUBTOPIC REGISTER',
      child: subtopics.isEmpty
          ? const Text('No subtopics are currently stored in this version.')
          : Column(
              children: subtopics.asMap().entries.map((entry) {
                final index = entry.key;
                final subtopic = entry.value;

                return Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(
                    bottom: index == subtopics.length - 1 ? 0 : 8,
                  ),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: StudyColors.surfaceSoft,
                    borderRadius: StudyRadius.medium,
                    border: Border.all(color: StudyColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: StudyColors.primaryLight,
                          borderRadius: StudyRadius.small,
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: StudyColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(subtopic.title, style: StudyTypography.label),
                            const SizedBox(height: 7),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _miniPill(
                                  'Topics',
                                  subtopic.mainContent.length,
                                ),
                                _miniPill(
                                  'Objectives',
                                  subtopic.learningObjectives.length,
                                ),
                                _miniPill(
                                  'Quiz Links',
                                  subtopic.quizzes.length,
                                ),
                                _miniPill(
                                  'References',
                                  subtopic.references.length,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _miniPill(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.pillRadius,
        border: Border.all(color: StudyColors.border),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: StudyColors.textSecondary,
        ),
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
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
          Text(
            title,
            style: StudyTypography.eyebrow.copyWith(color: StudyColors.primary),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: StudyRadius.pillRadius,
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
          color: color,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'published':
        return StudyColors.success;
      case 'validated':
        return StudyColors.info;
      case 'review':
        return StudyColors.warning;
      case 'archived':
        return StudyColors.textSecondary;
      default:
        return StudyColors.examTip;
    }
  }
}
