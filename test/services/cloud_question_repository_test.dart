import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exam_platform/models/question.dart';
import 'package:exam_platform/services/cloud_question_repository.dart';

Question _sampleQuestion({
  int id = 1001,
  String status = 'draft',
}) {
  return Question(
    id: id,
    domain: 7,
    competencyId: 'd07_c01',
    subtopicId: 'd07_c01_st01',
    topicId: 'topic_01',
    quizId: 'd07_c01-v1_d07_c01_st01_quiz',
    contentPackageId: 'd07_c01-v1',
    question:
        'A safety professional is reviewing a workplace scenario and must determine the most appropriate risk-control decision before work proceeds.',
    options: const [
      'Apply the selected control and verify its effectiveness before work begins.',
      'Allow the work to proceed and review the control after the task is completed.',
      'Record the concern for future review without changing the current work plan.',
      'Transfer the decision to another worker without checking the existing controls.',
    ],
    correctAnswer: 0,
    explanation:
        'The best answer applies the control before work starts and verifies that it is effective, which provides the strongest immediate risk reduction.',
    reference: 'CSP11 practice reference',
    difficulty: 'Hard',
    cognitiveLevel: 'analysis',
    questionType: 'scenario_mcq',
    status: status,
    version: 1,
    tags: const ['risk', 'controls'],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Phase H: CloudQuestionRepository saves and loads a question', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = CloudQuestionRepository(firestore: firestore);
    final question = _sampleQuestion();

    await repository.save(question);

    final loaded = await repository.load(question.id);

    expect(loaded, isNotNull);
    expect(loaded?.id, question.id);
    expect(loaded?.competencyId, question.competencyId);
    expect(loaded?.subtopicId, question.subtopicId);
    expect(loaded?.status, 'draft');
    expect(loaded?.options, hasLength(4));
  });

  test('Phase H: repository preserves lifecycle status', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = CloudQuestionRepository(firestore: firestore);

    await repository.save(_sampleQuestion(status: 'review'));
    await repository.save(_sampleQuestion(id: 1002, status: 'validated'));
    await repository.save(_sampleQuestion(id: 1003, status: 'published'));

    final questions = await repository.loadAll();

    expect(questions, hasLength(3));
    expect(questions.map((question) => question.id), [1001, 1002, 1003]);
    expect(
      questions.map((question) => question.status),
      ['review', 'validated', 'published'],
    );
  });

  test('Phase H: deleting a question removes it from cloud repository', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = CloudQuestionRepository(firestore: firestore);
    final question = _sampleQuestion();

    await repository.save(question);
    await repository.delete(question.id);

    expect(await repository.load(question.id), isNull);
    expect(await repository.loadAll(), isEmpty);
  });

  test('Phase H: clear removes all managed questions', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = CloudQuestionRepository(firestore: firestore);

    await repository.save(_sampleQuestion(id: 1001));
    await repository.save(_sampleQuestion(id: 1002));

    await repository.clear();

    expect(await repository.loadAll(), isEmpty);
  });
}
