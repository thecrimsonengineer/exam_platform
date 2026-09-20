import 'dart:async';

import 'package:flutter/material.dart';

import '../../features/flashcards/collection/daily_discovery_state.dart';
import '../../features/flashcards/collection/flashcard_ownership.dart';
import '../../features/flashcards/integration/flashcard_integration_models.dart';
import '../../features/flashcards/integration/flashcard_integration_service.dart';
import '../../features/flashcards/learner/flashcard_learner_experience_controller.dart';
import '../../features/flashcards/models/flashcard.dart';
import '../../features/learning_twin/integration/learning_twin_flashcard_guidance.dart';
import '../../navigation/csp11_route.dart';
import '../../services/haptics/csp11_haptic_service.dart';
import '../../theme/glass/student_glass.dart';
import '../../widgets/motion/csp11_staggered_reveal.dart';
import '../../widgets/motion/csp11_status_reveal.dart';
import 'widgets/flashcard_collectible_reveal_screen.dart';
import 'widgets/flashcard_review_player_screen.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({
    super.key,
    this.controller,
    this.integrationService,
  });

  final FlashcardLearnerExperienceController? controller;
  final FlashcardIntegrationService? integrationService;

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  late final FlashcardLearnerExperienceController _controller;
  late final FlashcardIntegrationService _integrationService;

  FlashcardLearnerSnapshot? _snapshot;
  FlashcardLearningTwinSummary? _learningTwinSummary;
  Object? _error;
  bool _loading = true;
  bool _claimingDaily = false;
  bool _openingReview = false;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? FlashcardLearnerExperienceController.local();
    _integrationService =
        widget.integrationService ??
        FlashcardIntegrationService.local(
          userIdOverride: _controller.userIdOverride,
        );
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    if (mounted) {
      setState(() {
        _loading = _snapshot == null;
        _error = null;
      });
    }

    try {
      final snapshot = await _controller.load();
      FlashcardLearningTwinSummary? learningTwinSummary;
      try {
        learningTwinSummary = await _integrationService.learningTwinSummary(
          now: snapshot.loadedAt,
        );
      } catch (_) {
        // Twin guidance is optional and must not block the Collection.
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = snapshot;
        _learningTwinSummary = learningTwinSummary;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _claimDaily() async {
    if (_claimingDaily) {
      return;
    }

    setState(() => _claimingDaily = true);
    try {
      final result = await _controller.claimDaily();
      await Csp11Haptics.success();

      if (!mounted) {
        return;
      }

      final snapshot = _controller.lastSnapshot;
      if (snapshot != null) {
        setState(() => _snapshot = snapshot);
      }

      final card = snapshot?.cardsById[result.state.cardId];
      final ownership = snapshot?.ownershipByCardId[result.state.cardId];
      if (card != null && ownership != null && mounted) {
        await _openCard(card, ownership);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Daily Discovery could not be claimed: $error'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _claimingDaily = false);
      }
    }
  }

  Future<void> _openCard(Flashcard card, FlashcardOwnership ownership) async {
    final snapshot = _snapshot;
    if (snapshot == null) {
      return;
    }

    await Csp11Haptics.navigation();
    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      Csp11Route.detail<void>(
        child: FlashcardCollectibleRevealScreen(
          card: card,
          ownership: ownership,
          snapshot: snapshot,
          controller: _controller,
        ),
      ),
    );
    await _refresh();
  }

  Future<void> _openReview() async {
    if (_openingReview) {
      return;
    }

    setState(() => _openingReview = true);
    try {
      final session = await _controller.startOrResumeReview();
      final snapshot = _controller.lastSnapshot;
      if (!mounted || snapshot == null) {
        return;
      }

      if (session.cardIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No Flashcards are due for review.')),
        );
        return;
      }

      await Csp11Haptics.navigation();
      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        Csp11Route.forward<void>(
          child: FlashcardReviewPlayerScreen(
            controller: _controller,
            snapshot: snapshot,
            session: session,
          ),
        ),
      );
      await _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Review could not be opened: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _openingReview = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StudentGlassScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Flashcards',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Flashcards',
            onPressed: _loading ? null : () => unawaited(_refresh()),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Csp11StatusReveal(
        kind: Csp11StatusKind.loading,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Csp11StatusReveal(
        kind: Csp11StatusKind.error,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: StudentGlassSurface(
              constraints: const BoxConstraints(maxWidth: 560),
              borderRadius: BorderRadius.circular(24),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 42,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Flashcards could not be loaded',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () => unawaited(_refresh()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final snapshot = _snapshot;
    if (snapshot == null) {
      return const SizedBox.shrink();
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        key: const ValueKey('flashcards-collection-scroll'),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Csp11StaggeredReveal(
                    child: _CollectionHero(snapshot: snapshot),
                  ),
                  if (_learningTwinSummary != null) ...[
                    const SizedBox(height: 16),
                    LearningTwinFlashcardGuidance(
                      summary: _learningTwinSummary!,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Csp11StaggeredReveal(
                    delay: const Duration(milliseconds: 40),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 760;
                        final discovery = _DailyDiscoveryCard(
                          snapshot: snapshot,
                          claiming: _claimingDaily,
                          onClaim: _claimDaily,
                          onOpenCard: _openCard,
                        );
                        final review = _ReviewNowCard(
                          snapshot: snapshot,
                          opening: _openingReview,
                          onOpenReview: _openReview,
                        );

                        if (!wide) {
                          return Column(
                            children: [
                              discovery,
                              const SizedBox(height: 12),
                              review,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: discovery),
                            const SizedBox(width: 12),
                            Expanded(child: review),
                          ],
                        );
                      },
                    ),
                  ),
                  if (snapshot.newlyCollectedCards.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _SectionTitle(
                      title: 'Newly Collected',
                      subtitle: 'Reveal these cards to activate memory review.',
                      trailing: '${snapshot.newlyCollectedCards.length} unseen',
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 126,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: snapshot.newlyCollectedCards.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final card = snapshot.newlyCollectedCards[index];
                          final ownership =
                              snapshot.ownershipByCardId[card.id]!;
                          return _NewlyCollectedTile(
                            card: card,
                            onTap: () => unawaited(_openCard(card, ownership)),
                          );
                        },
                      ),
                    ),
                  ],
                  if (snapshot.domainSummaries.isNotEmpty) ...[
                    const SizedBox(height: 26),
                    const _SectionTitle(
                      title: 'Collection by Domain',
                      subtitle:
                          'Ownership, unseen cards, and due reviews at a glance.',
                    ),
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final itemWidth = constraints.maxWidth >= 900
                            ? (constraints.maxWidth - 24) / 3
                            : constraints.maxWidth >= 580
                            ? (constraints.maxWidth - 12) / 2
                            : constraints.maxWidth;

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: snapshot.domainSummaries
                              .map(
                                (summary) => SizedBox(
                                  width: itemWidth,
                                  child: _DomainSummaryCard(summary: summary),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 26),
                  _SectionTitle(
                    title: 'My Collection',
                    subtitle:
                        'Concept cards you own. Open any unseen card to begin its memory schedule.',
                    trailing: '${snapshot.ownedCards.length} owned',
                  ),
                  const SizedBox(height: 10),
                  if (snapshot.cardsById.isEmpty)
                    const _NoContentCard()
                  else if (snapshot.ownedCards.isEmpty)
                    const _EmptyCollectionCard()
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final itemWidth = constraints.maxWidth >= 900
                            ? (constraints.maxWidth - 24) / 3
                            : constraints.maxWidth >= 580
                            ? (constraints.maxWidth - 12) / 2
                            : constraints.maxWidth;

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: snapshot.ownedCards.map((card) {
                            final ownership =
                                snapshot.ownershipByCardId[card.id]!;
                            final review = snapshot.reviewsByCardId[card.id];

                            return SizedBox(
                              width: itemWidth,
                              child: _CollectionCardTile(
                                card: card,
                                ownership: ownership,
                                due: review?.isDue(snapshot.loadedAt) == true,
                                onTap: () =>
                                    unawaited(_openCard(card, ownership)),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionHero extends StatelessWidget {
  const _CollectionHero({required this.snapshot});

  final FlashcardLearnerSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final total = snapshot.cardsById.length;
    final owned = snapshot.collectionStatistics.totalOwned;
    final progress = total == 0 ? 0.0 : owned / total;
    final theme = Theme.of(context);

    return StudentGlassSurface(
      borderRadius: BorderRadius.circular(28),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.style_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Collection',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Collect concepts, reveal their meaning, then keep them fresh through spaced review.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(99),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricChip(
                icon: Icons.collections_bookmark_outlined,
                label: '$owned / $total collected',
              ),
              _MetricChip(
                icon: Icons.visibility_off_outlined,
                label: '${snapshot.collectionStatistics.unseenCount} unseen',
              ),
              _MetricChip(
                icon: Icons.schedule_rounded,
                label: '${snapshot.memoryStatistics.dueCount} due now',
              ),
              _MetricChip(
                icon: Icons.replay_rounded,
                label: '${snapshot.memoryStatistics.totalReviewEvents} reviews',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DailyDiscoveryCard extends StatelessWidget {
  const _DailyDiscoveryCard({
    required this.snapshot,
    required this.claiming,
    required this.onClaim,
    required this.onOpenCard,
  });

  final FlashcardLearnerSnapshot snapshot;
  final bool claiming;
  final Future<void> Function() onClaim;
  final Future<void> Function(Flashcard card, FlashcardOwnership ownership)
  onOpenCard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = snapshot.dailyDiscovery;
    final card = snapshot.dailyCard;

    String title;
    String message;
    Widget? action;

    if (state == null) {
      title = 'Daily Discovery';
      message =
          'Learner-ready local Flashcard packages have not been installed yet.';
    } else if (state.status == DailyDiscoveryStatus.empty) {
      title = 'Daily Discovery';
      message = 'You already own every available concept card today.';
    } else if (state.status == DailyDiscoveryStatus.offered && card != null) {
      title = card.frontLabel;
      message = 'Today’s concept is ready to join your Collection.';
      action = FilledButton.icon(
        key: const ValueKey('daily-discovery-claim'),
        onPressed: claiming ? null : () => unawaited(onClaim()),
        icon: claiming
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_card_rounded),
        label: const Text('Collect today’s card'),
      );
    } else if (state.status == DailyDiscoveryStatus.claimed && card != null) {
      title = card.frontLabel;
      message = 'Collected today. Reveal it whenever you are ready.';
      final ownership = snapshot.ownershipByCardId[card.id];
      if (ownership != null) {
        action = OutlinedButton.icon(
          onPressed: () => unawaited(onOpenCard(card, ownership)),
          icon: const Icon(Icons.visibility_outlined),
          label: const Text('Open card'),
        );
      }
    } else {
      title = 'Daily Discovery';
      message = 'Today’s discovery is unavailable.';
    }

    return StudentGlassSurface(
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.wb_sunny_outlined, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            'DAILY DISCOVERY',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 16), action],
        ],
      ),
    );
  }
}

class _ReviewNowCard extends StatelessWidget {
  const _ReviewNowCard({
    required this.snapshot,
    required this.opening,
    required this.onOpenReview,
  });

  final FlashcardLearnerSnapshot snapshot;
  final bool opening;
  final Future<void> Function() onOpenReview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = snapshot.activeSession;
    final due = snapshot.memoryStatistics.dueCount;
    final canOpen = active != null || due > 0;

    final title = active != null
        ? 'Resume memory session'
        : due > 0
        ? '$due card${due == 1 ? '' : 's'} due'
        : 'Memory review is clear';

    final message = active != null
        ? '${active.remainingCount} card${active.remainingCount == 1 ? '' : 's'} remain in your saved session.'
        : due > 0
        ? 'Review due concepts now. Weak cards are prioritised without changing their due-date rules.'
        : 'No concept cards need review right now.';

    return StudentGlassSurface(
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.psychology_alt_outlined, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            'MEMORY REVIEW',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const ValueKey('flashcards-review-button'),
            onPressed: !canOpen || opening
                ? null
                : () => unawaited(onOpenReview()),
            icon: opening
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow_rounded),
            label: Text(active != null ? 'Resume review' : 'Start review'),
          ),
        ],
      ),
    );
  }
}

