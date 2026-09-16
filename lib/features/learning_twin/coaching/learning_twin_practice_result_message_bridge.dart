import '../domain/learning_twin_domain.dart';
import 'learning_twin_practice_context.dart';
import 'learning_twin_practice_result_context.dart';

/// Converts a sanitized practice result into one deterministic M3 candidate.
///
/// No Question objects, answer options, answer keys, explanations, references,
/// or incorrect-question objects enter this bridge.
final class LearningTwinPracticeResultMessageBridge {
  const LearningTwinPracticeResultMessageBridge();

  LearningTwinMessage toCandidate({
    required LearningTwinPracticeResultContext resultContext,
    required String screenId,
  }) {
    if (screenId.trim().isEmpty) {
      throw ArgumentError.value(screenId, 'screenId', 'must not be empty');
    }

    final band = _bandFor(resultContext);

    return LearningTwinMessage(
      id: _messageId(resultContext, band),
      state: _stateFor(band),
      trigger: LearningTwinTrigger.practiceCompleted,
      title: _titleFor(resultContext, band),
      body: _bodyFor(resultContext, band),
      unsolicited: true,
      allowRepeat: false,
      priority: _priorityFor(band),
      screenId: screenId,
      domainId: resultContext.practiceContext.domainId,
      competencyId: _clean(resultContext.practiceContext.competencyId),
      subtopicId: _clean(resultContext.practiceContext.subtopicId),
    );
  }

  _PracticeResultBand _bandFor(LearningTwinPracticeResultContext context) {
    if (context.isPerfect) {
      return _PracticeResultBand.perfect;
    }

    if (context.accuracy >= 0.80) {
      return _PracticeResultBand.strong;
    }

    if (context.accuracy >= 0.60) {
      return _PracticeResultBand.review;
    }

    return _PracticeResultBand.remediate;
  }

  LearningTwinState _stateFor(_PracticeResultBand band) {
    return switch (band) {
      _PracticeResultBand.perfect => LearningTwinState.celebrate,
      _PracticeResultBand.strong => LearningTwinState.resultReview,
      _PracticeResultBand.review => LearningTwinState.resultReview,
      _PracticeResultBand.remediate => LearningTwinState.remediate,
    };
  }

  int _priorityFor(_PracticeResultBand band) {
    return switch (band) {
      _PracticeResultBand.perfect => 90,
      _PracticeResultBand.remediate => 85,
      _PracticeResultBand.review => 75,
      _PracticeResultBand.strong => 70,
    };
  }

  String _messageId(
    LearningTwinPracticeResultContext context,
    _PracticeResultBand band,
  ) {
    final mode = context.practiceContext.mode.name;
    final scope = context.practiceContext.domainId ?? 'global';

    return 'm6-result-$mode-${band.name}-$scope-v1';
  }

  String _titleFor(
    LearningTwinPracticeResultContext context,
    _PracticeResultBand band,
  ) {
    if (context.practiceContext.mode == LearningTwinPracticeMode.weakAreas &&
        context.practiceContext.usedFallback) {
      return 'This result adds evidence';
    }

    return switch (band) {
      _PracticeResultBand.perfect => 'Clean sweep',
      _PracticeResultBand.strong => 'Strong practice result',
      _PracticeResultBand.review => 'Review the misses',
      _PracticeResultBand.remediate => 'Reinforce before moving on',
    };
  }

  String _bodyFor(
    LearningTwinPracticeResultContext context,
    _PracticeResultBand band,
  ) {
    final score = context.score;
    final total = context.totalQuestions;
    final misses = context.incorrectCount;
    final result = '$score of $total correct (${context.accuracyPercent}%).';

    if (context.practiceContext.mode == LearningTwinPracticeMode.weakAreas &&
        context.practiceContext.usedFallback) {
      return '$result This was a mixed fallback session because there was '
          'not enough reliable weak-area history. Treat this result as more '
          'performance evidence, not as proof that a particular Domain is weak.';
    }

    if (band == _PracticeResultBand.perfect) {
      return '$result You completed this published practice set without a '
          'miss. Review any bookmarks if needed, then continue when ready.';
    }

    final missWord = misses == 1 ? 'question' : 'questions';

    if (band == _PracticeResultBand.strong) {
      return '$result Review the $misses missed $missWord while the reasoning '
          'is fresh. A focused review is more useful than repeating answers '
          'from memory.';
    }

    if (band == _PracticeResultBand.review) {
      return '$result Work through the $misses missed $missWord and their '
          'explanations before another attempt. Focus on why each alternative '
          'was weaker than the best answer.';
    }

    if (context.practiceContext.hasFocusedWeakArea) {
      return '$result This focused weak-area session still needs '
          'reinforcement. Review the $misses missed $missWord, then retry the '
          'same set or return to Weak Areas for another focused session.';
    }

    return '$result Review the $misses missed $missWord and rebuild the '
        'reasoning before another attempt. Use Retry only after reviewing '
        'the explanations rather than memorising answer positions.';
  }

  String? _clean(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}

enum _PracticeResultBand { perfect, strong, review, remediate }
