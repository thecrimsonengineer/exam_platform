import 'dart:convert';

import 'lab_contracts.dart';
import 'lab_session.dart';

enum LabEvidenceCompletion { partial, completed }

class LabLearningEvidence {
  LabLearningEvidence({
    required this.eventId,
    required this.labId,
    required this.labVersionId,
    required this.nodeId,
    required this.optionId,
    required this.quality,
    required Iterable<String> competencyEvidence,
    required Iterable<String> mistakeDnaTags,
    required this.responseTimeMs,
    required this.recoveryEvidence,
    required this.completion,
    required this.occurredAt,
    this.confidence,
  }) : competencyEvidence = Set<String>.unmodifiable(competencyEvidence),
       mistakeDnaTags = Set<String>.unmodifiable(mistakeDnaTags);

  final String eventId;
  final String labId;
  final String labVersionId;
  final String nodeId;
  final String optionId;
  final LabDecisionQuality quality;
  final Set<String> competencyEvidence;
  final Set<String> mistakeDnaTags;
  final double? confidence;
  final int responseTimeMs;
  final bool recoveryEvidence;
  final LabEvidenceCompletion completion;
  final DateTime occurredAt;

  Map<String, Object?> toSanitizedJson() => <String, Object?>{
    'eventId': eventId,
    'labId': labId,
    'labVersionId': labVersionId,
    'nodeId': nodeId,
    'optionId': optionId,
    'quality': quality.name,
    'competencyEvidence': competencyEvidence.toList()..sort(),
    'mistakeDnaTags': mistakeDnaTags.toList()..sort(),
    if (confidence != null) 'confidence': confidence,
    'responseTimeMs': responseTimeMs,
    'recoveryEvidence': recoveryEvidence,
    'completion': completion.name,
    'occurredAt': occurredAt.toUtc().toIso8601String(),
  };
}

abstract interface class LabLearningEvidenceSink {
  Future<void> append(LabLearningEvidence evidence);
}

class InMemoryLabLearningEvidenceSink implements LabLearningEvidenceSink {
  final List<LabLearningEvidence> _events = <LabLearningEvidence>[];

  List<LabLearningEvidence> get events =>
      List<LabLearningEvidence>.unmodifiable(_events);

  @override
  Future<void> append(LabLearningEvidence evidence) async {
    if (_events.any((item) => item.eventId == evidence.eventId)) {
      return;
    }
    _events.add(evidence);
  }
}

class LabLearningTwinEvidenceBridge {
  const LabLearningTwinEvidenceBridge();

  List<LabLearningEvidence> buildEvidence({
    required LabPackage package,
    required LabSession session,
  }) {
    if (session.labId != package.metadata.id ||
        session.labVersionId != package.metadata.versionId) {
      throw const LabSessionException(
        'Learning evidence requires the session pinned LAB version.',
      );
    }

    final completion = session.status == LabSessionStatus.completed
        ? LabEvidenceCompletion.completed
        : LabEvidenceCompletion.partial;

    return List<LabLearningEvidence>.unmodifiable(
      session.decisionHistory.map(
        (event) => buildEvidenceForEvent(
          package: package,
          session: session,
          event: event,
          completion: completion,
        ),
      ),
    );
  }

  LabLearningEvidence buildEvidenceForEvent({
    required LabPackage package,
    required LabSession session,
    required LabDecisionEvent event,
    required LabEvidenceCompletion completion,
  }) {
    if (session.labId != package.metadata.id ||
        session.labVersionId != package.metadata.versionId) {
      throw const LabSessionException(
        'Learning evidence requires the session pinned LAB version.',
      );
    }
    LabDecisionEvent? committedEvent;
    for (final candidate in session.decisionHistory) {
      if (candidate.eventId == event.eventId) {
        committedEvent = candidate;
        break;
      }
    }
    if (committedEvent == null) {
      throw const LabSessionException(
        'Learning evidence event must belong to the supplied LAB session.',
      );
    }
    if (jsonEncode(committedEvent.toJson()) != jsonEncode(event.toJson())) {
      throw const LabSessionException(
        'Learning evidence event must exactly match the committed Decision Event.',
      );
    }

    final node = _decisionNode(package, event.nodeId);
    final option = node.requireOption(event.selectedOptionId);
    final recoveryNodes = _stringSet(
      package.learningSignals['recoveryDecisionNodeIds'],
    );

    return LabLearningEvidence(
      eventId: event.eventId,
      labId: session.labId,
      labVersionId: session.labVersionId,
      nodeId: event.nodeId,
      optionId: option.id,
      quality: option.quality,
      competencyEvidence: option.competencyEvidence,
      mistakeDnaTags: option.mistakeTags,
      confidence: event.confidence,
      responseTimeMs: event.responseTimeMs,
      recoveryEvidence: recoveryNodes.contains(event.nodeId),
      completion: completion,
      occurredAt: event.timestamp,
    );
  }

  Future<List<LabLearningEvidence>> emit({
    required LabPackage package,
    required LabSession session,
    required LabLearningEvidenceSink sink,
  }) async {
    final evidence = buildEvidence(package: package, session: session);
    for (final item in evidence) {
      await sink.append(item);
    }
    return evidence;
  }

  LabDecisionNode _decisionNode(LabPackage package, String nodeId) {
    for (final node in package.nodes) {
      if (node.id == nodeId && node is LabDecisionNode) {
        return node;
      }
    }
    throw LabContractException(
      'Learning evidence references unknown Decision Node ' + nodeId + '.',
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
