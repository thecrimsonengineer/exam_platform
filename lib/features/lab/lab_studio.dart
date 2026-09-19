import 'dart:convert';

import 'lab_contracts.dart';
import 'lab_dqg300.dart';
import 'lab_dqg300_certificate.dart';
import 'lab_l4l_certificate.dart';
import 'lab_l4n_certificate.dart';
import 'lab_validation.dart';

class LabStudioException implements Exception {
  const LabStudioException(this.message);

  final String message;

  @override
  String toString() => 'LabStudioException: $message';
}

class LabStudioPreview {
  const LabStudioPreview({
    required this.labId,
    required this.versionId,
    required this.title,
    required this.nodeCount,
    required this.decisionCount,
    required this.gateCount,
    required this.endingCount,
    required this.stateVariableCount,
  });

  final String labId;
  final String versionId;
  final String title;
  final int nodeCount;
  final int decisionCount;
  final int gateCount;
  final int endingCount;
  final int stateVariableCount;
}

class LabStudioInspection {
  const LabStudioInspection({
    required this.metadata,
    required this.stateVariableIds,
    required this.nodeIds,
    required this.gateIds,
    required this.endingIds,
    required this.evidenceIds,
  });

  final LabMetadata metadata;
  final List<String> stateVariableIds;
  final List<String> nodeIds;
  final List<String> gateIds;
  final List<String> endingIds;
  final List<String> evidenceIds;
}

class LabStudioWorkspace {
  LabStudioWorkspace({
    required this.sourceJson,
    required Map<String, Object?> root,
    required this.package,
    required this.report,
    this.reviewerId,
    this.publishedVersion,
  }) : root = Map<String, Object?>.unmodifiable(root);

  final String sourceJson;
  final Map<String, Object?> root;
  final LabPackage package;
  final LabValidationReport report;
  final String? reviewerId;
  final LabPublishedVersion? publishedVersion;

  LabLifecycleStatus get lifecycle => package.metadata.lifecycle;
  bool get isPublished => lifecycle == LabLifecycleStatus.published;

  LabStudioWorkspace copyWith({
    String? sourceJson,
    Map<String, Object?>? root,
    LabPackage? package,
    LabValidationReport? report,
    String? reviewerId,
    bool clearReviewer = false,
    LabPublishedVersion? publishedVersion,
    bool clearPublishedVersion = false,
  }) {
    return LabStudioWorkspace(
      sourceJson: sourceJson ?? this.sourceJson,
      root: root ?? this.root,
      package: package ?? this.package,
      report: report ?? this.report,
      reviewerId: clearReviewer ? null : (reviewerId ?? this.reviewerId),
      publishedVersion: clearPublishedVersion
          ? null
          : (publishedVersion ?? this.publishedVersion),
    );
  }
}

class LabPublishedVersion {
  const LabPublishedVersion({
    required this.labId,
    required this.versionId,
    required this.publishedJson,
    required this.publishedAt,
    required this.reviewerId,
    this.validationAuthority,
    this.qualityEvidenceJson,
    this.exhaustiveRouteEvidenceJson,
    this.publishEvidenceJson,
  });

  final String labId;
  final String versionId;
  final String publishedJson;
  final DateTime publishedAt;
  final String reviewerId;
  final String? validationAuthority;
  final String? qualityEvidenceJson;
  final String? exhaustiveRouteEvidenceJson;
  final String? publishEvidenceJson;
}

abstract class LabPublishedRepository {
  Future<void> saveImmutable(LabPublishedVersion version);

  Future<LabPublishedVersion?> load(String labId, String versionId);
}

class InMemoryLabPublishedRepository implements LabPublishedRepository {
  final Map<String, LabPublishedVersion> _versions =
      <String, LabPublishedVersion>{};

  String _key(String labId, String versionId) => '$labId::$versionId';

  @override
  Future<LabPublishedVersion?> load(String labId, String versionId) async =>
      _versions[_key(labId, versionId)];

  @override
  Future<void> saveImmutable(LabPublishedVersion version) async {
    final key = _key(version.labId, version.versionId);
    if (_versions.containsKey(key)) {
      throw const LabStudioException(
        'Published LAB versions are immutable and cannot be overwritten.',
      );
    }
    _validateImmutableSnapshot(version);
    _versions[key] = version;
  }

