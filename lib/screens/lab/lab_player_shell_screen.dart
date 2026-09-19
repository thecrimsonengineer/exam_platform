import 'package:flutter/material.dart';

import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/theme/glass/student_glass.dart';

import 'lab_reference_player_screen.dart';

class LabPlayerShellScreen extends StatelessWidget {
  const LabPlayerShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? const Color(0xFFF4F7FB) : const Color(0xFF18243A);
    final muted = dark ? const Color(0xFFA5B1C4) : const Color(0xFF667083);

    return StudentGlassScaffold(
      backgroundColor: dark ? const Color(0xFF0A111D) : const Color(0xFFF4F8FF),
      appBar: AppBar(title: const Text('LAB Player')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: StudentGlassSurface(
                padding: const EdgeInsets.all(26),
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scene → Decision → Consequence → Story Gate',
                      style: TextStyle(
                        color: text,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Choose how you want to experience the Safety Decision LAB. '
                      'Each mode opens the same deterministic authored scenario with '
                      'a different learning context.',
                      style: TextStyle(color: muted, height: 1.5),
                    ),
                    const SizedBox(height: 22),
                    _LabModeCard(
                      key: const ValueKey('lab-mode-guided'),
                      title: 'Guided LAB',
                      description:
                          'Learn through the scenario with decision feedback as you progress.',
                      icon: Icons.explore_rounded,
                      onTap: () => _openMode(context, LabMode.guided),
                    ),
                    const SizedBox(height: 14),
                    _LabModeCard(
                      key: const ValueKey('lab-mode-professional'),
                      title: 'Professional LAB',
                      description:
                          'Work through the scenario with reduced guidance and professional judgement.',
                      icon: Icons.engineering_rounded,
                      onTap: () => _openMode(context, LabMode.professional),
                    ),
                    const SizedBox(height: 14),
                    _LabModeCard(
                      key: const ValueKey('lab-mode-assessment'),
                      title: 'Assessment LAB',
                      description:
                          'Complete the scenario as an assessment and review your decisions at the end.',
                      icon: Icons.fact_check_rounded,
                      onTap: () => _openMode(context, LabMode.assessment),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openMode(BuildContext context, LabMode mode) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LabReferencePlayerScreen(mode: mode),
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
