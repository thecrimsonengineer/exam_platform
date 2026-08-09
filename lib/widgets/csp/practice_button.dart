import 'package:flutter/material.dart';

import '../../models/note.dart';

class PracticeButton extends StatelessWidget {
  final Note note;
  final VoidCallback? onPressed;

  const PracticeButton({super.key, required this.note, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final int questionCount = note.relatedQuestionIds.length;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: questionCount == 0 ? null : onPressed,
        icon: const Icon(Icons.quiz),
        label: Text(
          questionCount == 0
              ? 'No Practice Questions Available'
              : 'Practice Questions ($questionCount)',
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
