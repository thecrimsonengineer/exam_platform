import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../navigation/csp11_route.dart';
import '../../theme/motion/csp11_motion.dart';
import 'package:exam_platform/theme/glass/student_glass.dart';
import '../../services/haptics/csp11_haptic_service.dart';
import '../../services/settings/theme_mode_service.dart';
import '../../services/learning_activity_tracker.dart';
import '../../services/progress_overview_snapshot_service.dart';
import '../../services/quiz_service.dart';
import '../courses/csp/csp_study_hub_screen.dart';
import '../courses/csp/csp_study_hub_screen_dark.dart';
import '../flashcards/flashcards_screen.dart';
import '../flashcards/flashcards_screen_dark.dart';
import '../home/home_screen.dart';
import '../home/home_screen_dark.dart';
import '../lab/lab_library_screen.dart';
import '../practice/practice_hub_screen.dart';
import '../settings/settings_route.dart';

class BottomNavigationScreen extends StatefulWidget {
  const BottomNavigationScreen({super.key});

  @override
  State<BottomNavigationScreen> createState() => _BottomNavigationScreenState();
}

class _BottomNavigationScreenState extends State<BottomNavigationScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  int _tabDirection = 1;

  late final AnimationController _tabMotionController;
  late final Animation<double> _tabMotion;

  final Map<int, Widget> _lightScreens = <int, Widget>{};
  final Map<int, Widget> _darkScreens = <int, Widget>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabMotionController = AnimationController(
      vsync: this,
      duration: Csp11MotionDuration.quick,
      value: 1,
    );
    _tabMotion = CurvedAnimation(
      parent: _tabMotionController,
      curve: Csp11MotionCurve.enter,
    );
    _ensureScreenBuilt(0, ThemeModeService.isDarkMode.value);
    LearningActivityTracker.instance.start();
    const ProgressOverviewSnapshotService().prewarm();
    unawaited(_prewarmQuizCatalog());
  }

  Future<void> _prewarmQuizCatalog() async {
    try {
      await QuizService.shared.initialize();
    } catch (_) {
      // Practice screens retain their normal retry/error path.
    }
  }

  Future<void> _openSettings() async {
    await Navigator.of(
      context,
    ).push(Csp11Route.forward<void>(child: const SettingsRoute()));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      LearningActivityTracker.instance.resume();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      LearningActivityTracker.instance.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    LearningActivityTracker.instance.dispose();
    _tabMotionController.dispose();
    super.dispose();
  }

  Map<int, Widget> _screensFor(bool isDarkMode) =>
      isDarkMode ? _darkScreens : _lightScreens;

  Widget _buildScreen(int index, bool isDarkMode) {
    if (isDarkMode) {
      switch (index) {
        case 0:
          return DarkHomeScreen(
            onOpenStudy: () => _selectTab(1),
            onOpenFlashcards: () => _selectTab(4),
            onOpenSettings: _openSettings,
          );
        case 1:
          return const DarkCspStudyHubScreen();
        case 2:
          return const PracticeHubScreen();
        case 3:
          return const LabLibraryScreen();
        case 4:
          return const DarkFlashcardsScreen();
        default:
          return const SizedBox.shrink();
      }
    }

    switch (index) {
      case 0:
        return HomeScreen(
          onOpenStudy: () => _selectTab(1),
          onOpenFlashcards: () => _selectTab(4),
          onOpenSettings: _openSettings,
        );
      case 1:
        return const CspStudyHubScreen();
      case 2:
        return const PracticeHubScreen();
      case 3:
        return const LabLibraryScreen();
      case 4:
        return const FlashcardsScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  void _ensureScreenBuilt(int index, bool isDarkMode) {
    final screens = _screensFor(isDarkMode);
    screens[index] ??= _buildScreen(index, isDarkMode);
  }

  void _selectTab(int index) {
    if (!mounted || _selectedIndex == index) {
      return;
    }

    final isDarkMode = ThemeModeService.isDarkMode.value;
    final previousIndex = _selectedIndex;

    setState(() {
      _ensureScreenBuilt(index, isDarkMode);
      _tabDirection = index > previousIndex ? 1 : -1;
      _selectedIndex = index;
    });

    if (Csp11MotionPreferences.reduced(context)) {
      _tabMotionController.value = 1;
    } else {
      unawaited(_tabMotionController.forward(from: 0));
    }
  }

  void _selectBottomNavigationTab(int index) {
    if (_selectedIndex == index) {
      return;
    }

    unawaited(Csp11Haptics.navigation());
    _selectTab(index);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeModeService.isDarkMode,
      builder: (context, isDarkMode, _) {
        _ensureScreenBuilt(_selectedIndex, isDarkMode);
        final screens = _screensFor(isDarkMode);

        final baseTheme = isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
        final glassTheme = isDarkMode
            ? AppTheme.studentGlassDarkTheme
            : AppTheme.studentGlassLightTheme;

        return Theme(
          data: glassTheme.copyWith(textTheme: baseTheme.textTheme),
          child: StudentGlassScaffold(
            backgroundColor: isDarkMode ? const Color(0xFF0A111D) : null,
            body: AnimatedBuilder(
              animation: _tabMotion,
              child: IndexedStack(
                index: _selectedIndex,
                children: List<Widget>.generate(
                  5,
                  (index) => screens[index] ?? const SizedBox.shrink(),
                ),
              ),
              builder: (context, child) {
                final content = child ?? const SizedBox.shrink();
                final reduced = Csp11MotionPreferences.reduced(context);
                if (reduced) {
                  return content;
                }

                final progress = _tabMotion.value;
                final translation = (1 - progress) * 10 * _tabDirection;
                final opacity = 0.94 + (0.06 * progress);

                return Opacity(
                  opacity: opacity,
                  child: Transform.translate(
                    offset: Offset(translation, 0),
                    child: content,
                  ),
                );
              },
            ),
            bottomNavigationBar: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _selectBottomNavigationTab,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.menu_book_outlined),
                      selectedIcon: Icon(Icons.menu_book),
                      label: 'Learn',
                    ),
                    NavigationDestination(
                      key: ValueKey('bottom-nav-practice'),
                      icon: Icon(Icons.quiz_outlined),
                      selectedIcon: Icon(Icons.quiz_rounded),
                      label: 'Practice',
                    ),
                    NavigationDestination(
                      key: ValueKey('bottom-nav-lab'),
                      icon: Icon(Icons.science_outlined),
                      selectedIcon: Icon(Icons.science_rounded),
                      label: 'LAB',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.style_outlined),
                      selectedIcon: Icon(Icons.style_rounded),
                      label: 'Flashcards',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
