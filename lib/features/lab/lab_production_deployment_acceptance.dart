import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import 'lab_contracts.dart';
import 'lab_production_population_seed.dart';
import 'lab_production_release_closure.dart';
import 'lab_production_release_operator.dart';
import 'lab_runtime_binding.dart';

const String kLspQ16ClosedSha = '04bfdc9d5c61faeb5a7a30e86cb753947ba8e49a';
const String kLspQ16ClosureValidationRunId = '35950731991';
const String kExpectedProductionFirebaseProjectId = 'csp11-exam-platform';
const String kInitialLabDeploymentPreflightId =
    'phase_l_population_v1_q17_preflight_v1';
const String kInitialLabReleaseAcceptanceId =
    'phase_l_population_v1_q17_acceptance_v1';
const String kLabDeploymentPreflightFingerprintSchema =
    'csp11.lab.production_deployment_preflight.sha256.v1';
const String kLabReleaseAcceptanceFingerprintSchema =
    'csp11.lab.production_release_acceptance.sha256.v1';

class LabProductionDeploymentException implements Exception {
  const LabProductionDeploymentException(this.message);

  final String message;

  @override
  String toString() => 'LabProductionDeploymentException: ' + message;
}

String _fingerprint(String schema, Map<String, Object?> payload) {
  final digest = sha256.convert(utf8.encode(jsonEncode(payload)));
  return schema + ':' + digest.toString();
}

bool _validFingerprint(String value, String schema) {
  final prefix = schema + ':';
  return value.startsWith(prefix) &&
      RegExp(r'^[0-9a-f]{64}$').hasMatch(value.substring(prefix.length));
}

class LabProductionDeploymentPreflightEvidence {
  LabProductionDeploymentPreflightEvidence._({
    required this.preflightId,
    required this.projectId,
    required this.manifestId,
    required this.manifestFingerprint,
    required this.q16ClosureSha,
    required this.q16ValidationRunId,
    required this.operatorState,
    required this.verifiedBy,
    required this.verifiedAtIso,
    required this.labCount,
    required this.totalDecisionCount,
    required this.preflightFingerprint,
  }) {
    LabIds.requireCanonical(preflightId, 'Q17 deployment preflight ID');
    LabIds.requireCanonical(manifestId, 'Q17 manifest ID');

    if (projectId != kExpectedProductionFirebaseProjectId ||
        q16ClosureSha != kLspQ16ClosedSha ||
        q16ValidationRunId != kLspQ16ClosureValidationRunId ||
        verifiedBy.trim().isEmpty ||
        DateTime.tryParse(verifiedAtIso) == null ||
        labCount != 10 ||
        totalDecisionCount != 50 ||
        !_validFingerprint(
          manifestFingerprint,
          kLabProductionManifestFingerprintSchema,
        )) {
      throw const LabProductionDeploymentException(
        'Q17 deployment preflight evidence is not bound to the frozen production contract.',
      );
    }

    final expected = _computeFingerprint(
      preflightId: preflightId,
      projectId: projectId,
      manifestId: manifestId,
      manifestFingerprint: manifestFingerprint,
      q16ClosureSha: q16ClosureSha,
      q16ValidationRunId: q16ValidationRunId,
      operatorState: operatorState,
      verifiedBy: verifiedBy,
      verifiedAtIso: verifiedAtIso,
      labCount: labCount,
      totalDecisionCount: totalDecisionCount,
    );
    if (preflightFingerprint != expected) {
      throw const LabProductionDeploymentException(
        'Q17 deployment preflight fingerprint mismatch.',
      );
    }
  }

  factory LabProductionDeploymentPreflightEvidence.issue({
    required String projectId,
    required String manifestId,
    required String manifestFingerprint,
    required String operatorState,
    required String verifiedBy,
    required DateTime verifiedAt,
    required int labCount,
    required int totalDecisionCount,
  }) {
    final verifiedAtIso = verifiedAt.toUtc().toIso8601String();
    final fingerprint = _computeFingerprint(
      preflightId: kInitialLabDeploymentPreflightId,
      projectId: projectId,
      manifestId: manifestId,
      manifestFingerprint: manifestFingerprint,
      q16ClosureSha: kLspQ16ClosedSha,
      q16ValidationRunId: kLspQ16ClosureValidationRunId,
      operatorState: operatorState,
      verifiedBy: verifiedBy.trim(),
      verifiedAtIso: verifiedAtIso,
      labCount: labCount,
      totalDecisionCount: totalDecisionCount,
    );

    return LabProductionDeploymentPreflightEvidence._(
      preflightId: kInitialLabDeploymentPreflightId,
      projectId: projectId,
      manifestId: manifestId,
      manifestFingerprint: manifestFingerprint,
      q16ClosureSha: kLspQ16ClosedSha,
      q16ValidationRunId: kLspQ16ClosureValidationRunId,
      operatorState: operatorState,
      verifiedBy: verifiedBy.trim(),
      verifiedAtIso: verifiedAtIso,
      labCount: labCount,
      totalDecisionCount: totalDecisionCount,
      preflightFingerprint: fingerprint,
    );
  }

