import 'package:flutter/material.dart';

import '../../../../controllers/quiz_controller.dart';
import '../../../../models/question.dart';
import '../../../../services/bookmark_service.dart';

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

class QuizScreen extends StatefulWidget {
  final int domain;
  final String? quizId;
  final String? competencyId;
  final String? subtopicId;
  final String? topicId;
  final List<Question>? customQuestions;

  const QuizScreen({
    super.key,
    required this.domain,
    this.quizId,
    this.competencyId,
    this.subtopicId,
    this.topicId,
    this.customQuestions,
  });

  @override
  State<QuizScreen> createState() =>
      _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late QuizController controller;

  final BookmarkService _bookmarkService =
      BookmarkService();

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

  void _initializeController() {
    if (widget.customQuestions != null) {
      controller = QuizController.review(
        questions: widget.customQuestions!,
      );
    } else if (widget.topicId != null) {
      controller = QuizController.byTopic(
        topicId: widget.topicId!,
      );
    } else if (widget.subtopicId != null) {
      controller = QuizController.bySubtopic(
        subtopicId: widget.subtopicId!,
      );
    } else if (widget.competencyId != null) {
      controller = QuizController.byCompetency(
        competencyId: widget.competencyId!,
      );
    } else if (widget.quizId != null) {
      controller = QuizController.byQuizId(
        quizId: widget.quizId!,
      );
    } else {
      controller = QuizController(
        domain: widget.domain,
      );
    }
  }

  // ==========================================================
  // BOOKMARKS
  // ==========================================================

  Future<void> _loadBookmarks() async {
    final bookmarks =
        await _bookmarkService
            .getBookmarkedQuestionIds();

    if (!mounted) return;

    setState(() {
      _bookmarkedQuestions = bookmarks;
    });
  }

  Future<void> _toggleBookmark(
    int questionId,
  ) async {
    await _bookmarkService.toggleBookmark(
      questionId,
    );

    final bookmarks =
        await _bookmarkService
            .getBookmarkedQuestionIds();

    if (!mounted) return;

    setState(() {
      _bookmarkedQuestions = bookmarks;
    });
  }

  // ==========================================================
  // ANSWERS
  // ==========================================================

  void _selectAnswer(int index) {
    if (controller.submitted) return;

    setState(() {
      controller.selectAnswer(index);
    });
  }

  void _submitAnswer() {
    if (controller.submitted) return;
    if (controller.selectedAnswer == null) return;

    setState(() {
      controller.submitAnswer();
    });
  }

  void _nextQuestion() {
    if (!controller.nextQuestion()) {
      _showResult();
      return;
    }

    setState(() {});
  }

  // ==========================================================
  // RESULT
  // ==========================================================

  Future<void> _showResult() async {
    final bookmarkedCount =
        await _bookmarkService.getBookmarkCount();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          domain: widget.domain,
          score: controller.score,
          totalQuestions:
              controller.totalQuestions,
          bookmarkedCount: bookmarkedCount,
          incorrectQuestions:
              controller.incorrectQuestions,
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    if (controller.questions.isEmpty) {
      return Scaffold(
        backgroundColor: QuizColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: const Text('Quiz'),
        ),
        body: const Center(
          child: Text(
            'No questions are available for this content.',
          ),
        ),
      );
    }

    final Question question =
        controller.currentQuestionData;

    final bool isBookmarked =
        _bookmarkedQuestions.contains(
      question.id,
    );

    return Scaffold(
      backgroundColor: QuizColors.background,

      // ======================================================
      // APP BAR
      // ======================================================

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor:
            QuizColors.textPrimary,
        elevation: 0,
        surfaceTintColor:
            Colors.transparent,
        title: const Text(
          'CSP11 Practice Quiz',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ======================================================
      // BODY
      // ======================================================

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF3F6FC),
              Color(0xFFF7F9FC),
              Color(0xFFF8F7FC),
            ],
            stops: [
              0.0,
              0.55,
              1.0,
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // ==================================================
              // SCROLLABLE CONTENT
              // ==================================================

              Expanded(
                child: SingleChildScrollView(
                  physics:
                      const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.fromLTRB(
                    QuizSpacing.pageHorizontal,
                    QuizSpacing.sm,
                    QuizSpacing.pageHorizontal,
                    QuizSpacing.xxxl,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(
                        maxWidth: 1100,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          // ========================================
                          // QUIZ HEADER
                          // ========================================

                          QuizHeader(
                            title:
                                'Training Needs Assessment',
                            questionNumber:
                                controller
                                    .questionNumber,
                            totalQuestions:
                                controller
                                    .totalQuestions,
                            progress:
                                controller.progress,
                            difficulty:
                                question.difficulty,
                          ),

                          const SizedBox(
                            height: QuizSpacing.lg,
                          ),

                          // ========================================
                          // ANSWER INSTRUCTION + BOOKMARK
                          // ========================================

                          Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.center,
                            children: [
                              const Expanded(
                                child: Text(
                                  'Choose the best answer',
                                  style: TextStyle(
                                    color: QuizColors
                                        .textPrimary,
                                    fontSize: 15,
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 12,
                              ),
                              BookmarkButton(
                                isBookmarked:
                                    isBookmarked,
                                onPressed: () {
                                  _toggleBookmark(
                                    question.id,
                                  );
                                },
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: QuizSpacing.md,
                          ),

                          // ========================================
                          // QUESTION
                          // ========================================

                          QuestionCard(
                            question:
                                question.question,
                            questionNumber:
                                controller
                                    .questionNumber,
                          ),

                          const SizedBox(
                            height:
                                QuizSpacing.sectionGap,
                          ),

                          // ========================================
                          // ANSWERS
                          // ========================================

                          AnswerList(
                            question: question,
                            controller: controller,
                            onSelect:
                                _selectAnswer,
                          ),

                          // ========================================
                          // FEEDBACK
                          // ========================================

                          if (controller.submitted) ...[
                            const SizedBox(
                              height:
                                  QuizSpacing.sectionGap,
                            ),

                            ExplanationCard(
                              explanation:
                                  question.explanation,
                            ),

                            const SizedBox(
                              height: QuizSpacing.md,
                            ),

                            ReferenceCard(
                              reference:
                                  question.reference,
                            ),
                          ],

                          const SizedBox(
                            height: QuizSpacing.xxxl,
                          ),
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
                padding:
                    const EdgeInsets.fromLTRB(
                  QuizSpacing.pageHorizontal,
                  QuizSpacing.md,
                  QuizSpacing.pageHorizontal,
                  QuizSpacing.lg,
                ),
                decoration: BoxDecoration(
                  color: QuizColors.surface
                      .withValues(
                    alpha: 0.97,
                  ),
                  border: const Border(
                    top: BorderSide(
                      color: QuizColors.border,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          QuizColors.navy.withValues(
                        alpha: 0.055,
                      ),
                      blurRadius: 16,
                      offset:
                          const Offset(0, -4),
                    ),
                  ],
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(
                      maxWidth: 1100,
                    ),
                    child: QuizActionBar(
                      submitted:
                          controller.submitted,
                      isLastQuestion:
                          controller
                              .isLastQuestion,
                      onPressed:
                          controller.submitted
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