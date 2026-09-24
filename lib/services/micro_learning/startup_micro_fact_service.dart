import '../../models/micro_learning/micro_fact.dart';
import 'local_micro_fact_repository.dart';
import 'micro_fact_selector.dart';
import 'startup_micro_fact_history_store.dart';

typedef StartupMicroFactClock = DateTime Function();

class StartupMicroFactService {
  StartupMicroFactService({
    LocalMicroFactRepository? repository,
    MicroFactSelector selector = const MicroFactSelector(),
    StartupMicroFactHistoryStore? historyStore,
    StartupMicroFactClock? clock,
  }) : _repository = repository ?? LocalMicroFactRepository(),
       _selector = selector,
       _historyStore =
           historyStore ?? SharedPreferencesStartupMicroFactHistoryStore(),
       _clock = clock ?? DateTime.now;

  final LocalMicroFactRepository _repository;
  final MicroFactSelector _selector;
  final StartupMicroFactHistoryStore _historyStore;
  final StartupMicroFactClock _clock;

  Future<MicroFact?> load({
    int? rotationOrdinal,
    List<String> recentMicroFactIds = const <String>[],
    Set<String> activeAssessmentConceptIds = const <String>{},
  }) async {
    try {
      final now = _clock();
      final snapshot = await _repository.load(now: now);
      if (!snapshot.bundleValid || snapshot.eligibleFacts.isEmpty) {
        return null;
      }

      final usesExplicitSelectionContext =
          rotationOrdinal != null || recentMicroFactIds.isNotEmpty;

      StartupMicroFactHistorySnapshot? history;
      if (!usesExplicitSelectionContext) {
        try {
          history = await _historyStore.load();
        } catch (_) {
          history = null;
        }
      }

      final effectiveOrdinal =
          rotationOrdinal ??
          history?.launchOrdinal ??
          dailyRotationOrdinal(now);
      final effectiveRecentIds = recentMicroFactIds.isNotEmpty
          ? recentMicroFactIds
          : history?.recentMicroFactIds ?? const <String>[];

      final result = _selector.select(
        snapshot.eligibleFacts,
        context: MicroFactSelectionContext(
          rotationOrdinal: effectiveOrdinal,
          recentMicroFactIds: effectiveRecentIds,
          activeAssessmentConceptIds: activeAssessmentConceptIds,
        ),
      );

      final fact = result.fact;
      if (fact != null && !usesExplicitSelectionContext && history != null) {
        try {
          await _historyStore.recordSelection(
            launchOrdinal: effectiveOrdinal,
            microFactId: fact.microFactId,
          );
        } catch (_) {
          // Impression persistence must never block or fail startup.
        }
      }

      return fact;
    } catch (_) {
      return null;
    }
  }

  static int dailyRotationOrdinal(DateTime value) {
    final date = DateTime.utc(value.year, value.month, value.day);
    return date.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
  }
}
