import '../../data/csp11_blueprint.dart';
import 'canonical_curriculum_policy_validator.dart';

class CanonicalCurriculumRegistryIssue {
  const CanonicalCurriculumRegistryIssue({
    required this.code,
    required this.path,
    required this.message,
  });

  final String code;
  final String path;
  final String message;

  @override
  String toString() => '$code at $path: $message';
}

class CanonicalCurriculumRegistryValidationResult {
  const CanonicalCurriculumRegistryValidationResult(this.issues);

  final List<CanonicalCurriculumRegistryIssue> issues;

  bool get isValid => issues.isEmpty;
}

class CanonicalCurriculumRegistryValidator {
  static const String requiredRegistryVersion = '1.0.0';

  const CanonicalCurriculumRegistryValidator();

  CanonicalCurriculumRegistryValidationResult validateMap(
    Map<String, dynamic> registry,
  ) {
    final issues = <CanonicalCurriculumRegistryIssue>[];

    _exactKeys(
      registry,
      const {
        'schemaVersion',
        'registryVersion',
        'status',
        'frozenAt',
        'blueprintVersion',
        'blueprintSourcePath',
        'policy',
        'topics',
        'populationStatus',
        'topicCount',
        'subtopicCount',
      },
      r'$registry',
      issues,
    );

    if (registry['schemaVersion'] != 1) {
      _add(
        issues,
        'ML6_REGISTRY_SCHEMA_VERSION',
        r'$registry.schemaVersion',
        'Curriculum registry schemaVersion must be 1.',
      );
    }

    if (registry['registryVersion'] != requiredRegistryVersion) {
      _add(
        issues,
        'ML6_REGISTRY_VERSION',
        r'$registry.registryVersion',
        'Curriculum registry version must be $requiredRegistryVersion.',
      );
    }

    if (registry['status'] != 'frozen') {
      _add(
        issues,
        'ML6_REGISTRY_STATUS',
        r'$registry.status',
        'Curriculum registry must remain frozen.',
      );
    }

    if (!_isStrictDate(registry['frozenAt'])) {
      _add(
        issues,
        'ML6_REGISTRY_FROZEN_DATE',
        r'$registry.frozenAt',
        'frozenAt must be a valid YYYY-MM-DD date.',
      );
    }

    if (registry['blueprintVersion'] !=
            CanonicalCurriculumPolicyValidator.requiredBlueprintVersion ||
        registry['blueprintSourcePath'] !=
            'docs/source_pipeline/CSP11_canonical_blueprint.json') {
      _add(
        issues,
        'ML6_REGISTRY_BLUEPRINT_IDENTITY',
        r'$registry',
        'Navigation registry must bind to the frozen canonical blueprint.',
      );
    }

    _validatePolicy(registry['policy'], issues);

    final topics = registry['topics'];
    if (topics is! List) {
      _add(
        issues,
        'ML6_REGISTRY_TOPICS',
        r'$registry.topics',
        'topics must be an array.',
      );
      return CanonicalCurriculumRegistryValidationResult(
        List.unmodifiable(issues),
      );
    }

    final topicIds = <String>{};
    final subtopicIds = <String>{};
    var subtopicCount = 0;

    for (var i = 0; i < topics.length; i++) {
      final rawTopic = topics[i];
      final path = r'$registry.topics[' + i.toString() + ']';
      if (rawTopic is! Map) {
        _add(
          issues,
          'ML6_REGISTRY_TOPIC_OBJECT',
          path,
          'Each topic must be an object.',
        );
        continue;
      }

      final topic = Map<String, dynamic>.from(rawTopic);
      _exactKeys(
        topic,
        const {
          'id',
          'domainId',
          'competencyId',
          'title',
          'status',
          'subtopics',
        },
        path,
        issues,
      );

      final topicId = topic['id'];
      final domainId = topic['domainId'];
      final competencyId = topic['competencyId'];
      final status = topic['status'];

      if (topicId is! String ||
          !RegExp(r'^d0[1-7]_c[0-9]{2}_t[0-9]{2}$').hasMatch(topicId)) {
        _add(
          issues,
          'ML6_REGISTRY_TOPIC_ID',
          '$path.id',
          'Topic ID must use canonical dXX_cYY_tZZ format.',
        );
      } else if (!topicIds.add(topicId)) {
        _add(
          issues,
          'ML6_REGISTRY_DUPLICATE_TOPIC',
          '$path.id',
          'Topic IDs must be globally unique.',
        );
      }

      if (domainId is! String || domainForId(domainId) == null) {
        _add(
          issues,
          'ML6_REGISTRY_TOPIC_DOMAIN',
          '$path.domainId',
          'Topic domainId must exist in the canonical blueprint.',
        );
      }

      if (competencyId is! String || competencyForId(competencyId) == null) {
        _add(
          issues,
          'ML6_REGISTRY_TOPIC_COMPETENCY',
          '$path.competencyId',
          'Topic competencyId must exist in the canonical blueprint.',
        );
      }

      if (domainId is String &&
          competencyId is String &&
          !_competencyBelongsToDomain(domainId, competencyId)) {
        _add(
          issues,
          'ML6_REGISTRY_COMPETENCY_PARENT',
          '$path.competencyId',
          'Topic competency does not belong to the declared domain.',
        );
      }

      if (topicId is String &&
          competencyId is String &&
          !topicId.startsWith('${competencyId}_t')) {
        _add(
          issues,
          'ML6_REGISTRY_TOPIC_PARENTAGE',
          '$path.id',
          'Topic ID prefix must match its canonical competency parent.',
        );
      }

      if (!_nonEmptyString(topic['title'])) {
        _add(
          issues,
          'ML6_REGISTRY_TOPIC_TITLE',
          '$path.title',
          'Topic title is required.',
        );
      }

      if (!{'active', 'deprecated', 'retired'}.contains(status)) {
        _add(
          issues,
          'ML6_REGISTRY_TOPIC_STATUS',
          '$path.status',
          'Unknown topic lifecycle status.',
        );
      }

      final subtopics = topic['subtopics'];
      if (subtopics is! List) {
        _add(
          issues,
          'ML6_REGISTRY_SUBTOPICS',
          '$path.subtopics',
          'subtopics must be an array.',
        );
        continue;
      }

      for (var j = 0; j < subtopics.length; j++) {
        subtopicCount++;
        final rawSubtopic = subtopics[j];
        final subPath = '$path.subtopics[$j]';
        if (rawSubtopic is! Map) {
          _add(
            issues,
            'ML6_REGISTRY_SUBTOPIC_OBJECT',
            subPath,
            'Each subtopic must be an object.',
          );
          continue;
        }

        final subtopic = Map<String, dynamic>.from(rawSubtopic);
        _exactKeys(subtopic, const {'id', 'title', 'status'}, subPath, issues);

        final subtopicId = subtopic['id'];
        if (subtopicId is! String ||
            !RegExp(
              r'^d0[1-7]_c[0-9]{2}_t[0-9]{2}_s[0-9]{2}$',
            ).hasMatch(subtopicId)) {
          _add(
            issues,
            'ML6_REGISTRY_SUBTOPIC_ID',
            '$subPath.id',
            'Subtopic ID must use canonical dXX_cYY_tZZ_sAA format.',
          );
        } else {
          if (!subtopicIds.add(subtopicId)) {
            _add(
              issues,
              'ML6_REGISTRY_DUPLICATE_SUBTOPIC',
              '$subPath.id',
              'Subtopic IDs must be globally unique.',
            );
          }
          if (topicId is String && !subtopicId.startsWith('${topicId}_s')) {
            _add(
              issues,
              'ML6_REGISTRY_SUBTOPIC_PARENTAGE',
              '$subPath.id',
              'Subtopic ID prefix must match its canonical topic parent.',
            );
          }
        }

        if (!_nonEmptyString(subtopic['title'])) {
          _add(
            issues,
            'ML6_REGISTRY_SUBTOPIC_TITLE',
            '$subPath.title',
            'Subtopic title is required.',
          );
        }

        if (!{'active', 'deprecated', 'retired'}.contains(subtopic['status'])) {
          _add(
            issues,
            'ML6_REGISTRY_SUBTOPIC_STATUS',
            '$subPath.status',
            'Unknown subtopic lifecycle status.',
          );
        }
      }
    }

    if (registry['topicCount'] != topics.length) {
      _add(
        issues,
        'ML6_REGISTRY_TOPIC_COUNT',
        r'$registry.topicCount',
        'topicCount must equal the actual topic array length.',
      );
    }

    if (registry['subtopicCount'] != subtopicCount) {
      _add(
        issues,
        'ML6_REGISTRY_SUBTOPIC_COUNT',
        r'$registry.subtopicCount',
        'subtopicCount must equal the actual nested subtopic count.',
      );
    }

    final populationStatus = registry['populationStatus'];
    if (!{
      'domain_competency_only',
      'navigation_nodes_registered',
    }.contains(populationStatus)) {
      _add(
        issues,
        'ML6_REGISTRY_POPULATION_STATUS',
        r'$registry.populationStatus',
        'Unknown navigation registry population status.',
      );
    } else if (populationStatus == 'domain_competency_only' &&
        (topics.isNotEmpty || subtopicCount != 0)) {
      _add(
        issues,
        'ML6_REGISTRY_POPULATION_MISMATCH',
        r'$registry.populationStatus',
        'domain_competency_only registry must contain zero navigation nodes.',
      );
    } else if (populationStatus == 'navigation_nodes_registered' &&
        topics.isEmpty) {
      _add(
        issues,
        'ML6_REGISTRY_POPULATION_MISMATCH',
        r'$registry.populationStatus',
        'navigation_nodes_registered requires at least one topic.',
      );
    }

    return CanonicalCurriculumRegistryValidationResult(
      List.unmodifiable(issues),
    );
  }

