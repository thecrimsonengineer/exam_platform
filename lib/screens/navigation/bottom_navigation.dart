import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../services/settings/theme_mode_service.dart';
import '../courses/csp/csp_study_hub_screen.dart';
import '../courses/csp/csp_study_hub_screen_dark.dart';
import '../flashcards/flashcards_screen.dart';
import '../flashcards/flashcards_screen_dark.dart';
import '../home/home_screen.dart';
import '../home/home_screen_dark.dart';
import '../progress/progress_screen.dart';
import '../progress/progress_screen_dark.dart';
import '../settings/settings_screen.dart';
import '../settings/settings_screen_dark.dart';

class BottomNavigationScreen extends StatefulWidget {
  const BottomNavigationScreen({super.key});

  @override
  State<BottomNavigationScreen> createState() => _BottomNavigationScreenState();
}

class _BottomNavigationScreenState extends State<BottomNavigationScreen> {
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
    _ensureScreenBuilt(0, ThemeModeService.isDarkMode.value);
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
            onOpenProgress: () => _selectTab(3),
            onOpenSettings: () => _selectTab(4),
          );
        case 1:
          return const DarkCspStudyHubScreen();
        case 2:
          return const DarkFlashcardsScreen();
        case 3:
          return DarkProgressScreen(key: _darkProgressKey);
        case 4:
          return const DarkSettingsScreen();
        default:
          return const SizedBox.shrink();
      }
    }

    switch (index) {
      case 0:
        return HomeScreen(
          onOpenStudy: () => _selectTab(1),
          onOpenFlashcards: () => _selectTab(2),
          onOpenProgress: () => _selectTab(3),
          onOpenSettings: () => _selectTab(4),
        );
      case 1:
        return const CspStudyHubScreen();
      case 2:
        return const FlashcardsScreen();
      case 3:
        return ProgressScreen(key: _lightProgressKey);
      case 4:
        return const SettingsScreen();
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
          _darkProgressKey.currentState?.refresh();
        } else {
          _lightProgressKey.currentState?.refresh();
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

        return Theme(
          data: isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
          child: Scaffold(
            backgroundColor: isDarkMode ? const Color(0xFF0A111D) : null,
            body: IndexedStack(
              index: _selectedIndex,
              children: List<Widget>.generate(
                5,
                (index) => screens[index] ?? const SizedBox.shrink(),
              ),
            ),
            bottomNavigationBar: NavigationBar(
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
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