  factory LabProductionDeploymentPreflightEvidence.fromJson(
    Map<String, Object?> json,
  ) {
    final labCount = json['labCount'];
    final totalDecisionCount = json['totalDecisionCount'];
    if (labCount is! int || totalDecisionCount is! int) {
      throw const LabProductionDeploymentException(
        'Q17 deployment preflight counts must be integers.',
      );
    }

    return LabProductionDeploymentPreflightEvidence._(
      preflightId: json['preflightId']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      manifestId: json['manifestId']?.toString() ?? '',
      manifestFingerprint: json['manifestFingerprint']?.toString() ?? '',
      q16ClosureSha: json['q16ClosureSha']?.toString() ?? '',
      q16ValidationRunId: json['q16ValidationRunId']?.toString() ?? '',
      operatorState: json['operatorState']?.toString() ?? '',
      verifiedBy: json['verifiedBy']?.toString() ?? '',
      verifiedAtIso: json['verifiedAtIso']?.toString() ?? '',
      labCount: labCount,
      totalDecisionCount: totalDecisionCount,
      preflightFingerprint: json['preflightFingerprint']?.toString() ?? '',
    );
  }

  static const String schemaVersion =
      'csp11.lab.production_deployment_preflight.v1';

  final String preflightId;
  final String projectId;
  final String manifestId;
  final String manifestFingerprint;
  final String q16ClosureSha;
  final String q16ValidationRunId;
  final String operatorState;
  final String verifiedBy;
  final String verifiedAtIso;
  final int labCount;
  final int totalDecisionCount;
  final String preflightFingerprint;

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': schemaVersion,
    'preflightId': preflightId,
    'projectId': projectId,
    'manifestId': manifestId,
    'manifestFingerprint': manifestFingerprint,
    'q16ClosureSha': q16ClosureSha,
    'q16ValidationRunId': q16ValidationRunId,
    'operatorState': operatorState,
    'verifiedBy': verifiedBy,
    'verifiedAtIso': verifiedAtIso,
    'labCount': labCount,
    'totalDecisionCount': totalDecisionCount,
    'preflightFingerprint': preflightFingerprint,
  };

  static String _computeFingerprint({
    required String preflightId,
    required String projectId,
    required String manifestId,
    required String manifestFingerprint,
    required String q16ClosureSha,
    required String q16ValidationRunId,
    required String operatorState,
    required String verifiedBy,
    required String verifiedAtIso,
    required int labCount,
    required int totalDecisionCount,
  }) {
    return _fingerprint(
      kLabDeploymentPreflightFingerprintSchema,
      <String, Object?>{
        'schemaVersion': schemaVersion,
        'preflightId': preflightId,
        'projectId': projectId,
        'manifestId': manifestId,
        'manifestFingerprint': manifestFingerprint,
        'q16ClosureSha': q16ClosureSha,
        'q16ValidationRunId': q16ValidationRunId,
        'operatorState': operatorState,
        'verifiedBy': verifiedBy,
        'verifiedAtIso': verifiedAtIso,
        'labCount': labCount,
        'totalDecisionCount': totalDecisionCount,
      },
    );
  }
}

