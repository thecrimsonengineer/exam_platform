import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';

import '../../../controllers/note_controller.dart';
import '../../../models/note_domain.dart';
import 'note_sections_screen_dark.dart';

class DarkStudyNotesScreen extends StatelessWidget {
  final NoteController controller;

  DarkStudyNotesScreen({super.key, NoteController? controller})
    : controller = controller ?? NoteController();

  static const _bg = Color(0xFF0A111D);
  static const _surface = Color(0xFF111B2C);
  static const _surfaceSoft = Color(0xFF162238);
  static const _border = Color(0xFF25344A);
  static const _textPrimary = Color(0xFFF4F7FB);
  static const _textSecondary = Color(0xFFA5B1C4);
  static const _accent = Color(0xFF6EA8FF);

  @override
  Widget build(BuildContext context) {
    final List<NoteDomain> domains = controller.domains;

    return StudentGlassScaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Study Notes'),
        centerTitle: true,
        backgroundColor: _bg,
        foregroundColor: _textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      body: domains.isEmpty
          ? const Center(
              child: Text(
                'No study notes available.',
                style: TextStyle(color: _textSecondary, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: domains.length,
              itemBuilder: (context, index) {
                final domain = domains[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        controller.selectDomain(domain.id);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                DarkNoteSectionsScreen(controller: controller),
                          ),
                        );
                      },
                      child: StudentGlassSurface(
                        padding: const EdgeInsets.all(18),
                        borderRadius: BorderRadius.circular(18),
                        tint: _surface.withValues(alpha: 0.58),
                        borderColor: _border.withValues(alpha: 0.72),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: _surfaceSoft,
                              foregroundColor: _accent,
                              child: Text(
                                domain.title.substring(0, 1),
                                style: const TextStyle(
                                  fontSize: 22,
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
                                    domain.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _textPrimary,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    domain.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _textSecondary,
                                      height: 1.45,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${domain.sectionCount} Sections • ${domain.noteCount} Topics',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                  ),
                );
              },
            ),
    );
  }
}
