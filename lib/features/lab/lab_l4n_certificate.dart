import 'dart:convert';

import 'lab_contracts.dart';
import 'lab_publish_evidence_validator.dart';

class LabL4nPublishEvidenceCertificate {
  LabL4nPublishEvidenceCertificate({
    required this.labId,
    required this.versionId,
    required this.validationAuthority,
    required this.validatedAtIso,
    required Map<String, Object?> routeExplorationEvidence,
    required Map<String, Object?> publishEvidence,
  }) : routeExplorationEvidence = Map<String, Object?>.unmodifiable(
         routeExplorationEvidence,
       ),
       publishEvidence = Map<String, Object?>.unmodifiable(publishEvidence) {
    LabIds.requireCanonical(labId, 'L4N certificate LAB ID');
    LabIds.requireCanonical(versionId, 'L4N certificate version ID');
    if (validationAuthority.trim().isEmpty || validatedAtIso.trim().isEmpty) {
      throw const LabContractException(
        'L4N certificate requires validation authority and timestamp.',
      );
    }
    if (this.routeExplorationEvidence['schemaVersion'] !=
        'csp11.lab.l4m.exploration.v1') {
      throw const LabContractException(
        'L4N certificate requires L4M route exploration evidence v1.',
      );
    }
    if (this.publishEvidence['schemaVersion'] !=
        'csp11.lab.l4n.publish_evidence.v1') {
      throw const LabContractException(
        'L4N certificate requires publish evidence v1.',
      );
    }
  }

  factory LabL4nPublishEvidenceCertificate.fromReport({
    required LabPackage package,
    required LabPublishEvidenceReport report,
    required String validationAuthority,
    required DateTime validatedAt,
  }) {
    if (!report.isValid || !report.routeExplorationReport.isValid) {
      throw const LabContractException(
        'Only passing L4M/L4N evidence can be certified.',
      );
    }

    return LabL4nPublishEvidenceCertificate(
      labId: package.metadata.id,
      versionId: package.metadata.versionId,
      validationAuthority: validationAuthority.trim(),
      validatedAtIso: validatedAt.toUtc().toIso8601String(),
      routeExplorationEvidence: report.routeExplorationReport.toEvidenceJson(),
      publishEvidence: report.toEvidenceJson(),
    );
  }

  factory LabL4nPublishEvidenceCertificate.fromJson(Map<String, Object?> json) {
    if (json['schemaVersion'] != schemaVersion) {
      throw const LabContractException(
        'Unsupported L4N publish evidence certificate schema.',
      );
    }
    final rawRouteEvidence = json['routeExplorationEvidence'];
    final rawPublishEvidence = json['publishEvidence'];
    if (rawRouteEvidence is! Map || rawPublishEvidence is! Map) {
      throw const LabContractException(
        'L4N certificate requires route exploration and publish evidence objects.',
      );
    }

    return LabL4nPublishEvidenceCertificate(
      labId: json['labId']?.toString() ?? '',
      versionId: json['versionId']?.toString() ?? '',
      validationAuthority: json['validationAuthority']?.toString() ?? '',
      validatedAtIso: json['validatedAtIso']?.toString() ?? '',
      routeExplorationEvidence: rawRouteEvidence.cast<String, Object?>(),
      publishEvidence: rawPublishEvidence.cast<String, Object?>(),
    );
  }

  static const String schemaVersion = 'csp11.lab.l4n.certificate.v1';

  final String labId;
  final String versionId;
  final String validationAuthority;
  final String validatedAtIso;
  final Map<String, Object?> routeExplorationEvidence;
  final Map<String, Object?> publishEvidence;

  bool get routeEvidenceMatchesPublishEvidence =>
      routeExplorationEvidence['fingerprint'] ==
          publishEvidence['routeExplorationFingerprint'] &&
      routeExplorationEvidence['selectedRouteCount'] ==
          publishEvidence['selectedRouteCount'];

  bool get isPass =>
      routeEvidenceMatchesPublishEvidence &&
      routeExplorationEvidence['isValid'] == true &&
      routeExplorationEvidence['deterministic'] == true &&
      routeExplorationEvidence['completeMandatoryCoverage'] == true &&
      publishEvidence['isValid'] == true &&
      publishEvidence['deterministic'] == true &&
      publishEvidence['routeEvidenceValid'] == true &&
      publishEvidence['privacyBoundaryValid'] == true &&
      publishEvidence['alternateTimelineReferencesValid'] == true &&
      publishEvidence['recoverySignalReferencesValid'] == true &&
      (routeExplorationEvidence['fingerprint']?.toString().isNotEmpty ??
          false) &&
      (publishEvidence['fingerprint']?.toString().isNotEmpty ?? false);

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': schemaVersion,
    'labId': labId,
    'versionId': versionId,
    'validationAuthority': validationAuthority,
    'validatedAtIso': validatedAtIso,
    'routeExplorationEvidence': routeExplorationEvidence,
    'publishEvidence': publishEvidence,
  };

  String encode() => jsonEncode(toJson());

  static LabL4nPublishEvidenceCertificate decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const LabContractException(
        'L4N publish evidence certificate root must be an object.',
      );
    }
    return LabL4nPublishEvidenceCertificate.fromJson(
      decoded.cast<String, Object?>(),
    );
  }
}
