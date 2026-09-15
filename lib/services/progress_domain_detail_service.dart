import 'package:shared_preferences/shared_preferences.dart';

import '../models/student_learning_progress.dart';
import '../models/student_progress_dashboard.dart';
import '../models/student_question_progress.dart';
import '../models/study_content.dart';
import 'student_learning_progress_service.dart';
import 'student_progress_dashboard_service.dart';
import 'student_question_progress_service.dart';
import 'study_content/student_content_cache_repository.dart';
import 'study_content_loader.dart';

class ProgressDomainDetailService {
  const ProgressDomainDetailService();

  Future<StudentDomainProgress?> loadCachedDomain(String domainId) async {
    final prefs = await SharedPreferences.getInstance();

    final results = await Future.wait<dynamic>([
      StudentContentCacheRepository(preferences: prefs).loadAll(),
      const StudentLearningProgressService().loadAllProgress(),
      const StudentQuestionProgressService().loadAllProgress(),
    ]);

    final allContents = results[0] as List<StudyContent>;
    final contents = allContents
        .where((content) => content.domainId == domainId)
        .toList(growable: false);

    if (contents.isEmpty) {
      return null;
    }

    return _build(
      domainId: domainId,
      contents: contents,
      subtopicProgress: results[1] as Map<String, StudentSubtopicProgress>,
      questionProgress: results[2] as Map<int, StudentQuestionProgress>,
    );
  }

  Future<StudentDomainProgress?> loadAuthoritativeDomain(
    String domainId,
  ) async {
    final results = await Future.wait<dynamic>([
      const StudyContentLoader().loadPublishedDomainContent(domainId),
      const StudentLearningProgressService().loadAllProgress(),
      const StudentQuestionProgressService().loadAllProgress(),
    ]);

    return _build(
      domainId: domainId,
      contents: results[0] as List<StudyContent>,
      subtopicProgress: results[1] as Map<String, StudentSubtopicProgress>,
      questionProgress: results[2] as Map<int, StudentQuestionProgress>,
    );
  }

  StudentDomainProgress? _build({
    required String domainId,
    required List<StudyContent> contents,
    required Map<String, StudentSubtopicProgress> subtopicProgress,
    required Map<int, StudentQuestionProgress> questionProgress,
  }) {
    final dashboard = StudentProgressDashboardService.buildDashboard(
      contents: contents,
      subtopicProgress: subtopicProgress,
      questionProgress: questionProgress,
    );

    for (final domain in dashboard.domains) {
      if (domain.domainId == domainId) {
        return domain;
      }
    }

    return null;
  }
}
