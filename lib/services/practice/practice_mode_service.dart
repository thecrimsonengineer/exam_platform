import 'dart:math';

import '../../models/question.dart';
import '../../models/student_question_progress.dart';
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
  }) : _quizService = quizService ?? QuizService.shared,
       _loadQuestionProgress =
           questionProgressLoader ?? _defaultQuestionProgressLoader,
       _now = now ?? DateTime.now;

  static const int dailyQuestionCount = 5;
  static const int randomQuestionCount = 10;
  static const int weakQuestionCount = 10;
  static const int ultraHardQuestionCount = 20;
  static const int ultraHardMinimumQuestionCount = 5;

  // Keep the evidence boundary aligned with the existing M5 weak-domain
  // interpretation: at least five answered questions and mastery below 65%.
  static const int minWeakDomainEvidence = 5;
  static const double weakMasteryThreshold = 0.65;

  final QuizService _quizService;
  final QuestionProgressLoader _loadQuestionProgress;
  final DateTime Function() _now;

  static Future<Map<int, StudentQuestionProgress>>
  _defaultQuestionProgressLoader() {
    return const StudentQuestionProgressService().loadAllProgress();
  }

  Future<PracticeSessionPlan> build(PracticeMode mode) async {
    if (mode == PracticeMode.ultraHardExamReadiness) {
      // Ultra Hard questions can be published from the Admin Studio while
      // QuizService.shared is already initialized. Refresh this strict lane
      // before enforcing the five-question gate so newly published DQG300
      // questions are visible immediately without restarting the app.
      await _quizService.refresh();
    } else {
      await _quizService.initialize();
    }

    final published = _quizService.getAllQuestions();

    if (published.isEmpty) {
      throw StateError(
        'No published CSP11 questions are available for practice yet.',
      );
    }

    switch (mode) {
      case PracticeMode.dailyChallenge:
        return _buildDailyChallenge(published);
      case PracticeMode.randomQuiz:
        return _buildRandomQuiz(published);
      case PracticeMode.weakAreas:
        return _buildWeakAreas(published);
      case PracticeMode.ultraHardExamReadiness:
        return _buildUltraHardExamReadiness(published);
    }
  }

  PracticeSessionPlan _buildUltraHardExamReadiness(List<Question> published) {
    final ultraHard = published
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
        'Ultra Hard Exam Readiness requires at least '
        '$ultraHardMinimumQuestionCount published DQG300 questions. '
        'Currently available: ${ultraHard.length}.',
      );
    }

    ultraHard.shuffle();
    final count = min(ultraHardQuestionCount, ultraHard.length);
    final questions = ultraHard.take(count).toList(growable: false);

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

  PracticeSessionPlan _buildDailyChallenge(List<Question> published) {
    final now = _now();
    final daySeed = now.year * 10000 + now.month * 100 + now.day;
    final ranked = List<Question>.from(published);

    ranked.sort((a, b) {
      final aRank = _dailyRank(a.id, daySeed);
      final bRank = _dailyRank(b.id, daySeed);

      final rankCompare = aRank.compareTo(bRank);
      if (rankCompare != 0) {
        return rankCompare;
      }

      return a.id.compareTo(b.id);
    });

    final count = min(dailyQuestionCount, ranked.length);
    final questions = ranked.take(count).toList(growable: false);

    return PracticeSessionPlan(
      mode: PracticeMode.dailyChallenge,
      title: 'Daily Challenge',
      questions: List<Question>.unmodifiable(questions),
      domainNumber: 0,
      notice:
          'Today’s $count-question challenge is drawn from the published CSP11 question catalogue.',
      usedFallback: false,
    );
  }

  PracticeSessionPlan _buildRandomQuiz(List<Question> published) {
    final count = min(randomQuestionCount, published.length);
    final questions = _quizService.buildQuiz(numberOfQuestions: count);

    return PracticeSessionPlan(
      mode: PracticeMode.randomQuiz,
      title: 'Random Quiz',
      questions: List<Question>.unmodifiable(questions),
      domainNumber: 0,
      notice:
          '$count published questions were mixed across the available CSP11 catalogue.',
      usedFallback: false,
    );
  }

  Future<PracticeSessionPlan> _buildWeakAreas(List<Question> published) async {
    final progress = await _loadQuestionProgress();
    final publishedById = <int, Question>{
      for (final question in published) question.id: question,
    };

    final matched = progress.values
        .where((record) => publishedById.containsKey(record.questionId))
        .toList(growable: false);

    if (matched.length < minWeakDomainEvidence) {
      return _buildWeakFallback(
        published,
        'There is not enough answered-question history yet to identify a '
        'weak area reliably, so this session uses a mixed published quiz.',
      );
    }

    final byDomain = <int, List<StudentQuestionProgress>>{};

    for (final record in matched) {
      final currentQuestion = publishedById[record.questionId];
      final domain = currentQuestion?.domain ?? 0;

      if (domain <= 0) {
        continue;
      }

      byDomain
          .putIfAbsent(domain, () => <StudentQuestionProgress>[])
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
        published,
        'No evidence-backed weak domain is currently below the review '
        'threshold, so this session uses a mixed published quiz.',
      );
    }

    candidates.sort((a, b) {
      final masteryCompare = a.mastery.compareTo(b.mastery);
      if (masteryCompare != 0) {
        return masteryCompare;
      }

      final evidenceCompare = b.answeredQuestions.compareTo(
        a.answeredQuestions,
      );
      if (evidenceCompare != 0) {
        return evidenceCompare;
      }

      return a.domainNumber.compareTo(b.domainNumber);
    });

    final target = candidates.first;
    final available = _quizService.getDomainQuestionCount(target.domainNumber);

    if (available < minWeakDomainEvidence) {
      return _buildWeakFallback(
        published,
        'A weak area was detected, but there are not enough currently '
        'published questions in that domain for a focused session. '
        'This session uses a mixed published quiz instead.',
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
          '${target.answeredQuestions} answered questions as performance evidence.',
      usedFallback: false,
    );
  }

  PracticeSessionPlan _buildWeakFallback(
    List<Question> published,
    String reason,
  ) {
    final count = min(weakQuestionCount, published.length);
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
