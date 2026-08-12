import 'package:flutter/material.dart';

import '../../data/csp11_blueprint.dart';

import 'content_repository/content_repository_screen.dart';
import 'study_content/study_content_studio_screen.dart';
import 'question_bank_screen.dart';
import '../courses/courses_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sidebarController;
  late final Animation<double> _sidebarAnimation;

  int _selectedNav = 0;

  bool _sidebarPinned = false;
  bool _sidebarHovered = false;
  bool _mobileDrawerOpen = false;

  static const double collapsedWidth = 78;
  static const double expandedWidth = 270;

  final List<_NavItem> navigation = const [
    _NavItem(Icons.grid_view_rounded, 'Command Center', 'OVERVIEW'),
    _NavItem(Icons.school_rounded, 'Courses', 'LEARNING'),
    _NavItem(Icons.auto_awesome_rounded, 'Content Studio', 'CONTENT'),
    _NavItem(Icons.storage_rounded, 'Repository', 'CONTENT'),
    _NavItem(Icons.publish_rounded, 'Publishing', 'CONTENT'),
    _NavItem(Icons.quiz_rounded, 'Question Bank', 'ASSESSMENT'),
    _NavItem(
      Icons.assignment_rounded,
      'Practice Exams',
      'ASSESSMENT',
      enabled: false,
    ),
    _NavItem(Icons.people_alt_rounded, 'Learners', 'LEARNERS', enabled: false),
    _NavItem(Icons.analytics_rounded, 'Analytics', 'INSIGHTS', enabled: false),
    _NavItem(Icons.settings_rounded, 'Settings', 'SYSTEM', enabled: false),
  ];

  @override
  void initState() {
    super.initState();

    _sidebarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 240),
    );

    _sidebarAnimation = CurvedAnimation(
      parent: _sidebarController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _sidebarController.dispose();
    super.dispose();
  }

  void _openDesktopSidebar() {
    if (!_sidebarPinned) {
      _sidebarHovered = true;
      _sidebarController.forward();
    }
  }

  void _closeDesktopSidebar() {
    if (!_sidebarPinned) {
      _sidebarHovered = false;
      _sidebarController.reverse();
    }
  }

  void _togglePin() {
    setState(() {
      _sidebarPinned = !_sidebarPinned;
    });

    if (_sidebarPinned) {
      _sidebarController.forward();
    } else if (!_sidebarHovered) {
      _sidebarController.reverse();
    }
  }

  void _openMobileDrawer() {
    setState(() {
      _mobileDrawerOpen = true;
    });
  }

  void _closeMobileDrawer() {
    setState(() {
      _mobileDrawerOpen = false;
    });
  }

  void _openStudio() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const StudyContentStudioScreen()),
    );
  }

  void _openRepository() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ContentRepositoryScreen()),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is coming in the next platform stage.'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _selectNavigation(int index) {
    final item = navigation[index];

    if (!item.enabled) {
      _showComingSoon(item.label);
      return;
    }

    setState(() {
      _selectedNav = index;
      _mobileDrawerOpen = false;
    });

    if (index == 1) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const CoursesScreen()));
    } else if (index == 2) {
      _openStudio();
    } else if (index == 3) {
      _openRepository();
    } else if (index == 5) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const QuestionBankScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // MOBILE
        if (width < 600) {
          return _buildMobileHome();
        }

        // DESKTOP / WEB
        return _buildDesktopHome();
      },
    );
  }

  // ===========================================================================
  // DESKTOP
  // ===========================================================================

  Widget _buildDesktopHome() {
    return Scaffold(
      backgroundColor: _AdminColors.background,
      body: Row(
        children: [
          _buildDesktopSidebar(),
          Expanded(child: _buildDesktopDashboard()),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    return AnimatedBuilder(
      animation: _sidebarAnimation,
      builder: (context, child) {
        final width =
            collapsedWidth +
            ((expandedWidth - collapsedWidth) * _sidebarAnimation.value);

        return MouseRegion(
          onEnter: (_) => _openDesktopSidebar(),
          onExit: (_) => _closeDesktopSidebar(),
          child: SizedBox(
            width: width,
            child: ClipRect(
              child: Container(
                width: expandedWidth,
                decoration: BoxDecoration(
                  color: _AdminColors.sidebar,
                  border: Border(
                    right: BorderSide(
                      color: Colors.white.withValues(alpha: .07),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .10),
                      blurRadius: 30,
                      offset: const Offset(8, 0),
                    ),
                  ],
                ),
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth: expandedWidth,
                  maxWidth: expandedWidth,
                  child: _buildDesktopSidebarContent(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopSidebarContent() {
    return AnimatedBuilder(
      animation: _sidebarAnimation,
      builder: (context, child) {
        final t = _sidebarAnimation.value;

        return SizedBox(
          width: expandedWidth,
          height: double.infinity,
          child: Column(
            children: [
              SizedBox(
                height: 82,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 13, 0),
                  child: Row(
                    children: [
                      _brandIcon(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Opacity(
                          opacity: t,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CSP11',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.8,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'ADMIN CONSOLE',
                                style: TextStyle(
                                  color: Color(0xFF8994AA),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Opacity(
                        opacity: t,
                        child: IgnorePointer(
                          ignoring: t < .5,
                          child: _pinButton(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  child: _desktopNavigation(t),
                ),
              ),
              _desktopProfile(t),
            ],
          ),
        );
      },
    );
  }

  Widget _desktopNavigation(double t) {
    String? lastSection;

    final children = <Widget>[];

    for (int i = 0; i < navigation.length; i++) {
      final item = navigation[i];

      if (item.section != lastSection) {
        if (children.isNotEmpty) {
          children.add(const SizedBox(height: 13));
        }

        children.add(
          SizedBox(
            height: 20,
            child: Opacity(
              opacity: t,
              child: Padding(
                padding: const EdgeInsets.only(left: 13),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item.section,
                    style: const TextStyle(
                      color: Color(0xFF68748A),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        lastSection = item.section;
      }

      children.add(_desktopNavButton(i, item, t));
    }

    return Column(children: children);
  }

  Widget _desktopNavButton(int index, _NavItem item, double t) {
    final selected = _selectedNav == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Tooltip(
        message: t < .5 ? item.label : '',
        preferBelow: false,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _selectNavigation(index),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: selected
                    ? _AdminColors.primary.withValues(alpha: .16)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: selected
                    ? Border.all(
                        color: _AdminColors.primary.withValues(alpha: .22),
                      )
                    : null,
              ),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 9),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: selected
                              ? _AdminColors.primary
                              : Colors.white.withValues(alpha: .045),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          item.icon,
                          size: 17,
                          color: selected
                              ? Colors.white
                              : item.enabled
                              ? const Color(0xFF9AA5B8)
                              : const Color(0xFF596477),
                        ),
                      ),
                    ),
                  ),

                  // Fixed-width expanded content prevents RenderFlex
                  // from receiving a tiny width while the sidebar animates.
                  Positioned(
                    left: 53,
                    top: 0,
                    width: expandedWidth - 61,
                    height: 52,
                    child: IgnorePointer(
                      ignoring: t < .01,
                      child: Opacity(
                        opacity: t,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : item.enabled
                                      ? const Color(0xFFB1BAC9)
                                      : const Color(0xFF596477),
                                  fontSize: 12,
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                            if (!item.enabled)
                              const Icon(
                                Icons.lock_outline_rounded,
                                size: 12,
                                color: Color(0xFF596477),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _desktopProfile(double t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 8, 13, 15),
      child: SizedBox(
        width: expandedWidth - 26,
        height: 58,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .045),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: .06)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _adminIcon(),
                const SizedBox(width: 9),
                Expanded(
                  child: Opacity(
                    opacity: t,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Administrator',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Platform Control',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF707C91),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Opacity(
                  opacity: t,
                  child: const Icon(
                    Icons.more_horiz_rounded,
                    color: Color(0xFF68748A),
                    size: 17,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pinButton() {
    return Tooltip(
      message: _sidebarPinned ? 'Unpin sidebar' : 'Pin sidebar',
      preferBelow: false,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _togglePin,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _sidebarPinned
                  ? _AdminColors.primary.withValues(alpha: .24)
                  : Colors.white.withValues(alpha: .075),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: _sidebarPinned
                    ? _AdminColors.primary.withValues(alpha: .35)
                    : Colors.white.withValues(alpha: .10),
              ),
            ),
            child: Icon(
              _sidebarPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              size: 16,
              color: _sidebarPinned
                  ? const Color(0xFFA9C2F0)
                  : const Color(0xFF9AA6BA),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopDashboard() {
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 28, 32, 42),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1500),
            child: _desktopDashboardContent(),
          ),
        ),
      ),
    );
  }

  Widget _desktopDashboardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _dashboardHeader(),
        const SizedBox(height: 24),
        _desktopHero(),
        const SizedBox(height: 20),
        _desktopStats(),
        const SizedBox(height: 20),
        _desktopPanels(),
        const SizedBox(height: 20),
        _desktopQuickActions(),
        const SizedBox(height: 20),
        _desktopActivity(),
      ],
    );
  }

  // ===========================================================================
  // MOBILE
  // ===========================================================================

  Widget _buildMobileHome() {
    return Scaffold(
      backgroundColor: _AdminColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _mobileAppBar(),
                Expanded(child: _mobileContent()),
              ],
            ),
          ),

          if (_mobileDrawerOpen) _mobileDrawerOverlay(),
        ],
      ),
    );
  }

  Widget _mobileAppBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(color: _AdminColors.sidebar),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openMobileDrawer,
              borderRadius: BorderRadius.circular(11),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .07),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.menu_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
          _brandIcon(size: 38),
          const SizedBox(width: 9),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CSP11',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'ADMIN CONSOLE',
                  style: TextStyle(
                    color: Color(0xFF8994AA),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          _mobileNotificationButton(),
        ],
      ),
    );
  }

  Widget _mobileNotificationButton() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
          Positioned(
            right: 9,
            top: 8,
            child: CircleAvatar(radius: 3, backgroundColor: Color(0xFFEF5B68)),
          ),
        ],
      ),
    );
  }

  Widget _mobileContent() {
    return RefreshIndicator(
      onRefresh: () async {
        await Future<void>.delayed(const Duration(milliseconds: 350));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'COMMAND CENTER',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: _AdminColors.primary,
                letterSpacing: 1.9,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Platform Overview',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: _AdminColors.text,
                letterSpacing: -.5,
              ),
            ),
            const SizedBox(height: 16),

            _mobileHero(),

            const SizedBox(height: 14),

            _mobileSystemStatus(),

            const SizedBox(height: 14),

            _mobileStats(),

            const SizedBox(height: 14),

            _mobileQuickActions(),

            const SizedBox(height: 14),

            _mobileCoverage(),

            const SizedBox(height: 14),

            _mobileAttention(),

            const SizedBox(height: 14),

            _mobileActivity(),
          ],
        ),
      ),
    );
  }

  Widget _mobileHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF101D36), Color(0xFF203B6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF152A50).withValues(alpha: .18),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Text(
              'CSP11 PLATFORM',
              style: TextStyle(
                color: Color(0xFFB8C9E9),
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Content operations,\nunder control.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              height: 1.08,
              fontWeight: FontWeight.w900,
              letterSpacing: -.7,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Manage the complete CSP11 content lifecycle from one command center.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .65),
              fontSize: 11,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openStudio,
              icon: const Icon(Icons.auto_awesome_rounded, size: 16),
              label: const Text(
                'OPEN CONTENT STUDIO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .4,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF172A4C),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileSystemStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F1),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFC8ECDD)),
      ),
      child: const Row(
        children: [
          _PulseDot(),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'ALL SYSTEMS OPERATIONAL',
              style: TextStyle(
                color: Color(0xFF177A50),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: .6,
              ),
            ),
          ),
          Icon(Icons.check_circle_rounded, color: Color(0xFF219A6B), size: 17),
        ],
      ),
    );
  }

  Widget _mobileStats() {
    return Column(
      children: [
        _mobileStat(
          'ACTIVE CONTENT',
          '01',
          'Competency configured',
          Icons.menu_book_rounded,
          _AdminColors.primary,
        ),
        const SizedBox(height: 9),
        _mobileStat(
          'DRAFT VERSIONS',
          '03',
          'Stored in repository',
          Icons.edit_document,
          const Color(0xFFD08A27),
        ),
        const SizedBox(height: 9),
        _mobileStat(
          'PUBLISHED',
          '02',
          'Available to students',
          Icons.public_rounded,
          const Color(0xFF219A6B),
        ),
        const SizedBox(height: 9),
        _mobileStat(
          'SYSTEM STATUS',
          '100%',
          'Core platform operational',
          Icons.health_and_safety_rounded,
          const Color(0xFF219A6B),
        ),
      ],
    );
  }

  Widget _mobileStat(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _AdminColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _AdminColors.muted,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _AdminColors.muted,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: _AdminColors.text,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileQuickActions() {
    return _mobilePanel(
      title: 'Quick Actions',
      subtitle: 'Common administration operations',
      icon: Icons.bolt_rounded,
      child: Column(
        children: [
          _mobileAction(
            'Create Content',
            'Start a new study content item',
            Icons.add_circle_outline_rounded,
            _AdminColors.primary,
            _openStudio,
          ),
          const SizedBox(height: 8),
          _mobileAction(
            'Import Content',
            'Bring structured content into the platform',
            Icons.file_upload_outlined,
            const Color(0xFF4F7DBA),
            _openStudio,
          ),
          const SizedBox(height: 8),
          _mobileAction(
            'Content Studio',
            'Open the complete editing workspace',
            Icons.auto_awesome_rounded,
            const Color(0xFF7257B7),
            _openStudio,
          ),
          const SizedBox(height: 8),
          _mobileAction(
            'Repository',
            'Manage versions and published content',
            Icons.storage_rounded,
            const Color(0xFFB77B2A),
            () => _showComingSoon('Repository Management'),
          ),
        ],
      ),
    );
  }

  Widget _mobileAction(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFBFD),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: _AdminColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _AdminColors.text,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _AdminColors.muted,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9AA3B2),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mobileCoverage() {
    return _mobilePanel(
      title: 'CSP11 Examination Domains',
      subtitle: 'Official domain structure and examination weight',
      icon: Icons.account_tree_rounded,
      child: Column(
        children: csp11Domains
            .map((domain) => _mobileCoverageRow(domain))
            .toList(),
      ),
    );
  }

  Widget _mobileCoverageRow(Csp11Domain domain) {
    final relativeWeight = domain.weightPercent / 25;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'DOMAIN ${domain.number.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: _AdminColors.primary,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
              ),
              Text(
                '${domain.weightPercent}%',
                style: const TextStyle(
                  color: _AdminColors.text,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            domain.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _AdminColors.text,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: relativeWeight,
              minHeight: 6,
              backgroundColor: const Color(0xFFE9EDF3),
              valueColor: const AlwaysStoppedAnimation<Color>(
                _AdminColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileAttention() {
    return _mobilePanel(
      title: 'Attention Required',
      subtitle: 'Items requiring administrator action',
      icon: Icons.notifications_active_outlined,
      child: Column(
        children: [
          _mobileAttentionItem(
            Icons.edit_document,
            const Color(0xFFD18B2D),
            'Draft content available',
            'ADMIN REPOSITORY TEST has an active draft.',
            'OPEN',
            _openStudio,
          ),
          const SizedBox(height: 9),
          _mobileAttentionItem(
            Icons.storage_rounded,
            _AdminColors.primary,
            'Repository management',
            'Published storage is the next milestone.',
            'NEXT',
            () => _showComingSoon('Repository Management'),
          ),
          const SizedBox(height: 9),
          _mobileAttentionItem(
            Icons.quiz_outlined,
            const Color(0xFF8A6BC1),
            'Question system',
            'Practice questions connect after repository.',
            'LATER',
            () => _showComingSoon('Question Bank'),
          ),
        ],
      ),
    );
  }

  Widget _mobileAttentionItem(
    IconData icon,
    Color color,
    String title,
    String description,
    String action,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFBFD),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: _AdminColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color, size: 17),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _AdminColors.text,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _AdminColors.muted,
                        fontSize: 8,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                action,
                style: TextStyle(
                  color: color,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mobileActivity() {
    return _mobilePanel(
      title: 'Recent Activity',
      subtitle: 'Latest platform events',
      icon: Icons.history_rounded,
      child: Column(
        children: [
          _mobileActivityRow(
            Icons.auto_awesome_rounded,
            _AdminColors.primary,
            'Content Studio',
            'Editing workflow operational',
          ),
          _mobileActivityRow(
            Icons.publish_rounded,
            const Color(0xFF219A6B),
            'Published Content',
            'ADMIN REPOSITORY TEST v2 is live',
          ),
          _mobileActivityRow(
            Icons.layers_rounded,
            const Color(0xFFD18B2D),
            'Revision Created',
            'Draft version 3 available',
          ),
          _mobileActivityRow(
            Icons.check_circle_outline_rounded,
            const Color(0xFF219A6B),
            'Validation',
            'Publishing gate passed',
          ),
        ],
      ),
    );
  }

  Widget _mobileActivityRow(
    IconData icon,
    Color color,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _AdminColors.text,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _AdminColors.muted,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobilePanel({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _AdminColors.primary.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: _AdminColors.primary, size: 17),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _AdminColors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _AdminColors.muted,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ===========================================================================
  // MOBILE DRAWER
  // ===========================================================================

  Widget _mobileDrawerOverlay() {
    return Positioned.fill(
      child: Stack(
        children: [
          GestureDetector(
            onTap: _closeMobileDrawer,
            child: Container(color: Colors.black.withValues(alpha: .42)),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: SafeArea(
              child: Container(
                width: 305,
                height: double.infinity,
                decoration: const BoxDecoration(
                  color: _AdminColors.sidebar,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    _mobileDrawerHeader(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(13, 8, 13, 20),
                        child: _mobileNavigation(),
                      ),
                    ),
                    _mobileDrawerProfile(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileDrawerHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 14, 16),
      child: Row(
        children: [
          _brandIcon(size: 44),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CSP11',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'ADMIN CONSOLE',
                  style: TextStyle(
                    color: Color(0xFF8994AA),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _closeMobileDrawer,
              borderRadius: BorderRadius.circular(10),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.close_rounded,
                  color: Color(0xFF9AA5B8),
                  size: 21,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileNavigation() {
    String? lastSection;

    final widgets = <Widget>[];

    for (int i = 0; i < navigation.length; i++) {
      final item = navigation[i];

      if (item.section != lastSection) {
        if (widgets.isNotEmpty) {
          widgets.add(const SizedBox(height: 14));
        }

        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 6),
            child: Text(
              item.section,
              style: const TextStyle(
                color: Color(0xFF68748A),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
        );

        lastSection = item.section;
      }

      widgets.add(_mobileNavButton(i, item));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }

  Widget _mobileNavButton(int index, _NavItem item) {
    final selected = _selectedNav == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectNavigation(index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 51,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            decoration: BoxDecoration(
              color: selected
                  ? _AdminColors.primary.withValues(alpha: .16)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: selected
                        ? _AdminColors.primary
                        : Colors.white.withValues(alpha: .045),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    item.icon,
                    size: 17,
                    color: selected
                        ? Colors.white
                        : item.enabled
                        ? const Color(0xFF9AA5B8)
                        : const Color(0xFF596477),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : item.enabled
                          ? const Color(0xFFB1BAC9)
                          : const Color(0xFF596477),
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
                if (!item.enabled)
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 13,
                    color: Color(0xFF596477),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _mobileDrawerProfile() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 8, 13, 18),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .045),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: .06)),
        ),
        child: Row(
          children: [
            _adminIcon(),
            const SizedBox(width: 9),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Administrator',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Platform Control',
                    style: TextStyle(color: Color(0xFF707C91), fontSize: 9),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SHARED DESKTOP COMPONENTS
  // ===========================================================================

  Widget _dashboardHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COMMAND CENTER',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: _AdminColors.primary,
                  letterSpacing: 2.1,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Platform Overview',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: _AdminColors.text,
                ),
              ),
            ],
          ),
        ),
        _systemIndicator(),
        const SizedBox(width: 12),
        _desktopIconButton(Icons.notifications_none_rounded),
        const SizedBox(width: 8),
        _desktopIconButton(Icons.help_outline_rounded),
      ],
    );
  }

  Widget _desktopHero() {
    return Container(
      constraints: const BoxConstraints(minHeight: 215),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF101D36), Color(0xFF172A4C), Color(0xFF203B6B)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CSP11 PLATFORM',
                  style: TextStyle(
                    color: Color(0xFFB8C9E9),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Content operations,\nunder control.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 11),
                Text(
                  'Manage the complete CSP11 content lifecycle from one command center.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .66),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: _openStudio,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                  label: const Text('Open Content Studio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF172A4C),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 25),
          Expanded(flex: 2, child: _pipeline()),
        ],
      ),
    );
  }

  Widget _pipeline() {
    final items = [
      ('DRAFT', Icons.edit_note_rounded),
      ('REVIEW', Icons.rate_review_outlined),
      ('VALIDATE', Icons.verified_outlined),
      ('PUBLISHED', Icons.publish_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .055),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONTENT PIPELINE',
            style: TextStyle(
              color: Color(0xFF9FB3D8),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 17),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3157A4),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.$2, color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.$1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF9DB6E5),
                    size: 15,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _desktopStats() {
    return Row(
      children: [
        Expanded(
          child: _desktopStat(
            'ACTIVE CONTENT',
            '01',
            Icons.menu_book_rounded,
            _AdminColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _desktopStat(
            'DRAFT VERSIONS',
            '03',
            Icons.edit_document,
            const Color(0xFFD08A27),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _desktopStat(
            'PUBLISHED',
            '02',
            Icons.public_rounded,
            const Color(0xFF219A6B),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _desktopStat(
            'SYSTEM STATUS',
            '100%',
            Icons.health_and_safety_rounded,
            const Color(0xFF219A6B),
          ),
        ),
      ],
    );
  }

  Widget _desktopStat(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _AdminColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _AdminColors.muted,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: _AdminColors.text,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _desktopPanels() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 6, child: _desktopCoverage()),
        const SizedBox(width: 16),
        Expanded(flex: 4, child: _desktopAttention()),
      ],
    );
  }

  Widget _desktopCoverage() {
    return _desktopPanel(
      title: 'CSP11 Examination Domains',
      subtitle: 'Official domain structure and examination weight',
      icon: Icons.account_tree_rounded,
      child: Column(
        children: csp11Domains.map((domain) => _coverage(domain)).toList(),
      ),
    );
  }

  Widget _coverage(Csp11Domain domain) {
    final relativeWeight = domain.weightPercent / 25;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          SizedBox(
            width: 75,
            child: Text(
              'DOMAIN ${domain.number.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: _AdminColors.primary,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              domain.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _AdminColors.text,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: LinearProgressIndicator(
              value: relativeWeight,
              minHeight: 6,
              backgroundColor: const Color(0xFFE9EDF3),
              valueColor: const AlwaysStoppedAnimation<Color>(
                _AdminColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Text(
            '${domain.weightPercent}%',
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _desktopAttention() {
    return _desktopPanel(
      title: 'Attention Required',
      subtitle: 'Items requiring administrator action',
      icon: Icons.notifications_active_outlined,
      child: Column(
        children: [
          _attention(
            Icons.edit_document,
            const Color(0xFFD18B2D),
            'Draft content available',
            'ADMIN REPOSITORY TEST has an active draft.',
            'OPEN',
            _openStudio,
          ),
          _attention(
            Icons.storage_rounded,
            _AdminColors.primary,
            'Repository management',
            'Published storage is the next milestone.',
            'NEXT',
            () => _showComingSoon('Repository Management'),
          ),
          _attention(
            Icons.quiz_outlined,
            const Color(0xFF8A6BC1),
            'Question system',
            'Practice questions connect after repository.',
            'LATER',
            () => _showComingSoon('Question Bank'),
          ),
        ],
      ),
    );
  }

  Widget _attention(
    IconData icon,
    Color color,
    String title,
    String description,
    String action,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFBFD),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: _AdminColors.border),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _AdminColors.muted,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  action,
                  style: TextStyle(
                    color: color,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _desktopPanel({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _AdminColors.primary, size: 18),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _AdminColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _AdminColors.muted,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _desktopQuickActions() {
    return _desktopPanel(
      title: 'Quick Actions',
      subtitle: 'Common administration operations',
      icon: Icons.bolt_rounded,
      child: Row(
        children: [
          Expanded(
            child: _quickAction(
              'Create Content',
              Icons.add_circle_outline_rounded,
              _AdminColors.primary,
              _openStudio,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _quickAction(
              'Import Content',
              Icons.file_upload_outlined,
              const Color(0xFF4F7DBA),
              _openStudio,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _quickAction(
              'Content Studio',
              Icons.auto_awesome_rounded,
              const Color(0xFF7257B7),
              _openStudio,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _quickAction(
              'Repository',
              Icons.storage_rounded,
              const Color(0xFFB77B2A),
              () => _showComingSoon('Repository Management'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFBFD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _AdminColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _desktopActivity() {
    return _desktopPanel(
      title: 'Recent Activity',
      subtitle: 'Latest platform events',
      icon: Icons.history_rounded,
      child: Column(
        children: [
          _activity(
            Icons.auto_awesome_rounded,
            _AdminColors.primary,
            'Content Studio',
            'Editing workflow operational',
          ),
          _activity(
            Icons.publish_rounded,
            const Color(0xFF219A6B),
            'Published Content',
            'ADMIN REPOSITORY TEST v2 is live',
          ),
          _activity(
            Icons.layers_rounded,
            const Color(0xFFD18B2D),
            'Revision Created',
            'Draft version 3 available',
          ),
          _activity(
            Icons.check_circle_outline_rounded,
            const Color(0xFF219A6B),
            'Validation',
            'Publishing gate passed',
          ),
        ],
      ),
    );
  }

  Widget _activity(
    IconData icon,
    Color color,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$title  •  $description',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _AdminColors.text,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SHARED
  // ===========================================================================

  Widget _brandIcon({double size = 44}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_AdminColors.primary, _AdminColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(size * .29),
        boxShadow: [
          BoxShadow(
            color: _AdminColors.primary.withValues(alpha: .28),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Icon(Icons.shield_rounded, color: Colors.white, size: size * .52),
    );
  }

  Widget _adminIcon() {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFF293448),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.admin_panel_settings_rounded,
        color: Color(0xFF9EABC0),
        size: 18,
      ),
    );
  }

  Widget _systemIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulseDot(),
          SizedBox(width: 7),
          Text(
            'ALL SYSTEMS OPERATIONAL',
            style: TextStyle(
              color: Color(0xFF177A50),
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _desktopIconButton(IconData icon) {
    return Container(
      width: 39,
      height: 39,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _AdminColors.border),
      ),
      child: Icon(icon, size: 19, color: _AdminColors.muted),
    );
  }
}

// =============================================================================
// DATA
// =============================================================================

class _NavItem {
  final IconData icon;
  final String label;
  final String section;
  final bool enabled;

  const _NavItem(this.icon, this.label, this.section, {this.enabled = true});
}

// =============================================================================
// PULSE
// =============================================================================

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) {
        final size = 7 + controller.value * 2;

        return Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: Color(0xFF22A06B),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

// =============================================================================
// COLORS
// =============================================================================

class _AdminColors {
  static const Color background = Color(0xFFF5F7FA);
  static const Color sidebar = Color(0xFF0D1728);

  static const Color primary = Color(0xFF315EAA);
  static const Color primaryLight = Color(0xFF5D83C6);

  static const Color text = Color(0xFF172033);
  static const Color muted = Color(0xFF7A8495);
  static const Color border = Color(0xFFE5E9EF);
}
