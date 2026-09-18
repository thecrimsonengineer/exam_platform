import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/auth/learner_local_identity.dart';
import '../models/daily_study_plan.dart';

abstract interface class DailyStudyPlanRemoteStore {
  Future<List<DailyStudyPlan>> loadPlans(String userId);
  Future<void> savePlan(DailyStudyPlan plan);
}

class FirebaseDailyStudyPlanRemoteStore implements DailyStudyPlanRemoteStore {
  FirebaseDailyStudyPlanRemoteStore({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _firestore.collection('users').doc(userId).collection('dailyStudyPlans');

  @override
  Future<List<DailyStudyPlan>> loadPlans(String userId) async {
    final snapshot = await _collection(userId).get();
    final plans = <DailyStudyPlan>[];

    for (final document in snapshot.docs) {
      try {
        final data = Map<String, dynamic>.from(document.data())
          ..remove('serverUpdatedAt');
        final plan = DailyStudyPlan.fromJson(data);
        if (plan.userId == userId) plans.add(plan);
      } catch (_) {
        // One malformed plan version must not discard valid history.
      }
    }

    plans.sort(_newestFirst);
    return plans;
  }

  @override
  Future<void> savePlan(DailyStudyPlan plan) async {
    final documentId = '${plan.planId}_v${plan.planVersion}';
    final reference = _collection(plan.userId).doc(documentId);
    final existing = await reference.get();

    if (existing.exists) {
      final current = Map<String, dynamic>.from(existing.data() ?? {})
        ..remove('serverUpdatedAt');
      if (jsonEncode(current) != jsonEncode(plan.toJson())) {
        throw StateError('Daily plan history is immutable.');
      }
      return;
    }

    await reference.set({
      ...plan.toJson(),
      'serverUpdatedAt': FieldValue.serverTimestamp(),
    });
  }
}

class DailyStudyPlanRepository {
  DailyStudyPlanRepository({
    this.userIdOverride,
    DailyStudyPlanRemoteStore? remoteStore,
  }) : _remoteStore = remoteStore;

  final String? userIdOverride;
  final DailyStudyPlanRemoteStore? _remoteStore;

  static String storageKeyForUser(String userId) =>
      'csp11.student.$userId.exam_readiness.daily_study_plans.v1';

  String _requireUserId() =>
      LearnerLocalIdentity.requireCurrentUserId(userIdOverride: userIdOverride);

  Future<List<DailyStudyPlan>> loadHistory() async {
    final userId = _requireUserId();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKeyForUser(userId));

    if (raw == null || raw.trim().isEmpty) {
      return const <DailyStudyPlan>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Iterable) return const <DailyStudyPlan>[];

      final plans = <DailyStudyPlan>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        try {
          final plan = DailyStudyPlan.fromJson(Map<String, dynamic>.from(item));
          if (plan.userId == userId) plans.add(plan);
        } catch (_) {
          // Preserve other valid local versions.
        }
      }

      plans.sort(_newestFirst);
      return List<DailyStudyPlan>.unmodifiable(plans);
    } catch (_) {
      return const <DailyStudyPlan>[];
    }
  }

  Future<DailyStudyPlan?> loadLatestForDate(
    DateTime date, {
    bool refreshRemote = false,
  }) async {
    if (refreshRemote && _remoteStore != null) {
      await refreshFromRemote();
    }

    final matches =
        (await loadHistory())
            .where((plan) => _sameDay(plan.date, date))
            .toList()
          ..sort(_newestFirst);

    return matches.isEmpty ? null : matches.first;
  }

  Future<List<DailyStudyPlan>> refreshFromRemote() async {
    final remote = _remoteStore;
    if (remote == null) return loadHistory();

    final userId = _requireUserId();
    final plans = await remote.loadPlans(userId);
    await _saveLocal(userId, plans);
    return plans;
  }

  Future<void> savePlan(DailyStudyPlan plan, {bool syncRemote = true}) async {
    plan.validate();

    final userId = _requireUserId();
    if (plan.userId != userId) {
      throw StateError('Daily plan ownership does not match active learner.');
    }

    final history = (await loadHistory()).toList();
    final sameVersion = history.where(
      (item) =>
          item.planId == plan.planId && item.planVersion == plan.planVersion,
    );

    if (sameVersion.isNotEmpty) {
      if (jsonEncode(sameVersion.first.toJson()) != jsonEncode(plan.toJson())) {
        throw StateError('Daily plan history is immutable.');
      }
      return;
    }

    history.add(plan);
    history.sort(_newestFirst);
    await _saveLocal(userId, history);

    if (syncRemote && _remoteStore != null) {
      await _remoteStore.savePlan(plan);
    }
  }

  Future<void> clearLocal() async {
    final userId = _requireUserId();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKeyForUser(userId));
  }

  Future<void> _saveLocal(String userId, Iterable<DailyStudyPlan> plans) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKeyForUser(userId),
      jsonEncode(plans.map((plan) => plan.toJson()).toList()),
    );
  }
}

int _newestFirst(DailyStudyPlan a, DailyStudyPlan b) {
  final dateOrder = b.date.compareTo(a.date);
  if (dateOrder != 0) return dateOrder;
  final versionOrder = b.planVersion.compareTo(a.planVersion);
  if (versionOrder != 0) return versionOrder;
  return b.generatedAt.compareTo(a.generatedAt);
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
