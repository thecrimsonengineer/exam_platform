import 'package:exam_platform/models/student_learning_progress.dart';
import 'package:exam_platform/services/student_learning_progress_session_cache.dart';
import 'package:flutter_test/flutter_test.dart';

StudentSubtopicProgress _progress(String id) {
  return StudentSubtopicProgress(
    domainId: 'd01',
    domainNumber: 1,
    domainTitle: 'Domain 1',
    competencyId: 'd01_c01',
    competencyTitle: 'Competency',
    subtopicId: id,
    subtopicTitle: 'Subtopic',
    studyContentId: 'content',
    studyContentVersion: 1,
    state: StudentLearningState.inProgress,
    lastOpenedAt: DateTime(2026, 9, 14),
    completedAt: null,
  );
}

void main() {
  setUp(StudentLearningProgressSessionCache.clearAllScopes);

  test('peek returns null before progress is loaded for the scope', () {
    expect(StudentLearningProgressSessionCache.peek(scopeKey: 'uid:a'), isNull);
  });

  test('peek returns already decoded progress synchronously', () async {
    await StudentLearningProgressSessionCache.load(
      scopeKey: 'uid:a',
      loader: () async => <String, StudentSubtopicProgress>{
        's1': _progress('s1'),
      },
    );

    final cached = StudentLearningProgressSessionCache.peek(scopeKey: 'uid:a');

    expect(cached, isNotNull);
    expect(cached!['s1'], isNotNull);
  });

  test('invalidation removes synchronous peek data', () async {
    await StudentLearningProgressSessionCache.load(
      scopeKey: 'uid:a',
      loader: () async => <String, StudentSubtopicProgress>{
        's1': _progress('s1'),
      },
    );

    StudentLearningProgressSessionCache.invalidateScope('uid:a');

    expect(StudentLearningProgressSessionCache.peek(scopeKey: 'uid:a'), isNull);
  });
}
