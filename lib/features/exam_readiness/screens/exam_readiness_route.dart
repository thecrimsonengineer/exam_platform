import 'package:flutter/material.dart';

import '../../../app/theme.dart';

MaterialPageRoute<T> examReadinessRoute<T>({
  required Widget child,
  required bool isDarkMode,
}) {
  return MaterialPageRoute<T>(
    builder: (_) => Theme(
      data: isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      child: child,
    ),
  );
}
