import 'dart:convert';

import 'lab_contracts.dart';
import 'lab_debrief.dart';
import 'lab_learning_twin_bridge.dart';
import 'lab_reachable_route_explorer.dart';
import 'lab_session.dart';

class LabPublishEvidenceReport {
  const LabPublishEvidenceReport({
    required this.routeExplorationReport,
    required this.selectedRouteCount,
    required this.debriefCount,
    required this.decisionEventCount,
    required this.learningEvidenceCount,
    required this.alternateTimelineReferencesValid,
    required this.recoverySignalReferencesValid,
    required this.privacyBoundaryValid,
    required this.routeEvidenceValid,
    required this.deterministic,
    required this.issues,
    required this.fingerprint,
  });

  final LabReachableRouteExplorationReport routeExplorationReport;
  final int selectedRouteCount;
  final int debriefCount;
  final int decisionEventCount;
  final int learningEvidenceCount;
  final bool alternateTimelineReferencesValid;
  final bool recoverySignalReferencesValid;
  final bool privacyBoundaryValid;
  final bool routeEvidenceValid;
  final bool deterministic;
  final List<String> issues;
  final String fingerprint;

  bool get isValid =>
      routeExplorationReport.isValid &&
      selectedRouteCount > 0 &&
      debriefCount == selectedRouteCount &&
      decisionEventCount > 0 &&
      learningEvidenceCount == decisionEventCount &&
      alternateTimelineReferencesValid &&
      recoverySignalReferencesValid &&
      privacyBoundaryValid &&
      routeEvidenceValid &&
      deterministic &&
      issues.isEmpty;

  Map<String, Object?> toEvidenceJson() => <String, Object?>{
    'schemaVersion': 'csp11.lab.l4n.publish_evidence.v1',
    'selectedRouteCount': selectedRouteCount,
    'debriefCount': debriefCount,
    'decisionEventCount': decisionEventCount,
    'learningEvidenceCount': learningEvidenceCount,
    'alternateTimelineReferencesValid': alternateTimelineReferencesValid,
    'recoverySignalReferencesValid': recoverySignalReferencesValid,
    'privacyBoundaryValid': privacyBoundaryValid,
    'routeEvidenceValid': routeEvidenceValid,
    'deterministic': deterministic,
    'issues': issues,
    'routeExplorationFingerprint': routeExplorationReport.fingerprint,
    'fingerprint': fingerprint,
    'isValid': isValid,
  };
}

class LabPublishEvidenceValidator {
  const LabPublishEvidenceValidator({
    this.debriefEngine = const LabDebriefEngine(),
    this.learningTwinBridge = const LabLearningTwinEvidenceBridge(),
  });

  final LabDebriefEngine debriefEngine;
  final LabLearningTwinEvidenceBridge learningTwinBridge;

  LabPublishEvidenceReport validate({
    required LabPackage package,
    required LabReachableRouteExplorationReport routeExplorationReport,
  }) {
    final staticIssues = <String>[];
    final alternateValid = _validateAlternateTimelineReferences(
      package,
      staticIssues,
    );
    final recoveryValid = _validateRecoverySignalReferences(
      package,
      staticIssues,
    );
    final privacyValid = _validatePrivacyBoundary(package, staticIssues);

    if (!routeExplorationReport.isValid) {
      staticIssues.add(
        'L4N publish evidence requires a valid L4M route exploration report.',
      );
      staticIssues.sort();
      return LabPublishEvidenceReport(
        routeExplorationReport: routeExplorationReport,
        selectedRouteCount: routeExplorationReport.selectedRouteCount,
        debriefCount: 0,
        decisionEventCount: 0,
        learningEvidenceCount: 0,
        alternateTimelineReferencesValid: alternateValid,
        recoverySignalReferencesValid: recoveryValid,
        privacyBoundaryValid: privacyValid,
        routeEvidenceValid: false,
        deterministic: false,
        issues: List<String>.unmodifiable(staticIssues),
        fingerprint: '',
      );
    }

    final first = _inspectRoutes(
      package,
      routeExplorationReport.selectedRoutes,
    );
    final second = _inspectRoutes(
      package,
      routeExplorationReport.selectedRoutes,
    );

    final issues = <String>[...staticIssues, ...first.issues]..sort();
    final deterministic =
        first.fingerprint == second.fingerprint &&
        first.debriefCount == second.debriefCount &&
        first.decisionEventCount == second.decisionEventCount &&
        first.learningEvidenceCount == second.learningEvidenceCount &&
        _stringListEquals(first.issues, second.issues);

    if (!deterministic) {
      issues.add(
        'L4N repeated debrief/Learning Twin validation produced different evidence.',
      );
      issues.sort();
    }

    return LabPublishEvidenceReport(
      routeExplorationReport: routeExplorationReport,
      selectedRouteCount: routeExplorationReport.selectedRouteCount,
      debriefCount: first.debriefCount,
      decisionEventCount: first.decisionEventCount,
      learningEvidenceCount: first.learningEvidenceCount,
      alternateTimelineReferencesValid: alternateValid,
      recoverySignalReferencesValid: recoveryValid,
      privacyBoundaryValid: privacyValid,
      routeEvidenceValid: first.routeEvidenceValid,
      deterministic: deterministic,
      issues: List<String>.unmodifiable(issues),
      fingerprint: first.fingerprint,
    );
  }

