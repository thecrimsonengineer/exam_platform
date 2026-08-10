import 'package:flutter/material.dart';

import '../../../models/study_content.dart';
import '../../../theme/study/study_colors.dart';
import '../../../theme/study/study_icons.dart';
import '../../../theme/study/study_gradients.dart';
import '../../../theme/study/study_radius.dart';
import '../../../theme/study/study_shadows.dart';
import '../../../theme/study/study_spacing.dart';
import '../../../theme/study/study_typography.dart';
import 'content_block_renderer.dart';
import 'quiz_block.dart';

class MainContentTopicRenderer extends StatelessWidget {
  final MainContentTopic topic;
  final int domain;

  const MainContentTopicRenderer({
    super.key,
    required this.topic,
    required this.domain,
  });

  @override
  Widget build(BuildContext context) {
    final title = topic.title.trim();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: StudySpacing.blockGap),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: ClipRRect(
        borderRadius: StudyRadius.large,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty) _buildTopicHeader(title),
            _buildTopicBody(),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // TOPIC HEADER
  // ==========================================================

  Widget _buildTopicHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: const BoxDecoration(
        color: StudyColors.surfaceSoft,
        border: Border(bottom: BorderSide(color: StudyColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: StudyGradients.heroSoft,
              borderRadius: StudyRadius.medium,
              boxShadow: StudyShadows.soft,
            ),
            child: const Icon(StudyIcons.topic, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CORE TOPIC',
                  style: StudyTypography.eyebrow.copyWith(
                    color: StudyColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(title, style: StudyTypography.subSectionTitle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TOPIC BODY
  // ==========================================================

  Widget _buildTopicBody() {
    final hasBlocks = topic.blocks.isNotEmpty;
    final hasQuizzes = topic.quizzes.isNotEmpty;

    if (!hasBlocks && !hasQuizzes) {
      return _buildEmptyTopic();
    }

    return Padding(
      padding: const EdgeInsets.all(StudySpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasBlocks)
            ...topic.blocks.asMap().entries.map((entry) {
              final index = entry.key;
              final block = entry.value;

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == topic.blocks.length - 1 ? 0 : 18,
                ),
                child: ContentBlockRenderer(block: block),
              );
            }),
          if (hasQuizzes) ...[
            if (hasBlocks) const SizedBox(height: 22),
            _buildQuizSection(),
          ],
        ],
      ),
    );
  }

  // ==========================================================
  // QUIZ SECTION
  // ==========================================================

  Widget _buildQuizSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [StudyColors.primaryLight, StudyColors.accentLight],
        ),
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.primary.withValues(alpha: 0.12)),
        boxShadow: StudyShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: StudyGradients.heroSoft,
                  borderRadius: StudyRadius.medium,
                  boxShadow: StudyShadows.soft,
                ),
                child: const Icon(
                  StudyIcons.quiz,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TEST YOUR KNOWLEDGE',
                      style: StudyTypography.eyebrow.copyWith(
                        color: StudyColors.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Practice Questions',
                      style: StudyTypography.subSectionTitle.copyWith(
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: StudyColors.surface.withValues(alpha: 0.85),
                  borderRadius: StudyRadius.pillRadius,
                  border: Border.all(
                    color: StudyColors.primary.withValues(alpha: 0.10),
                  ),
                ),
                child: Text(
                  '${topic.quizzes.length} '
                  '${topic.quizzes.length == 1 ? 'QUESTION' : 'QUESTIONS'}',
                  style: StudyTypography.eyebrow.copyWith(
                    color: StudyColors.primary,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...topic.quizzes.asMap().entries.map((entry) {
            final index = entry.key;
            final quiz = entry.value;

            return Padding(
              padding: EdgeInsets.only(
                bottom: index == topic.quizzes.length - 1 ? 0 : 12,
              ),
              child: QuizBlock(quiz: quiz, domain: domain),
            );
          }),
        ],
      ),
    );
  }

  // ==========================================================
  // EMPTY TOPIC
  // ==========================================================

  Widget _buildEmptyTopic() {
    return Padding(
      padding: const EdgeInsets.all(StudySpacing.cardPadding),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: StudyColors.surfaceSoft,
          borderRadius: StudyRadius.medium,
          border: Border.all(color: StudyColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: StudyColors.surface,
                borderRadius: StudyRadius.small,
              ),
              child: const Icon(
                StudyIcons.info,
                color: StudyColors.textSecondary,
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'No content has been added to this topic yet.',
                  style: StudyTypography.bodySecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
