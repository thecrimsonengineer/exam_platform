import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/auth/learner_local_identity.dart';
import '../models/exam_study_plan.dart';

abstract interface class ExamStudyPlanRemoteStore {
  Future<List<ExamStudyPlan>> loadPlans(String userId);

  Future<void> savePlan(ExamStudyPlan plan);

  Future<void> deactivateOtherPlans({
    required String userId,
    required String activePlanId,
  });
}

class FirebaseExamStudyPlanRemoteStore implements ExamStudyPlanRemoteStore {
  FirebaseExamStudyPlanRemoteStore({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _firestore.collection('users').doc(userId).collection('examPlans');

  @override
  Future<List<ExamStudyPlan>> loadPlans(String userId) async {
    final snapshot = await _collection(userId).get();
    final plans = <ExamStudyPlan>[];

    for (final document in snapshot.docs) {
      try {
        final data = Map<String, dynamic>.from(document.data())
          ..remove('serverUpdatedAt');
        final plan = ExamStudyPlan.fromJson(data);
        if (plan.userId == userId) {
          plans.add(plan);
        }
      } catch (_) {
        // A malformed remote document must not discard valid plans.
      }
    }

    plans.sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    return plans;
  }

  @override
  Future<void> savePlan(ExamStudyPlan plan) async {
    await _collection(plan.userId).doc(plan.id).set({
      ...plan.toJson(),
      'serverUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deactivateOtherPlans({
    required String userId,
    required String activePlanId,
  }) async {
    final snapshot = await _collection(
      userId,
    ).where('active', isEqualTo: true).get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    for (final document in snapshot.docs) {
      if (document.id == activePlanId) {
        continue;
      }

      batch.update(document.reference, {
        'active': false,
        'serverUpdatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}

class ExamStudyPlanRepository {
  ExamStudyPlanRepository({
    this.userIdOverride,
    ExamStudyPlanRemoteStore? remoteStore,
  }) : _remoteStore = remoteStore;

  final String? userIdOverride;
  final ExamStudyPlanRemoteStore? _remoteStore;

  static String storageKeyForUser(String userId) =>
      'csp11.student.$userId.exam_readiness.exam_plans.v1';

  String _requireUserId() {
    return LearnerLocalIdentity.requireCurrentUserId(
      userIdOverride: userIdOverride,
    );
  }

  Future<List<ExamStudyPlan>> loadLocalPlans() async {
    final userId = _requireUserId();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKeyForUser(userId));

    if (raw == null || raw.trim().isEmpty) {
      return const <ExamStudyPlan>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <ExamStudyPlan>[];
      }

      final plans = <ExamStudyPlan>[];
      for (final item in decoded) {
        if (item is! Map) {
          continue;
        }

        try {
          final plan = ExamStudyPlan.fromJson(Map<String, dynamic>.from(item));
          if (plan.userId == userId && plan.id.isNotEmpty) {
            plans.add(plan);
          }
        } catch (_) {
          // One damaged local plan must not discard the rest.
        }
      }

      plans.sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
      return List<ExamStudyPlan>.unmodifiable(plans);
    } catch (_) {
      return const <ExamStudyPlan>[];
    }
  }

  Future<ExamStudyPlan?> loadActivePlan({bool refreshRemote = false}) async {
    if (refreshRemote && _remoteStore != null) {
      await refreshFromRemote();
    }

    final plans = await loadLocalPlans();
    return _newestActive(plans);
  }

  Future<ExamStudyPlan?> refreshFromRemote() async {
    final remoteStore = _remoteStore;
    if (remoteStore == null) {
      return loadActivePlan();
    }

    final userId = _requireUserId();
    final remotePlans = await remoteStore.loadPlans(userId);
    await _saveLocalPlans(userId, remotePlans);
    return _newestActive(remotePlans);
  }

  Future<void> savePlan(ExamStudyPlan plan, {bool syncRemote = true}) async {
    final userId = _requireUserId();
    if (plan.userId != userId) {
      throw StateError(
        'Exam plan ownership does not match the active learner.',
      );
    }

    final plans = (await loadLocalPlans()).toList(growable: true);
    final next = <ExamStudyPlan>[];

    for (final existing in plans) {
      if (existing.id == plan.id) {
        continue;
      }

      if (plan.active && existing.active) {
        next.add(existing.copyWith(active: false, updatedAt: plan.updatedAt));
      } else {
        next.add(existing);
      }
    }

    next.add(plan);
    next.sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    await _saveLocalPlans(userId, next);

    if (syncRemote && _remoteStore != null) {
      if (plan.active) {
        await _remoteStore.deactivateOtherPlans(
          userId: userId,
          activePlanId: plan.id,
        );
      }
      await _remoteStore.savePlan(plan);
    }
  }

  Future<void> deactivatePlan(
    String planId, {
    DateTime? updatedAt,
    bool syncRemote = true,
  }) async {
    final normalizedId = planId.trim();
    if (normalizedId.isEmpty) {
      return;
    }

    final userId = _requireUserId();
    final plans = (await loadLocalPlans()).toList(growable: true);
    final now = updatedAt ?? DateTime.now();
    ExamStudyPlan? changed;

    for (var index = 0; index < plans.length; index++) {
      final plan = plans[index];
      if (plan.id == normalizedId && plan.active) {
        changed = plan.copyWith(active: false, updatedAt: now);
        plans[index] = changed;
      }
    }

    if (changed == null) {
      return;
    }

    await _saveLocalPlans(userId, plans);

    if (syncRemote && _remoteStore != null) {
      await _remoteStore.savePlan(changed);
    }
  }

  Future<void> clearLocalPlans() async {
    final userId = _requireUserId();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKeyForUser(userId));
  }

  Future<void> _saveLocalPlans(
    String userId,
    Iterable<ExamStudyPlan> plans,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKeyForUser(userId),
      jsonEncode(plans.map((plan) => plan.toJson()).toList()),
    );
  }

  ExamStudyPlan? _newestActive(Iterable<ExamStudyPlan> plans) {
    final active = plans.where((plan) => plan.active).toList(growable: false)
      ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));

    return active.isEmpty ? null : active.first;
  }
}
