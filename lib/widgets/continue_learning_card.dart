import 'package:flutter/material.dart';

class ContinueLearningCard extends StatelessWidget {
  final String course;
  final String subtitle;
  final double progress;
  final int completedQuestions;
  final int totalQuestions;
  final VoidCallback? onPressed;

  const ContinueLearningCard({
    super.key,
    required this.course,
    required this.subtitle,
    required this.progress,
    required this.completedQuestions,
    required this.totalQuestions,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 4),

            Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),

            const SizedBox(height: 20),

            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(value: progress, minHeight: 10),
            ),

            const SizedBox(height: 10),

            Text("$completedQuestions / $totalQuestions Questions Completed"),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.play_arrow),
                label: const Text("Resume Learning"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
