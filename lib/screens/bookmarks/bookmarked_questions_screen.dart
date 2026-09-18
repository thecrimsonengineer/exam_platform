import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';

import '../../models/question.dart';
import '../../services/bookmark_service.dart';
import '../courses/csp/quiz/quiz_domain_label.dart';
import '../courses/csp/quiz/quiz_screen.dart';

class BookmarkedQuestionsScreen extends StatefulWidget {
  final bool isDarkMode;

  const BookmarkedQuestionsScreen({super.key, required this.isDarkMode});

  @override
  State<BookmarkedQuestionsScreen> createState() =>
      _BookmarkedQuestionsScreenState();
}

class _BookmarkedQuestionsScreenState extends State<BookmarkedQuestionsScreen> {
  final BookmarkService _bookmarkService = BookmarkService();
  late Future<List<Question>> _bookmarksFuture;

  Color get _background =>
      widget.isDarkMode ? const Color(0xFF0A111D) : const Color(0xFFF3F6FC);
  Color get _surface =>
      widget.isDarkMode ? const Color(0xFF111B2C) : Colors.white;
  Color get _surfaceAlt =>
      widget.isDarkMode ? const Color(0xFF162238) : const Color(0xFFF7F9FC);
  Color get _textPrimary =>
      widget.isDarkMode ? const Color(0xFFF4F7FB) : const Color(0xFF18243A);
  Color get _textMuted =>
      widget.isDarkMode ? const Color(0xFFA5B1C4) : const Color(0xFF718096);
  Color get _border =>
      widget.isDarkMode ? const Color(0xFF25344A) : const Color(0xFFE1E7F0);
  Color get _accent =>
      widget.isDarkMode ? const Color(0xFFB596FF) : const Color(0xFF6941C6);
  Color get _accentSoft =>
      widget.isDarkMode ? const Color(0xFF251E45) : const Color(0xFFF1EBFF);

  @override
  void initState() {
    super.initState();
    _bookmarksFuture = _bookmarkService.getBookmarkedQuestions();
  }

  void _reload() {
    setState(() {
      _bookmarksFuture = _bookmarkService.getBookmarkedQuestions();
    });
  }

  Future<void> _removeBookmark(Question question) async {
    await _bookmarkService.removeBookmark(question.id);

    if (!mounted) {
      return;
    }

    _reload();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bookmark removed from this device.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openQuestion(Question question) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizScreen(
          domain: question.domain,
          customQuestions: <Question>[question],
          sessionTitle: 'Bookmarked Question',
          sessionNotice:
              'This question was recalled from your device-local bookmark cache.',
        ),
      ),
    );

    if (mounted) {
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StudentGlassScaffold(
      backgroundColor: _background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _background,
        foregroundColor: _textPrimary,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Bookmarked Questions',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: FutureBuilder<List<Question>>(
        future: _bookmarksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: _accent));
          }

          if (snapshot.hasError) {
            return _buildMessageState(
              icon: Icons.error_outline_rounded,
              title: 'Bookmarks are unavailable',
              message:
                  'The local bookmark cache could not be read. Try opening this page again.',
            );
          }

          final questions = snapshot.data ?? const <Question>[];

          if (questions.isEmpty) {
            return _buildMessageState(
              icon: Icons.bookmark_add_outlined,
              title: 'No saved questions yet',
              message:
                  'Use the bookmark icon beside a quiz question to save it locally on this device.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _bookmarksFuture;
            },
            child: ListView.separated(
              key: const ValueKey('bookmarked-question-list'),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 36),
              itemCount: questions.length + 1,
              separatorBuilder: (_, index) =>
                  SizedBox(height: index == 0 ? 16 : 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildIntro(questions.length);
                }

                return _buildQuestionCard(questions[index - 1]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildIntro(int count) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _accentSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.bookmarks_rounded, color: _accent, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count ${count == 1 ? 'QUESTION' : 'QUESTIONS'} SAVED',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.9,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Your personal question shelf',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'These question snapshots live in the learner app cache on this device. Opening this page does not require a fresh question-bank download.',
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 12,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Question question) {
    final navigationLabel = question.navigationTags.isEmpty
        ? question.competencyId.toUpperCase()
        : question.navigationTags.last.toUpperCase();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('bookmarked-question-${question.id}'),
            onTap: () => _openQuestion(question),
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: widget.isDarkMode ? 0.16 : 0.04,
                    ),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _accentSoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          navigationLabel,
                          style: TextStyle(
                            color: _accent,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          csp11QuizDomainTitle(question.domain),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        key: ValueKey(
                          'remove-bookmarked-question-${question.id}',
                        ),
                        tooltip: 'Remove bookmark',
                        onPressed: () => _removeBookmark(question),
                        icon: Icon(
                          Icons.bookmark_remove_rounded,
                          color: _accent,
                          size: 21,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  Text(
                    question.question,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 15,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(height: 1, color: _border),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _metaChip(Icons.speed_rounded, question.difficulty),
                      _metaChip(
                        Icons.psychology_alt_rounded,
                        question.cognitiveLevel,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: _accentSoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Review question',
                              style: TextStyle(
                                color: _accent,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: _accent,
                              size: 17,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String value) {
    final text = value.trim().isEmpty ? 'CSP11' : value.trim();

    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: _surfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _textMuted, size: 13),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _accentSoft,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: _accent, size: 30),
                ),
                const SizedBox(height: 17),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
