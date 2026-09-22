import 'dart:math';

import '../../models/question.dart';
import '../../models/student_question_progress.dart';
import '../questions/published_question_package.dart';
import '../quiz_service.dart';
import '../student_question_progress_service.dart';
import '../ultra_hard_question_contract.dart';

enum PracticeMode {
  dailyChallenge,
  randomQuiz,
  weakAreas,
  ultraHardExamReadiness,
}

typedef QuestionProgressLoader =
    Future<Map<int, StudentQuestionProgress>> Function();

class PracticeSessionPlan {
  const PracticeSessionPlan({
    required this.mode,
    required this.title,
    required this.questions,
    required this.domainNumber,
    required this.notice,
    required this.usedFallback,
  });

  final PracticeMode mode;
  final String title;
  final List<Question> questions;
  final int domainNumber;
  final String notice;
  final bool usedFallback;

  int get questionCount => questions.length;
}

class PracticeModeService {
  PracticeModeService({
    QuizService? quizService,
    QuestionProgressLoader? questionProgressLoader,
    DateTime Function()? now,
    Random? random,
  }) : _quizService = quizService ?? QuizService.shared,
       _loadQuestionProgress =
           questionProgressLoader ?? _defaultQuestionProgressLoader,
       _now = now ?? DateTime.now,
       _random = random ?? Random();

  static const int dailyQuestionCount = 5;
  static const int randomQuestionCount = 10;
  static const int weakQuestionCount = 10;
  static const int ultraHardQuestionCount = 20;
  static const int ultraHardMinimumQuestionCount = 5;

  static const int minWeakDomainEvidence = 5;
  static const double weakMasteryThreshold = 0.65;

  final QuizService _quizService;
  final QuestionProgressLoader _loadQuestionProgress;
  final DateTime Function() _now;
  final Random _random;

  static Future<Map<int, StudentQuestionProgress>>
  _defaultQuestionProgressLoader() {
    return const StudentQuestionProgressService().loadAllProgress();
  }

  Future<PracticeSessionPlan> build(PracticeMode mode) async {
    final catalog = await _quizService.loadCatalogMetadata();

    if (catalog.isEmpty) {
      throw StateError(
        'No published CSP11 question packages are available for practice yet.',
      );
    }

    switch (mode) {
      case PracticeMode.dailyChallenge:
        return _buildDailyChallenge(catalog);
      case PracticeMode.randomQuiz:
        return _buildRandomQuiz(catalog);
      case PracticeMode.weakAreas:
        return _buildWeakAreas(catalog);
      case PracticeMode.ultraHardExamReadiness:
        return _buildUltraHardExamReadiness(catalog);
    }
  }

  Future<PracticeSessionPlan> _buildDailyChallenge(
    List<PublishedQuestionPackageDescriptor> catalog,
  ) async {
    final now = _now();
    final daySeed = now.year * 10000 + now.month * 100 + now.day;
    final rankedPackages = List<PublishedQuestionPackageDescriptor>.from(
      catalog,
    );

    rankedPackages.sort((left, right) {
      final leftRank = _textRank(left.competencyId, daySeed);
      final rightRank = _textRank(right.competencyId, daySeed);
      final rankCompare = leftRank.compareTo(rightRank);

      if (rankCompare != 0) {
        return rankCompare;
      }

      return left.competencyId.compareTo(right.competencyId);
    });

    final selected = _selectUntilQuestionCapacity(
      rankedPackages,
      dailyQuestionCount,
    );
    await _quizService.prepareCompetencies(
      selected.map((descriptor) => descriptor.competencyId),
    );

    final published = _quizService.getAllQuestions();
    final ranked = List<Question>.from(published);

    ranked.sort((left, right) {
      final leftRank = _dailyRank(left.id, daySeed);
      final rightRank = _dailyRank(right.id, daySeed);
      final rankCompare = leftRank.compareTo(rightRank);

      if (rankCompare != 0) {
        return rankCompare;
      }

      return left.id.compareTo(right.id);
    });

    final count = min(dailyQuestionCount, ranked.length);
    if (count == 0) {
      throw StateError('No published questions are available for today.');
    }

    final questions = ranked.take(count).toList(growable: false);

    return PracticeSessionPlan(
      mode: PracticeMode.dailyChallenge,
      title: 'Daily Challenge',
      questions: List<Question>.unmodifiable(questions),
      domainNumber: 0,
      notice:
          'Today’s $count-question challenge uses a bounded set of current '
          'CSP11 competency packages.',
      usedFallback: false,
    );
  }

