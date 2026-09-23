import 'lab_contracts.dart';
import 'lab_dqg300.dart';
import 'lab_learner_presentation.dart';

const String kLabScenarioPopulationManifestSchemaVersion =
    'csp11.lab.population_manifest.v1';

class LabScenarioPopulationManifestException implements Exception {
  const LabScenarioPopulationManifestException(this.message);

  final String message;

  @override
  String toString() => 'LabScenarioPopulationManifestException: ' + message;
}

void _requireOnlyManifestKeys(
  Map<String, Object?> json,
  Set<String> allowed,
  String label,
) {
  final unexpected = json.keys.where((key) => !allowed.contains(key)).toList()
    ..sort();
  if (unexpected.isNotEmpty) {
    throw LabScenarioPopulationManifestException(
      label + ' contains forbidden or unknown fields: ' + unexpected.join(', '),
    );
  }
}

String _requiredManifestText(
  Map<String, Object?> json,
  String field,
  String label,
) {
  final value = json[field]?.toString().trim() ?? '';
  if (value.isEmpty) {
    throw LabScenarioPopulationManifestException(
      label + ' requires non-empty ' + field + '.',
    );
  }
  return value;
}

String _requiredRelativeJsonPath(
  Map<String, Object?> json,
  String field,
  String label,
) {
  final value = _requiredManifestText(json, field, label);
  final lower = value.toLowerCase();
  final segments = value.split('/');

  final unsafe =
      value.contains('\\') ||
      value.startsWith('/') ||
      value.startsWith('./') ||
      value.contains('://') ||
      value.contains('?') ||
      value.contains('#') ||
      segments.any(
        (segment) => segment.isEmpty || segment == '.' || segment == '..',
      );

  if (unsafe || !lower.endsWith('.json')) {
    throw LabScenarioPopulationManifestException(
      label +
          '.' +
          field +
          ' must be a normalized relative JSON path without traversal or URL syntax.',
    );
  }

  return value;
}

class LabScenarioPopulationManifestEntry {
  LabScenarioPopulationManifestEntry.fromJson(Map<String, Object?> json)
    : entryId = LabIds.requireCanonical(
        _requiredManifestText(json, 'entryId', 'manifest entry'),
        'scenario population entry ID',
      ),
      labId = LabIds.requireCanonical(
        _requiredManifestText(json, 'labId', 'manifest entry'),
        'scenario population LAB ID',
      ),
      versionId = LabIds.requireCanonical(
        _requiredManifestText(json, 'versionId', 'manifest entry'),
        'scenario population version ID',
      ),
      technicalLabPath = _requiredRelativeJsonPath(
        json,
        'technicalLabPath',
        'manifest entry',
      ),
      dqg300EvidencePath = _requiredRelativeJsonPath(
        json,
        'dqg300EvidencePath',
        'manifest entry',
      ),
      learnerPresentationPath = _requiredRelativeJsonPath(
        json,
        'learnerPresentationPath',
        'manifest entry',
      ) {
    _requireOnlyManifestKeys(json, const <String>{
      'entryId',
      'labId',
      'versionId',
      'technicalLabPath',
      'dqg300EvidencePath',
      'learnerPresentationPath',
    }, 'manifest entry');

    if (artifactPaths.values.toSet().length != artifactPaths.length) {
      throw LabScenarioPopulationManifestException(
        'Manifest entry ' +
            entryId +
            ' must use three distinct artifact paths.',
      );
    }
  }

  final String entryId;
  final String labId;
  final String versionId;
  final String technicalLabPath;
  final String dqg300EvidencePath;
  final String learnerPresentationPath;

  String get identityKey => labId + '@' + versionId;

  Map<String, String> get artifactPaths => <String, String>{
    'technicalLabPath': technicalLabPath,
    'dqg300EvidencePath': dqg300EvidencePath,
    'learnerPresentationPath': learnerPresentationPath,
  };
}

class LabScenarioPopulationManifest {
  LabScenarioPopulationManifest._({
    required this.schemaVersion,
    required this.manifestId,
    required this.entries,
  });

