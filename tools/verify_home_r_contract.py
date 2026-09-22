#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
BASE_SHA = "b54740c394e8c0b0cdc6d7c2acd165f6a3ba1123"


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def require(path: str, *tokens: str) -> None:
    source = read(path)
    missing = [token for token in tokens if token not in source]
    if missing:
        raise AssertionError(f"{path} missing: {missing}")


def forbid(path: str, *tokens: str) -> None:
    source = read(path)
    present = [token for token in tokens if token in source]
    if present:
        raise AssertionError(f"{path} forbidden: {present}")


def ordered(path: str, *tokens: str) -> None:
    source = read(path)
    positions = [source.find(token) for token in tokens]
    if any(position < 0 for position in positions):
        raise AssertionError(f"{path} order token missing: {list(zip(tokens, positions))}")
    if positions != sorted(positions):
        raise AssertionError(f"{path} order drift: {list(zip(tokens, positions))}")


HOME_FILES = [
    "lib/screens/home/home_screen.dart",
    "lib/screens/home/home_screen_dark.dart",
]

for path in HOME_FILES:
    ordered(
        path,
        "_buildHero(context, snapshot, data)",
        "StudyContentSearchPanel(",
        "_buildContinueLearning(snapshot, data)",
        "FutureBuilder<TodayPlanSummary?>(",
        "_buildProgressIntelligence(snapshot, data)",
    )
    require(
        path,
        "StudentLearningPositionService",
        "DailyStudyPlanRepository",
        "TodayPlanSummaryService",
        "TodayPlanHomeSection",
        "loadLatestForDate(DateTime.now())",
        "home-exam-readiness",
        "Icons.track_changes_rounded",
    )
    forbid(
        path,
        "YOUR WORKSPACE",
        "QUICK PRACTICE",
        "Train with intent",
        "BookmarkedQuestionsScreen",
        "PracticeQuickLaunchScreen",
        "onOpenStudy",
        "onOpenFlashcards",
        "Icons.bookmark_border_rounded",
        "DailyStudyPlanService(",
        "PhaseAwareDailyPlanService(",
        "refreshRemote: true",
        "FirebaseFirestore",
        "cloud_firestore",
    )

require(
    "lib/features/exam_readiness/models/today_plan_task_category.dart",
    "enum TodayPlanTaskCategory { learn, practice, remember }",
)
require(
    "lib/features/exam_readiness/services/today_plan_task_category_policy.dart",
    "StudyPlanBlockType.learn",
    "StudyPlanBlockType.standardPractice",
    "StudyPlanBlockType.spacedReview",
    "StudyPlanBlockType.recovery",
    "RETENTION_DUE",
)
require(
    "lib/features/exam_readiness/services/today_plan_summary_service.dart",
    "TodayPlanSummary summarize(DailyStudyPlan plan)",
    "categoryPolicy.categoryFor(block)",
)
forbid(
    "lib/features/exam_readiness/services/today_plan_summary_service.dart",
    "savePlan(",
    ".generate(",
)

require(
    "lib/widgets/csp/home/today_plan_home_section.dart",
    "home-today-learn",
    "home-today-practice",
    "home-today-remember",
    "home-view-full-plan",
    "constraints.maxWidth < 760",
    "constraints.maxWidth < 560",
)

require(
    "lib/features/exam_readiness/screens/todays_plan_screen.dart",
    "final TodayPlanTaskCategory? initialCategory;",
    "TodayPlanPresentationFilter presentationFilter",
    "visibleBlocks = widget.presentationFilter.apply(",
    "StudyPlanBlockLauncher blockLauncher",
    "StudyPlanCompletionEvidenceService completionEvidenceService",
    "StudyPlanCompletionEvidenceSource.plannedPracticeSession",
    "StudyPlanCompletionEvidenceSource.studyContent",
    "allowsExplicitLearnerFinish(block)",
    "_completionInFlight.add(blockId)",
)
forbid(
    "lib/features/exam_readiness/screens/todays_plan_screen.dart",
    "copyWith(blocks: visibleBlocks",
    "FlashcardsScreen(",
)

require(
    "lib/features/exam_readiness/navigation/study_plan_block_launcher.dart",
    "class StudyPlanBlockLauncher",
    "StudyContentScreen(",
    "DarkStudyContentScreen(",
    "StudyPlanPracticeSessionScreen(",
    "UltraHardQuestionContract" if False else "StudyPlanExecutionTargetKind.examSimulation",
)
forbid(
    "lib/features/exam_readiness/navigation/study_plan_block_launcher.dart",
    "FlashcardsScreen(",
)

require(
    "lib/features/exam_readiness/screens/study_plan_practice_session_screen.dart",
    "await service.prepareScope(",
    "service.buildQuiz(",
    "UltraHardQuestionContract.classificationTag",
    "StudyPlanCompletionEvidenceService.sessionKindForBlock(",
)
forbid(
    "lib/features/exam_readiness/screens/study_plan_practice_session_screen.dart",
    "service.initialize(",
    "StudentQuizBuilder",
)

require(
    "lib/screens/courses/csp/quiz/quiz_screen.dart",
    "assessmentSessionKind",
    "sessionKind: widget.assessmentSessionKind",
    "_pendingQuestionWrites",
    "await Future.wait(",
    "_sessionCompletionNotified",
)

require(
    "lib/features/exam_readiness/services/study_plan_completion_evidence_service.dart",
    "plannedPracticeSession",
    "explicitLearnerFinish",
    "final questionIds = <int>{};",
    "progress.lastCompletedAt ?? progress.completedAt",
    "TodayPlanTaskCategory.learn",
)
require(
    "lib/models/student_learning_progress.dart",
    "final DateTime? lastCompletedAt;",
    "'lastCompletedAt': lastCompletedAt?.toIso8601String()",
)
require(
    "lib/services/student_learning_progress_service.dart",
    "final completedAt = existing?.completedAt ?? now",
    "lastCompletedAt: now",
)

for path in [
    "lib/screens/courses/csp/study_subtopic_screen.dart",
    "lib/screens/courses/csp/study_subtopic_screen_dark.dart",
]:
    require(path, "MARK REVIEW COMPLETE", "progress.lastCompletedAt")

for path, dark in [
    ("lib/screens/settings/settings_screen.dart", "false"),
    ("lib/screens/settings/settings_screen_dark.dart", "true"),
]:
    ordered(path, "'LEARNING & PROGRESS'", "'settings-full-progress'", "'settings-bookmarked-questions'", "'LEGAL'")
    require(
        path,
        "BookmarkedQuestionsScreen(",
        f"isDarkMode: {dark}",
        "Bookmarked Questions",
    )

require(
    "lib/services/bookmark_service.dart",
    "static const String _bookmarkKey = 'bookmarked_question_ids'",
    "static const String _snapshotKey = 'bookmarked_question_snapshots_v2'",
)

print(f"HOME-R frozen architecture verified from base {BASE_SHA}.")
