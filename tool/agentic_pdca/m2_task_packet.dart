import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'm1_path_guard.dart';

const m2PlanSha = '7a59205c550af5cc36a2c233513fc21b4f780e64';
const m2PhaseBaseSha = 'd6a20c988027bdc25aeddc041cc16849bc259ad6';
const m2GovernanceSha = '43b2b3cc99839ae9de4092b4e2b7058d1964bff7';

bool m2ExactSha(String value) => RegExp(r'^[0-9a-f]{40}$').hasMatch(value);

/// Sorted object keys; array order is significant. No timestamps or host state.
String m2CanonicalJson(Object? value) => jsonEncode(_freeze(value));

Object? _freeze(Object? value) {
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    return Map<String, Object?>.unmodifiable({
      for (final key in keys) key: _freeze(value[key]),
    });
  }
  if (value is List) return List<Object?>.unmodifiable(value.map(_freeze));
  return value;
}

/// Syntax and scope validation is not authorization. A trusted manifest must
/// separately bind the hash before DO. Pilot B is deliberately unavailable.
final class M2TaskPacket {
  M2TaskPacket._(this._data);

  factory M2TaskPacket.fromJson(Map<String, Object?> source) {
    // Copy first so later caller mutation cannot change validation or identity.
    final data = _freeze(source) as Map<String, Object?>;
    final packet = M2TaskPacket._(data);
    packet._validate();
    return packet;
  }

