import 'dart:ui';

import 'package:flutter/material.dart';

import '../../services/settings/theme_mode_service.dart';

class StudentGlassPalette {
  const StudentGlassPalette({
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.primaryOrb,
    required this.secondaryOrb,
    required this.surface,
    required this.surfaceStrong,
    required this.border,
    required this.highlight,
    required this.shadow,
    required this.navigationSurface,
  });

  final Color backgroundTop;
  final Color backgroundBottom;
  final Color primaryOrb;
  final Color secondaryOrb;
  final Color surface;
  final Color surfaceStrong;
  final Color border;
  final Color highlight;
  final Color shadow;
  final Color navigationSurface;

  static const light = StudentGlassPalette(
    backgroundTop: Color(0xFFF4F8FF),
    backgroundBottom: Color(0xFFF8F4FF),
    primaryOrb: Color(0x4D4F8BFF),
    secondaryOrb: Color(0x3DA855F7),
    surface: Color(0xA8FFFFFF),
    surfaceStrong: Color(0xD9FFFFFF),
    border: Color(0x99FFFFFF),
    highlight: Color(0xCCFFFFFF),
    shadow: Color(0x1A163B73),
    navigationSurface: Color(0xCFFFFFFF),
  );

  static const dark = StudentGlassPalette(
    backgroundTop: Color(0xFF07101B),
    backgroundBottom: Color(0xFF130D22),
    primaryOrb: Color(0x593B82F6),
    secondaryOrb: Color(0x4D9333EA),
    surface: Color(0x8A14233B),
    surfaceStrong: Color(0xB31A2B46),
    border: Color(0x4DFFFFFF),
    highlight: Color(0x26FFFFFF),
    shadow: Color(0x66000000),
    navigationSurface: Color(0xC7132035),
  );

  static StudentGlassPalette of(BuildContext context) {
    final serviceDark = ThemeModeService.isDarkMode.value;
    final themeDark = Theme.of(context).brightness == Brightness.dark;
    return serviceDark || themeDark ? dark : light;
  }
}

class StudentGlassBackdrop extends StatelessWidget {
  const StudentGlassBackdrop({
    super.key,
    required this.child,
    this.primaryOrbAlignment = const Alignment(1.15, -1.15),
    this.secondaryOrbAlignment = const Alignment(-1.2, 0.95),
  });

  final Widget child;
  final Alignment primaryOrbAlignment;
  final Alignment secondaryOrbAlignment;

  @override
  Widget build(BuildContext context) {
    final palette = StudentGlassPalette.of(context);

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  palette.backgroundTop,
                  Color.lerp(
                    palette.backgroundTop,
                    palette.backgroundBottom,
                    0.48,
                  )!,
                  palette.backgroundBottom,
                ],
                stops: const [0, 0.52, 1],
              ),
            ),
          ),
          Align(
            alignment: primaryOrbAlignment,
            child: const _GlassOrb(primary: true),
          ),
          Align(
            alignment: secondaryOrbAlignment,
            child: const _GlassOrb(primary: false),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlassOrb extends StatelessWidget {
  const _GlassOrb({required this.primary});

  final bool primary;

  @override
  Widget build(BuildContext context) {
    final palette = StudentGlassPalette.of(context);
    final color = primary ? palette.primaryOrb : palette.secondaryOrb;

    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 56, sigmaY: 56),
        child: Container(
          width: primary ? 330 : 290,
          height: primary ? 330 : 290,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class StudentGlassSurface extends StatelessWidget {
  const StudentGlassSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.blurSigma = 18,
    this.tint,
    this.borderColor,
    this.shadowColor,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry borderRadius;
  final double blurSigma;
  final Color? tint;
  final Color? borderColor;
  final Color? shadowColor;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final palette = StudentGlassPalette.of(context);
    final resolvedRadius = borderRadius.resolve(Directionality.of(context));

    Widget glass = ClipRRect(
      borderRadius: resolvedRadius,
      clipBehavior: clipBehavior,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (tint ?? palette.surfaceStrong),
                Color.lerp(
                  tint ?? palette.surfaceStrong,
                  palette.surface,
                  0.72,
                )!,
              ],
            ),
            borderRadius: resolvedRadius,
            border: Border.all(
              color: borderColor ?? palette.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor ?? palette.shadow,
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: palette.highlight,
                blurRadius: 0,
                spreadRadius: -0.5,
                offset: const Offset(0, -0.5),
              ),
            ],
          ),
          child: padding == null
              ? child
              : Padding(padding: padding!, child: child),
        ),
      ),
    );

    if (margin != null) {
      glass = Padding(padding: margin!, child: glass);
    }

    return glass;
  }
}

