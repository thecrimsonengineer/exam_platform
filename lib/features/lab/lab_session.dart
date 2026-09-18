import 'dart:convert';

import 'lab_contracts.dart';
import 'lab_runtime.dart';
import 'lab_state.dart';
import 'lab_story_gate.dart';

enum LabSessionStatus { active, interrupted, completed }

class LabSessionException implements Exception {
  const LabSessionException(this.message);

  final String message;

  @override
  String toString() => 'LabSessionException: $message';
}

class LabStaleSessionWriteException extends LabSessionException {
  const LabStaleSessionWriteException(super.message);
}

class LabDecisionEvent {
  LabDecisionEvent({
    required this.eventId,
    required this.nodeId,
    required this.selectedOptionId,
    required this.responseTimeMs,
    required this.stateBefore,
    required this.stateDelta,
    required this.stateAfter,
    required this.consequenceId,
    required this.gateTriggered,
    required this.nextNodeId,
    required this.simulatedMinutes,
    required this.timestamp,
    this.confidence,
    this.endingId,
  }) {
    if (responseTimeMs < 0) {
      throw const LabSessionException('Response time cannot be negative.');
    }
    if (confidence != null && (confidence! < 0 || confidence! > 1)) {
      throw const LabSessionException(
        'Confidence must be between zero and one.',
      );
    }
  }

  factory LabDecisionEvent.fromJson(Map<String, Object?> json) {
    Map<String, Object?> objectMap(Object? value) =>
        value is Map ? value.cast<String, Object?>() : <String, Object?>{};

    return LabDecisionEvent(
      eventId: json['eventId']?.toString() ?? '',
      nodeId: json['nodeId']?.toString() ?? '',
      selectedOptionId: json['selectedOptionId']?.toString() ?? '',
      confidence: (json['confidence'] as num?)?.toDouble(),
      responseTimeMs: (json['responseTimeMs'] as num?)?.toInt() ?? 0,
      stateBefore: objectMap(json['stateBefore']),
      stateDelta: objectMap(json['stateDelta']),
      stateAfter: objectMap(json['stateAfter']),
      consequenceId: json['consequenceId']?.toString() ?? '',
      gateTriggered: json['gateTriggered']?.toString() ?? '',
      nextNodeId: json['nextNodeId']?.toString(),
      endingId: json['endingId']?.toString(),
      simulatedMinutes: (json['simulatedMinutes'] as num?)?.toInt() ?? 0,
      timestamp: DateTime.parse(json['timestamp']?.toString() ?? ''),
    );
  }

  final String eventId;
  final String nodeId;
  final String selectedOptionId;
  final double? confidence;
  final int responseTimeMs;
  final Map<String, Object?> stateBefore;
  final Map<String, Object?> stateDelta;
  final Map<String, Object?> stateAfter;
  final String consequenceId;
  final String gateTriggered;
  final String? nextNodeId;
  final String? endingId;
  final int simulatedMinutes;
  final DateTime timestamp;

  Map<String, Object?> toJson() => <String, Object?>{
        'eventId': eventId,
        'nodeId': nodeId,
        'selectedOptionId': selectedOptionId,
        if (confidence != null) 'confidence': confidence,
        'responseTimeMs': responseTimeMs,
        'stateBefore': stateBefore,
        'stateDelta': stateDelta,
        'stateAfter': stateAfter,
        'consequenceId': consequenceId,
        'gateTriggered': gateTriggered,
        'nextNodeId': nextNodeId,
        'endingId': endingId,
        'simulatedMinutes': simulatedMinutes,
        'timestamp': timestamp.toUtc().toIso8601String(),
      };
}

class LabSession {
  LabSession({
    required this.sessionId,
    required this.userId,
    required this.labId,
    required this.labVersionId,
    required this.mode,
    required this.startedAt,
    required this.currentNodeId,
    required Map<String, Object?> stateValues,
    required Iterable<String> evidenceUnlocked,
    required this.simulatedMinutes,
    required this.status,
    required Iterable<LabDecisionEvent> decisionHistory,
    required Iterable<String> appliedConsequenceKeys,
    this.endingId,
    this.revision = 0,
  })  : stateValues = Map<String, Object?>.unmodifiable(stateValues),
        evidenceUnlocked = Set<String>.unmodifiable(evidenceUnlocked),
        decisionHistory = List<LabDecisionEvent>.unmodifiable(decisionHistory),
        appliedConsequenceKeys =
            Set<String>.unmodifiable(appliedConsequenceKeys) {
    if (sessionId.trim().isEmpty ||
        userId.trim().isEmpty ||
        labId.trim().isEmpty ||
        labVersionId.trim().isEmpty) {
      throw const LabSessionException(
        'Session, user, LAB and version IDs are required.',
      );
    }
    if (simulatedMinutes < 0 || revision < 0) {
      throw const LabSessionException(
        'Session time and revision cannot be negative.',
      );
    }
    if (status == LabSessionStatus.completed && endingId == null) {
      throw const LabSessionException(
        'Completed session requires an ending ID.',
      );
    }
  }