  void _validatePolicy(
    dynamic value,
    List<CanonicalCurriculumRegistryIssue> issues,
  ) {
    if (value is! Map) {
      _add(
        issues,
        'ML6_REGISTRY_POLICY',
        r'$registry.policy',
        'Registry policy object is required.',
      );
      return;
    }

    final map = Map<String, dynamic>.from(value);
    _exactKeys(
      map,
      const {
        'topicAuthority',
        'subtopicAuthority',
        'unregisteredTopicDisposition',
        'unregisteredSubtopicDisposition',
        'legacyIdDisposition',
        'deprecatedNodeDisposition',
        'automaticRemap',
      },
      r'$registry.policy',
      issues,
    );

    if (map['topicAuthority'] != 'explicit_registry_only' ||
        map['subtopicAuthority'] != 'explicit_registry_only' ||
        map['unregisteredTopicDisposition'] != 'block' ||
        map['unregisteredSubtopicDisposition'] != 'block' ||
        map['legacyIdDisposition'] != 'block' ||
        map['deprecatedNodeDisposition'] != 'block' ||
        map['automaticRemap'] != false) {
      _add(
        issues,
        'ML6_REGISTRY_POLICY_WEAKENED',
        r'$registry.policy',
        'Navigation registry must remain explicit and fail closed.',
      );
    }
  }

