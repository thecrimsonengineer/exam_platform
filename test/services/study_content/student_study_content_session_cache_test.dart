import 'package:exam_platform/models/study_content.dart';
import 'package:exam_platform/services/study_content/student_study_content_session_cache.dart';
import 'package:flutter_test/flutter_test.dart';

StudyContent _content(int index) {
  return StudyContent.fromJson(<String, dynamic>{
    'id': 'content-$index',
    'domainId': 'domain_01',
    'competencyId': 'd01_c${index.toString().padLeft(2, '0')}',
    'competencyNumber': index,
    'title': 'Competency $index',
    'status': 'published',
    'version': 1,
    'topics': <Map<String, dynamic>>[],
  });
}

void main() {
  setUp(StudentStudyContentSessionCache.clear);

  test('returns published content placed in the current session', () {
    final content = _content(1);

    StudentStudyContentSessionCache.put(content);

    final loaded = StudentStudyContentSessionCache.get(
      domainId: 'domain_01',
      competencyId: 'd01_c01',
    );

    expect(loaded?.id, content.id);
  });

  test('caps session content cache to five competencies', () {
    for (var i = 1; i <= 6; i++) {
      StudentStudyContentSessionCache.put(_content(i));
    }

    expect(StudentStudyContentSessionCache.length, 5);

    expect(
      StudentStudyContentSessionCache.get(
        domainId: 'domain_01',
        competencyId: 'd01_c01',
      ),
      isNull,
    );

    expect(
      StudentStudyContentSessionCache.get(
        domainId: 'domain_01',
        competencyId: 'd01_c06',
      ),
      isNotNull,
    );
  });

  test('reading an entry refreshes its LRU position', () {
    for (var i = 1; i <= 5; i++) {
      StudentStudyContentSessionCache.put(_content(i));
    }

    expect(
      StudentStudyContentSessionCache.get(
        domainId: 'domain_01',
        competencyId: 'd01_c01',
      ),
      isNotNull,
    );

    StudentStudyContentSessionCache.put(_content(6));

    expect(
      StudentStudyContentSessionCache.get(
        domainId: 'domain_01',
        competencyId: 'd01_c01',
      ),
      isNotNull,
    );

    expect(
      StudentStudyContentSessionCache.get(
        domainId: 'domain_01',
        competencyId: 'd01_c02',
      ),
      isNull,
    );
  });

  test('does not admit non-published content', () {
    final draft = StudyContent.fromJson(<String, dynamic>{
      'id': 'draft-content',
      'domainId': 'domain_01',
      'competencyId': 'd01_c01',
      'competencyNumber': 1,
      'title': 'Draft',
      'status': 'draft',
      'version': 1,
      'topics': <Map<String, dynamic>>[],
    });

    StudentStudyContentSessionCache.put(draft);

    expect(StudentStudyContentSessionCache.length, 0);
  });
}
