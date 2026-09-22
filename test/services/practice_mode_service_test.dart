import 'dart:math';

import 'package:exam_platform/models/question.dart';
import 'package:exam_platform/models/student_question_progress.dart';
import 'package:exam_platform/services/practice/practice_mode_service.dart';
import 'package:exam_platform/services/questions/learner_question_package_delivery_service.dart';
import 'package:exam_platform/services/questions/published_question_package.dart';
import 'package:exam_platform/services/quiz_service.dart';
import 'package:exam_platform/services/ultra_hard_question_contract.dart';
import 'package:flutter_test/flutter_test.dart';

Question _question({
  required int id,
  required int domain,
  bool ultraHard = false,
  String? competencyId,
}) {
  final domainId = domain.toString().padLeft(2, '0');
  final resolvedCompetencyId = competencyId ?? 'd${domainId}_c01';

  return Question(
    id: id,
    domain: domain,
    competencyId: resolvedCompetencyId,
    subtopicId: '${resolvedCompetencyId}_t01_s01',
    topicId: '${resolvedCompetencyId}_t01',
    quizId: '${resolvedCompetencyId}_quiz',
    contentPackageId: '',
    question:
        'A safety professional reviews a workplace scenario and must select the best available control for the identified risk.',
    options: const <String>[
      'Apply the strongest practical control at the source of the hazard.',
      'Rely only on worker attention while leaving the hazard unchanged.',
      'Delay action until another unwanted event confirms the concern.',
      'Use a weaker administrative step when a source control is feasible.',
    ],
    correctAnswer: 0,
    explanation:
        'The strongest practical control should address the hazard as close to its source as possible.',
    reference: 'CSP11 reference',
    difficulty: 'Hard',
    cognitiveLevel: 'Application',
    questionType: 'scenario_mcq',
    status: 'published',
    version: 1,
    tags: <String>[
      'practice',
      'risk-control',
      if (ultraHard) UltraHardQuestionContract.classificationTag,
    ],
  );
}

StudentQuestionProgress _progress({
  required Question question,
  required bool everCorrect,
}) {
  final answeredAt = DateTime(2026, 9, 15, 12);

  return StudentQuestionProgress(
    questionId: question.id,
    domainNumber: question.domain,
    competencyId: question.competencyId,
    topicId: question.topicId,
    subtopicId: question.subtopicId,
    attemptCount: 1,
    lastCorrect: everCorrect,
    everCorrect: everCorrect,
    firstAnsweredAt: answeredAt,
    lastAnsweredAt: answeredAt,
  );
}

class _FakePracticeDelivery extends LearnerQuestionPackageDeliveryService {
  _FakePracticeDelivery();

  final Map<String, List<Question>> questionsByCompetency =
      <String, List<Question>>{};
  final List<String> loadedCompetencies = <String>[];

  @override
  Future<List<PublishedQuestionPackageDescriptor>> loadCatalog() async {
    final descriptors = questionsByCompetency.entries.map((entry) {
      final ultraHardCount = entry.value
          .where(
            (question) => question.tags.contains(
              UltraHardQuestionContract.classificationTag,
            ),
          )
          .length;

      return PublishedQuestionPackageDescriptor(
        competencyId: entry.key,
        version: 1,
        checksumSha256: List<String>.filled(64, '0').join(),
        compressedBytes: 1,
        publishedQuestionCount: entry.value.length,
        ultraHardCount: ultraHardCount,
      );
    }).toList()
      ..sort(
        (left, right) => left.competencyId.compareTo(right.competencyId),
      );

    return List<PublishedQuestionPackageDescriptor>.unmodifiable(descriptors);
  }

  @override
  Future<List<Question>> loadCompetency(String competencyId) async {
    final normalized = competencyId.trim().toLowerCase();
    loadedCompetencies.add(normalized);
    return List<Question>.unmodifiable(
      questionsByCompetency[normalized] ?? const <Question>[],
    );
  }
}

class _PracticeFixture {
  _PracticeFixture({
    required this.quizService,
    required this.delivery,
    required this.questions,
  });

  final QuizService quizService;
  final _FakePracticeDelivery delivery;
  final List<Question> questions;
}

