import '../models/content_mapping_candidate.dart';
import '../data/csp11_blueprint.dart';
import '../models/source_structure_node.dart';

class Csp11BlueprintMappingEngine {
  const Csp11BlueprintMappingEngine();

  List<ContentMappingCandidate> generateCandidates({
    required String sourceId,
    required List<SourceStructureNode> nodes,
  }) {
    final results = <ContentMappingCandidate>[];

    for (final node in nodes) {
      if (node.text.trim().isEmpty && node.title.trim().isEmpty) {
        continue;
      }

      final haystack =
          '${node.title} ${node.text}'.toLowerCase();

      for (final domain in csp11Domains) {
        final domainTerms = domain.title
            .toLowerCase()
            .split(RegExp(r'\s+'))
            .where((term) => term.length >= 5)
            .toList();

        final matchedDomainTerms = domainTerms
            .where(haystack.contains)
            .toList();

        if (matchedDomainTerms.isEmpty) {
          continue;
        }

        Csp11Competency? bestCompetency;
        var bestScore = 0;

        for (final competency in domain.competencies) {
          final terms = competency.statement
              .toLowerCase()
              .split(RegExp(r'\s+'))
              .where((term) => term.length >= 5)
              .toList();

          final score = terms.where(haystack.contains).length;

          if (score > bestScore) {
            bestScore = score;
            bestCompetency = competency;
          }
        }

        final confidence = bestCompetency == null
            ? 0.55
            : (0.55 + (bestScore * 0.08)).clamp(0.0, 0.94);

        results.add(
          ContentMappingCandidate(
            sourceId: sourceId,
            sourceNodeId: node.id,
            domainId: domain.id,
            competencyId: bestCompetency?.id,
            confidence: confidence,
            rationale:
                'Candidate generated from blueprint title and concept-term overlap. '
                'Human review is required before import.',
            evidenceTerms: matchedDomainTerms,
          ),
        );
      }
    }

    return results;
  }
}