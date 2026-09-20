import 'package:flutter/material.dart';

import '../../../features/flashcards/integration/flashcard_integration_models.dart';
import '../../../theme/glass/student_glass.dart';

class FlashcardQuizRewardCard extends StatelessWidget {
  const FlashcardQuizRewardCard({super.key, required this.result});

  final FlashcardQuestionCompletionResult result;

  @override
  Widget build(BuildContext context) {
    if (!result.hasReward) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isNew = result.isNewCollection;
    final label = isNew ? 'NEW CONCEPT COLLECTED' : 'CONCEPT REINFORCED';
    final title = result.frontLabel?.trim().isNotEmpty == true
        ? result.frontLabel!.trim()
        : 'Concept card updated';
    final detail = isNew
        ? 'Saved to your Flashcard Collection. Reveal it later to activate memory review.'
        : 'Your existing concept card was reinforced by this Question completion.';

    return StudentGlassSurface(
      key: ValueKey(
        'flashcard-quiz-reward-${result.questionId}-${result.status.name}',
      ),
      width: double.infinity,
      borderRadius: BorderRadius.circular(18),
      padding: const EdgeInsets.all(18),
      tint: scheme.primaryContainer.withValues(alpha: .28),
      borderColor: scheme.primary.withValues(alpha: .20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(
                isNew ? Icons.auto_awesome_rounded : Icons.refresh_rounded,
                color: scheme.primary,
                size: 21,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  detail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
