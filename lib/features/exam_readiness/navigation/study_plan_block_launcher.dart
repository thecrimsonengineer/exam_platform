import 'package:flutter/material.dart';

import '../../../data/csp11_blueprint.dart';
import '../../../screens/courses/csp/study_content_screen.dart';
import '../../../screens/courses/csp/study_content_screen_dark.dart';
import '../models/study_plan_block.dart';
import '../models/study_plan_execution_target.dart';
import '../models/today_plan_task_category.dart';
import '../screens/study_plan_practice_session_screen.dart';
import '../services/today_plan_task_category_policy.dart';

class StudyPlanBlockLauncher {
  const StudyPlanBlockLauncher({
    this.categoryPolicy = const TodayPlanTaskCategoryPolicy(),
  });

  final TodayPlanTaskCategoryPolicy categoryPolicy;

  StudyPlanExecutionTarget resolve(StudyPlanBlock block) {
    final domain = domainForContentId(block.domainId);
    if (domain == null) {
      throw StateError(
        'Planned task ${block.blockId} has an unknown CSP11 domain target.',
      );
    }

    final competency = competencyForId(block.competencyId);
    if (competency == null) {
      throw StateError(
        'Planned task ${block.blockId} has an unknown CSP11 competency target.',
      );
    }

    final competencyDomain = domainForContentId(competency.domainId);
    if (competencyDomain?.id != domain.id) {
      throw StateError(
        'Planned task ${block.blockId} has inconsistent domain and '
        'competency targets.',
      );
    }

    if (block.plannedMinutes <= 0) {
      throw StateError(
        'Planned task ${block.blockId} has no executable duration.',
      );
    }

    final category = categoryPolicy.categoryFor(block);
    final kind = switch (category) {
      TodayPlanTaskCategory.learn => StudyPlanExecutionTargetKind.studyContent,
      TodayPlanTaskCategory.remember => StudyPlanExecutionTargetKind.review,
      TodayPlanTaskCategory.practice =>
        block.type == StudyPlanBlockType.examSimulation
            ? StudyPlanExecutionTargetKind.examSimulation
            : StudyPlanExecutionTargetKind.practiceSession,
    };

    if ((kind == StudyPlanExecutionTargetKind.practiceSession ||
            kind == StudyPlanExecutionTargetKind.examSimulation) &&
        block.questionCount <= 0) {
      throw StateError(
        'Planned practice task ${block.blockId} has no executable question count.',
      );
    }

    return StudyPlanExecutionTarget(
      kind: kind,
      blockId: block.blockId,
      blockType: block.type,
      domainId: domain.id,
      domainNumber: domain.number,
      domainTitle: domain.title,
      competencyId: competency.id,
      competencyTitle: competency.statement,
      topicId: _optionalId(block.topicId),
      subtopicId: _optionalId(block.subtopicId),
      plannedMinutes: block.plannedMinutes,
      questionCount: block.questionCount,
    );
  }

  Future<void> launch(
    BuildContext context, {
    required StudyPlanBlock block,
    required bool isDarkMode,
    Future<void> Function()? onPracticeSessionCompleted,
  }) async {
    final target = resolve(block);

    final destination = switch (target.kind) {
      StudyPlanExecutionTargetKind.studyContent ||
      StudyPlanExecutionTargetKind.review =>
        isDarkMode
            ? DarkStudyContentScreen(
                domainId: target.domainId,
                competencyId: target.competencyId,
                domainTitle: target.domainTitle,
                loadingTitle: target.competencyId.toUpperCase(),
                initialTopicId: target.topicId,
                initialSubtopicId: target.subtopicId,
              )
            : StudyContentScreen(
                domainId: target.domainId,
                competencyId: target.competencyId,
                domainTitle: target.domainTitle,
                loadingTitle: target.competencyId.toUpperCase(),
                initialTopicId: target.topicId,
                initialSubtopicId: target.subtopicId,
              ),
      StudyPlanExecutionTargetKind.practiceSession ||
      StudyPlanExecutionTargetKind.examSimulation =>
        StudyPlanPracticeSessionScreen(
          target: target,
          isDarkMode: isDarkMode,
          onSessionCompleted: onPracticeSessionCompleted,
        ),
    };

    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => destination));
  }

  static String? _optionalId(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }
}
