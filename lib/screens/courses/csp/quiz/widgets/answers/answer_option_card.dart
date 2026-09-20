import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';
import 'package:exam_platform/theme/motion/csp11_motion.dart';

import '../../theme/quiz_colors.dart';
import '../../theme/quiz_spacing.dart';

class AnswerOptionCard extends StatelessWidget {
  final String label;
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool isIncorrect;
  final bool submitted;
  final VoidCallback? onTap;

  const AnswerOptionCard({
    super.key,
    required this.label,
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.isIncorrect,
    required this.submitted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _getIcon();
    final reduced = Csp11MotionPreferences.reduced(context);
    final targetScale = !submitted && isSelected ? 1.006 : 1.0;

    return AnimatedScale(
      scale: reduced ? 1.0 : targetScale,
      duration: reduced ? Duration.zero : Csp11MotionDuration.quick,
      curve: Csp11MotionCurve.enter,
      child: StudentGlassSurface(
        borderRadius: BorderRadius.circular(QuizSpacing.cardRadius),
      tint: _surfaceTint(),
      borderColor: _surfaceBorderColor(),
      shadowColor: _surfaceShadowColor(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: submitted ? null : onTap,
          borderRadius: BorderRadius.circular(QuizSpacing.cardRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildIndicator(icon),
                const SizedBox(width: QuizSpacing.md),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: _textColor(),
                      fontSize: 16,
                      fontWeight: isSelected || isCorrect || isIncorrect
                          ? FontWeight.w600
                          : FontWeight.w500,
                      height: 1.48,
                      letterSpacing: 0.03,
                    ),
                  ),
                ),
                if (submitted && (isCorrect || isIncorrect)) ...[
                  const SizedBox(width: 8),
                  _buildStateIcon(),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Color _surfaceTint() {
    if (submitted && isCorrect) {
      return QuizColors.correctBackground.withValues(alpha: 0.66);
    }
    if (submitted && isIncorrect) {
      return QuizColors.incorrectBackground.withValues(alpha: 0.66);
    }
    if (!submitted && isSelected) {
      return QuizColors.purple.withValues(alpha: 0.14);
    }
    return QuizColors.surface.withValues(alpha: 0.52);
  }

  Color _surfaceBorderColor() {
    if (submitted && isCorrect) {
      return QuizColors.correct.withValues(alpha: 0.68);
    }
    if (submitted && isIncorrect) {
      return QuizColors.incorrect.withValues(alpha: 0.64);
    }
    if (!submitted && isSelected) {
      return QuizColors.purple.withValues(alpha: 0.82);
    }
    return QuizColors.border.withValues(alpha: 0.72);
  }

  Color _surfaceShadowColor() {
    if (submitted && isCorrect) {
      return QuizColors.correct.withValues(alpha: 0.06);
    }
    if (submitted && isIncorrect) {
      return QuizColors.incorrect.withValues(alpha: 0.05);
    }
    if (!submitted && isSelected) {
      return QuizColors.purple.withValues(alpha: 0.08);
    }
    return QuizColors.navy.withValues(alpha: 0.025);
  }

  // ==========================================================
  // OPTION INDICATOR
  // ==========================================================

  Widget _buildIndicator(IconData? icon) {
    if (icon != null) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _indicatorBackground(),
          shape: BoxShape.circle,
          border: Border.all(color: _indicatorBorderColor(), width: 1),
        ),
        child: Icon(icon, color: _indicatorColor(), size: 20),
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isSelected
            ? QuizColors.purple.withValues(alpha: 0.10)
            : QuizColors.surfaceAlt,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? QuizColors.purple : QuizColors.borderStrong,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? QuizColors.purple : QuizColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ==========================================================
  // SUBMITTED STATE
  // ==========================================================

  Widget _buildStateIcon() {
    final Color color = isCorrect ? QuizColors.correct : QuizColors.incorrect;

    final IconData icon = isCorrect ? Icons.check_rounded : Icons.close_rounded;

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  IconData? _getIcon() {
    if (submitted && isCorrect) {
      return Icons.check_rounded;
    }

    if (submitted && isIncorrect) {
      return Icons.close_rounded;
    }

    return null;
  }

  // ==========================================================
  // INDICATOR COLORS
  // ==========================================================

  Color _indicatorBackground() {
    if (isCorrect) {
      return QuizColors.correct.withValues(alpha: 0.12);
    }

    if (isIncorrect) {
      return QuizColors.incorrect.withValues(alpha: 0.12);
    }

    return QuizColors.surfaceAlt;
  }

  Color _indicatorBorderColor() {
    if (isCorrect) {
      return QuizColors.correct.withValues(alpha: 0.25);
    }

    if (isIncorrect) {
      return QuizColors.incorrect.withValues(alpha: 0.25);
    }

    return QuizColors.border;
  }

  Color _indicatorColor() {
    if (isCorrect) {
      return QuizColors.correct;
    }

    if (isIncorrect) {
      return QuizColors.incorrect;
    }

    return QuizColors.textSecondary;
  }

  Color _textColor() {
    if (submitted && isCorrect) {
      return QuizColors.correct;
    }

    if (submitted && isIncorrect) {
      return QuizColors.incorrect;
    }

    return QuizColors.textPrimary;
  }
}
