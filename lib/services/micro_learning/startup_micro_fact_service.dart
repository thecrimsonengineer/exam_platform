import '../../models/micro_learning/micro_fact.dart';
import 'local_micro_fact_repository.dart';
import 'micro_fact_selector.dart';

typedef StartupMicroFactClock = DateTime Function();

class StartupMicroFactService {
  StartupMicroFactService({
    LocalMicroFactRepository? repository,
    MicroFactSelector selector = const MicroFactSelector(),
    StartupMicroFactClock? clock,
  }) : _repository = repository ?? LocalMicroFactRepository(),
       _selector = selector,
       _clock = clock ?? DateTime.now;

  final LocalMicroFactRepository _repository;
  final MicroFactSelector _selector;
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

      final result = _selector.select(
        snapshot.eligibleFacts,
        context: MicroFactSelectionContext(
          rotationOrdinal: rotationOrdinal ?? dailyRotationOrdinal(now),
          recentMicroFactIds: recentMicroFactIds,
          activeAssessmentConceptIds: activeAssessmentConceptIds,
        ),
      );

      return result.fact;
    } catch (_) {
      return null;
    }
  }

  static int dailyRotationOrdinal(DateTime value) {
    final date = DateTime.utc(value.year, value.month, value.day);
    return date.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
  }
}
