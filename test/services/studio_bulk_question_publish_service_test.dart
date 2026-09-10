import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:exam_platform/models/study_content.dart';
import 'package:exam_platform/services/local_question_repository.dart';
import 'package:exam_platform/services/question_bank_service.dart';
import 'package:exam_platform/services/studio/studio_bulk_question_publish_service.dart';
import 'package:exam_platform/services/studio/studio_question_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  late StudioBulkQuestionPublishService service;

  setUp(() async {
    await LocalQuestionRepository.instance.replaceAll(const []);

    final questionService = StudioQuestionService(
      questionBankService: QuestionBankService(
        repository: LocalQuestionRepository.instance,
      ),
    );

    service = StudioBulkQuestionPublishService(
      questionService: questionService,
    );
  });

  StudyContent content() {
    return const StudyContent(
      id: 'd07_c05-v1',
      domainId: 'd07',
      competencyId: 'd07_c05',
      competencyNumber: 5,
      title: 'Education and Training Methods and Techniques',
      status: 'published',
      version: 1,
      topics: [
        StudyTopic(
          id: 'd07_c05_t01',
          title: 'Selecting an Appropriate Training Method',
          subtopics: [
            StudySubtopic(
              id: 'd07_c05_t01_s01',
              title: 'Match the Method to the Learning Objective',
            ),
            StudySubtopic(
              id: 'd07_c05_t01_s02',
              title: 'Consider the Learner, Task, Trainer and Workplace',
            ),
          ],
        ),
      ],
    );
  }

  Map<String, dynamic> question({
    required String topicId,
    required String subtopicId,
    required int number,
  }) {
    return {
      'competencyId': 'd07_c05',
      'topicId': topicId,
      'subtopicId': subtopicId,
      'question':
          'A safety professional must select a training method for scenario '
          '$number. Workers know the theory but must apply the task safely. '
          'Which approach BEST supports transfer?',
      'options': [
        'Use lecture only because it reaches the group quickly.',
        'Use supervised practice with specific feedback.',
        'Use reading material without instructor interaction.',
        'Use a written quiz as the only learning activity.',
      ],
      'correctAnswer': 1,
      'explanation':
          'Supervised practice with feedback supports application and '
          'transfer because workers perform the task and receive correction.',
      'reference': 'Raymond A. Noe, Employee Training and Development',
      'difficulty': 'Hard',
      'cognitiveLevel': 'application',
      'questionType': 'scenario_mcq',
      'tags': ['training methods', 'transfer of training'],
    };
  }

  test('prepares competency-wide package with five per subtopic', () {
    final questions = <Map<String, dynamic>>[];

    for (var index = 0; index < 5; index++) {
      questions.add(
        question(
          topicId: 'd07_c05_t01',
          subtopicId: 'd07_c05_t01_s01',
          number: index + 1,
        ),
      );
      questions.add(
        question(
          topicId: 'd07_c05_t01',
          subtopicId: 'd07_c05_t01_s02',
          number: index + 101,
        ),
      );
    }

    final plan = service.prepareFromJsonText(
      input: jsonEncode({'competencyId': 'd07_c05', 'questions': questions}),
      content: content(),
    );

    expect(plan.questionCount, 10);
    expect(plan.subtopicCount, 2);
    expect(plan.questionCountBySubtopic['d07_c05_t01_s01'], 5);
    expect(plan.questionCountBySubtopic['d07_c05_t01_s02'], 5);
    expect(
      plan.questions.every((item) => item.quizId == '${item.subtopicId}_quiz'),
      isTrue,
    );
  });

  test('coverage gate rejects any subtopic with fewer than five', () {
    final questions = <Map<String, dynamic>>[];

    for (var index = 0; index < 5; index++) {
      questions.add(
        question(
          topicId: 'd07_c05_t01',
          subtopicId: 'd07_c05_t01_s01',
          number: index + 1,
        ),
      );
    }

    for (var index = 0; index < 4; index++) {
      questions.add(
        question(
          topicId: 'd07_c05_t01',
          subtopicId: 'd07_c05_t01_s02',
          number: index + 101,
        ),
      );
    }

    expect(
      () => service.prepareFromDecoded(
        decoded: {'competencyId': 'd07_c05', 'questions': questions},
        content: content(),
      ),
      throwsFormatException,
    );
  });

  test('unknown subtopic is rejected before persistence', () {
    final questions = List<Map<String, dynamic>>.generate(
      10,
      (index) => question(
        topicId: 'd07_c05_t01',
        subtopicId: index < 5 ? 'd07_c05_t01_s01' : 'd07_c05_t01_s99',
        number: index + 1,
      ),
    );

    expect(
      () => service.prepareFromDecoded(
        decoded: {'competencyId': 'd07_c05', 'questions': questions},
        content: content(),
      ),
      throwsFormatException,
    );
  });
}