  void _validateImmutableSnapshot(LabPublishedVersion version) {
    if (version.reviewerId.trim().isEmpty) {
      throw const LabStudioException(
        'Published LAB snapshot requires a reviewer or validation authority.',
      );
    }

    late final LabPackage package;
    try {
      package = LabPackage.decode(version.publishedJson);
    } catch (error) {
      throw LabStudioException(
        'Published LAB snapshot is invalid: ' + error.toString(),
      );
    }

    if (package.metadata.lifecycle != LabLifecycleStatus.published) {
      throw const LabStudioException(
        'Immutable repository accepts only PUBLISHED LAB snapshots.',
      );
    }
    if (package.metadata.id != version.labId ||
        package.metadata.versionId != version.versionId) {
      throw const LabStudioException(
        'Published LAB snapshot identity does not match its repository key.',
      );
    }

    final authority = version.validationAuthority;
    final hasAutomatedEvidence =
        version.qualityEvidenceJson != null ||
        version.exhaustiveRouteEvidenceJson != null ||
        version.publishEvidenceJson != null;

    if (authority == null) {
      if (hasAutomatedEvidence) {
        throw const LabStudioException(
          'Automated LAB evidence requires a validation authority.',
        );
      }
      return;
    }
    if (authority.trim().isEmpty || version.reviewerId.trim() != authority.trim()) {
      throw const LabStudioException(
        'Automated LAB validation authority must match the published reviewer.',
      );
    }

    final dqgSource = version.qualityEvidenceJson;
    final l4lSource = version.exhaustiveRouteEvidenceJson;
    final l4nSource = version.publishEvidenceJson;
    if (dqgSource == null || l4lSource == null || l4nSource == null) {
      throw const LabStudioException(
        'Automated LAB publication requires DQG300, L4L and L4N evidence.',
      );
    }

    late final LabDqg300EvidenceCertificate dqg;
    late final LabL4lEvidenceCertificate l4l;
    late final LabL4nPublishEvidenceCertificate l4n;
    try {
      dqg = LabDqg300EvidenceCertificate.decode(dqgSource);
      l4l = LabL4lEvidenceCertificate.decode(l4lSource);
      l4n = LabL4nPublishEvidenceCertificate.decode(l4nSource);
    } catch (error) {
      throw LabStudioException(
        'Automated LAB evidence certificate is invalid: ' + error.toString(),
      );
    }

    bool pinned(String labId, String versionId, String certAuthority) =>
        labId == version.labId &&
        versionId == version.versionId &&
        certAuthority == authority.trim();

    if (!pinned(dqg.labId, dqg.versionId, dqg.validationAuthority) ||
        !pinned(l4l.labId, l4l.versionId, l4l.validationAuthority) ||
        !pinned(l4n.labId, l4n.versionId, l4n.validationAuthority) ||
        !dqg.isPass ||
        !l4l.isPass ||
        !l4n.isPass) {
      throw const LabStudioException(
        'Automated LAB evidence is not valid for this immutable version.',
      );
    }

    if (dqg.validatedAtIso != l4l.validatedAtIso ||
        dqg.validatedAtIso != l4n.validatedAtIso) {
      throw const LabStudioException(
        'Automated LAB evidence certificates must share one validation timestamp.',
      );
    }

    final decisionCertificates = <String, LabDqg300DecisionCertificate>{
      for (final decision in dqg.decisions) decision.nodeId: decision,
    };
    final decisionNodes = package.nodes.whereType<LabDecisionNode>().toList();
    if (decisionCertificates.length != decisionNodes.length ||
        decisionNodes.any((node) {
          final certificate = decisionCertificates[node.id];
          return certificate == null ||
              certificate.decisionSignature !=
                  LabDqg300Validator.decisionSignature(node);
        })) {
      throw const LabStudioException(
        'DQG300 evidence does not match the immutable Decision Node content.',
      );
    }

    if (l4n.routeExplorationEvidence['exhaustiveProofFingerprint'] !=
        l4l.routeEvidence['fingerprint']) {
      throw const LabStudioException(
        'L4N route exploration is not bound to the persisted L4L proof.',
      );
    }
  }
}