_PracticeFixture _fixture({
  required Map<int, int> questionsPerDomain,
  Set<int> ultraHardQuestionIds = const <int>{},
}) {
  final delivery = _FakePracticeDelivery();
  final questions = <Question>[];
  var id = 1;

  for (final entry in questionsPerDomain.entries) {
    final competencyId = 'd${entry.key.toString().padLeft(2, '0')}_c01';
    final competencyQuestions = <Question>[];

    for (var index = 0; index < entry.value; index++) {
      final question = _question(
        id: id,
        domain: entry.key,
        competencyId: competencyId,
        ultraHard: ultraHardQuestionIds.contains(id),
      );
      competencyQuestions.add(question);
      questions.add(question);
      id++;
    }

    delivery.questionsByCompetency[competencyId] = competencyQuestions;
  }

  return _PracticeFixture(
    quizService: QuizService(deliveryService: delivery),
    delivery: delivery,
    questions: List<Question>.unmodifiable(questions),
  );
}

void main() {
  test('Daily Challenge is stable for the same local calendar date', () async {
    final fixture = _fixture(questionsPerDomain: const <int, int>{1: 8, 2: 8});

    final service = PracticeModeService(
      quizService: fixture.quizService,
      questionProgressLoader: () async => <int, StudentQuestionProgress>{},
      now: () => DateTime(2026, 9, 16, 8),
      random: Random(1),
    );

    final first = await service.build(PracticeMode.dailyChallenge);
    final second = await service.build(PracticeMode.dailyChallenge);

    expect(first.questions.length, 5);
    expect(
      first.questions.map((question) => question.id).toList(),
      second.questions.map((question) => question.id).toList(),
    );
    expect(first.usedFallback, isFalse);
    expect(first.domainNumber, 0);
    expect(fixture.delivery.loadedCompetencies.toSet().length, 1);
  });

  test('Random Quiz returns ten unique published questions', () async {
    final fixture = _fixture(
      questionsPerDomain: const <int, int>{1: 10, 2: 10},
    );

    final service = PracticeModeService(
      quizService: fixture.quizService,
      questionProgressLoader: () async => <int, StudentQuestionProgress>{},
      random: Random(7),
    );

    final plan = await service.build(PracticeMode.randomQuiz);

    expect(plan.questions.length, 10);
    expect(plan.questions.map((question) => question.id).toSet().length, 10);
    expect(plan.usedFallback, isFalse);
    expect(plan.domainNumber, 0);
    expect(fixture.delivery.loadedCompetencies, hasLength(1));
  });

  test(
    'Ultra Hard mode uses only DQG300-classified published questions',
    () async {
      final fixture = _fixture(
        questionsPerDomain: const <int, int>{1: 8, 2: 8},
        ultraHardQuestionIds: const <int>{1, 2, 3, 4, 5, 9, 10},
      );

      final service = PracticeModeService(
        quizService: fixture.quizService,
        questionProgressLoader: () async => <int, StudentQuestionProgress>{},
        random: Random(11),
      );

      final plan = await service.build(PracticeMode.ultraHardExamReadiness);

      expect(plan.questions, hasLength(7));
      expect(
        plan.questions.every(
          (question) => question.tags.contains(
            UltraHardQuestionContract.classificationTag,
          ),
        ),
        isTrue,
      );
      expect(plan.title, contains('Exam Readiness'));
      expect(plan.notice, contains('300/300'));
      expect(plan.usedFallback, isFalse);
      expect(fixture.delivery.loadedCompetencies.toSet(), <String>{
        'd01_c01',
        'd02_c01',
      });
    },
  );

  test('Ultra Hard metadata sees newly available competency packages', () async {
    final fixture = _fixture(questionsPerDomain: const <int, int>{1: 1});
    final service = PracticeModeService(
      quizService: fixture.quizService,
      questionProgressLoader: () async => <int, StudentQuestionProgress>{},
      random: Random(3),
    );

    fixture.delivery.questionsByCompetency['d01_c01'] = <Question>[
      for (var index = 0; index < 5; index++)
        _question(
          id: 100 + index,
          domain: 1,
          competencyId: 'd01_c01',
          ultraHard: true,
        ),
    ];
    fixture.delivery.questionsByCompetency['d06_c04'] = <Question>[
      for (var index = 0; index < 5; index++)
        _question(
          id: 200 + index,
          domain: 6,
          competencyId: 'd06_c04',
          ultraHard: true,
        ),
    ];

    final plan = await service.build(PracticeMode.ultraHardExamReadiness);

    expect(plan.questions, hasLength(10));
    expect(
      plan.questions.where((question) => question.competencyId == 'd01_c01'),
      hasLength(5),
    );
    expect(
      plan.questions.where((question) => question.competencyId == 'd06_c04'),
      hasLength(5),
    );
  });

  test(
    'Ultra Hard mode fails closed when fewer than five are available',
    () async {
      final fixture = _fixture(
        questionsPerDomain: const <int, int>{1: 10},
        ultraHardQuestionIds: const <int>{1, 2, 3, 4},
      );

      final service = PracticeModeService(
        quizService: fixture.quizService,
        questionProgressLoader: () async => <int, StudentQuestionProgress>{},
      );

      await expectLater(
        service.build(PracticeMode.ultraHardExamReadiness),
        throwsStateError,
      );
      expect(fixture.delivery.loadedCompetencies, isEmpty);
    },
  );

  test('Weak Areas selects the lowest evidence-backed weak domain', () async {
    final fixture = _fixture(
      questionsPerDomain: const <int, int>{1: 10, 2: 10},
    );

    final domain1 = fixture.questions
        .where((question) => question.domain == 1)
        .toList();
    final domain2 = fixture.questions
        .where((question) => question.domain == 2)
        .toList();

    final progress = <int, StudentQuestionProgress>{};

    for (final question in domain1.take(5)) {
      progress[question.id] = _progress(question: question, everCorrect: true);
    }

    for (var index = 0; index < 5; index++) {
      final question = domain2[index];
      progress[question.id] = _progress(
        question: question,
        everCorrect: index == 0,
      );
    }

    final service = PracticeModeService(
      quizService: fixture.quizService,
      questionProgressLoader: () async => progress,
      random: Random(5),
    );

    final plan = await service.build(PracticeMode.weakAreas);

    expect(plan.usedFallback, isFalse);
    expect(plan.domainNumber, 2);
    expect(plan.questions.length, 10);
    expect(plan.questions.every((question) => question.domain == 2), isTrue);
    expect(plan.notice, contains('Domain 02'));
    expect(fixture.delivery.loadedCompetencies.toSet(), <String>{'d02_c01'});
  });

  test('Weak Areas clearly falls back when evidence is insufficient', () async {
    final fixture = _fixture(
      questionsPerDomain: const <int, int>{1: 10, 2: 10},
    );

    final progress = <int, StudentQuestionProgress>{};

    for (final question in fixture.questions.take(4)) {
      progress[question.id] = _progress(question: question, everCorrect: false);
    }

    final service = PracticeModeService(
      quizService: fixture.quizService,
      questionProgressLoader: () async => progress,
      random: Random(9),
    );

    final plan = await service.build(PracticeMode.weakAreas);

    expect(plan.usedFallback, isTrue);
    expect(plan.domainNumber, 0);
    expect(plan.questions.length, 10);
    expect(plan.notice, contains('not enough answered-question history'));
    expect(fixture.delivery.loadedCompetencies, hasLength(1));
  });

  test('Weak Areas falls back when no domain is below the threshold', () async {
    final fixture = _fixture(
      questionsPerDomain: const <int, int>{1: 10, 2: 10},
    );

    final progress = <int, StudentQuestionProgress>{};

    for (final question in fixture.questions.take(10)) {
      progress[question.id] = _progress(question: question, everCorrect: true);
    }

    final service = PracticeModeService(
      quizService: fixture.quizService,
      questionProgressLoader: () async => progress,
      random: Random(13),
    );

    final plan = await service.build(PracticeMode.weakAreas);

    expect(plan.usedFallback, isTrue);
    expect(plan.notice, contains('No evidence-backed weak domain'));
    expect(fixture.delivery.loadedCompetencies, hasLength(1));
  });
}
