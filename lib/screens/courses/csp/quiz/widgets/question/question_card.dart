import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';

import '../../theme/quiz_colors.dart';
import '../../theme/quiz_spacing.dart';

class QuestionCard extends StatelessWidget {
  final String question;
  final int questionNumber;

  const QuestionCard({
    super.key,
    required this.question,
    required this.questionNumber,
  });

  @override
  Widget build(BuildContext context) {
    return StudentGlassSurface(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      borderRadius: BorderRadius.circular(22),
      tint: QuizColors.surface.withValues(alpha: 0.56),
      borderColor: QuizColors.borderStrong.withValues(alpha: 0.72),
      shadowColor: QuizColors.navy.withValues(alpha: 0.08),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 18),
            _buildDivider(),
            const SizedBox(height: 19),
            _buildQuestion(),
          ],
        ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: QuizColors.selectedGradient,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: QuizColors.questionAccent.withValues(alpha: 0.35),
            ),
          ),
          child: Icon(
            Icons.help_outline_rounded,
            color: QuizColors.questionAccent,
            size: 21,
          ),
        ),
        const SizedBox(width: QuizSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'QUESTION',
                style: TextStyle(
                  color: QuizColors.questionLabel,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Scenario $questionNumber',
                style: TextStyle(
                  color: QuizColors.questionMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.05,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            QuizColors.border.withValues(alpha: 0.28),
            QuizColors.borderStrong.withValues(alpha: 0.92),
            QuizColors.questionAccent.withValues(alpha: 0.22),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    return SelectableText(
      question,
      style: TextStyle(
        color: QuizColors.textPrimary,
        fontSize: 17.5,
        fontWeight: FontWeight.w500,
        height: 1.62,
        letterSpacing: 0.03,
      ),
    );
  }
}
