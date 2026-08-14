import 'package:flutter/material.dart';

import '../../../models/content_repository.dart';
import '../../../theme/study/study_colors.dart';
import '../../../theme/study/study_radius.dart';
import '../../../theme/study/study_shadows.dart';
import '../../../theme/study/study_typography.dart';
import 'repository_version_screen.dart';

class RepositoryHistoryScreen extends StatelessWidget {
  final ContentPackageSummary package;
  final List<ContentPackageSummary> allPackages;

  const RepositoryHistoryScreen({
    super.key,
    required this.package,
    required this.allPackages,
  });

  List<ContentPackageSummary> _history() {
    final values = allPackages
        .where(
          (item) => item.content.competencyId == package.content.competencyId,
        )
        .toList();

    values.sort((a, b) => b.content.version.compareTo(a.content.version));

    return values;
  }

  @override
  Widget build(BuildContext context) {
    final history = _history();

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
              'Version History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 2),
            Text(
              'Complete competency version lineage',
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
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildVersionSummary(history),
                const SizedBox(height: 18),
                _buildTimeline(context, history),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
            'COMPETENCY ${package.content.competencyNumber}',
            style: StudyTypography.eyebrow.copyWith(color: StudyColors.primary),
          ),
          const SizedBox(height: 7),
          Text(package.content.title, style: StudyTypography.sectionTitle),
          const SizedBox(height: 6),
          Text(
            package.content.competencyId,
            style: StudyTypography.caption.copyWith(fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionSummary(List<ContentPackageSummary> history) {
    final published = history
        .where((item) => item.status == 'published')
        .toList()
      ..sort((a, b) => b.content.version.compareTo(a.content.version));

    final latest = history.isEmpty ? null : history.first;
    final currentPublished = published.isEmpty ? null : published.first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 14,
        children: [
          _summaryItem(
            'LATEST VERSION',
            latest == null ? 'N/A' : 'v${latest.content.version}.0',
            Icons.layers_rounded,
          ),
          _summaryItem(
            'PUBLISHED VERSION',
            currentPublished == null
                ? 'NONE'
                : 'v${currentPublished.content.version}.0',
            Icons.publish_rounded,
          ),
          _summaryItem(
            'TOTAL VERSIONS',
            '${history.length}',
            Icons.history_rounded,
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, IconData icon) {
    return SizedBox(
      width: 180,
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
            child: Icon(icon, size: 17, color: StudyColors.primary),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: StudyTypography.eyebrow.copyWith(fontSize: 8),
                ),
                const SizedBox(height: 2),
                Text(value, style: StudyTypography.cardTitle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(
    BuildContext context,
    List<ContentPackageSummary> history,
  ) {
    if (history.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: StudyColors.surface,
          borderRadius: StudyRadius.large,
          border: Border.all(color: StudyColors.border),
        ),
        child: const Text(
          'No version history is available for this competency.',
        ),
      );
    }

    return Column(
      children: history.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isCurrent = item.content.id == package.content.id;
        final isLast = index == history.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 42,
              child: Column(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? StudyColors.primary
                          : StudyColors.surface,
                      borderRadius: StudyRadius.small,
                      border: Border.all(
                        color: isCurrent
                            ? StudyColors.primary
                            : StudyColors.border,
                      ),
                    ),
                    child: Text(
                      '${item.content.version}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isCurrent
                            ? Colors.white
                            : StudyColors.textSecondary,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Container(width: 2, height: 86, color: StudyColors.border),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _versionCard(context, item, isCurrent),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _versionCard(
    BuildContext context,
    ContentPackageSummary item,
    bool isCurrent,
  ) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(
          color: isCurrent
              ? StudyColors.primary.withValues(alpha: 0.28)
              : StudyColors.border,
        ),
        boxShadow: StudyShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Version ${item.content.version}.0',
                  style: StudyTypography.cardTitle,
                ),
              ),
              _statusBadge(item.status),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            item.content.id,
            style: StudyTypography.caption.copyWith(fontFamily: 'monospace'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 7,
            children: [
              _smallInfo(
                Icons.account_tree_rounded,
                '${item.subtopicCount} subtopics',
              ),
              _smallInfo(Icons.menu_book_rounded, '${item.topicCount} topics'),
              _smallInfo(
                Icons.view_agenda_rounded,
                '${item.blockCount} blocks',
              ),
              _smallInfo(Icons.quiz_rounded, '${item.questionCount} questions'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: StudyRadius.pillRadius,
                  child: LinearProgressIndicator(
                    value: item.completeness,
                    minHeight: 6,
                    backgroundColor: StudyColors.progressTrack,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      StudyColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(item.completeness * 100).round()}%',
                style: StudyTypography.caption.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RepositoryVersionScreen(package: item),
                  ),
                );
              },
              icon: const Icon(Icons.visibility_rounded, size: 17),
              label: const Text('Inspect Version'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: StudyColors.textMuted),
        const SizedBox(width: 5),
        Text(text, style: StudyTypography.caption),
      ],
    );
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
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
