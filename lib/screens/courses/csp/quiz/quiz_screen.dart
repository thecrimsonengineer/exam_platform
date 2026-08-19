import 'package:flutter/material.dart';

import '../../../../controllers/quiz_controller.dart';
import '../../../../models/question.dart';
import '../../../../services/bookmark_service.dart';
import '../../../../services/quiz_service.dart';

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
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  QuizController? controller;
  bool _isInitializing = true;
  String? _initializationError;

  final BookmarkService _bookmarkService = BookmarkService();

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

  Future<void> _toggleBookmark(int questionId) async {
    await _bookmarkService.toggleBookmark(questionId);

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

    setState(() {
      quizController.selectAnswer(index);
    });
  }

  void _submitAnswer() {
    final quizController = controller;
    if (quizController == null || quizController.submitted) return;
    if (quizController.selectedAnswer == null) return;

    setState(() {
      quizController.submitAnswer();
    });
  }

  void _nextQuestion() {
    final quizController = controller;
    if (quizController == null) return;

    if (!quizController.nextQuestion()) {
      _showResult();
      return;
    }

    setState(() {});
  }

  // ==========================================================
  // RESULT
  // ==========================================================

  Future<void> _showResult() async {
    final quizController = controller;
    if (quizController == null) return;

    final bookmarkedCount = await _bookmarkService.getBookmarkCount();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          domain: widget.domain,
          score: quizController.score,
          totalQuestions: quizController.totalQuestions,
          bookmarkedCount: bookmarkedCount,
          incorrectQuestions: quizController.incorrectQuestions,
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_initializationError != null) {
      return Scaffold(
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
      return Scaffold(
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

    return Scaffold(
      backgroundColor: QuizColors.background,

      // ======================================================
      // APP BAR
      // ======================================================
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: QuizColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'CSP11 Practice Quiz',
          style: TextStyle(fontWeight: FontWeight.w700),
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
            colors: [Color(0xFFF3F6FC), Color(0xFFF7F9FC), Color(0xFFF8F7FC)],
            stops: [0.0, 0.55, 1.0],
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
                          QuizHeader(
                            title: 'Training Needs Assessment',
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
                              const Expanded(
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
                                  _toggleBookmark(question.id);
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

                            if (question.tags.isNotEmpty) ...[
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
                                        const Expanded(
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
                                      children: question.tags.map((tag) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 7,
                                          ),
                                          decoration: BoxDecoration(
                                            color: QuizColors.primary
                                                .withValues(alpha: 0.07),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: QuizColors.primary
                                                  .withValues(alpha: 0.14),
                                            ),
                                          ),
                                          child: Text(
                                            tag,
                                            style: const TextStyle(
                                              color: QuizColors.textPrimary,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
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
                  border: const Border(
                    top: BorderSide(color: QuizColors.border),
                  ),
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
