import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../theme/glass/student_glass.dart';
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
import '../progress/progress_screen.dart';
import '../progress/progress_screen_dark.dart';
import '../practice/practice_hub_screen.dart';
import '../settings/settings_screen.dart';
import '../settings/settings_screen_dark.dart';

class BottomNavigationScreen extends StatefulWidget {
  const BottomNavigationScreen({super.key});

  @override
  State<BottomNavigationScreen> createState() => _BottomNavigationScreenState();
}

class _BottomNavigationScreenState extends State<BottomNavigationScreen>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;

  final GlobalKey<ProgressScreenState> _lightProgressKey =
      GlobalKey<ProgressScreenState>();
  final GlobalKey<DarkProgressScreenState> _darkProgressKey =
      GlobalKey<DarkProgressScreenState>();

  final Map<int, Widget> _lightScreens = <int, Widget>{};
  final Map<int, Widget> _darkScreens = <int, Widget>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    final isDarkMode = ThemeModeService.isDarkMode.value;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            isDarkMode ? const DarkSettingsScreen() : const SettingsScreen(),
      ),
    );
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
            onOpenFlashcards: () => _selectTab(2),
            onOpenSettings: _openSettings,
          );
        case 1:
          return const DarkCspStudyHubScreen();
        case 2:
          return const DarkFlashcardsScreen();
        case 3:
          return DarkProgressScreen(key: _darkProgressKey);
        case 4:
          return const PracticeHubScreen();
        default:
          return const SizedBox.shrink();
      }
    }

    switch (index) {
      case 0:
        return HomeScreen(
          onOpenStudy: () => _selectTab(1),
          onOpenFlashcards: () => _selectTab(2),
          onOpenSettings: _openSettings,
        );
      case 1:
        return const CspStudyHubScreen();
      case 2:
        return const FlashcardsScreen();
      case 3:
        return ProgressScreen(key: _lightProgressKey);
      case 4:
        return const PracticeHubScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  void _ensureScreenBuilt(int index, bool isDarkMode) {
    final screens = _screensFor(isDarkMode);
    screens[index] ??= _buildScreen(index, isDarkMode);
  }

  void _selectTab(int index) {
    if (!mounted) {
      return;
    }

    final isDarkMode = ThemeModeService.isDarkMode.value;

    setState(() {
      _ensureScreenBuilt(index, isDarkMode);
      _selectedIndex = index;
    });

    if (index == 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ThemeModeService.isDarkMode.value) {
          _darkProgressKey.currentState?.onVisible();
        } else {
          _lightProgressKey.currentState?.onVisible();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeModeService.isDarkMode,
      builder: (context, isDarkMode, _) {
        _ensureScreenBuilt(_selectedIndex, isDarkMode);
        final screens = _screensFor(isDarkMode);

        final baseTheme = isDarkMode
            ? AppTheme.darkTheme
            : AppTheme.lightTheme;
        final glassTheme = isDarkMode
            ? AppTheme.studentGlassDarkTheme
            : AppTheme.studentGlassLightTheme;

        return Theme(
          data: glassTheme.copyWith(textTheme: baseTheme.textTheme),
          child: StudentGlassScaffold(
            backgroundColor: isDarkMode ? const Color(0xFF0A111D) : null,
            body: IndexedStack(
              index: _selectedIndex,
              children: List<Widget>.generate(
                5,
                (index) => screens[index] ?? const SizedBox.shrink(),
              ),
            ),
            bottomNavigationBar: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _selectTab,
                  destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: 'Study',
                ),
                NavigationDestination(
                  icon: Icon(Icons.style_outlined),
                  selectedIcon: Icon(Icons.style_rounded),
                  label: 'Flashcards',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart),
                  label: 'Progress',
                ),
                NavigationDestination(
                  key: ValueKey('bottom-nav-practice'),
                  icon: Icon(Icons.quiz_outlined),
                  selectedIcon: Icon(Icons.quiz_rounded),
                  label: 'Practice',
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
