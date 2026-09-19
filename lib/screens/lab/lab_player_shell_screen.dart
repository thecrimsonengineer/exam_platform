import 'package:flutter/material.dart';

import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/theme/glass/student_glass.dart';

import 'lab_reference_player_screen.dart';
import 'lab_scenario_catalog.dart';

class LabPlayerShellScreen extends StatelessWidget {
  const LabPlayerShellScreen({super.key, this.scenario});

  final LabScenarioDefinition? scenario;

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
                    padding: const EdgeInsets.all(24),
                    borderRadius: BorderRadius.circular(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected scenario',
                          style: TextStyle(
                            color: muted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          selectedScenario.title,
                          key: const ValueKey('lab-selected-scenario-title'),
                          style: TextStyle(
                            color: text,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          selectedScenario.summary,
                          style: TextStyle(color: muted, height: 1.45),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  StudentGlassSurface(
                    padding: const EdgeInsets.all(24),
                    borderRadius: BorderRadius.circular(24),
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
                        const SizedBox(height: 8),
                        Text(
                          'The scenario is the same in every mode. What changes '
                          'is how much guidance you receive while making decisions.',
                          style: TextStyle(color: muted, height: 1.5),
                        ),
                        const SizedBox(height: 22),
                        _LabModeCard(
                          key: const ValueKey('lab-mode-guided'),
                          title: 'Guided LAB',
                          bestFor: 'Best for learning',
                          description:
                              'Get more guidance and decision feedback while you progress.',
                          icon: Icons.explore_rounded,
                          onTap: () => _openMode(
                            context,
                            LabMode.guided,
                            selectedScenario,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _LabModeCard(
                          key: const ValueKey('lab-mode-professional'),
                          title: 'Professional LAB',
                          bestFor: 'Best for realistic practice',
                          description:
                              'Make decisions with limited guidance and review the analysis after the LAB.',
                          icon: Icons.engineering_rounded,
                          onTap: () => _openMode(
                            context,
                            LabMode.professional,
                            selectedScenario,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _LabModeCard(
                          key: const ValueKey('lab-mode-assessment'),
                          title: 'Assessment LAB',
                          bestFor: 'Best for testing yourself',
                          description:
                              'Complete the scenario without coaching during the attempt.',
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
        builder: (_) => LabReferencePlayerScreen(
          mode: mode,
          assetPath: selectedScenario.assetPath,
        ),
      ),
    );
  }
}

class _LabModeCard extends StatelessWidget {
  const _LabModeCard({
    super.key,
    required this.title,
    required this.bestFor,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String bestFor;
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
                        Text(
                          description,
                          style: TextStyle(color: muted, height: 1.35),
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
