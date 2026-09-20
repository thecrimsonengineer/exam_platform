import 'dart:convert';

import '../collection/daily_discovery_repository.dart';
import '../collection/daily_discovery_service.dart';
import '../collection/daily_discovery_state.dart';
import '../collection/flashcard_collection_repository.dart';
import '../collection/flashcard_collection_statistics.dart';
import '../collection/flashcard_ownership.dart';
import '../collection/flashcard_unlock_service.dart';
import '../memory/flashcard_memory_service.dart';
import '../memory/flashcard_memory_statistics.dart';
import '../memory/flashcard_review_repository.dart';
import '../memory/flashcard_review_session_repository.dart';
import '../memory/flashcard_review_session_service.dart';
import '../memory/flashcard_review_session_state.dart';
import '../memory/flashcard_review_state.dart';
import '../models/flashcard.dart';
import '../models/flashcard_content_package.dart';
import '../models/flashcard_source_provenance.dart';
import '../registry/flashcard_source_registry.dart';
import '../repository/flashcard_package_repository.dart';
import '../validation/fcq100_validator.dart';

class FlashcardDomainCollectionSummary {
  const FlashcardDomainCollectionSummary({
    required this.domainId,
    required this.totalCards,
    required this.ownedCards,
    required this.unseenCards,
    required this.dueCards,
  });

  final String domainId;
  final int totalCards;
  final int ownedCards;
  final int unseenCards;
  final int dueCards;

  double get collectionProgress {
    if (totalCards == 0) {
      return 0;
    }
    return ownedCards / totalCards;
  }
}

class FlashcardLearnerSnapshot {
  FlashcardLearnerSnapshot({
    required this.loadedAt,
    required this.packages,
    required this.cardsById,
    required this.ownershipByCardId,
    required this.reviewsByCardId,
    required this.sourceRegistry,
    required this.domainSummaries,
    required this.collectionStatistics,
    required this.memoryStatistics,
    required this.dailyDiscovery,
    required this.activeSession,
  });

  final DateTime loadedAt;
  final List<FlashcardContentPackage> packages;
  final Map<String, Flashcard> cardsById;
  final Map<String, FlashcardOwnership> ownershipByCardId;
  final Map<String, FlashcardReviewState> reviewsByCardId;
  final FlashcardSourceRegistry sourceRegistry;
  final List<FlashcardDomainCollectionSummary> domainSummaries;
  final FlashcardCollectionStatistics collectionStatistics;
  final FlashcardMemoryStatistics memoryStatistics;
  final DailyDiscoveryState? dailyDiscovery;
  final FlashcardReviewSessionState? activeSession;

  List<Flashcard> get ownedCards {
    final values = ownershipByCardId.keys
        .map((cardId) => cardsById[cardId])
        .whereType<Flashcard>()
        .toList()
      ..sort((a, b) {
        final ownedA = ownershipByCardId[a.id]!;
        final ownedB = ownershipByCardId[b.id]!;
        final acquired = ownedB.acquiredAt.compareTo(ownedA.acquiredAt);
        if (acquired != 0) {
          return acquired;
        }
        return a.frontLabel.compareTo(b.frontLabel);
      });
    return List.unmodifiable(values);
  }

  List<Flashcard> get newlyCollectedCards {
    return List.unmodifiable(
      ownedCards
          .where((card) => ownershipByCardId[card.id]?.isUnseen == true)
          .toList(),
    );
  }

  List<Flashcard> get dueCards {
    final values = reviewsByCardId.values
        .where((review) => review.isDue(loadedAt))
        .map((review) => cardsById[review.cardId])
        .whereType<Flashcard>()
        .toList()
      ..sort((a, b) {
        final reviewA = reviewsByCardId[a.id]!;
        final reviewB = reviewsByCardId[b.id]!;
        final due = reviewA.dueAt.compareTo(reviewB.dueAt);
        if (due != 0) {
          return due;
        }
        return a.frontLabel.compareTo(b.frontLabel);
      });
    return List.unmodifiable(values);
  }

