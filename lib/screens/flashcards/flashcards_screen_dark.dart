import 'package:flutter/material.dart';

import '../../app/app_colors.dart';

class DarkFlashcardsScreen extends StatelessWidget {
  const DarkFlashcardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A111D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A111D),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Flashcards',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: const Color(0xFF111B2C),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF25344A)),
                ),
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
                        color: Color(0xFFF4F7FB),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No flashcard decks are published yet. This learner screen is ready for the flashcard content and review engine to be added in the next flashcard phase.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFA5B1C4),
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
    );
  }
}
