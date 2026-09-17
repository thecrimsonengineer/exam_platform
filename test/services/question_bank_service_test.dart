import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:exam_platform/models/question.dart';
import 'package:exam_platform/services/local_question_repository.dart';
import 'package:exam_platform/services/question_bank_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('H2 Question safe lifecycle defaults', () {
    test('Question constructor defaults status to draft', () {
      final question = Question(
        id: 2001,
        domain: 1,
        competencyId: 'd01_c01',
        subtopicId: 'd01_c01_st01',
        topicId: 'd01_c01_t01',
        question: 'Test question.',
        options: const ['Option A', 'Option B', 'Option C', 'Option D'],
        correctAnswer: 0,
        explanation: 'Test explanation.',
        reference: 'Test reference.',
        difficulty: 'Hard',
        tags: const ['test'],
      );
      expect(question.status, 'draft');
    });

    test('Question.fromJson defaults missing status to draft', () {
      final question = Question.fromJson({
        'id': 2002,
        'domain': 1,
        'competencyId': 'd01_c01',
        'subtopicId': 'd01_c01_st01',
        'topicId': 'd01_c01_t01',
        'question': 'Test question.',
        'options': ['Option A', 'Option B', 'Option C', 'Option D'],
        'correctAnswer': 0,
        'explanation': 'Test explanation.',
        'reference': 'Test reference.',
        'difficulty': 'Hard',
        'tags': ['test'],
      });
      expect(question.status, 'draft');
    });

    test('Question preserves explicit published status', () {
      final question = Question(
        id: 2003,
        domain: 1,
        competencyId: 'd01_c01',
        subtopicId: 'd01_c01_st01',
        topicId: 'd01_c01_t01',
        question: 'Test question.',
        options: const ['Option A', 'Option B', 'Option C', 'Option D'],
        correctAnswer: 0,
        explanation: 'Test explanation.',
        reference: 'Test reference.',
        difficulty: 'Hard',
        status: 'published',
        tags: const ['test'],
      );
      expect(question.status, 'published');
    });
  });

  group('H1.1 QuestionBankService lifecycle', () {
    late QuestionBankService service;

    setUp(() async {
      service = QuestionBankService(
        repository: LocalQuestionRepository.instance,
      );
      await LocalQuestionRepository.instance.replaceAll(const <Question>[]);
    });

    Question validQuestion({String status = 'draft'}) {
      return Question(
        id: 1001,
        domain: 1,
        competencyId: 'd01_c01',
        subtopicId: 'd01_c01_st01',
        topicId: 'd01_c01_t01',
        quizId: 'quiz_01',
        contentPackageId: 'cp_01',
        question:
            'A manufacturing organisation identifies a recurring exposure during a high-risk maintenance task and needs to determine the most appropriate control before work continues.',
        options: const [
          'Improve supervision during the maintenance activity.',
          'Provide additional personal protective equipment.',
          'Eliminate the hazardous task through redesign.',
          'Increase worker awareness through toolbox talks.',
        ],
        correctAnswer: 2,
        explanation:
            'Redesigning the task to eliminate the hazardous exposure provides the strongest control because it removes the hazard rather than relying primarily on worker behaviour or protective equipment.',
        reference: 'CSP11 reference material',
        difficulty: 'Hard',
        cognitiveLevel: 'application',
        questionType: 'scenario_mcq',
        status: status,
        version: 1,
        tags: const ['hazard control', 'risk reduction'],
      );
    }

    test('saveDraft forces persisted status to draft', () async {
      final question = validQuestion(status: 'published');
      final issues = await service.saveDraft(question);
      expect(issues, isEmpty);
      final saved = service.allManagedQuestions().firstWhere(
        (item) => item.id == question.id,
      );
      expect(saved.status, 'draft');
    });

    test('sendToReview accepts only draft questions', () async {
      final question = validQuestion(status: 'draft');
      await service.saveDraft(question);
      await service.sendToReview(
        service.allManagedQuestions().firstWhere(
          (item) => item.id == question.id,
        ),
      );
      final reviewed = service.allManagedQuestions().firstWhere(
        (item) => item.id == question.id,
      );
      expect(reviewed.status, 'review');
    });

    test('sendToReview rejects non-draft questions', () async {
      final question = validQuestion(status: 'review');
      expect(() => service.sendToReview(question), throwsStateError);
    });

    test('review question cannot validate without DQG300 evidence', () {
      final question = validQuestion(status: 'review');
      expect(() => service.validateForPublication(question), throwsStateError);
      expect(service.allManagedQuestions(), isEmpty);
    });

    test('warning-only review cannot validate without DQG300 evidence', () {
      final warningQuestion = Question.fromJson({
        ...validQuestion(status: 'review').toJson(),
        'question': 'Short scenario question.',
      });
      expect(
        () => service.validateForPublication(warningQuestion),
        throwsStateError,
      );
      expect(service.allManagedQuestions(), isEmpty);
    });

    test('validateForPublication accepts only review questions', () {
      final question = validQuestion(status: 'draft');
      expect(() => service.validateForPublication(question), throwsStateError);
    });

    test('publish accepts only validated questions', () {
      final question = validQuestion(status: 'review');
      expect(() => service.publish(question), throwsStateError);
    });

    test('validated question cannot publish without DQG300 evidence', () {
      final question = validQuestion(status: 'validated');
      expect(() => service.publish(question), throwsStateError);
      expect(service.allManagedQuestions(), isEmpty);
    });

    test('validated question with legacy errors remains blocked', () {
      final question = Question.fromJson({
        ...validQuestion(status: 'validated').toJson(),
        'reference': '',
      });
      expect(() => service.publish(question), throwsStateError);
    });

    test('nextQuestionId is unique across rapid consecutive allocations', () {
      final ids = List<int>.generate(20, (_) => service.nextQuestionId());
      expect(ids.toSet(), hasLength(ids.length));
      for (var index = 1; index < ids.length; index++) {
        expect(ids[index], greaterThan(ids[index - 1]));
      }
    });

    test('five-question batch persists five distinct managed IDs', () async {
      final base = validQuestion();
      final questions = List<Question>.generate(
        5,
        (index) => Question.fromJson({
          ...base.toJson(),
          'id': service.nextQuestionId(),
          'question':
              '${base.question} Batch variation ${index + 1} requires a different decision.',
        }),
      );
      final result = await service.saveDraftBatch(questions);
      expect(result.addedCount, 5);
      expect(result.duplicateCount, 0);
      expect(service.allManagedQuestions(), hasLength(5));
      expect(
        service.allManagedQuestions().map((question) => question.id).toSet(),
        hasLength(5),
      );
    });

    test('exact re-import keeps one existing question ID', () async {
      final original = validQuestion();
      await service.saveDraft(original);
      final duplicate = Question.fromJson({
        ...original.toJson(),
        'id': service.nextQuestionId(),
      });
      final result = await service.saveDraftBatch([duplicate]);
      expect(result.addedCount, 0);
      expect(result.duplicateCount, 1);
      expect(service.allManagedQuestions(), hasLength(1));
      expect(service.allManagedQuestions().single.id, original.id);
    });

    test('same stem with changed answer metadata is rejected', () async {
      final original = validQuestion();
      await service.saveDraft(original);
      final conflict = Question.fromJson({
        ...original.toJson(),
        'id': service.nextQuestionId(),
        'explanation': 'A materially changed explanation.',
      });
      expect(() => service.saveDraftBatch([conflict]), throwsStateError);
      expect(service.allManagedQuestions(), hasLength(1));
      expect(service.allManagedQuestions().single.id, original.id);
    });

    test('same stem cannot be imported into a different subtopic', () async {
      final original = validQuestion();
      await service.saveDraft(original);
      final wrongPlacement = Question.fromJson({
        ...original.toJson(),
        'id': service.nextQuestionId(),
        'subtopicId': 'd01_c01_st99',
        'topicId': 'd01_c01_t99',
        'quizId': 'quiz_99',
      });
      expect(() => service.saveDraftBatch([wrongPlacement]), throwsStateError);
      expect(service.allManagedQuestions(), hasLength(1));
      expect(service.allManagedQuestions().single.subtopicId, 'd01_c01_st01');
    });
  });

  group('Bulk prepared question publication', () {
    late QuestionBankService service;

    setUp(() async {
      service = QuestionBankService(
        repository: LocalQuestionRepository.instance,
      );
      await LocalQuestionRepository.instance.replaceAll(const <Question>[]);
    });

    Question validQuestion(int id, String stem) {
      return Question(
        id: id,
        domain: 7,
        competencyId: 'd07_c05',
        subtopicId: 'd07_c05_t01_s01',
        topicId: 'd07_c05_t01',
        quizId: 'd07_c05_t01_s01_quiz',
        contentPackageId: 'd07_c05-v2',
        question: stem,
        options: const [
          'Use a lecture because it is quick to deliver.',
          'Use supervised practice with feedback.',
          'Use self-study only to reduce instructor time.',
          'Use a written test without practical activity.',
        ],
        correctAnswer: 1,
        explanation:
            'Supervised practice with feedback best supports application of a practical skill and allows immediate correction.',
        reference: 'Raymond A. Noe, Employee Training and Development',
        difficulty: 'Hard',
        cognitiveLevel: 'application',
        questionType: 'scenario_mcq',
        status: 'draft',
        version: 1,
        tags: const ['training methods', 'skill practice'],
      );
    }

    test('prepared batch cannot publish without evidence map', () {
      final questions = List<Question>.generate(
        5,
        (index) => validQuestion(
          service.nextQuestionId(),
          'A supervisor must select a practical training method for task ${index + 1} after workers understood the theory. Which approach BEST supports safe transfer to the job?',
        ),
      );
      expect(() => service.publishPreparedBatch(questions), throwsStateError);
      expect(service.allManagedQuestions(), isEmpty);
    });

    test('existing question is not rebound when evidence is absent', () async {
      final original = validQuestion(
        7001,
        'A safety trainer must teach a hands-on isolation sequence. Which method BEST supports correct task performance?',
      );
      await service.saveDraft(original);
      final incoming = Question.fromJson({
        ...original.toJson(),
        'id': service.nextQuestionId(),
        'contentPackageId': 'd07_c05-v3',
      });
      expect(
        () => service.publishPreparedBatch([incoming]),
        throwsStateError,
      );
      expect(service.allManagedQuestions(), hasLength(1));
      expect(service.allManagedQuestions().single.id, 7001);
      expect(service.allManagedQuestions().single.status, 'draft');
      expect(service.allManagedQuestions().single.contentPackageId, 'd07_c05-v2');
    });
  });
}
