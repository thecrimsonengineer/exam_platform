import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/csp11_blueprint.dart';
import '../../../services/student_question_progress_service.dart';
import '../../../services/study_content/student_content_cache_repository.dart';
import '../models/competency_evidence_snapshot.dart';
import '../models/learner_assessment_attempt.dart';
import '../repositories/evidence_snapshot_repository.dart';
import '../repositories/learner_assessment_attempt_repository.dart';
import 'learner_evidence_aggregation_service.dart';

class ReadinessEvidenceBootstrapResult {
  const ReadinessEvidenceBootstrapResult({
    required this.evidenceByCompetency,
    required this.attempts,
    required this.importedLegacyQuestionCount,
  });

  final Map<String, CompetencyEvidenceSnapshot> evidenceByCompetency;
  final List<LearnerAssessmentAttempt> attempts;
  final int importedLegacyQuestionCount;
}

/// Rebuilds learner readiness evidence from the learner's real local history.
///
/// M7B introduced an immutable assessment-attempt ledger after learners could
/// already have UID-scoped question progress. This service bridges those older
/// per-question records once, then rebuilds evidence snapshots locally.
///
/// The bridge is deliberately conservative:
/// - at most one historical attempt is created for each legacy question
/// - the legacy attempt uses only the stored last-known answer
/// - attemptCount is never expanded into invented historical attempts
/// - confidence and retention evidence are never fabricated
/// - current cloud question metadata is never retrofitted onto old attempts
/// - a question that already has a real M7B attempt is never bridged again
class ReadinessEvidenceBootstrapService {
  const ReadinessEvidenceBootstrapService({
    this.aggregationService = const LearnerEvidenceAggregationService(),
  });

  final LearnerEvidenceAggregationService aggregationService;

  Future<ReadinessEvidenceBootstrapResult> rebuildLocal({
    required EvidenceSnapshotRepository evidenceRepository,
    required LearnerAssessmentAttemptRepository attemptRepository,
    StudentQuestionProgressService? questionProgressService,
    DateTime? now,
  }) async {
    final progressService =
        questionProgressService ?? const StudentQuestionProgressService();

    final imported = await _bridgeLegacyQuestionProgress(
      progressService: progressService,
      attemptRepository: attemptRepository,
    );

    final attempts = await attemptRepository.loadAll();
    final effectiveNow = now ?? DateTime.now();
    final existingEvidence = await evidenceRepository.loadLocal();

    if (!_needsRebuild(
      importedLegacyQuestionCount: imported,
      attempts: attempts,
      evidenceByCompetency: existingEvidence,
      now: effectiveNow,
    )) {
      return ReadinessEvidenceBootstrapResult(
        evidenceByCompetency: existingEvidence,
        attempts: attempts,
        importedLegacyQuestionCount: imported,
      );
    }

    final scopes = await _buildScopes(attempts);
    final snapshots = aggregationService.buildAllSnapshots(
      attempts: attempts,
      scopes: scopes,
      now: effectiveNow,
    );

    await evidenceRepository.clearLocal();
    if (snapshots.isNotEmpty) {
      await evidenceRepository.saveMany(
        snapshots.values,
        syncRemote: false,
      );
    }

    return ReadinessEvidenceBootstrapResult(
      evidenceByCompetency: snapshots,
      attempts: attempts,
      importedLegacyQuestionCount: imported,
    );
  }

  bool _needsRebuild({
    required int importedLegacyQuestionCount,
    required List<LearnerAssessmentAttempt> attempts,
    required Map<String, CompetencyEvidenceSnapshot> evidenceByCompetency,
    required DateTime now,
  }) {
    if (importedLegacyQuestionCount > 0) {
      return true;
    }

    final represented = <String, List<LearnerAssessmentAttempt>>{};
    for (final attempt in attempts) {
      if (!attempt.publishedAtAttempt || !attempt.hasCanonicalCompetencyId) {
        continue;
      }

      final competencyId = attempt.competencyId.trim().toLowerCase();
      if (competencyForId(competencyId) == null) {
        continue;
      }

      represented
          .putIfAbsent(competencyId, () => <LearnerAssessmentAttempt>[])
          .add(attempt);
    }

    if (represented.isEmpty) {
      return false;
    }

    for (final entry in represented.entries) {
      final snapshot = evidenceByCompetency[entry.key];
      if (snapshot == null) {
        return true;
      }

      final latestAttempt = entry.value
          .map((attempt) => attempt.answeredAt)
          .reduce((left, right) => left.isAfter(right) ? left : right);

      if (latestAttempt.isAfter(snapshot.generatedAt)) {
        return true;
      }

      if (now.difference(snapshot.generatedAt).inHours >= 24) {
        return true;
      }
    }

    return false;
  }

