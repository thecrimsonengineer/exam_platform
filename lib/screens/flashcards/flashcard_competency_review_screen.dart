import 'package:flutter/material.dart';

import '../../features/flashcards/cloud/flashcard_package_repository.dart';
import '../../features/flashcards/cloud/published_flashcard_package.dart';
import '../../features/exam_readiness/services/flashcard_retention_evidence_service.dart';
import 'flashcards_catalog_view.dart';

/// Direct learner entry point for a DailyStudyPlan Flashcard review target.
///
/// This intentionally reuses the production Flashcard package repository and
/// [FlashcardDeckScreen]. It does not create a second Flashcard runtime.
class FlashcardCompetencyReviewScreen extends StatefulWidget {
  const FlashcardCompetencyReviewScreen({
    super.key,
    required this.competencyId,
    required this.isDarkMode,
    this.repository,
    this.plannedBlockId,
    this.targetCardCount,
    this.dueOnly = true,
    this.weakOnly = false,
    this.onReviewSessionCompleted,
    this.recallRuntime,
    this.now,
  });

  final String competencyId;
  final bool isDarkMode;
  final FlashcardPackageRepository? repository;
  final String? plannedBlockId;
  final int? targetCardCount;
  final bool dueOnly;
  final bool weakOnly;
  final Future<void> Function()? onReviewSessionCompleted;
  final FlashcardRecallRuntime? recallRuntime;
  final DateTime Function()? now;

  @override
  State<FlashcardCompetencyReviewScreen> createState() =>
      _FlashcardCompetencyReviewScreenState();
}

class _FlashcardCompetencyReviewScreenState
    extends State<FlashcardCompetencyReviewScreen> {
  late final FlashcardPackageRepository _repository;
  late Future<FlashcardDeckPackage> _deckFuture;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? CloudFlashcardPackageRepository();
    _deckFuture = _load();
  }

  Future<FlashcardDeckPackage> _load() =>
      _repository.loadCompetency(widget.competencyId);

  void _retry() {
    setState(() {
      _deckFuture = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FlashcardDeckPackage>(
      future: _deckFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Flashcards')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Flashcards')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 38),
                    const SizedBox(height: 12),
                    const Text(
                      'Unable to open the assigned flashcards.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error?.toString() ??
                          'The competency deck was not returned.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('RETRY'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return FlashcardDeckScreen(
          deck: snapshot.requireData,
          isDarkMode: widget.isDarkMode,
          plannedBlockId: widget.plannedBlockId,
          targetCardCount: widget.targetCardCount,
          dueOnly: widget.dueOnly,
          weakOnly: widget.weakOnly,
          onReviewSessionCompleted: widget.onReviewSessionCompleted,
          recallRuntime: widget.recallRuntime,
          now: widget.now,
        );
      },
    );
  }
}
