import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../models/student_progress_dashboard.dart';
import '../../services/student_progress_dashboard_service.dart';

class DarkProgressScreen extends StatefulWidget {
  final Future<StudentProgressDashboard> Function()? loadDashboard;

  const DarkProgressScreen({super.key, this.loadDashboard});

  @override
  State<DarkProgressScreen> createState() => DarkProgressScreenState();
}

class DarkProgressScreenState extends State<DarkProgressScreen> {
  static const _background = Color(0xFF0A111D);
  static const _surface = Color(0xFF111B2C);
  static const _navy = Color(0xFF5F93D8);
  static const _blue = Color(0xFF6EA8FF);
  static const _violet = Color(0xFF9A7CF4);
  static const _textPrimary = Color(0xFFF4F7FB);
  static const _textMuted = Color(0xFFA5B1C4);
  static const _border = Color(0xFF25344A);
  static const _green = Color(0xFF1F8A4C);
  static const _amber = Color(0xFFE59A24);

  final StudentProgressDashboardService _service =
      const StudentProgressDashboardService();

  late Future<StudentProgressDashboard> _future;
  final Set<String> _expandedDomains = <String>{};
  bool _seededExpansion = false;

  @override
  void initState() {
    super.initState();
    _future = _loadDashboard();
  }

  Future<StudentProgressDashboard> _loadDashboard() {
    final loader = widget.loadDashboard;

    if (loader != null) {
      return loader();
    }

    return _service.loadDashboard();
  }

  Future<void> refresh() async {
    final next = _loadDashboard();

    if (mounted) {
      setState(() {
        _future = next;
      });
    }

    await next;
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
          child: FutureBuilder<StudentProgressDashboard>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoading();
              }

              if (snapshot.hasError || snapshot.data == null) {
                return _buildError();
              }

              final dashboard = snapshot.data!;
              _seedExpansion(dashboard);

