import 'lab_contracts.dart';

const String kLabPresentationSchemaVersion = 'csp11.lab.presentation.v1';

class LabLearnerPresentationContractException implements Exception {
  const LabLearnerPresentationContractException(this.message);

  final String message;

  @override
  String toString() => 'LabLearnerPresentationContractException: $message';
}

void _requireOnlyKeys(
  Map<String, Object?> json,
  Set<String> allowed,
  String label,
) {
  final unexpected = json.keys.where((key) => !allowed.contains(key)).toList()
    ..sort();
  if (unexpected.isNotEmpty) {
    throw LabLearnerPresentationContractException(
      '$label contains forbidden or unknown fields: ${unexpected.join(', ')}',
    );
  }
}

String _requiredText(
  Map<String, Object?> json,
  String field,
  String label,
) {
  final value = json[field]?.toString().trim() ?? '';
  if (value.isEmpty) {
    throw LabLearnerPresentationContractException(
      '$label requires non-empty $field.',
    );
  }
  return value;
}

List<String> _stringList(
  Object? value,
  String label, {
  bool allowEmpty = false,
}) {
  if (value is! Iterable) {
    throw LabLearnerPresentationContractException('$label must be an array.');
  }
  final output = value.map((item) => item.toString().trim()).toList();
  if (output.any((item) => item.isEmpty)) {
    throw LabLearnerPresentationContractException(
      '$label cannot contain empty values.',
    );
  }
  if (!allowEmpty && output.isEmpty) {
    throw LabLearnerPresentationContractException(
      '$label requires at least one value.',
    );
  }
  return List<String>.unmodifiable(output);
}

class LabPresentationOverview {
  LabPresentationOverview.fromJson(Map<String, Object?> json)
      : summary = _requiredText(json, 'summary', 'presentation'),
        estimatedTime = _requiredText(json, 'estimatedTime', 'presentation'),
        decisionCountLabel =
            _requiredText(json, 'decisionCountLabel', 'presentation'),
        role = _requiredText(json, 'role', 'presentation'),
        situation = _requiredText(json, 'situation', 'presentation'),
        objective = _requiredText(json, 'objective', 'presentation'),
        peopleInvolved = _stringList(
          json['peopleInvolved'],
          'presentation.peopleInvolved',
          allowEmpty: true,
        ),
        knownFacts = _stringList(
          json['knownFacts'],
          'presentation.knownFacts',
        ),
        focusTags = _stringList(
          json['focusTags'],
          'presentation.focusTags',
        ) {
    _requireOnlyKeys(json, const <String>{
      'summary',
      'estimatedTime',
      'decisionCountLabel',
      'role',
      'situation',
      'objective',
      'peopleInvolved',
      'knownFacts',
      'focusTags',
    }, 'presentation');
  }

  final String summary;
  final String estimatedTime;
  final String decisionCountLabel;
  final String role;
  final String situation;
  final String objective;
  final List<String> peopleInvolved;
  final List<String> knownFacts;
  final List<String> focusTags;
}

class LabEvidencePresentation {
  LabEvidencePresentation.fromJson(Map<String, Object?> json)
      : title = _requiredText(json, 'title', 'evidence presentation'),
        summary = _requiredText(json, 'summary', 'evidence presentation'),
        details = _requiredText(json, 'details', 'evidence presentation') {
    _requireOnlyKeys(
      json,
      const <String>{'title', 'summary', 'details'},
      'evidence presentation',
    );
  }

  final String title;
  final String summary;
  final String details;
}

class LabDecisionPresentation {
  LabDecisionPresentation.fromJson(Map<String, Object?> json)
      : title = _requiredText(json, 'title', 'decision presentation') {
    _requireOnlyKeys(
      json,
      const <String>{'title'},
      'decision presentation',
    );
  }

  final String title;
}

class LabConsequencePresentation {
  LabConsequencePresentation.fromJson(Map<String, Object?> json)
      : observable = _requiredText(
          json,
          'observable',
          'consequence presentation',
        ),
        guidedInsight = _requiredText(
          json,
          'guidedInsight',
          'consequence presentation',
        ) {
    _requireOnlyKeys(
      json,
      const <String>{'observable', 'guidedInsight'},
      'consequence presentation',
    );
  }

  final String observable;
  final String guidedInsight;
}

