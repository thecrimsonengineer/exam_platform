import 'dart:convert';

import 'lab_automated_lifecycle.dart';
import 'lab_contracts.dart';
import 'lab_decision_quality_gate.dart';
import 'lab_dqg300.dart';
import 'lab_learner_presentation.dart';
import 'lab_scenario_population_manifest.dart';
import 'lab_studio.dart';

class LabScenarioPopulationAdmissionResult {
  const LabScenarioPopulationAdmissionResult({
    required this.manifestId,
    required this.entry,
    required this.bindingReport,
    required this.decisionQualityReport,
    required this.lifecycleResult,
    required this.publishedVersion,
  });

  final String manifestId;
  final LabScenarioPopulationManifestEntry entry;
  final LabScenarioPopulationBindingReport bindingReport;
  final LabDecisionQualityReport decisionQualityReport;
  final LabAutomatedLifecycleResult lifecycleResult;
  final LabPublishedVersion publishedVersion;

  bool get isAdmitted =>
      bindingReport.isValid &&
      decisionQualityReport.isValid &&
      lifecycleResult.gateReport.isPublishable &&
      lifecycleResult.workspace.lifecycle == LabLifecycleStatus.published &&
      publishedVersion.labId == entry.labId &&
      publishedVersion.versionId == entry.versionId;
}

/// LSP-Q11 population publication gate.
///
/// Admission is allowed only for an entry that already exists in the Q9/Q10
/// population manifest and still passes the complete frozen quality chain:
///
/// Q9 binding
/// AND Q4-Q7 Decision quality
/// AND L4K/L4L/L4M/L4N automated publication evidence
/// AND immutable repository acceptance.
///
/// This service does not add the admitted LAB to a learner catalogue.
class LabScenarioPopulationPublicationGate {
  const LabScenarioPopulationPublicationGate({
    required this.studio,
    this.bindingValidator = const LabScenarioPopulationBindingValidator(),
    this.decisionQualityGate = const LabDecisionQualityGate(),
    this.validationAuthority = 'LSP-Q11-POPULATION-AUTO',
  });

  final Lab1000StudioService studio;
  final LabScenarioPopulationBindingValidator bindingValidator;
  final LabDecisionQualityGate decisionQualityGate;
  final String validationAuthority;

  Future<LabScenarioPopulationAdmissionResult> admit({
    required LabScenarioPopulationManifest manifest,
    required String entryId,
    required Map<String, Object?> technicalRoot,
    required LabDqg300EvidenceBundle dqg300Evidence,
    required LabLearnerPresentationPackage presentationPackage,
    DateTime? validatedAt,
    DateTime? publishedAt,
  }) async {
    final entry = manifest.requireEntry(entryId);
    final package = LabPackage.fromJson(technicalRoot);

    final binding = bindingValidator.validate(
      entry: entry,
      technicalPackage: package,
      dqg300Evidence: dqg300Evidence,
      presentationPackage: presentationPackage,
    );
    if (!binding.isValid) {
      throw LabStudioException(
        'Q11 population binding gate blocked ' + entry.identityKey + '.',
      );
    }

    final decisionQuality = decisionQualityGate.evaluate(
      package: package,
      evidenceBundle: dqg300Evidence,
    );
    if (!decisionQuality.isValid) {
      throw LabStudioException(
        'Q11 Decision quality gate blocked ' + entry.identityKey + '.',
      );
    }

    if (package.metadata.lifecycle != LabLifecycleStatus.draft) {
      throw LabStudioException(
        'Q11 repository admission requires the manifest-backed source to remain DRAFT.',
      );
    }

    final existing = await studio.repository.load(entry.labId, entry.versionId);
    if (existing != null) {
      throw LabStudioException(
        'Q11 immutable repository already contains ' + entry.identityKey + '.',
      );
    }

    final workspace = studio.importJson(jsonEncode(technicalRoot));
    if (workspace.package.metadata.id != entry.labId ||
        workspace.package.metadata.versionId != entry.versionId) {
      throw LabStudioException(
        'Q11 Studio import identity drifted from manifest entry ' +
            entry.identityKey +
            '.',
      );
    }

    final lifecycle =
        await LabAutomatedLifecycleService(
          studio: studio,
          validationAuthority: validationAuthority,
        ).validateAndPublish(
          workspace: workspace,
          dqg300Evidence: dqg300Evidence,
          validatedAt: validatedAt,
          publishedAt: publishedAt,
        );

    final stored = await studio.repository.load(entry.labId, entry.versionId);
    if (stored == null) {
      throw LabStudioException(
        'Q11 repository admission did not persist ' + entry.identityKey + '.',
      );
    }

    final storedPackage = LabPackage.decode(stored.publishedJson);
    if (storedPackage.metadata.lifecycle != LabLifecycleStatus.published ||
        storedPackage.metadata.id != entry.labId ||
        storedPackage.metadata.versionId != entry.versionId ||
        stored.validationAuthority != validationAuthority ||
        stored.qualityEvidenceJson == null ||
        stored.exhaustiveRouteEvidenceJson == null ||
        stored.publishEvidenceJson == null ||
        stored.snapshotFingerprint == null) {
      throw LabStudioException(
        'Q11 immutable repository admission is incomplete for ' +
            entry.identityKey +
            '.',
      );
    }

    return LabScenarioPopulationAdmissionResult(
      manifestId: manifest.manifestId,
      entry: entry,
      bindingReport: binding,
      decisionQualityReport: decisionQuality,
      lifecycleResult: lifecycle,
      publishedVersion: stored,
    );
  }
}
