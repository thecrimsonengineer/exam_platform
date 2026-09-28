import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/auth/learner_local_identity.dart';
import '../../../services/performance/firestore_read_audit.dart';
import '../models/daily_study_plan.dart';
import '../models/study_plan_execution_attempt.dart';

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
    FirestoreReadAudit.recordQuery(
      operation: 'readiness.dailyStudyPlans.loadPlans',
      collection: 'users/$userId/dailyStudyPlans',
      scope: 'all',
      returnedDocuments: snapshot.docs.length,
    );
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
    FirestoreReadAudit.recordDocument(
      operation: 'readiness.dailyStudyPlans.savePlan.preflight',
      collection: 'users/${plan.userId}/dailyStudyPlans',
      documentId: documentId,
      exists: existing.exists,
    );

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

class DailyStudyPlanExecutionCommit {
  const DailyStudyPlanExecutionCommit({
    required this.startedPlan,
    required this.attempt,
  });

  final DailyStudyPlan startedPlan;
  final StudyPlanExecutionAttempt attempt;
}

class DailyStudyPlanRepository {
  DailyStudyPlanRepository({
    this.userIdOverride,
    DailyStudyPlanRemoteStore? remoteStore,
  }) : _remoteStore = remoteStore;

  final String? userIdOverride;
  final DailyStudyPlanRemoteStore? _remoteStore;

  static const int _localStorageSchemaVersion = 2;

  static String storageKeyForUser(String userId) =>
      'csp11.student.$userId.exam_readiness.daily_study_plans.v1';

  String _requireUserId() =>
      LearnerLocalIdentity.requireCurrentUserId(userIdOverride: userIdOverride);

  Future<List<DailyStudyPlan>> loadHistory() async {
    final userId = _requireUserId();
    final state = await _loadLocalState(userId);
    return List<DailyStudyPlan>.unmodifiable(state.plans);
  }

  Future<List<StudyPlanExecutionAttempt>> loadExecutionAttempts() async {
    final userId = _requireUserId();
    final state = await _loadLocalState(userId);
    return List<StudyPlanExecutionAttempt>.unmodifiable(state.executionAttempts);
  }

  Future<StudyPlanExecutionAttempt?> loadExecutionAttempt(
    String executionAttemptId,
  ) async {
    final attempts = await loadExecutionAttempts();
    for (final attempt in attempts) {
      if (attempt.executionAttemptId == executionAttemptId) return attempt;
    }
    return null;
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
    final state = await _loadLocalState(userId);
    await _saveLocalState(
      userId,
      _LocalDailyPlanState(
        plans: plans,
        executionAttempts: state.executionAttempts,
      ),
    );
    return plans;
  }

  Future<void> savePlan(DailyStudyPlan plan, {bool syncRemote = true}) async {
    plan.validate();

    final userId = _requireUserId();
    _validateOwnership(plan, userId);

    final state = await _loadLocalState(userId);
    final history = state.plans.toList();
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
    await _saveLocalState(
      userId,
      _LocalDailyPlanState(
        plans: history,
        executionAttempts: state.executionAttempts,
      ),
    );

    if (syncRemote && _remoteStore != null) {
      await _remoteStore.savePlan(plan);
    }
  }

  /// Atomically persists the ERDP-4 started plan version and execution attempt
  /// in one local storage envelope.
  ///
  /// Repeating the same deterministic attempt is idempotent: the previously
  /// committed plan and attempt are returned without creating another version.
  Future<DailyStudyPlanExecutionCommit> commitExecutionStart({
    required DailyStudyPlan startedPlan,
    required StudyPlanExecutionAttempt attempt,
  }) async {
    startedPlan.validate();

    final userId = _requireUserId();
    _validateOwnership(startedPlan, userId);

    final state = await _loadLocalState(userId);
    StudyPlanExecutionAttempt? existingAttempt;
    for (final item in state.executionAttempts) {
      if (item.executionAttemptId == attempt.executionAttemptId) {
        existingAttempt = item;
        break;
      }
    }

    if (existingAttempt != null) {
      DailyStudyPlan? existingPlan;
      for (final plan in state.plans) {
        if (plan.planId == existingAttempt.planId &&
            plan.planVersion == existingAttempt.committedPlanVersion) {
          existingPlan = plan;
          break;
        }
      }
      if (existingPlan == null) {
        throw StateError(
          'Execution attempt exists without its committed daily-plan version.',
        );
      }
      return DailyStudyPlanExecutionCommit(
        startedPlan: existingPlan,
        attempt: existingAttempt,
      );
    }

    final history = state.plans.toList();
    final sameVersion = history.where(
      (item) =>
          item.planId == startedPlan.planId &&
          item.planVersion == startedPlan.planVersion,
    );
    if (sameVersion.isNotEmpty) {
      if (jsonEncode(sameVersion.first.toJson()) !=
          jsonEncode(startedPlan.toJson())) {
        throw StateError('Daily plan history is immutable.');
      }
    } else {
      history.add(startedPlan);
      history.sort(_newestFirst);
    }

    final attempts = <StudyPlanExecutionAttempt>[
      ...state.executionAttempts,
      attempt,
    ];
    await _saveLocalState(
      userId,
      _LocalDailyPlanState(
        plans: history,
        executionAttempts: attempts,
      ),
    );

    return DailyStudyPlanExecutionCommit(
      startedPlan: startedPlan,
      attempt: attempt,
    );
  }

