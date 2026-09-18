import 'dart:convert';

const String kLabSchemaVersion = 'csp11.lab.v1';

class LabContractException implements Exception {
  const LabContractException(this.message);

  final String message;

  @override
  String toString() => 'LabContractException: $message';
}

class LabIds {
  LabIds._();

  static final RegExp _canonical = RegExp(
    r'^[a-z][a-z0-9]*(?:[._-][a-z0-9]+)*$',
  );

  static bool isCanonical(String value) => _canonical.hasMatch(value);

  static String requireCanonical(String value, String fieldName) {
    final trimmed = value.trim();
    if (!_canonical.hasMatch(trimmed)) {
      throw LabContractException(
        '$fieldName must be a lowercase canonical LAB identifier.',
      );
    }
    return trimmed;
  }
}

enum LabLifecycleStatus { draft, review, validated, published }

enum LabMode { guided, professional, assessment }

enum LabNodeType { scene, decision }

enum LabDecisionQuality { optimal, defensible, weak, critical }

enum LabStateKind {
  boolean,
  boundedNumeric,
  enumeration,
  stringId,
  stringSet,
  stringList,
}

enum LabMutationKind { set, increment, add, remove, noOp }

enum LabGateType {
  decision,
  consequence,
  route,
  criticalEvent,
  convergence,
  completion,
}

enum LabEndingFamily {
  safeCompletion,
  controlledRecovery,
  incidentContained,
  majorIncident,
  criticalFailure,
}

String _wireToken(String value) => value.trim().toUpperCase();

LabLifecycleStatus parseLabLifecycle(Object? value) {
  switch (_wireToken(value?.toString() ?? '')) {
    case 'DRAFT':
      return LabLifecycleStatus.draft;
    case 'REVIEW':
      return LabLifecycleStatus.review;
    case 'VALIDATED':
      return LabLifecycleStatus.validated;
    case 'PUBLISHED':
      return LabLifecycleStatus.published;
  }
  throw LabContractException('Unknown LAB lifecycle status: $value');
}

LabMode parseLabMode(Object? value) {
  switch (_wireToken(value?.toString() ?? '')) {
    case 'GUIDED':
      return LabMode.guided;
    case 'PROFESSIONAL':
      return LabMode.professional;
    case 'ASSESSMENT':
      return LabMode.assessment;
  }
  throw LabContractException('Unknown LAB mode: $value');
}

LabDecisionQuality parseDecisionQuality(Object? value) {
  switch (_wireToken(value?.toString() ?? '')) {
    case 'OPTIMAL':
      return LabDecisionQuality.optimal;
    case 'DEFENSIBLE':
      return LabDecisionQuality.defensible;
    case 'WEAK':
      return LabDecisionQuality.weak;
    case 'CRITICAL':
      return LabDecisionQuality.critical;
  }
  throw LabContractException('Unknown decision quality: $value');
}

LabStateKind parseStateKind(Object? value) {
  switch (_wireToken(value?.toString() ?? '')) {
    case 'BOOLEAN':
      return LabStateKind.boolean;
    case 'BOUNDED_NUMERIC':
    case 'BOUNDEDNUMBER':
    case 'NUMBER':
      return LabStateKind.boundedNumeric;
    case 'ENUM':
    case 'ENUMERATION':
      return LabStateKind.enumeration;
    case 'STRING_ID':
      return LabStateKind.stringId;
    case 'STRING_SET':
      return LabStateKind.stringSet;
    case 'STRING_LIST':
      return LabStateKind.stringList;
  }
  throw LabContractException('Unknown state kind: $value');
}

LabMutationKind parseMutationKind(Object? value) {
  switch (_wireToken(value?.toString() ?? '')) {
    case 'SET':
      return LabMutationKind.set;
    case 'INCREMENT':
      return LabMutationKind.increment;
    case 'ADD':
      return LabMutationKind.add;
    case 'REMOVE':
      return LabMutationKind.remove;
    case 'NO_OP':
    case 'NOOP':
      return LabMutationKind.noOp;
  }
  throw LabContractException('Unknown state mutation kind: $value');
}