  factory LabSession.fromJson(Map<String, Object?> json) {
    final state = json['stateValues'];
    final evidence = json['evidenceUnlocked'];
    final history = json['decisionHistory'];
    final applied = json['appliedConsequenceKeys'];

    if (state is! Map || history is! Iterable) {
      throw const LabSessionException('Invalid LAB session checkpoint.');
    }

    return LabSession(
      sessionId: json['sessionId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      labId: json['labId']?.toString() ?? '',
      labVersionId: json['labVersionId']?.toString() ?? '',
      mode: parseLabMode(json['mode']),
      startedAt: DateTime.parse(json['startedAt']?.toString() ?? ''),
      currentNodeId: json['currentNodeId']?.toString() ?? '',
      stateValues: state.cast<String, Object?>(),
      evidenceUnlocked: evidence is Iterable
          ? evidence.map((item) => item.toString())
          : const <String>[],
      simulatedMinutes: (json['simulatedMinutes'] as num?)?.toInt() ?? 0,
      status: LabSessionStatus.values.firstWhere(
        (item) => item.name == json['status']?.toString(),
        orElse: () => throw const LabSessionException(
          'Unknown LAB session status.',
        ),
      ),
      decisionHistory: history.map((item) {
        if (item is! Map) {
          throw const LabSessionException('Invalid decision event.');
        }
        return LabDecisionEvent.fromJson(item.cast<String, Object?>());
      }),
      appliedConsequenceKeys: applied is Iterable
          ? applied.map((item) => item.toString())
          : const <String>[],
      endingId: json['endingId']?.toString(),
      revision: (json['revision'] as num?)?.toInt() ?? 0,
    );
  }

  final String sessionId;
  final String userId;
  final String labId;
  final String labVersionId;
  final LabMode mode;
  final DateTime startedAt;
  final String currentNodeId;
  final Map<String, Object?> stateValues;
  final Set<String> evidenceUnlocked;
  final int simulatedMinutes;
  final LabSessionStatus status;
  final List<LabDecisionEvent> decisionHistory;
  final Set<String> appliedConsequenceKeys;
  final String? endingId;
  final int revision;

  Map<String, Object?> toJson() => <String, Object?>{
        'sessionId': sessionId,
        'userId': userId,
        'labId': labId,
        'labVersionId': labVersionId,
        'mode': mode.name.toUpperCase(),
        'startedAt': startedAt.toUtc().toIso8601String(),
        'currentNodeId': currentNodeId,
        'stateValues': stateValues,
        'evidenceUnlocked': evidenceUnlocked.toList()..sort(),
        'simulatedMinutes': simulatedMinutes,
        'status': status.name,
        'decisionHistory':
            decisionHistory.map((event) => event.toJson()).toList(),
        'appliedConsequenceKeys': appliedConsequenceKeys.toList()..sort(),
        'endingId': endingId,
        'revision': revision,
      };

  String encodeCheckpoint() => jsonEncode(toJson());

  LabSession copyWith({
    String? currentNodeId,
    Map<String, Object?>? stateValues,
    Iterable<String>? evidenceUnlocked,
    int? simulatedMinutes,
    LabSessionStatus? status,
    Iterable<LabDecisionEvent>? decisionHistory,
    Iterable<String>? appliedConsequenceKeys,
    String? endingId,
    bool clearEnding = false,
    int? revision,
  }) {
    return LabSession(
      sessionId: sessionId,
      userId: userId,
      labId: labId,
      labVersionId: labVersionId,
      mode: mode,
      startedAt: startedAt,
      currentNodeId: currentNodeId ?? this.currentNodeId,
      stateValues: stateValues ?? this.stateValues,
      evidenceUnlocked: evidenceUnlocked ?? this.evidenceUnlocked,
      simulatedMinutes: simulatedMinutes ?? this.simulatedMinutes,
      status: status ?? this.status,
      decisionHistory: decisionHistory ?? this.decisionHistory,
      appliedConsequenceKeys:
          appliedConsequenceKeys ?? this.appliedConsequenceKeys,
      endingId: clearEnding ? null : (endingId ?? this.endingId),
      revision: revision ?? this.revision,
    );
  }

  LabDecisionEvent? eventForNode(String nodeId) {
    for (final event in decisionHistory) {
      if (event.nodeId == nodeId) return event;
    }
    return null;
  }
}

abstract class LabSessionStore {
  Future<LabSession?> load(String sessionId);