  factory M2TaskPacket.parse(String source) {
    final value = jsonDecode(source);
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Packet must be an object.');
    }
    return M2TaskPacket.fromJson(value);
  }

  final Map<String, Object?> _data;
  Map<String, Object?> toJson() => _data;
  String get canonicalJson => m2CanonicalJson(_data);
  String get hash => sha256.convert(utf8.encode(canonicalJson)).toString();
  String text(String key) => _data[key] as String;
  List<String> strings(String key) =>
      List<String>.unmodifiable((_data[key] as List).cast<String>());
  int get revision => _data['revision'] as int;
  String get taskId => text('task_id');
  String get lineageId => text('lineage_id');
  String get taskBaseSha => text('task_base_sha');
  String get branch => text('branch');
  List<String> get expectedPaths => strings('expected_changed_paths');

  static const budgetCaps = {
    'F1': 5,
    'F2': 5,
    'F3': 3,
    'F4': 3,
    'F5': 3,
    'F6': 0,
    'F7': 2,
    'F8': 0,
    'F9': 0,
    'F10': 0,
  };
  static const _textKeys = {
    'task_id',
    'lineage_id',
    'maturity',
    'plan_sha',
    'governance_sha',
    'phase_base_sha',
    'task_base_sha',
    'branch',
    'feature_objective',
    'risk_class',
    'human_approval_reference',
  };
  static const _listKeys = {
    'acceptance_criteria',
    'in_scope_requirements',
    'out_of_scope_requirements',
    'allowed_paths',
    'forbidden_paths',
    'protected_paths',
    'expected_changed_paths',
    'required_targeted_tests',
    'required_architecture_gates',
    'required_check_gates',
    'permitted_repair_classes',
    'dependencies',
    'stop_conditions',
    'expected_handoff',
  };

  void _validate() {
    const keys = {
      ..._textKeys,
      ..._listKeys,
      'schema_version',
      'revision',
      'repair_budgets',
    };
    if (_data.length != keys.length || !_data.keys.every(keys.contains)) {
      throw const FormatException('Missing or unknown packet fields.');
    }
    for (final key in _textKeys) {
      final value = _data[key];
      if (value is! String || value.trim().isEmpty || value != value.trim()) {
        throw FormatException('Nonempty canonical string required: $key');
      }
    }
    for (final key in _listKeys) {
      final value = _data[key];
      if (value is! List ||
          value.any((v) => v is! String || v.trim().isEmpty || v != v.trim()) ||
          value.toSet().length != value.length ||
          (key != 'dependencies' && value.isEmpty)) {
        throw FormatException('Unique nonempty string list required: $key');
      }
    }
    if (!strings('expected_handoff').toSet().containsAll(const {
      'task_id',
      'lineage_id',
      'packet_hash',
      'revision',
      'base_sha',
      'candidate_sha',
      'branch',
      'commits',
      'changed_paths',
      'diff_statistics',
      'targeted_tests',
      'architecture_gates',
      'known_limitations',
      'expected_changed_paths',
      'clean_worktree',
      'evidence_references',
    })) {
      throw const FormatException('Incomplete handoff contract.');
    }
    if (_data['schema_version'] != 1 ||
        _data['revision'] is! int ||
        revision < 1 ||
        text('maturity') != 'M2' ||
        text('plan_sha') != m2PlanSha ||
        text('phase_base_sha') != m2PhaseBaseSha ||
        text('governance_sha') != m2GovernanceSha ||
        !m2ExactSha(taskBaseSha) ||
        !['low', 'moderate'].contains(text('risk_class'))) {
      throw const FormatException(
        'Invalid version, frozen identity, base or risk.',
      );
    }
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]*$').hasMatch(taskId) ||
        !RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]*$').hasMatch(lineageId) ||
        branch != 'agentic-pdca-m2-bounded-feature') {
      throw const FormatException('Invalid task, lineage or Pilot A branch.');
    }
    final budgets = _data['repair_budgets'];
    if (budgets is! Map || budgets.length != budgetCaps.length) {
      throw const FormatException('All canonical repair budgets are required.');
    }
    for (final entry in budgetCaps.entries) {
      final value = budgets[entry.key];
      if (value is! int || value < 0 || value > entry.value) {
        throw FormatException('Invalid budget for ${entry.key}');
      }
    }
    if (strings(
      'permitted_repair_classes',
    ).any((c) => !budgetCaps.containsKey(c) || (budgets[c] as int) == 0)) {
      throw const FormatException('Unbudgeted repair class.');
    }
    if (!strings('required_check_gates').toSet().containsAll([
      'FORMAT',
      'ANALYZE',
      'TEST',
      'ARCHITECTURE_GATE',
      'CHECK2',
      'CHECK3',
    ])) {
      throw const FormatException('Required M2 gates missing.');
    }
    for (final key in ['allowed_paths', 'forbidden_paths', 'protected_paths']) {
      if (strings(key).any((p) => !_validPattern(p))) {
        throw FormatException('Noncanonical path pattern: $key');
      }
    }
    for (final allowed in strings('allowed_paths')) {
      if (!_pilotPattern(allowed) ||
          [
            ...strings('forbidden_paths'),
            ...strings('protected_paths'),
          ].any((denied) => _overlap(allowed, denied))) {
        throw FormatException(
          'Scope contradiction or non-Pilot A path: $allowed',
        );
      }
    }
    if (expectedPaths.any((path) => !allows(path))) {
      throw const FormatException('Expected changes exceed approved envelope.');
    }
    for (final path in strings('required_targeted_tests')) {
      if (!RegExp(
        r'^test/agentic_pdca/m2_[A-Za-z0-9_]+_test\.dart$',
      ).hasMatch(path)) {
        throw const FormatException('Targeted tests must be M2 test paths.');
      }
    }
    for (final path in strings('required_architecture_gates')) {
      if (path != 'test/agentic_pdca/m1_architecture_gate_test.dart' &&
          !RegExp(
            r'^test/agentic_pdca/m2_[A-Za-z0-9_]+_test\.dart$',
          ).hasMatch(path)) {
        throw const FormatException('Unknown architecture gate path.');
      }
    }
  }

  bool allows(String path) {
    const guard = M1RepositoryPathGuard();
    return !path.contains('*') &&
        !guard.isProtected(path) &&
        guard.isAllowed(path, strings('allowed_paths')) &&
        !guard.isAllowed(path, [
          ...strings('forbidden_paths'),
          ...strings('protected_paths'),
        ]);
  }

  static bool _validPattern(String pattern) {
    final base = pattern.endsWith('/**')
        ? pattern.substring(0, pattern.length - 3)
        : pattern;
    return !base.contains('*') &&
        !base.contains('?') &&
        const M1RepositoryPathGuard().canonicalize(base) != null;
  }

  static bool _pilotPattern(String pattern) =>
      RegExp(
        r'^(tool|test)/agentic_pdca/m2_[A-Za-z0-9_]+\.dart$',
      ).hasMatch(pattern) ||
      pattern == 'docs/agentic/implementation/m2/**' ||
      const M1RepositoryPathGuard().isAllowed(pattern, [
        'docs/agentic/implementation/m2/**',
      ]);

  static bool _overlap(String a, String b) {
    final x = a.endsWith('/**') ? a.substring(0, a.length - 3) : a;
    final y = b.endsWith('/**') ? b.substring(0, b.length - 3) : b;
    return x == y ||
        (a.endsWith('/**') && y.startsWith('$x/')) ||
        (b.endsWith('/**') && x.startsWith('$y/'));
  }
}
