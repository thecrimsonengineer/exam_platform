import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/features/lab/lab_state.dart';

LabStateRegistry buildRegistry() {
  return LabStateRegistry([
    LabStateVariableDefinition(id: 'hazard_active', kind: LabStateKind.boolean),
    LabStateVariableDefinition(
      id: 'risk_score',
      kind: LabStateKind.boundedNumeric,
      min: 0,
      max: 100,
    ),
    LabStateVariableDefinition(
      id: 'work_status',
      kind: LabStateKind.enumeration,
      allowedValues: const ['stopped', 'active'],
    ),
    LabStateVariableDefinition(
      id: 'evidence_tags',
      kind: LabStateKind.stringSet,
    ),
    LabStateVariableDefinition(id: 'actions', kind: LabStateKind.stringList),
    LabStateVariableDefinition(
      id: 'worker_collapsed',
      kind: LabStateKind.boolean,
      irreversible: true,
    ),
  ]);
}

Map<String, Object?> buildStartingState({
  bool hazardActive = false,
  num riskScore = 10,
  String workStatus = 'stopped',
  List<String> evidenceTags = const [],
  List<String> actions = const [],
  bool workerCollapsed = false,
}) {
  return {
    'hazard_active': hazardActive,
    'risk_score': riskScore,
    'work_status': workStatus,
    'evidence_tags': evidenceTags,
    'actions': actions,
    'worker_collapsed': workerCollapsed,
  };
}

LabState buildState({
  bool hazardActive = false,
  num riskScore = 10,
  String workStatus = 'stopped',
  List<String> evidenceTags = const [],
  List<String> actions = const [],
  bool workerCollapsed = false,
}) {
  return LabState.initial(
    registry: buildRegistry(),
    startingState: buildStartingState(
      hazardActive: hazardActive,
      riskScore: riskScore,
      workStatus: workStatus,
      evidenceTags: evidenceTags,
      actions: actions,
      workerCollapsed: workerCollapsed,
    ),
  );
}

LabConsequence consequence({
  required String id,
  required List<LabStateMutation> mutations,
  Iterable<String> evidenceUnlocks = const [],
  int simulatedMinutes = 0,
  bool explicitNoOp = false,
}) {
  return LabConsequence(
    id: id,
    mutations: mutations,
    evidenceUnlocks: evidenceUnlocks,
    simulatedMinutes: simulatedMinutes,
    explicitNoOp: explicitNoOp,
  );
}

LabPackage buildPackage({
  LabLifecycleStatus lifecycle = LabLifecycleStatus.draft,
}) {
  final registry = buildRegistry();
  final options = List<LabDecisionOption>.generate(
    4,
    (index) => LabDecisionOption(
      id: 'option_' + (index + 1).toString(),
      text: 'Option ' + (index + 1).toString(),
      isBest: index == 0,
      quality: index == 0
          ? LabDecisionQuality.optimal
          : index == 1
          ? LabDecisionQuality.defensible
          : index == 2
          ? LabDecisionQuality.weak
          : LabDecisionQuality.critical,
      consequence: LabConsequence(
        id: 'consequence_' + (index + 1).toString(),
        explicitNoOp: true,
      ),
    ),
  );

  return LabPackage(
    schemaVersion: kLabSchemaVersion,
    metadata: LabMetadata(
      id: 'lab_foundation',
      versionId: 'v1',
      title: 'Foundation LAB',
      description: 'Fixture package for Phase L tests.',
      lifecycle: lifecycle,
      supportedModes: const [
        LabMode.guided,
        LabMode.professional,
        LabMode.assessment,
      ],
      startingNodeId: 'decision_start',
      startingState: buildStartingState(),
      competencyMappings: const ['d01_c01'],
      sources: const ['source_1'],
    ),
    stateRegistry: registry,
    nodes: [
      LabDecisionNode(
        id: 'decision_start',
        prompt: 'Choose the safest action.',
        options: options,
      ),
    ],
    gates: const [],
    endings: const [],
  );
}
