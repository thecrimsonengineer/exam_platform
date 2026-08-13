class Csp11Competency {
  final String id;
  final String domainId;
  final int number;
  final String statement;

  const Csp11Competency({
    required this.id,
    required this.domainId,
    required this.number,
    required this.statement,
  });
}

class Csp11Domain {
  final String id;
  final int number;
  final String title;
  final int weightPercent;
  final List<Csp11Competency> competencies;

  const Csp11Domain({
    required this.id,
    required this.number,
    required this.title,
    required this.weightPercent,
    required this.competencies,
  });
}

class Csp11Blueprint {
  const Csp11Blueprint._();

  static const domains = <Csp11Domain>[
    Csp11Domain(
      id: 'domain_01',
      number: 1,
      title: 'Advanced Application of Safety Principles',
      weightPercent: 25,
      competencies: [
        Csp11Competency(
          id: 'd01_c01',
          domainId: 'domain_01',
          number: 1,
          statement:
              'Describe the principles of minimizing hazards using Prevention-Through-Design.',
        ),
        Csp11Competency(
          id: 'd01_c02',
          domainId: 'domain_01',
          number: 2,
          statement:
              'Apply the principles of process safety.',
        ),
        Csp11Competency(
          id: 'd01_c03',
          domainId: 'domain_01',
          number: 3,
          statement:
              'Evaluate common workplace hazards.',
        ),
        Csp11Competency(
          id: 'd01_c04',
          domainId: 'domain_01',
          number: 4,
          statement:
              'Evaluate facility life safety features.',
        ),
        Csp11Competency(
          id: 'd01_c05',
          domainId: 'domain_01',
          number: 5,
          statement:
              'Describe fleet safety principles.',
        ),
        Csp11Competency(
          id: 'd01_c06',
          domainId: 'domain_01',
          number: 6,
          statement:
              'Evaluate materials handling methods and controls.',
        ),
        Csp11Competency(
          id: 'd01_c07',
          domainId: 'domain_01',
          number: 7,
          statement:
              'Evaluate the use of tools, machines, and equipment.',
        ),
      ],
    ),
    Csp11Domain(
      id: 'domain_02',
      number: 2,
      title: 'Program Management',
      weightPercent: 25,
      competencies: [
        Csp11Competency(
          id: 'd02_c01',
          domainId: 'domain_02',
          number: 1,
          statement: 'Compare performance against established benchmarks.',
        ),
        Csp11Competency(
          id: 'd02_c02',
          domainId: 'domain_02',
          number: 2,
          statement: 'Analyze performance standards to determine plan of action.',
        ),
        Csp11Competency(
          id: 'd02_c03',
          domainId: 'domain_02',
          number: 3,
          statement: 'Determine how to measure, analyze, and improve EHS culture.',
        ),
        Csp11Competency(
          id: 'd02_c04',
          domainId: 'domain_02',
          number: 4,
          statement:
              'Determine appropriate incident investigation techniques and apply corrective actions.',
        ),
        Csp11Competency(
          id: 'd02_c05',
          domainId: 'domain_02',
          number: 5,
          statement: 'Describe the Management of Change process.',
        ),
        Csp11Competency(
          id: 'd02_c06',
          domainId: 'domain_02',
          number: 6,
          statement: 'Describe system safety analysis techniques.',
        ),
        Csp11Competency(
          id: 'd02_c07',
          domainId: 'domain_02',
          number: 7,
          statement: 'Evaluate leading and lagging indicators.',
        ),
        Csp11Competency(
          id: 'd02_c08',
          domainId: 'domain_02',
          number: 8,
          statement: 'Recognize safety, health, and environmental management and audit systems.',
        ),
        Csp11Competency(
          id: 'd02_c09',
          domainId: 'domain_02',
          number: 9,
          statement: 'Describe required components for plans, systems, and policies.',
        ),
        Csp11Competency(
          id: 'd02_c10',
          domainId: 'domain_02',
          number: 10,
          statement: 'Utilize document retention or management principles.',
        ),
        Csp11Competency(
          id: 'd02_c11',
          domainId: 'domain_02',
          number: 11,
          statement: 'Apply budgeting, finance, and economic analysis techniques and principles.',
        ),
        Csp11Competency(
          id: 'd02_c12',
          domainId: 'domain_02',
          number: 12,
          statement: 'Differentiate management leadership techniques.',
        ),
        Csp11Competency(
          id: 'd02_c13',
          domainId: 'domain_02',
          number: 13,
          statement: 'Apply project management principles and techniques.',
        ),
        Csp11Competency(
          id: 'd02_c14',
          domainId: 'domain_02',
          number: 14,
          statement: 'Analyze and/or interpret data.',
        ),
      ],
    ),
    Csp11Domain(
      id: 'domain_03',
      number: 3,
      title: 'Risk Management',
      weightPercent: 15,
      competencies: [
        Csp11Competency(
          id: 'd03_c01',
          domainId: 'domain_03',
          number: 1,
          statement:
              'Apply general principles of the safety risk evaluation process.',
        ),
        Csp11Competency(
          id: 'd03_c02',
          domainId: 'domain_03',
          number: 2,
          statement:
              'Apply risk management strategies to identify and mitigate EHS hazards.',
        ),
        Csp11Competency(
          id: 'd03_c03',
          domainId: 'domain_03',
          number: 3,
          statement:
              'Differentiate financial risk mitigation strategies.',
        ),
        Csp11Competency(
          id: 'd03_c04',
          domainId: 'domain_03',
          number: 4,
          statement:
              'Apply risk analysis process of identifying, ranking, and monitoring.',
        ),
      ],
    ),
    Csp11Domain(
      id: 'domain_04',
      number: 4,
      title: 'Emergency Management',
      weightPercent: 9,
      competencies: [],
    ),
    Csp11Domain(
      id: 'domain_05',
      number: 5,
      title: 'Environmental Management',
      weightPercent: 6,
      competencies: [],
    ),
    Csp11Domain(
      id: 'domain_06',
      number: 6,
      title: 'Occupational Health and Applied Science',
      weightPercent: 10,
      competencies: [],
    ),
    Csp11Domain(
      id: 'domain_07',
      number: 7,
      title: 'Training',
      weightPercent: 10,
      competencies: [],
    ),
  ];

  static Csp11Domain? domainById(String id) {
    for (final domain in domains) {
      if (domain.id == id) return domain;
    }
    return null;
  }

  static Csp11Competency? competencyById(String id) {
    for (final domain in domains) {
      for (final competency in domain.competencies) {
        if (competency.id == id) return competency;
      }
    }
    return null;
  }
}