LabGateType parseGateType(Object? value) {
  switch (_wireToken(value?.toString() ?? '')) {
    case 'DECISION':
      return LabGateType.decision;
    case 'CONSEQUENCE':
      return LabGateType.consequence;
    case 'ROUTE':
      return LabGateType.route;
    case 'CRITICAL_EVENT':
      return LabGateType.criticalEvent;
    case 'CONVERGENCE':
      return LabGateType.convergence;
    case 'COMPLETION':
      return LabGateType.completion;
  }
  throw LabContractException('Unknown LAB gate type: $value');
}

LabEndingFamily parseEndingFamily(Object? value) {
  switch (_wireToken(value?.toString() ?? '')) {
    case 'SAFE_COMPLETION':
      return LabEndingFamily.safeCompletion;
    case 'CONTROLLED_RECOVERY':
      return LabEndingFamily.controlledRecovery;
    case 'INCIDENT_CONTAINED':
      return LabEndingFamily.incidentContained;
    case 'MAJOR_INCIDENT':
      return LabEndingFamily.majorIncident;
    case 'CRITICAL_FAILURE':
      return LabEndingFamily.criticalFailure;
  }
  throw LabContractException('Unknown LAB ending family: $value');
}

class LabLifecyclePolicy {
  LabLifecyclePolicy._();

  static bool canTransition(LabLifecycleStatus from, LabLifecycleStatus to) {
    if (from == to) return true;
    if (from == LabLifecycleStatus.published) return false;

    return switch (from) {
      LabLifecycleStatus.draft => to == LabLifecycleStatus.review,
      LabLifecycleStatus.review => to == LabLifecycleStatus.validated,
      LabLifecycleStatus.validated => to == LabLifecycleStatus.published,
      LabLifecycleStatus.published => false,
    };
  }

  static void requireTransition(
    LabLifecycleStatus from,
    LabLifecycleStatus to,
  ) {
    if (!canTransition(from, to)) {
      throw LabContractException(
        'Invalid LAB lifecycle transition: $from -> $to',
      );
    }
  }

  static void requireRuntimeMutable(LabLifecycleStatus lifecycle) {
    if (lifecycle == LabLifecycleStatus.published) {
      throw const LabContractException('Published LAB versions are immutable.');
    }
  }
}

class LabStateVariableDefinition {
  LabStateVariableDefinition._({
    required this.id,
    required this.kind,
    required this.irreversible,
    this.min,
    this.max,
    this.allowedValues = const <String>{},
  });

  factory LabStateVariableDefinition({
    required String id,
    required LabStateKind kind,
    bool irreversible = false,
    num? min,
    num? max,
    Iterable<String> allowedValues = const <String>[],
  }) {
    final canonicalId = LabIds.requireCanonical(id, 'state variable ID');
    final allowed = Set<String>.unmodifiable(
      allowedValues
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty),
    );

    if (kind == LabStateKind.boundedNumeric) {
      if (min == null || max == null || min > max) {
        throw const LabContractException(
          'Bounded numeric state requires min <= max.',
        );
      }
    }

    if (kind == LabStateKind.enumeration && allowed.isEmpty) {
      throw const LabContractException(
        'Enum state requires at least one allowed value.',
      );
    }