class LabProductionReleaseAcceptanceEvidence {
  LabProductionReleaseAcceptanceEvidence._({
    required this.acceptanceId,
    required this.preflightId,
    required this.preflightFingerprint,
    required this.projectId,
    required this.releaseId,
    required this.releaseEvidenceFingerprint,
    required this.acceptedBy,
    required this.acceptedAtIso,
    required this.labCount,
    required this.totalDecisionCount,
    required Iterable<String> learnerCatalogueIdentityKeys,
    required this.acceptanceFingerprint,
  }) : learnerCatalogueIdentityKeys = List<String>.unmodifiable(
         learnerCatalogueIdentityKeys.toList()..sort(),
       ) {
    LabIds.requireCanonical(acceptanceId, 'Q17 release acceptance ID');

    if (preflightId != kInitialLabDeploymentPreflightId ||
        projectId != kExpectedProductionFirebaseProjectId ||
        releaseId != kInitialLabProductionReleaseId ||
        acceptedBy.trim().isEmpty ||
        DateTime.tryParse(acceptedAtIso) == null ||
        labCount != 10 ||
        totalDecisionCount != 50 ||
        this.learnerCatalogueIdentityKeys.length != 10 ||
        this.learnerCatalogueIdentityKeys.toSet().length != 10 ||
        !_validFingerprint(
          preflightFingerprint,
          kLabDeploymentPreflightFingerprintSchema,
        ) ||
        !_validFingerprint(
          releaseEvidenceFingerprint,
          kLabProductionReleaseFingerprintSchema,
        )) {
      throw const LabProductionDeploymentException(
        'Q17 live release acceptance evidence is incomplete.',
      );
    }

    final expected = _computeFingerprint(
      acceptanceId: acceptanceId,
      preflightId: preflightId,
      preflightFingerprint: preflightFingerprint,
      projectId: projectId,
      releaseId: releaseId,
      releaseEvidenceFingerprint: releaseEvidenceFingerprint,
      acceptedBy: acceptedBy,
      acceptedAtIso: acceptedAtIso,
      labCount: labCount,
      totalDecisionCount: totalDecisionCount,
      learnerCatalogueIdentityKeys: this.learnerCatalogueIdentityKeys,
    );
    if (acceptanceFingerprint != expected) {
      throw const LabProductionDeploymentException(
        'Q17 live release acceptance fingerprint mismatch.',
      );
    }
  }

  factory LabProductionReleaseAcceptanceEvidence.issue({
    required LabProductionDeploymentPreflightEvidence preflight,
    required LabProductionReleaseEvidence release,
    required String acceptedBy,
    required DateTime acceptedAt,
    required int labCount,
    required int totalDecisionCount,
    required Iterable<String> learnerCatalogueIdentityKeys,
  }) {
    final acceptedAtIso = acceptedAt.toUtc().toIso8601String();
    final keys = learnerCatalogueIdentityKeys.toList()..sort();
    final fingerprint = _computeFingerprint(
      acceptanceId: kInitialLabReleaseAcceptanceId,
      preflightId: preflight.preflightId,
      preflightFingerprint: preflight.preflightFingerprint,
      projectId: preflight.projectId,
      releaseId: release.releaseId,
      releaseEvidenceFingerprint: release.evidenceFingerprint,
      acceptedBy: acceptedBy.trim(),
      acceptedAtIso: acceptedAtIso,
      labCount: labCount,
      totalDecisionCount: totalDecisionCount,
      learnerCatalogueIdentityKeys: keys,
    );

    return LabProductionReleaseAcceptanceEvidence._(
      acceptanceId: kInitialLabReleaseAcceptanceId,
      preflightId: preflight.preflightId,
      preflightFingerprint: preflight.preflightFingerprint,
      projectId: preflight.projectId,
      releaseId: release.releaseId,
      releaseEvidenceFingerprint: release.evidenceFingerprint,
      acceptedBy: acceptedBy.trim(),
      acceptedAtIso: acceptedAtIso,
      labCount: labCount,
      totalDecisionCount: totalDecisionCount,
      learnerCatalogueIdentityKeys: keys,
      acceptanceFingerprint: fingerprint,
    );
  }

