import 'lab_contracts.dart';
import 'lab_runtime.dart';
import 'lab_session.dart';
import 'lab_state.dart';
import 'lab_story_gate.dart';

class LabDebriefDecision {
  const LabDebriefDecision({
    required this.index,
    required this.nodeId,
    required this.optionId,
    required this.quality,
    required this.consequenceId,
    required this.gateId,
    required this.responseTimeMs,
    required this.timestamp,
    required this.critical,
    required this.recovery,
    required this.competencyEvidence,
    required this.mistakeDnaTags,
    required this.sources,
  });

  final int index;
  final String nodeId;
  final String optionId;
  final LabDecisionQuality quality;
  final String consequenceId;
  final String gateId;
  final int responseTimeMs;
  final DateTime timestamp;
  final bool critical;
  final bool recovery;
  final Set<String> competencyEvidence;
  final Set<String> mistakeDnaTags;
  final List<String> sources;
}

class LabAlternateTimeline {
  const LabAlternateTimeline({
    required this.nodeId,
    required this.originalOptionId,
    required this.alternateOptionId,
    required this.consequenceId,
    required this.gateId,
    this.nextNodeId,
    this.endingId,
  });

  final String nodeId;
  final String originalOptionId;
  final String alternateOptionId;
  final String consequenceId;
  final String gateId;
  final String? nextNodeId;
  final String? endingId;
}

class LabDebrief {
  const LabDebrief({
    required this.labId,
    required this.labVersionId,
    required this.completed,
    required this.decisions,
    required this.causalChain,
    required this.criticalDecisionIndexes,
    required this.recoveryDecisionIndexes,
    required this.competencyEvidence,
    required this.mistakeDnaSignals,
    required this.sources,
    required this.alternateTimelines,
    this.endingId,
  });

  final String labId;
  final String labVersionId;
  final bool completed;
  final List<LabDebriefDecision> decisions;
  final List<String> causalChain;
  final List<int> criticalDecisionIndexes;
  final List<int> recoveryDecisionIndexes;
  final Set<String> competencyEvidence;
  final Set<String> mistakeDnaSignals;
  final List<String> sources;
  final List<LabAlternateTimeline> alternateTimelines;
  final String? endingId;
}

class LabDebriefEngine {
  const LabDebriefEngine({
    this.runtime = const LabDeterministicRuntime(),
  });

  final LabDeterministicRuntime runtime;

  LabDebrief reconstruct({
    required LabPackage package,
    required LabSession session,
  }) {
    if (session.labId != package.metadata.id ||
        session.labVersionId != package.metadata.versionId) {
      throw const LabSessionException(
        'Debrief requires the session pinned LAB version.',
      );
    }

    final recoveryNodes = _stringSet(
      package.learningSignals['recoveryDecisionNodeIds'],
    );
    final decisions = <LabDebriefDecision>[];
    final causal = <String>[];
    final critical = <int>[];
    final recovery = <int>[];
    final competencies = <String>{};
    final mistakes = <String>{};

    for (var index = 0; index < session.decisionHistory.length; index++) {
      final event = session.decisionHistory[index];
      final node = _decisionNode(package, event.nodeId);
      final option = node.requireOption(event.selectedOptionId);
      final isCritical = option.quality == LabDecisionQuality.critical;
      final isRecovery = recoveryNodes.contains(event.nodeId);

      if (isCritical) critical.add(index);
      if (isRecovery) recovery.add(index);
      competencies.addAll(option.competencyEvidence);
      mistakes.addAll(option.mistakeTags);

      decisions.add(
        LabDebriefDecision(
          index: index,
          nodeId: node.id,
          optionId: option.id,
          quality: option.quality,
          consequenceId: event.consequenceId,
          gateId: event.gateTriggered,
          responseTimeMs: event.responseTimeMs,
          timestamp: event.timestamp,
          critical: isCritical,
          recovery: isRecovery,
          competencyEvidence:
              Set<String>.unmodifiable(option.competencyEvidence),
          mistakeDnaTags: Set<String>.unmodifiable(option.mistakeTags),
          sources: List<String>.unmodifiable(package.metadata.sources),
        ),
      );

      causal.add(
        node.id +
            ' -> ' +
            option.id +
            ' -> ' +
            event.consequenceId +
            ' -> ' +
            event.gateTriggered,
      );
    }

    return LabDebrief(
      labId: package.metadata.id,
      labVersionId: package.metadata.versionId,
      completed: session.status == LabSessionStatus.completed,
      decisions: List<LabDebriefDecision>.unmodifiable(decisions),
      causalChain: List<String>.unmodifiable(causal),
      criticalDecisionIndexes: List<int>.unmodifiable(critical),
      recoveryDecisionIndexes: List<int>.unmodifiable(recovery),
      competencyEvidence: Set<String>.unmodifiable(competencies),
      mistakeDnaSignals: Set<String>.unmodifiable(mistakes),
      sources: List<String>.unmodifiable(package.metadata.sources),
      alternateTimelines: List<LabAlternateTimeline>.unmodifiable(
        _alternateTimelines(package, session),
      ),
      endingId: session.endingId,
    );
  }