    return LabStateVariableDefinition._(
      id: canonicalId,
      kind: kind,
      irreversible: irreversible,
      min: min,
      max: max,
      allowedValues: allowed,
    );
  }

  factory LabStateVariableDefinition.fromJson(
    String id,
    Map<String, Object?> json,
  ) {
    final allowed = json['allowedValues'] ?? json['allowed'];
    return LabStateVariableDefinition(
      id: id,
      kind: parseStateKind(json['type']),
      irreversible: json['irreversible'] == true,
      min: json['min'] as num?,
      max: json['max'] as num?,
      allowedValues: allowed is Iterable
          ? allowed.map((value) => value.toString())
          : const <String>[],
    );
  }

  final String id;
  final LabStateKind kind;
  final bool irreversible;
  final num? min;
  final num? max;
  final Set<String> allowedValues;

  Object? normalize(Object? value) {
    switch (kind) {
      case LabStateKind.boolean:
        if (value is! bool) {
          throw LabContractException('$id requires a Boolean value.');
        }
        return value;
      case LabStateKind.boundedNumeric:
        if (value is! num) {
          throw LabContractException('$id requires a numeric value.');
        }
        if (value < min! || value > max!) {
          throw LabContractException(
            '$id must stay inside the declared numeric bounds.',
          );
        }
        return value;
      case LabStateKind.enumeration:
        if (value is! String || !allowedValues.contains(value)) {
          throw LabContractException(
            '$id requires one of the declared enum values.',
          );
        }
        return value;
      case LabStateKind.stringId:
        if (value is! String || value.trim().isEmpty) {
          throw LabContractException('$id requires a non-empty string ID.');
        }
        return value.trim();
      case LabStateKind.stringSet:
        if (value is! Iterable) {
          throw LabContractException('$id requires a string set/list.');
        }
        final values =
            value
                .map((item) {
                  if (item is! String || item.trim().isEmpty) {
                    throw LabContractException('$id requires string members.');
                  }
                  return item.trim();
                })
                .toSet()
                .toList()
              ..sort();
        return List<String>.unmodifiable(values);
      case LabStateKind.stringList:
        if (value is! Iterable) {
          throw LabContractException('$id requires a string list.');
        }
        final values = value
            .map((item) {
              if (item is! String || item.trim().isEmpty) {
                throw LabContractException('$id requires string members.');
              }
              return item.trim();
            })
            .toList(growable: false);
        return List<String>.unmodifiable(values);
    }
  }
}

class LabStateRegistry {
  LabStateRegistry(Iterable<LabStateVariableDefinition> definitions)
    : definitions = Map<String, LabStateVariableDefinition>.unmodifiable(
        <String, LabStateVariableDefinition>{
          for (final definition in definitions) definition.id: definition,
        },
      ) {
    if (this.definitions.length != definitions.length) {
      throw const LabContractException(
        'LAB state variable IDs must be unique.',
      );
    }
  }

  factory LabStateRegistry.fromJson(Map<String, Object?> json) {
    return LabStateRegistry(
      json.entries.map((entry) {
        final value = entry.value;
        if (value is! Map) {
          throw LabContractException(
            'State schema entry ' + entry.key + ' must be an object.',
          );
        }
        return LabStateVariableDefinition.fromJson(
          entry.key,
          value.cast<String, Object?>(),
        );
      }),
    );
  }

  final Map<String, LabStateVariableDefinition> definitions;

  LabStateVariableDefinition require(String id) {
    final definition = definitions[id];
    if (definition == null) {
      throw LabContractException('Unknown LAB state variable: $id');
    }
    return definition;
  }

  Map<String, Object?> normalizeStartingState(Map<String, Object?> input) {
    final normalized = <String, Object?>{};

    for (final entry in input.entries) {
      normalized[entry.key] = require(entry.key).normalize(entry.value);
    }

    for (final id in definitions.keys) {
      if (!normalized.containsKey(id)) {
        throw LabContractException(
          'Starting LAB state is missing declared variable: $id',
        );
      }
    }

    return Map<String, Object?>.unmodifiable(normalized);
  }
}

class LabStateMutation {
  const LabStateMutation({required this.kind, this.stateId, this.value});

  factory LabStateMutation.fromJson(Map<String, Object?> json) {
    final kind = parseMutationKind(json['op'] ?? json['kind']);
    if (kind == LabMutationKind.noOp) {
      return const LabStateMutation(kind: LabMutationKind.noOp);
    }
    final stateId = json['stateId']?.toString() ?? '';
    return LabStateMutation(
      kind: kind,
      stateId: LabIds.requireCanonical(stateId, 'mutation state ID'),
      value: json['value'],
    );
  }

  final LabMutationKind kind;
  final String? stateId;
  final Object? value;
}

class LabConsequence {
  LabConsequence({
    required String id,
    Iterable<LabStateMutation> mutations = const <LabStateMutation>[],
    Iterable<String> evidenceUnlocks = const <String>[],
    this.simulatedMinutes = 0,
    this.explicitNoOp = false,
  }) : id = LabIds.requireCanonical(id, 'consequence ID'),
       mutations = List<LabStateMutation>.unmodifiable(mutations),
       evidenceUnlocks = Set<String>.unmodifiable(
         evidenceUnlocks.map(
           (value) => LabIds.requireCanonical(value, 'evidence ID'),
         ),
       ) {
    if (simulatedMinutes < 0) {
      throw const LabContractException('Simulated time cannot move backwards.');
    }
    if (this.mutations.isEmpty && !explicitNoOp) {
      throw const LabContractException(
        'A consequence requires state mutations or explicitNoOp=true.',
      );
    }
  }

