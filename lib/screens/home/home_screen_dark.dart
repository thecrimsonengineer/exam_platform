import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';

import '../../app/app_colors.dart';
import '../../features/exam_readiness/screens/exam_readiness_plan_screen.dart';
import '../../features/exam_readiness/screens/exam_readiness_route.dart';
import '../../features/exam_readiness/models/today_plan_summary.dart';
import '../../features/exam_readiness/models/today_plan_task_category.dart';
import '../../features/exam_readiness/repositories/daily_study_plan_repository.dart';
import '../../features/exam_readiness/screens/todays_plan_screen.dart';
import '../../features/exam_readiness/services/today_plan_summary_service.dart';
import '../../models/student_learning_progress.dart';
import '../../services/student_learning_position_service.dart';
import '../../services/student_learning_progress_service.dart';
import '../../services/study_content_search_service.dart';
import '../../widgets/csp/home/study_content_search_panel.dart';
import '../../widgets/csp/home/today_plan_home_section.dart';
import '../courses/csp/domain_screen_dark.dart';
import '../courses/csp/study_content_screen_dark.dart';

class DarkHomeScreen extends StatefulWidget {
  final VoidCallback? onOpenSettings;
  final Future<StudentLearningPosition?> Function()? loadLearningPosition;
  final Future<Map<String, StudentSubtopicProgress>> Function()? loadProgress;

  const DarkHomeScreen({
    super.key,
    this.onOpenSettings,
    this.loadLearningPosition,
    this.loadProgress,
  });

  @override
  State<DarkHomeScreen> createState() => _DarkHomeScreenState();
}

class _DarkHomeScreenState extends State<DarkHomeScreen> {
  static const _background = Color(0xFF0A111D);
  static const _surface = Color(0xA314233B);
  static const _navy = Color(0xFF5F93D8);
  static const _blue = Color(0xFF6EA8FF);
  static const _violet = Color(0xFF9A7CF4);
  static const _textPrimary = Color(0xFFF4F7FB);
  static const _textMuted = Color(0xFFA5B1C4);
  static const _border = Color(0x4DFFFFFF);

  final StudentLearningPositionService _positionService =
      const StudentLearningPositionService();
  final StudentLearningProgressService _progressService =
      const StudentLearningProgressService();
  final DailyStudyPlanRepository _dailyPlanRepository =
      DailyStudyPlanRepository();
  final TodayPlanSummaryService _todayPlanSummaryService =
      const TodayPlanSummaryService();

  late Future<_HomeData> _homeFuture;
  late Future<TodayPlanSummary?> _todayPlanFuture;

  @override
  void initState() {
    super.initState();
    _homeFuture = _loadHomeData();
    _todayPlanFuture = _loadTodayPlanSummary();
  }

  Future<TodayPlanSummary?> _loadTodayPlanSummary() async {
    final plan = await _dailyPlanRepository.loadLatestForDate(DateTime.now());
    if (plan == null) return null;
    return _todayPlanSummaryService.summarize(plan);
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
    final nextHome = _loadHomeData();
    final nextTodayPlan = _loadTodayPlanSummary();

    if (mounted) {
      setState(() {
        _homeFuture = nextHome;
        _todayPlanFuture = nextTodayPlan;
      });
    }

    try {
      await nextHome;
    } catch (_) {
      // Home sections degrade independently after refresh.
    }
    try {
      await nextTodayPlan;
    } catch (_) {
      // Today's Plan failure must not hide Search or Continue CSP.
    }
  }

  Future<void> _retryTodayPlan() async {
    final next = _loadTodayPlanSummary();
    if (mounted) {
      setState(() => _todayPlanFuture = next);
    }
    try {
      await next;
    } catch (_) {
      // The section owns its visible error state.
    }
  }

