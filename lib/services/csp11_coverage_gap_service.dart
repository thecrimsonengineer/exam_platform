import '../models/csp11_coverage_gap.dart';

class Csp11CoverageGapService {
  const Csp11CoverageGapService();

  Csp11CoverageGap assess({
    required String domainId,
    required String domainTitle,
    required String competencyId,
    required String competencyTitle,
    required int mappedItems,
    int coveredThreshold = 3,
  }) {
    final level = mappedItems == 0
        ? CoverageGapLevel.missing
        : mappedItems < coveredThreshold
            ? CoverageGapLevel.partial
            : CoverageGapLevel.covered;

    return Csp11CoverageGap(
      domainId: domainId,
      domainTitle: domainTitle,
      competencyId: competencyId,
      competencyTitle: competencyTitle,
      mappedItems: mappedItems,
      level: level,
    );
  }
}
