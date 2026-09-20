import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../features/flashcards/models/flashcard_source_provenance.dart';
import '../../../services/haptics/csp11_haptic_service.dart';
import '../../../theme/glass/student_glass.dart';

Future<void> showFlashcardSourceDetailsSheet(
  BuildContext context, {
  required List<FlashcardSourceDetails> details,
}) async {
  if (details.isEmpty) {
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .35),
    builder: (context) {
      return SafeArea(
        minimum: const EdgeInsets.all(12),
        child: StudentGlassSurface(
          borderRadius: BorderRadius.circular(28),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 640),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: .35),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.source_outlined),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Source details',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close source details',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: details.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _SourceDetailsCard(details: details[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _SourceDetailsCard extends StatelessWidget {
  const _SourceDetailsCard({required this.details});

  final FlashcardSourceDetails details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: .34),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: .55),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  details.primary
                      ? Icons.verified_rounded
                      : Icons.library_books_outlined,
                  color: scheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    details.organization,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (details.primary)
                  _Badge(label: 'Primary', color: scheme.primary),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              details.title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
            if (details.locator.isNotEmpty) ...[
              const SizedBox(height: 12),
              _DetailRow(label: 'Locator', value: details.locator),
            ],
            _DetailRow(
              label: 'Authority',
              value: _readable(details.authorityTier.name),
            ),
            _DetailRow(
              label: 'Source type',
              value: _readable(details.sourceType.name),
            ),
            _DetailRow(
              label: 'Definition mode',
              value: _readable(details.definitionMode.name),
            ),
            _DetailRow(
              label: 'Verification',
              value: _readable(details.verificationStatus.name),
            ),
            if (details.verifiedOn.isNotEmpty)
              _DetailRow(label: 'Verified', value: details.verifiedOn),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => unawaited(_openSource(details.url)),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Open official source'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSource(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      return;
    }
    await Csp11Haptics.navigation();
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _readable(String value) {
  return value
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (match) => '${match.group(1)} ${match.group(2)}',
      )
      .replaceAll('_', ' ')
      .trim()
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map(
        (part) => part.length == 1
            ? part.toUpperCase()
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}