  factory LabConsequence.fromJson(Map<String, Object?> json) {
    final rawMutations = json['mutations'];
    final mutations = rawMutations is Iterable
        ? rawMutations
              .map((item) {
                if (item is! Map) {
                  throw const LabContractException(
                    'Consequence mutation must be an object.',
                  );
                }
                return LabStateMutation.fromJson(item.cast<String, Object?>());
              })
              .toList(growable: false)
        : const <LabStateMutation>[];

    final evidence = json['evidenceUnlocks'];
    return LabConsequence(
      id: json['id']?.toString() ?? '',
      mutations: mutations,
      evidenceUnlocks: evidence is Iterable
          ? evidence.map((item) => item.toString())
          : const <String>[],
      simulatedMinutes: (json['simulatedMinutes'] as num?)?.toInt() ?? 0,
      explicitNoOp: json['explicitNoOp'] == true,
    );
  }

  final String id;
  final List<LabStateMutation> mutations;
  final Set<String> evidenceUnlocks;
  final int simulatedMinutes;
  final bool explicitNoOp;
}

class LabDecisionOption {
  LabDecisionOption({
    required String id,
    required String text,
    required this.isBest,
    required this.quality,
    this.consequenceId,
    this.consequence,
    Iterable<String> mistakeTags = const <String>[],
    Iterable<String> competencyEvidence = const <String>[],
  }) : id = LabIds.requireCanonical(id, 'option ID'),
       text = text.trim(),
       mistakeTags = Set<String>.unmodifiable(mistakeTags),
       competencyEvidence = Set<String>.unmodifiable(competencyEvidence) {
    if (this.text.isEmpty) {
      throw const LabContractException('Decision option text is required.');
    }
    if ((consequenceId == null) == (consequence == null)) {
      throw const LabContractException(
        'Decision option requires exactly one consequence reference or payload.',
      );
    }
    if (consequenceId != null) {
      LabIds.requireCanonical(consequenceId!, 'consequence ID');
    }
  }

  factory LabDecisionOption.fromJson(Map<String, Object?> json) {
    final consequencePayload = json['consequence'];
    final mistakeTags = json['mistakeTags'];
    final evidence = json['competencyEvidence'];

    return LabDecisionOption(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      isBest: json['isBest'] == true,
      quality: parseDecisionQuality(json['quality']),
      consequenceId: consequencePayload == null
          ? json['consequenceId']?.toString()
          : null,
      consequence: consequencePayload is Map
          ? LabConsequence.fromJson(consequencePayload.cast<String, Object?>())
          : null,
      mistakeTags: mistakeTags is Iterable
          ? mistakeTags.map((item) => item.toString())
          : const <String>[],
      competencyEvidence: evidence is Iterable
          ? evidence.map((item) => item.toString())
          : const <String>[],
    );
  }

  final String id;
  final String text;
  final bool isBest;
  final LabDecisionQuality quality;
  final String? consequenceId;
  final LabConsequence? consequence;
  final Set<String> mistakeTags;
  final Set<String> competencyEvidence;
}

abstract class LabNodeContract {
  String get id;
  LabNodeType get type;
}

class LabSceneNode implements LabNodeContract {
  LabSceneNode({required String id, required String text})
    : id = LabIds.requireCanonical(id, 'scene node ID'),
      text = text.trim() {
    if (this.text.isEmpty) {
      throw const LabContractException('Scene text is required.');
    }
  }

  @override
  final String id;

  final String text;

  @override
  LabNodeType get type => LabNodeType.scene;
}

class LabDecisionNode implements LabNodeContract {
  LabDecisionNode({
    required String id,
    required String prompt,
    required Iterable<LabDecisionOption> options,
  }) : id = LabIds.requireCanonical(id, 'decision node ID'),
       prompt = prompt.trim(),
       options = List<LabDecisionOption>.unmodifiable(options) {
    validate();
  }

