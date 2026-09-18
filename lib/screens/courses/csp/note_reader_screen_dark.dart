import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';

import '../../../controllers/note_controller.dart';
import '../../../models/note.dart';

class DarkNoteReaderScreen extends StatelessWidget {
  final NoteController controller;

  const DarkNoteReaderScreen({super.key, required this.controller});

  static const _bg = Color(0xFF0A111D);
  static const _surface = Color(0xFF111B2C);
  static const _border = Color(0xFF25344A);
  static const _textPrimary = Color(0xFFF4F7FB);
  static const _textSecondary = Color(0xFFC4CDDA);
  static const _textMuted = Color(0xFFA5B1C4);
  static const _blue = Color(0xFF6EA8FF);

  @override
  Widget build(BuildContext context) {
    final Note? note = controller.selectedNote;

    if (note == null) {
      return const StudentGlassScaffold(
        backgroundColor: _bg,
        body: Center(
          child: Text(
            'Study note not found.',
            style: TextStyle(color: _textSecondary),
          ),
        ),
      );
    }

    return StudentGlassScaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(note.title),
        backgroundColor: _bg,
        foregroundColor: _textPrimary,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.bookmark_border)),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 28,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 18, color: _textMuted),
                      const SizedBox(width: 6),
                      Text(
                        '${note.estimatedReadTime} min read',
                        style: const TextStyle(color: _textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (note.learningObjectives.isNotEmpty)
                    _listCard(
                      title: 'Learning Objectives',
                      icon: Icons.check_circle_outline,
                      accent: const Color(0xFF4CC38A),
                      values: note.learningObjectives,
                    ),
                  if (note.mainContent.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _paragraphCard(
                      title: 'Main Content',
                      values: note.mainContent,
                    ),
                  ],
                  if (note.keyPoints.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _listCard(
                      title: 'Key Points',
                      icon: Icons.check_circle,
                      accent: _blue,
                      values: note.keyPoints,
                    ),
                  ],
                  if (note.examples.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _listCard(
                      title: 'Examples',
                      icon: Icons.lightbulb_outline,
                      accent: const Color(0xFF78AEF3),
                      values: note.examples,
                      tinted: const Color(0xFF14243B),
                    ),
                  ],
                  if (note.examTips.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _listCard(
                      title: 'CSP Exam Tips',
                      icon: Icons.emoji_events,
                      accent: const Color(0xFFF0B44D),
                      values: note.examTips,
                      tinted: const Color(0xFF2A2113),
                    ),
                  ],
                  if (note.commonMistakes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _listCard(
                      title: 'Common Mistakes',
                      icon: Icons.warning_amber_rounded,
                      accent: const Color(0xFFFF8A65),
                      values: note.commonMistakes,
                      tinted: const Color(0xFF2B171C),
                    ),
                  ],
                  if (note.references.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _listCard(
                      title: 'References',
                      icon: Icons.menu_book_rounded,
                      accent: const Color(0xFF9FA8FF),
                      values: note.references,
                      tinted: const Color(0xFF1B1D36),
                      selectable: true,
                    ),
                  ],
                  if (note.keyTakeaways.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _listCard(
                      title: 'Key Takeaways',
                      icon: Icons.flag_circle,
                      accent: const Color(0xFF4CC38A),
                      values: note.keyTakeaways,
                      tinted: const Color(0xFF10291F),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: note.relatedQuestionIds.isEmpty ? null : () {},
                      icon: const Icon(Icons.quiz),
                      label: Text(
                        note.relatedQuestionIds.isEmpty
                            ? 'No Practice Questions Available'
                            : 'Practice Questions (${note.relatedQuestionIds.length})',
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _paragraphCard({required String title, required List<String> values}) {
    return _baseCard(
      title: title,
      icon: Icons.menu_book_rounded,
      accent: _blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: values
            .map(
              (value) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: SelectableText(
                  value,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 16,
                    height: 1.7,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _listCard({
    required String title,
    required IconData icon,
    required Color accent,
    required List<String> values,
    Color? tinted,
    bool selectable = false,
  }) {
    return _baseCard(
      title: title,
      icon: icon,
      accent: accent,
      background: tinted,
      child: Column(
        children: values
            .map(
              (value) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: accent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: selectable
                          ? SelectableText(
                              value,
                              style: const TextStyle(
                                color: _textSecondary,
                                fontSize: 16,
                                height: 1.55,
                              ),
                            )
                          : Text(
                              value,
                              style: const TextStyle(
                                color: _textSecondary,
                                fontSize: 16,
                                height: 1.55,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _baseCard({
    required String title,
    required IconData icon,
    required Color accent,
    required Widget child,
    Color? background,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: background ?? _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
