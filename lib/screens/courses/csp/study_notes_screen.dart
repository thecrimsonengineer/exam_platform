import 'package:flutter/material.dart';

import '../../../controllers/note_controller.dart';
import '../../../models/note_domain.dart';
import 'note_sections_screen.dart';

class StudyNotesScreen extends StatelessWidget {
  StudyNotesScreen({super.key});

  final NoteController _controller = NoteController();

  @override
  Widget build(BuildContext context) {
    final List<NoteDomain> domains = _controller.domains;

    return Scaffold(
      appBar: AppBar(title: const Text('Study Notes'), centerTitle: true),
      body: domains.isEmpty
          ? const Center(
              child: Text(
                'No study notes available.',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: domains.length,
              itemBuilder: (context, index) {
                final domain = domains[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        _controller.selectDomain(domain.id);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                NoteSectionsScreen(controller: _controller),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
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
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    domain.description,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${domain.sectionCount} Sections • ${domain.noteCount} Topics',
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
                  ),
                );
              },
            ),
    );
  }
}
