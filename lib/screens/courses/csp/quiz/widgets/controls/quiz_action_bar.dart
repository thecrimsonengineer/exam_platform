import 'package:flutter/material.dart';

import '../../theme/quiz_colors.dart';
import '../../theme/quiz_spacing.dart';

class QuizActionBar extends StatelessWidget {
  final bool submitted;
  final bool isLastQuestion;
  final VoidCallback onPressed;

  const QuizActionBar({
    super.key,
    required this.submitted,
    required this.isLastQuestion,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final String label;

    if (!submitted) {
      label = 'SUBMIT ANSWER';
    } else if (isLastQuestion) {
      label = 'FINISH QUIZ';
    } else {
      label = 'NEXT QUESTION';
    }

    final IconData icon;

    if (!submitted) {
      icon = Icons.check_circle_outline_rounded;
    } else if (isLastQuestion) {
      icon = Icons.flag_outlined;
    } else {
      icon = Icons.arrow_forward_rounded;
    }

    return SizedBox(
      width: double.infinity,
      height: QuizSpacing.buttonHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: QuizColors.headerGradient,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: QuizColors.primary.withValues(
                alpha: 0.18,
              ),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(
              milliseconds: 220,
            ),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (
              Widget child,
              Animation<double> animation,
            ) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(
                    begin: 0.96,
                    end: 1.0,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Row(
              key: ValueKey<String>(label),
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                ),
                const SizedBox(width: 9),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.65,
                  ),
                ),
                if (submitted &&
                    !isLastQuestion) ...[
                  const SizedBox(width: 7),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 17,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}