import '../models/ai_classification_result.dart';
import '../data/csp11_blueprint.dart';
import '../models/source_structure_node.dart';

abstract class CompetencyClassifier {
  Future<AiClassificationResult> classify({
    required SourceStructureNode node,
    required List<Csp11Competency> allowedCompetencies,
  });
}

class LocalCompetencyClassifier implements CompetencyClassifier {
  const LocalCompetencyClassifier();

  @override
  Future<AiClassificationResult> classify({
    required SourceStructureNode node,
    required List<Csp11Competency> allowedCompetencies,
  }) async {
    final text =
        '${node.title} ${node.text}'.toLowerCase();

    final candidates = <AiClassificationCandidate>[];

    for (final competency in allowedCompetencies) {
      final terms = competency.statement
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where((term) => term.length >= 5)
          .toList();

      final matches =
          terms.where(text.contains).toList();

      if (matches.isEmpty) continue;

      final confidence =
          (0.55 + matches.length * 0.06).clamp(0.0, 0.92);

      candidates.add(
        AiClassificationCandidate(
          targetId: competency.id,
          confidence: confidence,
          rationale:
              'Local candidate based on terminology overlap. '
              'Replace with an AI provider for semantic classification.',
          evidenceTerms: matches,
        ),
      );
    }

    candidates.sort(
      (a, b) => b.confidence.compareTo(a.confidence),
    );

    return AiClassificationResult(
      sourceNodeId: node.id,
      candidates: candidates.take(5).toList(),
    );
  }
}