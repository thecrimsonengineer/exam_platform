import 'package:flutter/material.dart';

/// P6.2 dark palette for the competency Topic accordion screen only.
///
/// It intentionally mirrors the StudyColors API so the dark renderer can stay
/// behaviorally identical to the light renderer. Deeper Subtopic reading pages
/// continue to use the existing light StudyColors palette in this phase.
class DarkStudyColors {
  DarkStudyColors._();

  static const Color primary = Color(0xFF6EA8FF);
  static const Color primaryDark = Color(0xFF102A56);
  static const Color primaryLight = Color(0xFF14243B);

  static const Color accent = Color(0xFF8BB8FF);
  static const Color accentLight = Color(0xFF152A46);

  static const Color background = Color(0xFF0A111D);
  static const Color surface = Color(0xFF111B2C);
  static const Color surfaceSoft = Color(0xFF162238);
  static const Color surfaceMuted = Color(0xFF1B2940);

  static const Color textPrimary = Color(0xFFF4F7FB);
  static const Color textSecondary = Color(0xFFA5B1C4);
  static const Color textMuted = Color(0xFF7E8CA3);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color border = Color(0xFF25344A);
  static const Color borderStrong = Color(0xFF314159);

  static const Color success = Color(0xFF4CC38A);
  static const Color successLight = Color(0xFF10291F);

  static const Color warning = Color(0xFFF0B44D);
  static const Color warningLight = Color(0xFF2A2113);

  static const Color danger = Color(0xFFFF7A7A);
  static const Color dangerLight = Color(0xFF2B171C);

  static const Color info = Color(0xFF78AEF3);
  static const Color infoLight = Color(0xFF14243B);

  static const Color examTip = Color(0xFFB59AF6);
  static const Color examTipLight = Color(0xFF1D1934);

  static const Color remember = Color(0xFF62D4D4);
  static const Color rememberLight = Color(0xFF102925);

  static const Color caseStudy = Color(0xFFF0A45A);
  static const Color caseStudyLight = Color(0xFF2A2015);

  static const Color reference = Color(0xFFA5B1C4);
  static const Color referenceLight = Color(0xFF162238);

  static const Color progressTrack = Color(0xFF25344A);
  static const Color progressFill = Color(0xFF6EA8FF);

  static const Color scrim = Color(0x99000000);
}
