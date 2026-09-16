import '../../../models/progress_analytics_snapshot.dart';
import 'learning_twin_progress_insight.dart';

abstract interface class LearningTwinProgressInterpreter {
  LearningTwinProgressInsight interpret(ProgressAnalyticsSnapshot snapshot);
}

/// Pure deterministic M5 progress interpreter.
///
/// No Firebase, persistence, current-time dependency, randomness, navigation,
/// UI or LLM is permitted in this service.
final class DeterministicLearningTwinProgressInterpreter
    implements LearningTwinProgressInterpreter {
  const DeterministicLearningTwinProgressInterpreter();

  static const int minimumQuestionsForAccuracySignal = 5;
  static const int minimumQuestionsForMastery = 10;
  static const double weakAccuracyThreshold = 0.65;
  static const double masteryAccuracyThreshold = 0.80;
  static const double masteryProgressThreshold = 0.90;
  static const int studiedSubtopicsBeforePracticePrompt = 3;
  static const int lowPracticeQuestionCount = 3;

  @override
  LearningTwinProgressInsight interpret(ProgressAnalyticsSnapshot snapshot) {
    if (_isMasteryPattern(snapshot)) {
      return const LearningTwinProgressInsight(
        type: LearningTwinProgressInsightType.masteryAcknowledgement,
        priority: 100,
        title: 'Strong progress pattern',
        body:
            'You have completed most of the available study path while '
            'maintaining strong practice accuracy. Keep consolidating weaker '
            'areas before adding unnecessary new material.',
      );
    }

    final weakDomain = _weakDomain(snapshot.domains);
    if (weakDomain != null) {
      final domainNumber = weakDomain.domainNumber.toString().padLeft(2, '0');
      return LearningTwinProgressInsight(
        type: LearningTwinProgressInsightType.weakDomainRemediation,
        priority: 90,
        title: 'Revisit Domain $domainNumber',
        body:
            'Practice accuracy in ${weakDomain.title} is below the current '
            'coaching threshold after ${weakDomain.answeredQuestions} answered '
            'questions. Review the learning material before another practice '
            'set.',
        domainId: weakDomain.domainId,
        domainNumber: weakDomain.domainNumber,
      );
    }

    if (snapshot.completedSubtopics >= studiedSubtopicsBeforePracticePrompt &&
        snapshot.answeredQuestions < lowPracticeQuestionCount) {
      return LearningTwinProgressInsight(
        type: LearningTwinProgressInsightType.addPractice,
        priority: 80,
        title: 'Add retrieval practice',
        body:
            'You have completed ${snapshot.completedSubtopics} subtopics but '
            'have very little question practice recorded. Use a short practice '
            'set to check what you can recall without looking back.',
      );
    }

    final activeDomain = _activeIncompleteDomain(snapshot.domains);
    if (activeDomain != null) {
      final domainNumber = activeDomain.domainNumber.toString().padLeft(2, '0');
      return LearningTwinProgressInsight(
        type: LearningTwinProgressInsightType.continueLearning,
        priority: 60,
        title: 'Continue Domain $domainNumber',
        body:
            'You already have progress in ${activeDomain.title}. Continue that '
            'learning path before spreading attention across more domains.',
        domainId: activeDomain.domainId,
        domainNumber: activeDomain.domainNumber,
      );
    }

    if (snapshot.completedSubtopics > 0 || snapshot.answeredQuestions > 0) {
      return const LearningTwinProgressInsight(
        type: LearningTwinProgressInsightType.continueLearning,
        priority: 50,
        title: 'Keep the learning-practice loop moving',
        body:
            'Continue with one focused study block, then use practice to check '
            'whether the key ideas can be recalled independently.',
      );
    }

    return const LearningTwinProgressInsight(
      type: LearningTwinProgressInsightType.startLearning,
      priority: 40,
      title: 'Start with one domain',
      body:
          'Choose one domain, complete a small learning section, and then use '
          'practice to check recall before moving wider.',
    );
  }

  bool _isMasteryPattern(ProgressAnalyticsSnapshot snapshot) {
    return snapshot.totalSubtopics > 0 &&
        snapshot.overallProgress >= masteryProgressThreshold &&
        snapshot.answeredQuestions >= minimumQuestionsForMastery &&
        snapshot.accuracy >= masteryAccuracyThreshold;
  }

  ProgressDomainAnalyticsSummary? _weakDomain(
    List<ProgressDomainAnalyticsSummary> domains,
  ) {
    final candidates = domains
        .where(
          (domain) =>
              domain.answeredQuestions >= minimumQuestionsForAccuracySignal &&
              domain.accuracy < weakAccuracyThreshold,
        )
        .toList(growable: false);

    if (candidates.isEmpty) {
      return null;
    }

    final ordered = candidates.toList()
      ..sort((a, b) {
        final byAccuracy = a.accuracy.compareTo(b.accuracy);
        if (byAccuracy != 0) return byAccuracy;

        final byEvidence = b.answeredQuestions.compareTo(a.answeredQuestions);
        if (byEvidence != 0) return byEvidence;

        return a.domainNumber.compareTo(b.domainNumber);
      });

    return ordered.first;
  }

  ProgressDomainAnalyticsSummary? _activeIncompleteDomain(
    List<ProgressDomainAnalyticsSummary> domains,
  ) {
    final candidates = domains
        .where(
          (domain) =>
              domain.totalSubtopics > 0 &&
              domain.completedSubtopics > 0 &&
              domain.completedSubtopics < domain.totalSubtopics,
        )
        .toList(growable: false);

    if (candidates.isEmpty) {
      return null;
    }

    final ordered = candidates.toList()
      ..sort((a, b) {
        final byProgress = b.progress.compareTo(a.progress);
        if (byProgress != 0) return byProgress;
        return a.domainNumber.compareTo(b.domainNumber);
      });

    return ordered.first;
  }
}