  _PublishEvidenceInspection _inspectRoutes(
    LabPackage package,
    List<LabExhaustiveRouteTrace> routes,
  ) {
    final routeFingerprints = <String>[];
    final issues = <String>[];
    var debriefCount = 0;
    var decisionEventCount = 0;
    var learningEvidenceCount = 0;
    var routeEvidenceValid = true;

    for (var routeIndex = 0; routeIndex < routes.length; routeIndex++) {
      final route = routes[routeIndex];
      try {
        final session = _sessionFromRoute(
          package,
          route,
          routeIndex: routeIndex,
        );
        final before = jsonEncode(session.toJson());

        final debrief = debriefEngine.reconstruct(
          package: package,
          session: session,
        );
        final evidence = learningTwinBridge.buildEvidence(
          package: package,
          session: session,
        );

        final after = jsonEncode(session.toJson());
        if (before != after) {
          routeEvidenceValid = false;
          issues.add(
            'L4N evidence generation changed session state for route ' +
                routeIndex.toString() +
                '.',
          );
        }

        if (!debrief.completed ||
            debrief.endingId != route.endingId ||
            debrief.decisions.length != session.decisionHistory.length ||
            debrief.causalChain.length != session.decisionHistory.length ||
            !_stringListEquals(debrief.sources, package.metadata.sources)) {
          routeEvidenceValid = false;
          issues.add(
            'L4N debrief reconstruction did not match route ' +
                routeIndex.toString() +
                '.',
          );
        }

        if (evidence.length != session.decisionHistory.length ||
            evidence.any(
              (item) =>
                  item.labId != package.metadata.id ||
                  item.labVersionId != package.metadata.versionId ||
                  item.completion != LabEvidenceCompletion.completed ||
                  !_sanitizedEvidence(item.toSanitizedJson()),
            )) {
          routeEvidenceValid = false;
          issues.add(
            'L4N Learning Twin evidence did not satisfy the sanitized completed-route contract for route ' +
                routeIndex.toString() +
                '.',
          );
        }

        debriefCount++;
        decisionEventCount += session.decisionHistory.length;
        learningEvidenceCount += evidence.length;
        routeFingerprints.add(
          _routeEvidenceFingerprint(
            route: route,
            session: session,
            debrief: debrief,
            evidence: evidence,
          ),
        );
      } catch (error) {
        routeEvidenceValid = false;
        issues.add(
          'L4N route evidence failure at route ' +
              routeIndex.toString() +
              ': ' +
              error.toString(),
        );
      }
    }

    routeFingerprints.sort();
    issues.sort();

    return _PublishEvidenceInspection(
      debriefCount: debriefCount,
      decisionEventCount: decisionEventCount,
      learningEvidenceCount: learningEvidenceCount,
      routeEvidenceValid: routeEvidenceValid,
      issues: issues,
      fingerprint: jsonEncode(routeFingerprints),
    );
  }