class LabEndingPresentation {
  LabEndingPresentation.fromJson(Map<String, Object?> json)
      : title = _requiredText(json, 'title', 'ending presentation'),
        narrative = _requiredText(json, 'narrative', 'ending presentation'),
        keyTurningPoint = _requiredText(
          json,
          'keyTurningPoint',
          'ending presentation',
        ) {
    _requireOnlyKeys(
      json,
      const <String>{'title', 'narrative', 'keyTurningPoint'},
      'ending presentation',
    );
  }

  final String title;
  final String narrative;
  final String keyTurningPoint;
}

class LabLearnerPresentationPackage {
  LabLearnerPresentationPackage._({
    required this.schemaVersion,
    required this.labId,
    required this.versionId,
    required this.presentation,
    required this.evidencePresentation,
    required this.decisionPresentation,
    required this.consequencePresentation,
    required this.endingPresentation,
  });

  factory LabLearnerPresentationPackage.fromJson(Map<String, Object?> json) {
    _requireOnlyKeys(json, const <String>{
      'schemaVersion',
      'labId',
      'versionId',
      'presentation',
      'evidencePresentation',
      'decisionPresentation',
      'consequencePresentation',
      'endingPresentation',
    }, 'learner presentation root');

    if (json['schemaVersion'] != kLabPresentationSchemaVersion) {
      throw LabLearnerPresentationContractException(
        'Unsupported learner presentation schema: ${json['schemaVersion']}',
      );
    }

    final overview = _requiredMap(json['presentation'], 'presentation');

    return LabLearnerPresentationPackage._(
      schemaVersion: kLabPresentationSchemaVersion,
      labId: LabIds.requireCanonical(
        json['labId']?.toString() ?? '',
        'presentation LAB ID',
      ),
      versionId: LabIds.requireCanonical(
        json['versionId']?.toString() ?? '',
        'presentation LAB version ID',
      ),
      presentation: LabPresentationOverview.fromJson(overview),
      evidencePresentation: _mapping(
        json['evidencePresentation'],
        'evidencePresentation',
        LabEvidencePresentation.fromJson,
      ),
      decisionPresentation: _mapping(
        json['decisionPresentation'],
        'decisionPresentation',
        LabDecisionPresentation.fromJson,
      ),
      consequencePresentation: _mapping(
        json['consequencePresentation'],
        'consequencePresentation',
        LabConsequencePresentation.fromJson,
      ),
      endingPresentation: _mapping(
        json['endingPresentation'],
        'endingPresentation',
        LabEndingPresentation.fromJson,
      ),
    );
  }

  static Map<String, Object?> _requiredMap(Object? value, String label) {
    if (value is! Map) {
      throw LabLearnerPresentationContractException('$label must be an object.');
    }
    return value.cast<String, Object?>();
  }

  static Map<String, T> _mapping<T>(
    Object? value,
    String label,
    T Function(Map<String, Object?> json) parse,
  ) {
    final map = _requiredMap(value, label);
    final output = <String, T>{};

    for (final entry in map.entries) {
      final id = LabIds.requireCanonical(entry.key, '$label ID');
      if (output.containsKey(id)) {
        throw LabLearnerPresentationContractException(
          '$label contains duplicate ID $id.',
        );
      }
      output[id] = parse(_requiredMap(entry.value, '$label.$id'));
    }

    return Map<String, T>.unmodifiable(output);
  }

  final String schemaVersion;
  final String labId;
  final String versionId;
  final LabPresentationOverview presentation;
  final Map<String, LabEvidencePresentation> evidencePresentation;
  final Map<String, LabDecisionPresentation> decisionPresentation;
  final Map<String, LabConsequencePresentation> consequencePresentation;
  final Map<String, LabEndingPresentation> endingPresentation;
}

class LabLearnerPresentationValidationReport {
  const LabLearnerPresentationValidationReport({
    required this.identityMatches,
    required this.missingDecisionIds,
    required this.unexpectedDecisionIds,
    required this.missingConsequenceIds,
    required this.unexpectedConsequenceIds,
    required this.missingEvidenceIds,
    required this.unexpectedEvidenceIds,
    required this.missingEndingIds,
    required this.unexpectedEndingIds,
    required this.technicalMappingIssues,
  });

