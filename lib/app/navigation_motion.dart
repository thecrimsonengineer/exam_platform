import 'package:flutter/material.dart';

/// Applies one lightweight transition policy to Material routes app-wide.
class AppNavigationMotion {
  AppNavigationMotion._();

  static ThemeData apply(ThemeData theme, {required bool enabled}) {
    const enabledBuilder = _SmoothPageTransitionsBuilder();
    const disabledBuilder = _NoPageTransitionsBuilder();
    final builder = enabled ? enabledBuilder : disabledBuilder;

    return theme.copyWith(
      pageTransitionsTheme: PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: builder,
          TargetPlatform.iOS: builder,
          TargetPlatform.macOS: builder,
          TargetPlatform.windows: builder,
          TargetPlatform.linux: builder,
          TargetPlatform.fuchsia: builder,
        },
      ),
    );
  }
}

class _SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const _SmoothPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery?.disableAnimations ?? false) {
      return child;
    }

    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0.018, 0),
      end: Offset.zero,
    ).animate(curvedAnimation);
    final fadeAnimation = Tween<double>(
      begin: 0.92,
      end: 1,
    ).animate(curvedAnimation);

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(position: slideAnimation, child: child),
    );
  }
}

class _NoPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
