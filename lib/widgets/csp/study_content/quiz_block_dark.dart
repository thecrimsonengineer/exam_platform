import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';

import 'package:exam_platform/screens/courses/csp/quiz/quiz_screen.dart';
import '../../../models/study_content.dart';
import '../../../theme/study/study_colors_dark.dart';
import '../../../theme/study/study_icons.dart';
import '../../../theme/study/study_radius.dart';
import '../../../theme/study/study_shadows.dart';
import '../../../theme/study/study_typography_dark.dart';

class DarkQuizBlock extends StatelessWidget {
  final QuizReference quiz;
  final int domain;

  const DarkQuizBlock({super.key, required this.quiz, required this.domain});

  @override
  Widget build(BuildContext context) {
    return StudentGlassSurface(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      borderRadius: StudyRadius.large,
      tint: DarkStudyColors.surface.withValues(alpha: 0.56),
      borderColor: DarkStudyColors.primary.withValues(alpha: 0.18),
      child: ClipRRect(
        borderRadius: StudyRadius.large,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_buildHeader(), _buildBody(context)],
        ),
      ),
    );
  }

  // ==========================================================
  // HEADER
  // ==========================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: DarkStudyColors.primaryLight.withValues(alpha: 0.46),
        border: Border(
          bottom: BorderSide(
            color: DarkStudyColors.primary.withValues(alpha: 0.10),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: DarkStudyColors.primary,
              borderRadius: StudyRadius.medium,
              boxShadow: StudyShadows.soft,
            ),
            child: const Icon(StudyIcons.quiz, size: 21, color: Colors.white),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TEST YOUR KNOWLEDGE',
                  style: DarkStudyTypography.eyebrow.copyWith(
                    color: DarkStudyColors.primary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Practice Questions',
                  style: DarkStudyTypography.subSectionTitle,
                ),
              ],
            ),
          ),
          _buildQuizBadge(),
        ],
      ),
    );
  }

  // ==========================================================
  // QUIZ BADGE
  // ==========================================================

  Widget _buildQuizBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: DarkStudyColors.surface.withValues(alpha: 0.58),
        borderRadius: StudyRadius.pillRadius,
        border: Border.all(
          color: DarkStudyColors.primary.withValues(alpha: 0.14),
        ),
      ),
      child: Text(
        'QUIZ',
        style: DarkStudyTypography.eyebrow.copyWith(
          color: DarkStudyColors.primary,
          fontSize: 9,
        ),
      ),
    );
  }

  // ==========================================================
  // BODY
  // ==========================================================

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DarkStudyColors.surfaceSoft.withValues(alpha: 0.54),
                  borderRadius: StudyRadius.small,
                ),
                child: const Icon(
                  StudyIcons.question,
                  size: 18,
                  color: DarkStudyColors.textSecondary,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Text(
                  'Test your understanding of this topic with a practice quiz.',
                  style: DarkStudyTypography.bodySecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildQuizInfo(),
          const SizedBox(height: 18),
          _buildTakeQuizButton(context),
        ],
      ),
    );
  }

  // ==========================================================
  // QUIZ INFORMATION
  // ==========================================================

  Widget _buildQuizInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DarkStudyColors.surfaceSoft.withValues(alpha: 0.54),
        borderRadius: StudyRadius.medium,
        border: Border.all(color: DarkStudyColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildInfoItem(
              icon: StudyIcons.quiz,
              label: 'MODE',
              value: 'Practice',
            ),
          ),
          Container(width: 1, height: 36, color: DarkStudyColors.border),
          const SizedBox(width: 14),
          Expanded(
            child: _buildInfoItem(
              icon: StudyIcons.examTip,
              label: 'FOCUS',
              value: 'Exam',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: DarkStudyColors.primary),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: DarkStudyTypography.eyebrow.copyWith(
                  color: DarkStudyColors.textSecondary,
                  fontSize: 8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: DarkStudyTypography.label.copyWith(
                  color: DarkStudyColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // TAKE QUIZ BUTTON
  // ==========================================================

  Widget _buildTakeQuizButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        icon: const Icon(Icons.play_arrow_rounded, size: 19),
        label: const Text('Take Quiz'),
        style: FilledButton.styleFrom(
          backgroundColor: DarkStudyColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: StudyRadius.medium),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QuizScreen(domain: domain, quizId: quiz.quizId),
            ),
          );
        },
      ),
    );
  }
}