  Flashcard? get dailyCard {
    final cardId = dailyDiscovery?.cardId ?? '';
    if (cardId.isEmpty) {
      return null;
    }
    return cardsById[cardId];
  }

  FlashcardSourceFooter? primarySourceFooterFor(String cardId) {
    final card = cardsById[cardId];
    if (card == null || card.sourceRefs.isEmpty) {
      return null;
    }

    final primary = card.sourceRefs.where((ref) => ref.primary).firstOrNull;
    return sourceRegistry.footerFor(primary ?? card.sourceRefs.first);
  }

  List<FlashcardSourceDetails> sourceDetailsFor(String cardId) {
    final card = cardsById[cardId];
    if (card == null) {
      return const <FlashcardSourceDetails>[];
    }

    return List.unmodifiable(
      card.sourceRefs.map(sourceRegistry.detailsFor).toList(),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) {
      return null;
    }
    return iterator.current;
  }
}

class FlashcardLearnerExperienceController {
  FlashcardLearnerExperienceController({
    required FlashcardPackageRepository packageRepository,
    required FlashcardCollectionRepository collectionRepository,
    required DailyDiscoveryRepository discoveryRepository,
    required FlashcardReviewRepository reviewRepository,
    required FlashcardReviewSessionRepository sessionRepository,
    Fcq100Validator fcq100 = const Fcq100Validator(),
    this.userIdOverride,
    DateTime Function()? now,
  }) : _packageRepository = packageRepository,
       _collectionRepository = collectionRepository,
       _discoveryRepository = discoveryRepository,
       _reviewRepository = reviewRepository,
       _sessionRepository = sessionRepository,
       _fcq100 = fcq100,
       _now = now ?? DateTime.now {
    _unlockService = FlashcardUnlockService(
      repository: _collectionRepository,
      userIdOverride: userIdOverride,
    );
    _memoryService = FlashcardMemoryService(
      repository: _reviewRepository,
      userIdOverride: userIdOverride,
    );
    _dailyDiscoveryService = DailyDiscoveryService(
      discoveryRepository: _discoveryRepository,
      unlockService: _unlockService,
      fcq100: _fcq100,
      userIdOverride: userIdOverride,
    );
    _sessionService = FlashcardReviewSessionService(
      sessionRepository: _sessionRepository,
      memoryService: _memoryService,
      userIdOverride: userIdOverride,
    );
  }

  factory FlashcardLearnerExperienceController.local({
    String? userIdOverride,
  }) {
    return FlashcardLearnerExperienceController(
      packageRepository: SharedPreferencesFlashcardPackageRepository(),
      collectionRepository: SharedPreferencesFlashcardCollectionRepository(),
      discoveryRepository: SharedPreferencesDailyDiscoveryRepository(),
      reviewRepository: SharedPreferencesFlashcardReviewRepository(),
      sessionRepository: SharedPreferencesFlashcardReviewSessionRepository(),
      userIdOverride: userIdOverride,
    );
  }

  final FlashcardPackageRepository _packageRepository;
  final FlashcardCollectionRepository _collectionRepository;
  final DailyDiscoveryRepository _discoveryRepository;
  final FlashcardReviewRepository _reviewRepository;
  final FlashcardReviewSessionRepository _sessionRepository;
  final Fcq100Validator _fcq100;
  final String? userIdOverride;
  final DateTime Function() _now;

  late final FlashcardUnlockService _unlockService;
  late final FlashcardMemoryService _memoryService;
  late final DailyDiscoveryService _dailyDiscoveryService;
  late final FlashcardReviewSessionService _sessionService;

  FlashcardLearnerSnapshot? _lastSnapshot;

  FlashcardLearnerSnapshot? get lastSnapshot => _lastSnapshot;

  String requireLearnerId() => _unlockService.requireLearnerId();

