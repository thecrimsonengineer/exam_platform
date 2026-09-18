import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/auth/learner_local_identity.dart';
import '../models/competency_readiness_profile.dart';

abstract interface class ReadinessSnapshotRemoteStore {
  Future<List<CompetencyReadinessProfile>> loadAll(String userId);

  Future<void> save({
    required String userId,
    required CompetencyReadinessProfile profile,
  });
}

class FirebaseReadinessSnapshotRemoteStore
    implements ReadinessSnapshotRemoteStore {
  FirebaseReadinessSnapshotRemoteStore({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _firestore
          .collection('users')
          .doc(userId)
          .collection('readinessSnapshots');

  @override
  Future<List<CompetencyReadinessProfile>> loadAll(String userId) async {
    final query = await _collection(userId).get();
    final result = <CompetencyReadinessProfile>[];

    for (final document in query.docs) {
      try {
        final data = Map<String, dynamic>.from(document.data())
          ..remove('serverUpdatedAt');
        final profile = CompetencyReadinessProfile.fromJson(data);
        if (profile.competencyId == document.id) {
          result.add(profile);
        }
      } catch (_) {
        // One malformed snapshot must not invalidate the complete profile set.
      }
    }

    result.sort(
      (left, right) => left.competencyId.compareTo(right.competencyId),
    );
    return result;
  }

  @override
  Future<void> save({
    required String userId,
    required CompetencyReadinessProfile profile,
  }) async {
    await _collection(userId).doc(profile.competencyId).set({
      ...profile.toJson(),
      'serverUpdatedAt': FieldValue.serverTimestamp(),
    });
  }
}

class ReadinessSnapshotRepository {
  ReadinessSnapshotRepository({
    this.userIdOverride,
    ReadinessSnapshotRemoteStore? remoteStore,
  }) : _remoteStore = remoteStore;

  final String? userIdOverride;
  final ReadinessSnapshotRemoteStore? _remoteStore;

  static String storageKeyForUser(String userId) =>
      'csp11.student.$userId.exam_readiness.readiness_snapshots.v1';

  String _requireUserId() {
    return LearnerLocalIdentity.requireCurrentUserId(
      userIdOverride: userIdOverride,
    );
  }

  Future<Map<String, CompetencyReadinessProfile>> loadLocal() async {
    final userId = _requireUserId();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKeyForUser(userId));

    if (raw == null || raw.trim().isEmpty) {
      return const <String, CompetencyReadinessProfile>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const <String, CompetencyReadinessProfile>{};
      }

      final result = <String, CompetencyReadinessProfile>{};

      for (final entry in decoded.entries) {
        if (entry.value is! Map) {
          continue;
        }

        try {
          final profile = CompetencyReadinessProfile.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          );
          if (profile.competencyId.trim().isNotEmpty &&
              profile.competencyId == entry.key.toString()) {
            result[profile.competencyId] = profile;
          }
        } catch (_) {
          // Keep other valid local snapshots.
        }
      }

      return Map<String, CompetencyReadinessProfile>.unmodifiable(result);
    } catch (_) {
      return const <String, CompetencyReadinessProfile>{};
    }
  }

  Future<CompetencyReadinessProfile?> load(
    String competencyId, {
    bool refreshRemote = false,
  }) async {
    if (refreshRemote && _remoteStore != null) {
      await refreshFromRemote();
    }

    final local = await loadLocal();
    return local[competencyId.trim().toLowerCase()];
  }

  Future<Map<String, CompetencyReadinessProfile>> refreshFromRemote() async {
    final remote = _remoteStore;
    if (remote == null) {
      return loadLocal();
    }

    final userId = _requireUserId();
    final profiles = await remote.loadAll(userId);
    final map = <String, CompetencyReadinessProfile>{
      for (final profile in profiles) profile.competencyId: profile,
    };

    await _saveLocal(userId, map);
    return Map<String, CompetencyReadinessProfile>.unmodifiable(map);
  }

  Future<void> save(
    CompetencyReadinessProfile profile, {
    bool syncRemote = true,
  }) async {
    final userId = _requireUserId();
    final competencyId = profile.competencyId.trim().toLowerCase();

    if (!RegExp(r'^d\d{2}_c\d{2}$').hasMatch(competencyId)) {
      throw StateError('Readiness snapshot competency ID is not canonical.');
    }

    final current = Map<String, CompetencyReadinessProfile>.from(
      await loadLocal(),
    );
    current[competencyId] = profile;
    await _saveLocal(userId, current);

    if (syncRemote && _remoteStore != null) {
      await _remoteStore.save(userId: userId, profile: profile);
    }
  }

  Future<void> saveMany(
    Iterable<CompetencyReadinessProfile> profiles, {
    bool syncRemote = true,
  }) async {
    for (final profile in profiles) {
      await save(profile, syncRemote: syncRemote);
    }
  }

  Future<void> clearLocal() async {
    final userId = _requireUserId();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKeyForUser(userId));
  }

  Future<void> _saveLocal(
    String userId,
    Map<String, CompetencyReadinessProfile> profiles,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKeyForUser(userId),
      jsonEncode(profiles.map((key, value) => MapEntry(key, value.toJson()))),
    );
  }
}
