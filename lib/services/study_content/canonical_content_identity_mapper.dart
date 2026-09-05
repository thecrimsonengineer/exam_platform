import '../../data/csp11_blueprint.dart';
import '../../models/study_content.dart';

class CanonicalContentIdentityResult {
  const CanonicalContentIdentityResult({
    required this.content,
    required this.legacyDomainId,
    required this.legacyCompetencyId,
  });

  final StudyContent content;
  final String legacyDomainId;
  final String legacyCompetencyId;
}

class CanonicalContentIdentityMapper {
  const CanonicalContentIdentityMapper();

  CanonicalContentIdentityResult normalize(StudyContent content) {
    final legacyDomainId = content.domainId.trim();
    final legacyCompetencyId = content.competencyId.trim();

    if (legacyDomainId.isEmpty) {
      throw const FormatException(
        'Content domainId is required for canonical identity mapping.',
      );
    }

    if (legacyCompetencyId.isEmpty) {
      throw const FormatException(
        'Content competencyId is required for canonical identity mapping.',
      );
    }

    final domain = domainForContentId(legacyDomainId);

    if (domain == null) {
      throw FormatException(
        'Unknown CSP11 content domain: $legacyDomainId',
      );
    }

    final competency = _resolveCompetency(
      domainId: domain.id,
      legacyCompetencyId: legacyCompetencyId,
      competencyNumber: content.competencyNumber,
    );

    if (competency == null) {
      throw FormatException(
        'Unable to resolve CSP11 competency: '
        '$legacyDomainId / $legacyCompetencyId '
        '(number ${content.competencyNumber}).',
      );
    }

    final canonicalContent = StudyContent(
      id: content.id,
      domainId: domain.id,
      competencyId: competency.id,
      competencyNumber: competency.number,
      title: content.title,
      status: content.status,
      version: content.version,
      subtopics: content.subtopics,
    );

    return CanonicalContentIdentityResult(
      content: canonicalContent,
      legacyDomainId: legacyDomainId,
      legacyCompetencyId: legacyCompetencyId,
    );
  }

  Csp11Competency? _resolveCompetency({
    required String domainId,
    required String legacyCompetencyId,
    required int competencyNumber,
  }) {
    final byNumber = competencyForDomainAndNumber(
      domainId,
      competencyNumber,
    );

    if (byNumber == null) {
      return null;
    }

    final normalized = legacyCompetencyId.toLowerCase();

    if (normalized == byNumber.id.toLowerCase()) {
      return byNumber;
    }

    final domain = domainForContentId(domainId);

    if (domain == null) {
      return null;
    }

    final expectedLegacyId =
        'domain_${domain.number.toString().padLeft(2, '0')}_'
        '${competencyNumber.toString().padLeft(2, '0')}';

    if (normalized == expectedLegacyId.toLowerCase()) {
      return byNumber;
    }

    return null;
  }
}
