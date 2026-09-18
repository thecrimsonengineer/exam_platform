import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),

    scaffoldBackgroundColor: AppColors.background,

    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
    ),

    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
  );

  /// Dark theme used by the learner shell and learner route wrappers.
  ///
  /// BottomNavigationScreen applies this theme to the learner workspace.
  /// Pushed Exam Readiness routes explicitly preserve the active learner
  /// theme so setup, readiness details and adaptive plans stay consistent.
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ).copyWith(
          surface: const Color(0xFF111B2C),
          onSurface: const Color(0xFFF4F7FB),
          outline: const Color(0xFF314159),
          outlineVariant: const Color(0xFF25344A),
        ),
    scaffoldBackgroundColor: const Color(0xFF0A111D),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: Color(0xFF0A111D),
      foregroundColor: Color(0xFFF4F7FB),
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF111B2C),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: const Color(0xFF101A2A),
      indicatorColor: AppColors.primary.withValues(alpha: 0.24),
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          color: selected ? const Color(0xFFF4F7FB) : const Color(0xFFA5B1C4),
          fontSize: 11,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? const Color(0xFF7FB3FF) : const Color(0xFFA5B1C4),
        );
      }),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF25344A),
      thickness: 1,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF111B2C),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF111B2C),
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: Color(0xFF111B2C),
      dragHandleColor: Color(0xFF66758A),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF1A2740),
      contentTextStyle: TextStyle(color: Color(0xFFF4F7FB)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return const Color(0xFFB5C0D0);
      }),
      trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary;
        return const Color(0xFF334158);
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF162238),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
  );


  static final ThemeData studentGlassLightTheme = _studentGlassTheme(
    lightTheme,
    brightness: Brightness.light,
  );

  static final ThemeData studentGlassDarkTheme = _studentGlassTheme(
    darkTheme,
    brightness: Brightness.dark,
  );

  static ThemeData _studentGlassTheme(
    ThemeData base, {
    required Brightness brightness,
  }) {
    final dark = brightness == Brightness.dark;
    final surface = dark
        ? const Color(0x9914233B)
        : const Color(0xBFFFFFFF);
    final strongSurface = dark
        ? const Color(0xC21A2B46)
        : const Color(0xE6FFFFFF);
    final border = dark
        ? const Color(0x42FFFFFF)
        : const Color(0xA6FFFFFF);
    final baseText = dark
        ? const Color(0xFFF4F7FB)
        : const Color(0xFF18243A);

    return base.copyWith(
      scaffoldBackgroundColor:
          dark ? const Color(0xFF07101B) : const Color(0xFFF4F8FF),
      canvasColor: Colors.transparent,
      appBarTheme: base.appBarTheme.copyWith(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: strongSurface,
        foregroundColor: baseText,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: base.cardTheme.margin,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: dark
            ? const Color(0xD9132035)
            : const Color(0xE6FFFFFF),
        indicatorColor: base.colorScheme.primary.withValues(alpha: 0.18),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: base.navigationBarTheme.labelTextStyle,
        iconTheme: base.navigationBarTheme.iconTheme,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: base.colorScheme.primary.withValues(alpha: 0.82),
            width: 1.4,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: strongSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: border),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: strongSurface,
        modalBackgroundColor: strongSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: strongSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: border),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surface,
        selectedColor: base.colorScheme.primary.withValues(alpha: 0.16),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: dark
            ? const Color(0x33FFFFFF)
            : const Color(0x4D6F86A8),
        thickness: 1,
      ),
    );
  }
}
