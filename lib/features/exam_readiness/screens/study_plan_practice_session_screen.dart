import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';

import '../../../app/theme.dart';
import '../../../features/learning_twin/coaching/learning_twin_practice_context.dart';
import '../../../features/learning_twin/integration/learning_twin_pre_practice_guidance.dart';
import '../../../models/question.dart';
import '../../../screens/courses/csp/quiz/quiz_screen.dart';
import '../../../services/quiz_service.dart';
import '../../../services/ultra_hard_question_contract.dart';
import '../models/study_plan_block.dart';
import '../models/study_plan_execution_target.dart';
import '../services/study_plan_completion_evidence_service.dart';

class StudyPlanPracticeSessionScreen extends StatefulWidget {
  const StudyPlanPracticeSessionScreen({
    super.key,
    required this.target,
    required this.isDarkMode,
    this.questionLoader,
    this.onSessionCompleted,
  });

  final StudyPlanExecutionTarget target;
  final bool isDarkMode;
  final Future<List<Question>> Function(StudyPlanExecutionTarget target)?
      questionLoader;
  final Future<void> Function()? onSessionCompleted;

  @override
  State<StudyPlanPracticeSessionScreen> createState() =>
      _StudyPlanPracticeSessionScreenState();
}

class _StudyPlanPracticeSessionScreenState
    extends State<StudyPlanPracticeSessionScreen> {
  late Future<List<Question>> _questionsFuture;

  @override
  void initState() {
    super.initState();
    _questionsFuture = _loadQuestions();
  }

  Future<List<Question>> _loadQuestions() {
    final loader = widget.questionLoader;
    if (loader != null) {
      return loader(widget.target);
    }
    return _loadPublishedQuestions(widget.target);
  }

  Future<List<Question>> _loadPublishedQuestions(
    StudyPlanExecutionTarget target,
  ) async {
    final service = QuizService();

    await service.prepareScope(
      domain: target.domainNumber,
      competencyId: target.competencyId,
      topicId: target.topicId,
      subtopicId: target.subtopicId,
    );

    if (target.blockType == StudyPlanBlockType.ultraHardPractice) {
      final candidates = service
          .getAllQuestions()
          .where(
            (question) => question.allTags.any(
              (tag) =>
                  tag.trim().toLowerCase() ==
                  UltraHardQuestionContract.classificationTag,
            ),
          )
          .toList(growable: true)
        ..shuffle();

      if (candidates.length < target.questionCount) {
        throw StateError(
          'Only ${candidates.length} verified Ultra Hard DQG300 questions are '
          'available for ${target.competencyId.toUpperCase()}. '
          '${target.questionCount} were planned.',
        );
      }

      return List<Question>.unmodifiable(
        candidates.take(target.questionCount).toList(growable: false),
      );
    }

    return List<Question>.unmodifiable(
      service.buildQuiz(
        domain: target.domainNumber,
        competencyId: target.competencyId,
        topicId: target.topicId,
        subtopicId: target.subtopicId,
        numberOfQuestions: target.questionCount,
      ),
    );
  }

  String get _sessionTitle {
    switch (widget.target.blockType) {
      case StudyPlanBlockType.diagnostic:
        return 'Planned Diagnostic';
      case StudyPlanBlockType.standardPractice:
        return 'Planned Practice';
      case StudyPlanBlockType.ultraHardPractice:
        return 'Ultra Hard • Planned Practice';
      case StudyPlanBlockType.mixedRetrieval:
        return 'Planned Mixed Retrieval';
      case StudyPlanBlockType.competencyRecheck:
        return 'Planned Competency Recheck';
      case StudyPlanBlockType.confidenceCalibration:
        return 'Planned Confidence Check';
      case StudyPlanBlockType.examSimulation:
        return 'Planned Exam Simulation';
      default:
        return 'Planned Practice';
    }
  }

  String get _sessionNotice =>
      '${widget.target.questionCount} questions • '
      '${widget.target.plannedMinutes} planned minutes • '
      '${widget.target.competencyId.toUpperCase()}';

  @override
  Widget build(BuildContext context) {
    final theme = widget.isDarkMode
        ? AppTheme.studentGlassDarkTheme
        : AppTheme.studentGlassLightTheme;

    return Theme(
      data: theme,
      child: FutureBuilder<List<Question>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return _PracticePreparationState(
              title: _sessionTitle,
              message: 'Preparing the published questions for this planned task.',
              isLoading: true,
            );
          }

          if (snapshot.hasError) {
            return _PracticePreparationState(
              title: 'Planned practice unavailable',
              message: snapshot.error
                  .toString()
                  .replaceFirst('Bad state: ', ''),
              actionLabel: 'Retry',
              onAction: () {
                setState(() => _questionsFuture = _loadQuestions());
              },
            );
          }

          final questions = snapshot.data ?? const <Question>[];
          if (questions.isEmpty) {
            return _PracticePreparationState(
              title: 'Planned practice unavailable',
              message:
                  'No published questions are available for this planned task.',
            );
          }

          final practiceContext = LearningTwinPracticeContext(
            mode: LearningTwinPracticeMode.customQuiz,
            questionCount: questions.length,
            domainNumber: widget.target.domainNumber,
            competencyId: widget.target.competencyId,
            subtopicId: widget.target.subtopicId,
          );

          return LearningTwinPracticeSessionHost(
            practiceContext: practiceContext,
            theme: theme,
            child: QuizScreen(
              domain: widget.target.domainNumber,
              customQuestions: questions,
              sessionTitle: _sessionTitle,
              sessionNotice: _sessionNotice,
              learningTwinPracticeContext: practiceContext,
              assessmentSessionKind:
                  StudyPlanCompletionEvidenceService.sessionKindForBlock(
                    widget.target.blockId,
                  ),
              onSessionCompleted: widget.onSessionCompleted,
            ),
          );
        },
      ),
    );
  }
}

class _PracticePreparationState extends StatelessWidget {
  const _PracticePreparationState({
    required this.title,
    required this.message,
    this.isLoading = false,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final bool isLoading;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return StudentGlassScaffold(
      key: const ValueKey('home-r6-practice-preparation'),
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(title),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: StudentGlassSurface(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                borderRadius: BorderRadius.circular(22),
                tint: scheme.surfaceContainerLow.withValues(alpha: 0.54),
                borderColor: scheme.outlineVariant.withValues(alpha: 0.62),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLoading)
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    else
                      Icon(
                        Icons.warning_amber_rounded,
                        color: scheme.primary,
                        size: 34,
                      ),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    if (actionLabel != null && onAction != null) ...[
                      const SizedBox(height: 14),
                      FilledButton.tonal(
                        onPressed: onAction,
                        child: Text(actionLabel!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
