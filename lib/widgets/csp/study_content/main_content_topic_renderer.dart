import 'package:flutter/material.dart';

import '../../../models/study_content.dart';
import 'content_block_renderer.dart';
import 'quiz_block.dart';

class MainContentTopicRenderer extends StatelessWidget {
  final MainContentTopic topic;
  final int domain;

  const MainContentTopicRenderer({
    super.key,
    required this.topic,
    required this.domain,
  });

  @override
  Widget build(BuildContext context) {
    final title = topic.title.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                bottom: 12,
              ),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
            ),

          if (topic.blocks.isNotEmpty)
            ...topic.blocks.map(
              (ContentBlock block) => ContentBlockRenderer(
                block: block,
              ),
            ),

          if (topic.quizzes.isNotEmpty) ...[
            const SizedBox(height: 8),

            ...topic.quizzes.map(
              (QuizReference quiz) => QuizBlock(
                quiz: quiz,
                domain: domain,
              ),
            ),
          ],
        ],
      ),
    );
  }
}