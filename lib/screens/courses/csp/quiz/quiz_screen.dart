import 'dart:async';

import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';

import '../../../../controllers/quiz_controller.dart';
import '../../../../features/learning_twin/coaching/learning_twin_practice_context.dart';

import '../../../../models/question.dart';
import '../../../../services/bookmark_service.dart';
import '../../../../services/haptics/csp11_haptic_service.dart';
import '../../../../services/quiz_service.dart';
import '../../../../services/student_question_progress_service.dart';
import '../../../../services/settings/theme_mode_service.dart';

import '../study_content_screen.dart';
import '../study_content_screen_dark.dart';

import 'quiz_domain_label.dart';
import 'result/result_screen.dart';
import 'theme/quiz_colors.dart';
import 'theme/quiz_spacing.dart';
import 'widgets/answers/answer_list.dart';
import 'widgets/controls/bookmark_button.dart';
import 'widgets/controls/quiz_action_bar.dart';
import 'widgets/feedback/explanation_card.dart';
import 'widgets/feedback/reference_card.dart';
import 'widgets/header/quiz_header.dart';
import 'widgets/question/question_card.dart';

Widget buildCsp11QuizTagDestination({
  required bool isDarkMode,
  required String domainId,
  required String competencyId,
  required String domainTitle,
  required String loadingTitle,
  String? initialTopicId,
  String? initialSubtopicId,
}) {
  if (isDarkMode) {
    return DarkStudyContentScreen(
      domainId: domainId,
      competencyId: competencyId,
      domainTitle: domainTitle,
      loadingTitle: loadingTitle,
      initialTopicId: initialTopicId,
      initialSubtopicId: initialSubtopicId,
    );
  }

  return StudyContentScreen(
    domainId: domainId,
    competencyId: competencyId,
    domainTitle: domainTitle,
    loadingTitle: loadingTitle,
    initialTopicId: initialTopicId,
    initialSubtopicId: initialSubtopicId,
  );
}

class QuizScreen extends StatefulWidget {
  final int domain;
  final String? quizId;
  final String? competencyId;
  final String? subtopicId;
  final String? topicId;
  final List<Question>? customQuestions;
  final String? sessionTitle;
  final String? sessionNotice;
  final LearningTwinPracticeContext? learningTwinPracticeContext;

