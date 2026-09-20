class FcqRuleResult {
  const FcqRuleResult({
    required this.id,
    required this.points,
    required this.passed,
    required this.message,
  });

  final String id;
  final int points;
  final bool passed;
  final String message;

  int get awardedPoints => passed ? points : 0;
}

class FcqValidationResult {
  const FcqValidationResult({
    required this.rules,
  });

  final List<FcqRuleResult> rules;

  int get score =>
      rules.fold<int>(0, (sum, rule) => sum + rule.awardedPoints);

  int get maxScore => rules.fold<int>(0, (sum, rule) => sum + rule.points);

  bool get passed => maxScore == 100 && score == 100 && failedRules.isEmpty;

  List<FcqRuleResult> get failedRules =>
      rules.where((rule) => !rule.passed).toList(growable: false);
}
