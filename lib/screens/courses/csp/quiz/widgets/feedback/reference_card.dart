import 'package:flutter/material.dart';

import '../../theme/quiz_colors.dart';
import '../../theme/quiz_spacing.dart';

class ReferenceCard extends StatelessWidget {
  final String reference;

  const ReferenceCard({
    super.key,
    required this.reference,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: QuizColors.surfaceAlt.withValues(
          alpha: 0.72,
        ),
        borderRadius: BorderRadius.circular(
          QuizSpacing.cardRadius,
        ),
        border: Border.all(
          color: QuizColors.border.withValues(
            alpha: 0.85,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: QuizColors.navy.withValues(
              alpha: 0.022,
            ),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          20,
          19,
          20,
          20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildDivider(),
            const SizedBox(height: 16),
            _buildReference(),
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
            color: QuizColors.reference.withValues(
              alpha: 0.075,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: QuizColors.reference.withValues(
                alpha: 0.09,
              ),
            ),
          ),
          child: const Icon(
            Icons.menu_book_outlined,
            color: QuizColors.reference,
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
                'REFERENCE',
                style: TextStyle(
                  color: QuizColors.reference,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Supporting source',
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
      color: QuizColors.border.withValues(
        alpha: 0.55,
      ),
    );
  }

  Widget _buildReference() {
    return SelectableText(
      reference,
      style: const TextStyle(
        color: QuizColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.56,
        letterSpacing: 0.02,
      ),
    );
  }
}