  const QuizScreen({
    super.key,
    required this.domain,
    this.quizId,
    this.competencyId,
    this.subtopicId,
    this.topicId,
    this.customQuestions,
    this.sessionTitle,
    this.sessionNotice,
    this.learningTwinPracticeContext,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  QuizController? controller;
  bool _isInitializing = true;
  String? _initializationError;

  final BookmarkService _bookmarkService = BookmarkService();
  final StudentQuestionProgressService _questionProgressService =
      const StudentQuestionProgressService();

  Set<int> _bookmarkedQuestions = <int>{};

  @override
  void initState() {
    super.initState();

    _initializeController();
    _loadBookmarks();
  }

  // ==========================================================
  // INITIALIZE QUIZ
  // ==========================================================

  Future<void> _initializeController() async {
    try {
      if (widget.customQuestions != null) {
        controller = QuizController.review(questions: widget.customQuestions!);
      } else {
        final quizService = QuizService();
        await quizService.initialize();

        if (widget.topicId != null) {
          controller = QuizController.byTopic(
            topicId: widget.topicId!,
            quizService: quizService,
          );
        } else if (widget.subtopicId != null) {
          controller = QuizController.bySubtopic(
            subtopicId: widget.subtopicId!,
            quizService: quizService,
          );
        } else if (widget.competencyId != null) {
          controller = QuizController.byCompetency(
            competencyId: widget.competencyId!,
            quizService: quizService,
          );
        } else if (widget.quizId != null) {
          controller = QuizController.byQuizId(
            quizId: widget.quizId!,
            quizService: quizService,
          );
        } else {
          controller = QuizController(
            domain: widget.domain,
            quizService: quizService,
          );
        }
      }
    } catch (error) {
      _initializationError = error.toString().replaceFirst('Bad state: ', '');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  // ==========================================================
  // BOOKMARKS
  // ==========================================================

  Future<void> _loadBookmarks() async {
    final bookmarks = await _bookmarkService.getBookmarkedQuestionIds();

    if (!mounted) return;

    setState(() {
      _bookmarkedQuestions = bookmarks;
    });
  }

  Future<void> _toggleBookmark(Question question) async {
    await _bookmarkService.toggleQuestion(question);

    final bookmarks = await _bookmarkService.getBookmarkedQuestionIds();

    if (!mounted) return;

    setState(() {
      _bookmarkedQuestions = bookmarks;
    });
  }

  // ==========================================================
  // ANSWERS
  // ==========================================================

  void _selectAnswer(int index) {
    final quizController = controller;
    if (quizController == null || quizController.submitted) return;
    if (quizController.selectedAnswer == index) return;

    setState(() {
      quizController.selectAnswer(index);
    });

    unawaited(Csp11Haptics.selection());
  }

  void _submitAnswer() {
    final quizController = controller;
    if (quizController == null || quizController.submitted) return;

    if (quizController.selectedAnswer == null) {
      unawaited(Csp11Haptics.error());
      return;
    }

    final question = quizController.currentQuestionData;
    final correct = quizController.isCorrectDisplayedOption(
      quizController.selectedAnswer!,
    );

    setState(() {
      quizController.submitAnswer();
    });

    unawaited(_emitQuizResultHaptics(correct));
    _recordQuestionCompletion(question, correct);
  }

  Future<void> _emitQuizResultHaptics(bool correct) async {
    await Csp11Haptics.confirm();
    await Future<void>.delayed(const Duration(milliseconds: 180));

    if (correct) {
      await Csp11Haptics.success();
    } else {
      await Csp11Haptics.warning();
    }
  }

  Future<void> _recordQuestionCompletion(
    Question question,
    bool correct,
  ) async {
    try {
      await _questionProgressService.recordAnswer(
        question: question,
        correct: correct,
      );
    } catch (_) {
      // Question-history persistence must never interrupt the active quiz.
    }
  }

  void _nextQuestion() {
    final quizController = controller;
    if (quizController == null) return;

    if (!quizController.nextQuestion()) {
      unawaited(Csp11Haptics.completion());
      _showResult();
      return;
    }

    unawaited(Csp11Haptics.navigation());
    setState(() {});
  }

  // ==========================================================
  // HIERARCHY TAG NAVIGATION
  // ==========================================================

  void _openHierarchyTag(Question question, String tag) {
    final hierarchyTags = question.navigationTags;
    final level = hierarchyTags.indexOf(tag);

    if (level < 0 || hierarchyTags.isEmpty) {
      return;
    }

    final domainId = 'd${question.domain.toString().padLeft(2, '0')}';
    final competencyId = question.competencyId.trim().isNotEmpty
        ? question.competencyId.trim()
        : hierarchyTags.first;

    String? initialTopicId;
    String? initialSubtopicId;

    if (level >= 1 && hierarchyTags.length >= 2) {
      initialTopicId = question.topicId.trim().isNotEmpty
          ? question.topicId.trim()
          : hierarchyTags[1];
    }

    if (level >= 2 && hierarchyTags.length >= 3) {
      initialSubtopicId = question.subtopicId.trim().isNotEmpty
          ? question.subtopicId.trim()
          : hierarchyTags[2];
    }

    final isDarkMode = ThemeModeService.isDarkMode.value;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => buildCsp11QuizTagDestination(
          isDarkMode: isDarkMode,
          domainId: domainId,
          competencyId: competencyId,
          domainTitle: csp11QuizDomainTitle(question.domain),
          loadingTitle: competencyId.toUpperCase(),
          initialTopicId: initialTopicId,
          initialSubtopicId: initialSubtopicId,
        ),
      ),
    );
  }
  // ==========================================================
  // RESULT
  // ==========================================================

  Future<void> _showResult() async {
    final quizController = controller;
    if (quizController == null) return;

    final bookmarkedCount = await _bookmarkService.getBookmarkCount();

    if (!mounted) return;

    final resultRouteTheme = Theme.of(context);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => Theme(
          data: resultRouteTheme,
          child: ResultScreen(
            domain: widget.domain,
            score: quizController.score,
            totalQuestions: quizController.totalQuestions,
            bookmarkedCount: bookmarkedCount,
            incorrectQuestions: quizController.incorrectQuestions,
            retryQuestions: widget.customQuestions,
            sessionTitle: widget.sessionTitle,
            sessionNotice: widget.sessionNotice,
            learningTwinPracticeContext: widget.learningTwinPracticeContext,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const StudentGlassScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_initializationError != null) {
      return StudentGlassScaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Unable to load published questions.\n$_initializationError',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final quizController = controller;
    if (quizController == null || quizController.questions.isEmpty) {
      return StudentGlassScaffold(
        backgroundColor: QuizColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: const Text('Quiz'),
        ),
        body: const Center(
          child: Text('No questions are available for this content.'),
        ),
      );
    }

    final Question question = quizController.currentQuestionData;

    final bool isBookmarked = _bookmarkedQuestions.contains(question.id);

    return StudentGlassScaffold(
      backgroundColor: QuizColors.background,

      // ======================================================
      // APP BAR
      // ======================================================
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: QuizColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.sessionTitle ?? 'CSP11 Practice Quiz',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      // ======================================================
      // BODY
      // ======================================================
      body: Container(
        decoration: BoxDecoration(gradient: QuizColors.pageGradient),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // ==================================================
              // SCROLLABLE CONTENT
              // ==================================================
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    QuizSpacing.pageHorizontal,
                    QuizSpacing.sm,
                    QuizSpacing.pageHorizontal,
                    QuizSpacing.xxxl,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ========================================
                          // QUIZ HEADER
                          // ========================================
                          if (widget.sessionNotice?.trim().isNotEmpty ==
                              true) ...[
                            Container(
                              key: const ValueKey('quiz-session-notice'),
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: QuizColors.surfaceAlt.withValues(
                                  alpha: 0.82,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: QuizColors.border.withValues(
                                    alpha: 0.82,
                                  ),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    color: QuizColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      widget.sessionNotice!,
                                      style: TextStyle(
                                        color: QuizColors.textSecondary,
                                        fontSize: 12.5,
                                        height: 1.45,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: QuizSpacing.md),
                          ],

                          QuizHeader(
                            title: csp11QuizDomainTitle(widget.domain),
                            questionNumber: quizController.questionNumber,
                            totalQuestions: quizController.totalQuestions,
                            progress: quizController.progress,
                            difficulty: question.difficulty,
                          ),

                          const SizedBox(height: QuizSpacing.lg),

                          // ========================================
                          // ANSWER INSTRUCTION + BOOKMARK
                          // ========================================
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  'Choose the best answer',
                                  style: TextStyle(
                                    color: QuizColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              BookmarkButton(
                                isBookmarked: isBookmarked,
                                onPressed: () {
                                  _toggleBookmark(question);
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: QuizSpacing.md),

                          // ========================================
                          // QUESTION
                          // ========================================
                          QuestionCard(
                            question: question.question,
                            questionNumber: quizController.questionNumber,
                          ),

                          const SizedBox(height: QuizSpacing.sectionGap),

                          // ========================================
                          // ANSWERS
                          // ========================================
                          AnswerList(
                            question: question,
                            controller: quizController,
                            onSelect: _selectAnswer,
                          ),

                          // ========================================
                          // FEEDBACK
                          // ========================================
                          if (quizController.submitted) ...[
                            const SizedBox(height: QuizSpacing.sectionGap),

                            ExplanationCard(explanation: question.explanation),

                            const SizedBox(height: QuizSpacing.md),

                            ReferenceCard(reference: question.reference),

                            if (question.allTags.isNotEmpty) ...[
                              const SizedBox(height: QuizSpacing.md),

                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  19,
                                  20,
                                  20,
                                ),
                                decoration: BoxDecoration(
                                  color: QuizColors.surfaceAlt.withValues(
                                    alpha: 0.72,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    QuizSpacing.cardRadius,
                                  ),
                                  border: Border.all(
                                    color: QuizColors.border.withValues(
                                      alpha: 0.85,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: QuizColors.primary
                                                .withValues(alpha: 0.075),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: QuizColors.primary
                                                  .withValues(alpha: 0.09),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.sell_outlined,
                                            color: QuizColors.primary,
                                            size: 21,
                                          ),
                                        ),
                                        const SizedBox(width: QuizSpacing.md),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'TAGS',
                                                style: TextStyle(
                                                  color: QuizColors.primary,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 1.0,
                                                ),
                                              ),
                                              SizedBox(height: 3),
                                              Text(
                                                'Key learning topics',
                                                style: TextStyle(
                                                  color: QuizColors.textMuted,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    Container(
                                      height: 1,
                                      width: double.infinity,
                                      color: QuizColors.border.withValues(
                                        alpha: 0.55,
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: question.allTags.map((tag) {
                                        final isNavigationTag = question
                                            .navigationTags
                                            .contains(tag);

                                        final chip = Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            key: ValueKey('quiz-tag-$tag'),
                                            onTap: isNavigationTag
                                                ? () => _openHierarchyTag(
                                                    question,
                                                    tag,
                                                  )
                                                : null,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 7,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isNavigationTag
                                                    ? QuizColors.violet
                                                          .withValues(
                                                            alpha: 0.13,
                                                          )
                                                    : QuizColors.primary
                                                          .withValues(
                                                            alpha: 0.07,
                                                          ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: isNavigationTag
                                                      ? QuizColors.violet
                                                            .withValues(
                                                              alpha: 0.44,
                                                            )
                                                      : QuizColors.primary
                                                            .withValues(
                                                              alpha: 0.14,
                                                            ),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    tag,
                                                    style: TextStyle(
                                                      color: isNavigationTag
                                                          ? QuizColors.violet
                                                          : QuizColors
                                                                .textPrimary,
                                                      fontSize: 12.5,
                                                      fontWeight:
                                                          isNavigationTag
                                                          ? FontWeight.w800
                                                          : FontWeight.w600,
                                                    ),
                                                  ),
                                                  if (isNavigationTag) ...[
                                                    const SizedBox(width: 6),
                                                    const Icon(
                                                      Icons.north_east_rounded,
                                                      color: QuizColors.violet,
                                                      size: 14,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ),
                                        );

                                        if (!isNavigationTag) {
                                          return chip;
                                        }

                                        return Tooltip(
                                          message: 'Open $tag in study content',
                                          child: chip,
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],

                          const SizedBox(height: QuizSpacing.xxxl),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ==================================================
              // BOTTOM ACTION BAR
              // ==================================================
              Container(
                padding: const EdgeInsets.fromLTRB(
                  QuizSpacing.pageHorizontal,
                  QuizSpacing.md,
                  QuizSpacing.pageHorizontal,
                  QuizSpacing.lg,
                ),
                decoration: BoxDecoration(
                  color: QuizColors.surface.withValues(alpha: 0.97),
                  border: Border(top: BorderSide(color: QuizColors.border)),
                  boxShadow: [
                    BoxShadow(
                      color: QuizColors.navy.withValues(alpha: 0.055),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: QuizActionBar(
                      submitted: quizController.submitted,
                      isLastQuestion: quizController.isLastQuestion,
                      onPressed: quizController.submitted
                          ? _nextQuestion
                          : _submitAnswer,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
