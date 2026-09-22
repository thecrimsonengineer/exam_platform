import 'dart:math';

import '../../models/question.dart';
import '../../models/student_question_progress.dart';
import '../questions/learner_question_package_delivery_service.dart';
import '../questions/published_question_package.dart';
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
    LearnerQuestionPackageDeliveryService? deliveryService,
    QuestionProgressLoader? questionProgressLoader,
    DateTime Function()? now,
    Random? random,
  }) : _deliveryService =
           deliveryService ?? LearnerQuestionPackageDeliveryService(),
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

  final LearnerQuestionPackageDeliveryService _deliveryService;
  final QuestionProgressLoader _loadQuestionProgress;
  final DateTime Function() _now;
  final Random _random;

  static Future<Map<int, StudentQuestionProgress>>
  _defaultQuestionProgressLoader() {
    return const StudentQuestionProgressService().loadAllProgress();
  }

  Future<PracticeSessionPlan> build(PracticeMode mode) async {
    final catalog = (await _deliveryService.loadCatalog())
        .where((descriptor) => descriptor.publishedQuestionCount > 0)
        .toList(growable: false);

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
    final ordered = List<PublishedQuestionPackageDescriptor>.from(catalog);

    ordered.sort((left, right) {
      final leftRank = _dailyCompetencyRank(left.competencyId, daySeed);
      final rightRank = _dailyCompetencyRank(right.competencyId, daySeed);
      final rankCompare = leftRank.compareTo(rightRank);

      if (rankCompare != 0) {
        return rankCompare;
      }

      return left.competencyId.compareTo(right.competencyId);
    });

    final published = await _loadUntilQuestionCount(
      ordered,
      dailyQuestionCount,
    );

    if (published.isEmpty) {
      throw StateError(
        'No published CSP11 questions are available for today’s challenge.',
      );
    }

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
    final questions = ranked.take(count).toList(growable: false);

    return PracticeSessionPlan(
      mode: PracticeMode.dailyChallenge,
      title: 'Daily Challenge',
      questions: List<Question>.unmodifiable(questions),
      domainNumber: 0,
      notice:
          'Today’s $count-question challenge uses a bounded selection of '
          'published CSP11 competency packages.',
      usedFallback: false,
    );
  }

  Future<PracticeSessionPlan> _buildRandomQuiz(
    List<PublishedQuestionPackageDescriptor> catalog,
  ) async {
    final ordered = List<PublishedQuestionPackageDescriptor>.from(catalog)
      ..shuffle(_random);

    final published = await _loadUntilQuestionCount(
      ordered,
      randomQuestionCount,
    );

    if (published.isEmpty) {
      throw StateError(
        'No published CSP11 questions are available for random practice.',
      );
    }

    final shuffled = List<Question>.from(published)..shuffle(_random);
    final count = min(randomQuestionCount, shuffled.length);
    final questions = shuffled.take(count).toList(growable: false);

    return PracticeSessionPlan(
      mode: PracticeMode.randomQuiz,
      title: 'Random Quiz',
      questions: List<Question>.unmodifiable(questions),
      domainNumber: 0,
      notice:
          '$count published questions were selected from only the competency '
          'packages needed for this session.',
      usedFallback: false,
    );
  }

  Future<PracticeSessionPlan> _buildUltraHardExamReadiness(
    List<PublishedQuestionPackageDescriptor> catalog,
  ) async {
    final candidates =
        catalog
            .where((descriptor) => descriptor.ultraHardCount > 0)
            .toList(growable: false)
          ..sort(
            (left, right) => left.competencyId.compareTo(right.competencyId),
          );

    final advertisedUltraHard = candidates.fold<int>(
      0,
      (total, descriptor) => total + descriptor.ultraHardCount,
    );

    if (advertisedUltraHard < ultraHardMinimumQuestionCount) {
      throw StateError(
        'Ultra Hard Exam Readiness requires at least '
        '$ultraHardMinimumQuestionCount published DQG300 questions. '
        'Currently available: $advertisedUltraHard.',
      );
    }

    final ultraHard = <int, Question>{};

    for (final descriptor in candidates) {
      final questions = await _deliveryService.loadCompetency(
        descriptor.competencyId,
      );

      for (final question in questions) {
        if (_isUltraHard(question)) {
          ultraHard.putIfAbsent(question.id, () => question);
        }
      }

      if (ultraHard.length >= ultraHardQuestionCount) {
        break;
      }
    }

    if (ultraHard.length < ultraHardMinimumQuestionCount) {
      throw StateError(
        'Ultra Hard Exam Readiness requires at least '
        '$ultraHardMinimumQuestionCount verified DQG300 questions. '
        'Currently available: ${ultraHard.length}.',
      );
    }

    final shuffled = ultraHard.values.toList(growable: true)..shuffle(_random);
    final count = min(ultraHardQuestionCount, shuffled.length);
    final questions = shuffled.take(count).toList(growable: false);

    return PracticeSessionPlan(
      mode: PracticeMode.ultraHardExamReadiness,
      title: 'Ultra Hard • Exam Readiness',
      questions: List<Question>.unmodifiable(questions),
      domainNumber: 0,
      notice:
          'This $count-question readiness session uses only questions that '
          'passed the strict DQG300 300/300 gate with DQS 100.',
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
              activeCompetencies.contains(record.competencyId.trim()) &&
              record.domainNumber > 0,
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
    final domainCatalog = catalog
        .where(
          (descriptor) =>
              _domainNumberForCompetency(descriptor.competencyId) ==
              target.domainNumber,
        )
        .toList(growable: false);

    final advertised = domainCatalog.fold<int>(
      0,
      (total, descriptor) => total + descriptor.publishedQuestionCount,
    );

    if (advertised < minWeakDomainEvidence) {
      return _buildWeakFallback(
        catalog,
        'A weak area was detected, but there are not enough currently '
        'published questions in that domain for a focused session. '
        'This session uses a bounded mixed quiz instead.',
      );
    }

    final published = await _loadUntilQuestionCount(
      domainCatalog,
      weakQuestionCount,
    );
    final domainQuestions = published
        .where((question) => question.domain == target.domainNumber)
        .toList(growable: true);

    if (domainQuestions.length < minWeakDomainEvidence) {
      return _buildWeakFallback(
        catalog,
        'A weak area was detected, but the verified package data did not '
        'contain enough questions for a focused session. '
        'This session uses a bounded mixed quiz instead.',
      );
    }

    domainQuestions.shuffle(_random);
    final count = min(weakQuestionCount, domainQuestions.length);
    final questions = domainQuestions.take(count).toList(growable: false);

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
    final ordered = List<PublishedQuestionPackageDescriptor>.from(catalog)
      ..shuffle(_random);
    final published = await _loadUntilQuestionCount(ordered, weakQuestionCount);

    if (published.isEmpty) {
      throw StateError(
        'No published CSP11 questions are available for weak-area fallback.',
      );
    }

    final shuffled = List<Question>.from(published)..shuffle(_random);
    final count = min(weakQuestionCount, shuffled.length);
    final questions = shuffled.take(count).toList(growable: false);

    return PracticeSessionPlan(
      mode: PracticeMode.weakAreas,
      title: 'Weak Areas',
      questions: List<Question>.unmodifiable(questions),
      domainNumber: 0,
      notice: reason,
      usedFallback: true,
    );
  }

  Future<List<Question>> _loadUntilQuestionCount(
    Iterable<PublishedQuestionPackageDescriptor> descriptors,
    int requestedCount,
  ) async {
    final merged = <int, Question>{};

    for (final descriptor in descriptors) {
      if (descriptor.publishedQuestionCount <= 0) {
        continue;
      }

      final questions = await _deliveryService.loadCompetency(
        descriptor.competencyId,
      );

      for (final question in questions) {
        if (question.id <= 0 ||
            question.status.trim().toLowerCase() != 'published') {
          continue;
        }

        merged.putIfAbsent(question.id, () => question);
      }

      if (merged.length >= requestedCount) {
        break;
      }
    }

    final questions = merged.values.toList()
      ..sort((left, right) => left.id.compareTo(right.id));

    return List<Question>.unmodifiable(questions);
  }

  bool _isUltraHard(Question question) {
    return question.tags.any(
      (tag) =>
          tag.trim().toLowerCase() ==
          UltraHardQuestionContract.classificationTag,
    );
  }

  int _domainNumberForCompetency(String competencyId) {
    final match = RegExp(
      r'^d(\d{2})_c\d{2}$',
    ).firstMatch(competencyId.trim().toLowerCase());

    return match == null ? 0 : int.tryParse(match.group(1)!) ?? 0;
  }

  int _dailyCompetencyRank(String competencyId, int daySeed) {
    var hash = daySeed & 0x7fffffff;

    for (final codeUnit in competencyId.codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7fffffff;
    }

    return hash;
  }

  int _dailyRank(int questionId, int daySeed) {
    var value = (questionId * 1103515245 + daySeed * 12345) & 0x7fffffff;
    value = (value ^ (value >> 16)) & 0x7fffffff;
    return value;
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