  factory LabDecisionNode.fromJson(Map<String, Object?> json) {
    final rawOptions = json['options'];
    if (rawOptions is! Iterable) {
      throw const LabContractException(
        'Decision node options must be an array.',
      );
    }

    return LabDecisionNode(
      id: json['id']?.toString() ?? '',
      prompt: json['prompt']?.toString() ?? '',
      options: rawOptions.map((item) {
        if (item is! Map) {
          throw const LabContractException(
            'Decision option must be an object.',
          );
        }
        return LabDecisionOption.fromJson(item.cast<String, Object?>());
      }),
    );
  }

  @override
  final String id;

  final String prompt;
  final List<LabDecisionOption> options;

  @override
  LabNodeType get type => LabNodeType.decision;

  void validate() {
    if (prompt.isEmpty) {
      throw const LabContractException('Decision prompt is required.');
    }
    if (options.length != 4) {
      throw const LabContractException(
        'Every standard Decision Node requires exactly four options.',
      );
    }
    if (options.where((option) => option.isBest).length != 1) {
      throw const LabContractException(
        'Every Decision Node requires exactly one BEST option.',
      );
    }
    if (options.map((option) => option.id).toSet().length != options.length) {
      throw const LabContractException(
        'Decision option IDs must be unique within a node.',
      );
    }
  }

  LabDecisionOption requireOption(String optionId) {
    for (final option in options) {
      if (option.id == optionId) return option;
    }
    throw LabContractException(
      'Decision node $id does not contain option $optionId.',
    );
  }
}

class LabMetadata {
  LabMetadata({
    required String id,
    required String versionId,
    required String title,
    required String description,
    required this.lifecycle,
    required Iterable<LabMode> supportedModes,
    required String startingNodeId,
    required Map<String, Object?> startingState,
    Iterable<String> competencyMappings = const <String>[],
    Iterable<String> sources = const <String>[],
  }) : id = LabIds.requireCanonical(id, 'LAB ID'),
       versionId = LabIds.requireCanonical(versionId, 'LAB version ID'),
       title = title.trim(),
       description = description.trim(),
       supportedModes = Set<LabMode>.unmodifiable(supportedModes),
       startingNodeId = LabIds.requireCanonical(
         startingNodeId,
         'starting node ID',
       ),
       startingState = Map<String, Object?>.unmodifiable(startingState),
       competencyMappings = List<String>.unmodifiable(competencyMappings),
       sources = List<String>.unmodifiable(sources) {
    if (this.title.isEmpty || this.description.isEmpty) {
      throw const LabContractException(
        'LAB title and description are required.',
      );
    }
    if (this.supportedModes.isEmpty) {
      throw const LabContractException(
        'LAB must support at least one runtime mode.',
      );
    }
  }

