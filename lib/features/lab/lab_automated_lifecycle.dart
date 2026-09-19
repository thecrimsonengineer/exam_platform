import 'dart:convert';

import 'lab_automated_publish_gate.dart';
import 'lab_contracts.dart';
import 'lab_dqg300.dart';
import 'lab_dqg300_certificate.dart';
import 'lab_studio.dart';

class LabAutomatedLifecycleResult {
  const LabAutomatedLifecycleResult({
    required this.workspace,
    required this.gateReport,
    required this.certificate,
  });

  final LabStudioWorkspace workspace;
  final LabAutomatedPublishGateReport gateReport;
  final LabDqg300EvidenceCertificate certificate;
}

class LabAutomatedLifecycleService {
  const LabAutomatedLifecycleService({
    required this.studio,
    this.publishGate = const LabAutomatedPublishGate(),
    this.validationAuthority = 'DQG300-LAB-AUTO',
  });

  final Lab1000StudioService studio;
  final LabAutomatedPublishGate publishGate;
  final String validationAuthority;

  Future<LabAutomatedLifecycleResult> validateAndPublish({
    required LabStudioWorkspace workspace,
    required LabDqg300EvidenceBundle dqg300Evidence,
    DateTime? validatedAt,
    DateTime? publishedAt,
  }) async {
    if (workspace.lifecycle != LabLifecycleStatus.draft) {
      throw const LabStudioException(
        'Automated LAB publish starts from DRAFT.',
      );
    }
    if (validationAuthority.trim().isEmpty) {
      throw const LabStudioException(
        'Automated LAB validation authority is required.',
      );
    }

    final initialGate = publishGate.evaluate(
      package: workspace.package,
      root: workspace.root,
      dqg300Evidence: dqg300Evidence,
    );
    if (!initialGate.isPublishable) {
      throw const LabStudioException(
        'Automated LAB publish gate blocked this version.',
      );
    }

    final review = _transition(workspace, LabLifecycleStatus.review);
    final validated = _transition(review, LabLifecycleStatus.validated);

    final validatedGate = publishGate.evaluate(
      package: validated.package,
      root: validated.root,
      dqg300Evidence: dqg300Evidence,
    );
    if (!validatedGate.isPublishable) {
      throw const LabStudioException(
        'Automated LAB publish gate did not remain valid after lifecycle validation.',
      );
    }

    final published = _transition(validated, LabLifecycleStatus.published);
    final validationTime = validatedAt ?? DateTime.now().toUtc();
    final certificate = LabDqg300EvidenceCertificate.fromReport(
      package: published.package,
      report: validatedGate.dqg300Report,
      validationAuthority: validationAuthority,
      validatedAt: validationTime,
    );

    final version = LabPublishedVersion(
      labId: published.package.metadata.id,
      versionId: published.package.metadata.versionId,
      publishedJson: published.sourceJson,
      publishedAt: publishedAt ?? validationTime,
      reviewerId: validationAuthority,
      validationAuthority: validationAuthority,
      qualityEvidenceJson: certificate.encode(),
    );

    await studio.repository.saveImmutable(version);

    return LabAutomatedLifecycleResult(
      workspace: published.copyWith(
        reviewerId: validationAuthority,
        publishedVersion: version,
      ),
      gateReport: validatedGate,
      certificate: certificate,
    );
  }

  LabStudioWorkspace _transition(
    LabStudioWorkspace workspace,
    LabLifecycleStatus next,
  ) {
    LabLifecyclePolicy.requireTransition(workspace.lifecycle, next);

    final decoded = jsonDecode(jsonEncode(workspace.root));
    final root = (decoded as Map).cast<String, Object?>();
    final rawLab = root['lab'];
    if (rawLab is! Map) {
      throw const LabStudioException('LAB metadata is missing.');
    }
    final lab = rawLab.cast<String, Object?>();
    lab['lifecycle'] = next.name.toUpperCase();
    root['lab'] = lab;

    final package = LabPackage.fromJson(root);
    final report = studio.validator.validatePackage(package, root: root);
    if (!report.isValid) {
      throw const LabStudioException(
        'Automated lifecycle transition produced an invalid LAB.',
      );
    }

    return LabStudioWorkspace(
      sourceJson: jsonEncode(root),
      root: root,
      package: package,
      report: report,
      reviewerId: validationAuthority,
    );
  }
}
