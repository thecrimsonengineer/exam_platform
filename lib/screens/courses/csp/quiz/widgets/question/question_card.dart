import 'package:flutter/material.dart';

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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF8FAFF),
            Color(0xFFFAF8FF),
          ],
          stops: [0.0, 0.58, 1.0],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: QuizColors.border.withValues(
            alpha: 0.85,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: QuizColors.navy.withValues(
              alpha: 0.05,
            ),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
          BoxShadow(
            color: QuizColors.purple.withValues(
              alpha: 0.022,
            ),
            blurRadius: 28,
            offset: const Offset(7, 0),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          24,
        ),
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
              color: QuizColors.primary.withValues(
                alpha: 0.12,
              ),
            ),
          ),
          child: const Icon(
            Icons.help_outline_rounded,
            color: QuizColors.primary,
            size: 21,
          ),
        ),
        const SizedBox(
          width: QuizSpacing.md,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'QUESTION',
                style: TextStyle(
                  color: QuizColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Scenario $questionNumber',
                style: const TextStyle(
                  color: QuizColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
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
            QuizColors.border.withValues(
              alpha: 0.20,
            ),
            QuizColors.border.withValues(
              alpha: 0.78,
            ),
            QuizColors.purple.withValues(
              alpha: 0.10,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    return SelectableText(
      question,
      style: const TextStyle(
        color: QuizColors.textPrimary,
        fontSize: 17.5,
        fontWeight: FontWeight.w500,
        height: 1.62,
        letterSpacing: 0.03,
      ),
    );
  }
}