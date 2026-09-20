import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';
import 'package:exam_platform/widgets/motion/csp11_status_reveal.dart';

import '../../app/app_colors.dart';

class FlashcardsScreen extends StatelessWidget {
  const FlashcardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StudentGlassScaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F7FB),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Flashcards',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Csp11StatusReveal(
          kind: Csp11StatusKind.empty,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: StudentGlassSurface(
                  padding: const EdgeInsets.all(28),
                  borderRadius: BorderRadius.circular(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.style_rounded,
                          color: AppColors.primary,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'CSP11 Flashcards',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF172033),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'No flashcard decks are published yet. This learner screen is ready for the flashcard content and review engine to be added in the next flashcard phase.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF667083),
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