  Future<FlashcardLearnerSnapshot> load({DateTime? at}) async {
    final now = at ?? _now();
    final learnerId = requireLearnerId();
    final packages = await _loadLearnerReadyPackages();
    final cardsById = _indexCards(packages);
    final sourceRegistry = _buildSourceRegistry(packages);

    final ownership = await _collectionRepository.loadAllOwnership(
      learnerId: learnerId,
    );
    final ownershipByCardId = <String, FlashcardOwnership>{
      for (final item in ownership) item.cardId: item,
    };

    final reviews = await _reviewRepository.loadAll(learnerId: learnerId);
    final reviewsByCardId = <String, FlashcardReviewState>{
      for (final item in reviews) item.cardId: item,
    };

    final dailyDiscovery = packages.isEmpty
        ? null
        : await _dailyDiscoveryService.offerForDate(
            localDate: now,
            packages: packages,
            offeredAt: now,
          );

    final collectionStatistics =
        FlashcardCollectionStatistics.fromOwnership(ownership);
    final memoryStatistics = FlashcardMemoryStatistics.build(
      reviews: reviews,
      now: now,
      ownershipByCardId: ownershipByCardId,
    );

    final activeSession = await _loadMostRecentActiveSession(learnerId);

    final snapshot = FlashcardLearnerSnapshot(
      loadedAt: now,
      packages: List.unmodifiable(packages),
      cardsById: Map.unmodifiable(cardsById),
      ownershipByCardId: Map.unmodifiable(ownershipByCardId),
      reviewsByCardId: Map.unmodifiable(reviewsByCardId),
      sourceRegistry: sourceRegistry,
      domainSummaries: _buildDomainSummaries(
        cardsById: cardsById,
        ownershipByCardId: ownershipByCardId,
        reviewsByCardId: reviewsByCardId,
        now: now,
      ),
      collectionStatistics: collectionStatistics,
      memoryStatistics: memoryStatistics,
      dailyDiscovery: dailyDiscovery,
      activeSession: activeSession,
    );
    _lastSnapshot = snapshot;
    return snapshot;
  }

  Future<DailyDiscoveryClaimResult> claimDaily({DateTime? at}) async {
    final now = at ?? _now();
    final packages =
        _lastSnapshot?.packages ?? await _loadLearnerReadyPackages();
    if (packages.isEmpty) {
      throw StateError(
        'Daily Discovery is unavailable without learner-ready Flashcards.',
      );
    }

    final result = await _dailyDiscoveryService.claimForDate(
      localDate: now,
      packages: packages,
      claimedAt: now,
    );
    await load(at: now);
    return result;
  }

  Future<FlashcardOwnership> revealCard(
    String cardId, {
    DateTime? at,
  }) async {
    final viewedAt = at ?? _now();
    final ownership = await _unlockService.markFirstViewed(
      cardId: cardId,
      viewedAt: viewedAt,
    );
    await _memoryService.activateFromOwnership(ownership);
    await load(at: viewedAt);
    return ownership;
  }

  Future<FlashcardReviewSessionState> startOrResumeReview({
    DateTime? at,
    int maxCards = 20,
  }) async {
    final now = at ?? _now();
    final snapshot = await load(at: now);
    final active = snapshot.activeSession;
    if (active != null && !active.isCompleted) {
      return active;
    }

    final sessionId =
        'fc6-review-${now.toUtc().microsecondsSinceEpoch.toString()}';
    final session = await _sessionService.startOrResume(
      sessionId: sessionId,
      now: now,
      cardsById: snapshot.cardsById,
      ownershipByCardId: snapshot.ownershipByCardId,
      maxCards: maxCards,
    );
    await load(at: now);
    return session;
  }

  Future<FlashcardReviewSessionStepResult> rateCurrent({
    required String sessionId,
    required FlashcardReviewRating rating,
    DateTime? at,
  }) async {
    final reviewedAt = at ?? _now();
    final result = await _sessionService.rateCurrent(
      sessionId: sessionId,
      rating: rating,
      reviewedAt: reviewedAt,
    );
    await load(at: reviewedAt);
    return result;
  }

