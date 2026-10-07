enum ReleaseAdmissionGateStatus {
  pass,
  fail,
  notApplicable;

  String get wireValue {
    switch (this) {
      case ReleaseAdmissionGateStatus.pass:
        return 'PASS';
      case ReleaseAdmissionGateStatus.fail:
        return 'FAIL';
      case ReleaseAdmissionGateStatus.notApplicable:
        return 'NOT_APPLICABLE';
    }
  }
}

enum ReleaseAdmissionGateSeverity {
  info,
  warning,
  error;

  String get wireValue {
    switch (this) {
      case ReleaseAdmissionGateSeverity.info:
        return 'INFO';
      case ReleaseAdmissionGateSeverity.warning:
        return 'WARNING';
      case ReleaseAdmissionGateSeverity.error:
        return 'ERROR';
    }
  }
}

enum ReleaseAdmissionDecision {
  admissible,
  blocked;

  String get wireValue {
    switch (this) {
      case ReleaseAdmissionDecision.admissible:
        return 'ADMISSIBLE';
      case ReleaseAdmissionDecision.blocked:
        return 'BLOCKED';
    }
  }
}

class ReleaseAdmissionGateDefinition {
  const ReleaseAdmissionGateDefinition({
    required this.gateId,
    required this.name,
    required this.severity,
    required this.blocking,
  });

  final String gateId;
  final String name;
  final ReleaseAdmissionGateSeverity severity;
  final bool blocking;
}

class ReleaseAdmissionGate {
  const ReleaseAdmissionGate({
    required this.gateId,
    required this.name,
    required this.status,
    required this.severity,
    required this.blocking,
    required this.evidence,
    required this.message,
  });

  final String gateId;
  final String name;
  final ReleaseAdmissionGateStatus status;
  final ReleaseAdmissionGateSeverity severity;
  final bool blocking;
  final List<String> evidence;
  final String message;

  ReleaseAdmissionGate copyWith({
    String? gateId,
    String? name,
    ReleaseAdmissionGateStatus? status,
    ReleaseAdmissionGateSeverity? severity,
    bool? blocking,
    List<String>? evidence,
    String? message,
  }) {
    return ReleaseAdmissionGate(
      gateId: gateId ?? this.gateId,
      name: name ?? this.name,
      status: status ?? this.status,
      severity: severity ?? this.severity,
      blocking: blocking ?? this.blocking,
      evidence: evidence ?? this.evidence,
      message: message ?? this.message,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'gateId': gateId,
    'name': name,
    'status': status.wireValue,
    'severity': severity.wireValue,
    'blocking': blocking,
    'evidence': evidence,
    'message': message,
  };
}

class ReleaseAdmissionIssue {
  const ReleaseAdmissionIssue({
    required this.code,
    required this.message,
    this.gateId,
  });

  final String code;
  final String message;
  final String? gateId;

  Map<String, Object?> toJson() => <String, Object?>{
    'code': code,
    'gateId': gateId,
    'message': message,
  };
}

class ReleaseAdmissionResult {
  const ReleaseAdmissionResult({
    required this.decision,
    required this.requiredGateCount,
    required this.passedGateCount,
    required this.blockingFailureCount,
    required this.gates,
    required this.issues,
  });

  final ReleaseAdmissionDecision decision;
  final int requiredGateCount;
  final int passedGateCount;
  final int blockingFailureCount;
  final List<ReleaseAdmissionGate> gates;
  final List<ReleaseAdmissionIssue> issues;

  bool get admissible => decision == ReleaseAdmissionDecision.admissible;

  Map<String, Object?> toJson() => <String, Object?>{
    'decision': decision.wireValue,
    'requiredGateCount': requiredGateCount,
    'passedGateCount': passedGateCount,
    'blockingFailureCount': blockingFailureCount,
    'gates': gates.map((gate) => gate.toJson()).toList(),
    'issues': issues.map((issue) => issue.toJson()).toList(),
  };
}

class ReleaseAdmissionPolicy {
  const ReleaseAdmissionPolicy({
    this.permittedNotApplicableGateIds = const <String>{},
  });

  final Set<String> permittedNotApplicableGateIds;

