import 'lab_contracts.dart';

class LabStateSnapshot {
  const LabStateSnapshot({
    required this.values,
    required this.evidenceUnlocked,
    required this.simulatedMinutes,
  });

  final Map<String, Object?> values;
  final Set<String> evidenceUnlocked;
  final int simulatedMinutes;
}

class LabValueChange {
  const LabValueChange({required this.before, required this.after});

  final Object? before;
  final Object? after;
}

class LabState {
  LabState._({
    required this.registry,
    required Map<String, Object?> values,
    required Set<String> evidenceUnlocked,
    required Set<String> appliedConsequenceKeys,
    required this.simulatedMinutes,
  }) : _values = Map<String, Object?>.unmodifiable(values),
       _evidenceUnlocked = Set<String>.unmodifiable(evidenceUnlocked),
       _appliedConsequenceKeys = Set<String>.unmodifiable(
         appliedConsequenceKeys,
       );

  factory LabState.initial({
    required LabStateRegistry registry,
    required Map<String, Object?> startingState,
  }) {
    return LabState._(
      registry: registry,
      values: registry.normalizeStartingState(startingState),
      evidenceUnlocked: const <String>{},
      appliedConsequenceKeys: const <String>{},
      simulatedMinutes: 0,
    );
  }

  factory LabState.restore({
    required LabStateRegistry registry,
    required Map<String, Object?> values,
    Iterable<String> evidenceUnlocked = const <String>[],
    Iterable<String> appliedConsequenceKeys = const <String>[],
    int simulatedMinutes = 0,
  }) {
    if (simulatedMinutes < 0) {
      throw const LabContractException(
        'Restored simulated time cannot be negative.',
      );
    }

    return LabState._(
      registry: registry,
      values: registry.normalizeStartingState(values),
      evidenceUnlocked: evidenceUnlocked.toSet(),
      appliedConsequenceKeys: appliedConsequenceKeys.toSet(),
      simulatedMinutes: simulatedMinutes,
    );
  }

  final LabStateRegistry registry;
  final Map<String, Object?> _values;
  final Set<String> _evidenceUnlocked;
  final Set<String> _appliedConsequenceKeys;
  final int simulatedMinutes;

  Map<String, Object?> get values => _values;
  Set<String> get evidenceUnlocked => _evidenceUnlocked;
  Set<String> get appliedConsequenceKeys => _appliedConsequenceKeys;

  Object? valueOf(String id) {
    registry.require(id);
    return _values[id];
  }

  bool hasApplied(String applicationKey) =>
      _appliedConsequenceKeys.contains(applicationKey);

  LabStateSnapshot get snapshot => LabStateSnapshot(
    values: Map<String, Object?>.unmodifiable(_values),
    evidenceUnlocked: Set<String>.unmodifiable(_evidenceUnlocked),
    simulatedMinutes: simulatedMinutes,
  );

  LabState _replace({
    required Map<String, Object?> values,
    required Set<String> evidenceUnlocked,
    required Set<String> appliedConsequenceKeys,
    required int simulatedMinutes,
  }) {
    return LabState._(
      registry: registry,
      values: values,
      evidenceUnlocked: evidenceUnlocked,
      appliedConsequenceKeys: appliedConsequenceKeys,
      simulatedMinutes: simulatedMinutes,
    );
  }
}

class LabConsequenceResult {
  const LabConsequenceResult({
    required this.state,
    required this.before,
    required this.after,
    required this.delta,
    required this.duplicate,
    required this.consequenceId,
  });

  final LabState state;
  final LabStateSnapshot before;
  final LabStateSnapshot after;
  final Map<String, LabValueChange> delta;
  final bool duplicate;
  final String consequenceId;
}

class LabConsequenceEngine {
  const LabConsequenceEngine();

