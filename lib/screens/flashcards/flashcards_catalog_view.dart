import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';

import '../../app/app_colors.dart';
import '../../data/csp11_blueprint.dart';
import '../../features/flashcards/cloud/flashcard_package_repository.dart';
import '../../features/flashcards/cloud/published_flashcard_package.dart';

class FlashcardsCatalogView extends StatefulWidget {
  const FlashcardsCatalogView({
    super.key,
    required this.isDarkMode,
    this.repository,
  });

  final bool isDarkMode;
  final FlashcardPackageRepository? repository;

  @override
  State<FlashcardsCatalogView> createState() => _FlashcardsCatalogViewState();
}

class _FlashcardsCatalogViewState extends State<FlashcardsCatalogView> {
  late final FlashcardPackageRepository _repository;
  late Future<List<PublishedFlashcardPackageDescriptor>> _catalogFuture;
  String? _openingCompetencyId;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? CloudFlashcardPackageRepository();
    _catalogFuture = _repository.loadCatalog();
  }

  void _retry() {
    setState(() {
      _catalogFuture = _repository.loadCatalog();
    });
  }

  Future<void> _openDeck(PublishedFlashcardPackageDescriptor descriptor) async {
    if (_openingCompetencyId != null) return;

    setState(() => _openingCompetencyId = descriptor.competencyId);

    try {
      final deck = await _repository.loadCompetency(descriptor.competencyId);
      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              FlashcardDeckScreen(deck: deck, isDarkMode: widget.isDarkMode),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open flashcards. $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _openingCompetencyId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDarkMode;
    final background = dark ? const Color(0xFF0A111D) : const Color(0xFFF4F7FB);
    final text = dark ? const Color(0xFFF4F7FB) : const Color(0xFF172033);
    final muted = dark ? const Color(0xFFA5B1C4) : const Color(0xFF667083);

    return StudentGlassScaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Flashcards',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<PublishedFlashcardPackageDescriptor>>(
          future: _catalogFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _FlashcardErrorState(
                message: snapshot.error.toString(),
                isDarkMode: dark,
                onRetry: _retry,
              );
            }

            final catalog =
                snapshot.data ?? const <PublishedFlashcardPackageDescriptor>[];

            if (catalog.isEmpty) {
              return _FlashcardEmptyState(isDarkMode: dark, onRetry: _retry);
            }

            final byDomain =
                <String, List<PublishedFlashcardPackageDescriptor>>{};
            for (final descriptor in catalog) {
              final domainId = descriptor.competencyId.substring(0, 3);
              byDomain
                  .putIfAbsent(
                    domainId,
                    () => <PublishedFlashcardPackageDescriptor>[],
                  )
                  .add(descriptor);
            }

            return RefreshIndicator(
              onRefresh: () async {
                final next = _repository.loadCatalog();
                setState(() => _catalogFuture = next);
                await next;
              },
              child: ListView(
                key: const ValueKey('flashcard-production-catalog'),
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 34),
                children: [
                  StudentGlassSurface(
                    padding: const EdgeInsets.all(22),
                    borderRadius: BorderRadius.circular(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: .10),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.style_rounded,
                                color: AppColors.primary,
                                size: 25,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CSP11 Flashcards',
                                    style: TextStyle(
                                      color: text,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${catalog.length} published competency decks • '
                                    '${catalog.fold<int>(0, (sum, item) => sum + item.flashcardCount)} cards',
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Choose a competency. The deck is downloaded from the '
                          'private learner package service only when you open it.',
                          style: TextStyle(color: muted, height: 1.45),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  for (final domainId in <String>['d01', 'd02'])
                    if ((byDomain[domainId] ?? const []).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: _DomainFlashcardSection(
                          domainId: domainId,
                          descriptors: byDomain[domainId]!,
                          isDarkMode: dark,
                          openingCompetencyId: _openingCompetencyId,
                          onOpen: _openDeck,
                        ),
                      ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DomainFlashcardSection extends StatelessWidget {
  const _DomainFlashcardSection({
    required this.domainId,
    required this.descriptors,
    required this.isDarkMode,
    required this.openingCompetencyId,
    required this.onOpen,
  });

  final String domainId;
  final List<PublishedFlashcardPackageDescriptor> descriptors;
  final bool isDarkMode;
  final String? openingCompetencyId;
  final Future<void> Function(PublishedFlashcardPackageDescriptor) onOpen;

  @override
  Widget build(BuildContext context) {
    final domain = domainForId(domainId);
    if (domain == null) return const SizedBox.shrink();

    final text = isDarkMode ? const Color(0xFFF4F7FB) : const Color(0xFF172033);
    final muted = isDarkMode
        ? const Color(0xFFA5B1C4)
        : const Color(0xFF667083);

    final available = <String, PublishedFlashcardPackageDescriptor>{
      for (final item in descriptors) item.competencyId: item,
    };

    return StudentGlassSurface(
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DOMAIN ${domain.number.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            domain.title,
            style: TextStyle(
              color: text,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${descriptors.length} competencies • '
            '${descriptors.fold<int>(0, (sum, item) => sum + item.flashcardCount)} cards',
            style: TextStyle(color: muted, fontSize: 11.5),
          ),
          const SizedBox(height: 15),
          for (final competency in domain.competencies)
            if (available[competency.id] case final descriptor?)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CompetencyDeckTile(
                  competency: competency,
                  descriptor: descriptor,
                  isDarkMode: isDarkMode,
                  loading: openingCompetencyId == competency.id,
                  onTap: () => onOpen(descriptor),
                ),
              ),
        ],
      ),
    );
  }
}

class _CompetencyDeckTile extends StatelessWidget {
  const _CompetencyDeckTile({
    required this.competency,
    required this.descriptor,
    required this.isDarkMode,
    required this.loading,
    required this.onTap,
  });

  final Csp11Competency competency;
  final PublishedFlashcardPackageDescriptor descriptor;
  final bool isDarkMode;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = isDarkMode ? const Color(0xFFF4F7FB) : const Color(0xFF172033);
    final muted = isDarkMode
        ? const Color(0xFFA5B1C4)
        : const Color(0xFF667083);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('flashcard-deck-${competency.id}'),
        borderRadius: BorderRadius.circular(16),
        onTap: loading ? null : onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDarkMode
                ? Colors.white.withValues(alpha: .035)
                : Colors.white.withValues(alpha: .60),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: .08)
                  : const Color(0xFFDDE5F0),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'C${competency.number}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      competency.statement,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: text,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${descriptor.flashcardCount} cards • v${descriptor.version}',
                      style: TextStyle(color: muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (loading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.chevron_right_rounded, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}

class FlashcardDeckScreen extends StatefulWidget {
  const FlashcardDeckScreen({
    super.key,
    required this.deck,
    required this.isDarkMode,
  });

  final FlashcardDeckPackage deck;
  final bool isDarkMode;

  @override
  State<FlashcardDeckScreen> createState() => _FlashcardDeckScreenState();
}

class _FlashcardDeckScreenState extends State<FlashcardDeckScreen> {
  int _index = 0;
  bool _showBack = false;

  FlashcardCard get _card => widget.deck.cards[_index];

  void _move(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= widget.deck.cards.length) return;
    setState(() {
      _index = next;
      _showBack = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDarkMode;
    final background = dark ? const Color(0xFF0A111D) : const Color(0xFFF4F7FB);
    final text = dark ? const Color(0xFFF4F7FB) : const Color(0xFF172033);
    final muted = dark ? const Color(0xFFA5B1C4) : const Color(0xFF667083);

    return StudentGlassScaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.deck.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Text(
                  'Card ${_index + 1} of ${widget.deck.cards.length}',
                  style: TextStyle(color: muted, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Text(
                  widget.deck.competencyId.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GestureDetector(
              key: const ValueKey('flashcard-study-card'),
              onTap: () => setState(() => _showBack = !_showBack),
              child: StudentGlassSurface(
                constraints: const BoxConstraints(minHeight: 350),
                padding: const EdgeInsets.all(25),
                borderRadius: BorderRadius.circular(24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _showBack
                      ? Column(
                          key: ValueKey('flashcard-back-${_card.id}'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _card.frontLabel,
                              style: TextStyle(
                                color: muted,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              _card.backDefinition,
                              style: TextStyle(
                                color: text,
                                fontSize: 19,
                                height: 1.45,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 22),
                            _BackSection(
                              title: 'Why it matters',
                              body: _card.whyItMatters,
                              text: text,
                              muted: muted,
                            ),
                            const SizedBox(height: 18),
                            _BackSection(
                              title: 'Key point',
                              body: _card.keyPoint,
                              text: text,
                              muted: muted,
                            ),
                          ],
                        )
                      : Center(
                          key: ValueKey('flashcard-front-${_card.id}'),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.style_rounded,
                                color: AppColors.primary,
                                size: 38,
                              ),
                              const SizedBox(height: 22),
                              Text(
                                _card.frontLabel,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: text,
                                  fontSize: 28,
                                  height: 1.2,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Tap to reveal',
                                style: TextStyle(
                                  color: muted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _index == 0 ? null : () => _move(-1),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('PREVIOUS'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _index == widget.deck.cards.length - 1
                        ? null
                        : () => _move(1),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('NEXT'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BackSection extends StatelessWidget {
  const _BackSection({
    required this.title,
    required this.body,
    required this.text,
    required this.muted,
  });

  final String title;
  final String body;
  final Color text;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: muted,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(body, style: TextStyle(color: text, height: 1.45)),
      ],
    );
  }
}

class _FlashcardErrorState extends StatelessWidget {
  const _FlashcardErrorState({
    required this.message,
    required this.isDarkMode,
    required this.onRetry,
  });

  final String message;
  final bool isDarkMode;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text = isDarkMode ? const Color(0xFFF4F7FB) : const Color(0xFF172033);
    final muted = isDarkMode
        ? const Color(0xFFA5B1C4)
        : const Color(0xFF667083);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: StudentGlassSurface(
          padding: const EdgeInsets.all(24),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, color: muted, size: 38),
              const SizedBox(height: 12),
              Text(
                'Flashcards are unavailable right now.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: text,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, fontSize: 11.5, height: 1.4),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('RETRY'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlashcardEmptyState extends StatelessWidget {
  const _FlashcardEmptyState({required this.isDarkMode, required this.onRetry});

  final bool isDarkMode;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text = isDarkMode ? const Color(0xFFF4F7FB) : const Color(0xFF172033);
    final muted = isDarkMode
        ? const Color(0xFFA5B1C4)
        : const Color(0xFF667083);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.style_outlined, color: muted, size: 42),
            const SizedBox(height: 12),
            Text(
              'No published flashcard decks were returned.',
              textAlign: TextAlign.center,
              style: TextStyle(color: text, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('REFRESH'),
            ),
          ],
        ),
      ),
    );
  }
}