  static const List<ReleaseAdmissionGateDefinition> canonicalDefinitions =
      <ReleaseAdmissionGateDefinition>[
        ReleaseAdmissionGateDefinition(
          gateId: 'RG001',
          name: 'repository_clean',
          severity: ReleaseAdmissionGateSeverity.error,
          blocking: true,
        ),
        ReleaseAdmissionGateDefinition(
          gateId: 'RG002',
          name: 'repository_identity',
          severity: ReleaseAdmissionGateSeverity.error,
          blocking: true,
        ),
        ReleaseAdmissionGateDefinition(
          gateId: 'RG003',
          name: 'version_valid',
          severity: ReleaseAdmissionGateSeverity.error,
          blocking: true,
        ),
        ReleaseAdmissionGateDefinition(
          gateId: 'RG004',
          name: 'build_number_valid',
          severity: ReleaseAdmissionGateSeverity.error,
          blocking: true,
        ),
        ReleaseAdmissionGateDefinition(
          gateId: 'RG005',
          name: 'dependency_lock',
          severity: ReleaseAdmissionGateSeverity.error,
          blocking: true,
        ),
        ReleaseAdmissionGateDefinition(
          gateId: 'RG006',
          name: 'environment_valid',
          severity: ReleaseAdmissionGateSeverity.error,
          blocking: true,
        ),
        ReleaseAdmissionGateDefinition(
          gateId: 'RG007',
          name: 'formatter',
          severity: ReleaseAdmissionGateSeverity.error,
          blocking: true,
        ),
        ReleaseAdmissionGateDefinition(
          gateId: 'RG008',
          name: 'analyzer',
          severity: ReleaseAdmissionGateSeverity.error,
          blocking: true,
        ),
        ReleaseAdmissionGateDefinition(
          gateId: 'RG009',
          name: 'unit_tests',
          severity: ReleaseAdmissionGateSeverity.error,
          blocking: true,
        ),
        ReleaseAdmissionGateDefinition(
          gateId: 'RG010',
          name: 'widget_tests',
          severity: ReleaseAdmissionGateSeverity.error,
          blocking: true,
        ),
        ReleaseAdmissionGateDefinition(
          gateId: 'RG011',
          name: 'schema_validation',
          severity: ReleaseAdmissionGateSeverity.error,
          blocking: true,
        ),
        ReleaseAdmissionGateDefinition(
          gateId: 'RG012',
          name: 'component_evidence',
          severity: ReleaseAdmissionGateSeverity.error,
          blocking: true,
        ),
        ReleaseAdmissionGateDefinition(
          gateId: 'RG013',
          name: 'artifact_inventory',
          severity: ReleaseAdmissionGateSeverity.error,
          blocking: true,
        ),
        ReleaseAdmissionGateDefinition(
          gateId: 'RG014',
          name: 'artifact_hashes',
          severity: ReleaseAdmissionGateSeverity.error,
          blocking: true,
        ),
        ReleaseAdmissionGateDefinition(
          gateId: 'RG015',
          name: 'provenance',
          severity: ReleaseAdmissionGateSeverity.error,
          blocking: true,
        ),
        ReleaseAdmissionGateDefinition(
          gateId: 'RG016',
          name: 'release_state',
          severity: ReleaseAdmissionGateSeverity.error,
          blocking: true,
        ),
        ReleaseAdmissionGateDefinition(
          gateId: 'RG017',
          name: 'manifest_completeness',
          severity: ReleaseAdmissionGateSeverity.error,
          blocking: true,
        ),
      ];

