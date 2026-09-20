import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'daily_discovery_state.dart';

abstract class DailyDiscoveryRepository {
  Future<DailyDiscoveryState?> loadState({
    required String learnerId,
    required String dateKey,
  });

  Future<void> saveState({
    required String learnerId,
    required DailyDiscoveryState state,
  });

  Future<void> clearState({required String learnerId, required String dateKey});
}

class MemoryDailyDiscoveryRepository implements DailyDiscoveryRepository {
  final Map<String, DailyDiscoveryState> _states =
      <String, DailyDiscoveryState>{};

  String _key(String learnerId, String dateKey) => '$learnerId|$dateKey';

  @override
  Future<DailyDiscoveryState?> loadState({
    required String learnerId,
    required String dateKey,
  }) async {
    return _states[_key(learnerId, dateKey)];
  }

  @override
  Future<void> saveState({
    required String learnerId,
    required DailyDiscoveryState state,
  }) async {
    state.validate();
    _states[_key(learnerId, state.dateKey)] = state;
  }

  @override
  Future<void> clearState({
    required String learnerId,
    required String dateKey,
  }) async {
    _states.remove(_key(learnerId, dateKey));
  }
}

class SharedPreferencesDailyDiscoveryRepository
    implements DailyDiscoveryRepository {
  static String storageKey({
    required String learnerId,
    required String dateKey,
  }) => 'csp11.student.$learnerId.flashcards.daily.v1.$dateKey';

  @override
  Future<DailyDiscoveryState?> loadState({
    required String learnerId,
    required String dateKey,
  }) async {
    _validate(learnerId: learnerId, dateKey: dateKey);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(
      storageKey(learnerId: learnerId, dateKey: dateKey),
    );
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw FormatException(
        'Daily Discovery state must be a JSON object: $dateKey',
      );
    }

    final state = DailyDiscoveryState.fromJson(
      Map<String, dynamic>.from(decoded),
    );
    if (state.dateKey != dateKey) {
      throw FormatException('Daily Discovery storage/date mismatch: $dateKey');
    }
    return state;
  }

  @override
  Future<void> saveState({
    required String learnerId,
    required DailyDiscoveryState state,
  }) async {
    _validate(learnerId: learnerId, dateKey: state.dateKey);
    state.validate();

    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(
      storageKey(learnerId: learnerId, dateKey: state.dateKey),
      jsonEncode(state.toJson()),
    );
    if (!saved) {
      throw StateError(
        'Unable to persist Daily Discovery state for ${state.dateKey}.',
      );
    }
  }

  @override
  Future<void> clearState({
    required String learnerId,
    required String dateKey,
  }) async {
    _validate(learnerId: learnerId, dateKey: dateKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey(learnerId: learnerId, dateKey: dateKey));
  }

  static void _validate({required String learnerId, required String dateKey}) {
    if (learnerId.trim().isEmpty) {
      throw const FormatException('Daily Discovery learner ID is required.');
    }
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateKey)) {
      throw FormatException('Invalid Daily Discovery date key: $dateKey');
    }
  }
}