  Future<PracticeSessionPlan> _buildRandomQuiz(
    List<PublishedQuestionPackageDescriptor> catalog,
  ) async {
    final shuffled = List<PublishedQuestionPackageDescriptor>.from(catalog)
      ..shuffle(_random);
    final selected = _selectUntilQuestionCapacity(
      shuffled,
      randomQuestionCount,
    );

    await _quizService.prepareCompetencies(
      selected.map((descriptor) => descriptor.competencyId),
      forceRefresh: true,
    );

    final published = _quizService.getAllQuestions();
    final count = min(randomQuestionCount, published.length);

    if (count == 0) {
      throw StateError('No published questions are available for Random Quiz.');
    }

    final questions = _quizService.buildQuiz(numberOfQuestions: count);

    return PracticeSessionPlan(
      mode: PracticeMode.randomQuiz,
      title: 'Random Quiz',
      questions: List<Question>.unmodifiable(questions),
      domainNumber: 0,
      notice:
          '$count published questions were mixed from a bounded randomized '
          'competency set.',
      usedFallback: false,
    );
  }

  Future<PracticeSessionPlan> _buildUltraHardExamReadiness(
    List<PublishedQuestionPackageDescriptor> catalog,
  ) async {
    final candidates = catalog
        .where((descriptor) => descriptor.ultraHardCount > 0)
        .toList(growable: true)
      ..sort((left, right) {
        final countCompare = right.ultraHardCount.compareTo(
          left.ultraHardCount,
        );

        if (countCompare != 0) {
          return countCompare;
        }

        return left.competencyId.compareTo(right.competencyId);
      });

    final selected = <PublishedQuestionPackageDescriptor>[];
    var discoveryCount = 0;

    for (final descriptor in candidates) {
      selected.add(descriptor);
      discoveryCount += descriptor.ultraHardCount;

      if (discoveryCount >= ultraHardQuestionCount) {
        break;
      }
    }

    if (discoveryCount < ultraHardMinimumQuestionCount) {
      throw StateError(
        'Ultra Hard Exam Readiness requires at least '
        '$ultraHardMinimumQuestionCount published DQG300 questions. '
        'Currently available: $discoveryCount.',
      );
    }

    await _quizService.prepareCompetencies(
      selected.map((descriptor) => descriptor.competencyId),
      forceRefresh: true,
    );

    final ultraHard = _quizService
        .getAllQuestions()
        .where(
          (question) => question.tags.any(
            (tag) =>
                tag.trim().toLowerCase() ==
                UltraHardQuestionContract.classificationTag,
          ),
        )
        .toList(growable: true);

    if (ultraHard.length < ultraHardMinimumQuestionCount) {
      throw StateError(
        'Ultra Hard package metadata did not match verified package content.',
      );
    }

    ultraHard.shuffle(_random);
    final count = min(ultraHardQuestionCount, ultraHard.length);
    final questions = ultraHard.take(count).toList(growable: false);

    return PracticeSessionPlan(
      mode: PracticeMode.ultraHardExamReadiness,
      title: 'Ultra Hard • Exam Readiness',
      questions: List<Question>.unmodifiable(questions),
      domainNumber: 0,
      notice:
          'This $count-question readiness session uses only verified questions '
          'that passed the strict DQG300 300/300 gate with DQS 100.',
      usedFallback: false,
    );
  }