  factory LabMetadata.fromJson(Map<String, Object?> json) {
    final rawModes = json['supportedModes'];
    final startState = json['startingState'];
    final mappings = json['competencyMappings'];
    final sources = json['sources'];

    if (rawModes is! Iterable || startState is! Map) {
      throw const LabContractException(
        'LAB metadata requires supportedModes and startingState.',
      );
    }

    return LabMetadata(
      id: json['id']?.toString() ?? '',
      versionId: json['versionId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      lifecycle: parseLabLifecycle(json['lifecycle']),
      supportedModes: rawModes.map(parseLabMode),
      startingNodeId: json['startingNodeId']?.toString() ?? '',
      startingState: startState.cast<String, Object?>(),
      competencyMappings: mappings is Iterable
          ? mappings.map((item) => item.toString())
          : const <String>[],
      sources: sources is Iterable
          ? sources.map((item) => item.toString())
          : const <String>[],
    );
  }

  final String id;
  final String versionId;
  final String title;
  final String description;
  final LabLifecycleStatus lifecycle;
  final Set<LabMode> supportedModes;
  final String startingNodeId;
  final Map<String, Object?> startingState;
  final List<String> competencyMappings;
  final List<String> sources;

  LabMetadata withLifecycle(LabLifecycleStatus next) {
    LabLifecyclePolicy.requireTransition(lifecycle, next);
    return LabMetadata(
      id: id,
      versionId: versionId,
      title: title,
      description: description,
      lifecycle: next,
      supportedModes: supportedModes,
      startingNodeId: startingNodeId,
      startingState: startingState,
      competencyMappings: competencyMappings,
      sources: sources,
    );
  }
}

class LabPackage {
  LabPackage({
    required this.schemaVersion,
    required this.metadata,
    required this.stateRegistry,
    required Iterable<LabNodeContract> nodes,
    Iterable<LabConsequence> consequences = const <LabConsequence>[],
    Iterable<Map<String, Object?>> gates = const <Map<String, Object?>>[],
    Iterable<Map<String, Object?>> endings = const <Map<String, Object?>>[],
    Iterable<Map<String, Object?>> characters = const <Map<String, Object?>>[],
    Iterable<Map<String, Object?>> evidence = const <Map<String, Object?>>[],
    Map<String, Object?> debrief = const <String, Object?>{},
    Map<String, Object?> learningSignals = const <String, Object?>{},
  }) : nodes = List<LabNodeContract>.unmodifiable(nodes),
       consequences = List<LabConsequence>.unmodifiable(consequences),
       gates = List<Map<String, Object?>>.unmodifiable(
         gates.map(Map<String, Object?>.unmodifiable),
       ),
       endings = List<Map<String, Object?>>.unmodifiable(
         endings.map(Map<String, Object?>.unmodifiable),
       ),
       characters = List<Map<String, Object?>>.unmodifiable(
         characters.map(Map<String, Object?>.unmodifiable),
       ),
       evidence = List<Map<String, Object?>>.unmodifiable(
         evidence.map(Map<String, Object?>.unmodifiable),
       ),
       debrief = Map<String, Object?>.unmodifiable(debrief),
       learningSignals = Map<String, Object?>.unmodifiable(learningSignals) {
    if (schemaVersion != kLabSchemaVersion) {
      throw LabContractException(
        'Unsupported LAB schema version: $schemaVersion',
      );
    }
    if (this.nodes.isEmpty) {
      throw const LabContractException('LAB package requires story nodes.');
    }
    final ids = this.nodes.map((node) => node.id).toSet();
    if (ids.length != this.nodes.length) {
      throw const LabContractException('LAB node IDs must be unique.');
    }
    if (!ids.contains(metadata.startingNodeId)) {
      throw const LabContractException(
        'LAB starting node must exist in the package.',
      );
    }
    stateRegistry.normalizeStartingState(metadata.startingState);
  }

