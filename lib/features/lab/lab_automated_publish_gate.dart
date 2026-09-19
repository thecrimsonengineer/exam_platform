import 'lab_contracts.dart';
import 'lab_dqg300.dart';
import 'lab_exhaustive_route_validator.dart';
import 'lab_validation.dart';

class LabAutomatedPublishGateReport {
  const LabAutomatedPublishGateReport({
    required this.structuralReport,
    required this.dqg300Report,
    required this.runtimeNodeCoverageComplete,
    required this.runtimeEndingCoverageComplete,
    required this.exhaustiveRouteReport,
  });

  final LabValidationReport structuralReport;
  final LabDqg300Report dqg300Report;
  final bool runtimeNodeCoverageComplete;
  final bool runtimeEndingCoverageComplete;
  final LabExhaustiveRouteReport exhaustiveRouteReport;

  bool get isPublishable =>
      structuralReport.isValid &&
      structuralReport.errorCount == 0 &&
      structuralReport.warningCount == 0 &&
      structuralReport.simulationCount > 0 &&
      runtimeNodeCoverageComplete &&
      runtimeEndingCoverageComplete &&
      dqg300Report.isValid &&
      exhaustiveRouteReport.isValid;
}

class LabAutomatedPublishGate {
  const LabAutomatedPublishGate({
    this.labValidator = const LabValidationEngine(),
    this.dqg300Validator = const LabDqg300Validator(),
    this.exhaustiveRouteValidator = const LabExhaustiveRouteValidator(),
  });

  final LabValidationEngine labValidator;
  final LabDqg300Validator dqg300Validator;
  final LabExhaustiveRouteValidator exhaustiveRouteValidator;

  LabAutomatedPublishGateReport evaluate({
    required LabPackage package,
    required Map<String, Object?> root,
    required LabDqg300EvidenceBundle dqg300Evidence,
    Set<String>? availableAssetIds,
    Set<String>? allowedCompetencyIds,
    int simulationLimit = 1000,
    int exhaustiveRouteLimit = 1000,
  }) {
    final structural = labValidator.validatePackage(
      package,
      root: root,
      availableAssetIds: availableAssetIds,
      allowedCompetencyIds: allowedCompetencyIds,
      simulationLimit: simulationLimit,
    );
    final dqg300 = dqg300Validator.validate(
      package: package,
      evidenceBundle: dqg300Evidence,
    );

    final exhaustive = exhaustiveRouteValidator.run(
      package,
      maxRoutes: exhaustiveRouteLimit,
    );

    final expectedNodes = package.nodes.map((node) => node.id).toSet();
    final expectedEndings = package.endings
        .map((ending) => ending['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();

    return LabAutomatedPublishGateReport(
      structuralReport: structural,
      dqg300Report: dqg300,
      runtimeNodeCoverageComplete: structural.reachableNodeIds.containsAll(
        expectedNodes,
      ),
      runtimeEndingCoverageComplete: structural.reachableEndingIds.containsAll(
        expectedEndings,
      ),
      exhaustiveRouteReport: exhaustive,
    );
  }
}
