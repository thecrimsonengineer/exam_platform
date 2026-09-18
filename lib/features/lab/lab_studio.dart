import 'dart:convert';

import 'lab_contracts.dart';
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
  });

  final String labId;
  final String versionId;
  final String publishedJson;
  final DateTime publishedAt;
  final String reviewerId;
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
    _versions[key] = version;
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
    if (!workspace.isPublished) {
      throw const LabStudioException(
        'A new version is created from an immutable published LAB.',
      );
    }
    LabIds.requireCanonical(newVersionId, 'LAB version ID');
    if (newVersionId == workspace.package.metadata.versionId) {
      throw const LabStudioException(
        'New LAB version ID must differ from the published version.',
      );
    }

    final mutable = _deepCopy(workspace.root);
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