class StudentGlassCard extends StatelessWidget {
  const StudentGlassCard({
    super.key,
    this.child,
    this.color,
    this.shadowColor,
    this.surfaceTintColor,
    this.elevation,
    this.shape,
    this.borderOnForeground = true,
    this.margin,
    this.clipBehavior = Clip.antiAlias,
    this.semanticContainer = true,
  });

  final Widget? child;
  final Color? color;
  final Color? shadowColor;
  final Color? surfaceTintColor;
  final double? elevation;
  final ShapeBorder? shape;
  final bool borderOnForeground;
  final EdgeInsetsGeometry? margin;
  final Clip clipBehavior;
  final bool semanticContainer;

  @override
  Widget build(BuildContext context) {
    BorderRadiusGeometry radius = BorderRadius.circular(22);
    final currentShape = shape;
    if (currentShape is RoundedRectangleBorder) {
      radius = currentShape.borderRadius;
    }

    return Semantics(
      container: semanticContainer,
      child: StudentGlassSurface(
        margin: margin,
        borderRadius: radius,
        tint: color,
        clipBehavior: clipBehavior,
        shadowColor: shadowColor,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

class StudentGlassScaffold extends StatelessWidget {
  const StudentGlassScaffold({
    super.key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.floatingActionButtonAnimator,
    this.persistentFooterButtons,
    this.persistentFooterAlignment = AlignmentDirectional.centerEnd,
    this.drawer,
    this.onDrawerChanged,
    this.endDrawer,
    this.onEndDrawerChanged,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.primary = true,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.drawerScrimColor,
    this.drawerEdgeDragWidth,
    this.drawerEnableOpenDragGesture = true,
    this.endDrawerEnableOpenDragGesture = true,
    this.restorationId,
  });

  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final FloatingActionButtonAnimator? floatingActionButtonAnimator;
  final List<Widget>? persistentFooterButtons;
  final AlignmentDirectional persistentFooterAlignment;
  final Widget? drawer;
  final DrawerCallback? onDrawerChanged;
  final Widget? endDrawer;
  final DrawerCallback? onEndDrawerChanged;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  final bool primary;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final Color? drawerScrimColor;
  final double? drawerEdgeDragWidth;
  final bool drawerEnableOpenDragGesture;
  final bool endDrawerEnableOpenDragGesture;
  final String? restorationId;

  @override
  Widget build(BuildContext context) {
    return StudentGlassBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        floatingActionButtonAnimator: floatingActionButtonAnimator,
        persistentFooterButtons: persistentFooterButtons,
        persistentFooterAlignment: persistentFooterAlignment,
        drawer: drawer,
        onDrawerChanged: onDrawerChanged,
        endDrawer: endDrawer,
        onEndDrawerChanged: onEndDrawerChanged,
        bottomNavigationBar: bottomNavigationBar,
        bottomSheet: bottomSheet,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        primary: primary,
        extendBody: extendBody,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        drawerScrimColor: drawerScrimColor,
        drawerEdgeDragWidth: drawerEdgeDragWidth,
        drawerEnableOpenDragGesture: drawerEnableOpenDragGesture,
        endDrawerEnableOpenDragGesture: endDrawerEnableOpenDragGesture,
        restorationId: restorationId,
      ),
    );
  }
}
