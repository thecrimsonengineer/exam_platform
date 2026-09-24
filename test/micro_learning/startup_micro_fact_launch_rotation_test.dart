import 'package:exam_platform/services/micro_learning/startup_micro_fact_history_store.dart';
import 'package:exam_platform/services/micro_learning/startup_micro_fact_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('meaningful launches rotate facts and persist recency', () async {
    final history = _MemoryHistoryStore();
    final service = StartupMicroFactService(
      historyStore: history,
      clock: () => DateTime(2026, 9, 24, 12),
    );

    final first = await service.load();
    final second = await service.load();
    final third = await service.load();

    expect(first, isNotNull);
    expect(second, isNotNull);
    expect(third, isNotNull);

    expect(second!.microFactId, isNot(first!.microFactId));
    expect(third!.microFactId, isNot(first.microFactId));
    expect(third.microFactId, isNot(second.microFactId));

    expect(history.launchOrdinal, 3);
    expect(history.recentMicroFactIds, hasLength(3));
    expect(history.recentMicroFactIds.first, third.microFactId);
  });

  test('persistent launch history remains bounded to twelve facts', () async {
    final history = _MemoryHistoryStore();
    final service = StartupMicroFactService(
      historyStore: history,
      clock: () => DateTime(2026, 9, 24, 12),
    );

    for (var index = 0; index < 20; index++) {
      expect(await service.load(), isNotNull);
    }

    expect(history.launchOrdinal, 20);
    expect(history.recentMicroFactIds.length, lessThanOrEqualTo(12));
    expect(history.recentMicroFactIds.toSet().length, history.recentMicroFactIds.length);
  });

  test('explicit selector inputs do not mutate persisted launch history', () async {
    final history = _MemoryHistoryStore(
      launchOrdinal: 9,
      recentMicroFactIds: const <String>['mf_existing'],
    );
    final service = StartupMicroFactService(
      historyStore: history,
      clock: () => DateTime(2026, 9, 24, 12),
    );

    final fact = await service.load(
      rotationOrdinal: 4,
      recentMicroFactIds: const <String>['mf_override'],
    );

    expect(fact, isNotNull);
    expect(history.launchOrdinal, 9);
    expect(history.recentMicroFactIds, const <String>['mf_existing']);
    expect(history.recordCount, 0);
  });
}

class _MemoryHistoryStore implements StartupMicroFactHistoryStore {
  _MemoryHistoryStore({
    this.launchOrdinal = 0,
    List<String> recentMicroFactIds = const <String>[],
  }) : recentMicroFactIds = List<String>.from(recentMicroFactIds);

  int launchOrdinal;
  List<String> recentMicroFactIds;
  int recordCount = 0;

  @override
  Future<StartupMicroFactHistorySnapshot> load() async {
    return StartupMicroFactHistorySnapshot(
      launchOrdinal: launchOrdinal,
      recentMicroFactIds: List<String>.unmodifiable(recentMicroFactIds),
    );
  }

  @override
  Future<void> recordSelection({
    required int launchOrdinal,
    required String microFactId,
  }) async {
    recordCount++;
    this.launchOrdinal = launchOrdinal + 1;

    recentMicroFactIds = <String>[
      microFactId,
      ...recentMicroFactIds.where((id) => id != microFactId),
    ].take(12).toList(growable: false);
  }
}
