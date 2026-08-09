import 'package:flutter/material.dart';

import '../../theme/quiz_colors.dart';

class BookmarkButton extends StatelessWidget {
  final bool isBookmarked;
  final VoidCallback onPressed;

  const BookmarkButton({
    super.key,
    required this.isBookmarked,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isBookmarked
          ? 'Remove Bookmark'
          : 'Bookmark Question',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(13),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isBookmarked
                  ? QuizColors.purple.withValues(alpha: 0.10)
                  : QuizColors.surfaceAlt.withValues(
                      alpha: 0.82,
                    ),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: isBookmarked
                    ? QuizColors.purple.withValues(alpha: 0.32)
                    : QuizColors.border,
                width: isBookmarked ? 1.3 : 1,
              ),
              boxShadow: isBookmarked
                  ? [
                      BoxShadow(
                        color: QuizColors.purple.withValues(
                          alpha: 0.08,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (
                Widget child,
                Animation<double> animation,
              ) {
                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },
              child: Icon(
                isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                key: ValueKey<bool>(isBookmarked),
                color: isBookmarked
                    ? QuizColors.purple
                    : QuizColors.textSecondary,
                size: 21,
              ),
            ),
          ),
        ),
      ),
    );
  }
}