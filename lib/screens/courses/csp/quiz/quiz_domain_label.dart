import '../../../../data/csp11_blueprint.dart';

/// Returns the canonical learner-facing CSP11 domain label used by quizzes.
///
/// Quiz routes already carry the selected domain number. The header must use
/// that route context rather than a hard-coded competency title or question
/// metadata that may be stale.
String csp11QuizDomainTitle(int domainNumber) {
  for (final domain in csp11Domains) {
    if (domain.number == domainNumber) {
      final number = domain.number.toString().padLeft(2, '0');
      return 'Domain $number • ${domain.title}';
    }
  }

  if (domainNumber > 0) {
    return 'Domain ${domainNumber.toString().padLeft(2, '0')}';
  }

  return 'CSP11 Practice Quiz';
}
