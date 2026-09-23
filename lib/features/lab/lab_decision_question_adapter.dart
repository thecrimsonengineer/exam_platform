import '../../models/question.dart';
import '../../models/question_quality_evidence.dart';
import '../../services/questions/canonical_question_parser.dart';
import 'lab_contracts.dart';

/// Converts one authored LAB Decision Node into the canonical CSP11 question
/// representation used by normal question authoring.
///
/// LSP-Q3 requires scenario-specific explanation and BEST-answer rationale
/// derived deterministically from pinned DQG300 evidence. No generic fallback
/// is permitted.
class LabDecisionQuestionAdapter {
  const LabDecisionQuestionAdapter({
    this.parser = const CanonicalQuestionParser(),
  });

  final CanonicalQuestionParser parser;

  Map<String, dynamic> toCanonicalPayload({
    required LabPackage package,
    required LabDecisionNode node,
    required QuestionQualityEvidence evidence,
  }) {
    final correctAnswer = node.options.indexWhere((option) => option.isBest);

    return <String, dynamic>{
      'question': node.prompt,
      'options': node.options.map((option) => option.text).toList(),
      'correctAnswer': correctAnswer,
      'explanation': _scenarioExplanation(node: node, evidence: evidence),
      'bestAnswerRationale': _bestAnswerRationale(
        node: node,
        evidence: evidence,
      ),
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
    required QuestionQualityEvidence evidence,
  }) {
    return parser.parseQuestion(
      toCanonicalPayload(package: package, node: node, evidence: evidence),
    );
  }

  Question toQuestion({
    required LabPackage package,
    required LabDecisionNode node,
    required QuestionQualityEvidence evidence,
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

    final draft = toCanonicalDraft(
      package: package,
      node: node,
      evidence: evidence,
    );
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

  String _scenarioExplanation({
    required LabDecisionNode node,
    required QuestionQualityEvidence evidence,
  }) {
    final facts = _nonEmpty(evidence.decisiveScenarioFacts);
    final criteria = _nonEmpty(evidence.keySatisfiedCriteria);

    if (facts.isEmpty) {
      throw LabContractException(
        'LAB Decision ${node.id} requires decisiveScenarioFacts before '
        'canonical question conversion.',
      );
    }
    if (criteria.isEmpty) {
      throw LabContractException(
        'LAB Decision ${node.id} requires keySatisfiedCriteria before '
        'canonical question conversion.',
      );
    }

    return 'The decisive scenario facts are: ${facts.join('; ')}. '
        'The BEST action is supported because it satisfies these material '
        'criteria: ${criteria.join('; ')}.';
  }

  String _bestAnswerRationale({
    required LabDecisionNode node,
    required QuestionQualityEvidence evidence,
  }) {
    final proofEntries =
        evidence.keySuperiorityProof.entries
            .where((entry) => entry.value.trim().isNotEmpty)
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));

    if (proofEntries.isEmpty) {
      throw LabContractException(
        'LAB Decision ${node.id} requires keySuperiorityProof before '
        'canonical question conversion.',
      );
    }

    final proofs = proofEntries
        .map((entry) => _normalizeProof(entry.value))
        .toList(growable: false);

    return 'The BEST action is superior to the alternatives because '
        '${proofs.join(' ')}';
  }

  String _normalizeProof(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'\bKEY\b'), 'the BEST action')
        .replaceAllMapped(
          RegExp(r'\bD(\d+)\b'),
          (match) => 'alternative ${match.group(1)}',
        );
  }

  List<String> _nonEmpty(Iterable<String> values) {
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  int _domainNumber(String competencyId) {
    final match = RegExp(r'^d(\d{2})_c\d{2}$').firstMatch(competencyId);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }
}
