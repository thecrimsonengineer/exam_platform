import 'lab_contracts.dart';
import 'lab_dqg300.dart';
import 'lab_exhaustive_route_validator.dart';
import 'lab_publish_evidence_validator.dart';
import 'lab_reachable_route_explorer.dart';
import 'lab_validation.dart';

class LabAutomatedPublishGateReport {
  const LabAutomatedPublishGateReport({
    required this.structuralReport,
    required this.dqg300Report,
    required this.runtimeNodeCoverageComplete,
    required this.runtimeEndingCoverageComplete,
    required this.exhaustiveRouteReport,
    required this.routeExplorationReport,
    required this.publishEvidenceReport,
  });

  final LabValidationReport structuralReport;
  final LabDqg300Report dqg300Report;
  final bool runtimeNodeCoverageComplete;
  final bool runtimeEndingCoverageComplete;
  final LabExhaustiveRouteReport exhaustiveRouteReport;
  final LabReachableRouteExplorationReport routeExplorationReport;
  final LabPublishEvidenceReport publishEvidenceReport;

  bool get isPublishable =>
      structuralReport.isValid &&
      structuralReport.errorCount == 0 &&
      structuralReport.warningCount == 0 &&
      structuralReport.simulationCount > 0 &&
      runtimeNodeCoverageComplete &&
      runtimeEndingCoverageComplete &&
      dqg300Report.isValid &&
      exhaustiveRouteReport.isValid &&
      routeExplorationReport.isValid &&
      publishEvidenceReport.isValid;
}

class LabAutomatedPublishGate {
  const LabAutomatedPublishGate({
    this.labValidator = const LabValidationEngine(),
    this.dqg300Validator = const LabDqg300Validator(),
    this.exhaustiveRouteValidator = const LabExhaustiveRouteValidator(),
    this.routeExplorer = const LabReachableRouteExplorer(),
    this.publishEvidenceValidator = const LabPublishEvidenceValidator(),
  });

  final LabValidationEngine labValidator;
  final LabDqg300Validator dqg300Validator;
  final LabExhaustiveRouteValidator exhaustiveRouteValidator;
  final LabReachableRouteExplorer routeExplorer;
  final LabPublishEvidenceValidator publishEvidenceValidator;

  LabAutomatedPublishGateReport evaluate({
    required LabPackage package,
    required Map<String, Object?> root,
    required LabDqg300EvidenceBundle dqg300Evidence,
    Set<String>? availableAssetIds,
    Set<String>? allowedCompetencyIds,
    int simulationLimit = 1000,
    int exhaustiveRouteLimit = 10000,
    int routeExplorationBudget = 1000,
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
    final effectiveRouteBudget = routeExplorationBudget <= exhaustiveRouteLimit
        ? routeExplorationBudget
        : exhaustiveRouteLimit;
    final routeExploration = routeExplorer.exploreFromExhaustive(
      exhaustive,
      routeBudget: effectiveRouteBudget,
      hardRouteLimit: exhaustiveRouteLimit,
    );
    final publishEvidence = publishEvidenceValidator.validate(
      package: package,
      routeExplorationReport: routeExploration,
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
      routeExplorationReport: routeExploration,
      publishEvidenceReport: publishEvidence,
    );
  }
}