  LabConsequenceResult apply({
    required LabState state,
    required LabConsequence consequence,
    required String applicationKey,
  }) {
    if (applicationKey.trim().isEmpty) {
      throw const LabContractException(
        'Consequence application key is required.',
      );
    }

    final before = state.snapshot;

    if (state.hasApplied(applicationKey)) {
      return LabConsequenceResult(
        state: state,
        before: before,
        after: before,
        delta: const <String, LabValueChange>{},
        duplicate: true,
        consequenceId: consequence.id,
      );
    }

    final working = Map<String, Object?>.from(state.values);
    final changes = <String, LabValueChange>{};

    for (final mutation in consequence.mutations) {
      if (mutation.kind == LabMutationKind.noOp) {
        continue;
      }

      final stateId = mutation.stateId;
      if (stateId == null) {
        throw const LabContractException(
          'Non-no-op mutation requires a state ID.',
        );
      }

      final definition = state.registry.require(stateId);
      final beforeValue = working[stateId];
      final afterValue = _mutate(
        definition: definition,
        before: beforeValue,
        mutation: mutation,
      );
      final normalized = definition.normalize(afterValue);

      if (definition.irreversible &&
          definition.kind == LabStateKind.boolean &&
          beforeValue == true &&
          normalized == false) {
        throw LabContractException(
          'Irreversible LAB flag $stateId cannot be reset.',
        );
      }

      working[stateId] = normalized;
      changes[stateId] = LabValueChange(before: beforeValue, after: normalized);
    }

    final evidence = Set<String>.from(state.evidenceUnlocked)
      ..addAll(consequence.evidenceUnlocks);
    final applied = Set<String>.from(state._appliedConsequenceKeys)
      ..add(applicationKey);

    final next = state._replace(
      values: working,
      evidenceUnlocked: evidence,
      appliedConsequenceKeys: applied,
      simulatedMinutes: state.simulatedMinutes + consequence.simulatedMinutes,
    );

    return LabConsequenceResult(
      state: next,
      before: before,
      after: next.snapshot,
      delta: Map<String, LabValueChange>.unmodifiable(changes),
      duplicate: false,
      consequenceId: consequence.id,
    );
  }

  Object? _mutate({
    required LabStateVariableDefinition definition,
    required Object? before,
    required LabStateMutation mutation,
  }) {
    switch (mutation.kind) {
      case LabMutationKind.noOp:
        return before;
      case LabMutationKind.set:
        return mutation.value;
      case LabMutationKind.increment:
        if (before is! num || mutation.value is! num) {
          throw LabContractException(
            definition.id + ' increment requires numeric values.',
          );
        }
        return before + (mutation.value as num);
      case LabMutationKind.add:
        return _add(definition, before, mutation.value);
      case LabMutationKind.remove:
        return _remove(definition, before, mutation.value);
    }
  }

  Object _add(
    LabStateVariableDefinition definition,
    Object? before,
    Object? value,
  ) {
    if (value is! String || value.trim().isEmpty) {
      throw LabContractException(
        definition.id + ' add requires a string member.',
      );
    }

    final current = before is Iterable
        ? before.map((item) => item.toString()).toList()
        : <String>[];

    switch (definition.kind) {
      case LabStateKind.stringSet:
        final set = current.toSet()..add(value.trim());
        final sorted = set.toList()..sort();
        return sorted;
      case LabStateKind.stringList:
        return <String>[...current, value.trim()];
      default:
        throw LabContractException(definition.id + ' does not support ADD.');
    }
  }

  Object _remove(
    LabStateVariableDefinition definition,
    Object? before,
    Object? value,
  ) {
    if (value is! String || value.trim().isEmpty) {
      throw LabContractException(
        definition.id + ' remove requires a string member.',
      );
    }

    final current = before is Iterable
        ? before.map((item) => item.toString()).toList()
        : <String>[];

    switch (definition.kind) {
      case LabStateKind.stringSet:
        final set = current.toSet()..remove(value.trim());
        final sorted = set.toList()..sort();
        return sorted;
      case LabStateKind.stringList:
        current.removeWhere((item) => item == value.trim());
        return current;
      default:
        throw LabContractException(definition.id + ' does not support REMOVE.');
    }
  }
}
