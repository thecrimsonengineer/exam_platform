import 'package:flutter/material.dart';

import '../../../controllers/note_controller.dart';
import '../../../models/note.dart';
import 'note_reader_screen_dark.dart';

class DarkNotesListScreen extends StatelessWidget {
  final NoteController controller;

  const DarkNotesListScreen({super.key, required this.controller});

  static const _bg = Color(0xFF0A111D);
  static const _surface = Color(0xFF111B2C);
  static const _surfaceSoft = Color(0xFF162238);
  static const _border = Color(0xFF25344A);
  static const _textPrimary = Color(0xFFF4F7FB);
  static const _textSecondary = Color(0xFFA5B1C4);
  static const _accent = Color(0xFF6EA8FF);

  @override
  Widget build(BuildContext context) {
    final List<Note> notes = controller.getNotes();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(controller.selectedSection?.title ?? 'Topics'),
        centerTitle: true,
        backgroundColor: _bg,
        foregroundColor: _textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      body: notes.isEmpty
          ? const Center(
              child: Text(
                'No topics available.',
                style: TextStyle(color: _textSecondary, fontSize: 16),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final note = notes[index];
                return Material(
                  color: _surface,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      controller.selectNote(note.id);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              DarkNoteReaderScreen(controller: controller),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _border),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: _surfaceSoft,
                            foregroundColor: _accent,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  note.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${note.learningObjectives.length} Learning Objectives',
                                  style: const TextStyle(color: _textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 18,
                            color: _accent,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
