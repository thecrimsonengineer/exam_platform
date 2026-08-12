import 'package:flutter/material.dart';

import '../../../controllers/note_controller.dart';
import '../../../models/note.dart';
import 'note_reader_screen.dart';

class NotesListScreen extends StatelessWidget {
  final NoteController controller;

  const NotesListScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final List<Note> notes = controller.getNotes();

    return Scaffold(
      appBar: AppBar(
        title: Text(controller.selectedSection?.title ?? 'Topics'),
        centerTitle: true,
      ),
      body: notes.isEmpty
          ? const Center(
              child: Text(
                'No topics available.',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final note = notes[index];

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      controller.selectNote(note.id);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              NoteReaderScreen(controller: controller),
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
                                  note.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${note.learningObjectives.length} Learning Objectives',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 18),
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
