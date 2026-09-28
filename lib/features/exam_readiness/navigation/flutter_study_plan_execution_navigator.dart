import 'package:flutter/material.dart';

import '../models/study_plan_execution_target.dart';
import '../services/study_plan_execution_router.dart';
import 'study_plan_block_launcher.dart';

typedef PracticeCompletionCallback =
    Future<void> Function(StudyPlanExecutionTarget target);
typedef LabCompletionCallback =
    Future<void> Function(
      StudyPlanExecutionTarget target,
      double applicationAccuracy,
    );

class FlutterStudyPlanExecutionNavigator
    implements StudyPlanExecutionNavigator {
  const FlutterStudyPlanExecutionNavigator({
    required this.context,
    required this.launcher,
    required this.isDarkMode,
    this.onPracticeSessionCompleted,
    this.onLabCompleted,
  });

  final BuildContext context;
  final StudyPlanBlockLauncher launcher;
  final bool isDarkMode;
  final PracticeCompletionCallback? onPracticeSessionCompleted;
  final LabCompletionCallback? onLabCompleted;

  @override
  Future<void> open(StudyPlanExecutionTarget target) {
    final isPractice =
        target.kind == StudyPlanExecutionTargetKind.practiceSession ||
        target.kind == StudyPlanExecutionTargetKind.examSimulation;

    return launcher.launchTarget(
      context,
      target: target,
      isDarkMode: isDarkMode,
      onPracticeSessionCompleted:
          isPractice && onPracticeSessionCompleted != null
          ? () => onPracticeSessionCompleted!(target)
          : null,
      onLabCompleted:
          target.kind == StudyPlanExecutionTargetKind.lab &&
              onLabCompleted != null
          ? (applicationAccuracy) =>
                onLabCompleted!(target, applicationAccuracy)
          : null,
    );
  }
}
