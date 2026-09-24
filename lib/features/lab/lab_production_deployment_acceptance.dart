import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

import 'lab_production_release_closure.dart';
import 'lab_production_release_operator.dart';

const String kLspQ16ClosedSha =
    '04bfdc9d5c61faeb5a7a30e86cb753947ba8e49a';
const String kLspQ16ClosureValidationRunId = '35950731991';
const String kExpectedLabProductionEnvironmentId =
    'firebase_project:csp11-exam-platform';
const String kQ17AcceptanceConfirmationPhrase = 'ACCEPT LIVE RELEASE';
const String kLabProductionReleaseAcceptanceSchemaVersion =
    'csp11.lab.production_release_acceptance.v1';
const String kLabProductionReleaseAcceptanceFingerprintSchema =
    'csp11.lab.production_release_acceptance.sha256.v1';

class LabProductionDeploymentAcceptanceException implements Exception {
  const LabProductionDeploymentAcceptanceException(this.message);

  final String message;

  @override
  String toString() =>
      'LabProductionDeploymentAcceptanceException: ' + message;
}

bool _isSha256Fingerprint(String value, String schema) {
  final prefix = schema + ':';
  if (!value.startsWith(prefix)) return false;
  return RegExp(r'^[0-9a-f]{64}$').hasMatch(value.substring(prefix.length));
}

class LabProductionReleaseAcceptance {
  LabProductionReleaseAcceptance._({
    required this.releaseId,
    required this.q16ClosureSha,
    required this.q16ValidationRunId,
    required this.environmentId,
    required this.manifestFingerprint,
    required this.evidenceFingerprint,
    required this.labCount,
    required this.totalDecisionCount,
    required this.acceptedBy,
    required this.acceptedAtIso,
    required this.acceptanceFingerprint,
  }) {
    if (releaseId != kInitialLabProductionReleaseId ||
        q16ClosureSha != kLspQ16ClosedSha ||
        q16ValidationRunId != kLspQ16ClosureValidationRunId ||
        environmentId != kExpectedLabProductionEnvironmentId ||
        !_isSha256Fingerprint(
          manifestFingerprint,
          kLabProductionManifestFingerprintSchema,
        ) ||
        !_isSha256Fingerprint(
          evidenceFingerprint,
          kLabProductionReleaseFingerprintSchema,
        ) ||
        labCount != 10 ||
        totalDecisionCount != 50 ||
        acceptedBy.trim().isEmpty ||
        DateTime.tryParse(acceptedAtIso) == null) {
      throw const LabProductionDeploymentAcceptanceException(
        'Q17 acceptance evidence is incomplete or outside the frozen production boundary.',
      );
    }

    final expected = _computeFingerprint(
      releaseId: releaseId,
      q16ClosureSha: q16ClosureSha,
      q16ValidationRunId: q16ValidationRunId,
      environmentId: environmentId,
      manifestFingerprint: manifestFingerprint,
      evidenceFingerprint: evidenceFingerprint,
      labCount: labCount,
      totalDecisionCount: totalDecisionCount,
      acceptedBy: acceptedBy,
      acceptedAtIso: acceptedAtIso,
    );
    if (acceptanceFingerprint != expected) {
      throw const LabProductionDeploymentAcceptanceException(
        'Q17 acceptance fingerprint mismatch.',
      );
    }
  }

  factory LabProductionReleaseAcceptance.issue({
    required LabProductionReleaseEvidence evidence,
    required String acceptedBy,
    required DateTime acceptedAt,
  }) {
    final normalizedActor = acceptedBy.trim();
    final acceptedAtIso = acceptedAt.toUtc().toIso8601String();
    final acceptanceFingerprint = _computeFingerprint(
      releaseId: evidence.releaseId,
      q16ClosureSha: kLspQ16ClosedSha,
      q16ValidationRunId: kLspQ16ClosureValidationRunId,
      environmentId: evidence.environmentId,
      manifestFingerprint: evidence.manifestFingerprint,
      evidenceFingerprint: evidence.evidenceFingerprint,
      labCount: evidence.labCount,
      totalDecisionCount: evidence.totalDecisionCount,
      acceptedBy: normalizedActor,
      acceptedAtIso: acceptedAtIso,
    );

    return LabProductionReleaseAcceptance._(
      releaseId: evidence.releaseId,
      q16ClosureSha: kLspQ16ClosedSha,
      q16ValidationRunId: kLspQ16ClosureValidationRunId,
      environmentId: evidence.environmentId,
      manifestFingerprint: evidence.manifestFingerprint,
      evidenceFingerprint: evidence.evidenceFingerprint,
      labCount: evidence.labCount,
      totalDecisionCount: evidence.totalDecisionCount,
      acceptedBy: normalizedActor,
      acceptedAtIso: acceptedAtIso,
      acceptanceFingerprint: acceptanceFingerprint,
    );
  }

