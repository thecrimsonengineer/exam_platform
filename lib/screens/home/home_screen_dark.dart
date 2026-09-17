import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../models/student_learning_progress.dart';
import '../../services/student_learning_position_service.dart';
import '../../services/student_learning_progress_service.dart';
import '../../services/practice/practice_mode_service.dart';
import '../../services/study_content_search_service.dart';
import '../../widgets/csp/home/study_content_search_panel.dart';
import '../courses/csp/csp_practice_screen_dark.dart';
import '../courses/csp/domain_screen_dark.dart';
import '../courses/csp/study_content_screen_dark.dart';
import '../practice/practice_quick_launch_screen.dart';

class DarkHomeScreen extends StatefulWidget {
  final VoidCallback? onOpenStudy;
  final VoidCallback? onOpenFlashcards;
  final VoidCallback? onOpenProgress;
  final VoidCallback? onOpenSettings;
  final Future<StudentLearningPosition?> Function()? loadLearningPosition;
  final Future<Map<String, StudentSubtopicProgress>> Function()? loadProgress;

  const DarkHomeScreen({
    super.key,
    this.onOpenStudy,
    this.onOpenFlashcards,
    this.onOpenProgress,
    this.onOpenSettings,
    this.loadLearningPosition,
    this.loadProgress,
  });

  @override
  State<DarkHomeScreen> createState() => _DarkHomeScreenState();
}

class _DarkHomeScreenState extends State<DarkHomeScreen> {
  static const _background = Color(0xFF0A111D);
  static const _surface = Color(0xFF111B2C);
  static const _navy = Color(0xFF5F93D8);
  static const _blue = Color(0xFF6EA8FF);
  static const _violet = Color(0xFF9A7CF4);
  static const _textPrimary = Color(0xFFF4F7FB);
  static const _textMuted = Color(0xFFA5B1C4);
  static const _border = Color(0xFF25344A);

  final StudentLearningPositionService _positionService =
      const StudentLearningPositionService();
  final StudentLearningProgressService _progressService =
      const StudentLearningProgressService();

  late Future<_HomeData> _homeFuture;

  @override
  void initState() {
    super.initState();
    _homeFuture = _loadHomeData();
  }

  Future<_HomeData> _loadHomeData() async {
    final positionLoader = widget.loadLearningPosition;
    final progressLoader = widget.loadProgress;

    final position = positionLoader != null
        ? await positionLoader()
        : await _positionService.loadPosition();

    final progress = progressLoader != null
        ? await progressLoader()
        : await _progressService.loadAllProgress();

    return _HomeData(position: position, progress: progress);
  }

  Future<void> _refreshHome() async {
    final next = _loadHomeData();

    if (mounted) {
      setState(() {
        _homeFuture = next;
      });
    }

    await next;
  }