  Future<LabSession> save(
    LabSession session, {
    required int? expectedRevision,
  });
}

class InMemoryLabSessionStore implements LabSessionStore {
  final Map<String, LabSession> _sessions = <String, LabSession>{};

  @override
  Future<LabSession?> load(String sessionId) async => _sessions[sessionId];

  @override
  Future<LabSession> save(
    LabSession session, {
    required int? expectedRevision,
  }) async {
    final current = _sessions[session.sessionId];

    if (current == null) {
      if (expectedRevision != null) {
        throw const LabStaleSessionWriteException(
          'Cannot update a missing LAB session.',
        );
      }
      _sessions[session.sessionId] = session;
      return session;
    }

    if (expectedRevision == null || current.revision != expectedRevision) {
      if (current.revision == session.revision &&
          current.currentNodeId == session.currentNodeId &&
          current.decisionHistory.length == session.decisionHistory.length) {
        return current;
      }
      throw LabStaleSessionWriteException(
        'Stale LAB session write. Expected revision ' +
            current.revision.toString() +
            '.',
      );
    }

    if (session.revision != expectedRevision + 1) {
      throw const LabStaleSessionWriteException(
        'LAB session revision must advance exactly once.',
      );
    }

    _sessions[session.sessionId] = session;
    return session;
  }
}

class LabSessionEngine {
  const LabSessionEngine({
    required this.store,
    this.runtime = const LabDeterministicRuntime(),
  });

  final LabSessionStore store;
  final LabDeterministicRuntime runtime;

  Future<LabSession> startAttempt({
    required LabPackage package,
    required String sessionId,
    required String userId,
    required LabMode mode,
    DateTime? startedAt,
  }) async {
    if (!package.metadata.supportedModes.contains(mode)) {
      throw const LabSessionException(
        'Requested LAB mode is not supported by this version.',
      );
    }

    final session = LabSession(
      sessionId: sessionId,
      userId: userId,
      labId: package.metadata.id,
      labVersionId: package.metadata.versionId,
      mode: mode,
      startedAt: startedAt ?? DateTime.now().toUtc(),
      currentNodeId: package.metadata.startingNodeId,
      stateValues: package.stateRegistry.normalizeStartingState(
        package.metadata.startingState,
      ),
      evidenceUnlocked: const <String>[],
      simulatedMinutes: 0,
      status: LabSessionStatus.active,
      decisionHistory: const <LabDecisionEvent>[],
      appliedConsequenceKeys: const <String>[],
    );

    return store.save(session, expectedRevision: null);
  }

  Future<LabSession> resume({
    required LabPackage package,
    required String sessionId,
  }) async {
    final session = await store.load(sessionId);
    if (session == null) {
      throw const LabSessionException('LAB session checkpoint was not found.');
    }
    _requirePinnedVersion(session, package);

    package.stateRegistry.normalizeStartingState(session.stateValues);

    if (session.status == LabSessionStatus.completed) {
      return session;
    }

    if (session.status == LabSessionStatus.active) {
      return session;
    }

    final resumed = session.copyWith(
      status: LabSessionStatus.active,
      revision: session.revision + 1,
    );
    return store.save(resumed, expectedRevision: session.revision);
  }

  Future<LabSession> restoreCheckpoint({
    required LabPackage package,
    required String checkpoint,
  }) async {
    final decoded = jsonDecode(checkpoint);
    if (decoded is! Map) {
      throw const LabSessionException('Invalid LAB checkpoint JSON.');
    }
    final session = LabSession.fromJson(decoded.cast<String, Object?>());
    _requirePinnedVersion(session, package);
    package.stateRegistry.normalizeStartingState(session.stateValues);
    return session;
  }

  Future<LabSession> interrupt(LabSession session) async {
    if (session.status == LabSessionStatus.completed) {
      return session;
    }
    final interrupted = session.copyWith(
      status: LabSessionStatus.interrupted,
      revision: session.revision + 1,
    );
    return store.save(interrupted, expectedRevision: session.revision);
  }

  Future<LabSession> replay({
    required LabPackage package,
    required LabSession prior,
    required String newSessionId,
    DateTime? startedAt,
  }) {
    _requirePinnedVersion(prior, package);
    return startAttempt(
      package: package,
      sessionId: newSessionId,
      userId: prior.userId,
      mode: prior.mode,
      startedAt: startedAt,
    );
  }