  ReleaseAdmissionResult evaluate(Iterable<ReleaseAdmissionGate> gates) {
    final definitionsById = <String, ReleaseAdmissionGateDefinition>{
      for (final definition in canonicalDefinitions)
        definition.gateId: definition,
    };

    for (final gateId in permittedNotApplicableGateIds) {
      if (!definitionsById.containsKey(gateId)) {
        throw ArgumentError.value(
          gateId,
          'permittedNotApplicableGateIds',
          'Unknown release admission gate.',
        );
      }
    }

    final issues = <ReleaseAdmissionIssue>[];
    final gatesById = <String, ReleaseAdmissionGate>{};

    for (final gate in gates) {
      if (!definitionsById.containsKey(gate.gateId)) {
        issues.add(
          ReleaseAdmissionIssue(
            code: 'RGA002_UNKNOWN_GATE',
            gateId: gate.gateId,
            message: 'Unknown release admission gate.',
          ),
        );
        continue;
      }

      if (gatesById.containsKey(gate.gateId)) {
        issues.add(
          ReleaseAdmissionIssue(
            code: 'RGA001_DUPLICATE_GATE',
            gateId: gate.gateId,
            message: 'Duplicate release admission gate.',
          ),
        );
        continue;
      }

      gatesById[gate.gateId] = gate;
    }

    final evaluatedGates = <ReleaseAdmissionGate>[];
    var passedGateCount = 0;

    for (final definition in canonicalDefinitions) {
      final gate = gatesById[definition.gateId];
      if (gate == null) {
        issues.add(
          ReleaseAdmissionIssue(
            code: 'RGA003_MISSING_REQUIRED_GATE',
            gateId: definition.gateId,
            message: 'Required release admission gate is missing.',
          ),
        );
        continue;
      }

      evaluatedGates.add(gate);
      final issueCountBeforeGate = issues.length;

      if (gate.name != definition.name) {
        issues.add(
          ReleaseAdmissionIssue(
            code: 'RGA004_GATE_NAME_MISMATCH',
            gateId: definition.gateId,
            message: 'Gate name does not match canonical policy.',
          ),
        );
      }

      if (gate.severity != definition.severity) {
        issues.add(
          ReleaseAdmissionIssue(
            code: 'RGA005_GATE_SEVERITY_MISMATCH',
            gateId: definition.gateId,
            message: 'Gate severity does not match canonical policy.',
          ),
        );
      }

      if (gate.blocking != definition.blocking) {
        issues.add(
          ReleaseAdmissionIssue(
            code: 'RGA006_GATE_BLOCKING_MISMATCH',
            gateId: definition.gateId,
            message: 'Gate blocking flag does not match canonical policy.',
          ),
        );
      }

      if (gate.message.trim().isEmpty) {
        issues.add(
          ReleaseAdmissionIssue(
            code: 'RGA007_GATE_MESSAGE_MISSING',
            gateId: definition.gateId,
            message: 'Gate message must not be empty.',
          ),
        );
      }

      final evidenceRefs = <String>{};
      for (final evidenceRef in gate.evidence) {
        if (evidenceRef.trim().isEmpty) {
          issues.add(
            ReleaseAdmissionIssue(
              code: 'RGA009_INVALID_EVIDENCE_REF',
              gateId: definition.gateId,
              message: 'Evidence references must not be empty.',
            ),
          );
          continue;
        }
        if (!evidenceRefs.add(evidenceRef)) {
          issues.add(
            ReleaseAdmissionIssue(
              code: 'RGA010_DUPLICATE_EVIDENCE_REF',
              gateId: definition.gateId,
              message: 'Evidence references must be unique per gate.',
            ),
          );
        }
      }

      switch (gate.status) {
        case ReleaseAdmissionGateStatus.pass:
          if (gate.evidence.isEmpty) {
            issues.add(
              ReleaseAdmissionIssue(
                code: 'RGA008_PASS_EVIDENCE_MISSING',
                gateId: definition.gateId,
                message: 'A PASS requires at least one evidence reference.',
              ),
            );
          }
          break;
        case ReleaseAdmissionGateStatus.fail:
          if (definition.blocking) {
            issues.add(
              ReleaseAdmissionIssue(
                code: 'RGA012_REQUIRED_GATE_FAILED',
                gateId: definition.gateId,
                message: 'Blocking release admission gate failed.',
              ),
            );
          }
          break;
        case ReleaseAdmissionGateStatus.notApplicable:
          if (!permittedNotApplicableGateIds.contains(definition.gateId)) {
            issues.add(
              ReleaseAdmissionIssue(
                code: 'RGA011_NOT_APPLICABLE_NOT_PERMITTED',
                gateId: definition.gateId,
                message: 'NOT_APPLICABLE is not permitted for this gate.',
              ),
            );
          }
          break;
      }

      if (issues.length == issueCountBeforeGate &&
          gate.status == ReleaseAdmissionGateStatus.pass) {
        passedGateCount++;
      }
    }

    final immutableGates = List<ReleaseAdmissionGate>.unmodifiable(
      evaluatedGates,
    );
    final immutableIssues = List<ReleaseAdmissionIssue>.unmodifiable(issues);
    final decision = immutableIssues.isEmpty
        ? ReleaseAdmissionDecision.admissible
        : ReleaseAdmissionDecision.blocked;

    return ReleaseAdmissionResult(
      decision: decision,
      requiredGateCount: canonicalDefinitions.length,
      passedGateCount: passedGateCount,
      blockingFailureCount: immutableIssues.length,
      gates: immutableGates,
      issues: immutableIssues,
    );
  }
}
