import 'package:flutter/material.dart';

import '../../../../../services/settings/theme_mode_service.dart';

class QuizColors {
  QuizColors._();

  static bool get _dark => ThemeModeService.isDarkMode.value;

  // BRAND / PRIMARY
  static const Color navy = Color(0xFF172554);
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);

  // PURPLE ACCENT
  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleDark = Color(0xFF6D28D9);
  static const Color violet = Color(0xFF8B5CF6);

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, primary, purple],
  );

  static LinearGradient get pageGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: _dark
        ? const [Color(0xB30A111D), Color(0xAD0D1624), Color(0xB3111827)]
        : const [Color(0xBFF3F6FC), Color(0xB8F7F9FC), Color(0xB8F8F7FC)],
    stops: const [0.0, 0.55, 1.0],
  );

  static LinearGradient get selectedGradient => LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: _dark
        ? const [Color(0xFF14243B), Color(0xFF1D1934)]
        : const [Color(0xFFEFF6FF), Color(0xFFF5F3FF)],
  );

  // QUESTION CARD
  static LinearGradient get questionGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: _dark
        ? const [Color(0xB3111B2C), Color(0xA614243B), Color(0x9E1D1934)]
        : const [Color(0xD9FFFFFF), Color(0xCFF8FAFF), Color(0xC7FAF8FF)],
    stops: const [0.0, 0.58, 1.0],
  );

  static Color get questionAccent => _dark ? const Color(0xFF60A5FA) : primary;

  static Color get questionLabel =>
      _dark ? const Color(0xFF60A5FA) : textSecondary;

  static Color get questionMuted => _dark ? const Color(0xFF9AA8BC) : textMuted;

  // QUESTION / SURFACE
  static Color get background =>
      _dark ? const Color(0xB307101B) : const Color(0xBFF4F8FF);
  static Color get surface =>
      _dark ? const Color(0x8F14233B) : const Color(0xBFFFFFFF);
  static Color get surfaceAlt =>
      _dark ? const Color(0x801A2B46) : const Color(0x99FFFFFF);
  static Color get border =>
      _dark ? const Color(0x42FFFFFF) : const Color(0x8FFFFFFF);
  static Color get borderStrong =>
      _dark ? const Color(0x59FFFFFF) : const Color(0xB3FFFFFF);

  // TEXT
  static Color get textPrimary =>
      _dark ? const Color(0xFFF4F7FB) : const Color(0xFF172033);
  static Color get textSecondary =>
      _dark ? const Color(0xFFA5B1C4) : const Color(0xFF64748B);
  static Color get textMuted =>
      _dark ? const Color(0xFF7E8CA3) : const Color(0xFF94A3B8);

  // ANSWER STATES
  static const Color selected = Color(0xFF2563EB);
  static Color get selectedBackground =>
      _dark ? const Color(0xFF14243B) : const Color(0xFFEFF6FF);

  static const Color correct = Color(0xFF15803D);
  static Color get correctBackground =>
      _dark ? const Color(0xFF10291F) : const Color(0xFFF0FDF4);

  static const Color incorrect = Color(0xFFDC2626);
  static Color get incorrectBackground =>
      _dark ? const Color(0xFF2B171C) : const Color(0xFFFEF2F2);

  // FEEDBACK
  static const Color explanation = Color(0xFF2563EB);
  static Color get explanationBackground =>
      _dark ? const Color(0xFF14243B) : const Color(0xFFEFF6FF);

  static const Color reference = Color(0xFF475569);
  static Color get referenceBackground =>
      _dark ? const Color(0xFF162238) : const Color(0xFFF8FAFC);

  static const Color examTip = Color(0xFFD97706);
  static Color get examTipBackground =>
      _dark ? const Color(0xFF2A2113) : const Color(0xFFFFFBEB);

  static const Color keyPoint = Color(0xFF059669);
  static Color get keyPointBackground =>
      _dark ? const Color(0xFF102925) : const Color(0xFFECFDF5);

  static const Color remember = Color(0xFF7C3AED);
  static Color get rememberBackground =>
      _dark ? const Color(0xFF1D1934) : const Color(0xFFF5F3FF);

  static const Color warning = Color(0xFFEA580C);
  static Color get warningBackground =>
      _dark ? const Color(0xFF2A2015) : const Color(0xFFFFF7ED);
}