              return RefreshIndicator(
                onRefresh: refresh,
                child: _buildDashboard(context, dashboard),
              );
            },
          ),
        ),
      ),
    );
  }

  void _seedExpansion(StudentProgressDashboard dashboard) {
    if (_seededExpansion) {
      return;
    }

    _seededExpansion = true;

    StudentDomainProgress? preferred;

    for (final domain in dashboard.domains) {
      if (domain.inProgress) {
        preferred = domain;
        break;
      }
    }

    preferred ??= dashboard.nextDomain;

    if (preferred != null) {
      _expandedDomains.add(preferred.domainId);
    }
  }

  Widget _buildDashboard(
    BuildContext context,
    StudentProgressDashboard dashboard,
  ) {
    return CustomScrollView(
      key: const PageStorageKey<String>('csp11-progress-scroll'),
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
            48,
          ),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHero(context, dashboard),
                    const SizedBox(height: 24),
                    _buildSummaryGrid(context, dashboard),
                    const SizedBox(height: 28),
                    _buildExplainer(),
                    const SizedBox(height: 30),
                    _sectionHeading(
                      eyebrow: 'DOMAIN PROGRESS',
                      title: 'See exactly where you stand',
                      subtitle:
                          'Open a domain to inspect its competencies, Topics, Subtopics, and completed questions.',
                    ),
                    const SizedBox(height: 14),
                    ...dashboard.domains.map(_buildDomainCard),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
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
      automaticallyImplyLeading: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: _background.withValues(alpha: 0.96),
      surfaceTintColor: Colors.transparent,
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
              Icons.insights_rounded,
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
            'Progress',
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
            tooltip: 'Refresh progress',
            onPressed: refresh,
            icon: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: _textPrimary,
                size: 19,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHero(BuildContext context, StudentProgressDashboard dashboard) {
    final percentage = (dashboard.overallProgress * 100).round();
    final compact = MediaQuery.sizeOf(context).width < 650;

    return Container(
      key: const ValueKey('progress-hero'),
      width: double.infinity,
      constraints: BoxConstraints(minHeight: compact ? 340 : 310),
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
        children: [
          Positioned(
            top: -70,
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
            right: compact ? 4 : 34,
            bottom: compact ? -8 : 28,
            child: IgnorePointer(
              child: Icon(
                Icons.insights_rounded,
                size: compact ? 120 : 160,
                color: Colors.white.withValues(alpha: 0.045),
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final heroCompact = constraints.maxWidth < 620;

              final copy = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _heroPill(
                    icon: Icons.track_changes_rounded,
                    text: 'LEARNING PROGRESS',
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '$percentage%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 50,
                      height: 0.95,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Overall Subtopic completion',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Text(
                      'A clear view of your CSP11 journey from Domains down to Topics, Subtopics, and the questions you have answered.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: dashboard.overallProgress,
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.16),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                ],
              );

              final ring = _ProgressRing(
                progress: dashboard.overallProgress,
                percentage: percentage,
              );

              if (heroCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [copy, const SizedBox(height: 22), ring],
                );
              }

              return Row(
                children: [
                  Expanded(child: copy),
                  const SizedBox(width: 32),
                  ring,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _heroPill({required IconData icon, required String text}) {
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
          Icon(icon, color: Colors.white.withValues(alpha: 0.92), size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.94),
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(
    BuildContext context,
    StudentProgressDashboard dashboard,
  ) {
    final items = [
      _SummaryData(
        icon: Icons.shield_rounded,
        label: 'DOMAINS',
        value: '${dashboard.completedDomains}/7',
        caption: 'completed',
        accent: _blue,
        tint: const Color(0xFF14243B),
      ),
      _SummaryData(
        icon: Icons.layers_rounded,
        label: 'TOPICS',
        value: '${dashboard.completedTopics}/${dashboard.totalTopics}',
        caption: 'completed',
        accent: _violet,
        tint: const Color(0xFF1D1934),
      ),
      _SummaryData(
        icon: Icons.check_circle_rounded,
        label: 'SUBTOPICS',
        value: '${dashboard.completedSubtopics}/${dashboard.totalSubtopics}',
        caption: 'completed',
        accent: _green,
        tint: const Color(0xFF13271D),
      ),
      _SummaryData(
        icon: Icons.quiz_rounded,
        label: 'QUESTIONS',
        value: '${dashboard.answeredQuestions}',
        caption: 'unique answered',
        accent: const Color(0xFFB66A1F),
        tint: const Color(0xFF2A2015),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 920
            ? 4
            : constraints.maxWidth >= 560
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
                  height: 132,
                  child: _summaryCard(item),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _summaryCard(_SummaryData item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.045),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: item.tint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: item.accent, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    color: item.accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.value,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.35,
                  ),
                ),
                Text(
                  item.caption,
                  style: const TextStyle(
                    color: _textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplainer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF101A2A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HOW TO READ YOUR PROGRESS',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _legendItem(
                icon: Icons.check_circle_rounded,
                color: _green,
                label: 'Completed',
              ),
              _legendItem(
                icon: Icons.timelapse_rounded,
                color: _amber,
                label: 'In Progress',
              ),
              _legendItem(
                icon: Icons.radio_button_unchecked_rounded,
                color: _textMuted,
                label: 'Not Started',
              ),
              _legendItem(
                icon: Icons.quiz_outlined,
                color: _violet,
                label: 'Question submitted',
              ),
            ],
          ),
          const SizedBox(height: 11),
          const Text(
            'Topic completion is derived from its Subtopics. Question completion is tracked separately and means you submitted an answer to that unique question at least once.',
            style: TextStyle(color: _textMuted, fontSize: 10.5, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _legendItem({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading({
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

  Widget _buildDomainCard(StudentDomainProgress domain) {
    final expanded = _expandedDomains.contains(domain.domainId);
    final percentage = (domain.subtopicProgress * 100).round();
    final status = domain.completed
        ? 'COMPLETED'
        : domain.inProgress
        ? 'IN PROGRESS'
        : 'NOT STARTED';

    final statusColor = domain.completed
        ? _green
        : domain.inProgress
        ? _amber
        : _textMuted;

    return Container(
      key: ValueKey('progress-domain-${domain.domainNumber}'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: expanded ? AppColors.primary.withValues(alpha: 0.24) : _border,
        ),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: expanded ? 0.075 : 0.04),
            blurRadius: expanded ? 22 : 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  if (expanded) {
                    _expandedDomains.remove(domain.domainId);
                  } else {
                    _expandedDomains.add(domain.domainId);
                  }
                });
              },
              borderRadius: BorderRadius.circular(22),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [_navy, _blue],
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            domain.domainNumber.toString().padLeft(2, '0'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'DOMAIN ${domain.domainNumber.toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.9,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _statusPill(status, statusColor),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                domain.title,
                                style: const TextStyle(
                                  color: _textPrimary,
                                  fontSize: 15,
                                  height: 1.25,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$percentage%',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Icon(
                              expanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: _textMuted,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _progressLine(
                      label: 'Subtopics',
                      value:
                          '${domain.completedSubtopics}/${domain.subtopicCount}',
                      progress: domain.subtopicProgress,
                      accent: _blue,
                    ),
                    const SizedBox(height: 11),
                    _progressLine(
                      label: 'Topics',
                      value: '${domain.completedTopics}/${domain.topicCount}',
                      progress: domain.topicProgress,
                      accent: _violet,
                    ),
                    const SizedBox(height: 13),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _miniMetric(
                          Icons.account_tree_outlined,
                          '${domain.competencyCount} competencies',
                        ),
                        _miniMetric(
                          Icons.quiz_outlined,
                          '${domain.answeredQuestions} questions completed',
                        ),
                        _miniMetric(
                          Icons.verified_outlined,
                          '${domain.correctQuestions} correct',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded) ...[
            Container(height: 1, color: _border.withValues(alpha: 0.9)),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 17, 18, 20),
              child: _buildDomainDetails(domain),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 7.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.55,
        ),
      ),
    );
  }

  Widget _progressLine({
    required String label,
    required String value,
    required double progress,
    required Color accent,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 74,
          child: Text(
            label,
            style: const TextStyle(
              color: _textMuted,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: const Color(0xFF162238),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 58,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniMetric(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF101A2A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: _textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDomainDetails(StudentDomainProgress domain) {
    if (domain.competencies.isEmpty) {
      return const Text(
        'No published learning content is available in this domain yet.',
        style: TextStyle(color: _textMuted, fontSize: 10.5),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TOPIC-BY-TOPIC BREAKDOWN',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.9,
          ),
        ),
        const SizedBox(height: 12),
        ...domain.competencies.map(_buildCompetencyDetail),
      ],
    );
  }

  Widget _buildCompetencyDetail(StudentCompetencyProgressDetail competency) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF101A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COMPETENCY ${competency.competencyNumber.toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            competency.title,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 12.5,
              height: 1.3,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _miniMetric(
                Icons.layers_outlined,
                '${competency.completedTopics}/${competency.topicCount} topics',
              ),
              _miniMetric(
                Icons.check_circle_outline_rounded,
                '${competency.completedSubtopics}/${competency.subtopicCount} subtopics',
              ),
              _miniMetric(
                Icons.quiz_outlined,
                '${competency.answeredQuestions} questions',
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...competency.topics.map(_buildTopicDetail),
        ],
      ),
    );
  }

  Widget _buildTopicDetail(StudentTopicProgressDetail topic) {
    final statusColor = topic.completed
        ? _green
        : topic.inProgress
        ? _amber
        : _textMuted;

    final statusIcon = topic.completed
        ? Icons.check_circle_rounded
        : topic.inProgress
        ? Icons.timelapse_rounded
        : Icons.radio_button_unchecked_rounded;

    return Container(
      key: ValueKey('progress-topic-${topic.topicId}'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(statusIcon, color: statusColor, size: 18),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  topic.title,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 11.5,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _topicMetric(
                'SUBTOPICS',
                '${topic.completedSubtopics}/${topic.subtopicCount}',
                statusColor,
              ),
              _topicMetric(
                'QUESTIONS COMPLETED',
                '${topic.answeredQuestions}',
                _violet,
              ),
              _topicMetric('CORRECT', '${topic.correctQuestions}', _green),
            ],
          ),
          if (topic.subtopics.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: topic.subtopics.map(_subtopicPill).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _topicMetric(String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontSize: 7.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.45,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _subtopicPill(StudentSubtopicProgressDetail subtopic) {
    final color = subtopic.completed
        ? _green
        : subtopic.inProgress
        ? _amber
        : _textMuted;

    final icon = subtopic.completed
        ? Icons.check_rounded
        : subtopic.inProgress
        ? Icons.more_horiz_rounded
        : Icons.circle_outlined;

    return Tooltip(
      message:
          '${subtopic.title}\n${subtopic.answeredQuestions} questions completed',
      child: Container(
        constraints: const BoxConstraints(maxWidth: 245),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                subtopic.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        _buildAppBar(),
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }

  Widget _buildError() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        _buildAppBar(),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.insights_rounded,
                      size: 44,
                      color: _textMuted,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Progress could not be loaded',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Pull to refresh or try again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _textMuted, fontSize: 11),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: refresh,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('TRY AGAIN'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryData {
  final IconData icon;
  final String label;
  final String value;
  final String caption;
  final Color accent;
  final Color tint;

  const _SummaryData({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    required this.accent,
    required this.tint,
  });
}

class _ProgressRing extends StatelessWidget {
  final double progress;
  final int percentage;

  const _ProgressRing({required this.progress, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 136,
      height: 136,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.075),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 9,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percentage%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'COMPLETE',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.62),
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
