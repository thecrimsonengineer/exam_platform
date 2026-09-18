import 'lab_contracts.dart';
import 'lab_state.dart';

enum LabNumericOperator {
  lessThan,
  lessOrEqual,
  equal,
  greaterOrEqual,
  greaterThan,
}

LabNumericOperator parseNumericOperator(Object? value) {
  switch (value?.toString().trim().toUpperCase()) {
    case 'LT':
      return LabNumericOperator.lessThan;
    case 'LTE':
      return LabNumericOperator.lessOrEqual;
    case 'EQ':
      return LabNumericOperator.equal;
    case 'GTE':
      return LabNumericOperator.greaterOrEqual;
    case 'GT':
      return LabNumericOperator.greaterThan;
  }
  throw LabContractException('Unknown numeric gate operator: $value');
}

abstract class LabCondition {
  const LabCondition();

  bool evaluate(LabState state);

  factory LabCondition.fromJson(Map<String, Object?> json) {
    final op = json['op']?.toString().trim().toUpperCase();

    switch (op) {
      case 'ALWAYS':
        return const LabAlwaysCondition();
      case 'BOOLEAN':
        return LabBooleanCondition(
          stateId: json['stateId']?.toString() ?? '',
          expected: json['equals'] == true,
        );
      case 'NUMERIC':
        final value = json['value'];
        if (value is! num) {
          throw const LabContractException(
            'Numeric gate condition requires a numeric value.',
          );
        }
        return LabNumericCondition(
          stateId: json['stateId']?.toString() ?? '',
          operator: parseNumericOperator(json['operator']),
          value: value,
        );
      case 'ENUM':
        return LabEnumCondition(
          stateId: json['stateId']?.toString() ?? '',
          expected: json['equals']?.toString() ?? '',
        );
      case 'SET_CONTAINS':
        return LabSetContainsCondition(
          stateId: json['stateId']?.toString() ?? '',
          member: json['value']?.toString() ?? '',
        );
      case 'AND':
      case 'OR':
        final rawConditions = json['conditions'];
        if (rawConditions is! Iterable) {
          throw const LabContractException(
            'Compound gate condition requires conditions.',
          );
        }
        final conditions = rawConditions.map((item) {
          if (item is! Map) {
            throw const LabContractException(
              'Compound gate child must be an object.',
            );
          }
          return LabCondition.fromJson(
            item.cast<String, Object?>(),
          );
        }).toList(growable: false);
        return op == 'AND'
            ? LabAllCondition(conditions)
            : LabAnyCondition(conditions);
      case 'NOT':
        final child = json['condition'];
        if (child is! Map) {
          throw const LabContractException(
            'NOT gate condition requires one child condition.',
          );
        }
        return LabNotCondition(
          LabCondition.fromJson(child.cast<String, Object?>()),
        );
    }

    throw LabContractException(
      'Unsupported declarative LAB gate condition: $op',
    );
  }
}

class LabAlwaysCondition extends LabCondition {
  const LabAlwaysCondition();

  @override
  bool evaluate(LabState state) => true;
}

class LabBooleanCondition extends LabCondition {
  LabBooleanCondition({
    required String stateId,
    required this.expected,
  }) : stateId = LabIds.requireCanonical(stateId, 'gate state ID');

  final String stateId;
  final bool expected;

  @override
  bool evaluate(LabState state) {
    final value = state.valueOf(stateId);
    if (value is! bool) {
      throw LabContractException(
        '$stateId is not a Boolean state variable.',
      );
    }
    return value == expected;
  }
}

class LabNumericCondition extends LabCondition {
  LabNumericCondition({
    required String stateId,
    required this.operator,
    required this.value,
  }) : stateId = LabIds.requireCanonical(stateId, 'gate state ID');

  final String stateId;
  final LabNumericOperator operator;
  final num value;

  @override
  bool evaluate(LabState state) {
    final current = state.valueOf(stateId);
    if (current is! num) {
      throw LabContractException(
        '$stateId is not a numeric state variable.',
      );
    }

    return switch (operator) {
      LabNumericOperator.lessThan => current < value,
      LabNumericOperator.lessOrEqual => current <= value,
      LabNumericOperator.equal => current == value,
      LabNumericOperator.greaterOrEqual => current >= value,
      LabNumericOperator.greaterThan => current > value,
    };
  }
}

class LabEnumCondition extends LabCondition {
  LabEnumCondition({
    required String stateId,
    required String expected,
  })  : stateId = LabIds.requireCanonical(stateId, 'gate state ID'),
        expected = expected.trim() {
    if (this.expected.isEmpty) {
      throw const LabContractException(
        'Enum gate condition requires an expected value.',
      );
    }
  }

  final String stateId;
  final String expected;

  @override
  bool evaluate(LabState state) => state.valueOf(stateId) == expected;
}

class LabSetContainsCondition extends LabCondition {
  LabSetContainsCondition({
    required String stateId,
    required String member,
  })  : stateId = LabIds.requireCanonical(stateId, 'gate state ID'),
        member = member.trim() {
    if (this.member.isEmpty) {
      throw const LabContractException(
        'Set gate condition requires a member.',
      );
    }
  }

  final String stateId;
  final String member;

