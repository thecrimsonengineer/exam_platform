class WeeklyReadinessReview {
  const WeeklyReadinessReview({
    required this.weekStart,
    required this.weekEnd,
    required this.plannedMinutes,
    required this.completedMinutes,
    required this.completedBlocks,
    required this.abandonedBlocks,
    required this.competenciesImproved,
    required this.newEvidenceGaps,
    required this.criticalGapsRemaining,
    required this.focusCompetencyIds,
    required this.reasonCodes,
    this.knowledgeDelta,
    this.applicationDelta,
    this.retentionDelta,
  });

  final DateTime weekStart;
  final DateTime weekEnd;
  final int plannedMinutes;
  final int completedMinutes;
  final int completedBlocks;
  final int abandonedBlocks;
  final double? knowledgeDelta;
  final double? applicationDelta;
  final double? retentionDelta;
  final int competenciesImproved;
  final int newEvidenceGaps;
  final int criticalGapsRemaining;
  final List<String> focusCompetencyIds;
  final List<String> reasonCodes;

  Map<String, dynamic> toJson() => {
    'weekStart': weekStart.toIso8601String(),
    'weekEnd': weekEnd.toIso8601String(),
    'plannedMinutes': plannedMinutes,
    'completedMinutes': completedMinutes,
    'completedBlocks': completedBlocks,
    'abandonedBlocks': abandonedBlocks,
    'knowledgeDelta': knowledgeDelta,
    'applicationDelta': applicationDelta,
    'retentionDelta': retentionDelta,
    'competenciesImproved': competenciesImproved,
    'newEvidenceGaps': newEvidenceGaps,
    'criticalGapsRemaining': criticalGapsRemaining,
    'focusCompetencyIds': focusCompetencyIds,
    'reasonCodes': reasonCodes,
  };
}
