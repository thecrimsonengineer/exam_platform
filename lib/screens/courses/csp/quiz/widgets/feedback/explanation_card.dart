import 'package:flutter/material.dart';

import '../../theme/quiz_colors.dart';
import '../../theme/quiz_spacing.dart';

class ExplanationCard extends StatelessWidget {
  final String explanation;

  const ExplanationCard({
    super.key,
    required this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            QuizColors.explanationBackground,
            QuizColors.explanation.withValues(
              alpha: 0.032,
            ),
            QuizColors.purple.withValues(
              alpha: 0.028,
            ),
          ],
          stops: const [
            0.0,
            0.60,
            1.0,
          ],
        ),
        borderRadius: BorderRadius.circular(
          QuizSpacing.cardRadius,
        ),
        border: Border.all(
          color: QuizColors.explanation.withValues(
            alpha: 0.18,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: QuizColors.explanation.withValues(
              alpha: 0.045,
            ),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          20,
          19,
          20,
          21,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 17),
            _buildDivider(),
            const SizedBox(height: 17),
            _buildExplanation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                QuizColors.explanation.withValues(
                  alpha: 0.13,
                ),
                QuizColors.purple.withValues(
                  alpha: 0.07,
                ),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: QuizColors.explanation.withValues(
                alpha: 0.11,
              ),
            ),
          ),
          child: const Icon(
            Icons.lightbulb_outline_rounded,
            color: QuizColors.explanation,
            size: 21,
          ),
        ),
        const SizedBox(
          width: QuizSpacing.md,
        ),
        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'WHY THIS IS THE BEST ANSWER',
                style: TextStyle(
                  color: QuizColors.explanation,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.95,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Learn from the reasoning',
                style: TextStyle(
                  color: QuizColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
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
            QuizColors.explanation.withValues(
              alpha: 0.045,
            ),
            QuizColors.explanation.withValues(
              alpha: 0.16,
            ),
            QuizColors.purple.withValues(
              alpha: 0.07,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanation() {
    return SelectableText(
      explanation,
      style: const TextStyle(
        color: QuizColors.textPrimary,
        fontSize: 15.5,
        fontWeight: FontWeight.w400,
        height: 1.62,
        letterSpacing: 0.03,
      ),
    );
  }
}