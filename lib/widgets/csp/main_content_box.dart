import 'package:flutter/material.dart';

import '../../models/note.dart';

class MainContentBox extends StatelessWidget {
  final Note note;

  const MainContentBox({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    if (note.mainContent.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Main Content',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            ...note.mainContent.map(
              (paragraph) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SelectableText(
                  paragraph,
                  style: const TextStyle(fontSize: 16, height: 1.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