  Future<void> saveExecutionAttempt(
    StudyPlanExecutionAttempt attempt,
  ) async {
    final userId = _requireUserId();
    final state = await _loadLocalState(userId);
    final attempts = state.executionAttempts.toList();
    final index = attempts.indexWhere(
      (item) => item.executionAttemptId == attempt.executionAttemptId,
    );
    if (index < 0) {
      throw StateError('Execution attempt does not exist.');
    }
    attempts[index] = attempt;
    await _saveLocalState(
      userId,
      _LocalDailyPlanState(plans: state.plans, executionAttempts: attempts),
    );
  }

  Future<void> clearLocal() async {
    final userId = _requireUserId();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKeyForUser(userId));
  }

  void _validateOwnership(DailyStudyPlan plan, String userId) {
    if (plan.userId != userId) {
      throw StateError('Daily plan ownership does not match active learner.');
    }
  }

  Future<_LocalDailyPlanState> _loadLocalState(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKeyForUser(userId));

    if (raw == null || raw.trim().isEmpty) {
      return const _LocalDailyPlanState();
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Iterable) {
        return _LocalDailyPlanState(
          plans: _decodePlans(decoded, userId),
        );
      }
      if (decoded is! Map) return const _LocalDailyPlanState();

      final map = Map<String, dynamic>.from(decoded);
      final plans = map['plans'] is Iterable
          ? _decodePlans(map['plans'] as Iterable, userId)
          : const <DailyStudyPlan>[];
      final attempts = map['executionAttempts'] is Iterable
          ? _decodeExecutionAttempts(map['executionAttempts'] as Iterable)
          : const <StudyPlanExecutionAttempt>[];
      return _LocalDailyPlanState(
        plans: plans,
        executionAttempts: attempts,
      );
    } catch (_) {
      return const _LocalDailyPlanState();
    }
  }

  List<DailyStudyPlan> _decodePlans(Iterable decoded, String userId) {
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
    return plans;
  }

  List<StudyPlanExecutionAttempt> _decodeExecutionAttempts(
    Iterable decoded,
  ) {
    final attempts = <StudyPlanExecutionAttempt>[];
    final ids = <String>{};
    for (final item in decoded) {
      if (item is! Map) continue;
      try {
        final attempt = StudyPlanExecutionAttempt.fromJson(
          Map<String, dynamic>.from(item),
        );
        if (ids.add(attempt.executionAttemptId)) attempts.add(attempt);
      } catch (_) {
        // Preserve other valid execution attempts.
      }
    }
    return attempts;
  }

  Future<void> _saveLocalState(
    String userId,
    _LocalDailyPlanState state,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(
      storageKeyForUser(userId),
      jsonEncode(<String, dynamic>{
        'storageSchemaVersion': _localStorageSchemaVersion,
        'plans': state.plans.map((plan) => plan.toJson()).toList(),
        'executionAttempts': state.executionAttempts
            .map((attempt) => attempt.toJson())
            .toList(),
      }),
    );
    if (!saved) {
      throw StateError('Daily plan local persistence failed.');
    }
  }
}

class _LocalDailyPlanState {
  const _LocalDailyPlanState({
    this.plans = const <DailyStudyPlan>[],
    this.executionAttempts = const <StudyPlanExecutionAttempt>[],
  });

  final List<DailyStudyPlan> plans;
  final List<StudyPlanExecutionAttempt> executionAttempts;
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
