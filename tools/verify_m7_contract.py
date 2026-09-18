#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PLAN = ROOT / "docs/learning_twin/PHASE_M7_EXAM_READINESS_FROZEN_IMPLEMENTATION_PLAN.md"
ROADMAP = ROOT / "docs/learning_twin/PHASE_M_ROADMAP.md"
DECISION = ROOT / "lib/features/learning_twin/domain/learning_twin_decision_service.dart"
LEGACY_BULK = ROOT / "lib/services/studio/studio_bulk_question_publish_service.dart"

FROZEN_PLAN_BLOB = "b714a740b4590a48fe8efba216e8ec59a31bd9e6"

PHASE_TEST_DIRS = {
    "m7a": ROOT / "test/features/exam_readiness/m7a",
    "m7b": ROOT / "test/features/exam_readiness/m7b",
    "m7c": ROOT / "test/features/exam_readiness/m7c",
    "m7d": ROOT / "test/features/exam_readiness/m7d",
    "m7e": ROOT / "test/features/exam_readiness/m7e",
}

PHASE_MIN_TESTS = {
    "m7a": 40,
    "m7b": 100,
    "m7c": 100,
    "m7d": 100,
    "m7e": 40,
}

PHASE_REQUIRED_FILES = {
    "m7a": [
        "lib/features/exam_readiness/models/exam_study_plan.dart",
        "lib/features/exam_readiness/models/study_schedule_exception.dart",
        "lib/features/exam_readiness/models/study_capacity_snapshot.dart",
        "lib/features/exam_readiness/repositories/exam_study_plan_repository.dart",
        "lib/features/exam_readiness/services/exam_study_capacity_service.dart",
        "lib/features/exam_readiness/screens/exam_plan_setup_screen.dart",
        "lib/features/exam_readiness/screens/exam_readiness_plan_screen.dart",
    ],
    "m7b": [
        "lib/features/exam_readiness/models/competency_evidence_snapshot.dart",
        "lib/features/exam_readiness/models/evidence_confidence.dart",
        "lib/features/exam_readiness/models/learner_assessment_attempt.dart",
        "lib/features/exam_readiness/repositories/evidence_snapshot_repository.dart",
        "lib/features/exam_readiness/services/learner_evidence_aggregation_service.dart",
        "lib/features/exam_readiness/services/retention_evidence_service.dart",
    ],
    "m7c": [
        "lib/features/exam_readiness/models/competency_readiness_profile.dart",
        "lib/features/exam_readiness/models/readiness_gap.dart",
        "lib/features/exam_readiness/repositories/readiness_snapshot_repository.dart",
        "lib/features/exam_readiness/services/readiness_profile_service.dart",
        "lib/features/exam_readiness/services/readiness_gap_service.dart",
        "lib/features/exam_readiness/screens/readiness_profile_screen.dart",
        "lib/features/exam_readiness/screens/competency_readiness_screen.dart",
    ],
    "m7d": [
        "lib/features/exam_readiness/models/daily_study_plan.dart",
        "lib/features/exam_readiness/models/study_plan_block.dart",
        "lib/features/exam_readiness/models/learning_priority_score.dart",
        "lib/features/exam_readiness/repositories/daily_study_plan_repository.dart",
        "lib/features/exam_readiness/services/evidence_debt_service.dart",
        "lib/features/exam_readiness/services/learning_priority_engine.dart",
        "lib/features/exam_readiness/services/planner_constraints.dart",
        "lib/features/exam_readiness/services/daily_study_plan_service.dart",
        "lib/features/exam_readiness/services/ultra_hard_availability_service.dart",
        "lib/features/exam_readiness/screens/todays_plan_screen.dart",
    ],
    "m7e": [
        "lib/features/exam_readiness/models/study_plan_block_outcome.dart",
        "lib/features/exam_readiness/models/plan_regeneration_reason.dart",
        "lib/features/exam_readiness/models/misconception_signal.dart",
        "lib/features/exam_readiness/models/learning_state_update_event.dart",
        "lib/features/exam_readiness/models/weekly_readiness_review.dart",
        "lib/features/exam_readiness/repositories/study_plan_block_outcome_repository.dart",
        "lib/features/exam_readiness/repositories/learning_state_audit_repository.dart",
        "lib/features/exam_readiness/services/learning_state_update_coordinator.dart",
        "lib/features/exam_readiness/services/plan_staleness_service.dart",
        "lib/features/exam_readiness/services/plan_replanning_service.dart",
        "lib/features/exam_readiness/services/misconception_signal_service.dart",
        "lib/features/exam_readiness/services/weekly_readiness_review_service.dart",
    ],
}


