import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/auth/learner_local_identity.dart';
import '../models/competency_evidence_snapshot.dart';

abstract interface class EvidenceSnapshotRemoteStore {
  Future<List<CompetencyEvidenceSnapshot>> loadAll(String userId);

  Future<void> save({
    required String userId,
    required CompetencyEvidenceSnapshot snapshot,
  });
}

class FirebaseEvidenceSnapshotRemoteStore
    implements EvidenceSnapshotRemoteStore {
  FirebaseEvidenceSnapshotRemoteStore({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _firestore
          .collection('users')
          .doc(userId)
          .collection('evidenceSnapshots');

  @override
  Future<List<CompetencyEvidenceSnapshot>> loadAll(String userId) async {
    final snapshot = await _collection(userId).get();
    final result = <CompetencyEvidenceSnapshot>[];

    for (final document in snapshot.docs) {
      try {
        final data = Map<String, dynamic>.from(document.data())
          ..remove('serverUpdatedAt');
        final item = CompetencyEvidenceSnapshot.fromJson(data);
        if (item.competencyId == document.id) {
          result.add(item);
        }
      } catch (_) {
        // One malformed remote snapshot must not discard the rest.
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
    required CompetencyEvidenceSnapshot snapshot,
  }) async {
    await _collection(userId).doc(snapshot.competencyId).set({
      ...snapshot.toJson(),
      'serverUpdatedAt': FieldValue.serverTimestamp(),
    });
  }
}

class EvidenceSnapshotRepository {
  EvidenceSnapshotRepository({
    this.userIdOverride,
    EvidenceSnapshotRemoteStore? remoteStore,
  }) : _remoteStore = remoteStore;

  final String? userIdOverride;
  final EvidenceSnapshotRemoteStore? _remoteStore;

  static String storageKeyForUser(String userId) =>
      'csp11.student.$userId.exam_readiness.evidence_snapshots.v1';

  String _requireUserId() {
    return LearnerLocalIdentity.requireCurrentUserId(
      userIdOverride: userIdOverride,
    );
  }

  Future<Map<String, CompetencyEvidenceSnapshot>> loadLocal() async {
    final userId = _requireUserId();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKeyForUser(userId));

    if (raw == null || raw.trim().isEmpty) {
      return const <String, CompetencyEvidenceSnapshot>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const <String, CompetencyEvidenceSnapshot>{};
      }

      final result = <String, CompetencyEvidenceSnapshot>{};

      for (final entry in decoded.entries) {
        if (entry.value is! Map) {
          continue;
        }

        try {
          final snapshot = CompetencyEvidenceSnapshot.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          );

          if (snapshot.competencyId.trim().isNotEmpty &&
              snapshot.competencyId == entry.key.toString()) {
            result[snapshot.competencyId] = snapshot;
          }
        } catch (_) {
          // One damaged local snapshot must not discard valid snapshots.
        }
      }

      return Map<String, CompetencyEvidenceSnapshot>.unmodifiable(result);
    } catch (_) {
      return const <String, CompetencyEvidenceSnapshot>{};
    }
  }

  Future<CompetencyEvidenceSnapshot?> load(
    String competencyId, {
    bool refreshRemote = false,
  }) async {
    if (refreshRemote && _remoteStore != null) {
      await refreshFromRemote();
    }

    final all = await loadLocal();
    return all[competencyId.trim().toLowerCase()];
  }

  Future<Map<String, CompetencyEvidenceSnapshot>> refreshFromRemote() async {
    final remoteStore = _remoteStore;
    if (remoteStore == null) {
      return loadLocal();
    }

    final userId = _requireUserId();
    final remote = await remoteStore.loadAll(userId);
    final map = <String, CompetencyEvidenceSnapshot>{
      for (final item in remote) item.competencyId: item,
    };

    await _saveLocal(userId, map);
    return Map<String, CompetencyEvidenceSnapshot>.unmodifiable(map);
  }

  Future<void> save(
    CompetencyEvidenceSnapshot snapshot, {
    bool syncRemote = true,
  }) async {
    final userId = _requireUserId();
    final competencyId = snapshot.competencyId.trim().toLowerCase();

    if (!RegExp(r'^d\d{2}_c\d{2}$').hasMatch(competencyId)) {
      throw StateError('Evidence snapshot competency ID is not canonical.');
    }

    final all = Map<String, CompetencyEvidenceSnapshot>.from(await loadLocal());
    all[competencyId] = snapshot;
    await _saveLocal(userId, all);

    if (syncRemote && _remoteStore != null) {
      await _remoteStore.save(userId: userId, snapshot: snapshot);
    }
  }

  Future<void> saveMany(
    Iterable<CompetencyEvidenceSnapshot> snapshots, {
    bool syncRemote = true,
  }) async {
    for (final snapshot in snapshots) {
      await save(snapshot, syncRemote: syncRemote);
    }
  }

  Future<void> clearLocal() async {
    final userId = _requireUserId();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKeyForUser(userId));
  }

  Future<void> _saveLocal(
    String userId,
    Map<String, CompetencyEvidenceSnapshot> snapshots,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKeyForUser(userId),
      jsonEncode(snapshots.map((key, value) => MapEntry(key, value.toJson()))),
    );
  }
}
