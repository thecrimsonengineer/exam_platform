import 'dart:convert';

import 'lab_contracts.dart';
import 'lab_exhaustive_route_validator.dart';

class LabL4lEvidenceCertificate {
  LabL4lEvidenceCertificate({
    required this.labId,
    required this.versionId,
    required this.validationAuthority,
    required this.validatedAtIso,
    required Map<String, Object?> routeEvidence,
  }) : routeEvidence = Map<String, Object?>.unmodifiable(routeEvidence) {
    LabIds.requireCanonical(labId, 'L4L certificate LAB ID');
    LabIds.requireCanonical(versionId, 'L4L certificate version ID');
    if (validationAuthority.trim().isEmpty || validatedAtIso.trim().isEmpty) {
      throw const LabContractException(
        'L4L certificate requires validation authority and timestamp.',
      );
    }
    if (this.routeEvidence['schemaVersion'] !=
        'csp11.lab.l4l.exhaustive.v1') {
      throw const LabContractException(
        'L4L certificate requires exhaustive route evidence v1.',
      );
    }
  }

  factory LabL4lEvidenceCertificate.fromReport({
    required LabPackage package,
    required LabExhaustiveRouteReport report,
    required String validationAuthority,
    required DateTime validatedAt,
  }) {
    if (!report.isValid) {
      throw const LabContractException(
        'Only a passing L4L exhaustive route report can be certified.',
      );
    }
    return LabL4lEvidenceCertificate(
      labId: package.metadata.id,
      versionId: package.metadata.versionId,
      validationAuthority: validationAuthority.trim(),
      validatedAtIso: validatedAt.toUtc().toIso8601String(),
      routeEvidence: report.toEvidenceJson(),
    );
  }

  factory LabL4lEvidenceCertificate.fromJson(Map<String, Object?> json) {
    if (json['schemaVersion'] != schemaVersion) {
      throw const LabContractException(
        'Unsupported L4L evidence certificate schema.',
      );
    }
    final rawEvidence = json['routeEvidence'];
    if (rawEvidence is! Map) {
      throw const LabContractException(
        'L4L certificate route evidence must be an object.',
      );
    }

    return LabL4lEvidenceCertificate(
      labId: json['labId']?.toString() ?? '',
      versionId: json['versionId']?.toString() ?? '',
      validationAuthority: json['validationAuthority']?.toString() ?? '',
      validatedAtIso: json['validatedAtIso']?.toString() ?? '',
      routeEvidence: rawEvidence.cast<String, Object?>(),
    );
  }

  static const String schemaVersion = 'csp11.lab.l4l.certificate.v1';

  final String labId;
  final String versionId;
  final String validationAuthority;
  final String validatedAtIso;
  final Map<String, Object?> routeEvidence;

  bool get isPass =>
      routeEvidence['isValid'] == true &&
      routeEvidence['deterministic'] == true &&
      routeEvidence['routeInvariantsHold'] == true &&
      routeEvidence['completeOptionCoverage'] == true &&
      routeEvidence['completeConsequenceCoverage'] == true &&
      routeEvidence['completeGateCoverage'] == true &&
      routeEvidence['completeEndingCoverage'] == true &&
      routeEvidence['limitExceeded'] == false &&
      (routeEvidence['fingerprint']?.toString().isNotEmpty ?? false);

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': schemaVersion,
    'labId': labId,
    'versionId': versionId,
    'validationAuthority': validationAuthority,
    'validatedAtIso': validatedAtIso,
    'routeEvidence': routeEvidence,
  };

  String encode() => jsonEncode(toJson());

  static LabL4lEvidenceCertificate decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const LabContractException(
        'L4L evidence certificate root must be an object.',
      );
    }
    return LabL4lEvidenceCertificate.fromJson(
      decoded.cast<String, Object?>(),
    );
  }
}
