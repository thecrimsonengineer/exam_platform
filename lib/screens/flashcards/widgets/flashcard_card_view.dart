import 'package:flutter/material.dart';

import '../../../features/flashcards/models/flashcard.dart';
import '../../../features/flashcards/models/flashcard_source_provenance.dart';
import '../../../theme/glass/student_glass.dart';
import '../../../widgets/motion/csp11_flip_card.dart';

class FlashcardCardView extends StatelessWidget {
  const FlashcardCardView({
    super.key,
    required this.card,
    required this.isFlipped,
    this.sourceFooter,
    this.onReveal,
    this.onSourceTap,
    this.compact = false,
  });

  final Flashcard card;
  final bool isFlipped;
  final FlashcardSourceFooter? sourceFooter;
  final VoidCallback? onReveal;
  final VoidCallback? onSourceTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final minHeight = compact ? 300.0 : 390.0;

    final front = Semantics(
      button: onReveal != null,
      label: 'Flashcard front. ${card.frontLabel}',
      hint: onReveal == null ? null : 'Activate to reveal the meaning.',
      child: InkWell(
        key: ValueKey('flashcard-front-${card.id}'),
        borderRadius: BorderRadius.circular(26),
        onTap: onReveal,
        child: StudentGlassSurface(
          borderRadius: BorderRadius.circular(26),
          padding: EdgeInsets.all(compact ? 22 : 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: compact ? 34 : 42,
                  color: scheme.primary,
                ),
                SizedBox(height: compact ? 20 : 28),
                Text(
                  card.frontLabel,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Concept card',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (onReveal != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Tap to reveal the meaning',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    final back = Semantics(
      label: 'Flashcard meaning for ${card.frontLabel}',
      child: StudentGlassSurface(
        key: ValueKey('flashcard-back-${card.id}'),
        borderRadius: BorderRadius.circular(26),
        padding: EdgeInsets.all(compact ? 20 : 26),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.frontLabel,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 18),
                _Section(
                  label: 'Definition / meaning',
                  text: card.backDefinition,
                ),
                if (card.whyItMatters.trim().isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _Section(
                    label: 'Why it matters',
                    text: card.whyItMatters,
                  ),
                ],
                if (card.keyPoint.trim().isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _Section(
                    label: 'Key point',
                    text: card.keyPoint,
                  ),
                ],
                const Spacer(),
                const SizedBox(height: 24),
                Divider(color: scheme.outlineVariant.withValues(alpha: .7)),
                const SizedBox(height: 10),
                if (sourceFooter != null)
                  Semantics(
                    button: onSourceTap != null,
                    label: sourceFooter!.label,
                    child: InkWell(
                      key: ValueKey('flashcard-source-${card.id}'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: onSourceTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 8,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.verified_outlined,
                              size: 18,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                sourceFooter!.label,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            if (onSourceTap != null)
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: scheme.onSurfaceVariant,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    return Csp11FlipCard(
      front: front,
      back: back,
      isFlipped: isFlipped,
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w900,
            letterSpacing: .7,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          text,
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