  factory LabProductionReleaseAcceptance.fromJson(
    Map<String, Object?> json,
  ) {
    final labCount = json['labCount'];
    final totalDecisionCount = json['totalDecisionCount'];
    if (labCount is! int || totalDecisionCount is! int) {
      throw const LabProductionDeploymentAcceptanceException(
        'Q17 acceptance counts must be integers.',
      );
    }

    return LabProductionReleaseAcceptance._(
      releaseId: json['releaseId']?.toString() ?? '',
      q16ClosureSha: json['q16ClosureSha']?.toString() ?? '',
      q16ValidationRunId: json['q16ValidationRunId']?.toString() ?? '',
      environmentId: json['environmentId']?.toString() ?? '',
      manifestFingerprint: json['manifestFingerprint']?.toString() ?? '',
      evidenceFingerprint: json['evidenceFingerprint']?.toString() ?? '',
      labCount: labCount,
      totalDecisionCount: totalDecisionCount,
      acceptedBy: json['acceptedBy']?.toString() ?? '',
      acceptedAtIso: json['acceptedAtIso']?.toString() ?? '',
      acceptanceFingerprint: json['acceptanceFingerprint']?.toString() ?? '',
    );
  }

  final String releaseId;
  final String q16ClosureSha;
  final String q16ValidationRunId;
  final String environmentId;
  final String manifestFingerprint;
  final String evidenceFingerprint;
  final int labCount;
  final int totalDecisionCount;
  final String acceptedBy;
  final String acceptedAtIso;
  final String acceptanceFingerprint;

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': kLabProductionReleaseAcceptanceSchemaVersion,
    'releaseId': releaseId,
    'q16ClosureSha': q16ClosureSha,
    'q16ValidationRunId': q16ValidationRunId,
    'environmentId': environmentId,
    'manifestFingerprint': manifestFingerprint,
    'evidenceFingerprint': evidenceFingerprint,
    'labCount': labCount,
    'totalDecisionCount': totalDecisionCount,
    'acceptedBy': acceptedBy,
    'acceptedAtIso': acceptedAtIso,
    'acceptanceFingerprint': acceptanceFingerprint,
  };

  static String _computeFingerprint({
    required String releaseId,
    required String q16ClosureSha,
    required String q16ValidationRunId,
    required String environmentId,
    required String manifestFingerprint,
    required String evidenceFingerprint,
    required int labCount,
    required int totalDecisionCount,
    required String acceptedBy,
    required String acceptedAtIso,
  }) {
    final payload = <String, Object?>{
      'schemaVersion': kLabProductionReleaseAcceptanceSchemaVersion,
      'releaseId': releaseId,
      'q16ClosureSha': q16ClosureSha,
      'q16ValidationRunId': q16ValidationRunId,
      'environmentId': environmentId,
      'manifestFingerprint': manifestFingerprint,
      'evidenceFingerprint': evidenceFingerprint,
      'labCount': labCount,
      'totalDecisionCount': totalDecisionCount,
      'acceptedBy': acceptedBy,
      'acceptedAtIso': acceptedAtIso,
    };
    return kLabProductionReleaseAcceptanceFingerprintSchema +
        ':' +
        sha256.convert(utf8.encode(jsonEncode(payload))).toString();
  }
}

abstract class LabProductionReleaseAcceptanceRepository {
  Future<LabProductionReleaseAcceptance?> load(String releaseId);

  Future<void> saveImmutable(LabProductionReleaseAcceptance acceptance);
}

class InMemoryLabProductionReleaseAcceptanceRepository
    implements LabProductionReleaseAcceptanceRepository {
  final Map<String, LabProductionReleaseAcceptance> _records =
      <String, LabProductionReleaseAcceptance>{};

  @override
  Future<LabProductionReleaseAcceptance?> load(String releaseId) async =>
      _records[releaseId];

  @override
  Future<void> saveImmutable(LabProductionReleaseAcceptance acceptance) async {
    if (_records.containsKey(acceptance.releaseId)) {
      throw const LabProductionDeploymentAcceptanceException(
        'Q17 live release acceptance is immutable and already exists.',
      );
    }
    _records[acceptance.releaseId] = acceptance;
  }
}

