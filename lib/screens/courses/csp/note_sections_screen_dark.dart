import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';

import '../../../controllers/note_controller.dart';
import '../../../models/note_section.dart';
import 'notes_list_screen_dark.dart';

class DarkNoteSectionsScreen extends StatelessWidget {
  final NoteController controller;

  const DarkNoteSectionsScreen({super.key, required this.controller});

  static const _bg = Color(0xFF0A111D);
  static const _surface = Color(0xFF111B2C);
  static const _surfaceSoft = Color(0xFF162238);
  static const _border = Color(0xFF25344A);
  static const _textPrimary = Color(0xFFF4F7FB);
  static const _textSecondary = Color(0xFFA5B1C4);
  static const _accent = Color(0xFF6EA8FF);

  @override
  Widget build(BuildContext context) {
    final List<NoteSection> sections = controller.getSections();

    return StudentGlassScaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(controller.selectedDomain?.title ?? 'Study Notes'),
        centerTitle: true,
        backgroundColor: _bg,
        foregroundColor: _textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      body: sections.isEmpty
          ? const Center(
              child: Text(
                'No sections available.',
                style: TextStyle(color: _textSecondary, fontSize: 16),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sections.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final section = sections[index];
                return Material(
                  color: _surface,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      controller.selectSection(section.id);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              DarkNotesListScreen(controller: controller),
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
                                  section.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  section.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _textSecondary,
                                    height: 1.45,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${section.noteCount} Topics',
                                  style: const TextStyle(
                                    color: _textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: _accent),
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
