import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';

import 'lab_player_shell_screen.dart';

class LabLibraryScreen extends StatelessWidget {
  const LabLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? const Color(0xFFF4F7FB) : const Color(0xFF18243A);
    final muted = dark ? const Color(0xFFA5B1C4) : const Color(0xFF667083);

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
          padding: const EdgeInsets.all(20),
          children: [
            StudentGlassSurface(
              padding: const EdgeInsets.all(24),
              borderRadius: BorderRadius.circular(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.science_rounded,
                    size: 42,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Decision LABs',
                    style: TextStyle(
                      color: text,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Deterministic safety simulations where every confirmed choice creates an authored consequence before the Story Gate selects what happens next.',
                    style: TextStyle(color: muted, height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      Chip(label: Text('4 options')),
                      Chip(label: Text('1 BEST')),
                      Chip(label: Text('Irreversible after confirm')),
                      Chip(label: Text('No runtime AI branching')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            StudentGlassSurface(
              padding: const EdgeInsets.all(22),
              borderRadius: BorderRadius.circular(22),
              child: Column(
                children: [
                  Icon(
                    Icons.route_rounded,
                    size: 34,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'LAB player shell ready',
                    style: TextStyle(
                      color: text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Published LAB packages will appear here after LAB1000 validation and publishing are implemented in L2.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted, height: 1.45),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    key: const ValueKey('lab-open-player-shell'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LabPlayerShellScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('OPEN PLAYER SHELL'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
