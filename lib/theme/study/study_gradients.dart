import 'package:flutter/material.dart';

import 'study_colors.dart';

class StudyGradients {
  StudyGradients._();

  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [StudyColors.primaryDark, StudyColors.primary],
  );

  static const LinearGradient heroSoft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [StudyColors.primary, StudyColors.accent],
  );

  static const LinearGradient progress = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [StudyColors.primary, StudyColors.accent],
  );
}
