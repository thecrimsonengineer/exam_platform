import '../../models/micro_learning/micro_fact.dart';
import '../../services/micro_learning/local_micro_fact_repository.dart';
import '../../services/micro_learning/micro_fact_selector.dart';

class StartupMicroLearningSnapshot {
  const StartupMicroLearningSnapshot({
    required this.fact,
    required this.rotationOrdinal,
    required this.bundleValid,
    required this.diagnostics,
  });

  const StartupMicroLearningSnapshot.empty()
    : fact = null,
      rotationOrdinal = null,
      bundleValid = false,
      diagnostics = const <String>[];

  final MicroFact? fact;
  final int? rotationOrdinal;
  final bool bundleValid;
  final List<String> diagnostics;

  bool get hasFact => fact != null;
}

class StartupMicroLearningService {
  StartupMicroLearningService({
    LocalMicroFactRepository? repository,
    MicroFactSelector selector = const MicroFactSelector(),
  }) : _repository = repository ?? LocalMicroFactRepository(),
       _selector = selector;

  final LocalMicroFactRepository _repository;
  final MicroFactSelector _selector;

  Future<StartupMicroLearningSnapshot> load({
    DateTime? now,
    List<String> recentMicroFactIds = const <String>[],
    Set<String> activeAssessmentConceptIds = const <String>{},
  }) async {
    final clock = now ?? DateTime.now();

    try {
      final repositorySnapshot = await _repository.load(now: clock);
      if (!repositorySnapshot.bundleValid ||
          repositorySnapshot.eligibleFacts.isEmpty) {
        return StartupMicroLearningSnapshot(
          fact: null,
          rotationOrdinal: null,
          bundleValid: repositorySnapshot.bundleValid,
          diagnostics: List<String>.unmodifiable(
            repositorySnapshot.diagnostics,
          ),
        );
      }

      final rotationOrdinal = _dailyRotationOrdinal(clock);
      final selection = _selector.select(
        repositorySnapshot.eligibleFacts,
        context: MicroFactSelectionContext(
          rotationOrdinal: rotationOrdinal,
          recentMicroFactIds: recentMicroFactIds,
          activeAssessmentConceptIds: activeAssessmentConceptIds,
        ),
      );

      return StartupMicroLearningSnapshot(
        fact: selection.fact,
        rotationOrdinal: rotationOrdinal,
        bundleValid: true,
        diagnostics: List<String>.unmodifiable([
          ...repositorySnapshot.diagnostics,
          ...selection.diagnostics,
        ]),
      );
    } catch (_) {
      return const StartupMicroLearningSnapshot(
        fact: null,
        rotationOrdinal: null,
        bundleValid: false,
        diagnostics: <String>['ML12_STARTUP_MICRO_LEARNING_LOAD_FAILED'],
      );
    }
  }

  int _dailyRotationOrdinal(DateTime value) {
    final day = DateTime.utc(value.year, value.month, value.day);
    return day.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
  }
}