  Future<List<FlashcardContentPackage>> _loadLearnerReadyPackages() async {
    final packageIds = await _packageRepository.listPackageIds();
    final packages = <FlashcardContentPackage>[];

    for (final packageId in packageIds) {
      final contentPackage = await _packageRepository.loadPackage(packageId);
      if (contentPackage == null) {
        throw FormatException(
          'Flashcard package index references missing package: $packageId',
        );
      }

      final result = _fcq100.validate(contentPackage);
      if (result.passed) {
        packages.add(contentPackage);
      }
    }

    packages.sort((a, b) => a.packageId.compareTo(b.packageId));
    return packages;
  }

  static Map<String, Flashcard> _indexCards(
    Iterable<FlashcardContentPackage> packages,
  ) {
    final cardsById = <String, Flashcard>{};

    for (final contentPackage in packages) {
      for (final card in contentPackage.cards) {
        final previous = cardsById[card.id];
        if (previous != null &&
            jsonEncode(previous.toJson()) != jsonEncode(card.toJson())) {
          throw FormatException(
            'Conflicting learner Flashcard identity: ${card.id}',
          );
        }
        cardsById[card.id] = card;
      }
    }

    return cardsById;
  }

  static FlashcardSourceRegistry _buildSourceRegistry(
    Iterable<FlashcardContentPackage> packages,
  ) {
    final sourceById = <String, FlashcardSourceRegistryEntry>{};

    for (final contentPackage in packages) {
      for (final source in contentPackage.sources) {
        final previous = sourceById[source.id];
        if (previous != null &&
            jsonEncode(previous.toJson()) != jsonEncode(source.toJson())) {
          throw FormatException(
            'Conflicting learner Flashcard source identity: ${source.id}',
          );
        }
        sourceById[source.id] = source;
      }
    }

    return FlashcardSourceRegistry.build(entries: sourceById.values);
  }

  static List<FlashcardDomainCollectionSummary> _buildDomainSummaries({
    required Map<String, Flashcard> cardsById,
    required Map<String, FlashcardOwnership> ownershipByCardId,
    required Map<String, FlashcardReviewState> reviewsByCardId,
    required DateTime now,
  }) {
    final totals = <String, int>{};
    final owned = <String, int>{};
    final unseen = <String, int>{};
    final due = <String, int>{};

    for (final card in cardsById.values) {
      final domainId = card.primaryPlacement.domainId;
      totals[domainId] = (totals[domainId] ?? 0) + 1;

      final cardOwnership = ownershipByCardId[card.id];
      if (cardOwnership != null) {
        owned[domainId] = (owned[domainId] ?? 0) + 1;
        if (cardOwnership.isUnseen) {
          unseen[domainId] = (unseen[domainId] ?? 0) + 1;
        }
      }

      final review = reviewsByCardId[card.id];
      if (review != null && review.isDue(now)) {
        due[domainId] = (due[domainId] ?? 0) + 1;
      }
    }

    final domainIds = totals.keys.toList()..sort();
    return List.unmodifiable(
      domainIds
          .map(
            (domainId) => FlashcardDomainCollectionSummary(
              domainId: domainId,
              totalCards: totals[domainId] ?? 0,
              ownedCards: owned[domainId] ?? 0,
              unseenCards: unseen[domainId] ?? 0,
              dueCards: due[domainId] ?? 0,
            ),
          )
          .toList(),
    );
  }

  Future<FlashcardReviewSessionState?> _loadMostRecentActiveSession(
    String learnerId,
  ) async {
    final ids = await _sessionRepository.listSessionIds(
      learnerId: learnerId,
    );
    FlashcardReviewSessionState? best;

    for (final sessionId in ids) {
      final state = await _sessionRepository.load(
        learnerId: learnerId,
        sessionId: sessionId,
      );
      if (state == null || state.isCompleted) {
        continue;
      }
      if (best == null || state.updatedAt.isAfter(best.updatedAt)) {
        best = state;
      }
    }

    return best;
  }
}
