import 'package:exam_platform/models/student_learning_progress.dart';
import 'package:exam_platform/models/study_content.dart';
import 'package:exam_platform/services/study_content/student_study_content_prefetch_service.dart';
import 'package:exam_platform/services/study_content/student_study_content_session_cache.dart';
import 'package:flutter_test/flutter_test.dart';

StudyContent _content({
  required String competencyId,
  required int competencyNumber,
  int version = 1,
  int subtopicCount = 2,
}) {
  return StudyContent(
    id: '$competencyId-v$version',
    domainId: 'd01',
    competencyId: competencyId,
    competencyNumber: competencyNumber,
    title: competencyId,
    status: 'published',
    version: version,
    topics: <StudyTopic>[
      StudyTopic(
        id: '${competencyId}_t01',
        title: 'Topic',
        subtopics: List<StudySubtopic>.generate(
          subtopicCount,
          (index) => StudySubtopic(
            id: '${competencyId}_s${index + 1}',
            title: 'Subtopic ${index + 1}',
          ),
        ),
      ),
    ],
  );
}

StudentSubtopicProgress _progress({
  required StudyContent content,
  required String subtopicId,
  required StudentLearningState state,
  required DateTime opened,
}) {
  return StudentSubtopicProgress(
    domainId: content.domainId,
    domainNumber: 1,
    domainTitle: 'Domain 1',
    competencyId: content.competencyId,
    competencyTitle: content.title,
    subtopicId: subtopicId,
    subtopicTitle: subtopicId,
    studyContentId: content.id,
    studyContentVersion: content.version,
    state: state,
    lastOpenedAt: opened,
    completedAt: state == StudentLearningState.completed ? opened : null,
  );
}

void main() {
  const service = StudentStudyContentPrefetchService();

  setUp(StudentStudyContentSessionCache.clear);

  test('chooses first untouched competency when no progress exists', () {
    final first = _content(competencyId: 'd01_c01', competencyNumber: 1);
    final second = _content(competencyId: 'd01_c02', competencyNumber: 2);

    final selected = service.selectCandidate(
      domainId: 'd01',
      contents: <StudyContent>[second, first],
      progress: const <String, StudentSubtopicProgress>{},
      isCached: (_) => false,
    );

    expect(selected?.competencyId, 'd01_c01');
  });

  test('prefers most recently active in-progress competency', () {
    final first = _content(competencyId: 'd01_c01', competencyNumber: 1);
    final second = _content(competencyId: 'd01_c02', competencyNumber: 2);
    final third = _content(competencyId: 'd01_c03', competencyNumber: 3);

    final progress = <String, StudentSubtopicProgress>{
      'a': _progress(
        content: second,
        subtopicId: 'd01_c02_s1',
        state: StudentLearningState.inProgress,
        opened: DateTime(2026, 9, 13, 10),
      ),
      'b': _progress(
        content: third,
        subtopicId: 'd01_c03_s1',
        state: StudentLearningState.inProgress,
        opened: DateTime(2026, 9, 14, 10),
      ),
    };

    final selected = service.selectCandidate(
      domainId: 'd01',
      contents: <StudyContent>[first, second, third],
      progress: progress,
      isCached: (_) => false,
    );

    expect(selected?.competencyId, 'd01_c03');
  });

  test('skips fully completed current-version competency', () {
    final first = _content(
      competencyId: 'd01_c01',
      competencyNumber: 1,
      subtopicCount: 1,
    );
    final second = _content(competencyId: 'd01_c02', competencyNumber: 2);

    final progress = <String, StudentSubtopicProgress>{
      'done': _progress(
        content: first,
        subtopicId: 'd01_c01_s1',
        state: StudentLearningState.completed,
        opened: DateTime(2026, 9, 14, 9),
      ),
    };

    final selected = service.selectCandidate(
      domainId: 'd01',
      contents: <StudyContent>[first, second],
      progress: progress,
      isCached: (_) => false,
    );

    expect(selected?.competencyId, 'd01_c02');
  });

  test('skips already cached candidate and warms exactly one new item', () {
    final first = _content(competencyId: 'd01_c01', competencyNumber: 1);
    final second = _content(competencyId: 'd01_c02', competencyNumber: 2);

    StudentStudyContentSessionCache.put(first);

    final warmed = service.warmOne(
      domainId: 'd01',
      contents: <StudyContent>[first, second],
      progress: const <String, StudentSubtopicProgress>{},
    );

    expect(warmed?.competencyId, 'd01_c02');
    expect(StudentStudyContentSessionCache.length, 2);
    expect(
      StudentStudyContentSessionCache.contains(
        domainId: 'd01',
        competencyId: 'd01_c02',
      ),
      isTrue,
    );
  });

  test('does not warm content from another domain or unpublished content', () {
    final otherDomain = _content(
      competencyId: 'd01_c01',
      competencyNumber: 1,
    ).copyWith(domainId: 'd02');

    final draft = _content(
      competencyId: 'd01_c02',
      competencyNumber: 2,
    ).copyWith(status: 'draft');

    final warmed = service.warmOne(
      domainId: 'd01',
      contents: <StudyContent>[otherDomain, draft],
      progress: const <String, StudentSubtopicProgress>{},
    );

    expect(warmed, isNull);
    expect(StudentStudyContentSessionCache.length, 0);
  });
}
