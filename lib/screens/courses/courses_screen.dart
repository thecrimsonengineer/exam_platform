import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';
import 'csp/csp_overview_screen.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  static const double _overallProgress = 0.72;

  static const _domains = <_DomainData>[
    _DomainData(
      number: '01',
      title: 'Foundation & General Knowledge',
      progress: .82,
      color: Color(0xFF3157A4),
    ),
    _DomainData(
      number: '02',
      title: 'Risk Management',
      progress: .64,
      color: Color(0xFF4C73B8),
    ),
    _DomainData(
      number: '03',
      title: 'Emergency Preparedness',
      progress: .47,
      color: Color(0xFF667EB0),
    ),
    _DomainData(
      number: '04',
      title: 'Environmental Management',
      progress: .31,
      color: Color(0xFF7D62B4),
    ),
    _DomainData(
      number: '05',
      title: 'Occupational Health',
      progress: .22,
      color: Color(0xFFC7862E),
    ),
    _DomainData(
      number: '06',
      title: 'Training & Education',
      progress: .14,
      color: Color(0xFF6F7D92),
    ),
    _DomainData(
      number: '07',
      title: 'Safety & Health Program Management',
      progress: .08,
      color: Color(0xFF65748A),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F7FB),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 18,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Courses'),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final wide = width >= 1200;
          final tablet = width >= 760 && width < 1200;
          final horizontal = wide
              ? 34.0
              : tablet
                  ? 24.0
                  : 16.0;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              horizontal,
              10,
              horizontal,
              44,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _pageHeader(wide),
                    const SizedBox(height: 20),
                    _hero(context, width, wide),
                    const SizedBox(height: 18),
                    _learningPulse(wide, tablet),
                    const SizedBox(height: 18),
                    _continueLearning(context, wide),
                    const SizedBox(height: 18),
                    _domainJourney(context, width),
                    const SizedBox(height: 18),
                    _learningModes(context, width),
                    const SizedBox(height: 18),
                    _readinessPanel(width),
                    const SizedBox(height: 18),
                    _academyExpansion(width),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _pageHeader(bool wide) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR LEARNING COMMAND CENTER',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Build your CSP11 journey.',
                style: AppTextStyles.heading.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Text(
                  'Study strategically, practice deliberately, and turn every completed session into measurable exam readiness.',
                  style: AppTextStyles.body.copyWith(
                    color: const Color(0xFF687387),
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (wide) ...[
          const SizedBox(width: 20),
          _topBadge(),
        ],
      ],
    );
  }

  Widget _topBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: AppColors.primary,
              size: 17,
            ),
          ),
          const SizedBox(width: 9),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CSP11',
                style: TextStyle(
                  color: Color(0xFF172033),
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
              Text(
                'CERTIFICATION TRACK',
                style: TextStyle(
                  color: Color(0xFF7B8493),
                  fontSize: 7.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hero(
    BuildContext context,
    double width,
    bool wide,
  ) {
    final desktop = width >= 1050;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(wide ? 28 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D1A31),
            Color(0xFF173E76),
            Color(0xFF2B5FB0),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x20101D36),
            blurRadius: 34,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -55,
            top: -75,
            child: _decorCircle(
              230,
              const Color(0x4498B9FF),
            ),
          ),
          Positioned(
            right: 120,
            bottom: -105,
            child: _decorCircle(
              210,
              const Color(0x227E5DFF),
            ),
          ),
          if (desktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _heroCopy(context),
                ),
                const SizedBox(width: 24),
                SizedBox(
                  width: 370,
                  child: _heroProgress(),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heroCopy(context),
                const SizedBox(height: 22),
                _heroProgress(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _decorCircle(
    double size,
    Color color,
  ) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: Colors.white.withValues(alpha: .05),
            width: 18,
          ),
        ),
      ),
    );
  }

  Widget _heroCopy(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heroPill(),
        const SizedBox(height: 15),
        const Text(
          'CSP 11',
          style: TextStyle(
            color: Colors.white,
            fontSize: 38,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Certified Safety Professional',
          style: TextStyle(
            color: Color(0xFFD8E4F7),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 13),
        Text(
          'A structured pathway for concept mastery, question practice, domain coverage, and full-exam confidence.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: .69),
            fontSize: 12,
            height: 1.55,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            _HeroStat(label: 'DOMAINS', value: '7'),
            _HeroStat(label: 'QUESTIONS', value: '1,850+'),
            _HeroStat(label: 'PROGRESS', value: '72%'),
          ],
        ),
        const SizedBox(height: 21),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CSPOverviewScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.arrow_forward_rounded,
                size: 16,
              ),
              label: const Text('CONTINUE CSP11'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF172A4C),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(
                Icons.insights_rounded,
                size: 16,
              ),
              label: const Text('VIEW PROGRESS'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.white.withValues(alpha: .22),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _heroPill() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .075),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: Colors.white.withValues(alpha: .09),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium_outlined,
            color: Color(0xFFB8C9E9),
            size: 13,
          ),
          SizedBox(width: 5),
          Text(
            'CERTIFICATION TRACK',
            style: TextStyle(
              color: Color(0xFFB8C9E9),
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroProgress() {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .055),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: Colors.white.withValues(alpha: .09),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CERTIFICATION PROGRESS',
            style: TextStyle(
              color: Color(0xFF9FB3D8),
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: const [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: _overallProgress,
                        strokeWidth: 9,
                        backgroundColor: Color(0x223E609B),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(
                          Color(0xFFFFC21A),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '72%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'PROGRESS',
                          style: TextStyle(
                            color: Color(0xFF9FB3D8),
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .7,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _MiniProgress(
                      label: 'Content',
                      value: .78,
                    ),
                    SizedBox(height: 12),
                    _MiniProgress(
                      label: 'Practice',
                      value: .66,
                    ),
                    SizedBox(height: 12),
                    _MiniProgress(
                      label: 'Readiness',
                      value: .71,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Container(
            width: double.infinity,
            height: 1,
            color: Colors.white.withValues(alpha: .08),
          ),
          const SizedBox(height: 13),
          const Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFFFFC21A),
                size: 14,
              ),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Strongest momentum: Domain 01',
                  style: TextStyle(
                    color: Color(0xC5FFFFFF),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _learningPulse(
    bool wide,
    bool tablet,
  ) {
    final stack = !wide || tablet;

    return _sectionCard(
      title: 'LEARNING PULSE',
      subtitle: 'Your current momentum at a glance.',
      icon: Icons.insights_rounded,
      child: stack
          ? Column(
              children: [
                _pulseMetric(
                  'STUDY PROGRESS',
                  '72%',
                  'Overall CSP11 pathway',
                  Icons.track_changes_rounded,
                ),
                const Divider(height: 26),
                _pulseMetric(
                  'QUESTIONS TODAY',
                  '126',
                  '+18% from last week',
                  Icons.quiz_outlined,
                ),
                const Divider(height: 26),
                _pulseMetric(
                  'CURRENT STREAK',
                  '12 days',
                  'Keep the momentum',
                  Icons.local_fire_department_outlined,
                ),
                const Divider(height: 26),
                _pulseMetric(
                  'STRONGEST AREA',
                  'Domain 01',
                  '82% coverage',
                  Icons.workspace_premium_outlined,
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: _pulseMetric(
                    'STUDY PROGRESS',
                    '72%',
                    'Overall CSP11 pathway',
                    Icons.track_changes_rounded,
                  ),
                ),
                _verticalDivider(),
                Expanded(
                  child: _pulseMetric(
                    'QUESTIONS TODAY',
                    '126',
                    '+18% from last week',
                    Icons.quiz_outlined,
                  ),
                ),
                _verticalDivider(),
                Expanded(
                  child: _pulseMetric(
                    'CURRENT STREAK',
                    '12 days',
                    'Keep the momentum',
                    Icons.local_fire_department_outlined,
                  ),
                ),
                _verticalDivider(),
                Expanded(
                  child: _pulseMetric(
                    'STRONGEST AREA',
                    'Domain 01',
                    '82% coverage',
                    Icons.workspace_premium_outlined,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _continueLearning(
    BuildContext context,
    bool wide,
  ) {
    return _sectionCard(
      title: 'CONTINUE LEARNING',
      subtitle: 'Pick up exactly where you stopped.',
      icon: Icons.play_circle_outline_rounded,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F8FC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE4E9F1),
          ),
        ),
        child: wide
            ? Row(
                children: [
                  _continueIcon(),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: _ContinueCopy(),
                  ),
                  const SizedBox(width: 18),
                  _continueButton(context),
                ],
              )
            : Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _continueIcon(),
                  const SizedBox(height: 13),
                  const _ContinueCopy(),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: _continueButton(context),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _continueIcon() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFEDF2FF),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Icon(
        Icons.play_arrow_rounded,
        color: Color(0xFF3157A4),
        size: 27,
      ),
    );
  }

  Widget _continueButton(
    BuildContext context,
  ) {
    return SizedBox(
      width: 160,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CSPOverviewScreen(),
            ),
          );
        },
        icon: const Icon(
          Icons.arrow_forward_rounded,
          size: 15,
        ),
        label: const Text('CONTINUE'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 17,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
    );
  }

  Widget _domainJourney(
    BuildContext context,
    double width,
  ) {
    final columns = width >= 1200
        ? 3
        : width >= 700
            ? 2
            : 1;

    return _sectionCard(
      title: 'CSP11 DOMAIN JOURNEY',
      subtitle:
          'Seven examination domains, one structured pathway.',
      icon: Icons.account_tree_rounded,
      trailing: _sectionBadge(),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _domains.length,
        gridDelegate:
            SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio:
              columns == 1 ? 3.0 : 1.7,
        ),
        itemBuilder: (context, index) {
          return _domainCard(
            context,
            _domains[index],
          );
        },
      ),
    );
  }

  Widget _sectionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(9),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.route_rounded,
            size: 12,
            color: AppColors.primary,
          ),
          SizedBox(width: 4),
          Text(
            '7 DOMAINS',
            style: TextStyle(
              color: Color(0xFF3157A4),
              fontSize: 7,
              fontWeight: FontWeight.w900,
              letterSpacing: .6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _domainCard(
    BuildContext context,
    _DomainData domain,
  ) {
    final percent =
        (domain.progress * 100).round();
    final status = _statusFor(domain.progress);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CSPOverviewScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: domain.color.withValues(alpha: .11),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    domain.color.withValues(alpha: .05),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: domain.color
                          .withValues(alpha: .09),
                      borderRadius:
                          BorderRadius.circular(13),
                    ),
                    child: Text(
                      domain.number,
                      style: TextStyle(
                        color: domain.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DOMAIN ${domain.number}',
                          style: TextStyle(
                            color: domain.color,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          domain.title,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF172033),
                            fontSize: 10.5,
                            height: 1.2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$percent%',
                    style: TextStyle(
                      color: domain.color,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: domain.progress,
                  minHeight: 6,
                  backgroundColor:
                      const Color(0xFFE9EDF3),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(
                    domain.color,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    status.icon,
                    size: 12,
                    color: domain.color,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    status.label,
                    style: TextStyle(
                      color: domain.color,
                      fontSize: 7.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .75,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: Color(0xFF9AA3B2),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  _StatusInfo _statusFor(double progress) {
    if (progress >= .75) {
      return const _StatusInfo(
        'STRONG',
        Icons.check_circle_outline_rounded,
      );
    }
    if (progress >= .50) {
      return const _StatusInfo(
        'IN PROGRESS',
        Icons.timelapse_rounded,
      );
    }
    if (progress >= .25) {
      return const _StatusInfo(
        'NEEDS FOCUS',
        Icons.arrow_forward_rounded,
      );
    }
    return const _StatusInfo(
      'NOT STARTED',
      Icons.lock_outline_rounded,
    );
  }

  Widget _learningModes(
    BuildContext context,
    double width,
  ) {
    final columns = width >= 1200
        ? 3
        : width >= 760
            ? 2
            : 1;

    return _sectionCard(
      title: 'CHOOSE YOUR MODE',
      subtitle:
          'Use the pathway that matches your current goal.',
      icon: Icons.tune_rounded,
      child: GridView.count(
        shrinkWrap: true,
        physics:
            const NeverScrollableScrollPhysics(),
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio:
            columns == 1 ? 3.0 : 2.0,
        children: [
          _modeCard(
            context,
            Icons.menu_book_rounded,
            'STUDY',
            'Structured notes and core concepts.',
            const Color(0xFF3157A4),
          ),
          _modeCard(
            context,
            Icons.quiz_outlined,
            'PRACTICE',
            'Target weak areas with focused questions.',
            const Color(0xFF7257B7),
          ),
          _modeCard(
            context,
            Icons.timer_outlined,
            'EXAM',
            'Build full exam readiness under pressure.',
            const Color(0xFFD18B2D),
          ),
        ],
      ),
    );
  }

  Widget _modeCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CSPOverviewScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color.withValues(alpha: .10),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color:
                      color.withValues(alpha: .09),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF596477),
                        fontSize: 9.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.arrow_forward_rounded,
                color: color,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _readinessPanel(double width) {
    final desktop = width >= 1050;

    return _sectionCard(
      title: 'CERTIFICATION READINESS',
      subtitle:
          'A high-level view of your current preparation.',
      icon: Icons.verified_user_outlined,
      child: desktop
          ? Row(
              children: [
                SizedBox(
                  width: 155,
                  height: 155,
                  child: _readinessRing(),
                ),
                const SizedBox(width: 28),
                Expanded(
                  child: Column(
                    children: [
                      _readinessRow(
                        'Content completion',
                        .72,
                      ),
                      _readinessRow(
                        'Question mastery',
                        .68,
                      ),
                      _readinessRow(
                        'Domain coverage',
                        .74,
                      ),
                      _readinessRow(
                        'Mock exam performance',
                        .81,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 28),
                SizedBox(
                  width: 250,
                  child: _readinessInsight(),
                ),
              ],
            )
          : Column(
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: _readinessRing(),
                ),
                const SizedBox(height: 24),
                _readinessRow(
                  'Content completion',
                  .72,
                ),
                _readinessRow(
                  'Question mastery',
                  .68,
                ),
                _readinessRow(
                  'Domain coverage',
                  .74,
                ),
                _readinessRow(
                  'Mock exam performance',
                  .81,
                ),
                const SizedBox(height: 6),
                _readinessInsight(),
              ],
            ),
    );
  }

  Widget _readinessRing() {
    return Stack(
      alignment: Alignment.center,
      children: const [
        SizedBox.expand(
          child: CircularProgressIndicator(
            value: .74,
            strokeWidth: 11,
            backgroundColor:
                Color(0xFFE9EDF3),
            valueColor:
                AlwaysStoppedAnimation<Color>(
              Color(0xFF3157A4),
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '74%',
              style: TextStyle(
                color: Color(0xFF172033),
                fontSize: 29,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'READINESS',
              style: TextStyle(
                color: Color(0xFF7A8495),
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _readinessRow(
    String label,
    double value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF3E4859),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 7,
                backgroundColor:
                    const Color(0xFFE9EDF3),
                valueColor:
                    const AlwaysStoppedAnimation<
                        Color>(
                  Color(0xFF3157A4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 34,
            child: Text(
              '${(value * 100).round()}%',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF172033),
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _readinessInsight() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FC),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE1E7F1),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'NEXT BEST ACTION',
            style: TextStyle(
              color: Color(0xFF3157A4),
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Strengthen Domain 04',
            style: TextStyle(
              color: Color(0xFF172033),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Your current coverage is 31%. Focused study and practice here can raise overall readiness.',
            style: TextStyle(
              color: Color(0xFF6F7888),
              fontSize: 9.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF3157A4)
                      .withValues(alpha: .08),
                  borderRadius:
                      BorderRadius.circular(8),
                ),
                child: const Text(
                  'RECOMMENDED',
                  style: TextStyle(
                    color: Color(0xFF3157A4),
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 15,
                color: Color(0xFF3157A4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _academyExpansion(double width) {
    const courses = [
      ('ASP', 'Associate Safety Professional'),
      ('NEBOSH IDIP', 'International Diploma'),
      ('NEBOSH IGC',
          'International General Certificate'),
      ('CRSP',
          'Canadian Registered Safety Professional'),
      ('IOSH', 'Professional Safety Training'),
      ('OPITO', 'Offshore Safety Training'),
    ];

    final compact = width < 720;
    final cardWidth = compact
        ? width - 68
        : 270.0;

    return _sectionCard(
      title: 'EXPANDING THE ACADEMY',
      subtitle:
          'Additional certification pathways are being prepared.',
      icon: Icons.auto_awesome_outlined,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: courses.map((course) {
          return SizedBox(
            width: cardWidth > 270 ? 270 : cardWidth,
            child: Container(
              padding:
                  const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:
                    const Color(0xFFF8F9FB),
                borderRadius:
                    BorderRadius.circular(15),
                border: Border.all(
                  color: const Color(0xFFE5E8EF),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFECEFF4),
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      color: Color(0xFF8993A3),
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.$1,
                          style: const TextStyle(
                            color:
                                Color(0xFF273247),
                            fontSize: 10,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          course.$2,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            color:
                                Color(0xFF7A8495),
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: const Color(0xFFE3E8F0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFEEF3FF),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF172033),
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w900,
                        letterSpacing: .3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF7A8495),
                        fontSize: 8.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 10),
                trailing,
              ],
            ],
          ),
          const SizedBox(height: 17),
          child,
        ],
      ),
    );
  }

  Widget _pulseMetric(
    String title,
    String value,
    String subtitle,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF3FF),
            borderRadius:
                BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 18,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF7A8495),
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF8993A3),
                  fontSize: 7.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 48,
      margin:
          const EdgeInsets.symmetric(horizontal: 14),
      color: const Color(0xFFE7EAF0),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeroStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .055),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: Colors.white.withValues(alpha: .07),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF9FB3D8),
              fontSize: 7,
              fontWeight: FontWeight.w800,
              letterSpacing: .7,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniProgress extends StatelessWidget {
  final String label;
  final double value;

  const _MiniProgress({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFB8C9E9),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius:
              BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 5,
            backgroundColor:
                const Color(0x223E609B),
            valueColor:
                const AlwaysStoppedAnimation<
                    Color>(
              Color(0xFF9DB6E5),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContinueCopy extends StatelessWidget {
  const _ContinueCopy();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          'DOMAIN 01 • ADVANCED APPLICATIOONS OF SAFETY PRINCIPLES',
          style: TextStyle(
            color: Color(0xFF3157A4),
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: .8,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Continue your current study session',
          style: TextStyle(
            color: Color(0xFF172033),
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Last opened: Risk Evaluation Methods • 68% through this section',
          style: TextStyle(
            color: Color(0xFF737D8D),
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

class _DomainData {
  final String number;
  final String title;
  final double progress;
  final Color color;

  const _DomainData({
    required this.number,
    required this.title,
    required this.progress,
    required this.color,
  });
}

class _StatusInfo {
  final String label;
  final IconData icon;

  const _StatusInfo(this.label, this.icon);
}
