import 'package:flutter/material.dart';

import 'flashcards_catalog_view.dart';

class DarkFlashcardsScreen extends StatelessWidget {
  const DarkFlashcardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FlashcardsCatalogView(isDarkMode: true);
  }
}
