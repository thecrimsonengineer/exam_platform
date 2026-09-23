import '../../models/question.dart';
import '../../services/questions/canonical_question_parser.dart';
import 'lab_contracts.dart';

/// Converts one authored LAB Decision Node into the canonical CSP11 question
/// representation used by normal question authoring.
///
/// LSP-Q2 intentionally preserves the existing DQG300 compatibility
/// explanation and rationale. LSP-Q3 replaces those generic placeholders with
/// scenario-specific authored/evidence-backed text.
class LabDecisionQuestionAdapter {
  const LabDecisionQuestionAdapter({
    this.parser = const CanonicalQuestionParser(),
  });

  static const String compatibilityExplanation =
      'Internal DQG300-LAB evidence supports the uniquely defensible BEST action.';

  static const String compatibilityBestAnswerRationale =
      'Internal DQG300-LAB evidence proves BEST-answer superiority for this authored decision.';

  final CanonicalQuestionParser parser;

  Map<String, dynamic> toCanonicalPayload({
    required LabPackage package,
    required LabDecisionNode node,
  }) {
    final correctAnswer = node.options.indexWhere((option) => option.isBest);

    return <String, dynamic>{
      'question': node.prompt,
      'options': node.options.map((option) => option.text).toList(),
      'correctAnswer': correctAnswer,
      'explanation': compatibilityExplanation,
      'bestAnswerRationale': compatibilityBestAnswerRationale,
      'reference': package.metadata.sources.join('; '),
      'difficulty': 'Hard',
      'cognitiveLevel': 'analysis',
      'questionType': 'scenario_mcq',
      'version': 1,
      'tags': <String>['lab-dqg300', node.id],
    };
  }

  CanonicalQuestionDraft toCanonicalDraft({
    required LabPackage package,
    required LabDecisionNode node,
  }) {
    return parser.parseQuestion(
      toCanonicalPayload(package: package, node: node),
    );
  }

  Question toQuestion({
    required LabPackage package,
    required LabDecisionNode node,
    required int decisionIndex,
    String status = 'validated',
  }) {
    if (decisionIndex < 0) {
      throw ArgumentError.value(
        decisionIndex,
        'decisionIndex',
        'Decision index cannot be negative.',
      );
    }

    final draft = toCanonicalDraft(package: package, node: node);
    final competency = package.metadata.competencyMappings.isEmpty
        ? ''
        : package.metadata.competencyMappings.first;

    return Question(
      id: decisionIndex + 1,
      domain: _domainNumber(competency),
      competencyId: competency,
      subtopicId: '',
      topicId: '',
      quizId: '${package.metadata.id}_${node.id}',
      contentPackageId: '${package.metadata.id}-${package.metadata.versionId}',
      question: draft.question,
      options: List<String>.from(draft.options),
      correctAnswer: draft.correctAnswer,
      explanation: draft.explanation,
      bestAnswerRationale: draft.bestAnswerRationale,
      reference: draft.reference,
      difficulty: draft.difficulty,
      cognitiveLevel: draft.cognitiveLevel,
      questionType: draft.questionType,
      status: status,
      version: draft.version,
      tags: List<String>.from(draft.tags),
    );
  }

  int _domainNumber(String competencyId) {
    final match = RegExp(r'^d(\d{2})_c\d{2}$').firstMatch(competencyId);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }
}
