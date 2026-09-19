import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';

import 'lab_scenario_briefing_screen.dart';
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
              padding: const EdgeInsets.all(22),
              borderRadius: BorderRadius.circular(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.science_rounded, size: 40, color: primary),
                  const SizedBox(height: 13),
                  Text(
                    'Practice safety decisions before they happen for real',
                    key: const ValueKey('lab-learner-intro'),
                    style: TextStyle(
                      color: text,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    'Choose a workplace scenario, make decisions and see how the '
                    'situation develops because of your choices.',
                    style: TextStyle(color: muted, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
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
              'Choose a scenario to read the briefing and begin.',
              style: TextStyle(color: muted, height: 1.4),
            ),
            const SizedBox(height: 14),
            for (final scenario in LabScenarioCatalog.all) ...[
              _ScenarioCard(scenario: scenario),
              const SizedBox(height: 14),
            ],
            const SizedBox(height: 4),
            const _HowLabWorksCard(),
          ],
        ),
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
          const SizedBox(height: 11),
          Text(scenario.summary, style: TextStyle(color: muted, height: 1.45)),
          const SizedBox(height: 13),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final tag in scenario.focusTags)
                Chip(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  label: Text(tag),
                ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 18, color: muted),
              const SizedBox(width: 6),
              Text(scenario.estimatedTime, style: TextStyle(color: muted)),
              const SizedBox(width: 18),
              Icon(Icons.alt_route_rounded, size: 18, color: muted),
              const SizedBox(width: 6),
              Text(scenario.decisionCountLabel, style: TextStyle(color: muted)),
            ],
          ),
          const SizedBox(height: 17),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: ValueKey('lab-scenario-open-' + scenario.id),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        LabScenarioBriefingScreen(scenario: scenario),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('START SCENARIO'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HowLabWorksCard extends StatefulWidget {
  const _HowLabWorksCard();

  @override
  State<_HowLabWorksCard> createState() => _HowLabWorksCardState();
}

class _HowLabWorksCardState extends State<_HowLabWorksCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? const Color(0xFFF4F7FB) : const Color(0xFF18243A);
    final muted = dark ? const Color(0xFFA5B1C4) : const Color(0xFF667083);

    return StudentGlassSurface(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            key: const ValueKey('lab-how-it-works-toggle'),
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    Icons.help_outline_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How a LAB works',
                          style: TextStyle(
                            color: text,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Read, decide, confirm and see what happens next.',
                          style: TextStyle(color: muted, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: muted,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 18),
            const _HowStep(
              number: '1',
              title: 'Read the situation',
              description: 'Understand what is happening around you.',
            ),
            const _HowStep(
              number: '2',
              title: 'Choose one action',
              description: 'Select the action you would take.',
            ),
            const _HowStep(
              number: '3',
              title: 'Confirm your decision',
              description:
                  'Once confirmed, that decision is locked for the current attempt.',
            ),
            const _HowStep(
              number: '4',
              title: 'See what happens next',
              description:
                  'Your decision creates a consequence and the scenario continues.',
            ),
            const Divider(height: 26),
            Text(
              'You can use Guided, Professional or Assessment mode after reading '
              'the scenario briefing. At the end, you can review your outcome '
              'and decision journey.',
              style: TextStyle(color: muted, height: 1.45),
            ),
          ],
        ],
      ),
    );
  }
}

class _HowStep extends StatelessWidget {
  const _HowStep({
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
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            child: Text(
              number,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: text, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(description, style: TextStyle(color: muted, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
