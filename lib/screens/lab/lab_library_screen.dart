import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';

import 'lab_player_shell_screen.dart';
import 'lab_scenario_catalog.dart';

class LabLibraryScreen extends StatelessWidget {
  const LabLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? const Color(0xFFF4F7FB) : const Color(0xFF18243A);
    final muted = dark ? const Color(0xFFA5B1C4) : const Color(0xFF667083);
    final primary = Theme.of(context).colorScheme.primary;

    return StudentGlassScaffold(
      backgroundColor: dark ? const Color(0xFF0A111D) : const Color(0xFFF4F8FF),
      appBar: AppBar(
        title: const Text(
          'Safety Decision LAB',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: ListView(
          key: const ValueKey('lab-library-scroll'),
          padding: const EdgeInsets.all(20),
          children: [
            StudentGlassSurface(
              padding: const EdgeInsets.all(24),
              borderRadius: BorderRadius.circular(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.science_rounded, size: 42, color: primary),
                  const SizedBox(height: 14),
                  Text(
                    'Practice safety decisions before they happen for real',
                    key: const ValueKey('lab-learner-intro'),
                    style: TextStyle(
                      color: text,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Each LAB puts you inside a workplace situation. You choose '
                    'what to do next, confirm your decision and then see how the '
                    'situation develops because of that choice.',
                    style: TextStyle(color: muted, height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'A poor decision does not always end the LAB. You may need '
                    'to control the consequences, recover the situation or '
                    'respond to an emergency.',
                    style: TextStyle(color: muted, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            StudentGlassSurface(
              padding: const EdgeInsets.all(22),
              borderRadius: BorderRadius.circular(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How a LAB works',
                    style: TextStyle(
                      color: text,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _HowItWorksStep(
                    number: '1',
                    title: 'Read the situation',
                    description:
                        'Understand what is happening and what information matters.',
                  ),
                  const _HowItWorksStep(
                    number: '2',
                    title: 'Choose one action',
                    description:
                        'You will have four possible actions. Choose the action you would take.',
                  ),
                  const _HowItWorksStep(
                    number: '3',
                    title: 'Confirm your decision',
                    description:
                        'Once confirmed, that decision is locked for the current attempt.',
                  ),
                  const _HowItWorksStep(
                    number: '4',
                    title: 'See what happens next',
                    description:
                        'The scenario changes based on your decisions and continues until you reach an outcome.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            StudentGlassSurface(
              padding: const EdgeInsets.all(22),
              borderRadius: BorderRadius.circular(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What you get at the end',
                    style: TextStyle(
                      color: text,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _OutputRow(
                    icon: Icons.flag_circle_rounded,
                    text: 'Your final scenario outcome',
                  ),
                  const _OutputRow(
                    icon: Icons.timeline_rounded,
                    text: 'A timeline of the decisions you made',
                  ),
                  const _OutputRow(
                    icon: Icons.account_tree_rounded,
                    text: 'The consequences that shaped the scenario',
                  ),
                  const _OutputRow(
                    icon: Icons.psychology_alt_rounded,
                    text: 'Strengths, improvement areas and decision patterns',
                  ),
                  const _OutputRow(
                    icon: Icons.school_rounded,
                    text: 'Competency evidence and learning feedback',
                  ),
                  const _OutputRow(
                    icon: Icons.replay_rounded,
                    text: 'A chance to replay and try a different approach',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Choose how you want to practise',
              style: TextStyle(
                color: text,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            const _ModePreviewCard(
              icon: Icons.explore_rounded,
              title: 'Guided LAB',
              bestFor: 'Best for learning',
              description:
                  'Get more guidance and feedback while you work through the scenario.',
            ),
            const SizedBox(height: 10),
            const _ModePreviewCard(
              icon: Icons.engineering_rounded,
              title: 'Professional LAB',
              bestFor: 'Best for realistic practice',
              description:
                  'Make decisions with limited guidance. Review the detailed feedback after the LAB.',
            ),
            const SizedBox(height: 10),
            const _ModePreviewCard(
              icon: Icons.fact_check_rounded,
              title: 'Assessment LAB',
              bestFor: 'Best for testing yourself',
              description:
                  'Complete the scenario without coaching during the attempt and review your performance at the end.',
            ),
            const SizedBox(height: 24),
            Text(
              'Available scenarios',
              key: const ValueKey('lab-available-scenarios-heading'),
              style: TextStyle(
                color: text,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose a scenario first. You will select your LAB mode on the next screen.',
              style: TextStyle(color: muted, height: 1.45),
            ),
            const SizedBox(height: 14),
            for (final scenario in LabScenarioCatalog.all) ...[
              _ScenarioCard(scenario: scenario),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _HowItWorksStep extends StatelessWidget {
  const _HowItWorksStep({
    required this.number,
    required this.title,
    required this.description,
  });

  final String number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? const Color(0xFFF4F7FB) : const Color(0xFF18243A);
    final muted = dark ? const Color(0xFFA5B1C4) : const Color(0xFF667083);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            child: Text(
              number,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: text, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(description, style: TextStyle(color: muted, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutputRow extends StatelessWidget {
  const _OutputRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFA5B1C4)
        : const Color(0xFF667083);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 11),
          Expanded(
            child: Text(text, style: TextStyle(color: muted, height: 1.35)),
          ),
        ],
      ),
    );
  }
}

class _ModePreviewCard extends StatelessWidget {
  const _ModePreviewCard({
    required this.icon,
    required this.title,
    required this.bestFor,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String bestFor;
  final String description;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? const Color(0xFFF4F7FB) : const Color(0xFF18243A);
    final muted = dark ? const Color(0xFFA5B1C4) : const Color(0xFF667083);

    return StudentGlassSurface(
      padding: const EdgeInsets.all(17),
      borderRadius: BorderRadius.circular(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 27, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: text,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  bestFor,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(description, style: TextStyle(color: muted, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({required this.scenario});

  final LabScenarioDefinition scenario;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? const Color(0xFFF4F7FB) : const Color(0xFF18243A);
    final muted = dark ? const Color(0xFFA5B1C4) : const Color(0xFF667083);

    return StudentGlassSurface(
      key: ValueKey('lab-scenario-' + scenario.id),
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.health_and_safety_rounded,
                size: 31,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  scenario.title,
                  style: TextStyle(
                    color: text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(scenario.summary, style: TextStyle(color: muted, height: 1.5)),
          const SizedBox(height: 12),
          Text(
            scenario.focus,
            style: TextStyle(
              color: text,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            scenario.difficulty,
            style: TextStyle(color: muted, fontSize: 12.5),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: ValueKey('lab-scenario-open-' + scenario.id),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LabPlayerShellScreen(scenario: scenario),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('CHOOSE SCENARIO'),
            ),
          ),
        ],
      ),
    );
  }
}