  factory LabPackage.fromJson(Map<String, Object?> json) {
    _rejectExecutablePayload(json);

    if (json['schemaVersion'] != kLabSchemaVersion) {
      throw LabContractException(
        'Unsupported LAB schema version: ' + json['schemaVersion'].toString(),
      );
    }

    final metadataRaw = json['lab'];
    final stateSchemaRaw = json['stateSchema'];
    final nodesRaw = json['nodes'];
    final gatesRaw = json['gates'];
    final endingsRaw = json['endings'];

    if (metadataRaw is! Map ||
        stateSchemaRaw is! Map ||
        nodesRaw is! Iterable ||
        gatesRaw is! Iterable ||
        endingsRaw is! Iterable) {
      throw const LabContractException(
        'LAB JSON is missing required top-level contract fields.',
      );
    }

    Map<String, Object?> mapObject(Object? value, String label) {
      if (value is! Map) {
        throw LabContractException('$label entry must be an object.');
      }
      return value.cast<String, Object?>();
    }

    final nodes = nodesRaw
        .map((item) {
          final node = mapObject(item, 'node');
          switch (_wireToken(node['type']?.toString() ?? '')) {
            case 'SCENE':
              return LabSceneNode(
                id: node['id']?.toString() ?? '',
                text: node['text']?.toString() ?? '',
              );
            case 'DECISION':
              return LabDecisionNode.fromJson(node);
          }
          throw LabContractException(
            'Unknown LAB node type: ' + node['type'].toString(),
          );
        })
        .toList(growable: false);

    List<Map<String, Object?>> mapList(Object? value, String label) {
      if (value == null) return const <Map<String, Object?>>[];
      if (value is! Iterable) {
        throw LabContractException('$label must be an array.');
      }
      return value
          .map((item) => mapObject(item, label))
          .toList(growable: false);
    }

    final metadata = LabMetadata.fromJson(metadataRaw.cast<String, Object?>());

    final topMappings = json['competencyMappings'];
    final topSources = json['sources'];

    final mergedMetadata = LabMetadata(
      id: metadata.id,
      versionId: metadata.versionId,
      title: metadata.title,
      description: metadata.description,
      lifecycle: metadata.lifecycle,
      supportedModes: metadata.supportedModes,
      startingNodeId: metadata.startingNodeId,
      startingState: metadata.startingState,
      competencyMappings: topMappings is Iterable
          ? topMappings.map((item) => item.toString())
          : metadata.competencyMappings,
      sources: topSources is Iterable
          ? topSources.map((item) => item.toString())
          : metadata.sources,
    );

    final consequenceMaps = mapList(json['consequences'], 'consequence');

    return LabPackage(
      schemaVersion: kLabSchemaVersion,
      metadata: mergedMetadata,
      stateRegistry: LabStateRegistry.fromJson(
        stateSchemaRaw.cast<String, Object?>(),
      ),
      nodes: nodes,
      consequences: consequenceMaps.map(LabConsequence.fromJson),
      gates: mapList(gatesRaw, 'gate'),
      endings: mapList(endingsRaw, 'ending'),
      characters: mapList(json['characters'], 'character'),
      evidence: mapList(json['evidence'], 'evidence'),
      debrief: json['debrief'] is Map
          ? (json['debrief'] as Map).cast<String, Object?>()
          : const <String, Object?>{},
      learningSignals: json['learningSignals'] is Map
          ? (json['learningSignals'] as Map).cast<String, Object?>()
          : const <String, Object?>{},
    );
  }

  factory LabPackage.decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const LabContractException('LAB JSON root must be an object.');
    }
    return LabPackage.fromJson(decoded.cast<String, Object?>());
  }

  final String schemaVersion;
  final LabMetadata metadata;
  final LabStateRegistry stateRegistry;
  final List<LabNodeContract> nodes;
  final List<LabConsequence> consequences;
  final List<Map<String, Object?>> gates;
  final List<Map<String, Object?>> endings;
  final List<Map<String, Object?>> characters;
  final List<Map<String, Object?>> evidence;
  final Map<String, Object?> debrief;
  final Map<String, Object?> learningSignals;

  LabPackage withLifecycle(LabLifecycleStatus next) {
    return LabPackage(
      schemaVersion: schemaVersion,
      metadata: metadata.withLifecycle(next),
      stateRegistry: stateRegistry,
      nodes: nodes,
      consequences: consequences,
      gates: gates,
      endings: endings,
      characters: characters,
      evidence: evidence,
      debrief: debrief,
      learningSignals: learningSignals,
    );
  }

  LabPackage replaceNodes(Iterable<LabNodeContract> replacement) {
    LabLifecyclePolicy.requireRuntimeMutable(metadata.lifecycle);
    return LabPackage(
      schemaVersion: schemaVersion,
      metadata: metadata,
      stateRegistry: stateRegistry,
      nodes: replacement,
      consequences: consequences,
      gates: gates,
      endings: endings,
      characters: characters,
      evidence: evidence,
      debrief: debrief,
      learningSignals: learningSignals,
    );
  }

  static void _rejectExecutablePayload(Object? value, [String path = r'$']) {
    const forbiddenKeys = <String>{
      'script',
      'javascript',
      'dartcode',
      'shell',
      'executable',
      'eval',
      'expression',
      'remotecode',
    };

    if (value is Map) {
      for (final entry in value.entries) {
        final key = entry.key.toString();
        final normalized = key.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
        if (forbiddenKeys.contains(normalized)) {
          throw LabContractException(
            'Executable LAB JSON field is forbidden at $path.$key.',
          );
        }
        _rejectExecutablePayload(entry.value, '$path.$key');
      }
    } else if (value is Iterable) {
      var index = 0;
      for (final item in value) {
        _rejectExecutablePayload(item, '$path[$index]');
        index++;
      }
    }
  }
}
