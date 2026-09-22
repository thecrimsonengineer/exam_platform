import '../../models/study_content.dart';

abstract interface class StudentContentCache {
  Future<List<StudyContent>> loadAll();

  Future<StudyContent?> load(String contentId);

  Future<StudyContent?> loadLatestForCompetency(String competencyId);

  Future<int?> cachedVersionForCompetency(String competencyId);

  Future<void> save(StudyContent content);

  Future<void> remove(String contentId);

  Future<void> clear();
}
