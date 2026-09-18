import 'package:exam_platform/models/question.dart';
import 'package:exam_platform/models/student_question_progress.dart';
import 'package:exam_platform/services/cloud_question_repository.dart';
import 'package:exam_platform/services/practice/practice_mode_service.dart';
import 'package:exam_platform/services/quiz_service.dart';
import 'package:exam_platform/services/ultra_hard_question_contract.dart';
import 'package:exam_platform/services/study_content/cloud_content_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

Question _question({
  required int id,
  required int domain,
  bool ultraHard = false,
  String? competencyId,
}) {
  final domainId = domain.toString().padLeft(2, '0');
  final resolvedCompetencyId =
      competencyId ?? 'd${domainId}_c01';

  return Question(
    id: id,
    domain: domain,
    competencyId: resolvedCompetencyId,
    subtopicId: '${resolvedCompetencyId}_st01',
    topicId: '${resolvedCompetencyId}_t01',
    quizId: 'practice_$domainId',
    contentPackageId: 'content_$domainId',
    question:
        'A safety professional reviews a workplace scenario and must select the best available control for the identified risk.',
    options: const [
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
    tags: [
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

Future<QuizService> _quizService({
  required Map<int, int> questionsPerDomain,
  Set<int> ultraHardQuestionIds = const <int>{},
}) async {
  final firestore = FakeFirebaseFirestore();
  final questionRepository = CloudQuestionRepository(firestore: firestore);
  final contentRepository = CloudContentRepository(firestore: firestore);

  var id = 1;

  for (final entry in questionsPerDomain.entries) {
    for (var index = 0; index < entry.value; index++) {
      await questionRepository.save(
        _question(
          id: id,
          domain: entry.key,
          ultraHard: ultraHardQuestionIds.contains(id),
        ),
      );
      id++;
    }
  }

  return QuizService(
    questionRepository: questionRepository,
    contentRepository: contentRepository,
  );
}

void main() {
  test('Daily Challenge is stable for the same local calendar date', () async {
    final quizService = await _quizService(
      questionsPerDomain: const {1: 8, 2: 8},
    );

    final service = PracticeModeService(
      quizService: quizService,
      questionProgressLoader: () async => <int, StudentQuestionProgress>{},
      now: () => DateTime(2026, 9, 16, 8),
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
  });

  test('Random Quiz returns ten unique published questions', () async {
    final quizService = await _quizService(
      questionsPerDomain: const {1: 10, 2: 10},
    );

    final service = PracticeModeService(
      quizService: quizService,
      questionProgressLoader: () async => <int, StudentQuestionProgress>{},
    );

    final plan = await service.build(PracticeMode.randomQuiz);

    expect(plan.questions.length, 10);
    expect(plan.questions.map((question) => question.id).toSet().length, 10);
    expect(plan.usedFallback, isFalse);
    expect(plan.domainNumber, 0);
  });

  test(
    'Ultra Hard mode uses only DQG300-classified published questions',
    () async {
      final quizService = await _quizService(
        questionsPerDomain: const {1: 8, 2: 8},
        ultraHardQuestionIds: const {1, 2, 3, 4, 5, 9, 10},
      );

      final service = PracticeModeService(
        quizService: quizService,
        questionProgressLoader: () async => <int, StudentQuestionProgress>{},
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
    },
  );

  test(
    'Ultra Hard refresh sees newly published D01 C01 and D06 C04 questions',
    () async {
      final firestore = FakeFirebaseFirestore();
      final questionRepository = CloudQuestionRepository(firestore: firestore);
      final contentRepository = CloudContentRepository(firestore: firestore);
      final quizService = QuizService(
        questionRepository: questionRepository,
        contentRepository: contentRepository,
      );

      // Prime the shared-style catalogue before the Ultra Hard batches exist.
      await questionRepository.save(
        _question(id: 1, domain: 1, ultraHard: false),
      );
      await quizService.initialize();

      expect(
        quizService.getAllQuestions().where(
          (question) => question.tags.contains(
            UltraHardQuestionContract.classificationTag,
          ),
        ),
        isEmpty,
      );

      var id = 100;
      for (var index = 0; index < 5; index++) {
        await questionRepository.save(
          _question(
            id: id++,
            domain: 1,
            competencyId: 'd01_c01',
            ultraHard: true,
          ),
        );
      }
      for (var index = 0; index < 5; index++) {
        await questionRepository.save(
          _question(
            id: id++,
            domain: 6,
            competencyId: 'd06_c04',
            ultraHard: true,
          ),
        );
      }

      final plan = await PracticeModeService(
        quizService: quizService,
        questionProgressLoader: () async => <int, StudentQuestionProgress>{},
      ).build(PracticeMode.ultraHardExamReadiness);

      expect(plan.questions, hasLength(10));
      expect(
        plan.questions
            .where((question) => question.competencyId == 'd01_c01'),
        hasLength(5),
      );
      expect(
        plan.questions
            .where((question) => question.competencyId == 'd06_c04'),
        hasLength(5),
      );
      expect(
        plan.questions.every(
          (question) => question.tags.contains(
            UltraHardQuestionContract.classificationTag,
          ),
        ),
        isTrue,
      );
    },
  );

  test(
    'Ultra Hard mode fails closed when fewer than five are available',
    () async {
      final quizService = await _quizService(
        questionsPerDomain: const {1: 10},
        ultraHardQuestionIds: const {1, 2, 3, 4},
      );

      final service = PracticeModeService(
        quizService: quizService,
        questionProgressLoader: () async => <int, StudentQuestionProgress>{},
      );

      expect(
        () => service.build(PracticeMode.ultraHardExamReadiness),
        throwsA(isA<StateError>()),
      );
    },
  );

  test('Weak Areas selects the lowest evidence-backed weak domain', () async {
    final quizService = await _quizService(
      questionsPerDomain: const {1: 10, 2: 10},
    );

    await quizService.initialize();

    final questions = quizService.getAllQuestions();
    final domain1 = questions
        .where((question) => question.domain == 1)
        .toList();
    final domain2 = questions
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
      quizService: quizService,
      questionProgressLoader: () async => progress,
    );

    final plan = await service.build(PracticeMode.weakAreas);

    expect(plan.usedFallback, isFalse);
    expect(plan.domainNumber, 2);
    expect(plan.questions.length, 10);
    expect(plan.questions.every((question) => question.domain == 2), isTrue);
    expect(plan.notice, contains('Domain 02'));
  });

  test('Weak Areas clearly falls back when evidence is insufficient', () async {
    final quizService = await _quizService(
      questionsPerDomain: const {1: 10, 2: 10},
    );

    await quizService.initialize();

    final questions = quizService.getAllQuestions();
    final progress = <int, StudentQuestionProgress>{};

    for (final question in questions.take(4)) {
      progress[question.id] = _progress(question: question, everCorrect: false);
    }

    final service = PracticeModeService(
      quizService: quizService,
      questionProgressLoader: () async => progress,
    );

    final plan = await service.build(PracticeMode.weakAreas);

    expect(plan.usedFallback, isTrue);
    expect(plan.domainNumber, 0);
    expect(plan.questions.length, 10);
    expect(plan.notice, contains('not enough answered-question history'));
  });

  test('Weak Areas falls back when no domain is below the threshold', () async {
    final quizService = await _quizService(
      questionsPerDomain: const {1: 10, 2: 10},
    );

    await quizService.initialize();

    final questions = quizService.getAllQuestions();
    final progress = <int, StudentQuestionProgress>{};

    for (final question in questions.take(10)) {
      progress[question.id] = _progress(question: question, everCorrect: true);
    }

    final service = PracticeModeService(
      quizService: quizService,
      questionProgressLoader: () async => progress,
    );

    final plan = await service.build(PracticeMode.weakAreas);

    expect(plan.usedFallback, isTrue);
    expect(plan.notice, contains('No evidence-backed weak domain'));
  });
}
