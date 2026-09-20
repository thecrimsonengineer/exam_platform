import 'package:flutter/material.dart';

import '../../features/flashcards/learner/flashcard_learner_experience_controller.dart';
import 'flashcards_screen.dart';

class DarkFlashcardsScreen extends StatelessWidget {
  const DarkFlashcardsScreen({
    super.key,
    this.controller,
  });

  final FlashcardLearnerExperienceController? controller;

  @override
  Widget build(BuildContext context) {
    return FlashcardsScreen(controller: controller);
  }
}
