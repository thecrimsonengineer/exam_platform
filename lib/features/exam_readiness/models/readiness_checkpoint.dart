import 'exam_preparation_phase.dart';

enum ReadinessCheckpointStatus { upcoming, due }

class ReadinessCheckpoint {
  const ReadinessCheckpoint({
    required this.milestoneDaysRemaining,
    required this.dueDate,
    required this.status,
    required this.phase,
    required this.questionCount,
    required this.includeHard,
    required this.includeUltraHard,
    required this.includeConfidencePrompts,
    required this.includeDelayedRetrieval,
    required this.reasonCodes,
    required this.algorithmVersion,
  });

  final int milestoneDaysRemaining;
  final DateTime dueDate;
  final ReadinessCheckpointStatus status;
  final ExamPreparationPhase phase;
  final int questionCount;
  final bool includeHard;
  final bool includeUltraHard;
  final bool includeConfidencePrompts;
  final bool includeDelayedRetrieval;
  final List<String> reasonCodes;
  final String algorithmVersion;

  Map<String, dynamic> toJson() => {
    'milestoneDaysRemaining': milestoneDaysRemaining,
    'dueDate': DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
    ).toIso8601String(),
    'status': status.name,
    'phase': phase.name,
    'questionCount': questionCount,
    'includeHard': includeHard,
    'includeUltraHard': includeUltraHard,
    'includeConfidencePrompts': includeConfidencePrompts,
    'includeDelayedRetrieval': includeDelayedRetrieval,
    'reasonCodes': reasonCodes,
    'algorithmVersion': algorithmVersion,
  };
}
