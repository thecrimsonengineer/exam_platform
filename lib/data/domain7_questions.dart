import '../models/question.dart';

const List<Question> domain7Questions = [
  Question(
    id: 1,
    domain: 7,
    competencyId: 'd07_c01',
    subtopicId: 'd07_c01_s01',
    topicId: 'd07_c01_s01_t01',
    question:
        'A manufacturing site has experienced a rise in errors during a newly introduced automated process. Supervisors recommend refresher training for all operators. Before approving the training, the safety professional reviews incident data, observes operators performing the task, examines the revised procedure, and interviews experienced workers. The review shows that most operators understand the procedure, but the control interface differs significantly from the training environment. What is the BEST conclusion?',
    options: [
      'Provide additional procedural training for all affected operators.',
      'Provide equipment familiarization and task-specific practice.',
      'Increase supervisory oversight until performance improves.',
      'Require competency testing before independent operation resumes.',
    ],
    correctAnswer: 1,
    explanation:
        'The assessment identifies a specific performance gap between the training environment and the actual control interface. Equipment familiarization and task-specific practice directly address the identified gap.',
    reference: 'CSP11 Domain 7: Training Needs Assessment',
    difficulty: 'Hard',
    tags: [
      'Needs Assessment',
      'Training Needs Analysis',
      'Performance Gap',
    ],
  ),

  Question(
    id: 2,
    domain: 7,
    competencyId: 'd07_c01',
    subtopicId: 'd07_c01_s01',
    topicId: 'd07_c01_s01_t02',
    question:
        'An organization requires employees to complete annual confined-space training. A needs assessment identifies that experienced entry supervisors consistently perform well, while newly appointed supervisors struggle with atmospheric-monitoring decisions despite completing the same course. Which finding provides the strongest evidence that the existing training approach should be reassessed?',
    options: [
      'Training records confirm that new supervisors attended the course.',
      'Course surveys indicate that participants considered the content relevant.',
      'Field observations identify recurring gaps during critical decisions.',
      'Supervisor feedback indicates that the technical content is sufficient.',
    ],
    correctAnswer: 2,
    explanation:
        'Field observations provide direct evidence of actual workplace performance and identify recurring competency gaps during critical decisions.',
    reference: 'CSP11 Domain 7: Training Needs Assessment',
    difficulty: 'Hard',
    tags: [
      'Needs Assessment',
      'Competency',
      'Performance Observation',
    ],
  ),

  Question(
    id: 3,
    domain: 7,
    competencyId: 'd07_c01',
    subtopicId: 'd07_c01_s01',
    topicId: 'd07_c01_s01_t03',
    question:
        'A company is investigating why several workers have failed a practical competency assessment for mobile equipment operation. The training department proposes adding two hours of classroom instruction. The safety professional discovers that the assessment uses equipment configurations and operating conditions that were not represented during training. What should be addressed FIRST?',
    options: [
      'Increase classroom instruction before repeating practical assessments.',
      'Replace practical assessment with a written knowledge examination.',
      'Provide additional coaching before workers repeat the assessment.',
      'Verify alignment between training, assessment, and job requirements.',
    ],
    correctAnswer: 3,
    explanation:
        'The first priority is to verify alignment between the training, assessment, and actual job requirements before deciding that additional training is necessary.',
    reference: 'CSP11 Domain 7: Training Needs Assessment',
    difficulty: 'Hard',
    tags: [
      'Needs Assessment',
      'Training Alignment',
      'Competency Assessment',
    ],
  ),

  Question(
    id: 4,
    domain: 7,
    competencyId: 'd07_c01',
    subtopicId: 'd07_c01_s01',
    topicId: 'd07_c01_s01_t04',
    question:
        'A safety professional is conducting a training needs assessment for workers exposed to a newly introduced chemical process. Management states that everyone in the department should receive identical training because they have the same job title. The assessment identifies differences in exposure, responsibilities, decision-making authority, and required emergency actions. What is the MOST appropriate training strategy?',
    options: [
      'Provide common training with role-specific competency requirements.',
      'Provide identical training based on the shared job classification.',
      'Provide advanced training based on potential exposure levels.',
      'Provide awareness training with supervisor-led task instruction.',
    ],
    correctAnswer: 0,
    explanation:
        'Workers with the same job title may have different responsibilities, exposure, decision-making authority, and emergency duties. Training should therefore include common content with role-specific competency requirements.',
    reference: 'CSP11 Domain 7: Training Needs Assessment',
    difficulty: 'Hard',
    tags: [
      'Needs Assessment',
      'Role-Based Training',
      'Competency',
    ],
  ),

  Question(
    id: 5,
    domain: 7,
    competencyId: 'd07_c01',
    subtopicId: 'd07_c01_s01',
    topicId: 'd07_c01_s01_t05',
    question:
        'A company has identified a significant gap between the required competency of maintenance technicians and their current performance. Management immediately requests a training program. During the needs assessment, the safety professional finds that technicians have the necessary knowledge but cannot consistently perform because critical tools are unavailable and the maintenance procedure requires unrealistic production pressures. What is the BEST action?',
    options: [
      'Develop additional technical training to reinforce existing knowledge.',
      'Conduct competency examinations to identify retraining requirements.',
      'Address workplace barriers before selecting training as the solution.',
      'Increase supervisory monitoring to improve procedural compliance.',
    ],
    correctAnswer: 2,
    explanation:
        'The technicians already have the necessary knowledge. The identified performance problem is caused by workplace barriers, so those barriers should be addressed before selecting training as the solution.',
    reference: 'CSP11 Domain 7: Training Needs Assessment',
    difficulty: 'Hard',
    tags: [
      'Needs Assessment',
      'Non-Training Solutions',
      'Performance Barriers',
    ],
  ),
];