import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:exam_platform/models/question.dart';
import 'package:exam_platform/models/studio_question_context.dart';
import 'package:exam_platform/services/local_question_repository.dart';
import 'package:exam_platform/services/question_bank_service.dart';
import 'package:exam_platform/services/studio/studio_question_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('StudioQuestionService', () {
    late LocalQuestionRepository repository;
    late QuestionBankService questionBankService;
    late StudioQuestionService service;

    setUp(() {
      repository = LocalQuestionRepository.instance;

      questionBankService = QuestionBankService(repository: repository);

      service = StudioQuestionService(questionBankService: questionBankService);
    });

    test('uses the existing question management service boundary', () {
      expect(service.allManagedQuestions(), isA<List>());
      expect(service.answerLengthCheckEnabled, isTrue);
    });

    test('keeps the Studio service answer-length setting independent', () {
      service.answerLengthCheckEnabled = false;

      expect(service.answerLengthCheckEnabled, isFalse);

      service.answerLengthCheckEnabled = true;

      expect(service.answerLengthCheckEnabled, isTrue);
    });

    test('saves a Studio question as a persistent draft', () async {
      final questionId = DateTime.now().microsecondsSinceEpoch;

      final question = Question(
        id: questionId,
        domain: 7,
        competencyId: 'd07_c02',
        subtopicId: 'd07_c02_01',
        topicId: 'd07_c02_01_t01',
        quizId: 'd07_c02-v1_d07_c02_01_quiz',
        contentPackageId: 'd07_c02-v1',
        question:
            'A supervisor identifies a recurring hazard during a high-risk task. '
            'Which action should be taken first to reduce the risk most effectively?',
        options: const [
          'Eliminate the hazard where reasonably practicable.',
          'Tell workers to remain alert while performing the task.',
          'Provide additional warning signs around the work area.',
          'Ask workers to report the hazard again during the next meeting.',
        ],
        correctAnswer: 0,
        explanation:
            'Eliminating the hazard removes the source of the risk and provides '
            'the strongest control when reasonably practicable.',
        reference: 'CSP11 hierarchy of controls and risk control principles',
        difficulty: 'hard',
        cognitiveLevel: 'application',
        questionType: 'scenario_mcq',
        status: 'draft',
        version: 1,
        tags: const [
          'risk control',
          'hierarchy of controls',
          'hazard elimination',
        ],
      );

      final issues = await service.saveDraft(question);

      if (issues.isNotEmpty) {
        for (final issue in issues) {
          print('QUALITY ISSUE: ${issue.message}');
        }
      }

      expect(issues.where((issue) => issue.isError), isEmpty);

      final stored = repository.questions.where(
        (item) => item.id == questionId,
      );

      expect(stored, hasLength(1));

      final savedQuestion = stored.single;

      expect(savedQuestion.id, questionId);
      expect(savedQuestion.status, 'draft');
      expect(savedQuestion.domain, 7);
      expect(savedQuestion.competencyId, 'd07_c02');
      expect(savedQuestion.subtopicId, 'd07_c02_01');
      expect(savedQuestion.topicId, 'd07_c02_01_t01');
      expect(savedQuestion.quizId, 'd07_c02-v1_d07_c02_01_quiz');
      expect(savedQuestion.contentPackageId, 'd07_c02-v1');
      expect(savedQuestion.question, question.question);
      expect(savedQuestion.options, question.options);
      expect(savedQuestion.correctAnswer, question.correctAnswer);
      expect(savedQuestion.explanation, question.explanation);
      expect(savedQuestion.reference, question.reference);
      expect(savedQuestion.tags, question.tags);

      await service.delete(questionId);

      expect(
        repository.questions.any((item) => item.id == questionId),
        isFalse,
      );
    });

    test(
      'returns only questions belonging to the active Studio context',
      () async {
        final baseId = DateTime.now().microsecondsSinceEpoch;

        final targetQuizId = 'd07_c02-v1_d07_c02_01_quiz';
        final otherQuizId = 'd07_c02-v1_d07_c02_02_quiz';

        final targetSubtopic = 'd07_c02_01';
        final otherSubtopic = 'd07_c02_02';

        final targetQuestionHighId = Question(
          id: baseId + 2,
          domain: 7,
          competencyId: 'd07_c02',
          subtopicId: targetSubtopic,
          topicId: 'd07_c02_01_t01',
          quizId: targetQuizId,
          contentPackageId: 'd07_c02-v1',
          question: 'Target question with higher ID?',
          options: const [
            'Correct answer',
            'Alternative answer',
            'Another alternative',
            'Final alternative',
          ],
          correctAnswer: 0,
          explanation: 'This is the explanation.',
          reference: 'CSP11 test reference',
          difficulty: 'hard',
          cognitiveLevel: 'application',
          questionType: 'scenario_mcq',
          status: 'draft',
          version: 1,
          tags: const ['context', 'scope'],
        );

        final targetQuestionLowId = Question(
          id: baseId + 1,
          domain: 7,
          competencyId: 'd07_c02',
          subtopicId: targetSubtopic,
          topicId: 'd07_c02_01_t01',
          quizId: targetQuizId,
          contentPackageId: 'd07_c02-v1',
          question: 'Target question with lower ID?',
          options: const [
            'Correct answer',
            'Alternative answer',
            'Another alternative',
            'Final alternative',
          ],
          correctAnswer: 0,
          explanation: 'This is the explanation.',
          reference: 'CSP11 test reference',
          difficulty: 'hard',
          cognitiveLevel: 'application',
          questionType: 'scenario_mcq',
          status: 'draft',
          version: 1,
          tags: const ['context', 'scope'],
        );

        final wrongQuizQuestion = Question(
          id: baseId + 3,
          domain: 7,
          competencyId: 'd07_c02',
          subtopicId: targetSubtopic,
          topicId: 'd07_c02_01_t01',
          quizId: otherQuizId,
          contentPackageId: 'd07_c02-v1',
          question: 'Question from another quiz?',
          options: const [
            'Correct answer',
            'Alternative answer',
            'Another alternative',
            'Final alternative',
          ],
          correctAnswer: 0,
          explanation: 'This is the explanation.',
          reference: 'CSP11 test reference',
          difficulty: 'hard',
          cognitiveLevel: 'application',
          questionType: 'scenario_mcq',
          status: 'draft',
          version: 1,
          tags: const ['context', 'scope'],
        );

        final wrongSubtopicQuestion = Question(
          id: baseId + 4,
          domain: 7,
          competencyId: 'd07_c02',
          subtopicId: otherSubtopic,
          topicId: 'd07_c02_02_t01',
          quizId: targetQuizId,
          contentPackageId: 'd07_c02-v1',
          question: 'Question from another subtopic?',
          options: const [
            'Correct answer',
            'Alternative answer',
            'Another alternative',
            'Final alternative',
          ],
          correctAnswer: 0,
          explanation: 'This is the explanation.',
          reference: 'CSP11 test reference',
          difficulty: 'hard',
          cognitiveLevel: 'application',
          questionType: 'scenario_mcq',
          status: 'draft',
          version: 1,
          tags: const ['context', 'scope'],
        );

        await service.saveDraft(targetQuestionHighId);
        await service.saveDraft(targetQuestionLowId);
        await service.saveDraft(wrongQuizQuestion);
        await service.saveDraft(wrongSubtopicQuestion);

        final context = StudioQuestionContext(
          domain: 7,
          competencyId: 'd07_c02',
          subtopicId: targetSubtopic,
          topicId: 'd07_c02_01_t01',
          quizId: targetQuizId,
          contentPackageId: 'd07_c02-v1',
          contentVersion: 1,
        );

        final questions = service.questionsForContext(context);

        expect(questions, hasLength(2));

        expect(questions.map((question) => question.id).toList(), [
          baseId + 1,
          baseId + 2,
        ]);

        expect(
          questions.every(
            (question) =>
                question.quizId == targetQuizId &&
                question.subtopicId == targetSubtopic,
          ),
          isTrue,
        );

        await service.delete(targetQuestionHighId.id);
        await service.delete(targetQuestionLowId.id);
        await service.delete(wrongQuizQuestion.id);
        await service.delete(wrongSubtopicQuestion.id);
      },
    );
  });
}
