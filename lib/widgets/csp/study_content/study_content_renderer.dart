import 'package:flutter/material.dart';

import '../../../models/study_content.dart';
import 'study_subtopic_renderer.dart';

/// Renders a complete CSP competency.
///
/// A StudyContent object can contain any number of subtopics.
/// Each subtopic is passed to StudySubtopicRenderer, which handles
/// the detailed educational content.
class StudyContentRenderer extends StatelessWidget {
  final StudyContent content;

  const StudyContentRenderer({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final domain = _getDomainNumber(content.domainId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),

          const SizedBox(height: 24),

          if (content.subtopics.isEmpty)
            _buildNoContentMessage()
          else
            ...content.subtopics.map(
              (StudySubtopic subtopic) => Padding(
                padding: const EdgeInsets.only(
                  bottom: 20,
                ),
                child: StudySubtopicRenderer(
                  subtopic: subtopic,
                  domain: domain,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================================
  // Domain Number
  // ==========================================================

  int _getDomainNumber(String domainId) {
    final match = RegExp(r'\d+').firstMatch(domainId);

    if (match == null) {
      return 0;
    }

    return int.tryParse(match.group(0)!) ?? 0;
  }

  // ==========================================================
  // Competency Header
  // ==========================================================

  Widget _buildHeader() {
    final title = content.title.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),

        const SizedBox(height: 8),

        Text(
          'Competency ${content.competencyNumber}',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),

        if (content.subtopics.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            '${content.subtopics.length} '
            '${content.subtopics.length == 1 ? 'subtopic' : 'subtopics'}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }

  // ==========================================================
  // Empty Content
  // ==========================================================

  Widget _buildNoContentMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: const Text(
        'No study content is available for this competency yet.',
        style: TextStyle(
          fontSize: 16,
          height: 1.5,
        ),
      ),
    );
  }
}