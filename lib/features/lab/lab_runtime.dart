import 'lab_contracts.dart';
import 'lab_state.dart';
import 'lab_story_gate.dart';

class LabDecisionResolution {
  const LabDecisionResolution({
    required this.nodeId,
    required this.optionId,
    required this.consequence,
    required this.gate,
  });

  final String nodeId;
  final String optionId;
  final LabConsequenceResult consequence;
  final LabGateResult? gate;

  LabState get state => consequence.state;
}

class LabDeterministicRuntime {
  const LabDeterministicRuntime({
    this.consequenceEngine = const LabConsequenceEngine(),
    this.gateEvaluator = const LabGateEvaluator(),
  });

  final LabConsequenceEngine consequenceEngine;
  final LabGateEvaluator gateEvaluator;

  LabDecisionResolution resolveDecision({
    required LabState state,
    required LabDecisionNode node,
    required String optionId,
    required String applicationKey,
    required Iterable<LabStoryGate> gates,
    Map<String, LabConsequence> consequenceRegistry =
        const <String, LabConsequence>{},
  }) {
    node.validate();

    final option = node.requireOption(optionId);
    final consequence =
        option.consequence ??
        (option.consequenceId == null
            ? null
            : consequenceRegistry[option.consequenceId]);

    if (consequence == null) {
      throw LabContractException(
        'Runtime cannot resolve consequence reference ' +
            option.consequenceId.toString() +
            '.',
      );
    }

    final consequenceResult = consequenceEngine.apply(
      state: state,
      consequence: consequence,
      applicationKey: applicationKey,
    );

    final gateResult = gateEvaluator.evaluate(
      state: consequenceResult.state,
      currentNodeId: node.id,
      gates: gates,
    );

    return LabDecisionResolution(
      nodeId: node.id,
      optionId: option.id,
      consequence: consequenceResult,
      gate: gateResult,
    );
  }
}
