import 'package:flutter/material.dart';

import 'flashcards_catalog_view.dart';

class FlashcardsScreen extends StatelessWidget {
  const FlashcardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FlashcardsCatalogView(isDarkMode: false);
  }
}