  @override
  bool evaluate(LabState state) {
    final value = state.valueOf(stateId);
    if (value is! Iterable) {
      throw LabContractException(
        '$stateId is not a set/list state variable.',
      );
    }
    return value.map((item) => item.toString()).contains(member);
  }
}

class LabAllCondition extends LabCondition {
  LabAllCondition(Iterable<LabCondition> conditions)
      : conditions = List<LabCondition>.unmodifiable(conditions) {
    if (this.conditions.isEmpty) {
      throw const LabContractException(
        'AND condition requires at least one child.',
      );
    }
  }

  final List<LabCondition> conditions;

  @override
  bool evaluate(LabState state) =>
      conditions.every((condition) => condition.evaluate(state));
}

class LabAnyCondition extends LabCondition {
  LabAnyCondition(Iterable<LabCondition> conditions)
      : conditions = List<LabCondition>.unmodifiable(conditions) {
    if (this.conditions.isEmpty) {
      throw const LabContractException(
        'OR condition requires at least one child.',
      );
    }
  }

  final List<LabCondition> conditions;

  @override
  bool evaluate(LabState state) =>
      conditions.any((condition) => condition.evaluate(state));
}

class LabNotCondition extends LabCondition {
  const LabNotCondition(this.condition);

  final LabCondition condition;

  @override
  bool evaluate(LabState state) => !condition.evaluate(state);
}

class LabStoryGate {
  LabStoryGate({
    required String id,
    required this.type,
    required this.priority,
    required this.condition,
    this.fromNodeId,
    this.targetNodeId,
    this.endingId,
  }) : id = LabIds.requireCanonical(id, 'gate ID') {
    if (priority < 0) {
      throw const LabContractException(
        'Gate priority must be a non-negative integer.',
      );
    }
    if (fromNodeId != null) {
      LabIds.requireCanonical(fromNodeId!, 'gate source node ID');
    }
    if (targetNodeId != null) {
      LabIds.requireCanonical(targetNodeId!, 'gate target node ID');
    }
    if (endingId != null) {
      LabIds.requireCanonical(endingId!, 'ending ID');
    }

    if (type == LabGateType.completion) {
      if (endingId == null || targetNodeId != null) {
        throw const LabContractException(
          'Completion Gate requires endingId and no targetNodeId.',
        );
      }
    } else if ((type == LabGateType.route ||
            type == LabGateType.criticalEvent ||
            type == LabGateType.convergence) &&
        targetNodeId == null) {
      throw LabContractException(
        type.toString() + ' requires a target node.',
      );
    }
  }

  factory LabStoryGate.fromJson(Map<String, Object?> json) {
    final rawCondition = json['condition'];
    if (rawCondition is! Map) {
      throw const LabContractException(
        'Story Gate requires a declarative condition object.',
      );
    }

    final priorityValue = json['priority'];
    if (priorityValue is! int) {
      throw const LabContractException(
        'Story Gate priority must be an integer.',
      );
    }

    return LabStoryGate(
      id: json['id']?.toString() ?? '',
      type: parseGateType(json['type']),
      priority: priorityValue,
      condition: LabCondition.fromJson(
        rawCondition.cast<String, Object?>(),
      ),
      fromNodeId: json['fromNodeId']?.toString(),
      targetNodeId: json['targetNodeId']?.toString(),
      endingId: json['endingId']?.toString(),
    );
  }

  final String id;
  final LabGateType type;
  final int priority;
  final LabCondition condition;
  final String? fromNodeId;
  final String? targetNodeId;
  final String? endingId;

  bool isEligible({
    required LabState state,
    required String currentNodeId,
  }) {
    if (fromNodeId != null && fromNodeId != currentNodeId) {
      return false;
    }
    return condition.evaluate(state);
  }
}

class LabGateResult {
  const LabGateResult({
    required this.gateId,
    required this.type,
    required this.priority,
    this.targetNodeId,
    this.endingId,
  });

  final String gateId;
  final LabGateType type;
  final int priority;
  final String? targetNodeId;
  final String? endingId;
}

class LabGateAmbiguityException extends LabContractException {
  const LabGateAmbiguityException(super.message);
}

class LabGateEvaluator {
  const LabGateEvaluator();

  LabGateResult? evaluate({
    required LabState state,
    required String currentNodeId,
    required Iterable<LabStoryGate> gates,
  }) {
    LabIds.requireCanonical(currentNodeId, 'current node ID');

    final eligible = gates
        .where(
          (gate) => gate.isEligible(
            state: state,
            currentNodeId: currentNodeId,
          ),
        )
        .toList(growable: false);

    if (eligible.isEmpty) return null;

    var highest = eligible.first.priority;
    for (final gate in eligible.skip(1)) {
      if (gate.priority > highest) highest = gate.priority;
    }

    final winners =
        eligible.where((gate) => gate.priority == highest).toList();

    if (winners.length != 1) {
      final ids = winners.map((gate) => gate.id).toList()..sort();
      throw LabGateAmbiguityException(
        'Reachable LAB state activates equal-priority gates: ' +
            ids.join(', '),
      );
    }

    final winner = winners.single;
    return LabGateResult(
      gateId: winner.id,
      type: winner.type,
      priority: winner.priority,
      targetNodeId: winner.targetNodeId,
      endingId: winner.endingId,
    );
  }
}