  Future<void> _continueLearning(StudentLearningPosition? position) async {
    if (position == null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const DarkDomainScreen(domainNumber: 1),
        ),
      );
      await _refreshHome();
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DarkStudyContentScreen(
          domainId: position.domainId,
          competencyId: position.competencyId,
          domainTitle: position.domainTitle,
          loadingTitle: position.competencyTitle,
          initialSubtopicId: position.subtopicId,
        ),
      ),
    );

    await _refreshHome();
  }

  Future<void> _openSearchResult(StudyContentSearchResult result) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DarkStudyContentScreen(
          domainId: result.domainId,
          competencyId: result.competencyId,
          domainTitle: result.domainTitle,
          loadingTitle: result.competencyTitle,
          initialSubtopicId: result.subtopicId,
        ),
      ),
    );

    await _refreshHome();
  }

  void _openPractice({required String title, required String description}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            DarkCspPracticeScreen(title: title, description: description),
      ),
    );
  }

  void _openQuickPractice(PracticeMode mode) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PracticeQuickLaunchScreen(mode: mode, isDarkMode: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A111D), Color(0xFF0D1624), Color(0xFF111827)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshHome,
            child: CustomScrollView(
              key: const PageStorageKey<String>('csp11-home-scroll'),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                _buildAppBar(),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    _pageHorizontal(context),
                    12,
                    _pageHorizontal(context),
                    44,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: FutureBuilder<_HomeData>(
                          future: _homeFuture,
                          builder: (context, snapshot) {
                            final data =
                                snapshot.data ?? const _HomeData.empty();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHero(context, snapshot, data),
                                const SizedBox(height: 18),
                                StudyContentSearchPanel(
                                  isDarkMode: true,
                                  onSelected: _openSearchResult,
                                ),
                                const SizedBox(height: 24),
                                _buildContinueLearning(snapshot, data),
                                const SizedBox(height: 28),
                                _buildSectionHeading(
                                  eyebrow: 'YOUR WORKSPACE',
                                  title: 'Learn, practise, remember',
                                  subtitle:
                                      'Three focused routes. One CSP11 learning system.',
                                ),
                                const SizedBox(height: 14),
                                _buildPrimaryActions(context),
                                const SizedBox(height: 30),
                                _buildSectionHeading(
                                  eyebrow: 'QUICK PRACTICE',
                                  title: 'Train with intent',
                                  subtitle:
                                      'Jump straight into a focused question session.',
                                ),
                                const SizedBox(height: 14),
                                _buildQuickPractice(context),
                                const SizedBox(height: 30),
                                _buildProgressIntelligence(snapshot, data),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _pageHorizontal(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) return 28;
    if (width >= 700) return 22;
    return 16;
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: _background.withValues(alpha: 0.96),
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 18,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.10),
              ),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: AppColors.primary,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'CSP11',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.25,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Learning Hub',
            style: TextStyle(
              color: _textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconButton(
            key: const ValueKey('home-settings'),
            tooltip: 'Settings',
            onPressed: widget.onOpenSettings,
            icon: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: _textPrimary,
                size: 19,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHero(
    BuildContext context,
    AsyncSnapshot<_HomeData> snapshot,
    _HomeData data,
  ) {
    final compact = MediaQuery.sizeOf(context).width < 650;
    final completed = data.completedCount;
    final inProgress = data.inProgressCount;

    return Container(
      key: const ValueKey('home-hero'),
      constraints: BoxConstraints(minHeight: compact ? 360 : 330),
      padding: EdgeInsets.all(compact ? 22 : 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF102A56), Color(0xFF1E4C91), Color(0xFF5B36A8)],
          stops: [0.0, 0.58, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.20),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -74,
            right: -42,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.065),
                    width: 24,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 86,
            bottom: -105,
            child: IgnorePointer(
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.025),
                ),
              ),
            ),
          ),
          Positioned(
            right: compact ? 10 : 26,
            top: compact ? 130 : 76,
            child: IgnorePointer(
              child: Transform.rotate(
                angle: -0.12,
                child: Icon(
                  Icons.workspace_premium_rounded,
                  size: compact ? 105 : 150,
                  color: Colors.white.withValues(alpha: 0.045),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _heroPill(
                    icon: Icons.verified_rounded,
                    text: 'CSP11 LEARNING HUB',
                  ),
                  _heroPill(
                    icon: Icons.hub_rounded,
                    text: '7 DOMAINS',
                    accent: Colors.amber.shade300,
                  ),
                ],
              ),
              const SizedBox(height: 26),
              const Text(
                'Your CSP command center.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  height: 1.06,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.9,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 690),
                child: Text(
                  'Move from focused study to deliberate practice and rapid recall without leaving your learning flow.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 14.5,
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              if (snapshot.connectionState == ConnectionState.waiting)
                _buildHeroLoadingMetrics()
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final metrics = [
                      _HeroMetricData(
                        icon: Icons.check_circle_rounded,
                        value: '$completed',
                        label: 'Completed',
                      ),
                      _HeroMetricData(
                        icon: Icons.timelapse_rounded,
                        value: '$inProgress',
                        label: 'In Progress',
                      ),
                      const _HeroMetricData(
                        icon: Icons.layers_rounded,
                        value: '7',
                        label: 'Domains',
                      ),
                    ];

                    if (constraints.maxWidth < 560) {
                      return Wrap(
                        spacing: 22,
                        runSpacing: 15,
                        children: metrics.map(_heroMetric).toList(),
                      );
                    }

                    return Row(
                      children: [
                        _heroMetric(metrics[0]),
                        _heroDivider(),
                        _heroMetric(metrics[1]),
                        _heroDivider(),
                        _heroMetric(metrics[2]),
                      ],
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroPill({
    required IconData icon,
    required String text,
    Color? accent,
  }) {
    final foreground = accent ?? Colors.white.withValues(alpha: 0.94);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: foreground,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroMetric(_HeroMetricData metric) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 116),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Icon(
              metric.icon,
              color: Colors.white.withValues(alpha: 0.90),
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                metric.value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                metric.label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.62),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroDivider() {
    return Container(
      height: 42,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      color: Colors.white.withValues(alpha: 0.13),
    );
  }

  Widget _buildHeroLoadingMetrics() {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children: List.generate(
        3,
        (_) => Container(
          width: 122,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueLearning(
    AsyncSnapshot<_HomeData> snapshot,
    _HomeData data,
  ) {
    final position = data.position;

    return Container(
      key: const ValueKey('home-continue-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.055),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: snapshot.connectionState == ConnectionState.waiting
          ? const _HomeInlineLoading()
          : snapshot.hasError
          ? _buildContinueError()
          : position == null
          ? _buildFreshStart()
          : _buildResume(position),
    );
  }

  Widget _buildContinueError() {
    return Row(
      children: [
        _featureIcon(
          icon: Icons.cloud_off_rounded,
          background: const Color(0xFF1D1934),
          foreground: _violet,
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Eyebrow('CONTINUE LEARNING'),
              SizedBox(height: 5),
              Text(
                'Your saved position is unavailable right now.',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _ArrowButton(tooltip: 'Open Study', onTap: widget.onOpenStudy),
      ],
    );
  }

  Widget _buildFreshStart() {
    return Row(
      children: [
        _featureIcon(
          icon: Icons.route_rounded,
          background: const Color(0xFF14243B),
          foreground: _blue,
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Eyebrow('START YOUR PATH'),
              SizedBox(height: 5),
              Text(
                'Begin with the CSP11 domain map.',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Your latest learning position will appear here automatically.',
                style: TextStyle(color: _textMuted, fontSize: 11, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _ArrowButton(
          key: const ValueKey('home-continue'),
          tooltip: 'Start Learning',
          onTap: () => _continueLearning(null),
        ),
      ],
    );
  }

  Widget _buildResume(StudentLearningPosition position) {
    final subtopic = position.subtopicTitle?.trim();
    final detail = subtopic == null || subtopic.isEmpty
        ? position.domainTitle
        : subtopic;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;

        final copy = Row(
          children: [
            _featureIcon(
              icon: Icons.play_arrow_rounded,
              background: const Color(0xFF13271D),
              foreground: const Color(0xFF1F8A4C),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Eyebrow('CONTINUE LEARNING'),
                  const SizedBox(height: 5),
                  Text(
                    position.competencyTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 16,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Domain ${position.domainNumber}  •  $detail',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _textMuted,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        final button = FilledButton.icon(
          key: const ValueKey('home-continue'),
          onPressed: () => _continueLearning(position),
          style: FilledButton.styleFrom(
            backgroundColor: _navy,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.arrow_forward_rounded, size: 17),
          label: const Text(
            'CONTINUE',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [copy, const SizedBox(height: 16), button],
          );
        }

        return Row(
          children: [
            Expanded(child: copy),
            const SizedBox(width: 18),
            button,
          ],
        );
      },
    );
  }

  Widget _featureIcon({
    required IconData icon,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: foreground, size: 24),
    );
  }

  Widget _buildSectionHeading({
    required String eyebrow,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.15,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 22,
            height: 1.12,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.45,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: _textMuted,
            fontSize: 11.5,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryActions(BuildContext context) {
    final actions = [
      _PrimaryActionData(
        keyName: 'home-study',
        eyebrow: 'LEARN',
        title: 'Study',
        description:
            'Move through the canonical Domain → Competency → Topic → Subtopic path.',
        icon: Icons.menu_book_rounded,
        gradient: const [Color(0xFF102A56), Color(0xFF2457A2)],
        onTap: widget.onOpenStudy,
      ),
      _PrimaryActionData(
        keyName: 'home-practice',
        eyebrow: 'APPLY',
        title: 'Practice Questions',
        description:
            'Build a focused quiz from the published CSP11 question bank.',
        icon: Icons.quiz_rounded,
        gradient: const [Color(0xFF4C2F8B), Color(0xFF7654C6)],
        onTap: () => _openPractice(
          title: 'Practice Questions',
          description:
              'Build a CSP11 quiz by domain, competency, subtopic, difficulty, or cognitive level.',
        ),
      ),
      _PrimaryActionData(
        keyName: 'home-flashcards',
        eyebrow: 'RECALL',
        title: 'Flashcards',
        description:
            'A dedicated space for rapid recall and future spaced review.',
        icon: Icons.style_rounded,
        gradient: const [Color(0xFF126E66), Color(0xFF22A091)],
        onTap: widget.onOpenFlashcards,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 580
            ? 2
            : 1;
        const gap = 14.0;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: actions
              .map(
                (action) => SizedBox(
                  width: width,
                  height: 190,
                  child: _buildPrimaryActionCard(action),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildPrimaryActionCard(_PrimaryActionData action) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey(action.keyName),
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: action.gradient,
            ),
            boxShadow: [
              BoxShadow(
                color: action.gradient.first.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -30,
                right: -28,
                child: Container(
                  width: 105,
                  height: 105,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 16,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                bottom: 14,
                child: Icon(
                  action.icon,
                  size: 62,
                  color: Colors.white.withValues(alpha: 0.065),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(19),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Icon(
                            action.icon,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_outward_rounded,
                            color: Colors.white,
                            size: 17,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      action.eyebrow,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.62),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      action.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      action.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.76),
                        fontSize: 10.5,
                        height: 1.38,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickPractice(BuildContext context) {
    final items = [
      _QuickActionData(
        keyName: 'home-daily-challenge',
        icon: Icons.local_fire_department_rounded,
        title: 'Daily Challenge',
        subtitle: 'A short focused session',
        accent: const Color(0xFFE37A2F),
        tint: const Color(0xFF2A2015),
        onTap: () => _openQuickPractice(PracticeMode.dailyChallenge),
      ),
      _QuickActionData(
        keyName: 'home-weak-areas',
        icon: Icons.track_changes_rounded,
        title: 'Weak Areas',
        subtitle: 'Target a precise learning area',
        accent: const Color(0xFF7A52C8),
        tint: const Color(0xFF1D1934),
        onTap: () => _openQuickPractice(PracticeMode.weakAreas),
      ),
      _QuickActionData(
        keyName: 'home-random-quiz',
        icon: Icons.shuffle_rounded,
        title: 'Random Quiz',
        subtitle: 'Mix published CSP11 questions',
        accent: const Color(0xFF1A8178),
        tint: const Color(0xFF102925),
        onTap: () => _openQuickPractice(PracticeMode.randomQuiz),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 800
            ? 3
            : constraints.maxWidth >= 540
            ? 2
            : 1;
        const gap = 12.0;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: items
              .map(
                (item) => SizedBox(
                  width: width,
                  child: _buildQuickPracticeCard(item),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildQuickPracticeCard(_QuickActionData item) {
    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: ValueKey(item.keyName),
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 104),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: item.tint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: item.accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.toUpperCase(),
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.45,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        color: _textMuted,
                        fontSize: 10.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: item.accent.withValues(alpha: 0.75),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIntelligence(
    AsyncSnapshot<_HomeData> snapshot,
    _HomeData data,
  ) {
    final completed = data.completedCount;
    final inProgress = data.inProgressCount;
    final tracked = data.trackedCount;

    return Container(
      key: const ValueKey('home-progress-panel'),
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;

          final intro = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Eyebrow('PROGRESS INTELLIGENCE'),
              const SizedBox(height: 6),
              const Text(
                'Your learning footprint',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.35,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'These are real learner records stored for your signed-in account on this device.',
                style: TextStyle(color: _textMuted, fontSize: 11, height: 1.45),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  _progressChip(
                    icon: Icons.check_circle_outline_rounded,
                    label: '$completed completed',
                  ),
                  _progressChip(
                    icon: Icons.timelapse_rounded,
                    label: '$inProgress in progress',
                  ),
                  _progressChip(
                    icon: Icons.bookmark_border_rounded,
                    label: '$tracked tracked',
                  ),
                ],
              ),
            ],
          );

          final action = Material(
            color: const Color(0xFF101A2A),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              key: const ValueKey('home-progress'),
              onTap: widget.onOpenProgress,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: compact ? double.infinity : 240,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _border),
                ),
                child: const Row(
                  children: [
                    _ProgressOrb(),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'OPEN DASHBOARD',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'See domain and topic progress',
                            style: TextStyle(
                              color: _textPrimary,
                              fontSize: 11.5,
                              height: 1.3,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [intro, const SizedBox(height: 18), action],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: intro),
              const SizedBox(width: 24),
              action,
            ],
          );
        },
      ),
    );
  }

  Widget _progressChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF101A2A),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeData {
  final StudentLearningPosition? position;
  final Map<String, StudentSubtopicProgress> progress;

  const _HomeData({required this.position, required this.progress});

  const _HomeData.empty()
    : position = null,
      progress = const <String, StudentSubtopicProgress>{};

  int get completedCount => progress.values
      .where((item) => item.state == StudentLearningState.completed)
      .length;

  int get inProgressCount => progress.values
      .where((item) => item.state == StudentLearningState.inProgress)
      .length;

  int get trackedCount => progress.length;
}

class _HeroMetricData {
  final IconData icon;
  final String value;
  final String label;

  const _HeroMetricData({
    required this.icon,
    required this.value,
    required this.label,
  });
}

class _PrimaryActionData {
  final String keyName;
  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback? onTap;

  const _PrimaryActionData({
    required this.keyName,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });
}

class _QuickActionData {
  final String keyName;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final Color tint;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.keyName,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.tint,
    required this.onTap,
  });
}

class _Eyebrow extends StatelessWidget {
  final String text;

  const _Eyebrow(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 9.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.05,
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback? onTap;

  const _ArrowButton({super.key, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: _DarkHomeScreenState._navy,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 19,
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeInlineLoading extends StatelessWidget {
  const _HomeInlineLoading();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: 12),
        Text(
          'Preparing your learning position…',
          style: TextStyle(
            color: _DarkHomeScreenState._textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ProgressOrb extends StatelessWidget {
  const _ProgressOrb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_DarkHomeScreenState._navy, _DarkHomeScreenState._violet],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: _DarkHomeScreenState._navy.withValues(alpha: 0.13),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Icon(Icons.insights_rounded, color: Colors.white, size: 22),
    );
  }
}