class FirestoreLabProductionReleaseAcceptanceRepository
    implements LabProductionReleaseAcceptanceRepository {
  FirestoreLabProductionReleaseAcceptanceRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('labProductionReleaseAcceptance');

  @override
  Future<LabProductionReleaseAcceptance?> load(String releaseId) async {
    final snapshot = await _collection.doc(releaseId).get();
    if (!snapshot.exists) return null;

    final data = snapshot.data();
    if (data == null ||
        data['schemaVersion'] !=
            kLabProductionReleaseAcceptanceSchemaVersion) {
      throw const LabProductionDeploymentAcceptanceException(
        'Unsupported or empty Q17 production acceptance document.',
      );
    }

    final payload = Map<String, Object?>.from(data)..remove('serverCreatedAt');
    final acceptance = LabProductionReleaseAcceptance.fromJson(payload);
    if (acceptance.releaseId != releaseId) {
      throw const LabProductionDeploymentAcceptanceException(
        'Q17 Firestore acceptance identity does not match its document key.',
      );
    }
    return acceptance;
  }

  @override
  Future<void> saveImmutable(LabProductionReleaseAcceptance acceptance) async {
    final reference = _collection.doc(acceptance.releaseId);
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(reference);
      if (existing.exists) {
        throw const LabProductionDeploymentAcceptanceException(
          'Q17 live release acceptance is immutable and already exists.',
        );
      }
      transaction.set(reference, <String, dynamic>{
        ...acceptance.toJson(),
        'serverCreatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}

enum LabProductionDeploymentState { blocked, ready, accepted }

class LabProductionDeploymentInspection {
  const LabProductionDeploymentInspection({
    required this.state,
    required this.environmentId,
    required this.expectedEnvironmentId,
    required this.manifestId,
    required this.manifestFingerprint,
    required this.expectedLabCount,
    required this.publishedCount,
    required this.catalogueCount,
    required this.catalogueIdentityCount,
    this.evidence,
    this.acceptance,
    this.blockingReason,
  });

  final LabProductionDeploymentState state;
  final String environmentId;
  final String expectedEnvironmentId;
  final String manifestId;
  final String manifestFingerprint;
  final int expectedLabCount;
  final int publishedCount;
  final int catalogueCount;
  final int catalogueIdentityCount;
  final LabProductionReleaseEvidence? evidence;
  final LabProductionReleaseAcceptance? acceptance;
  final String? blockingReason;

  bool get canAccept => state == LabProductionDeploymentState.ready;
  bool get isAccepted => state == LabProductionDeploymentState.accepted;

  String get stateLabel {
    switch (state) {
      case LabProductionDeploymentState.blocked:
        return 'BLOCKED';
      case LabProductionDeploymentState.ready:
        return 'READY';
      case LabProductionDeploymentState.accepted:
        return 'ACCEPTED';
    }
  }
}

abstract class LabProductionDeploymentAcceptanceOperator {
  Future<LabProductionDeploymentInspection> inspect();

  Future<LabProductionReleaseAcceptance> acceptLiveRelease({
    required String acceptedBy,
    required String confirmationPhrase,
    DateTime? acceptedAt,
  });
}

class LabProductionDeploymentAcceptanceService
    implements LabProductionDeploymentAcceptanceOperator {
  const LabProductionDeploymentAcceptanceService({
    required this.releaseOperator,
    required this.acceptanceRepository,
    this.expectedEnvironmentId = kExpectedLabProductionEnvironmentId,
  });

  factory LabProductionDeploymentAcceptanceService.firestore({
    FirebaseFirestore? firestore,
  }) {
    final instance = firestore ?? FirebaseFirestore.instance;
    return LabProductionDeploymentAcceptanceService(
      releaseOperator: LabProductionReleaseOperatorService.firestore(
        firestore: instance,
      ),
      acceptanceRepository:
          FirestoreLabProductionReleaseAcceptanceRepository(
            firestore: instance,
          ),
    );
  }

  final LabProductionReleaseOperator releaseOperator;
  final LabProductionReleaseAcceptanceRepository acceptanceRepository;
  final String expectedEnvironmentId;

  @override
  Future<LabProductionDeploymentInspection> inspect() async {
    final release = await releaseOperator.inspect();
    final evidence = release.evidence;

    LabProductionDeploymentInspection blocked(String reason) {
      return LabProductionDeploymentInspection(
        state: LabProductionDeploymentState.blocked,
        environmentId: release.environmentId,
        expectedEnvironmentId: expectedEnvironmentId,
        manifestId: release.manifestId,
        manifestFingerprint: release.manifestFingerprint,
        expectedLabCount: release.expectedLabCount,
        publishedCount: release.publishedCount,
        catalogueCount: release.catalogueCount,
        catalogueIdentityCount: release.catalogueIdentityCount,
        evidence: evidence,
        blockingReason: reason,
      );
    }

    if (expectedEnvironmentId != kExpectedLabProductionEnvironmentId) {
      return blocked(
        'Q17 expected environment configuration does not match the frozen production project.',
      );
    }

    if (release.environmentId != expectedEnvironmentId) {
      return blocked(
        'Q17 is blocked because the connected Firebase project is not the frozen production project.',
      );
    }

    if (release.state != LabProductionOperatorState.closed ||
        evidence == null) {
      return blocked(
        'Q17 requires a verified CLOSED Q16 production release before acceptance.',
      );
    }

    if (evidence.releaseId != kInitialLabProductionReleaseId ||
        evidence.environmentId != release.environmentId ||
        evidence.manifestId != release.manifestId ||
        evidence.manifestFingerprint != release.manifestFingerprint ||
        release.expectedLabCount != 10 ||
        release.publishedCount != 10 ||
        release.catalogueCount != 10 ||
        release.catalogueIdentityCount != 10 ||
        evidence.labCount != 10 ||
        evidence.totalDecisionCount != 50) {
      return blocked(
        'Q17 live state does not match the frozen 10-LAB / 50-decision release contract.',
      );
    }

    try {
      final acceptance = await acceptanceRepository.load(evidence.releaseId);
      if (acceptance == null) {
        return LabProductionDeploymentInspection(
          state: LabProductionDeploymentState.ready,
          environmentId: release.environmentId,
          expectedEnvironmentId: expectedEnvironmentId,
          manifestId: release.manifestId,
          manifestFingerprint: release.manifestFingerprint,
          expectedLabCount: release.expectedLabCount,
          publishedCount: release.publishedCount,
          catalogueCount: release.catalogueCount,
          catalogueIdentityCount: release.catalogueIdentityCount,
          evidence: evidence,
        );
      }

      if (acceptance.releaseId != evidence.releaseId ||
          acceptance.environmentId != evidence.environmentId ||
          acceptance.manifestFingerprint != evidence.manifestFingerprint ||
          acceptance.evidenceFingerprint != evidence.evidenceFingerprint ||
          acceptance.labCount != evidence.labCount ||
          acceptance.totalDecisionCount != evidence.totalDecisionCount ||
          acceptance.q16ClosureSha != kLspQ16ClosedSha ||
          acceptance.q16ValidationRunId != kLspQ16ClosureValidationRunId) {
        return blocked(
          'Q17 persisted acceptance does not match the current frozen release evidence.',
        );
      }

      return LabProductionDeploymentInspection(
        state: LabProductionDeploymentState.accepted,
        environmentId: release.environmentId,
        expectedEnvironmentId: expectedEnvironmentId,
        manifestId: release.manifestId,
        manifestFingerprint: release.manifestFingerprint,
        expectedLabCount: release.expectedLabCount,
        publishedCount: release.publishedCount,
        catalogueCount: release.catalogueCount,
        catalogueIdentityCount: release.catalogueIdentityCount,
        evidence: evidence,
        acceptance: acceptance,
      );
    } catch (error) {
      return blocked(error.toString());
    }
  }

  @override
  Future<LabProductionReleaseAcceptance> acceptLiveRelease({
    required String acceptedBy,
    required String confirmationPhrase,
    DateTime? acceptedAt,
  }) async {
    if (acceptedBy.trim().isEmpty) {
      throw const LabProductionDeploymentAcceptanceException(
        'Q17 requires an authenticated admin acceptance actor.',
      );
    }
    if (confirmationPhrase != kQ17AcceptanceConfirmationPhrase) {
      throw const LabProductionDeploymentAcceptanceException(
        'Q17 live release acceptance requires the exact confirmation phrase.',
      );
    }

    final before = await inspect();
    final evidence = before.evidence;
    if (!before.canAccept || evidence == null) {
      throw LabProductionDeploymentAcceptanceException(
        'Q17 acceptance is not permitted from state ' +
            before.stateLabel +
            '.',
      );
    }

    final acceptance = LabProductionReleaseAcceptance.issue(
      evidence: evidence,
      acceptedBy: acceptedBy,
      acceptedAt: acceptedAt ?? DateTime.now().toUtc(),
    );
    await acceptanceRepository.saveImmutable(acceptance);

    final after = await inspect();
    if (!after.isAccepted ||
        after.acceptance?.acceptanceFingerprint !=
            acceptance.acceptanceFingerprint) {
      throw const LabProductionDeploymentAcceptanceException(
        'Q17 acceptance write completed without a verified ACCEPTED state.',
      );
    }
    return after.acceptance!;
  }
}
