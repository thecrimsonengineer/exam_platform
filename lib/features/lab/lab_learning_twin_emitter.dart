import 'dart:convert';

import 'lab_contracts.dart';
import 'lab_learning_twin_bridge.dart';
import 'lab_session.dart';

class LabLearningEvidenceEmissionResult {
  const LabLearningEvidenceEmissionResult({
    required this.attemptedEventIds,
    required this.deliveredEventIds,
    required this.failedEventIds,
    required this.issues,
  });

  final List<String> attemptedEventIds;
  final List<String> deliveredEventIds;
  final List<String> failedEventIds;
  final List<String> issues;

  bool get transitionValid =>
      !issues.any((issue) => issue.startsWith('L4P transition'));
  bool get allDelivered =>
      transitionValid &&
      issues.isEmpty &&
      attemptedEventIds.length == deliveredEventIds.length &&
      failedEventIds.isEmpty;
}

class LabIncrementalLearningTwinEvidenceEmitter {
  const LabIncrementalLearningTwinEvidenceEmitter({
    this.bridge = const LabLearningTwinEvidenceBridge(),
  });

  final LabLearningTwinEvidenceBridge bridge;

  Future<LabLearningEvidenceEmissionResult> emitNewlyPersisted({
    required LabPackage package,
    required LabSession before,
    required LabSession after,
    required LabLearningEvidenceSink sink,
  }) async {
    final transitionIssues = _transitionIssues(
      package: package,
      before: before,
      after: after,
    );
    if (transitionIssues.isNotEmpty) {
      return LabLearningEvidenceEmissionResult(
        attemptedEventIds: const <String>[],
        deliveredEventIds: const <String>[],
        failedEventIds: const <String>[],
        issues: List<String>.unmodifiable(transitionIssues),
      );
    }

    final newEvents = after.decisionHistory
        .skip(before.decisionHistory.length)
        .toList(growable: false);
    final attempted = <String>[];
    final delivered = <String>[];
    final failed = <String>[];
    final issues = <String>[];
    final beforeSnapshot = jsonEncode(before.toJson());
    final afterSnapshot = jsonEncode(after.toJson());

    for (final event in newEvents) {
      attempted.add(event.eventId);
      final completion = event.endingId == null
          ? LabEvidenceCompletion.partial
          : LabEvidenceCompletion.completed;

      try {
        final evidence = bridge.buildEvidenceForEvent(
          package: package,
          session: after,
          event: event,
          completion: completion,
        );
        await sink.append(evidence);
        delivered.add(event.eventId);
      } catch (error) {
        failed.add(event.eventId);
        issues.add(
          'L4P evidence sink failed for ' +
              event.eventId +
              ': ' +
              error.toString(),
        );
      }
    }

    if (jsonEncode(before.toJson()) != beforeSnapshot ||
        jsonEncode(after.toJson()) != afterSnapshot) {
      issues.add(
        'L4P evidence emission changed LAB session state, which is forbidden.',
      );
    }

    return LabLearningEvidenceEmissionResult(
      attemptedEventIds: List<String>.unmodifiable(attempted),
      deliveredEventIds: List<String>.unmodifiable(delivered),
      failedEventIds: List<String>.unmodifiable(failed),
      issues: List<String>.unmodifiable(issues),
    );
  }

  List<String> _transitionIssues({
    required LabPackage package,
    required LabSession before,
    required LabSession after,
  }) {
    final issues = <String>[];

    if (before.sessionId != after.sessionId ||
        before.userId != after.userId ||
        before.labId != after.labId ||
        before.labVersionId != after.labVersionId ||
        before.mode != after.mode ||
        before.startedAt != after.startedAt) {
      issues.add(
        'L4P transition must remain inside one pinned LAB session.',
      );
      return issues;
    }

    if (after.labId != package.metadata.id ||
        after.labVersionId != package.metadata.versionId) {
      issues.add(
        'L4P transition package does not match the pinned LAB session version.',
      );
      return issues;
    }

    if (after.revision < before.revision) {
      issues.add('L4P transition revision moved backwards.');
    }

    if (after.decisionHistory.length < before.decisionHistory.length) {
      issues.add('L4P transition removed committed Decision Events.');
      return issues;
    }

    for (var index = 0; index < before.decisionHistory.length; index++) {
      final oldEvent = jsonEncode(before.decisionHistory[index].toJson());
      final newEvent = jsonEncode(after.decisionHistory[index].toJson());
      if (oldEvent != newEvent) {
        issues.add(
          'L4P transition rewrote committed Decision Event at index ' +
              index.toString() +
              '.',
        );
        return issues;
      }
    }

    final appended = after.decisionHistory
        .skip(before.decisionHistory.length)
        .toList(growable: false);
    if (appended.isEmpty) {
      return issues;
    }
    if (after.revision <= before.revision) {
      issues.add(
        'L4P transition appended Decision Events without advancing revision.',
      );
      return issues;
    }

    final endingEvents = appended.where((event) => event.endingId != null).toList();
    if (endingEvents.length > 1 ||
        (endingEvents.isNotEmpty && endingEvents.last != appended.last)) {
      issues.add(
        'L4P transition contains an invalid completion-event sequence.',
      );
    }

    if (after.status == LabSessionStatus.completed) {
      if (appended.last.endingId == null ||
          appended.last.endingId != after.endingId) {
        issues.add(
          'L4P transition completed without a matching final Decision Event ending.',
        );
      }
    } else if (endingEvents.isNotEmpty) {
      issues.add(
        'L4P transition contains completion evidence for a non-completed session.',
      );
    }

    return issues;
  }
}
