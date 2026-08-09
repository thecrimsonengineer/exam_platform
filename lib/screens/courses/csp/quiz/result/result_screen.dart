import 'package:flutter/material.dart';

import '../../../../../models/question.dart';
import '../theme/quiz_colors.dart';
import '../theme/quiz_spacing.dart';
import '../quiz_screen.dart';

class ResultScreen extends StatelessWidget {
  final int domain;
  final int score;
  final int totalQuestions;
  final int bookmarkedCount;
  final List<Question> incorrectQuestions;

  const ResultScreen({
    super.key,
    required this.domain,
    required this.score,
    required this.totalQuestions,
    required this.bookmarkedCount,
    required this.incorrectQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final double percentage = totalQuestions == 0
        ? 0.0
        : (score / totalQuestions) * 100;

    final int incorrectCount = totalQuestions - score;

    return Scaffold(
      backgroundColor: QuizColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: QuizColors.textPrimary,
        title: const Text(
          'Quiz Result',
          style: TextStyle(
            color: QuizColors.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF3F6FC),
              Color(0xFFF7F9FC),
              Color(0xFFF8F7FC),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16,
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics:
                        const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(
                      bottom: 190,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(
                          maxWidth: 1000,
                        ),
                        child: Column(
                          children: [
                            _buildHeroCard(
                              percentage,
                              score,
                              totalQuestions,
                            ),

                            const SizedBox(
                              height: 16,
                            ),

                            _buildPerformanceCard(
                              score,
                              incorrectCount,
                              bookmarkedCount,
                            ),

                            const SizedBox(
                              height: 16,
                            ),

                            _buildReviewCard(
                              incorrectCount,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(
                      maxWidth: 1000,
                    ),
                    child: _buildActionButtons(
                      context,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // HERO
  // ==========================================================

  Widget _buildHeroCard(
    double percentage,
    int score,
    int totalQuestions,
  ) {
    final performance =
        _performanceLabel(percentage);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        22,
        25,
        22,
        24,
      ),
      decoration: BoxDecoration(
        gradient: QuizColors.headerGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: QuizColors.navy.withValues(
              alpha: 0.16,
            ),
            blurRadius: 24,
            offset: const Offset(0, 9),
          ),
          BoxShadow(
            color: QuizColors.purple.withValues(
              alpha: 0.07,
            ),
            blurRadius: 32,
            offset: const Offset(7, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.12,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: 0.18,
                ),
              ),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),

          const SizedBox(height: 15),

          const Text(
            'QUIZ COMPLETE',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 50,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.4,
            ),
          ),

          const SizedBox(height: 9),

          Text(
            performance,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            '$score correct out of '
            '$totalQuestions questions',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 21),

          _buildProgressBar(percentage),
        ],
      ),
    );
  }

  // ==========================================================
  // PROGRESS
  // ==========================================================

  Widget _buildProgressBar(double percentage) {
    final double value =
        (percentage / 100).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius:
              BorderRadius.circular(20),
          child: SizedBox(
            height: 7,
            child: LinearProgressIndicator(
              value: value,
              backgroundColor:
                  Colors.white.withValues(
                alpha: 0.14,
              ),
              valueColor:
                  const AlwaysStoppedAnimation<
                      Color>(
                Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Performance',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(0)}% complete',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================================
  // PERFORMANCE
  // ==========================================================

  Widget _buildPerformanceCard(
    int correct,
    int incorrect,
    int bookmarked,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        QuizSpacing.cardPadding,
      ),
      decoration: BoxDecoration(
        color: QuizColors.surface,
        borderRadius: BorderRadius.circular(
          QuizSpacing.cardRadius,
        ),
        border: Border.all(
          color: QuizColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: QuizColors.navy.withValues(
              alpha: 0.03,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'PERFORMANCE',
            style: TextStyle(
              color: QuizColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Your quiz breakdown',
            style: TextStyle(
              color: QuizColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 17),

          _buildStatRow(
            Icons.check_circle_rounded,
            QuizColors.correct,
            'Correct',
            '$correct',
          ),

          _buildStatDivider(),

          _buildStatRow(
            Icons.cancel_rounded,
            QuizColors.incorrect,
            'Incorrect',
            '$incorrect',
          ),

          _buildStatDivider(),

          _buildStatRow(
            Icons.bookmark_rounded,
            QuizColors.examTip,
            'Bookmarked',
            '$bookmarked',
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    IconData icon,
    Color color,
    String title,
    String value,
  ) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(
              alpha: 0.09,
            ),
            borderRadius:
                BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: QuizColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        Text(
          value,
          style: const TextStyle(
            color: QuizColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),
      child: Divider(
        height: 1,
        color: QuizColors.border.withValues(
          alpha: 0.60,
        ),
      ),
    );
  }

  // ==========================================================
  // REVIEW MESSAGE
  // ==========================================================

  Widget _buildReviewCard(
    int incorrectCount,
  ) {
    final bool hasMistakes =
        incorrectCount > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        QuizSpacing.cardPadding,
      ),
      decoration: BoxDecoration(
        color: QuizColors.surfaceAlt.withValues(
          alpha: 0.72,
        ),
        borderRadius: BorderRadius.circular(
          QuizSpacing.cardRadius,
        ),
        border: Border.all(
          color: QuizColors.border.withValues(
            alpha: 0.80,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: QuizColors.primary
                  .withValues(alpha: 0.08),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              hasMistakes
                  ? Icons.menu_book_outlined
                  : Icons.verified_rounded,
              color: QuizColors.primary,
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  hasMistakes
                      ? 'WHAT TO REVIEW'
                      : 'STRONG PERFORMANCE',
                  style: const TextStyle(
                    color: QuizColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  hasMistakes
                      ? 'Review the questions you missed to strengthen your understanding.'
                      : 'You answered every question correctly. Keep building your exam readiness.',
                  style: const TextStyle(
                    color: QuizColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ACTION BUTTONS
  // ==========================================================

  Widget _buildActionButtons(
    BuildContext context,
  ) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            icon: const Icon(
              Icons.refresh_rounded,
              size: 20,
            ),
            label: const Text(
              'Retry Quiz',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => QuizScreen(
                    domain: domain,
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            icon: const Icon(
              Icons.menu_book_rounded,
              size: 20,
            ),
            label: const Text(
              'Review Incorrect Answers',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed:
                incorrectQuestions.isEmpty
                    ? null
                    : () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                QuizScreen(
                              domain: domain,
                              customQuestions:
                                  incorrectQuestions,
                            ),
                          ),
                        );
                      },
          ),
        ),

        const SizedBox(height: 6),

        TextButton.icon(
          icon: const Icon(
            Icons.arrow_back_rounded,
            size: 18,
          ),
          label: const Text(
            'Back to Domain',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  // ==========================================================
  // PERFORMANCE LABEL
  // ==========================================================

  String _performanceLabel(
    double percentage,
  ) {
    if (percentage >= 90) {
      return 'Excellent performance';
    }

    if (percentage >= 80) {
      return 'Great progress';
    }

    if (percentage >= 70) {
      return 'Good progress';
    }

    if (percentage >= 60) {
      return 'Keep building your knowledge';
    }

    return 'More practice will strengthen your readiness';
  }
}