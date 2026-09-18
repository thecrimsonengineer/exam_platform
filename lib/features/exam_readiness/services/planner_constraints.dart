class DailyPlannerConstraints {
  const DailyPlannerConstraints({
    this.learnMinMinutes = 15,
    this.learnMaxMinutes = 30,
    this.reviewMinMinutes = 5,
    this.reviewMaxMinutes = 15,
    this.practiceMinMinutes = 5,
    this.practiceMaxMinutes = 20,
    this.maxCompetenciesPerDay = 3,
    this.maxBlocksPerDay = 6,
    this.forwardLearningShare = 0.40,
    this.repairShare = 0.25,
    this.retentionShare = 0.20,
    this.assessmentShare = 0.15,
  });

  final int learnMinMinutes;
  final int learnMaxMinutes;
  final int reviewMinMinutes;
  final int reviewMaxMinutes;
  final int practiceMinMinutes;
  final int practiceMaxMinutes;
  final int maxCompetenciesPerDay;
  final int maxBlocksPerDay;
  final double forwardLearningShare;
  final double repairShare;
  final double retentionShare;
  final double assessmentShare;

  void validate() {
    if (learnMinMinutes <= 0 ||
        reviewMinMinutes <= 0 ||
        practiceMinMinutes <= 0) {
      throw StateError('Planner minimum block minutes must be positive.');
    }
    if (learnMinMinutes > learnMaxMinutes ||
        reviewMinMinutes > reviewMaxMinutes ||
        practiceMinMinutes > practiceMaxMinutes) {
      throw StateError('Planner minimums cannot exceed maximums.');
    }
    if (maxCompetenciesPerDay <= 0 || maxBlocksPerDay <= 0) {
      throw StateError('Planner day limits must be positive.');
    }
    final sum =
        forwardLearningShare + repairShare + retentionShare + assessmentShare;
    if ((sum - 1.0).abs() > 0.000001) {
      throw StateError('Planner target shares must sum to 1.0.');
    }
  }
}
