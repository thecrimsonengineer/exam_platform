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
        options: const [
          'Option A',
          'Option B',
          'Option C',
          'Option D',
        ],
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
        'options': [
          'Option A',
          'Option B',
          'Option C',
          'Option D',
        ],
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
        options: const [
          'Option A',
          'Option B',
          'Option C',
          'Option D',
        ],
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

    test('validateForPublication accepts warning-only questions', () async {
      final question = validQuestion(status: 'review');

      final warningQuestion = Question.fromJson({
        ...question.toJson(),
        'question': 'Short scenario question.',
      });

      final issues = await service.validateForPublication(warningQuestion);

      expect(issues.any((issue) => issue.isWarning), isTrue);

      expect(issues.any((issue) => issue.isError), isFalse);

      final validated = service.allManagedQuestions().firstWhere(
        (item) => item.id == question.id,
      );

      expect(validated.status, 'validated');
    });

    test(
      'validateForPublication rejects questions containing errors',
      () async {
        final question = Question.fromJson({
          ...validQuestion(status: 'review').toJson(),
          'reference': '',
        });

        expect(
          () => service.validateForPublication(question),
          throwsStateError,
        );

        expect(
          service.allManagedQuestions().where((item) => item.id == question.id),
          isEmpty,
        );
      },
    );

    test('validateForPublication accepts only review questions', () async {
      final question = validQuestion(status: 'draft');

      expect(() => service.validateForPublication(question), throwsStateError);
    });

    test('publish accepts only validated questions', () async {
      final question = validQuestion(status: 'review');

      expect(() => service.publish(question), throwsStateError);
    });

    test('validated question can be published', () async {
      final question = validQuestion(status: 'validated');

      await service.publish(question);

      final published = service.allManagedQuestions().firstWhere(
        (item) => item.id == question.id,
      );

      expect(published.status, 'published');
    });

    test('publish rejects validated questions containing errors', () async {
      final question = Question.fromJson({
        ...validQuestion(status: 'validated').toJson(),
        'reference': '',
      });

      expect(() => service.publish(question), throwsStateError);
    });

    test(
      'publication randomizes options while preserving correct answer',
      () async {
        final question = validQuestion(status: 'validated');

        await service.publish(question);

        final published = service.allManagedQuestions().firstWhere(
          (item) => item.id == question.id,
        );

        expect(published.status, 'published');
        expect(published.options, hasLength(4));

        final correctText = question.options[question.correctAnswer];

        expect(published.options[published.correctAnswer], correctText);

        expect(published.options.toSet(), question.options.toSet());
      },
    );
  });
}