class Lab1000StudioService {
  const Lab1000StudioService({
    this.validator = const LabValidationEngine(),
    required this.repository,
  });

  final LabValidationEngine validator;
  final LabPublishedRepository repository;

  LabStudioWorkspace importJson(
    String source, {
    Set<String>? availableAssetIds,
    Set<String>? allowedCompetencyIds,
  }) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const LabStudioException('LAB JSON root must be an object.');
    }
    final root = decoded.cast<String, Object?>();
    final package = LabPackage.fromJson(root);
    final report = validator.validatePackage(
      package,
      root: root,
      availableAssetIds: availableAssetIds,
      allowedCompetencyIds: allowedCompetencyIds,
    );

    return LabStudioWorkspace(
      sourceJson: source,
      root: root,
      package: package,
      report: report,
    );
  }

  LabStudioWorkspace pasteJson(
    String source, {
    Set<String>? availableAssetIds,
    Set<String>? allowedCompetencyIds,
  }) => importJson(
    source,
    availableAssetIds: availableAssetIds,
    allowedCompetencyIds: allowedCompetencyIds,
  );

  LabStudioWorkspace validate(
    LabStudioWorkspace workspace, {
    Set<String>? availableAssetIds,
    Set<String>? allowedCompetencyIds,
  }) {
    final report = validator.validatePackage(
      workspace.package,
      root: workspace.root,
      availableAssetIds: availableAssetIds,
      allowedCompetencyIds: allowedCompetencyIds,
    );
    return workspace.copyWith(report: report);
  }

  LabStudioInspection inspect(LabStudioWorkspace workspace) {
    String idOf(Map<String, Object?> item) => item['id']?.toString() ?? '';

    return LabStudioInspection(
      metadata: workspace.package.metadata,
      stateVariableIds:
          workspace.package.stateRegistry.definitions.keys.toList()..sort(),
      nodeIds: workspace.package.nodes.map((node) => node.id).toList()..sort(),
      gateIds: workspace.package.gates.map(idOf).toList()..sort(),
      endingIds: workspace.package.endings.map(idOf).toList()..sort(),
      evidenceIds: workspace.package.evidence.map(idOf).toList()..sort(),
    );
  }

  LabStudioPreview createPreview(LabStudioWorkspace workspace) {
    final package = workspace.package;
    return LabStudioPreview(
      labId: package.metadata.id,
      versionId: package.metadata.versionId,
      title: package.metadata.title,
      nodeCount: package.nodes.length,
      decisionCount: package.nodes.whereType<LabDecisionNode>().length,
      gateCount: package.gates.length,
      endingCount: package.endings.length,
      stateVariableCount: package.stateRegistry.definitions.length,
    );
  }

  LabStudioWorkspace editRoot(
    LabStudioWorkspace workspace,
    Map<String, Object?> editedRoot,
  ) {
    if (workspace.isPublished) {
      throw const LabStudioException(
        'Published LAB versions cannot be edited.',
      );
    }
    final encoded = jsonEncode(editedRoot);
    return importJson(encoded);
  }

  LabStudioWorkspace requestReview(LabStudioWorkspace workspace) {
    if (workspace.lifecycle != LabLifecycleStatus.draft) {
      throw const LabStudioException('Only a DRAFT LAB can enter REVIEW.');
    }
    final checked = validate(workspace);
    if (checked.report.hasBlockingIssues) {
      throw const LabStudioException(
        'Blocking validation issues prevent REVIEW.',
      );
    }
    return _withLifecycle(checked, LabLifecycleStatus.review);
  }

  LabStudioWorkspace approveReview(
    LabStudioWorkspace workspace, {
    required String reviewerId,
  }) {
    if (workspace.lifecycle != LabLifecycleStatus.review) {
      throw const LabStudioException(
        'Reviewer approval requires REVIEW lifecycle.',
      );
    }
    if (reviewerId.trim().isEmpty) {
      throw const LabStudioException('Reviewer ID is required.');
    }

    final checked = validate(workspace);
    if (!checked.report.isValid) {
      throw const LabStudioException(
        'LAB must pass validation before VALIDATED.',
      );
    }

    return _withLifecycle(
      checked,
      LabLifecycleStatus.validated,
      reviewerId: reviewerId.trim(),
    );
  }

  Future<LabStudioWorkspace> publish(
    LabStudioWorkspace workspace, {
    DateTime? publishedAt,
  }) async {
    if (workspace.lifecycle != LabLifecycleStatus.validated) {
      throw const LabStudioException('Only a VALIDATED LAB can be published.');
    }
    if (workspace.reviewerId == null || workspace.reviewerId!.isEmpty) {
      throw const LabStudioException(
        'Reviewer approval is required before publish.',
      );
    }

    final checked = validate(workspace);
    if (!checked.report.isValid) {
      throw const LabStudioException(
        'Blocking validation issues prevent publish.',
      );
    }

    final publishedWorkspace = _withLifecycle(
      checked,
      LabLifecycleStatus.published,
    );
    final version = LabPublishedVersion(
      labId: publishedWorkspace.package.metadata.id,
      versionId: publishedWorkspace.package.metadata.versionId,
      publishedJson: publishedWorkspace.sourceJson,
      publishedAt: publishedAt ?? DateTime.now().toUtc(),
      reviewerId: publishedWorkspace.reviewerId!,
    );
    await repository.saveImmutable(version);
    return publishedWorkspace.copyWith(publishedVersion: version);
  }

  LabStudioWorkspace createRevision(
    LabStudioWorkspace workspace, {
    required String newVersionId,
  }) {
    final immutable = workspace.publishedVersion;
    if (!workspace.isPublished || immutable == null) {
      throw const LabStudioException(
        'A new version must be created from a persisted immutable LAB.',
      );
    }
    if (immutable.labId != workspace.package.metadata.id ||
        immutable.versionId != workspace.package.metadata.versionId ||
        immutable.publishedJson != workspace.sourceJson ||
        jsonEncode(workspace.root) != immutable.publishedJson ||
        immutable.reviewerId != workspace.reviewerId) {
      throw const LabStudioException(
        'Published workspace no longer matches its immutable repository snapshot.',
      );
    }
    LabIds.requireCanonical(newVersionId, 'LAB version ID');
    if (newVersionId == workspace.package.metadata.versionId) {
      throw const LabStudioException(
        'New LAB version ID must differ from the published version.',
      );
    }

    final immutableDecoded = jsonDecode(immutable.publishedJson);
    if (immutableDecoded is! Map) {
      throw const LabStudioException(
        'Immutable published LAB snapshot is no longer decodable.',
      );
    }
    final mutable = _deepCopy(
      immutableDecoded.cast<String, Object?>(),
    );
    final lab = mutable['lab'];
    if (lab is! Map) {
      throw const LabStudioException('LAB metadata is missing.');
    }
    final labMap = lab.cast<String, Object?>();
    labMap['versionId'] = newVersionId;
    labMap['lifecycle'] = 'DRAFT';
    mutable['lab'] = labMap;

    return importJson(
      jsonEncode(mutable),
    ).copyWith(clearReviewer: true, clearPublishedVersion: true);
  }

  LabStudioWorkspace _withLifecycle(
    LabStudioWorkspace workspace,
    LabLifecycleStatus lifecycle, {
    String? reviewerId,
  }) {
    final mutable = _deepCopy(workspace.root);
    final lab = mutable['lab'];
    if (lab is! Map) {
      throw const LabStudioException('LAB metadata is missing.');
    }
    final labMap = lab.cast<String, Object?>();
    labMap['lifecycle'] = lifecycle.name.toUpperCase();
    mutable['lab'] = labMap;
    final encoded = jsonEncode(mutable);
    final package = LabPackage.fromJson(mutable);
    final report = validator.validatePackage(package, root: mutable);

    return LabStudioWorkspace(
      sourceJson: encoded,
      root: mutable,
      package: package,
      report: report,
      reviewerId: reviewerId ?? workspace.reviewerId,
    );
  }

  Map<String, Object?> _deepCopy(Map<String, Object?> source) {
    final decoded = jsonDecode(jsonEncode(source));
    return (decoded as Map).cast<String, Object?>();
  }
}