  Future<void> _openTodaysPlan({TodayPlanTaskCategory? category}) async {
    await Navigator.of(context).push(
      examReadinessRoute<void>(
        child: TodaysPlanScreen(initialCategory: category),
        isDarkMode: true,
      ),
    );
    await _refreshHome();
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
          initialTopicId: result.topicId,
          initialSubtopicId: result.subtopicId,
        ),
      ),
    );

    await _refreshHome();
  }

  void _openExamReadiness() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Navigator.of(context).push(
      examReadinessRoute<void>(
        child: const ExamReadinessPlanScreen(),
        isDarkMode: isDarkMode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StudentGlassScaffold(
      backgroundColor: _background,
      body: Container(
        color: Colors.transparent,
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
                                FutureBuilder<TodayPlanSummary?>(
                                  future: _todayPlanFuture,
                                  builder: (context, todaySnapshot) {
                                    return TodayPlanHomeSection(
                                      snapshot: todaySnapshot,
                                      onCategoryTap: (category) =>
                                          _openTodaysPlan(category: category),
                                      onViewFullPlan: () => _openTodaysPlan(),
                                      onRetry: _retryTodayPlan,
                                    );
                                  },
                                ),
                                const SizedBox(height: 28),
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

  Widget _buildHero(
    BuildContext context,
    AsyncSnapshot<_HomeData> snapshot,
    _HomeData data,
  ) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 760;
    final completion = _completionRate(data.progress);

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CSP11 LEARNING OS',
          style: TextStyle(
            color: _violet,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Good to see you.',
          style: TextStyle(
            color: _textPrimary,
            fontSize: isWide ? 30 : 26,
            fontWeight: FontWeight.w800,
            height: 1.08,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          snapshot.connectionState == ConnectionState.waiting
              ? 'Loading your current learning position…'
              : data.position == null
              ? 'Choose a domain, start learning, and CSP11 will keep your place.'
              : 'You are ${_progressPercent(data.position)} through '
                    '${data.position!.competencyId.toUpperCase()} • '
                    '${data.position!.subtopicTitle}.',
          style: TextStyle(
            color: _textMuted,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ],
    );

    final progress = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OVERALL PROGRESS',
          style: TextStyle(
            color: _textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$completion%',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'completed',
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 7,
            value: completion / 100,
            backgroundColor: const Color(0xFF22314A),
            valueColor: const AlwaysStoppedAnimation<Color>(_violet),
          ),
        ),
      ],
    );

    return StudentGlassSurface(
      width: double.infinity,
      padding: EdgeInsets.all(isWide ? 24 : 20),
      borderRadius: BorderRadius.circular(22),
      tint: _surface,
      borderColor: _border,
      shadowColor: Colors.black.withValues(alpha: 0.20),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 3, child: copy),
                const SizedBox(width: 24),
                SizedBox(width: 210, child: progress),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [copy, const SizedBox(height: 20), progress],
            ),
    );
  }

  Widget _buildContinueLearning(
    AsyncSnapshot<_HomeData> snapshot,
    _HomeData data,
  ) {
    final isLoading = snapshot.connectionState == ConnectionState.waiting;
    final position = data.position;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('CONTINUE CSP'),
        const SizedBox(height: 12),
        StudentGlassSurface(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          borderRadius: BorderRadius.circular(18),
          tint: _surface,
          borderColor: _border,
          shadowColor: Colors.black.withValues(alpha: 0.16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2941),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  position == null
                      ? Icons.menu_book_outlined
                      : Icons.play_arrow_rounded,
                  color: _blue,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLoading
                          ? 'Finding your place…'
                          : position == null
                          ? 'Start Domain 1'
                          : position.subtopicTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLoading
                          ? 'Loading your latest learning state'
                          : position == null
                          ? 'Begin your CSP11 learning path'
                          : '${position.competencyId.toUpperCase()} • '
                                '${position.topicTitle}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _textMuted, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: isLoading ? null : () => _continueLearning(position),
                style: FilledButton.styleFrom(
                  backgroundColor: _violet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(position == null ? 'START' : 'CONTINUE'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIntelligence(
    AsyncSnapshot<_HomeData> snapshot,
    _HomeData data,
  ) {
    final completed = data.progress.values.where((item) => item.completed).length;
    final total = data.progress.length;
    final remaining = total > completed ? total - completed : 0;

    return StudentGlassSurface(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(18),
      tint: _surface,
      borderColor: _border,
      shadowColor: Colors.black.withValues(alpha: 0.16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, color: _violet, size: 21),
              const SizedBox(width: 9),
              Text(
                'PROGRESS INTELLIGENCE',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (snapshot.connectionState == ConnectionState.waiting)
            _progressMessage(
              title: 'Reading your learning history',
              body: 'CSP11 is building your current progress snapshot.',
            )
          else if (snapshot.hasError)
            _progressMessage(
              title: 'Progress temporarily unavailable',
              body: 'Your learning data was not changed. Pull down to retry.',
            )
          else if (total == 0)
            _progressMessage(
              title: 'Your learning signal starts here',
              body:
                  'Complete your first subtopic and CSP11 will begin building '
                  'your progress picture.',
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$completed of $total tracked subtopics complete',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  remaining == 0
                      ? 'Everything currently tracked is complete. Open your '
                            'readiness plan for the next priority.'
                      : '$remaining tracked subtopics remain. Use your plan to '
                            'balance learning, practice, and recall.',
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _openExamReadiness,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                    label: const Text('VIEW EXAM READINESS'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _violet,
                      side: BorderSide(
                        color: _violet.withValues(alpha: 0.60),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _progressMessage({required String title, required String body}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: _textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          body,
          style: TextStyle(color: _textMuted, fontSize: 12.5, height: 1.4),
        ),
      ],
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor: _background.withValues(alpha: 0.94),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 62,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF15223A),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(Icons.shield_outlined, color: _violet, size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            'CSP11',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Settings',
          onPressed: widget.onOpenSettings,
          icon: Icon(Icons.settings_outlined, color: _textPrimary),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        color: _textMuted,
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.9,
      ),
    );
  }

  double _pageHorizontal(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) return 42;
    if (width >= 760) return 28;
    return 18;
  }

  int _completionRate(Map<String, StudentSubtopicProgress> progress) {
    if (progress.isEmpty) return 0;
    final completed = progress.values.where((item) => item.completed).length;
    return ((completed / progress.length) * 100).round().clamp(0, 100);
  }

  int _progressPercent(StudentLearningPosition? position) {
    if (position == null || position.subtopicCount <= 0) return 0;
    return (((position.subtopicIndex + 1) / position.subtopicCount) * 100)
        .round()
        .clamp(0, 100);
  }
}

class _HomeData {
  final StudentLearningPosition? position;
  final Map<String, StudentSubtopicProgress> progress;

  const _HomeData({required this.position, required this.progress});
  const _HomeData.empty() : position = null, progress = const {};
}
