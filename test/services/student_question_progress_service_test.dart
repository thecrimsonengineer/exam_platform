import 'package:exam_platform/models/question.dart';
import 'package:exam_platform/services/auth/learner_local_identity.dart';
import 'package:exam_platform/services/student_question_progress_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LearnerLocalIdentity.clear();
  });

  tearDown(LearnerLocalIdentity.clear);

  test('question completion is isolated between two Firebase UIDs', () async {
    const service = StudentQuestionProgressService();

    LearnerLocalIdentity.activate('uid-A');
    await service.recordAnswer(question: _question(101), correct: true);

    expect((await service.loadAllProgress()).length, 1);

    LearnerLocalIdentity.activate('uid-B');
    expect(await service.loadAllProgress(), isEmpty);

    await service.recordAnswer(question: _question(102), correct: false);

    expect((await service.loadAllProgress()).keys, contains(102));
    expect((await service.loadAllProgress()).keys, isNot(contains(101)));

    LearnerLocalIdentity.activate('uid-A');

    expect((await service.loadAllProgress()).keys, contains(101));
    expect((await service.loadAllProgress()).keys, isNot(contains(102)));
  });

  test(
    're-answering one question does not inflate unique completion count',
    () async {
      const service = StudentQuestionProgressService(
        userIdOverride: 'test-user',
      );

      await service.recordAnswer(question: _question(101), correct: false);
      await service.recordAnswer(question: _question(101), correct: true);

      final all = await service.loadAllProgress();

      expect(all.length, 1);
      expect(all[101]?.attemptCount, 2);
      expect(all[101]?.lastCorrect, isTrue);
      expect(all[101]?.everCorrect, isTrue);
    },
  );

  test('clearAllProgress clears only the active learner', () async {
    const service = StudentQuestionProgressService();

    LearnerLocalIdentity.activate('uid-A');
    await service.recordAnswer(question: _question(101), correct: true);

    LearnerLocalIdentity.activate('uid-B');
    await service.recordAnswer(question: _question(102), correct: true);
    await service.clearAllProgress();

    expect(await service.loadAllProgress(), isEmpty);

    LearnerLocalIdentity.activate('uid-A');
    expect((await service.loadAllProgress()).keys, contains(101));
  });
}

Question _question(int id) {
  return Question(
    id: id,
    domain: 7,
    competencyId: 'd07_c01',
    topicId: 'd07_c01_t01',
    subtopicId: 'd07_c01_t01_s01',
    quizId: 'quiz-1',
    question: 'Question?',
    options: const ['A', 'B', 'C', 'D'],
    correctAnswer: 0,
    explanation: 'Explanation',
    reference: 'Reference',
    difficulty: 'Hard',
    tags: const ['tag1', 'tag2'],
    status: 'published',
  );
}
