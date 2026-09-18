import 'package:shared_preferences/shared_preferences.dart';

import '../models/learner_assessment_attempt.dart';
import 'learner_evidence_aggregation_service.dart';
import '../../../services/study_content/student_content_cache_repository.dart';

class CompetencyEvidenceScopeService {
  const CompetencyEvidenceScopeService();

  Future<CompetencyEvidenceScope> resolve({
    required String competencyId,
    Iterable<LearnerAssessmentAttempt> attempts = const [],
  }) async {
    final normalized = competencyId.trim().toLowerCase();
    final preferences = await SharedPreferences.getInstance();
    final cached = await StudentContentCacheRepository(
      preferences: preferences,
    ).loadLatestForCompetency(normalized);

    if (cached == null) {
      return CompetencyEvidenceScope(competencyId: normalized);
    }

    final topics = <String>{};
    final subtopics = <String>{};

    for (final topic in cached.topics) {
      if (topic.id.trim().isNotEmpty) topics.add(topic.id.trim());
      for (final subtopic in topic.subtopics) {
        if (subtopic.id.trim().isNotEmpty) {
          subtopics.add(subtopic.id.trim());
        }
      }
    }

    return CompetencyEvidenceScope(
      competencyId: normalized,
      topicIds: topics,
      subtopicIds: subtopics,
    );
  }
}
