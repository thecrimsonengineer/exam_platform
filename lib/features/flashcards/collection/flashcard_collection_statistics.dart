import 'flashcard_ownership.dart';

class FlashcardCollectionStatistics {
  const FlashcardCollectionStatistics({
    required this.totalOwned,
    required this.unseenCount,
    required this.firstViewedCount,
    required this.totalReinforcements,
    required this.questionAcquiredCount,
    required this.dailyDiscoveryAcquiredCount,
    required this.correctSignalCount,
    required this.incorrectSignalCount,
  });

  final int totalOwned;
  final int unseenCount;
  final int firstViewedCount;
  final int totalReinforcements;
  final int questionAcquiredCount;
  final int dailyDiscoveryAcquiredCount;
  final int correctSignalCount;
  final int incorrectSignalCount;

  factory FlashcardCollectionStatistics.fromOwnership(
    Iterable<FlashcardOwnership> ownership,
  ) {
    var totalOwned = 0;
    var unseenCount = 0;
    var firstViewedCount = 0;
    var totalReinforcements = 0;
    var questionAcquiredCount = 0;
    var dailyDiscoveryAcquiredCount = 0;
    var correctSignalCount = 0;
    var incorrectSignalCount = 0;

    for (final record in ownership) {
      totalOwned++;
      if (record.isUnseen) {
        unseenCount++;
      } else {
        firstViewedCount++;
      }
      totalReinforcements += record.reinforcementCount;
      correctSignalCount += record.correctSignalCount;
      incorrectSignalCount += record.incorrectSignalCount;

      switch (record.acquisitionSource) {
        case FlashcardAcquisitionSource.questionCompletion:
          questionAcquiredCount++;
        case FlashcardAcquisitionSource.dailyDiscovery:
          dailyDiscoveryAcquiredCount++;
      }
    }

    return FlashcardCollectionStatistics(
      totalOwned: totalOwned,
      unseenCount: unseenCount,
      firstViewedCount: firstViewedCount,
      totalReinforcements: totalReinforcements,
      questionAcquiredCount: questionAcquiredCount,
      dailyDiscoveryAcquiredCount: dailyDiscoveryAcquiredCount,
      correctSignalCount: correctSignalCount,
      incorrectSignalCount: incorrectSignalCount,
    );
  }
}
