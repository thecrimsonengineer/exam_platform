import 'package:flutter/material.dart';

import '../../../data/csp11_blueprint.dart';
import '../../../models/content_repository.dart';
import '../../../theme/study/study_colors.dart';
import '../../../theme/study/study_radius.dart';
import '../../../theme/study/study_shadows.dart';
import '../../../theme/study/study_typography.dart';
import 'repository_history_screen.dart';
import 'repository_version_screen.dart';

class RepositoryDetailScreen extends StatelessWidget {
  final ContentPackageSummary package;
  final List<ContentPackageSummary> allPackages;

  const RepositoryDetailScreen({
    super.key,
    required this.package,
    required this.allPackages,
  });

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
              'Repository Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 2),
            Text(
              'Content package command view',
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
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(context),
                const SizedBox(height: 16),
                _buildMetrics(),
                const SizedBox(height: 16),
                _buildStructure(),
                const SizedBox(height: 16),
                _buildLifecycle(),
                const SizedBox(height: 16),
                _buildActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final content = package.content;
    final domain = domainForContentId(content.domainId);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;

          final identity = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CONTENT PACKAGE',
                style: StudyTypography.eyebrow.copyWith(
                  color: StudyColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(content.title, style: StudyTypography.sectionTitle),
              const SizedBox(height: 7),
              Text(
                domain == null
                    ? content.domainId
                    : 'Domain ${domain.number} • ${domain.title}',
                style: StudyTypography.bodySecondary,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _identityPill(
                    'COMPETENCY ${content.competencyNumber}',
                    Icons.account_tree_rounded,
                  ),
                  _identityPill(content.competencyId, Icons.badge_outlined),
                  _identityPill(
                    'VERSION ${content.version}.0',
                    Icons.layers_outlined,
                  ),
                ],
              ),
            ],
          );

          final status = _statusBadge(package.status);

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [identity, const SizedBox(height: 16), status],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: identity),
              const SizedBox(width: 20),
              status,
            ],
          );
        },
      ),
    );
  }

  Widget _identityPill(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: StudyColors.surfaceSoft,
        borderRadius: StudyRadius.pillRadius,
        border: Border.all(color: StudyColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: StudyColors.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: StudyColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: StudyRadius.pillRadius,
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(status), size: 15, color: color),
          const SizedBox(width: 7),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 900
            ? 6
            : width >= 600
            ? 3
            : 2;

        final spacing = 10.0;
        final cardWidth = (width - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            _metric(
              cardWidth,
              'SUBTOPICS',
              '${package.subtopicCount}',
              Icons.account_tree_rounded,
            ),
            _metric(
              cardWidth,
              'MAIN TOPICS',
              '${package.topicCount}',
              Icons.menu_book_rounded,
            ),
            _metric(
              cardWidth,
              'CONTENT BLOCKS',
              '${package.blockCount}',
              Icons.view_agenda_rounded,
            ),
            _metric(
              cardWidth,
              'QUESTIONS',
              '${package.questionCount}',
              Icons.quiz_rounded,
            ),
            _metric(
              cardWidth,
              'COMPLETENESS',
              '${(package.completeness * 100).round()}%',
              Icons.donut_large_rounded,
            ),
            _metric(
              cardWidth,
              'VERSION',
              '${package.content.version}.0',
              Icons.layers_rounded,
            ),
          ],
        );
      },
    );
  }

  Widget _metric(double width, String label, String value, IconData icon) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
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
            child: Icon(icon, size: 18, color: StudyColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StudyTypography.eyebrow.copyWith(fontSize: 8.5),
                ),
                const SizedBox(height: 3),
                Text(value, style: StudyTypography.cardTitle),
              ],
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
      title: 'CONTENT STRUCTURE',
      subtitle: 'Live structure of this content version',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _structureTile('Subtopics', content.subtopics.length),
          _structureTile('Main Topics', mainTopics),
          _structureTile('Content Blocks', blocks),
          _structureTile('Objectives', objectives),
          _structureTile('Examples', examples),
          _structureTile('Case Studies', caseStudies),
          _structureTile('References', references),
          _structureTile('Quiz Links', quizLinks),
        ],
      ),
    );
  }

  Widget _structureTile(String label, int value) {
    return Container(
      width: 145,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: StudyColors.surfaceSoft,
        borderRadius: StudyRadius.medium,
        border: Border.all(color: StudyColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: StudyTypography.caption),
          const SizedBox(height: 5),
          Text('$value', style: StudyTypography.cardTitle),
        ],
      ),
    );
  }

  Widget _buildLifecycle() {
    const states = <String>[
      'draft',
      'review',
      'validated',
      'published',
      'archived',
    ];

    final currentIndex = states.indexOf(package.status.toLowerCase());

    return _section(
      title: 'LIFECYCLE',
      subtitle: 'Current package state and progression',
      child: Column(
        children: [
          Row(
            children: states.asMap().entries.map((entry) {
              final index = entry.key;
              final state = entry.value;
              final reached = currentIndex >= index && currentIndex >= 0;
              final active = currentIndex == index;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == states.length - 1 ? 0 : 5,
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: reached
                              ? _statusColor(state)
                              : StudyColors.progressTrack,
                          borderRadius: StudyRadius.pillRadius,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        active ? state.toUpperCase() : '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: _statusColor(state),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Current status', style: StudyTypography.caption),
              const Spacer(),
              _statusBadge(package.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return _section(
      title: 'REPOSITORY ACTIONS',
      subtitle: 'Inspect this version without changing its data',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RepositoryVersionScreen(package: package),
                ),
              );
            },
            icon: const Icon(Icons.visibility_rounded),
            label: const Text('Inspect Version'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RepositoryHistoryScreen(
                    package: package,
                    allPackages: allPackages,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.history_rounded),
            label: const Text('Version History'),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
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
          const SizedBox(height: 4),
          Text(subtitle, style: StudyTypography.bodySecondary),
          const SizedBox(height: 15),
          child,
        ],
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

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'published':
        return Icons.publish_rounded;
      case 'validated':
        return Icons.verified_rounded;
      case 'review':
        return Icons.rate_review_rounded;
      case 'archived':
        return Icons.archive_rounded;
      default:
        return Icons.edit_note_rounded;
    }
  }
}