  static bool _competencyBelongsToDomain(String domainId, String competencyId) {
    return competenciesForDomain(
      domainId,
    ).any((competency) => competency.id == competencyId);
  }

  static bool _nonEmptyString(dynamic value) =>
      value is String && value.trim().isNotEmpty;

  static bool _isStrictDate(dynamic value) {
    if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}
      return false;
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return false;
    final normalized =
        '${parsed.year.toString().padLeft(4, '0')}-'
        '${parsed.month.toString().padLeft(2, '0')}-'
        '${parsed.day.toString().padLeft(2, '0')}';
    return normalized == value;
  }

  static void _exactKeys(
    Map<String, dynamic> map,
    Set<String> expected,
    String path,
    List<CanonicalCurriculumRegistryIssue> issues,
  ) {
    final actual = map.keys.toSet();
    for (final missing in expected.difference(actual)) {
      _add(
        issues,
        'ML6_REGISTRY_REQUIRED_FIELD',
        '$path.$missing',
        'Required registry field is missing.',
      );
    }
    for (final extra in actual.difference(expected)) {
      _add(
        issues,
        'ML6_REGISTRY_UNKNOWN_FIELD',
        '$path.$extra',
        'Unknown registry field is not allowed.',
      );
    }
  }

  static void _add(
    List<CanonicalCurriculumRegistryIssue> issues,
    String code,
    String path,
    String message,
  ) {
    issues.add(
      CanonicalCurriculumRegistryIssue(
        code: code,
        path: path,
        message: message,
      ),
    );
  }
}
).hasMatch(value)) {
      return false;
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return false;
    final normalized =
        '${parsed.year.toString().padLeft(4, '0')}-'
        '${parsed.month.toString().padLeft(2, '0')}-'
        '${parsed.day.toString().padLeft(2, '0')}';
    return normalized == value;
  }

  static void _exactKeys(
    Map<String, dynamic> map,
    Set<String> expected,
    String path,
    List<CanonicalCurriculumRegistryIssue> issues,
  ) {
    final actual = map.keys.toSet();
    for (final missing in expected.difference(actual)) {
      _add(
        issues,
        'ML6_REGISTRY_REQUIRED_FIELD',
        '$path.$missing',
        'Required registry field is missing.',
      );
    }
    for (final extra in actual.difference(expected)) {
      _add(
        issues,
        'ML6_REGISTRY_UNKNOWN_FIELD',
        '$path.$extra',
        'Unknown registry field is not allowed.',
      );
    }
  }

  static void _add(
    List<CanonicalCurriculumRegistryIssue> issues,
    String code,
    String path,
    String message,
  ) {
    issues.add(
      CanonicalCurriculumRegistryIssue(
        code: code,
        path: path,
        message: message,
      ),
    );
  }
}
