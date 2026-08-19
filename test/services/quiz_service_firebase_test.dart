import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exam_platform/models/question.dart';
import 'package:exam_platform/models/study_content.dart';
import 'package:exam_platform/services/cloud_question_repository.dart';
import 'package:exam_platform/services/quiz_service.dart';
import 'package:exam_platform/services/study_content/cloud_content_repository.dart';

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
    question:
        'A safety professional reviews a workplace scenario and must select the best control strategy for the identified risk.',
    options: const [
      'Implement the most effective control at the source of the hazard.',
      'Provide additional training and rely on worker compliance.',
      'Increase administrative checks without changing the hazard.',
      'Wait for another incident before changing the control plan.',
    ],
    correctAnswer: 0,
    explanation:
        'The best answer applies the hierarchy of controls by selecting a control that addresses the hazard at its source and provides the strongest practical risk reduction.',
    reference: 'CSP11 reference',
    difficulty: 'Hard',
    cognitiveLevel: 'application',
    questionType: 'scenario_mcq',
    status: status,
    version: 1,
    tags: const ['risk-control', 'hierarchy-of-controls'],
  );
}

StudyContent _contentWithQuestions({
  required List<Question> questions,
  String id = 'cp_content_01',
  String status = 'published',
}) {
  return StudyContent(
    id: id,
    domainId: 'd01',
    competencyId: 'd01_c01',
    competencyNumber: 1,
    title: 'Risk Management',
    status: status,
    version: 1,
    subtopics: [
      StudySubtopic(
        id: 'd01_c01_st01',
        title: 'Risk Control',
        learningObjectives: const [],
        mainContent: const [],
        questions: questions,
        keyPoints: const [],
        examples: const [],
        caseStudies: const [],
        formulas: const [],
        references: const [],
        examTips: const [],
        commonMistakes: const [],
        keyTakeaways: const [],
        quizzes: const [],
      ),
    ],
  );
}

void main() {
  group('QuizService Firebase question integration', () {
    test('loads only published independent questions from Firebase', () async {
      final firestore = FakeFirebaseFirestore();

      final questionRepository = CloudQuestionRepository(firestore: firestore);

      final contentRepository = CloudContentRepository(firestore: firestore);

      await questionRepository.save(_question(id: 1, status: 'published'));

      await questionRepository.save(_question(id: 2, status: 'draft'));

      await questionRepository.save(_question(id: 3, status: 'validated'));

      final service = QuizService(
        questionRepository: questionRepository,
        contentRepository: contentRepository,
      );

      await service.initialize();

      expect(service.getAllQuestions().map((q) => q.id), [1]);

      expect(service.getTotalQuestions(), 1);
    });

    test('does not expose unpublished independent questions', () async {
      final firestore = FakeFirebaseFirestore();

      final questionRepository = CloudQuestionRepository(firestore: firestore);

      final contentRepository = CloudContentRepository(firestore: firestore);

      await questionRepository.save(_question(id: 10, status: 'published'));

      await questionRepository.save(_question(id: 11, status: 'review'));

      await questionRepository.save(_question(id: 12, status: 'archived'));

      final service = QuizService(
        questionRepository: questionRepository,
        contentRepository: contentRepository,
      );

      await service.initialize();

      final questions = service.getQuestionsBySubtopic('d01_c01_st01');

      expect(questions.map((q) => q.id), [10]);
    });

    test('loads questions embedded inside published content', () async {
      final firestore = FakeFirebaseFirestore();

      final questionRepository = CloudQuestionRepository(firestore: firestore);

      final contentRepository = CloudContentRepository(firestore: firestore);

      final embeddedQuestion = _question(id: 100, status: 'published');

      final content = _contentWithQuestions(questions: [embeddedQuestion]);

      await contentRepository.publish(content);

      final service = QuizService(
        questionRepository: questionRepository,
        contentRepository: contentRepository,
      );

      await service.initialize();

      final questions = service.getQuestionsBySubtopic('d01_c01_st01');

      expect(questions.map((q) => q.id), [100]);

      expect(questions.single.contentPackageId, 'cp_01');
    });

    test('merges independent and content-version questions', () async {
      final firestore = FakeFirebaseFirestore();

      final questionRepository = CloudQuestionRepository(firestore: firestore);

      final contentRepository = CloudContentRepository(firestore: firestore);

      await questionRepository.save(_question(id: 200, status: 'published'));

      final contentQuestion = _question(id: 201, status: 'published');

      final content = _contentWithQuestions(
        id: 'cp_content_02',
        questions: [contentQuestion],
      );

      await contentRepository.publish(content);

      final service = QuizService(
        questionRepository: questionRepository,
        contentRepository: contentRepository,
      );

      await service.initialize();

      final questions = service.getQuestionsBySubtopic('d01_c01_st01');

      expect(questions.map((q) => q.id), containsAll(<int>[200, 201]));

      expect(questions.length, 2);
    });

    test('independent question takes precedence when the same ID '
        'exists in both sources', () async {
      final firestore = FakeFirebaseFirestore();

      final questionRepository = CloudQuestionRepository(firestore: firestore);

      final contentRepository = CloudContentRepository(firestore: firestore);

      final independent = _question(id: 300, status: 'published');

      await questionRepository.save(independent);

      final embedded = _question(id: 300, status: 'published');

      final content = _contentWithQuestions(
        id: 'cp_content_03',
        questions: [embedded],
      );

      await contentRepository.publish(content);

      final service = QuizService(
        questionRepository: questionRepository,
        contentRepository: contentRepository,
      );

      await service.initialize();

      final questions = service.getQuestionsBySubtopic('d01_c01_st01');

      expect(questions.length, 1);

      expect(questions.single.id, 300);

      expect(questions.single.contentPackageId, 'cp_01');
    });
  });
}
