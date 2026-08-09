import 'package:flutter/material.dart';

import '../../../models/study_content.dart';
import 'main_content_topic_renderer.dart';
import 'quiz_block.dart';

/// Renders a complete CSP study subtopic.
///
/// A subtopic may contain any combination of:
/// - Learning objectives
/// - Main content topics
/// - Key points
/// - Examples
/// - Case studies
/// - Formulas
/// - References
/// - Exam tips
/// - Common mistakes
/// - Key takeaways
/// - Quizzes
///
/// Every section is optional. Empty sections are not displayed.
class StudySubtopicRenderer extends StatelessWidget {
  final StudySubtopic subtopic;
  final int domain;

  const StudySubtopicRenderer({
    super.key,
    required this.subtopic,
    required this.domain,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubtopicTitle(),
        _buildLearningObjectives(),
        _buildMainContent(),
        _buildKeyPoints(),
        _buildExamples(),
        _buildCaseStudies(),
        _buildFormulas(),
        _buildReferences(),
        _buildExamTips(),
        _buildCommonMistakes(),
        _buildKeyTakeaways(),
        _buildQuizzes(),
      ],
    );
  }

  // ==========================================================
  // Subtopic Title
  // ==========================================================

  Widget _buildSubtopicTitle() {
    final title = subtopic.title.trim();

    if (title.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 20,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
      ),
    );
  }

  // ==========================================================
  // Learning Objectives
  // ==========================================================

  Widget _buildLearningObjectives() {
    if (subtopic.learningObjectives.isEmpty) {
      return const SizedBox.shrink();
    }

    final objectives = subtopic.learningObjectives
        .map((objective) => objective.trim())
        .where((objective) => objective.isNotEmpty)
        .toList();

    if (objectives.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Learning Objectives',
      icon: Icons.flag_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: objectives
            .map(
              (objective) => Padding(
                padding: const EdgeInsets.only(
                  bottom: 10,
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '•',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        objective,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ==========================================================
  // Main Content
  // ==========================================================

  Widget _buildMainContent() {
    if (subtopic.mainContent.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Main Content',
      icon: Icons.menu_book_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: subtopic.mainContent
            .map(
              (MainContentTopic topic) =>
                  MainContentTopicRenderer(
                topic: topic,
                domain: domain,
              ),
            )
            .toList(),
      ),
    );
  }

  // ==========================================================
  // Key Points
  // ==========================================================

  Widget _buildKeyPoints() {
    if (subtopic.keyPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    final points = subtopic.keyPoints
        .where(
          (entry) => entry.content.trim().isNotEmpty,
        )
        .toList();

    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Key Points',
      icon: Icons.push_pin_outlined,
      child: _buildContentEntryList(points),
    );
  }

  // ==========================================================
  // Examples
  // ==========================================================

  Widget _buildExamples() {
    if (subtopic.examples.isEmpty) {
      return const SizedBox.shrink();
    }

    final examples = subtopic.examples
        .where(
          (entry) => entry.content.trim().isNotEmpty,
        )
        .toList();

    if (examples.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Examples',
      icon: Icons.work_outline,
      child: _buildContentEntryList(examples),
    );
  }

  // ==========================================================
  // Case Studies
  // ==========================================================

  Widget _buildCaseStudies() {
    if (subtopic.caseStudies.isEmpty) {
      return const SizedBox.shrink();
    }

    final caseStudies = subtopic.caseStudies
        .where(
          (entry) => entry.content.trim().isNotEmpty,
        )
        .toList();

    if (caseStudies.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Case Studies',
      icon: Icons.business_center_outlined,
      child: _buildContentEntryList(caseStudies),
    );
  }

  // ==========================================================
  // Formulas
  // ==========================================================

  Widget _buildFormulas() {
    if (subtopic.formulas.isEmpty) {
      return const SizedBox.shrink();
    }

    final formulas = subtopic.formulas
        .where(
          (entry) => entry.content.trim().isNotEmpty,
        )
        .toList();

    if (formulas.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Formulas',
      icon: Icons.functions,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: formulas
            .map(
              (formula) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(
                  bottom: 12,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(10),
                  color: Colors.grey.shade100,
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    if (formula.title.trim().isNotEmpty) ...[
                      Text(
                        formula.title.trim(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      formula.content.trim(),
                      style: const TextStyle(
                        fontSize: 17,
                        fontFamily: 'monospace',
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ==========================================================
  // References
  // ==========================================================

  Widget _buildReferences() {
    if (subtopic.references.isEmpty) {
      return const SizedBox.shrink();
    }

    final references = subtopic.references
        .where(
          (entry) =>
              entry.title.trim().isNotEmpty ||
              entry.content.trim().isNotEmpty ||
              entry.source.trim().isNotEmpty ||
              entry.url.trim().isNotEmpty,
        )
        .toList();

    if (references.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'References',
      icon: Icons.menu_book_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: references
            .map(
              (reference) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(
                  bottom: 12,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(10),
                  color: Colors.grey.shade100,
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    if (reference.title
                        .trim()
                        .isNotEmpty)
                      Text(
                        reference.title.trim(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    if (reference.source
                        .trim()
                        .isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        reference.source.trim(),
                      ),
                    ],
                    if (reference.content
                        .trim()
                        .isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        reference.content.trim(),
                      ),
                    ],
                    if (reference.url
                        .trim()
                        .isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        reference.url.trim(),
                        style: TextStyle(
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ==========================================================
  // Exam Tips
  // ==========================================================

  Widget _buildExamTips() {
    if (subtopic.examTips.isEmpty) {
      return const SizedBox.shrink();
    }

    final tips = subtopic.examTips
        .where(
          (entry) => entry.content.trim().isNotEmpty,
        )
        .toList();

    if (tips.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Exam Tips',
      icon: Icons.lightbulb_outline,
      child: _buildContentEntryList(tips),
    );
  }

  // ==========================================================
  // Common Mistakes
  // ==========================================================

  Widget _buildCommonMistakes() {
    if (subtopic.commonMistakes.isEmpty) {
      return const SizedBox.shrink();
    }

    final mistakes = subtopic.commonMistakes
        .where(
          (entry) => entry.content.trim().isNotEmpty,
        )
        .toList();

    if (mistakes.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Common Mistakes',
      icon: Icons.error_outline,
      child: _buildContentEntryList(mistakes),
    );
  }

  // ==========================================================
  // Key Takeaways
  // ==========================================================

  Widget _buildKeyTakeaways() {
    if (subtopic.keyTakeaways.isEmpty) {
      return const SizedBox.shrink();
    }

    final takeaways = subtopic.keyTakeaways
        .where(
          (entry) => entry.content.trim().isNotEmpty,
        )
        .toList();

    if (takeaways.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Key Takeaways',
      icon: Icons.check_circle_outline,
      child: _buildContentEntryList(takeaways),
    );
  }

  // ==========================================================
  // Quizzes
  // ==========================================================

  Widget _buildQuizzes() {
    if (subtopic.quizzes.isEmpty) {
      return const SizedBox.shrink();
    }

    final quizzes = subtopic.quizzes
        .where(
          (quiz) => quiz.quizId.trim().isNotEmpty,
        )
        .toList();

    if (quizzes.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Practice Questions',
      icon: Icons.quiz_outlined,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: quizzes
            .map(
              (quiz) => QuizBlock(
                quiz: quiz,
                domain: domain,
              ),
            )
            .toList(),
      ),
    );
  }

  // ==========================================================
  // Content Entry List
  // ==========================================================

  Widget _buildContentEntryList(
    List<ContentEntry> entries,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: entries
          .map(
            (entry) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(
                bottom: 10,
              ),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.grey.shade300,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  if (entry.title.trim().isNotEmpty)
                    Text(
                      entry.title.trim(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (entry.content
                      .trim()
                      .isNotEmpty) ...[
                    if (entry.title.trim().isNotEmpty)
                      const SizedBox(height: 6),
                    Text(
                      entry.content.trim(),
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // ==========================================================
  // Shared Section
  // ==========================================================

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 24,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 21,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}