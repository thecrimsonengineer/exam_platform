// Frozen CSP11 domain catalog.
//
// This is the single source of truth for CSP11 domain
// names, numbers, and examination weights.

class Csp11Domain {
  final String id;
  final int number;
  final String title;
  final int weightPercent;

  const Csp11Domain({
    required this.id,
    required this.number,
    required this.title,
    required this.weightPercent,
  });
}

const List<Csp11Domain> csp11Domains = <Csp11Domain>[
  Csp11Domain(
    id: 'domain_01',
    number: 1,
    title: 'Advanced Application of Safety Principles',
    weightPercent: 25,
  ),
  Csp11Domain(
    id: 'domain_02',
    number: 2,
    title: 'Program Management',
    weightPercent: 25,
  ),
  Csp11Domain(
    id: 'domain_03',
    number: 3,
    title: 'Risk Management',
    weightPercent: 15,
  ),
  Csp11Domain(
    id: 'domain_04',
    number: 4,
    title: 'Emergency Management',
    weightPercent: 10,
  ),
  Csp11Domain(
    id: 'domain_05',
    number: 5,
    title: 'Environmental Management',
    weightPercent: 10,
  ),
  Csp11Domain(
    id: 'domain_06',
    number: 6,
    title: 'Occupational Health and Applied Science',
    weightPercent: 10,
  ),
  Csp11Domain(id: 'domain_07', number: 7, title: 'Training', weightPercent: 5),
];

Csp11Domain? domainForId(String id) {
  for (final domain in csp11Domains) {
    if (domain.id == id) {
      return domain;
    }
  }

  return null;
}

Csp11Domain? domainForContentId(String domainId) {
  final normalized = domainId.trim().toLowerCase();

  for (final domain in csp11Domains) {
    if (domain.id.toLowerCase() == normalized ||
        'domain_${domain.number.toString().padLeft(2, '0')}' == normalized ||
        'domain${domain.number}' == normalized ||
        domain.number.toString() == normalized.replaceAll('domain', '')) {
      return domain;
    }
  }

  return null;
}

Csp11Domain domainForNumber(int number) {
  if (number < 1 || number > csp11Domains.length) {
    throw ArgumentError.value(
      number,
      'number',
      'CSP11 domain number must be 1-7.',
    );
  }

  return csp11Domains[number - 1];
}
