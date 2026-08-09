import 'package:flutter/material.dart';

import '../../../controllers/note_controller.dart';
import '../../../models/note.dart';

import '../../../widgets/csp/learning_objectives_box.dart';
import '../../../widgets/csp/main_content_box.dart';
import '../../../widgets/csp/key_points_box.dart';
import '../../../widgets/csp/examples_box.dart';
import '../../../widgets/csp/exam_tip_box.dart';
import '../../../widgets/csp/warning_box.dart';
import '../../../widgets/csp/reference_box.dart';
import '../../../widgets/csp/key_takeaways_box.dart';
import '../../../widgets/csp/practice_button.dart';

class NoteReaderScreen extends StatelessWidget {
  final NoteController controller;

  const NoteReaderScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final Note? note = controller.selectedNote;

    if (note == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Study Note')),
        body: const Center(child: Text('Study note not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(note.title),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              // TODO:
              // Bookmark functionality will be added later.
            },
            icon: const Icon(Icons.bookmark_border),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(Icons.schedule, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '${note.estimatedReadTime} min read',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              LearningObjectivesBox(note: note),

              const SizedBox(height: 16),

              MainContentBox(note: note),

              const SizedBox(height: 16),

              KeyPointsBox(note: note),

              const SizedBox(height: 16),

              ExamplesBox(note: note),

              const SizedBox(height: 16),

              ExamTipBox(note: note),

              const SizedBox(height: 16),

              WarningBox(note: note),

              const SizedBox(height: 16),

              ReferenceBox(note: note),

              const SizedBox(height: 16),

              KeyTakeawaysBox(note: note),

              const SizedBox(height: 24),

              PracticeButton(
                note: note,
                onPressed: () {
                  // TODO:
                  // Launch a quiz using
                  // note.relatedQuestionIds.
                },
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