  Future<int> _bridgeLegacyQuestionProgress({
    required StudentQuestionProgressService progressService,
    required LearnerAssessmentAttemptRepository attemptRepository,
  }) async {
    final progress = await progressService.loadAllProgress();
    if (progress.isEmpty) return 0;

    final existingAttempts = await attemptRepository.loadAll();
    final questionIdsWithRealEvidence = existingAttempts
        .map((attempt) => attempt.questionId)
        .toSet();

    final records = progress.values.toList(growable: false)
      ..sort(
        (left, right) => left.lastAnsweredAt.compareTo(right.lastAnsweredAt),
      );

    var imported = 0;

    for (final record in records) {
      if (record.questionId <= 0 ||
          questionIdsWithRealEvidence.contains(record.questionId)) {
        continue;
      }

      final competencyId = _canonicalCompetencyId(
        record.competencyId,
        record.domainNumber,
      );
      if (competencyId == null) {
        continue;
      }

      final attempt = LearnerAssessmentAttempt(
        attemptId: 'legacy-question-progress-v1-${record.questionId}',
        questionId: record.questionId,
        domainNumber: record.domainNumber,
        competencyId: competencyId,
        topicId: record.topicId.trim(),
        subtopicId: record.subtopicId.trim(),
        correct: record.lastCorrect,
        answeredAt: record.lastAnsweredAt,
        cognitiveLevel: 'legacy_unclassified',
        questionType: 'legacy_progress',
        difficultyLane: AttemptDifficultyLane.standard,
        publishedAtAttempt: true,
        questionVersion: 1,
        sessionKind: 'legacy_progress_bridge',
      );

      if (await attemptRepository.append(attempt)) {
        imported++;
        questionIdsWithRealEvidence.add(record.questionId);
      }
    }

    return imported;
  }

  Future<List<CompetencyEvidenceScope>> _buildScopes(
    List<LearnerAssessmentAttempt> attempts,
  ) async {
    final representedCompetencies = attempts
        .where(
          (attempt) =>
              attempt.publishedAtAttempt && attempt.hasCanonicalCompetencyId,
        )
        .map((attempt) => attempt.competencyId.trim().toLowerCase())
        .where((id) => competencyForId(id) != null)
        .toSet();

    if (representedCompetencies.isEmpty) {
      return const <CompetencyEvidenceScope>[];
    }

    final topics = <String, Set<String>>{
      for (final id in representedCompetencies) id: <String>{},
    };
    final subtopics = <String, Set<String>>{
      for (final id in representedCompetencies) id: <String>{},
    };

    final preferences = await SharedPreferences.getInstance();
    final contentCache = StudentContentCacheRepository(
      preferences: preferences,
    );
    final cachedContent = await contentCache.loadAll();

    for (final content in cachedContent) {
      final competencyId = content.competencyId.trim().toLowerCase();
      if (!representedCompetencies.contains(competencyId)) {
        continue;
      }

      for (final topic in content.topics) {
        final topicId = topic.id.trim();
        if (topicId.isNotEmpty) {
          topics[competencyId]!.add(topicId);
        }

        for (final subtopic in topic.subtopics) {
          final subtopicId = subtopic.id.trim();
          if (subtopicId.isNotEmpty) {
            subtopics[competencyId]!.add(subtopicId);
          }
        }
      }
    }

    final sorted = representedCompetencies.toList()..sort();

    return [
      for (final competencyId in sorted)
        CompetencyEvidenceScope(
          competencyId: competencyId,
          topicIds: topics[competencyId] ?? const <String>{},
          subtopicIds: subtopics[competencyId] ?? const <String>{},
        ),
    ];
  }

  String? _canonicalCompetencyId(String raw, int domainNumber) {
    final normalized = raw.trim().toLowerCase();

    if (competencyForId(normalized) != null) {
      return normalized;
    }

    final compact = normalized.replaceAll(RegExp(r'[^a-z0-9]'), '');
    final match = RegExp(r'^d0?(\d+)c0?(\d+)$').firstMatch(compact);

    if (match != null) {
      final domain = int.tryParse(match.group(1) ?? '');
      final competency = int.tryParse(match.group(2) ?? '');
      if (domain != null && competency != null) {
        final candidate =
            'd${domain.toString().padLeft(2, '0')}_c${competency.toString().padLeft(2, '0')}';
        if (competencyForId(candidate) != null) {
          return candidate;
        }
      }
    }

    if (domainNumber > 0) {
      final competencyMatch = RegExp(r'c0?(\d+)').firstMatch(compact);
      final competency = int.tryParse(competencyMatch?.group(1) ?? '');
      if (competency != null) {
        final candidate =
            'd${domainNumber.toString().padLeft(2, '0')}_c${competency.toString().padLeft(2, '0')}';
        if (competencyForId(candidate) != null) {
          return candidate;
        }
      }
    }

    return null;
  }
}
