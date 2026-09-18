import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';

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
                      'L1 provides the deterministic player route and runtime foundation. A decision can be changed before confirmation. Once confirmed, the authored consequence is applied and the choice is irreversible for that attempt.',
                      style: TextStyle(color: muted, height: 1.5),
                    ),
                    const SizedBox(height: 18),
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text('Guided LAB')),
                        Chip(label: Text('Professional LAB')),
                        Chip(label: Text('Assessment LAB')),
                      ],
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
}
