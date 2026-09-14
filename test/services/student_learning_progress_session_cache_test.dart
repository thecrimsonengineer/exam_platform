import 'package:exam_platform/models/student_learning_progress.dart';
import 'package:exam_platform/services/student_learning_progress_session_cache.dart';
import 'package:flutter_test/flutter_test.dart';

StudentSubtopicProgress _progress(String id) {
  return StudentSubtopicProgress(
    domainId: 'domain_01',
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

  test('reuses decoded progress within one learner scope', () async {
    var loads = 0;

    Future<Map<String, StudentSubtopicProgress>> loader() async {
      loads++;
      return <String, StudentSubtopicProgress>{
        's1': _progress('s1'),
      };
    }

    final first = await StudentLearningProgressSessionCache.load(
      loader: loader,
      scopeKey: 'uid:a',
    );
    final second = await StudentLearningProgressSessionCache.load(
      loader: loader,
      scopeKey: 'uid:a',
    );

    expect(first['s1'], isNotNull);
    expect(second['s1'], isNotNull);
    expect(loads, 1);
  });

  test('isolates cached progress by learner scope', () async {
    var loads = 0;

    Future<Map<String, StudentSubtopicProgress>> loader() async {
      loads++;
      return <String, StudentSubtopicProgress>{
        's$loads': _progress('s$loads'),
      };
    }

    final a = await StudentLearningProgressSessionCache.load(
      loader: loader,
      scopeKey: 'uid:a',
    );
    final b = await StudentLearningProgressSessionCache.load(
      loader: loader,
      scopeKey: 'uid:b',
    );

    expect(a.containsKey('s1'), isTrue);
    expect(b.containsKey('s2'), isTrue);
    expect(loads, 2);
  });

  test('invalidation forces the next read back to persistent storage', () async {
    var loads = 0;

    Future<Map<String, StudentSubtopicProgress>> loader() async {
      loads++;
      return <String, StudentSubtopicProgress>{
        's$loads': _progress('s$loads'),
      };
    }

    await StudentLearningProgressSessionCache.load(
      loader: loader,
      scopeKey: 'uid:a',
    );

    StudentLearningProgressSessionCache.invalidateScope('uid:a');

    final refreshed = await StudentLearningProgressSessionCache.load(
      loader: loader,
      scopeKey: 'uid:a',
    );

    expect(loads, 2);
    expect(refreshed.containsKey('s2'), isTrue);
  });
}