  final bool identityMatches;
  final Set<String> missingDecisionIds;
  final Set<String> unexpectedDecisionIds;
  final Set<String> missingConsequenceIds;
  final Set<String> unexpectedConsequenceIds;
  final Set<String> missingEvidenceIds;
  final Set<String> unexpectedEvidenceIds;
  final Set<String> missingEndingIds;
  final Set<String> unexpectedEndingIds;
  final List<String> technicalMappingIssues;

  bool get isValid =>
      identityMatches &&
      missingDecisionIds.isEmpty &&
      unexpectedDecisionIds.isEmpty &&
      missingConsequenceIds.isEmpty &&
      unexpectedConsequenceIds.isEmpty &&
      missingEvidenceIds.isEmpty &&
      unexpectedEvidenceIds.isEmpty &&
      missingEndingIds.isEmpty &&
      unexpectedEndingIds.isEmpty &&
      technicalMappingIssues.isEmpty;
}

class LabLearnerPresentationValidator {
  const LabLearnerPresentationValidator();

  LabLearnerPresentationValidationReport validate({
    required LabPackage technicalPackage,
    required LabLearnerPresentationPackage presentationPackage,
  }) {
    final issues = <String>[];

    final decisionIds = technicalPackage.nodes
        .whereType<LabDecisionNode>()
        .map((node) => node.id)
        .toSet();

    final consequenceIds = <String>{
      for (final consequence in technicalPackage.consequences) consequence.id,
    };
    for (final decision in technicalPackage.nodes.whereType<LabDecisionNode>()) {
      for (final option in decision.options) {
        final consequenceId = option.consequenceId ?? option.consequence?.id;
        if (consequenceId == null || consequenceId.trim().isEmpty) {
          issues.add(
            'Decision ${decision.id} option ${option.id} has no consequence ID.',
          );
        } else {
          consequenceIds.add(consequenceId);
        }
      }
    }

    final evidenceIds = _technicalIds(
      technicalPackage.evidence,
      'evidence',
      issues,
    );
    final endingIds = _technicalIds(
      technicalPackage.endings,
      'ending',
      issues,
    );

    return LabLearnerPresentationValidationReport(
      identityMatches:
          presentationPackage.labId == technicalPackage.metadata.id &&
          presentationPackage.versionId == technicalPackage.metadata.versionId,
      missingDecisionIds: Set<String>.unmodifiable(
        decisionIds.difference(presentationPackage.decisionPresentation.keys.toSet()),
      ),
      unexpectedDecisionIds: Set<String>.unmodifiable(
        presentationPackage.decisionPresentation.keys.toSet().difference(decisionIds),
      ),
      missingConsequenceIds: Set<String>.unmodifiable(
        consequenceIds.difference(
          presentationPackage.consequencePresentation.keys.toSet(),
        ),
      ),
      unexpectedConsequenceIds: Set<String>.unmodifiable(
        presentationPackage.consequencePresentation.keys
            .toSet()
            .difference(consequenceIds),
      ),
      missingEvidenceIds: Set<String>.unmodifiable(
        evidenceIds.difference(presentationPackage.evidencePresentation.keys.toSet()),
      ),
      unexpectedEvidenceIds: Set<String>.unmodifiable(
        presentationPackage.evidencePresentation.keys.toSet().difference(evidenceIds),
      ),
      missingEndingIds: Set<String>.unmodifiable(
        endingIds.difference(presentationPackage.endingPresentation.keys.toSet()),
      ),
      unexpectedEndingIds: Set<String>.unmodifiable(
        presentationPackage.endingPresentation.keys.toSet().difference(endingIds),
      ),
      technicalMappingIssues: List<String>.unmodifiable(issues),
    );
  }

  Set<String> _technicalIds(
    Iterable<Map<String, Object?>> records,
    String label,
    List<String> issues,
  ) {
    final ids = <String>{};
    for (final record in records) {
      final rawId = record['id']?.toString().trim() ?? '';
      if (rawId.isEmpty) {
        issues.add('Technical $label record is missing an ID.');
        continue;
      }
      if (!LabIds.isCanonical(rawId)) {
        issues.add('Technical $label ID is not canonical: $rawId');
        continue;
      }
      if (!ids.add(rawId)) {
        issues.add('Technical $label ID is duplicated: $rawId');
      }
    }
    return ids;
  }
}
