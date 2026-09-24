import 'package:shared_preferences/shared_preferences.dart';

import 'micro_fact_selector.dart';

class StartupMicroFactHistorySnapshot {
  const StartupMicroFactHistorySnapshot({
    required this.launchOrdinal,
    required this.recentMicroFactIds,
  });

  final int launchOrdinal;
  final List<String> recentMicroFactIds;
}

abstract interface class StartupMicroFactHistoryStore {
  Future<StartupMicroFactHistorySnapshot> load();

  Future<void> recordSelection({
    required int launchOrdinal,
    required String microFactId,
  });
}

class SharedPreferencesStartupMicroFactHistoryStore
    implements StartupMicroFactHistoryStore {
  static const String _ordinalKey =
      'csp11.micro_learning.startup_history.v1.launch_ordinal';
  static const String _recentIdsKey =
      'csp11.micro_learning.startup_history.v1.recent_ids';

  @override
  Future<StartupMicroFactHistorySnapshot> load() async {
    final preferences = await SharedPreferences.getInstance();
    final storedOrdinal = preferences.getInt(_ordinalKey) ?? 0;
    final ordinal = storedOrdinal < 0 ? 0 : storedOrdinal;
    final recent = _normalizeRecentIds(
      preferences.getStringList(_recentIdsKey) ?? const <String>[],
    );

    return StartupMicroFactHistorySnapshot(
      launchOrdinal: ordinal,
      recentMicroFactIds: recent,
    );
  }

  @override
  Future<void> recordSelection({
    required int launchOrdinal,
    required String microFactId,
  }) async {
    final normalizedId = microFactId.trim();
    if (normalizedId.isEmpty) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    final existing = _normalizeRecentIds(
      preferences.getStringList(_recentIdsKey) ?? const <String>[],
    );

    final recent = <String>[normalizedId];
    for (final id in existing) {
      if (id == normalizedId) {
        continue;
      }
      recent.add(id);
      if (recent.length == MicroFactSelector.recentWindowSize) {
        break;
      }
    }

    await preferences.setStringList(_recentIdsKey, recent);
    await preferences.setInt(_ordinalKey, launchOrdinal + 1);
  }

  List<String> _normalizeRecentIds(List<String> values) {
    final output = <String>[];
    final seen = <String>{};

    for (final raw in values) {
      final value = raw.trim();
      if (value.isEmpty || !seen.add(value)) {
        continue;
      }

      output.add(value);
      if (output.length == MicroFactSelector.recentWindowSize) {
        break;
      }
    }

    return List<String>.unmodifiable(output);
  }
}
