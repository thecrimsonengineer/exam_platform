import 'package:flutter/material.dart';

import '../../../controllers/note_controller.dart';
import '../../../models/note_section.dart';
import 'notes_list_screen.dart';

class NoteSectionsScreen extends StatelessWidget {
  final NoteController controller;

  const NoteSectionsScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final List<NoteSection> sections = controller.getSections();

    return Scaffold(
      appBar: AppBar(
        title: Text(controller.selectedDomain?.title ?? 'Study Notes'),
        centerTitle: true,
      ),
      body: sections.isEmpty
          ? const Center(
              child: Text(
                'No sections available.',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sections.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final section = sections[index];

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      controller.selectSection(section.id);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              NotesListScreen(controller: controller),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
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
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  section.description,
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${section.noteCount} Topics',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
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