  LabSession _sessionFromRoute(
    LabPackage package,
    LabExhaustiveRouteTrace route, {
    required int routeIndex,
  }) {
    if (route.steps.isEmpty) {
      throw const LabContractException(
        'L4N cannot validate an empty route trace.',
      );
    }

    final events = <LabDecisionEvent>[];
    var decisionIndex = 0;
    for (final step in route.steps) {
      final optionId = step.optionId;
      final consequenceId = step.consequenceId;
      if (optionId == null) continue;
      if (consequenceId == null) {
        throw const LabContractException(
          'L4N decision trace is missing consequence evidence.',
        );
      }
      decisionIndex++;
      final delta = <String, Object?>{
        for (final entry in step.stateDelta.entries)
          entry.key: <String, Object?>{
            'before': entry.value.before,
            'after': entry.value.after,
          },
      };
      events.add(
        LabDecisionEvent(
          eventId:
              'l4n_route_' +
              routeIndex.toString() +
              '_event_' +
              decisionIndex.toString(),
          nodeId: step.nodeId,
          selectedOptionId: optionId,
          responseTimeMs: 100 + decisionIndex,
          stateBefore: step.stateBefore,
          stateDelta: delta,
          stateAfter: step.stateAfter,
          consequenceId: consequenceId,
          gateTriggered: step.gateId,
          nextNodeId: step.targetNodeId,
          endingId: step.endingId,
          simulatedMinutes: step.simulatedMinutesAfter,
          timestamp: DateTime.utc(
            2026,
            9,
            19,
            12,
            0,
            decisionIndex,
          ),
        ),
      );
    }

    if (events.isEmpty) {
      throw const LabContractException(
        'L4N publish evidence requires at least one Decision Event.',
      );
    }

    final last = route.steps.last;
    return LabSession(
      sessionId: 'l4n_route_' + routeIndex.toString(),
      userId: 'l4n_validation_user',
      labId: package.metadata.id,
      labVersionId: package.metadata.versionId,
      mode: _validationMode(package),
      startedAt: DateTime.utc(2026, 9, 19, 12),
      currentNodeId: last.nodeId,
      stateValues: last.stateAfter,
      evidenceUnlocked: last.evidenceAfter,
      simulatedMinutes: last.simulatedMinutesAfter,
      status: LabSessionStatus.completed,
      decisionHistory: events,
      appliedConsequenceKeys: const <String>[],
      endingId: route.endingId,
      revision: events.length,
    );
  }

  LabMode _validationMode(LabPackage package) {
    if (package.metadata.supportedModes.contains(LabMode.professional)) {
      return LabMode.professional;
    }
    final modes = package.metadata.supportedModes.toList()
      ..sort((left, right) => left.name.compareTo(right.name));
    if (modes.isEmpty) {
      throw const LabContractException(
        'L4N validation requires at least one supported LAB mode.',
      );
    }
    return modes.first;
  }

  bool _validateAlternateTimelineReferences(
    LabPackage package,
    List<String> issues,
  ) {
    final raw = package.debrief['alternateTimelineOptions'];
    if (raw == null) return true;
    if (raw is! Iterable) {
      issues.add(
        'L4N debrief alternateTimelineOptions must be a list when authored.',
      );
      return false;
    }

    final decisions = <String, LabDecisionNode>{
      for (final node in package.nodes.whereType<LabDecisionNode>())
        node.id: node,
    };
    final seen = <String>{};
    var valid = true;

    for (final item in raw) {
      if (item is! Map) {
        valid = false;
        issues.add(
          'L4N debrief alternate timeline entries must be objects.',
        );
        continue;
      }
      final map = item.cast<String, Object?>();
      final nodeId = map['nodeId']?.toString() ?? '';
      final optionId = map['alternateOptionId']?.toString() ?? '';
      final node = decisions[nodeId];

      if (node == null || optionId.isEmpty) {
        valid = false;
        issues.add(
          'L4N debrief alternate timeline references an unknown Decision Node or empty option.',
        );
        continue;
      }

      try {
        node.requireOption(optionId);
      } catch (_) {
        valid = false;
        issues.add(
          'L4N debrief alternate timeline references unknown option ' +
              nodeId +
              '::' +
              optionId +
              '.',
        );
      }

      final key = nodeId + '::' + optionId;
      if (!seen.add(key)) {
        valid = false;
        issues.add(
          'L4N debrief alternate timeline contains duplicate reference ' +
              key +
              '.',
        );
      }
    }
    return valid;
  }

