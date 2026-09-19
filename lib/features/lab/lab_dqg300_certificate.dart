import 'dart:convert';

import 'lab_contracts.dart';
import 'lab_dqg300.dart';

class LabDqg300DecisionCertificate {
  const LabDqg300DecisionCertificate({
    required this.nodeId,
    required this.decisionSignature,
    required this.dqs,
    required this.passedRuleCount,
  });

  factory LabDqg300DecisionCertificate.fromJson(Map<String, Object?> json) {
    final dqs = json['dqs'];
    final passed = json['passedRuleCount'];
    if (dqs is! int || passed is! int) {
      throw const LabContractException(
        'DQG300-LAB certificate decision requires integer DQS and rule count.',
      );
    }
    return LabDqg300DecisionCertificate(
      nodeId: LabIds.requireCanonical(
        json['nodeId']?.toString() ?? '',
        'DQG300-LAB certificate node ID',
      ),
      decisionSignature: json['decisionSignature']?.toString() ?? '',
      dqs: dqs,
      passedRuleCount: passed,
    );
  }

  final String nodeId;
  final String decisionSignature;
  final int dqs;
  final int passedRuleCount;

  bool get isPass =>
      decisionSignature.isNotEmpty && dqs == 100 && passedRuleCount == 300;

  Map<String, Object?> toJson() => <String, Object?>{
    'nodeId': nodeId,
    'decisionSignature': decisionSignature,
    'dqs': dqs,
    'passedRuleCount': passedRuleCount,
  };
}

class LabDqg300EvidenceCertificate {
  LabDqg300EvidenceCertificate({
    required this.labId,
    required this.versionId,
    required this.validationAuthority,
    required this.validatedAtIso,
    required Iterable<LabDqg300DecisionCertificate> decisions,
  }) : decisions = List<LabDqg300DecisionCertificate>.unmodifiable(decisions) {
    LabIds.requireCanonical(labId, 'DQG300-LAB certificate LAB ID');
    LabIds.requireCanonical(versionId, 'DQG300-LAB certificate version ID');
    if (validationAuthority.trim().isEmpty || validatedAtIso.trim().isEmpty) {
      throw const LabContractException(
        'DQG300-LAB certificate requires validation authority and timestamp.',
      );
    }
    if (this.decisions.isEmpty ||
        this.decisions.map((item) => item.nodeId).toSet().length !=
            this.decisions.length) {
      throw const LabContractException(
        'DQG300-LAB certificate requires unique Decision Node evidence.',
      );
    }
  }

  factory LabDqg300EvidenceCertificate.fromReport({
    required LabPackage package,
    required LabDqg300Report report,
    required String validationAuthority,
    required DateTime validatedAt,
  }) {
    if (!report.isValid) {
      throw const LabContractException(
        'Only a passing DQG300-LAB report can be certified.',
      );
    }

    final nodes = <String, LabDecisionNode>{
      for (final node in package.nodes.whereType<LabDecisionNode>())
        node.id: node,
    };

    return LabDqg300EvidenceCertificate(
      labId: package.metadata.id,
      versionId: package.metadata.versionId,
      validationAuthority: validationAuthority.trim(),
      validatedAtIso: validatedAt.toUtc().toIso8601String(),
      decisions: report.decisionResults.map((item) {
        final node = nodes[item.nodeId];
        if (node == null) {
          throw LabContractException(
            'DQG300-LAB report references unknown node ' + item.nodeId + '.',
          );
        }
        return LabDqg300DecisionCertificate(
          nodeId: item.nodeId,
          decisionSignature: LabDqg300Validator.decisionSignature(node),
          dqs: item.result.dqs,
          passedRuleCount: item.result.passedRuleCount,
        );
      }),
    );
  }

  factory LabDqg300EvidenceCertificate.fromJson(Map<String, Object?> json) {
    if (json['schemaVersion'] != schemaVersion) {
      throw const LabContractException(
        'Unsupported DQG300-LAB certificate schema.',
      );
    }
    final rawDecisions = json['decisions'];
    if (rawDecisions is! Iterable) {
      throw const LabContractException(
        'DQG300-LAB certificate decisions must be an array.',
      );
    }
    return LabDqg300EvidenceCertificate(
      labId: json['labId']?.toString() ?? '',
      versionId: json['versionId']?.toString() ?? '',
      validationAuthority: json['validationAuthority']?.toString() ?? '',
      validatedAtIso: json['validatedAtIso']?.toString() ?? '',
      decisions: rawDecisions.map((item) {
        if (item is! Map) {
          throw const LabContractException(
            'DQG300-LAB certificate decision must be an object.',
          );
        }
        return LabDqg300DecisionCertificate.fromJson(
          item.cast<String, Object?>(),
        );
      }),
    );
  }

  static const String schemaVersion = 'csp11.lab.dqg300.v1';

  final String labId;
  final String versionId;
  final String validationAuthority;
  final String validatedAtIso;
  final List<LabDqg300DecisionCertificate> decisions;

  bool get isPass => decisions.every((item) => item.isPass);

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': schemaVersion,
    'labId': labId,
    'versionId': versionId,
    'validationAuthority': validationAuthority,
    'validatedAtIso': validatedAtIso,
    'decisions': decisions.map((item) => item.toJson()).toList(),
  };

  String encode() => jsonEncode(toJson());

  static LabDqg300EvidenceCertificate decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const LabContractException(
        'DQG300-LAB certificate root must be an object.',
      );
    }
    return LabDqg300EvidenceCertificate.fromJson(
      decoded.cast<String, Object?>(),
    );
  }
}