  List<LabAlternateTimeline> _alternateTimelines(
    LabPackage package,
    LabSession session,
  ) {
    final authored = package.debrief['alternateTimelineOptions'];
    if (authored is! Iterable) return const <LabAlternateTimeline>[];

    final gates = package.gates.map(LabStoryGate.fromJson).toList();
    final consequences = <String, LabConsequence>{
      for (final consequence in package.consequences)
        consequence.id: consequence,
    };
    final output = <LabAlternateTimeline>[];

    for (final item in authored) {
      if (item is! Map) continue;
      final map = item.cast<String, Object?>();
      final nodeId = map['nodeId']?.toString() ?? '';
      final alternateOptionId = map['alternateOptionId']?.toString() ?? '';
      final event = _eventForNode(session, nodeId);
      if (event == null || alternateOptionId.isEmpty) continue;

      final node = _decisionNode(package, nodeId);
      node.requireOption(alternateOptionId);

      final state = LabState.restore(
        registry: package.stateRegistry,
        values: event.stateBefore,
        simulatedMinutes: _simulatedBefore(session, event),
      );
      final resolution = runtime.resolveDecision(
        state: state,
        node: node,
        optionId: alternateOptionId,
        applicationKey:
            'debrief:' + session.sessionId + ':' + nodeId + ':' + alternateOptionId,
        gates: gates,
        consequenceRegistry: consequences,
      );
      final gate = resolution.gate;
      if (gate == null) continue;

      output.add(
        LabAlternateTimeline(
          nodeId: nodeId,
          originalOptionId: event.selectedOptionId,
          alternateOptionId: alternateOptionId,
          consequenceId: resolution.consequence.consequenceId,
          gateId: gate.gateId,
          nextNodeId: gate.targetNodeId,
          endingId: gate.endingId,
        ),
      );
    }
    return output;
  }

  int _simulatedBefore(LabSession session, LabDecisionEvent event) {
    final index = session.decisionHistory.indexOf(event);
    if (index <= 0) return 0;
    return session.decisionHistory[index - 1].simulatedMinutes;
  }

  LabDecisionEvent? _eventForNode(LabSession session, String nodeId) {
    for (final event in session.decisionHistory) {
      if (event.nodeId == nodeId) return event;
    }
    return null;
  }

  LabDecisionNode _decisionNode(LabPackage package, String nodeId) {
    for (final node in package.nodes) {
      if (node.id == nodeId && node is LabDecisionNode) {
        return node;
      }
    }
    throw LabContractException(
      'Debrief references unknown Decision Node ' + nodeId + '.',
    );
  }

  Set<String> _stringSet(Object? raw) {
    if (raw is! Iterable) return const <String>{};
    return raw
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toSet();
  }
}
