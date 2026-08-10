import 'package:flutter/material.dart';

import 'study_colors.dart';

class StudyTypography {
  StudyTypography._();

  static const TextStyle eyebrow = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: StudyColors.textSecondary,
  );

  static const TextStyle heroTitle = TextStyle(
    fontSize: 36,
    height: 1.12,
    fontWeight: FontWeight.w800,
    color: StudyColors.textPrimary,
  );

  static const TextStyle pageTitle = TextStyle(
    fontSize: 30,
    height: 1.2,
    fontWeight: FontWeight.w800,
    color: StudyColors.textPrimary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 22,
    height: 1.25,
    fontWeight: FontWeight.w700,
    color: StudyColors.textPrimary,
  );

  static const TextStyle subSectionTitle = TextStyle(
    fontSize: 18,
    height: 1.3,
    fontWeight: FontWeight.w700,
    color: StudyColors.textPrimary,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    height: 1.3,
    fontWeight: FontWeight.w700,
    color: StudyColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 17,
    height: 1.7,
    fontWeight: FontWeight.w400,
    color: StudyColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    height: 1.65,
    fontWeight: FontWeight.w400,
    color: StudyColors.textPrimary,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 14,
    height: 1.55,
    color: StudyColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    height: 1.4,
    color: StudyColors.textMuted,
  );

  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: StudyColors.textSecondary,
  );

  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: StudyColors.textOnPrimary,
  );

  static const TextStyle blockTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
    color: StudyColors.textPrimary,
  );
}
