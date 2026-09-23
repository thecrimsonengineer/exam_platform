import 'package:flutter/material.dart';

import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/theme/glass/student_glass.dart';

import 'lab_reference_player_screen.dart';
import 'lab_scenario_catalog.dart';

class LabPlayerShellScreen extends StatelessWidget {
  const LabPlayerShellScreen({
    super.key,
    this.scenario,
    this.publishedPackage,
  });

  final LabScenarioDefinition? scenario;
  final LabPackage? publishedPackage;

  LabScenarioDefinition get _scenario =>
      scenario ?? LabScenarioCatalog.confinedSpaceH2s;

  @override
  Widget build(BuildContext context) {
    final selectedScenario = _scenario;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? const Color(0xFFF4F7FB) : const Color(0xFF18243A);
    final muted = dark ? const Color(0xFFA5B1C4) : const Color(0xFF667083);

    return StudentGlassScaffold(
      backgroundColor: dark ? const Color(0xFF0A111D) : const Color(0xFFF4F8FF),
      appBar: AppBar(title: const Text('Choose LAB Mode')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                children: [
                  StudentGlassSurface(
                    padding: const EdgeInsets.all(20),
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scenario',
                          style: TextStyle(
                            color: muted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          selectedScenario.title,
                          key: const ValueKey('lab-selected-scenario-title'),
                          style: TextStyle(
                            color: text,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  StudentGlassSurface(
                    padding: const EdgeInsets.all(23),
                    borderRadius: BorderRadius.circular(23),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose how you want to practise',
                          style: TextStyle(
                            color: text,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          'The story is the same in every mode. Only the amount '
                          'of guidance changes.',
                          style: TextStyle(color: muted, height: 1.45),
                        ),
                        const SizedBox(height: 20),
                        _LabModeCard(
                          key: const ValueKey('lab-mode-guided'),
                          title: 'Guided LAB',
                          description:
                              'Learn while you practise. Feedback may be provided during the scenario.',
                          icon: Icons.explore_rounded,
                          onTap: () => _openMode(
                            context,
                            LabMode.guided,
                            selectedScenario,
                          ),
                        ),
                        const SizedBox(height: 13),
                        _LabModeCard(
                          key: const ValueKey('lab-mode-professional'),
                          title: 'Professional LAB',
                          description:
                              'Make decisions with limited guidance. Detailed feedback comes later.',
                          icon: Icons.engineering_rounded,
                          onTap: () => _openMode(
                            context,
                            LabMode.professional,
                            selectedScenario,
                          ),
                        ),
                        const SizedBox(height: 13),
                        _LabModeCard(
                          key: const ValueKey('lab-mode-assessment'),
                          title: 'Assessment LAB',
                          description:
                              'Complete the scenario independently. Feedback is provided after completion.',
                          icon: Icons.fact_check_rounded,
                          onTap: () => _openMode(
                            context,
                            LabMode.assessment,
                            selectedScenario,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openMode(
    BuildContext context,
    LabMode mode,
    LabScenarioDefinition selectedScenario,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            LabReferencePlayerScreen(
              mode: mode,
              scenario: selectedScenario,
              publishedPackage: publishedPackage,
            ),
      ),
    );
  }
}

class _LabModeCard extends StatelessWidget {
  const _LabModeCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? const Color(0xFFF4F7FB) : const Color(0xFF18243A);
    final muted = dark ? const Color(0xFFA5B1C4) : const Color(0xFF667083);

    return SizedBox(
      width: double.infinity,
      child: StudentGlassSurface(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 29,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: text,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          description,
                          style: TextStyle(color: muted, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.chevron_right_rounded, color: muted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
