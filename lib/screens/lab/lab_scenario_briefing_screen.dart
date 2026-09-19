import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';

import 'lab_player_shell_screen.dart';
import 'lab_scenario_catalog.dart';

class LabScenarioBriefingScreen extends StatelessWidget {
  const LabScenarioBriefingScreen({super.key, required this.scenario});

  final LabScenarioDefinition scenario;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? const Color(0xFFF4F7FB) : const Color(0xFF18243A);
    final muted = dark ? const Color(0xFFA5B1C4) : const Color(0xFF667083);

    return StudentGlassScaffold(
      backgroundColor: dark ? const Color(0xFF0A111D) : const Color(0xFFF4F8FF),
      appBar: AppBar(title: const Text('Scenario Briefing')),
      body: SafeArea(
        child: ListView(
          key: const ValueKey('lab-scenario-briefing'),
          padding: const EdgeInsets.all(20),
          children: [
            StudentGlassSurface(
              padding: const EdgeInsets.all(22),
              borderRadius: BorderRadius.circular(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scenario.title,
                    key: const ValueKey('lab-briefing-title'),
                    style: TextStyle(
                      color: text,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      height: 1.22,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Read the briefing before you choose how you want to practise.',
                    style: TextStyle(color: muted, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            _BriefingSection(
              icon: Icons.badge_outlined,
              title: 'Your role',
              body: scenario.role,
            ),
            const SizedBox(height: 12),
            _BriefingSection(
              icon: Icons.place_outlined,
              title: 'Situation',
              body: scenario.situation,
            ),
            const SizedBox(height: 12),
            _BriefingSection(
              icon: Icons.flag_outlined,
              title: 'Your objective',
              body: scenario.objective,
            ),
            const SizedBox(height: 12),
            StudentGlassSurface(
              padding: const EdgeInsets.all(19),
              borderRadius: BorderRadius.circular(19),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeading(
                    icon: Icons.groups_rounded,
                    title: 'People involved',
                  ),
                  const SizedBox(height: 11),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final person in scenario.peopleInvolved)
                        Chip(label: Text(person)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            StudentGlassSurface(
              padding: const EdgeInsets.all(19),
              borderRadius: BorderRadius.circular(19),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeading(
                    icon: Icons.fact_check_outlined,
                    title: 'What you know so far',
                  ),
                  const SizedBox(height: 11),
                  for (final fact in scenario.knownFacts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 7,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              fact,
                              style: TextStyle(color: muted, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const ValueKey('lab-briefing-continue'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LabPlayerShellScreen(scenario: scenario),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('CONTINUE'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BriefingSection extends StatelessWidget {
  const _BriefingSection({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final muted = dark ? const Color(0xFFA5B1C4) : const Color(0xFF667083);

    return StudentGlassSurface(
      padding: const EdgeInsets.all(19),
      borderRadius: BorderRadius.circular(19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(icon: icon, title: title),
          const SizedBox(height: 8),
          Text(body, style: TextStyle(color: muted, height: 1.45)),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? const Color(0xFFF4F7FB) : const Color(0xFF18243A);

    return Row(
      children: [
        Icon(icon, size: 21, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: text,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