def fail(message: str) -> None:
    raise SystemExit(f"M7 CONTRACT FAIL: {message}")


def git_blob(path: Path) -> str:
    result = subprocess.run(
        ["git", "hash-object", str(path.relative_to(ROOT))],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout.strip()


def require(condition: bool, message: str) -> None:
    if not condition:
        fail(message)


def read(path: Path) -> str:
    require(path.exists(), f"missing required file: {path.relative_to(ROOT)}")
    return path.read_text(encoding="utf-8")


def verify_frozen_contract() -> None:
    plan = read(PLAN)
    require(git_blob(PLAN) == FROZEN_PLAN_BLOB, "frozen M7 plan blob changed")

    for number in range(1, 21):
        marker = f"M7-{number:03d}"
        require(marker in plan, f"frozen plan lost {marker}")

    for heading in (
        "# M7A - Exam Plan Foundation and Capacity Engine",
        "# M7B - Learner Evidence Engine",
        "# M7C - Multidimensional Readiness Profile",
        "# M7D - Adaptive Daily Planner",
        "# M7E - Closed Feedback Loop and Dynamic Replanning",
        "# M7F - Advanced Readiness Intelligence",
    ):
        require(heading in plan, f"frozen plan lost heading: {heading}")

    require(
        "0% and INSUFFICIENT EVIDENCE are not equivalent states." in plan,
        "missing-evidence safety wording changed",
    )
    require(
        "Readiness is not pass probability" in plan,
        "pass-probability safety rule missing",
    )

    roadmap = read(ROADMAP)
    require(
        "PHASE_M7_EXAM_READINESS_FROZEN_IMPLEMENTATION_PLAN.md" in roadmap,
        "roadmap no longer points to frozen M7 plan",
    )

    decision = read(DECISION)
    require(
        "if (context.isTimedExamActive)" in decision
        and "LearningTwinDecisionReason.timedExamActive" in decision,
        "timed Exam Simulator suppression is not enforced in decision layer",
    )

    legacy = read(LEGACY_BULK)
    require(
        "Dqg300QuestionQualityValidator" not in legacy,
        "legacy H0.3 bulk importer now depends on DQG300",
    )
    require(
        "publishPreparedUltraHardBatch" not in legacy,
        "legacy bulk importer was redirected to Ultra Hard publication",
    )


def phase_test_count(phase: str) -> int:
    root = PHASE_TEST_DIRS[phase]
    require(root.exists(), f"{phase.upper()} test directory missing")

    total = 0
    for path in sorted(root.rglob("*.dart")):
        source = path.read_text(encoding="utf-8")
        require("skip:" not in source, f"skipped test found in {path.relative_to(ROOT)}")
        require("@Skip" not in source, f"@Skip found in {path.relative_to(ROOT)}")
        total += len(re.findall(r"\btest(?:Widgets)?\s*\(", source))
    return total


def verify_phase(phase: str) -> None:
    for relative in PHASE_REQUIRED_FILES[phase]:
        require((ROOT / relative).exists(), f"{phase.upper()} missing {relative}")

    count = phase_test_count(phase)
    minimum = PHASE_MIN_TESTS[phase]
    require(
        count >= minimum,
        f"{phase.upper()} has {count} explicit tests; minimum is {minimum}",
    )

    if phase == "m7a":
        capacity = read(ROOT / "lib/features/exam_readiness/services/exam_study_capacity_service.dart")
        require("Readiness" not in capacity, "M7A capacity service contains readiness logic")
        screen = read(ROOT / "lib/features/exam_readiness/screens/exam_readiness_plan_screen.dart")
        require("pass probability" not in screen.lower(), "M7A UI contains pass probability")

    if phase == "m7b":
        aggregation = read(
            ROOT / "lib/features/exam_readiness/services/learner_evidence_aggregation_service.dart"
        )
        forbidden = ("DailyStudyPlan", "LearningPriority", "ReadinessIndex")
        for token in forbidden:
            require(token not in aggregation, f"M7B evidence engine leaks into {token}")

        evidence = read(
            ROOT / "lib/features/exam_readiness/models/competency_evidence_snapshot.dart"
        )
        require(
            "ultraHardAttempts" in evidence and "ultraHardAccuracy" in evidence,
            "M7B does not preserve Ultra Hard as a separate evidence lane",
        )

    if phase == "m7c":
        profile = read(
            ROOT / "lib/features/exam_readiness/services/readiness_profile_service.dart"
        )
        require(
            "ReadinessIndex" not in profile,
            "M7C introduced composite Readiness Index before M7F",
        )
        require(
            "pass probability" not in profile.lower(),
            "M7C uses prohibited pass-probability language",
        )

        model = read(
            ROOT / "lib/features/exam_readiness/models/competency_readiness_profile.dart"
        )
        require(
            "insufficientEvidence" in model,
            "M7C cannot represent insufficient evidence distinctly",
        )


    if phase == "m7d":
        planner = read(
            ROOT / "lib/features/exam_readiness/services/daily_study_plan_service.dart"
        )
        block_model = read(
            ROOT / "lib/features/exam_readiness/models/study_plan_block.dart"
        )
        plan_model = read(
            ROOT / "lib/features/exam_readiness/models/daily_study_plan.dart"
        )
        availability = read(
            ROOT / "lib/features/exam_readiness/services/ultra_hard_availability_service.dart"
        )
        repository = read(
            ROOT / "lib/features/exam_readiness/repositories/daily_study_plan_repository.dart"
        )

        require(
            "StudyPlanBlockType.diagnostic" in planner
            and "Repair cannot be scheduled for unknown evidence" in planner,
            "M7D diagnostic-vs-repair safety gate is missing",
        )
        require(
            "Ultra Hard block requires a published DQG300 Ultra Hard bank" in planner,
            "M7D Ultra Hard generation gate is missing",
        )
        require(
            "UltraHardQuestionContract.classificationTag" in availability
            and "entry.value >= 5" in availability,
            "M7D Ultra Hard availability is not tied to the published DQG300 lane",
        )
        require(
            "reasonCodes" in block_model and "reasonText" in block_model,
            "M7D blocks are not explainable",
        )
        require(
            "bool get isLocked" in block_model,
            "M7D block locking contract is missing",
        )
        require(
            "allocatedMinutes > availableMinutes" in plan_model,
            "M7D capacity invariant is missing",
        )
        require(
            "Daily plan history is immutable" in repository,
            "M7D immutable plan history guard is missing",
        )
        require(
            "Started/completed block was silently replaced" in planner,
            "M7D started-block regeneration guard is missing",
        )



    if phase == "m7e":
        coordinator = read(
            ROOT / "lib/features/exam_readiness/services/learning_state_update_coordinator.dart"
        )
        staleness = read(
            ROOT / "lib/features/exam_readiness/services/plan_staleness_service.dart"
        )
        outcome_repository = read(
            ROOT / "lib/features/exam_readiness/repositories/study_plan_block_outcome_repository.dart"
        )
        audit_repository = read(
            ROOT / "lib/features/exam_readiness/repositories/learning_state_audit_repository.dart"
        )
        plan_model = read(
            ROOT / "lib/features/exam_readiness/models/daily_study_plan.dart"
        )
        regeneration = read(
            ROOT / "lib/features/exam_readiness/models/plan_regeneration_reason.dart"
        )

        require(
            "updateCompetencySnapshot" in coordinator
            and "buildCompetencyProfile" in coordinator,
            "M7E does not perform incremental competency evidence/readiness updates",
        )
        require(
            "buildAllSnapshots" not in coordinator
            and "buildDashboard" not in coordinator,
            "M7E coordinator performs prohibited full-blueprint rebuild per outcome",
        )
        require(
            "syncRemote: false" in coordinator,
            "M7E coordinator is not explicitly local-first",
        )
        require(
            "DailyStudyPlanStatus.stale" in staleness
            and "planVersion + 1" in staleness,
            "M7E future-plan staleness/versioning contract is missing",
        )
        require(
            "previousPlanId" in plan_model and "inputSnapshotVersion" in plan_model,
            "M7E plan lineage fields are missing",
        )
        require(
            "SharedPreferences" in outcome_repository
            and "SharedPreferences" in audit_repository,
            "M7E outcome/audit history is not UID-local",
        )
        for token in (
            "dailyRollover",
            "assessmentCompleted",
            "majorPerformanceShift",
            "examDateChanged",
            "studyScheduleChanged",
            "criticalGapDetected",
            "manualRequest",
            "missedStudyDay",
            "capacityChanged",
        ):
            require(token in regeneration, f"M7E regeneration reason missing: {token}")
        require(
            "pass probability" not in coordinator.lower(),
            "M7E uses prohibited pass-probability language",
        )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--phase",
        choices=("pre", "m7a", "m7b", "m7c", "m7d", "m7e"),
        default="pre",
    )
    args = parser.parse_args()

    verify_frozen_contract()

    ordered = ("m7a", "m7b", "m7c", "m7d", "m7e")
    if args.phase != "pre":
        target = ordered.index(args.phase)
        for phase in ordered[: target + 1]:
            verify_phase(phase)

    print(f"M7 CONTRACT PASS: {args.phase.upper()}")


if __name__ == "__main__":
    main()
