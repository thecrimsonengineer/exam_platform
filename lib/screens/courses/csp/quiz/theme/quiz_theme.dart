import 'package:flutter/material.dart';

import 'quiz_colors.dart';
import 'quiz_spacing.dart';

class QuizTheme {
  QuizTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: QuizColors.background,

      colorScheme: ColorScheme.fromSeed(
        seedColor: QuizColors.primary,
        brightness: Brightness.light,
      ),

      cardTheme: CardThemeData(
        color: QuizColors.surface,
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            QuizSpacing.cardRadius,
          ),
          side: const BorderSide(
            color: QuizColors.border,
          ),
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: QuizColors.surface,
        foregroundColor: QuizColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(
            double.infinity,
            QuizSpacing.buttonHeight,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}