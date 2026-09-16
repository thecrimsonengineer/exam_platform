import '../domain/learning_twin_domain.dart';
import 'learning_twin_practice_context.dart';

/// Converts sanitized practice-session metadata into one M3 candidate.
///
/// This bridge is pure and deterministic. It has no question-bank, Firebase,
/// persistence, navigation, clock, or random dependencies.
final class LearningTwinPracticeMessageBridge {
  const LearningTwinPracticeMessageBridge();

  LearningTwinMessage toCandidate({
    required LearningTwinPracticeContext practiceContext,
    required String screenId,
  }) {
    if (screenId.trim().isEmpty) {
      throw ArgumentError.value(screenId, 'screenId', 'must not be empty');
    }

    return LearningTwinMessage(
      id: _messageId(practiceContext),
      state: _stateFor(practiceContext),
      trigger: LearningTwinTrigger.screenVisit,
      title: _titleFor(practiceContext),
      body: _bodyFor(practiceContext),
      unsolicited: true,
      allowRepeat: false,
      priority: _priorityFor(practiceContext),
      screenId: screenId,
      domainId: practiceContext.domainId,
      competencyId: _clean(practiceContext.competencyId),
      subtopicId: _clean(practiceContext.subtopicId),
    );
  }

  String _messageId(LearningTwinPracticeContext context) {
    final scope = context.domainId ?? 'global';

    return switch (context.mode) {
      LearningTwinPracticeMode.dailyChallenge =>
        'm6-pre-practice-daily-$scope-v1',
      LearningTwinPracticeMode.randomQuiz => 'm6-pre-practice-random-$scope-v1',
      LearningTwinPracticeMode.weakAreas when context.usedFallback =>
        'm6-pre-practice-weak-fallback-v1',
      LearningTwinPracticeMode.weakAreas => 'm6-pre-practice-weak-$scope-v1',
      LearningTwinPracticeMode.customQuiz => 'm6-pre-practice-custom-$scope-v1',
    };
  }

  LearningTwinState _stateFor(LearningTwinPracticeContext context) {
    return switch (context.mode) {
      LearningTwinPracticeMode.weakAreas when !context.usedFallback =>
        LearningTwinState.remediate,
      LearningTwinPracticeMode.weakAreas => LearningTwinState.recommend,
      LearningTwinPracticeMode.dailyChallenge => LearningTwinState.encourage,
      LearningTwinPracticeMode.randomQuiz => LearningTwinState.encourage,
      LearningTwinPracticeMode.customQuiz => LearningTwinState.recommend,
    };
  }

  int _priorityFor(LearningTwinPracticeContext context) {
    return switch (context.mode) {
      LearningTwinPracticeMode.weakAreas when !context.usedFallback => 80,
      LearningTwinPracticeMode.weakAreas => 70,
      LearningTwinPracticeMode.dailyChallenge => 60,
      LearningTwinPracticeMode.customQuiz => 50,
      LearningTwinPracticeMode.randomQuiz => 40,
    };
  }

  String _titleFor(LearningTwinPracticeContext context) {
    return switch (context.mode) {
      LearningTwinPracticeMode.dailyChallenge => 'Today’s practice cue',
      LearningTwinPracticeMode.randomQuiz => 'Mixed practice cue',
      LearningTwinPracticeMode.weakAreas when context.usedFallback =>
        'Build more evidence',
      LearningTwinPracticeMode.weakAreas =>
        'Reinforce Domain ${_domainLabel(context.domainNumber)}',
      LearningTwinPracticeMode.customQuiz => 'Your practice plan',
    };
  }

  String _bodyFor(LearningTwinPracticeContext context) {
    final count = context.questionCount;

    return switch (context.mode) {
      LearningTwinPracticeMode.dailyChallenge =>
        '$count published ${_questionWord(count)} are ready for today. '
            'Work through the reasoning before checking each explanation.',
      LearningTwinPracticeMode.randomQuiz =>
        'This mixed set has $count published ${_questionWord(count)}. '
            'Treat each one as a fresh decision and avoid pattern guessing.',
      LearningTwinPracticeMode.weakAreas when context.usedFallback =>
        'There is not enough reliable performance evidence yet to identify '
            'a weak area, so this $count-question session uses a mixed '
            'published-question set. Your results will help build that evidence.',
      LearningTwinPracticeMode.weakAreas =>
        'This $count-question session is focused on Domain '
            '${_domainLabel(context.domainNumber)} because your saved '
            'performance history met the weak-area evidence threshold. '
            'Work through the reasoning before checking each explanation.',
      LearningTwinPracticeMode.customQuiz when context.domainNumber != null =>
        'You built a $count-question session for Domain '
            '${_domainLabel(context.domainNumber)}. Use each explanation '
            'to check the reasoning behind your answer.',
      LearningTwinPracticeMode.customQuiz =>
        'You built a $count-question session from the published CSP11 '
            'scope you selected. Use each explanation to check the reasoning '
            'behind your answer.',
    };
  }

  String _domainLabel(int? domainNumber) {
    final value = domainNumber;
    if (value == null) {
      return 'selected';
    }

    return value.toString().padLeft(2, '0');
  }

  String _questionWord(int count) => count == 1 ? 'question' : 'questions';

  String? _clean(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }
}
