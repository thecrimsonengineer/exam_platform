import 'package:flutter_test/flutter_test.dart';

import 'package:exam_platform/models/question.dart';
import 'package:exam_platform/services/questions/learner_question_package_delivery_service.dart';
import 'package:exam_platform/services/quiz_service.dart';

class _FakeDeliveryService extends LearnerQuestionPackageDeliveryService {
  _FakeDeliveryService(this.questions);

  final List<Question> questions;
  int calls = 0;
  int? lastDomain;
  String? lastCompetencyId;
  String? lastTopicId;
  String? lastSubtopicId;
  String? lastQuizId;

  @override
  Future<List<Question>> loadForScope({
    required int domain,
    String? competencyId,
    String? topicId,
    String? subtopicId,
    String? quizId,
  }) async {
    calls++;
    lastDomain = domain;
    lastCompetencyId = competencyId;
    lastTopicId = topicId;
    lastSubtopicId = subtopicId;
    lastQuizId = quizId;
    return List<Question>.from(questions);
  }
}

Question _question({
  required int id,
  String status = 'published',
  String competencyId = 'd01_c01',
  String topicId = 'd01_c01_t01',
  String subtopicId = 'd01_c01_t01_s01',
  String quizId = 'd01_c01_quiz',
}) {
  return Question(
    id: id,
    domain: 1,
    competencyId: competencyId,
    subtopicId: subtopicId,
    topicId: topicId,
    quizId: quizId,
    contentPackageId: '',
    question: 'Which control is the strongest available choice?',
    options: const <String>[
      'Eliminate the hazard.',
      'Add a warning.',
      'Rely on training.',
      'Accept the exposure.',
    ],
    correctAnswer: 0,
    explanation: 'Elimination removes the hazard at source.',
    reference: 'CSP11 reference',
    difficulty: 'Hard',
    cognitiveLevel: 'application',
    questionType: 'scenario_mcq',
    status: status,
    version: 1,
    tags: const <String>['risk-control'],
  );
}

void main() {
  group('FR9D QuizService prepared scopes', () {
    test('global initialize fails closed', () async {
      final service = QuizService(
        deliveryService: _FakeDeliveryService(const <Question>[]),
      );

      await expectLater(service.initialize(), throwsStateError);
      expect(service.isInitialized, isFalse);
    });

    test('prepares exactly the requested competency scope', () async {
      final delivery = _FakeDeliveryService(<Question>[_question(id: 1)]);
      final service = QuizService(deliveryService: delivery);

      await service.prepareScope(
        domain: 1,
        competencyId: 'd01_c01',
      );

      expect(delivery.calls, 1);
      expect(delivery.lastDomain, 1);
      expect(delivery.lastCompetencyId, 'd01_c01');
      expect(service.getAllQuestions().map((q) => q.id), <int>[1]);
      expect(service.isInitialized, isTrue);
    });

    test('topic and subtopic selectors survive scope preparation', () async {
      final delivery = _FakeDeliveryService(<Question>[
        _question(id: 10, subtopicId: 'd01_c01_t01_s01'),
        _question(id: 11, subtopicId: 'd01_c01_t01_s02'),
      ]);
      final service = QuizService(deliveryService: delivery);

      await service.prepareScope(
        domain: 1,
        topicId: 'd01_c01_t01',
        subtopicId: 'd01_c01_t01_s01',
      );

      expect(
        service.getQuestionsBySubtopic('d01_c01_t01_s01').map((q) => q.id),
        <int>[10],
      );
      expect(
        service.getQuestionsByTopic('d01_c01_t01').map((q) => q.id),
        <int>[10, 11],
      );
    });

    test('prepared scope keeps only published positive unique IDs', () async {
      final delivery = _FakeDeliveryService(<Question>[
        _question(id: 20),
        _question(id: 20),
        _question(id: 21, status: 'draft'),
        _question(id: -1),
      ]);
      final service = QuizService(deliveryService: delivery);

      await service.prepareScope(domain: 1, competencyId: 'd01_c01');

      expect(service.getAllQuestions().map((q) => q.id), <int>[20]);
    });

    test('same prepared scope is reused without another delivery call', () async {
      final delivery = _FakeDeliveryService(<Question>[_question(id: 30)]);
      final service = QuizService(deliveryService: delivery);

      await service.prepareScope(domain: 1, competencyId: 'd01_c01');
      await service.prepareScope(domain: 1, competencyId: 'd01_c01');

      expect(delivery.calls, 1);
    });

    test('clearProtectedSession removes prepared protected questions', () async {
      final delivery = _FakeDeliveryService(<Question>[_question(id: 40)]);
      final service = QuizService(deliveryService: delivery);

      await service.prepareScope(domain: 1, competencyId: 'd01_c01');
      service.clearProtectedSession();

      expect(service.getAllQuestions(), isEmpty);
      expect(service.isInitialized, isFalse);
    });
  });
}
