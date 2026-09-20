import 'package:flutter/material.dart';

import '../../../features/flashcards/models/flashcard_content_package.dart';
import '../../../features/flashcards/models/flashcard_deck_index.dart';
import '../../../features/flashcards/registry/flashcard_source_registry.dart';
import '../../../features/flashcards/repository/flashcard_package_repository.dart';
import '../../../features/flashcards/studio/flashcard_studio_service.dart';

class FlashcardStudioScreen extends StatefulWidget {
  const FlashcardStudioScreen({super.key, this.studioService});

  final FlashcardStudioService? studioService;

  @override
  State<FlashcardStudioScreen> createState() => _FlashcardStudioScreenState();
}

class _FlashcardStudioScreenState extends State<FlashcardStudioScreen> {
  late final FlashcardStudioService _studio;
  final TextEditingController _jsonController = TextEditingController();

  FlashcardStudioImportResult? _preview;
  FlashcardDeckIndex? _index;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _studio =
        widget.studioService ??
        FlashcardStudioService(
          repository: SharedPreferencesFlashcardPackageRepository(),
        );
    _loadIndex();
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _loadIndex() async {
    try {
      final index = await _studio.buildDeckIndex();
      if (mounted) {
        setState(() => _index = index);
      }
    } catch (_) {
      // Authoring remains usable even when the local index is unavailable.
    }
  }

  void _previewJson() {
    final source = _jsonController.text.trim();
    if (source.isEmpty) {
      setState(() {
        _error = 'Paste a Flashcard package JSON payload first.';
        _preview = null;
      });
      return;
    }

    try {
      final result = _studio.importJson(source);
      setState(() {
        _preview = result;
        _error = null;
      });
    } catch (error) {
      setState(() {
        _preview = null;
        _error = error.toString();
      });
    }
  }

  Future<void> _saveLocally() async {
    final preview = _preview;
    if (preview == null || _saving) {
      return;
    }

    setState(() => _saving = true);
    try {
      await _studio.savePackage(preview.contentPackage);
      await _loadIndex();

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved local Flashcard package '
            '${preview.contentPackage.packageId}.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _clear() {
    _jsonController.clear();
    setState(() {
      _preview = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcard Studio'),
        actions: [
          IconButton(
            tooltip: 'Clear Flashcard Studio',
            onPressed: _clear,
            icon: const Icon(Icons.clear_all_rounded),
          ),
        ],
      ),
      body: ListView(
        key: const ValueKey('flashcard-studio-list'),
        padding: const EdgeInsets.all(18),
        children: [
          _buildRepositorySummary(context),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey('flashcard-studio-json'),
            controller: _jsonController,
            minLines: 12,
            maxLines: 22,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12.5,
              height: 1.4,
            ),
            decoration: const InputDecoration(
              labelText: 'Flashcard package JSON',
              hintText: 'Paste one CSP11 Flashcard package JSON payload here.',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                key: const ValueKey('flashcard-studio-preview'),
                onPressed: _previewJson,
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Import + validate preview'),
              ),
              FilledButton.tonalIcon(
                key: const ValueKey('flashcard-studio-save'),
                onPressed: preview == null || _saving
                    ? null
                    : () => _saveLocally(),
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Save locally'),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(_error!),
              ),
            ),
          ],
          if (preview != null) ...[
            const SizedBox(height: 18),
            _PackagePreview(result: preview),
          ],
        ],
      ),
    );
  }

  Widget _buildRepositorySummary(BuildContext context) {
    final index = _index;
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: index == null
            ? const Text('Loading local Flashcard package index…')
            : Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  Chip(label: Text('${index.deckCount} decks')),
                  Chip(label: Text('${index.cardCount} cards')),
                  Chip(label: Text('${index.conceptCount} concepts')),
                  Chip(label: Text('${index.mappingCount} mappings')),
                ],
              ),
      ),
    );
  }
}

class _PackagePreview extends StatelessWidget {
  const _PackagePreview({required this.result});

  final FlashcardStudioImportResult result;

  @override
  Widget build(BuildContext context) {
    final contentPackage = result.contentPackage;
    final fcq = result.fcq;
    final registry = FlashcardSourceRegistry.build(
      entries: contentPackage.sources,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contentPackage.deck.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  '${contentPackage.packageId} • '
                  '${contentPackage.cards.length} cards • '
                  '${contentPackage.questionMappings.length} mappings',
                ),
                const SizedBox(height: 12),
                Chip(
                  label: Text(
                    'FCQ100 ${fcq.score}/${fcq.maxScore} '
                    '${fcq.passed ? 'PASS' : 'BLOCK'}',
                  ),
                ),
                if (fcq.failedRules.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  for (final rule in fcq.failedRules)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${rule.id}: ${rule.message}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final card in contentPackage.cards)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.frontLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(card.backDefinition),
                    if (card.whyItMatters.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Why it matters: ${card.whyItMatters}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      _sourceFooter(contentPackage, registry, card.id),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _sourceFooter(
    FlashcardContentPackage contentPackage,
    FlashcardSourceRegistry registry,
    String cardId,
  ) {
    final card = contentPackage.cards.firstWhere((item) => item.id == cardId);
    if (card.sourceRefs.isEmpty) {
      return 'Source unavailable';
    }

    final primary = card.sourceRefs.where((ref) => ref.primary);
    final ref = primary.isNotEmpty ? primary.first : card.sourceRefs.first;
    return registry.footerFor(ref).label;
  }
}
