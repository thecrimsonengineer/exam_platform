enum CoverageGapLevel {
  covered,
  partial,
  missing,
}

class Csp11CoverageGap {
  final String domainId;
  final String domainTitle;
  final String competencyId;
  final String competencyTitle;
  final int mappedItems;
  final CoverageGapLevel level;

  const Csp11CoverageGap({
    required this.domainId,
    required this.domainTitle,
    required this.competencyId,
    required this.competencyTitle,
    required this.mappedItems,
    required this.level,
  });

  String get label {
    switch (level) {
      case CoverageGapLevel.covered:
        return 'COVERED';
      case CoverageGapLevel.partial:
        return 'PARTIAL';
      case CoverageGapLevel.missing:
        return 'MISSING';
    }
  }
}
