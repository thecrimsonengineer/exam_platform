import 'package:flutter/material.dart';

import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/features/lab/lab_debrief.dart';
import 'package:exam_platform/features/lab/lab_session.dart';
import 'package:exam_platform/theme/glass/student_glass.dart';

import 'lab_scenario_catalog.dart';

class LabLearnerDebriefScreen extends StatelessWidget {
  const LabLearnerDebriefScreen({
    super.key,
    required this.package,
    required this.session,
    required this.scenario,
    required this.onReplay,
  });

  final LabPackage package;
  final LabSession session;
  final LabScenarioDefinition scenario;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    final debrief = const LabDebriefEngine().reconstruct(
      package: package,
      session: session,
    );
    final ending = scenario.endingFor(debrief.endingId);
    final strongCount = debrief.decisions
        .where(
          (decision) =>
              decision.quality == LabDecisionQuality.optimal ||
              decision.quality == LabDecisionQuality.defensible,
        )
        .length;
    final riskIncreasingCount = debrief.decisions
        .where(
          (decision) =>
              decision.quality == LabDecisionQuality.weak ||
              decision.quality == LabDecisionQuality.critical,
        )
        .length;
    final patterns = debrief.mistakeDnaSignals
        .map(_friendlyId)
        .toList()
      ..sort();
    final competencies = debrief.competencyEvidence
        .where((item) => !RegExp(r'^d\d{2}_c\d{2}$').hasMatch(item))
        .map(_friendlyId)
        .toSet()
        .toList()
      ..sort();

    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? const Color(0xFFF4F7FB) : const Color(0xFF18243A);
    final muted = dark ? const Color(0xFFA5B1C4) : const Color(0xFF667083);

    return StudentGlassScaffold(
      backgroundColor: dark ? const Color(0xFF0A111D) : const Color(0xFFF4F8FF),
      appBar: AppBar(title: const Text('LAB Debrief')),
      body: SafeArea(
        child: ListView(
          key: const ValueKey('lab-learner-debrief'),
          padding: const EdgeInsets.all(20),
          children: [
            _Section(
              title: 'Your outcome',
              icon: Icons.flag_circle_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ending.title,
                    key: const ValueKey('lab-debrief-outcome'),
                    style: TextStyle(
                      color: text,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ending.narrative,
                    style: TextStyle(color: muted, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'Your decision journey',
              icon: Icons.timeline_rounded,
              child: Column(
                children: [
                  for (final decision in debrief.decisions)
                    _DecisionDebriefRow(
                      decision: decision,
                      package: package,
                      scenario: scenario,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'Important turning points',
              icon: Icons.alt_route_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ending.keyTurningPoint,
                    style: TextStyle(color: text, height: 1.45),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    debrief.criticalDecisionIndexes.isEmpty
                        ? 'No decision in this attempt triggered the most severe authored decision category.'
                        : debrief.criticalDecisionIndexes.length.toString() +
                              ' decision(s) created a critical turning point in the authored scenario.',
                    style: TextStyle(color: muted, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'What you handled well',
              icon: Icons.task_alt_rounded,
              child: Text(
                strongCount == 0
                    ? 'This attempt did not record a decision that maintained or strengthened control.'
                    : strongCount.toString() +
                          ' decision(s) maintained or strengthened control in the authored scenario.',
                style: TextStyle(color: muted, height: 1.45),
              ),
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'Where risk increased',
              icon: Icons.trending_up_rounded,
              child: Text(
                riskIncreasingCount == 0
                    ? 'Your decisions did not create an authored increase in risk during this attempt.'
                    : riskIncreasingCount.toString() +
                          ' decision(s) allowed risk to increase or left important controls weaker.',
                style: TextStyle(color: muted, height: 1.45),
              ),
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'How you recovered',
              icon: Icons.restore_rounded,
              child: Text(
                debrief.recoveryDecisionIndexes.isEmpty
                    ? 'This route did not require a dedicated recovery-stage decision.'
                    : 'You reached ' +
                          debrief.recoveryDecisionIndexes.length.toString() +
                          ' authored recovery or emergency decision stage(s). Review those choices in your journey above.',
                style: TextStyle(color: muted, height: 1.45),
              ),
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'Patterns noticed',
              icon: Icons.psychology_alt_rounded,
              child: patterns.isEmpty
                  ? Text(
                      'No risk-increasing decision pattern was tagged in this attempt.',
                      style: TextStyle(color: muted, height: 1.45),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [for (final item in patterns) Chip(label: Text(item))],
                    ),
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'Competencies demonstrated',
              icon: Icons.school_rounded,
              child: competencies.isEmpty
                  ? Text(
                      'Competency evidence will build as you make more decisions.',
                      style: TextStyle(color: muted, height: 1.45),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final item in competencies) Chip(label: Text(item)),
                      ],
                    ),
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'References',
              icon: Icons.menu_book_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final source in debrief.sources)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Text(
                        source,
                        style: TextStyle(color: muted, height: 1.4),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'Explore another path',
              icon: Icons.replay_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Replay the same scenario and change one decision to see how the authored consequences and route change.',
                    style: TextStyle(color: muted, height: 1.45),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const ValueKey('lab-debrief-replay'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        onReplay();
                      },
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('REPLAY SCENARIO'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _friendlyId(String value) {
    return value
        .split('_')
        .where((part) => part.isNotEmpty)
        .map(
          (part) => part[0].toUpperCase() + part.substring(1).toLowerCase(),
        )
        .join(' ');
  }
}

class _DecisionDebriefRow extends StatelessWidget {
  const _DecisionDebriefRow({
    required this.decision,
    required this.package,
    required this.scenario,
  });

  final LabDebriefDecision decision;
  final LabPackage package;
  final LabScenarioDefinition scenario;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? const Color(0xFFF4F7FB) : const Color(0xFF18243A);
    final muted = dark ? const Color(0xFFA5B1C4) : const Color(0xFF667083);
    final node = package.nodes
        .whereType<LabDecisionNode>()
        .singleWhere((item) => item.id == decision.nodeId);
    final option = node.requireOption(decision.optionId);
    final consequence = scenario.consequenceFor(decision.consequenceId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            child: Text(
              (decision.index + 1).toString(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scenario.decisionTitleFor(decision.nodeId),
                  style: TextStyle(
                    color: text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  option.text,
                  style: TextStyle(color: text, height: 1.4),
                ),
                const SizedBox(height: 5),
                Text(
                  'What followed: ' + consequence.observable,
                  style: TextStyle(color: muted, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? const Color(0xFFF4F7FB) : const Color(0xFF18243A);

    return StudentGlassSurface(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: text,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}
