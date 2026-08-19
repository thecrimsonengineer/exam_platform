import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exam_platform/models/question.dart';
import 'package:exam_platform/services/cloud_question_repository.dart';
import 'package:exam_platform/services/quiz_service.dart';

Question _question({
  required int id,
  required String status,
  String subtopicId = 'd01_c01_st01',
}) {
  return Question(
    id: id,
    domain: 1,
    competencyId: 'd01_c01',
    subtopicId: subtopicId,
    topicId: 'd01_c01_t01',
    quizId: 'quiz_01',
    contentPackageId: 'cp_01',
    question: 'A safety professional reviews a workplace scenario and must select the best control strategy for the identified risk.',
    options: const [
      'Implement the most effective control at the source of the hazard.',
      'Provide additional training and rely on worker compliance.',
      'Increase administrative checks without changing the hazard.',
      'Wait for another incident before changing the control plan.',
    ],
    correctAnswer: 0,
    explanation: 'The best answer applies the hierarchy of controls by selecting a control that addresses the hazard at its source and provides the strongest practical risk reduction.',
    reference: 'CSP11 reference',
    difficulty: 'Hard',
    cognitiveLevel: 'application',
    questionType: 'scenario_mcq',
    status: status,
    version: 1,
    tags: const ['risk-control', 'hierarchy-of-controls'],
  );
}

void main() {
  group('QuizService Firebase question integration', () {
    test('loads only published questions from Firebase', () async {
      final firestore = FakeFirebaseFirestore();
      final repository = CloudQuestionRepository(firestore: firestore);

      await repository.save(_question(id: 1, status: 'published'));
      await repository.save(_question(id: 2, status: 'draft'));
      await repository.save(_question(id: 3, status: 'validated'));

      final service = QuizService(repository: repository);
      await service.initialize();

      expect(service.getAllQuestions().map((q) => q.id), [1]);
      expect(service.getTotalQuestions(), 1);
    });

    test('does not expose unpublished questions through filters', () async {
      final firestore = FakeFirebaseFirestore();
      final repository = CloudQuestionRepository(firestore: firestore);

      await repository.save(_question(id: 10, status: 'published'));
      await repository.save(_question(id: 11, status: 'review'));
      await repository.save(_question(id: 12, status: 'archived'));

      final service = QuizService(repository: repository);
      await service.initialize();

      final questions = service.getQuestionsBySubtopic('d01_c01_st01');

      expect(questions.map((q) => q.id), [10]);
    });
  });
}