  factory LabProductionReleaseAcceptanceEvidence.fromJson(
    Map<String, Object?> json,
  ) {
    final labCount = json['labCount'];
    final totalDecisionCount = json['totalDecisionCount'];
    final keys = json['learnerCatalogueIdentityKeys'];
    if (labCount is! int || totalDecisionCount is! int || keys is! Iterable) {
      throw const LabProductionDeploymentException(
        'Q17 acceptance evidence has invalid field types.',
      );
    }

    return LabProductionReleaseAcceptanceEvidence._(
      acceptanceId: json['acceptanceId']?.toString() ?? '',
      preflightId: json['preflightId']?.toString() ?? '',
      preflightFingerprint: json['preflightFingerprint']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      releaseId: json['releaseId']?.toString() ?? '',
      releaseEvidenceFingerprint:
          json['releaseEvidenceFingerprint']?.toString() ?? '',
      acceptedBy: json['acceptedBy']?.toString() ?? '',
      acceptedAtIso: json['acceptedAtIso']?.toString() ?? '',
      labCount: labCount,
      totalDecisionCount: totalDecisionCount,
      learnerCatalogueIdentityKeys: keys.map((item) => item.toString()),
      acceptanceFingerprint: json['acceptanceFingerprint']?.toString() ?? '',
    );
  }

  static const String schemaVersion =
      'csp11.lab.production_release_acceptance.v1';

  final String acceptanceId;
  final String preflightId;
  final String preflightFingerprint;
  final String projectId;
  final String releaseId;
  final String releaseEvidenceFingerprint;
  final String acceptedBy;
  final String acceptedAtIso;
  final int labCount;
  final int totalDecisionCount;
  final List<String> learnerCatalogueIdentityKeys;
  final String acceptanceFingerprint;

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': schemaVersion,
    'acceptanceId': acceptanceId,
    'preflightId': preflightId,
    'preflightFingerprint': preflightFingerprint,
    'projectId': projectId,
    'releaseId': releaseId,
    'releaseEvidenceFingerprint': releaseEvidenceFingerprint,
    'acceptedBy': acceptedBy,
    'acceptedAtIso': acceptedAtIso,
    'labCount': labCount,
    'totalDecisionCount': totalDecisionCount,
    'learnerCatalogueIdentityKeys': learnerCatalogueIdentityKeys,
    'acceptanceFingerprint': acceptanceFingerprint,
  };

  static String _computeFingerprint({
    required String acceptanceId,
    required String preflightId,
    required String preflightFingerprint,
    required String projectId,
    required String releaseId,
    required String releaseEvidenceFingerprint,
    required String acceptedBy,
    required String acceptedAtIso,
    required int labCount,
    required int totalDecisionCount,
    required Iterable<String> learnerCatalogueIdentityKeys,
  }) {
    final keys = learnerCatalogueIdentityKeys.toList()..sort();
    return _fingerprint(
      kLabReleaseAcceptanceFingerprintSchema,
      <String, Object?>{
        'schemaVersion': schemaVersion,
        'acceptanceId': acceptanceId,
        'preflightId': preflightId,
        'preflightFingerprint': preflightFingerprint,
        'projectId': projectId,
        'releaseId': releaseId,
        'releaseEvidenceFingerprint': releaseEvidenceFingerprint,
        'acceptedBy': acceptedBy,
        'acceptedAtIso': acceptedAtIso,
        'labCount': labCount,
        'totalDecisionCount': totalDecisionCount,
        'learnerCatalogueIdentityKeys': keys,
      },
    );
  }
}

abstract class LabProductionDeploymentRepository {
  Future<void> savePreflightImmutable(
    LabProductionDeploymentPreflightEvidence evidence,
  );

  Future<LabProductionDeploymentPreflightEvidence?> loadPreflight(
    String preflightId,
  );

  Future<void> saveAcceptanceImmutable(
    LabProductionReleaseAcceptanceEvidence evidence,
  );

  Future<LabProductionReleaseAcceptanceEvidence?> loadAcceptance(
    String acceptanceId,
  );
}

class InMemoryLabProductionDeploymentRepository
    implements LabProductionDeploymentRepository {
  final Map<String, LabProductionDeploymentPreflightEvidence> _preflight =
      <String, LabProductionDeploymentPreflightEvidence>{};
  final Map<String, LabProductionReleaseAcceptanceEvidence> _acceptance =
      <String, LabProductionReleaseAcceptanceEvidence>{};

  @override
  Future<void> savePreflightImmutable(
    LabProductionDeploymentPreflightEvidence evidence,
  ) async {
    if (_preflight.containsKey(evidence.preflightId)) {
      throw const LabProductionDeploymentException(
        'Q17 deployment preflight evidence already exists.',
      );
    }
    _preflight[evidence.preflightId] = evidence;
  }

  @override
  Future<LabProductionDeploymentPreflightEvidence?> loadPreflight(
    String preflightId,
  ) async => _preflight[preflightId];

  @override
  Future<void> saveAcceptanceImmutable(
    LabProductionReleaseAcceptanceEvidence evidence,
  ) async {
    if (_acceptance.containsKey(evidence.acceptanceId)) {
      throw const LabProductionDeploymentException(
        'Q17 live release acceptance already exists.',
      );
    }
    _acceptance[evidence.acceptanceId] = evidence;
  }

  @override
  Future<LabProductionReleaseAcceptanceEvidence?> loadAcceptance(
    String acceptanceId,
  ) async => _acceptance[acceptanceId];
}

