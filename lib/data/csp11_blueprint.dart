// Frozen CSP11 examination blueprint.
//
// This is the single source of truth for CSP11 domain names, numbers,
// examination weights, and official competency statements.
//
// Source:
// CSP11 Examination Blueprint | V.2024.04.24
// Board of Certified Safety Professionals (BCSP)
//
// Application-created topics and subtopics are NOT part of this blueprint.
// They must remain separate from the official CSP11 competency hierarchy.

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

const List<Csp11Domain> csp11Domains = <Csp11Domain>[
  Csp11Domain(
    id: 'domain_01',
    number: 1,
    title: 'Advanced Application of Safety Principles',
    weightPercent: 25,
    competencies: <Csp11Competency>[
      Csp11Competency(
        id: 'd01_c01',
        domainId: 'domain_01',
        number: 1,
        statement:
            'Describe the principles of minimizing hazards using Prevention-Through-Design. (e.g., avoidance, elimination, substitution, safety design criteria for workplace facilities, machines, and practices)',
      ),
      Csp11Competency(
        id: 'd01_c02',
        domainId: 'domain_01',
        number: 2,
        statement:
            'Apply the principles of process safety. (e.g., pressure relief systems, chemical compatibility, management of change, materials of construction, process flow diagrams)',
      ),
      Csp11Competency(
        id: 'd01_c03',
        domainId: 'domain_01',
        number: 3,
        statement:
            'Evaluate common workplace hazards. (e.g., electrical, falls, confined spaces, lockout/tagout, working around water, caught in, struck by, excavation)',
      ),
      Csp11Competency(
        id: 'd01_c04',
        domainId: 'domain_01',
        number: 4,
        statement:
            'Evaluate facility life safety features. (e.g., public space safety, floor loading, occupancy loads)',
      ),
      Csp11Competency(
        id: 'd01_c05',
        domainId: 'domain_01',
        number: 5,
        statement:
            'Describe fleet safety principles. (e.g., driver and equipment safety, maintenance, surveillance equipment, GPS monitoring, telematics, hybrid vehicles, fuel systems, driving under the influence, fatigue)',
      ),
      Csp11Competency(
        id: 'd01_c06',
        domainId: 'domain_01',
        number: 6,
        statement:
            'Evaluate materials handling methods and controls. (e.g., forklifts, aerial lifts, and other powered industrial trucks; cranes, hand trucks, hoists, rigging, manual handling, drones)',
      ),
      Csp11Competency(
        id: 'd01_c07',
        domainId: 'domain_01',
        number: 7,
        statement:
            'Evaluate the use of tools, machines, and equipment. (e.g., hand tools, power tools, ladders, grinders, hydraulics, robotics)',
      ),
    ],
  ),

  Csp11Domain(
    id: 'domain_02',
    number: 2,
    title: 'Program Management',
    weightPercent: 25,
    competencies: <Csp11Competency>[
      Csp11Competency(
        id: 'd02_c01',
        domainId: 'domain_02',
        number: 1,
        statement:
            'Compare performance against established benchmarks. (e.g., gap analysis)',
      ),
      Csp11Competency(
        id: 'd02_c02',
        domainId: 'domain_02',
        number: 2,
        statement:
            'Analyze performance standards to determine plan of action.',
      ),
      Csp11Competency(
        id: 'd02_c03',
        domainId: 'domain_02',
        number: 3,
        statement:
            'Determine how to measure, analyze, and improve EHS culture.',
      ),
      Csp11Competency(
        id: 'd02_c04',
        domainId: 'domain_02',
        number: 4,
        statement:
            'Determine appropriate incident investigation techniques (root causes) and apply corrective actions.',
      ),
      Csp11Competency(
        id: 'd02_c05',
        domainId: 'domain_02',
        number: 5,
        statement:
            'Describe the Management of Change process. (prior, during, after)',
      ),
      Csp11Competency(
        id: 'd02_c06',
        domainId: 'domain_02',
        number: 6,
        statement:
            'Describe system safety analysis techniques. (e.g., fault tree analysis, failure modes and effects analysis [FMEA], Safety Case approach, risk summation)',
      ),
      Csp11Competency(
        id: 'd02_c07',
        domainId: 'domain_02',
        number: 7,
        statement:
            'Evaluate leading and lagging indicators.',
      ),
      Csp11Competency(
        id: 'd02_c08',
        domainId: 'domain_02',
        number: 8,
        statement:
            'Recognize safety, health, and environmental management and audit systems. (e.g., ISO 14000 series, 45001, 19011, ANSI Z10)',
      ),
      Csp11Competency(
        id: 'd02_c09',
        domainId: 'domain_02',
        number: 9,
        statement:
            'Describe required components for plans, systems, and policies. (e.g., safety, health, and environmental regulations and standards)',
      ),
      Csp11Competency(
        id: 'd02_c10',
        domainId: 'domain_02',
        number: 10,
        statement:
            'Utilize document retention or management principles.',
      ),
      Csp11Competency(
        id: 'd02_c11',
        domainId: 'domain_02',
        number: 11,
        statement:
            'Apply budgeting, finance, and economic analysis techniques and principles.',
      ),
      Csp11Competency(
        id: 'd02_c12',
        domainId: 'domain_02',
        number: 12,
        statement:
            'Differentiate management leadership techniques.',
      ),
      Csp11Competency(
        id: 'd02_c13',
        domainId: 'domain_02',
        number: 13,
        statement:
            'Apply project management principles and techniques.',
      ),
      Csp11Competency(
        id: 'd02_c14',
        domainId: 'domain_02',
        number: 14,
        statement:
            'Analyze and/or interpret data.',
      ),
    ],
  ),

  Csp11Domain(
    id: 'domain_03',
    number: 3,
    title: 'Risk Management',
    weightPercent: 15,
    competencies: <Csp11Competency>[
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
    competencies: <Csp11Competency>[
      Csp11Competency(
        id: 'd04_c01',
        domainId: 'domain_04',
        number: 1,
        statement:
            'Create, employ, and maintain an Emergency Response Plan.',
      ),
      Csp11Competency(
        id: 'd04_c02',
        domainId: 'domain_04',
        number: 2,
        statement:
            'Describe the elements in disaster response and recovery.',
      ),
      Csp11Competency(
        id: 'd04_c03',
        domainId: 'domain_04',
        number: 3,
        statement:
            'Identify key components of fire prevention, protection, and suppression systems.',
      ),
      Csp11Competency(
        id: 'd04_c04',
        domainId: 'domain_04',
        number: 4,
        statement:
            'Prepare procedures for the safe transportation and security of hazardous materials.',
      ),
      Csp11Competency(
        id: 'd04_c05',
        domainId: 'domain_04',
        number: 5,
        statement:
            'Implement a workplace violence prevention program.',
      ),
    ],
  ),

  Csp11Domain(
    id: 'domain_05',
    number: 5,
    title: 'Environmental Management',
    weightPercent: 6,
    competencies: <Csp11Competency>[
      Csp11Competency(
        id: 'd05_c01',
        domainId: 'domain_05',
        number: 1,
        statement:
            'Describe environmental protection and pollution prevention programs.',
      ),
      Csp11Competency(
        id: 'd05_c02',
        domainId: 'domain_05',
        number: 2,
        statement:
            'Identify procedures used to manage hazardous materials.',
      ),
      Csp11Competency(
        id: 'd05_c03',
        domainId: 'domain_05',
        number: 3,
        statement:
            'Identify procedures used to manage waste.',
      ),
      Csp11Competency(
        id: 'd05_c04',
        domainId: 'domain_05',
        number: 4,
        statement:
            'Determine sustainability principles and practices.',
      ),
      Csp11Competency(
        id: 'd05_c05',
        domainId: 'domain_05',
        number: 5,
        statement:
            'Describe the impact of environmental issues.',
      ),
    ],
  ),

  Csp11Domain(
    id: 'domain_06',
    number: 6,
    title: 'Occupational Health and Applied Science',
    weightPercent: 10,
    competencies: <Csp11Competency>[
      Csp11Competency(
        id: 'd06_c01',
        domainId: 'domain_06',
        number: 1,
        statement:
            'Anticipate, recognize, evaluate, and control occupational exposures by implementing techniques for measurement, sampling, and analysis.',
      ),
      Csp11Competency(
        id: 'd06_c02',
        domainId: 'domain_06',
        number: 2,
        statement:
            'Understand principles of public health as applicable.',
      ),
      Csp11Competency(
        id: 'd06_c03',
        domainId: 'domain_06',
        number: 3,
        statement:
            'Apply toxicology principles to create exposure control plans and develop risk mitigation plans.',
      ),
      Csp11Competency(
        id: 'd06_c04',
        domainId: 'domain_06',
        number: 4,
        statement:
            'Evaluate principles related to ergonomics and human factors.',
      ),
      Csp11Competency(
        id: 'd06_c05',
        domainId: 'domain_06',
        number: 5,
        statement:
            'Apply chemistry principles to calculate required containment volumes and hazardous materials storage requirements.',
      ),
      Csp11Competency(
        id: 'd06_c06',
        domainId: 'domain_06',
        number: 6,
        statement:
            'Apply core concepts in physics.',
      ),
    ],
  ),

  Csp11Domain(
    id: 'domain_07',
    number: 7,
    title: 'Training',
    weightPercent: 10,
    competencies: <Csp11Competency>[
      Csp11Competency(
        id: 'd07_c01',
        domainId: 'domain_07',
        number: 1,
        statement:
            'Describe the needs assessment process to determine worker training, competencies, and qualifications.',
      ),
      Csp11Competency(
        id: 'd07_c02',
        domainId: 'domain_07',
        number: 2,
        statement:
            'Develop training programs with training materials to address various learning styles.',
      ),
      Csp11Competency(
        id: 'd07_c03',
        domainId: 'domain_07',
        number: 3,
        statement:
            'Describe how to implement training programs utilizing the Continuous Improvement model.',
      ),
      Csp11Competency(
        id: 'd07_c04',
        domainId: 'domain_07',
        number: 4,
        statement:
            'Determine the effectiveness of training programs.',
      ),
      Csp11Competency(
        id: 'd07_c05',
        domainId: 'domain_07',
        number: 5,
        statement:
            'Demonstrate working knowledge of education and training methods and techniques.',
      ),
      Csp11Competency(
        id: 'd07_c06',
        domainId: 'domain_07',
        number: 6,
        statement:
            'Understand adult learning principles.',
      ),
    ],
  ),
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

Csp11Competency? competencyForId(String id) {
  final normalized = id.trim().toLowerCase();

  for (final domain in csp11Domains) {
    for (final competency in domain.competencies) {
      if (competency.id.toLowerCase() == normalized) {
        return competency;
      }
    }
  }

  return null;
}

List<Csp11Competency> competenciesForDomain(String domainId) {
  final domain = domainForContentId(domainId);

  if (domain == null) {
    return const <Csp11Competency>[];
  }

  return domain.competencies;
}

Csp11Competency? competencyForDomainAndNumber(
  String domainId,
  int competencyNumber,
) {
  final domain = domainForContentId(domainId);

  if (domain == null) {
    return null;
  }

  for (final competency in domain.competencies) {
    if (competency.number == competencyNumber) {
      return competency;
    }
  }

  return null;
}
