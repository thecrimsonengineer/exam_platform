import 'package:flutter/material.dart';

import '../../theme/quiz_colors.dart';
import '../../theme/quiz_spacing.dart';

class QuizHeader extends StatelessWidget {
  final String title;
  final int questionNumber;
  final int totalQuestions;
  final double progress;
  final String difficulty;

  const QuizHeader({
    super.key,
    required this.title,
    required this.questionNumber,
    required this.totalQuestions,
    required this.progress,
    required this.difficulty,
  });

  @override
  Widget build(BuildContext context) {
    final double normalizedProgress =
        progress.clamp(0.0, 1.0);

    final int percentage =
        (normalizedProgress * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        24,
        22,
        24,
        23,
      ),
      decoration: BoxDecoration(
        gradient: QuizColors.headerGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: QuizColors.navy.withValues(
              alpha: 0.17,
            ),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: QuizColors.purple.withValues(
              alpha: 0.07,
            ),
            blurRadius: 32,
            offset: const Offset(8, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopRow(),
          const SizedBox(height: 21),
          _buildTitle(),
          const SizedBox(height: 23),
          _buildProgress(
            normalizedProgress,
            percentage,
          ),
        ],
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: 0.12,
            ),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: 0.17,
              ),
            ),
          ),
          child: const Icon(
            Icons.psychology_outlined,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(
          width: QuizSpacing.md,
        ),
        const Expanded(
          child: Text(
            'CSP11 PRACTICE',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.25,
            ),
          ),
        ),
        _DifficultyBadge(
          difficulty: difficulty,
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1.18,
            letterSpacing: -0.35,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Test your knowledge and build exam readiness.',
          style: TextStyle(
            color: Colors.white.withValues(
              alpha: 0.70,
            ),
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildProgress(
    double normalizedProgress,
    int percentage,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'QUESTION $questionNumber',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.75,
              ),
            ),
            const Spacer(),
            Text(
              '$questionNumber / $totalQuestions',
              style: TextStyle(
                color: Colors.white.withValues(
                  alpha: 0.76,
                ),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        _buildProgressBar(normalizedProgress),
        const SizedBox(height: 9),
        Row(
          children: [
            Text(
              '$percentage% complete',
              style: TextStyle(
                color: Colors.white.withValues(
                  alpha: 0.64,
                ),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white60,
              size: 13,
            ),
            const SizedBox(width: 5),
            Text(
              'Keep going',
              style: TextStyle(
                color: Colors.white.withValues(
                  alpha: 0.64,
                ),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressBar(double progress) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 7,
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              color: Colors.white.withValues(
                alpha: 0.14,
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  final String difficulty;

  const _DifficultyBadge({
    required this.difficulty,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.11,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.speed_outlined,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            difficulty.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.65,
            ),
          ),
        ],
      ),
    );
  }
}