  factory LabScenarioPopulationManifest.fromJson(Map<String, Object?> json) {
    _requireOnlyManifestKeys(json, const <String>{
      'schemaVersion',
      'manifestId',
      'entries',
    }, 'scenario population manifest');

    if (json['schemaVersion'] != kLabScenarioPopulationManifestSchemaVersion) {
      throw const LabScenarioPopulationManifestException(
        'Unsupported scenario population manifest schema.',
      );
    }

    final rawEntries = json['entries'];
    if (rawEntries is! Iterable) {
      throw const LabScenarioPopulationManifestException(
        'Scenario population manifest entries must be an array.',
      );
    }

    final entries = rawEntries
        .map((item) {
          if (item is! Map) {
            throw const LabScenarioPopulationManifestException(
              'Scenario population manifest entry must be an object.',
            );
          }
          return LabScenarioPopulationManifestEntry.fromJson(
            item.cast<String, Object?>(),
          );
        })
        .toList(growable: false);

    if (entries.isEmpty) {
      throw const LabScenarioPopulationManifestException(
        'Scenario population manifest requires at least one entry.',
      );
    }

    final entryIds = <String>{};
    final identities = <String>{};
    final pathOwners = <String, String>{};

    for (final entry in entries) {
      if (!entryIds.add(entry.entryId)) {
        throw LabScenarioPopulationManifestException(
          'Duplicate scenario population entry ID: ' + entry.entryId,
        );
      }
      if (!identities.add(entry.identityKey)) {
        throw LabScenarioPopulationManifestException(
          'Duplicate LAB/version population binding: ' + entry.identityKey,
        );
      }

      for (final artifact in entry.artifactPaths.entries) {
        final owner = pathOwners[artifact.value];
        if (owner != null) {
          throw LabScenarioPopulationManifestException(
            'Artifact path ' +
                artifact.value +
                ' is shared by ' +
                owner +
                ' and ' +
                entry.entryId +
                ':' +
                artifact.key +
                '.',
          );
        }
        pathOwners[artifact.value] = entry.entryId + ':' + artifact.key;
      }
    }

    return LabScenarioPopulationManifest._(
      schemaVersion: kLabScenarioPopulationManifestSchemaVersion,
      manifestId: LabIds.requireCanonical(
        _requiredManifestText(
          json,
          'manifestId',
          'scenario population manifest',
        ),
        'scenario population manifest ID',
      ),
      entries: List<LabScenarioPopulationManifestEntry>.unmodifiable(entries),
    );
  }

  final String schemaVersion;
  final String manifestId;
  final List<LabScenarioPopulationManifestEntry> entries;

  LabScenarioPopulationManifestEntry? entryFor({
    required String labId,
    required String versionId,
  }) {
    for (final entry in entries) {
      if (entry.labId == labId && entry.versionId == versionId) {
        return entry;
      }
    }
    return null;
  }

  LabScenarioPopulationManifestEntry requireEntry(String entryId) {
    for (final entry in entries) {
      if (entry.entryId == entryId) {
        return entry;
      }
    }
    throw LabScenarioPopulationManifestException(
      'Scenario population entry was not found: ' + entryId,
    );
  }
}

class LabScenarioPopulationBindingReport {
  const LabScenarioPopulationBindingReport({
    required this.technicalIdentityMatches,
    required this.dqgIdentityMatches,
    required this.presentationIdentityMatches,
    required this.missingDqgDecisionIds,
    required this.unexpectedDqgDecisionIds,
    required this.staleDqgDecisionIds,
    required this.presentationReport,
  });

  final bool technicalIdentityMatches;
  final bool dqgIdentityMatches;
  final bool presentationIdentityMatches;
  final Set<String> missingDqgDecisionIds;
  final Set<String> unexpectedDqgDecisionIds;
  final Set<String> staleDqgDecisionIds;
  final LabLearnerPresentationValidationReport presentationReport;

  bool get isValid =>
      technicalIdentityMatches &&
      dqgIdentityMatches &&
      presentationIdentityMatches &&
      missingDqgDecisionIds.isEmpty &&
      unexpectedDqgDecisionIds.isEmpty &&
      staleDqgDecisionIds.isEmpty &&
      presentationReport.isValid;
}

class LabScenarioPopulationBindingValidator {
  const LabScenarioPopulationBindingValidator({
    this.presentationValidator = const LabLearnerPresentationValidator(),
  });

  final LabLearnerPresentationValidator presentationValidator;

  LabScenarioPopulationBindingReport validate({
    required LabScenarioPopulationManifestEntry entry,
    required LabPackage technicalPackage,
    required LabDqg300EvidenceBundle dqg300Evidence,
    required LabLearnerPresentationPackage presentationPackage,
  }) {
    final technicalIdentityMatches =
        technicalPackage.metadata.id == entry.labId &&
        technicalPackage.metadata.versionId == entry.versionId;

    final dqgIdentityMatches =
        dqg300Evidence.labId == entry.labId &&
        dqg300Evidence.versionId == entry.versionId;

    final presentationIdentityMatches =
        presentationPackage.labId == entry.labId &&
        presentationPackage.versionId == entry.versionId;

    final decisionNodes = <String, LabDecisionNode>{
      for (final node in technicalPackage.nodes.whereType<LabDecisionNode>())
        node.id: node,
    };
    final decisionIds = decisionNodes.keys.toSet();
    final evidenceIds = dqg300Evidence.decisions.keys.toSet();

    final stale = <String>{};
    for (final id in decisionIds.intersection(evidenceIds)) {
      final node = decisionNodes[id];
      final evidence = dqg300Evidence.decisions[id];
      if (node == null || evidence == null) {
        continue;
      }
      if (evidence.decisionSignature !=
          LabDqg300Validator.decisionSignature(node)) {
        stale.add(id);
      }
    }

    return LabScenarioPopulationBindingReport(
      technicalIdentityMatches: technicalIdentityMatches,
      dqgIdentityMatches: dqgIdentityMatches,
      presentationIdentityMatches: presentationIdentityMatches,
      missingDqgDecisionIds: Set<String>.unmodifiable(
        decisionIds.difference(evidenceIds),
      ),
      unexpectedDqgDecisionIds: Set<String>.unmodifiable(
        evidenceIds.difference(decisionIds),
      ),
      staleDqgDecisionIds: Set<String>.unmodifiable(stale),
      presentationReport: presentationValidator.validate(
        technicalPackage: technicalPackage,
        presentationPackage: presentationPackage,
      ),
    );
  }
}