class FirestoreLabProductionDeploymentRepository
    implements LabProductionDeploymentRepository {
  FirestoreLabProductionDeploymentRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _preflightCollection =>
      _firestore.collection('labProductionDeploymentPreflight');

  CollectionReference<Map<String, dynamic>> get _acceptanceCollection =>
      _firestore.collection('labProductionReleaseAcceptance');

  @override
  Future<void> savePreflightImmutable(
    LabProductionDeploymentPreflightEvidence evidence,
  ) async {
    final reference = _preflightCollection.doc(evidence.preflightId);
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(reference);
      if (existing.exists) {
        throw const LabProductionDeploymentException(
          'Q17 deployment preflight evidence already exists.',
        );
      }
      transaction.set(reference, <String, dynamic>{
        ...evidence.toJson(),
        'serverCreatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<LabProductionDeploymentPreflightEvidence?> loadPreflight(
    String preflightId,
  ) async {
    final snapshot = await _preflightCollection.doc(preflightId).get();
    if (!snapshot.exists) return null;
    final data = snapshot.data();
    if (data == null) {
      throw const LabProductionDeploymentException(
        'Q17 deployment preflight Firestore document is empty.',
      );
    }
    final payload = Map<String, Object?>.from(data)..remove('serverCreatedAt');
    final evidence = LabProductionDeploymentPreflightEvidence.fromJson(payload);
    if (evidence.preflightId != preflightId) {
      throw const LabProductionDeploymentException(
        'Q17 deployment preflight identity does not match its document key.',
      );
    }
    return evidence;
  }

  @override
  Future<void> saveAcceptanceImmutable(
    LabProductionReleaseAcceptanceEvidence evidence,
  ) async {
    final reference = _acceptanceCollection.doc(evidence.acceptanceId);
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(reference);
      if (existing.exists) {
        throw const LabProductionDeploymentException(
          'Q17 live release acceptance already exists.',
        );
      }
      transaction.set(reference, <String, dynamic>{
        ...evidence.toJson(),
        'serverCreatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<LabProductionReleaseAcceptanceEvidence?> loadAcceptance(
    String acceptanceId,
  ) async {
    final snapshot = await _acceptanceCollection.doc(acceptanceId).get();
    if (!snapshot.exists) return null;
    final data = snapshot.data();
    if (data == null) {
      throw const LabProductionDeploymentException(
        'Q17 live acceptance Firestore document is empty.',
      );
    }
    final payload = Map<String, Object?>.from(data)..remove('serverCreatedAt');
    final evidence = LabProductionReleaseAcceptanceEvidence.fromJson(payload);
    if (evidence.acceptanceId != acceptanceId) {
      throw const LabProductionDeploymentException(
        'Q17 live acceptance identity does not match its document key.',
      );
    }
    return evidence;
  }
}

class LabProductionDeploymentStatus {
  const LabProductionDeploymentStatus({
    required this.operatorInspection,
    this.preflight,
    this.acceptance,
  });

  final LabProductionOperatorInspection operatorInspection;
  final LabProductionDeploymentPreflightEvidence? preflight;
  final LabProductionReleaseAcceptanceEvidence? acceptance;
}

class LabQ17GuardedProductionReleaseOperator
    implements LabProductionReleaseOperator {
  const LabQ17GuardedProductionReleaseOperator({
    required this.delegate,
    required this.deploymentRepository,
  });

  final LabProductionReleaseOperator delegate;
  final LabProductionDeploymentRepository deploymentRepository;

  @override
  Future<LabProductionOperatorInspection> inspect() => delegate.inspect();

  Future<void> _requirePreflight() async {
    final evidence = await deploymentRepository.loadPreflight(
      kInitialLabDeploymentPreflightId,
    );
    if (evidence == null ||
        evidence.projectId != kExpectedProductionFirebaseProjectId ||
        evidence.q16ClosureSha != kLspQ16ClosedSha ||
        evidence.q16ValidationRunId != kLspQ16ClosureValidationRunId) {
      throw const LabProductionDeploymentException(
        'Q17 deployment preflight must pass before production release action.',
      );
    }
  }

  @override
  Future<LabProductionReleaseEvidence> executeInitialRelease({
    required String executedBy,
    required String confirmationPhrase,
    DateTime? executedAt,
  }) async {
    await _requirePreflight();
    return delegate.executeInitialRelease(
      executedBy: executedBy,
      confirmationPhrase: confirmationPhrase,
      executedAt: executedAt,
    );
  }

  @override
  Future<LabProductionReleaseEvidence> closeExistingRelease({
    required String executedBy,
    required String confirmationPhrase,
    DateTime? executedAt,
  }) async {
    await _requirePreflight();
    return delegate.closeExistingRelease(
      executedBy: executedBy,
      confirmationPhrase: confirmationPhrase,
      executedAt: executedAt,
    );
  }
}

class LabProductionDeploymentAcceptanceService {
  const LabProductionDeploymentAcceptanceService({
    required this.populationSource,
    required this.operator,
    required this.deploymentRepository,
    required this.learnerRuntime,
  });

  factory LabProductionDeploymentAcceptanceService.firestore({
    FirebaseFirestore? firestore,
  }) {
    final instance = firestore ?? FirebaseFirestore.instance;
    final operator = LabProductionReleaseOperatorService.firestore(
      firestore: instance,
    );
    return LabProductionDeploymentAcceptanceService(
      populationSource: BundledLabProductionPopulationSource(
        bundle: rootBundle,
      ),
      operator: operator,
      deploymentRepository: FirestoreLabProductionDeploymentRepository(
        firestore: instance,
      ),
      learnerRuntime: LabLearnerRuntimeBinding.firestoreProduction(
        firestore: instance,
      ),
    );
  }

  final LabProductionPopulationSource populationSource;
  final LabProductionReleaseOperator operator;
  final LabProductionDeploymentRepository deploymentRepository;
  final LabLearnerRuntimeBinding learnerRuntime;

  Future<LabProductionDeploymentStatus> inspect() async {
    return LabProductionDeploymentStatus(
      operatorInspection: await operator.inspect(),
      preflight: await deploymentRepository.loadPreflight(
        kInitialLabDeploymentPreflightId,
      ),
      acceptance: await deploymentRepository.loadAcceptance(
        kInitialLabReleaseAcceptanceId,
      ),
    );
  }

  Future<LabProductionDeploymentPreflightEvidence> runPreflight({
    required String verifiedBy,
    DateTime? verifiedAt,
  }) async {
    if (verifiedBy.trim().isEmpty) {
      throw const LabProductionDeploymentException(
        'Q17 deployment preflight requires an authenticated admin actor.',
      );
    }

    final existing = await deploymentRepository.loadPreflight(
      kInitialLabDeploymentPreflightId,
    );
    if (existing != null) return existing;

    final manifest = await populationSource.loadManifest();
    final candidates = await populationSource.loadCandidates(manifest);
    final inspection = await operator.inspect();

    if (inspection.state == LabProductionOperatorState.blockedPartial) {
      throw LabProductionDeploymentException(
        'Q17 deployment preflight blocked: ' +
            (inspection.blockingReason ?? 'partial production state'),
      );
    }

    if (inspection.environmentId !=
        'firebase_project:' + kExpectedProductionFirebaseProjectId) {
      throw LabProductionDeploymentException(
        'Q17 production target mismatch: ' + inspection.environmentId + '.',
      );
    }

    if (manifest.entries.length != 10 || candidates.length != 10) {
      throw const LabProductionDeploymentException(
        'Q17 requires the frozen 10-LAB population manifest.',
      );
    }

    var totalDecisionCount = 0;
    final candidateByEntry = <String, LabProductionPopulationSeedCandidate>{
      for (final candidate in candidates) candidate.entryId: candidate,
    };

    for (final entry in manifest.entries) {
      final candidate = candidateByEntry[entry.entryId];
      if (candidate == null) {
        throw LabProductionDeploymentException(
          'Q17 population asset missing for ' + entry.entryId + '.',
        );
      }
      final package = LabPackage.decode(jsonEncode(candidate.technicalRoot));
      if (package.metadata.id != entry.labId ||
          package.metadata.versionId != entry.versionId) {
        throw LabProductionDeploymentException(
          'Q17 population asset identity mismatch for ' +
              entry.identityKey +
              '.',
        );
      }
      totalDecisionCount += package.nodes.whereType<LabDecisionNode>().length;
    }

    if (totalDecisionCount != 50) {
      throw LabProductionDeploymentException(
        'Q17 expected 50 LAB decisions but found ' +
            totalDecisionCount.toString() +
            '.',
      );
    }

    final evidence = LabProductionDeploymentPreflightEvidence.issue(
      projectId: kExpectedProductionFirebaseProjectId,
      manifestId: manifest.manifestId,
      manifestFingerprint:
          LabProductionReleaseClosureService.manifestFingerprintFor(manifest),
      operatorState: inspection.stateLabel,
      verifiedBy: verifiedBy,
      verifiedAt: verifiedAt ?? DateTime.now().toUtc(),
      labCount: manifest.entries.length,
      totalDecisionCount: totalDecisionCount,
    );

    await deploymentRepository.savePreflightImmutable(evidence);
    final persisted = await deploymentRepository.loadPreflight(
      evidence.preflightId,
    );
    if (persisted == null ||
        persisted.preflightFingerprint != evidence.preflightFingerprint) {
      throw const LabProductionDeploymentException(
        'Q17 deployment preflight did not persist exactly.',
      );
    }
    return persisted;
  }

  Future<LabProductionReleaseAcceptanceEvidence> acceptLiveRelease({
    required String acceptedBy,
    DateTime? acceptedAt,
  }) async {
    if (acceptedBy.trim().isEmpty) {
      throw const LabProductionDeploymentException(
        'Q17 live acceptance requires an authenticated admin actor.',
      );
    }

    final existing = await deploymentRepository.loadAcceptance(
      kInitialLabReleaseAcceptanceId,
    );
    if (existing != null) return existing;

    final preflight = await deploymentRepository.loadPreflight(
      kInitialLabDeploymentPreflightId,
    );
    if (preflight == null) {
      throw const LabProductionDeploymentException(
        'Q17 live acceptance requires persisted deployment preflight evidence.',
      );
    }

    final manifest = await populationSource.loadManifest();
    final inspection = await operator.inspect();
    final release = inspection.evidence;
    if (!inspection.isClosed || release == null) {
      throw const LabProductionDeploymentException(
        'Q17 live acceptance requires a CLOSED Q15 production release.',
      );
    }

    final available = await learnerRuntime.listAvailable();
    final expected = manifest.entries.map((entry) => entry.identityKey).toSet();
    final actual = available.map((entry) => entry.identityKey).toSet();

    if (available.length != 10 ||
        actual.length != 10 ||
        !actual.containsAll(expected) ||
        !expected.containsAll(actual)) {
      throw const LabProductionDeploymentException(
        'Q17 learner runtime catalogue does not exactly match the 10-LAB manifest.',
      );
    }

    var totalDecisionCount = 0;
    for (final entry in manifest.entries) {
      final delivery = await learnerRuntime.load(
        labId: entry.labId,
        versionId: entry.versionId,
      );
      totalDecisionCount += delivery.package.nodes
          .whereType<LabDecisionNode>()
          .length;
    }

    if (totalDecisionCount != 50 ||
        release.labCount != 10 ||
        release.totalDecisionCount != 50) {
      throw const LabProductionDeploymentException(
        'Q17 learner runtime decision totals do not match release evidence.',
      );
    }

    final evidence = LabProductionReleaseAcceptanceEvidence.issue(
      preflight: preflight,
      release: release,
      acceptedBy: acceptedBy,
      acceptedAt: acceptedAt ?? DateTime.now().toUtc(),
      labCount: available.length,
      totalDecisionCount: totalDecisionCount,
      learnerCatalogueIdentityKeys: actual,
    );

    await deploymentRepository.saveAcceptanceImmutable(evidence);
    final persisted = await deploymentRepository.loadAcceptance(
      evidence.acceptanceId,
    );
    if (persisted == null ||
        persisted.acceptanceFingerprint != evidence.acceptanceFingerprint) {
      throw const LabProductionDeploymentException(
        'Q17 live acceptance did not persist exactly.',
      );
    }
    return persisted;
  }
}