  Future<PracticeSessionPlan> _buildWeakAreas(
    List<PublishedQuestionPackageDescriptor> catalog,
  ) async {
    final progress = await _loadQuestionProgress();
    final activeCompetencies = catalog
        .map((descriptor) => descriptor.competencyId)
        .toSet();

    final matched = progress.values
        .where(
          (record) =>
              record.domainNumber > 0 &&
              activeCompetencies.contains(record.competencyId.toLowerCase()),
        )
        .toList(growable: false);

    if (matched.length < minWeakDomainEvidence) {
      return _buildWeakFallback(
        catalog,
        'There is not enough answered-question history yet to identify a '
        'weak area reliably, so this session uses a bounded mixed quiz.',
      );
    }

    final byDomain = <int, List<StudentQuestionProgress>>{};

    for (final record in matched) {
      byDomain
          .putIfAbsent(record.domainNumber, () => <StudentQuestionProgress>[])
          .add(record);
    }

    final candidates = <_WeakDomainCandidate>[];

    for (final entry in byDomain.entries) {
      final records = entry.value;

      if (records.length < minWeakDomainEvidence) {
        continue;
      }

      final correct = records.where((record) => record.everCorrect).length;
      final mastery = correct / records.length;

      if (mastery >= weakMasteryThreshold) {
        continue;
      }

      candidates.add(
        _WeakDomainCandidate(
          domainNumber: entry.key,
          answeredQuestions: records.length,
          mastery: mastery,
        ),
      );
    }

    if (candidates.isEmpty) {
      return _buildWeakFallback(
        catalog,
        'No evidence-backed weak domain is currently below the review '
        'threshold, so this session uses a bounded mixed quiz.',
      );
    }

    candidates.sort((left, right) {
      final masteryCompare = left.mastery.compareTo(right.mastery);

      if (masteryCompare != 0) {
        return masteryCompare;
      }

      final evidenceCompare = right.answeredQuestions.compareTo(
        left.answeredQuestions,
      );

      if (evidenceCompare != 0) {
        return evidenceCompare;
      }

      return left.domainNumber.compareTo(right.domainNumber);
    });

    final target = candidates.first;
    final prefix = 'd${target.domainNumber.toString().padLeft(2, '0')}_';
    final domainPackages = catalog
        .where((descriptor) => descriptor.competencyId.startsWith(prefix))
        .toList(growable: false);

    final selected = _selectUntilQuestionCapacity(
      domainPackages,
      weakQuestionCount,
    );

    if (selected.isEmpty) {
      return _buildWeakFallback(
        catalog,
        'A weak area was detected, but no active package is currently '
        'available for that domain. This session uses a bounded mixed quiz.',
      );
    }

    await _quizService.prepareCompetencies(
      selected.map((descriptor) => descriptor.competencyId),
      forceRefresh: true,
    );

    final available = _quizService.getDomainQuestionCount(target.domainNumber);

    if (available < minWeakDomainEvidence) {
      return _buildWeakFallback(
        catalog,
        'A weak area was detected, but there are not enough currently '
        'published questions in that domain for a focused session. '
        'This session uses a bounded mixed quiz instead.',
      );
    }

    final count = min(weakQuestionCount, available);
    final questions = _quizService.getDomainQuiz(
      domain: target.domainNumber,
      numberOfQuestions: count,
    );

    return PracticeSessionPlan(
      mode: PracticeMode.weakAreas,
      title: 'Weak Areas',
      questions: List<Question>.unmodifiable(questions),
      domainNumber: target.domainNumber,
      notice:
          'This $count-question session focuses on Domain '
          '${target.domainNumber.toString().padLeft(2, '0')} using '
          '${target.answeredQuestions} answered questions as performance '
          'evidence.',
      usedFallback: false,
    );
  }

  Future<PracticeSessionPlan> _buildWeakFallback(
    List<PublishedQuestionPackageDescriptor> catalog,
    String reason,
  ) async {
    final ranked = List<PublishedQuestionPackageDescriptor>.from(catalog)
      ..sort((left, right) {
        final countCompare = right.publishedQuestionCount.compareTo(
          left.publishedQuestionCount,
        );

        if (countCompare != 0) {
          return countCompare;
        }

        return left.competencyId.compareTo(right.competencyId);
      });

    final selected = _selectUntilQuestionCapacity(ranked, weakQuestionCount);

    await _quizService.prepareCompetencies(
      selected.map((descriptor) => descriptor.competencyId),
      forceRefresh: true,
    );

    final published = _quizService.getAllQuestions();
    final count = min(weakQuestionCount, published.length);

    if (count == 0) {
      throw StateError('No published questions are available for Weak Areas.');
    }

    final questions = _quizService.buildQuiz(numberOfQuestions: count);

    return PracticeSessionPlan(
      mode: PracticeMode.weakAreas,
      title: 'Weak Areas',
      questions: List<Question>.unmodifiable(questions),
      domainNumber: 0,
      notice: reason,
      usedFallback: true,
    );
  }

  List<PublishedQuestionPackageDescriptor> _selectUntilQuestionCapacity(
    Iterable<PublishedQuestionPackageDescriptor> candidates,
    int requiredQuestions,
  ) {
    final selected = <PublishedQuestionPackageDescriptor>[];
    var capacity = 0;

    for (final descriptor in candidates) {
      if (descriptor.publishedQuestionCount <= 0) {
        continue;
      }

      selected.add(descriptor);
      capacity += descriptor.publishedQuestionCount;

      if (capacity >= requiredQuestions) {
        break;
      }
    }

    return List<PublishedQuestionPackageDescriptor>.unmodifiable(selected);
  }

  int _dailyRank(int questionId, int daySeed) {
    var value = (questionId * 1103515245 + daySeed * 12345) & 0x7fffffff;
    value = (value ^ (value >> 16)) & 0x7fffffff;
    return value;
  }

  int _textRank(String value, int seed) {
    var hash = seed & 0x7fffffff;

    for (final codeUnit in value.codeUnits) {
      hash = ((hash * 31) ^ codeUnit) & 0x7fffffff;
    }

    return hash;
  }
}

class _WeakDomainCandidate {
  const _WeakDomainCandidate({
    required this.domainNumber,
    required this.answeredQuestions,
    required this.mastery,
  });

  final int domainNumber;
  final int answeredQuestions;
  final double mastery;
}
