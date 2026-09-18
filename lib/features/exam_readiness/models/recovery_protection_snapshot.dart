enum RecoveryProtectionState { none, reducedIntensityDay, recoveryDay }

class RecoveryProtectionSnapshot {
  const RecoveryProtectionSnapshot({
    required this.state,
    required this.consecutiveMissedStudyDays,
    required this.declaredMinutes,
    required this.suggestedMinutes,
    required this.reasonCodes,
    required this.algorithmVersion,
  });

  final RecoveryProtectionState state;
  final int consecutiveMissedStudyDays;
  final int declaredMinutes;
  final int suggestedMinutes;
  final List<String> reasonCodes;
  final String algorithmVersion;

  bool get recommendsChange => state != RecoveryProtectionState.none;
}
