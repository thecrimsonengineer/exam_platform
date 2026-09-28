import 'study_plan_execution_target.dart';

enum StudyPlanExecutionAttemptStatus { started, navigationFailed, completed }

class StudyPlanExecutionAttempt {
  const StudyPlanExecutionAttempt({
    required this.executionAttemptId,
    required this.planId,
    required this.sourcePlanVersion,
    required this.committedPlanVersion,
    required this.blockId,
    required this.targetKind,
    required this.startedAt,
    required this.status,
    this.navigationFailedAt,
    this.failureCode,
  });

  static const int currentSchemaVersion = 1;

  final String executionAttemptId;
  final String planId;
  final int sourcePlanVersion;
  final int committedPlanVersion;
  final String blockId;
  final StudyPlanExecutionTargetKind targetKind;
  final DateTime startedAt;
  final StudyPlanExecutionAttemptStatus status;
  final DateTime? navigationFailedAt;
  final String? failureCode;

  static String deterministicId({
    required String planId,
    required int sourcePlanVersion,
    required String blockId,
  }) => 'erdp4-$planId-v$sourcePlanVersion-$blockId';

  StudyPlanExecutionAttempt markNavigationFailed({
    required DateTime at,
    required String failureCode,
  }) {
    return StudyPlanExecutionAttempt(
      executionAttemptId: executionAttemptId,
      planId: planId,
      sourcePlanVersion: sourcePlanVersion,
      committedPlanVersion: committedPlanVersion,
      blockId: blockId,
      targetKind: targetKind,
      startedAt: startedAt,
      status: StudyPlanExecutionAttemptStatus.navigationFailed,
      navigationFailedAt: at,
      failureCode: failureCode,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'schemaVersion': currentSchemaVersion,
    'executionAttemptId': executionAttemptId,
    'planId': planId,
    'sourcePlanVersion': sourcePlanVersion,
    'committedPlanVersion': committedPlanVersion,
    'blockId': blockId,
    'targetKind': targetKind.name,
    'startedAt': startedAt.toIso8601String(),
    'status': status.name,
    'navigationFailedAt': navigationFailedAt?.toIso8601String(),
    'failureCode': failureCode,
  };

  factory StudyPlanExecutionAttempt.fromJson(Map<String, dynamic> json) {
    final startedAt = DateTime.tryParse(json['startedAt']?.toString() ?? '');
    if (startedAt == null) {
      throw const FormatException('Invalid execution attempt startedAt.');
    }

    final navigationFailedAtValue = json['navigationFailedAt']?.toString();
    final navigationFailedAt =
        navigationFailedAtValue == null || navigationFailedAtValue.isEmpty
        ? null
        : DateTime.tryParse(navigationFailedAtValue);
    if (navigationFailedAtValue != null &&
        navigationFailedAtValue.isNotEmpty &&
        navigationFailedAt == null) {
      throw const FormatException(
        'Invalid execution attempt navigationFailedAt.',
      );
    }

    final targetKindName = json['targetKind']?.toString();
    final statusName = json['status']?.toString();

    return StudyPlanExecutionAttempt(
      executionAttemptId: _requiredString(json, 'executionAttemptId'),
      planId: _requiredString(json, 'planId'),
      sourcePlanVersion: _requiredPositiveInt(json, 'sourcePlanVersion'),
      committedPlanVersion: _requiredPositiveInt(json, 'committedPlanVersion'),
      blockId: _requiredString(json, 'blockId'),
      targetKind: StudyPlanExecutionTargetKind.values.firstWhere(
        (value) => value.name == targetKindName,
        orElse: () => throw const FormatException(
          'Unknown execution attempt target kind.',
        ),
      ),
      startedAt: startedAt,
      status: StudyPlanExecutionAttemptStatus.values.firstWhere(
        (value) => value.name == statusName,
        orElse: () =>
            throw const FormatException('Unknown execution attempt status.'),
      ),
      navigationFailedAt: navigationFailedAt,
      failureCode: json['failureCode']?.toString(),
    );
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key]?.toString().trim() ?? '';
  if (value.isEmpty) {
    throw FormatException('Execution attempt requires $key.');
  }
  return value;
}

int _requiredPositiveInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  final parsed = value is int ? value : int.tryParse(value?.toString() ?? '');
  if (parsed == null || parsed <= 0) {
    throw FormatException('Execution attempt requires positive $key.');
  }
  return parsed;
}
