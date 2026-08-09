import 'package:flutter/material.dart';

class QuizColors {
  QuizColors._();

  // ==========================================================
  // BRAND / PRIMARY
  // ==========================================================

  static const Color navy = Color(0xFF172554);
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);

  // ==========================================================
  // PURPLE ACCENT
  // ==========================================================

  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleDark = Color(0xFF6D28D9);
  static const Color violet = Color(0xFF8B5CF6);

  // ==========================================================
  // GRADIENTS
  // ==========================================================

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      navy,
      primary,
      purple,
    ],
  );

  static const LinearGradient selectedGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFEFF6FF),
      Color(0xFFF5F3FF),
    ],
  );

  // ==========================================================
  // QUESTION / SURFACE
  // ==========================================================

  static const Color background = Color(0xFFF7F8FC);
  static const Color surface = Colors.white;
  static const Color surfaceAlt = Color(0xFFF1F5F9);

  static const Color border = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);

  // ==========================================================
  // TEXT
  // ==========================================================

  static const Color textPrimary = Color(0xFF172033);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // ==========================================================
  // ANSWER STATES
  // ==========================================================

  static const Color selected = Color(0xFF2563EB);
  static const Color selectedBackground = Color(0xFFEFF6FF);

  static const Color correct = Color(0xFF15803D);
  static const Color correctBackground = Color(0xFFF0FDF4);

  static const Color incorrect = Color(0xFFDC2626);
  static const Color incorrectBackground = Color(0xFFFEF2F2);

  // ==========================================================
  // FEEDBACK
  // ==========================================================

  static const Color explanation = Color(0xFF2563EB);
  static const Color explanationBackground = Color(0xFFEFF6FF);

  static const Color reference = Color(0xFF475569);
  static const Color referenceBackground = Color(0xFFF8FAFC);

  static const Color examTip = Color(0xFFD97706);
  static const Color examTipBackground = Color(0xFFFFFBEB);

  static const Color keyPoint = Color(0xFF059669);
  static const Color keyPointBackground = Color(0xFFECFDF5);

  static const Color remember = Color(0xFF7C3AED);
  static const Color rememberBackground = Color(0xFFF5F3FF);

  static const Color warning = Color(0xFFEA580C);
  static const Color warningBackground = Color(0xFFFFF7ED);
}