class _NewlyCollectedTile extends StatelessWidget {
  const _NewlyCollectedTile({required this.card, required this.onTap});

  final Flashcard card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: StudentGlassSurface(
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.all(16),
        child: InkWell(
          key: ValueKey('newly-collected-${card.id}'),
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  card.frontLabel,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DomainSummaryCard extends StatelessWidget {
  const _DomainSummaryCard({required this.summary});

  final FlashcardDomainCollectionSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final domainLabel = _domainLabel(summary.domainId);

    return StudentGlassSurface(
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            domainLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: summary.collectionProgress,
            minHeight: 6,
            borderRadius: BorderRadius.circular(99),
          ),
          const SizedBox(height: 10),
          Text(
            '${summary.ownedCards} of ${summary.totalCards} collected',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (summary.unseenCards > 0)
                _TinyStatus(
                  icon: Icons.visibility_off_outlined,
                  label: '${summary.unseenCards} unseen',
                ),
              if (summary.dueCards > 0)
                _TinyStatus(
                  icon: Icons.schedule_rounded,
                  label: '${summary.dueCards} due',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CollectionCardTile extends StatelessWidget {
  const _CollectionCardTile({
    required this.card,
    required this.ownership,
    required this.due,
    required this.onTap,
  });

  final Flashcard card;
  final FlashcardOwnership ownership;
  final bool due;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StudentGlassSurface(
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(16),
      child: InkWell(
        key: ValueKey('collection-card-${card.id}'),
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  ownership.isUnseen
                      ? Icons.auto_awesome_rounded
                      : Icons.style_rounded,
                  color: theme.colorScheme.primary,
                ),
                const Spacer(),
                if (ownership.isUnseen)
                  const _TinyStatus(
                    icon: Icons.visibility_off_outlined,
                    label: 'New',
                  ),
                if (due) ...[
                  if (ownership.isUnseen) const SizedBox(width: 6),
                  const _TinyStatus(icon: Icons.schedule_rounded, label: 'Due'),
                ],
              ],
            ),
            const SizedBox(height: 14),
            Text(
              card.frontLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _domainLabel(card.primaryPlacement.domainId),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (ownership.reinforcementCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${ownership.reinforcementCount} reinforcement${ownership.reinforcementCount == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NoContentCard extends StatelessWidget {
  const _NoContentCard();

  @override
  Widget build(BuildContext context) {
    return StudentGlassSurface(
      borderRadius: BorderRadius.circular(22),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 38,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'No learner-ready Flashcard packages yet',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'The Collection experience is ready. Learner content will appear here when validated local packages are installed.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCollectionCard extends StatelessWidget {
  const _EmptyCollectionCard();

  @override
  Widget build(BuildContext context) {
    return StudentGlassSurface(
      borderRadius: BorderRadius.circular(22),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.style_outlined,
            size: 38,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Your Collection is ready',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Complete eligible learning activities or collect today’s Daily Discovery to add concept cards.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: .32),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .45)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: scheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _TinyStatus extends StatelessWidget {
  const _TinyStatus({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: scheme.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          Text(
            trailing!,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ],
    );
  }
}

String _domainLabel(String domainId) {
  final match = RegExp(r'^d(\d{2})$').firstMatch(domainId.trim());
  if (match == null) {
    return domainId.toUpperCase();
  }
  return 'Domain ${int.parse(match.group(1)!)}';
}