  Future<LabSession> commitDecision({
    required LabPackage package,
    required LabSession session,
    required String optionId,
    required int responseTimeMs,
    double? confidence,
    DateTime? timestamp,
  }) async {
    _requirePinnedVersion(session, package);

    if (session.status != LabSessionStatus.active) {
      throw const LabSessionException(
        'Only an active LAB session can commit a decision.',
      );
    }

    final existing = session.eventForNode(session.currentNodeId);
    if (existing != null) {
      if (existing.selectedOptionId == optionId) {
        return session;
      }
      throw const LabSessionException(
        'Committed LAB decisions are irreversible.',
      );
    }

    final node = _requireDecisionNode(package, session.currentNodeId);
    node.requireOption(optionId);

    final gates = package.gates.map(LabStoryGate.fromJson).toList();
    final consequences = <String, LabConsequence>{
      for (final consequence in package.consequences)
        consequence.id: consequence,
    };

    final labState = LabState.restore(
      registry: package.stateRegistry,
      values: session.stateValues,
      evidenceUnlocked: session.evidenceUnlocked,
      appliedConsequenceKeys: session.appliedConsequenceKeys,
      simulatedMinutes: session.simulatedMinutes,
    );

    final applicationKey =
        session.sessionId + ':' + session.currentNodeId;
    final resolution = runtime.resolveDecision(
      state: labState,
      node: node,
      optionId: optionId,
      applicationKey: applicationKey,
      gates: gates,
      consequenceRegistry: consequences,
    );

    final gate = resolution.gate;
    if (gate == null) {
      throw const LabSessionException(
        'Committed decision did not resolve a Story Gate.',
      );
    }

    if (gate.targetNodeId == null && gate.endingId == null) {
      throw const LabSessionException(
        'Resolved Story Gate has no next node or ending.',
      );
    }

    if (gate.targetNodeId != null &&
        !_nodeIds(package).contains(gate.targetNodeId)) {
      throw const LabSessionException(
        'Resolved Story Gate points to an unknown node.',
      );
    }

    final delta = <String, Object?>{
      for (final entry in resolution.consequence.delta.entries)
        entry.key: <String, Object?>{
          'before': entry.value.before,
          'after': entry.value.after,
        },
    };

    final event = LabDecisionEvent(
      eventId: session.sessionId +
          ':event:' +
          (session.decisionHistory.length + 1).toString(),
      nodeId: session.currentNodeId,
      selectedOptionId: optionId,
      confidence: confidence,
      responseTimeMs: responseTimeMs,
      stateBefore: resolution.consequence.before.values,
      stateDelta: delta,
      stateAfter: resolution.consequence.after.values,
      consequenceId: resolution.consequence.consequenceId,
      gateTriggered: gate.gateId,
      nextNodeId: gate.targetNodeId,
      endingId: gate.endingId,
      simulatedMinutes: resolution.state.simulatedMinutes,
      timestamp: timestamp ?? DateTime.now().toUtc(),
    );

    final nextStatus = gate.endingId == null
        ? LabSessionStatus.active
        : LabSessionStatus.completed;
    final nextNode = gate.targetNodeId ?? session.currentNodeId;

    final updated = session.copyWith(
      currentNodeId: nextNode,
      stateValues: resolution.state.values,
      evidenceUnlocked: resolution.state.evidenceUnlocked,
      simulatedMinutes: resolution.state.simulatedMinutes,
      status: nextStatus,
      decisionHistory: <LabDecisionEvent>[
        ...session.decisionHistory,
        event,
      ],
      appliedConsequenceKeys: resolution.state.appliedConsequenceKeys,
      endingId: gate.endingId,
      revision: session.revision + 1,
    );

    return store.save(updated, expectedRevision: session.revision);
  }

  LabDecisionNode _requireDecisionNode(
    LabPackage package,
    String nodeId,
  ) {
    for (final node in package.nodes) {
      if (node.id == nodeId) {
        if (node is LabDecisionNode) return node;
        throw const LabSessionException(
          'Current LAB node is not a Decision Node.',
        );
      }
    }
    throw const LabSessionException('Current LAB node does not exist.');
  }

  Set<String> _nodeIds(LabPackage package) =>
      package.nodes.map((node) => node.id).toSet();

  void _requirePinnedVersion(LabSession session, LabPackage package) {
    if (session.labId != package.metadata.id ||
        session.labVersionId != package.metadata.versionId) {
      throw const LabSessionException(
        'LAB session is pinned to a different immutable version.',
      );
    }
  }
}