  bool _validateRecoverySignalReferences(
    LabPackage package,
    List<String> issues,
  ) {
    final raw = package.learningSignals['recoveryDecisionNodeIds'];
    if (raw == null) return true;
    if (raw is! Iterable) {
      issues.add(
        'L4N learningSignals.recoveryDecisionNodeIds must be a list when authored.',
      );
      return false;
    }

    final decisionIds = package.nodes
        .whereType<LabDecisionNode>()
        .map((node) => node.id)
        .toSet();
    final seen = <String>{};
    var valid = true;

    for (final item in raw) {
      final id = item.toString().trim();
      if (id.isEmpty || !decisionIds.contains(id)) {
        valid = false;
        issues.add(
          'L4N learningSignals references unknown recovery Decision Node ' +
              id +
              '.',
        );
      } else if (!seen.add(id)) {
        valid = false;
        issues.add(
          'L4N learningSignals repeats recovery Decision Node ' + id + '.',
        );
      }
    }
    return valid;
  }

  bool _validatePrivacyBoundary(
    LabPackage package,
    List<String> issues,
  ) {
    final raw = package.learningSignals['privacy'];
    if (raw == null) return true;
    final valid = raw.toString() == 'sanitized_decision_evidence_only';
    if (!valid) {
      issues.add(
        'L4N Learning Twin privacy must remain sanitized_decision_evidence_only.',
      );
    }
    return valid;
  }

  bool _sanitizedEvidence(Map<String, Object?> json) {
    const forbidden = <String>{
      'userId',
      'stateBefore',
      'stateAfter',
      'stateDelta',
      'stateValues',
      'evidenceUnlocked',
      'appliedConsequenceKeys',
    };
    return forbidden.every((key) => !json.containsKey(key));
  }

  String _routeEvidenceFingerprint({
    required LabExhaustiveRouteTrace route,
    required LabSession session,
    required LabDebrief debrief,
    required List<LabLearningEvidence> evidence,
  }) {
    final decisions = debrief.decisions
        .map(
          (item) => <String, Object?>{
            'index': item.index,
            'nodeId': item.nodeId,
            'optionId': item.optionId,
            'quality': item.quality.name,
            'consequenceId': item.consequenceId,
            'gateId': item.gateId,
            'critical': item.critical,
            'recovery': item.recovery,
            'competencyEvidence': item.competencyEvidence.toList()..sort(),
            'mistakeDnaTags': item.mistakeDnaTags.toList()..sort(),
            'sources': item.sources,
          },
        )
        .toList(growable: false);
    final alternate = debrief.alternateTimelines
        .map(
          (item) => <String, Object?>{
            'nodeId': item.nodeId,
            'originalOptionId': item.originalOptionId,
            'alternateOptionId': item.alternateOptionId,
            'consequenceId': item.consequenceId,
            'gateId': item.gateId,
            'nextNodeId': item.nextNodeId,
            'endingId': item.endingId,
          },
        )
        .toList(growable: false);
    final learning = evidence
        .map((item) => item.toSanitizedJson())
        .toList(growable: false);

    return jsonEncode(<String, Object?>{
      'route': route.fingerprint,
      'session': session.toJson(),
      'debrief': <String, Object?>{
        'completed': debrief.completed,
        'endingId': debrief.endingId,
        'causalChain': debrief.causalChain,
        'criticalDecisionIndexes': debrief.criticalDecisionIndexes,
        'recoveryDecisionIndexes': debrief.recoveryDecisionIndexes,
        'competencyEvidence': debrief.competencyEvidence.toList()..sort(),
        'mistakeDnaSignals': debrief.mistakeDnaSignals.toList()..sort(),
        'sources': debrief.sources,
        'decisions': decisions,
        'alternateTimelines': alternate,
      },
      'learningEvidence': learning,
    });
  }

  bool _stringListEquals(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}

class _PublishEvidenceInspection {
  const _PublishEvidenceInspection({
    required this.debriefCount,
    required this.decisionEventCount,
    required this.learningEvidenceCount,
    required this.routeEvidenceValid,
    required this.issues,
    required this.fingerprint,
  });

  final int debriefCount;
  final int decisionEventCount;
  final int learningEvidenceCount;
  final bool routeEvidenceValid;
  final List<String> issues;
  final String fingerprint;
}
