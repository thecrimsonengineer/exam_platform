import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';
import '../../widgets/continue_learning_card.dart';
import '../../widgets/course_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String userName = 'Naveed';

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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: AppColors.primary,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Academy',
              style: TextStyle(
                color: Color(0xFF172033),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE3E8F0),
                ),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF536075),
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final wide = width >= 1180;
          final tablet = width >= 760 && width < 1180;
          final horizontal = wide
              ? 34.0
              : tablet
                  ? 24.0
                  : 16.0;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              horizontal,
              12,
              horizontal,
              44,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _hero(context, width),
                    const SizedBox(height: 18),
                    _snapshot(width),
                    const SizedBox(height: 18),
                    _continueLearning(context, width),
                    const SizedBox(height: 18),
                    _certifications(context, width),
                    const SizedBox(height: 18),
                    _quickPractice(context, width),
                    const SizedBox(height: 18),
                    _lowerDashboard(context, width),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _hero(BuildContext context, double width) {
    final desktop = width >= 950;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(width >= 1180 ? 30 : 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0C1930),
            Color(0xFF173C73),
            Color(0xFF2E61B4),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22101D36),
            blurRadius: 32,
            offset: Offset(0, 17),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -70,
            top: -85,
            child: _orb(230, const Color(0x4595B8FF)),
          ),
          Positioned(
            right: 150,
            bottom: -110,
            child: _orb(210, const Color(0x227D60E7)),
          ),
          if (desktop)
            Row(
              children: [
                Expanded(child: _heroCopy(context)),
                const SizedBox(width: 24),
                SizedBox(
                  width: 340,
                  child: _heroStatus(),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heroCopy(context),
                const SizedBox(height: 22),
                _heroStatus(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _orb(double size, Color color) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: Colors.white.withValues(alpha: .045),
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
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: Colors.white.withValues(alpha: .09),
            ),
          ),
          child: const Text(
            'PROFESSIONAL LEARNING ACADEMY',
            style: TextStyle(
              color: Color(0xFFB9CAE9),
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.15,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Good morning, $userName',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            height: 1.08,
            fontWeight: FontWeight.w900,
            letterSpacing: -.8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your professional learning journey, at a glance.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: .72),
            fontSize: 13,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 19),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            _HeroPill(
              icon: Icons.workspace_premium_outlined,
              text: '3 ACTIVE CERTIFICATIONS',
            ),
            _HeroPill(
              icon: Icons.local_fire_department_outlined,
              text: '12 DAY STREAK',
            ),
          ],
        ),
      ],
    );
  }

  Widget _heroStatus() {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .055),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: Colors.white.withValues(alpha: .09),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACADEMY SNAPSHOT',
            style: TextStyle(
              color: Color(0xFF9FB3D8),
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 14),
          Row(
            children: [
              _HeroMetric(
                value: '1,332',
                label: 'QUESTIONS',
              ),
              SizedBox(width: 22),
              _HeroMetric(
                value: '74%',
                label: 'READINESS',
              ),
            ],
          ),
          SizedBox(height: 16),
          _HeroBar(
            label: 'Overall learning',
            value: .72,
          ),
          SizedBox(height: 11),
          _HeroBar(
            label: 'Question progress',
            value: .72,
          ),
        ],
      ),
    );
  }

  Widget _snapshot(double width) {
    final stack = width < 700;

    final metrics = [
      _SnapshotData(
        'ACTIVE COURSES',
        '3',
        'Certifications in progress',
        Icons.library_books_outlined,
      ),
      _SnapshotData(
        'QUESTIONS',
        '1,332',
        'Questions completed',
        Icons.quiz_outlined,
      ),
      _SnapshotData(
        'STREAK',
        '12 days',
        'Keep the momentum',
        Icons.local_fire_department_outlined,
      ),
      _SnapshotData(
        'READINESS',
        '74%',
        'Overall preparation',
        Icons.track_changes_rounded,
      ),
    ];

    return _sectionCard(
      title: 'YOUR LEARNING SNAPSHOT',
      subtitle: 'A quick view of your current academy activity.',
      icon: Icons.insights_rounded,
      child: stack
          ? Column(
              children: _buildStackMetrics(metrics),
            )
          : Row(
              children: [
                for (var i = 0; i < metrics.length; i++) ...[
                  if (i > 0) _verticalDivider(),
                  Expanded(
                    child: _snapshotMetric(metrics[i]),
                  ),
                ],
              ],
            ),
    );
  }

  List<Widget> _buildStackMetrics(
    List<_SnapshotData> metrics,
  ) {
    final widgets = <Widget>[];

    for (var i = 0; i < metrics.length; i++) {
      if (i > 0) {
        widgets.add(
          const Divider(
            height: 25,
            color: Color(0xFFE7EAF0),
          ),
        );
      }
      widgets.add(_snapshotMetric(metrics[i]));
    }

    return widgets;
  }

  Widget _snapshotMetric(_SnapshotData data) {
    return Row(
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF3FF),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            data.icon,
            color: AppColors.primary,
            size: 19,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.label,
                style: const TextStyle(
                  color: Color(0xFF7A8495),
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.value,
                style: const TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                data.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

  Widget _continueLearning(
    BuildContext context,
    double width,
  ) {
    final desktop = width >= 900;

    return _sectionCard(
      title: 'CONTINUE LEARNING',
      subtitle: 'Pick up exactly where you stopped.',
      icon: Icons.play_circle_outline_rounded,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F8FD),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: const Color(0xFFE1E7F0),
          ),
        ),
        child: desktop
            ? Row(
                children: [
                  _courseLogo(
                    Icons.workspace_premium_rounded,
                    const Color(0xFF3157A4),
                  ),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: _ContinueCopy(),
                  ),
                  const SizedBox(width: 18),
                  _primaryButton(
                    context,
                    'CONTINUE',
                  ),
                ],
              )
            : Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _courseLogo(
                    Icons.workspace_premium_rounded,
                    const Color(0xFF3157A4),
                  ),
                  const SizedBox(height: 13),
                  const _ContinueCopy(),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: _primaryButton(
                      context,
                      'CONTINUE',
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _courseLogo(
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        icon,
        color: color,
        size: 27,
      ),
    );
  }

  Widget _primaryButton(
    BuildContext context,
    String label,
  ) {
    return SizedBox(
      width: 155,
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(
          Icons.arrow_forward_rounded,
          size: 15,
        ),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
    );
  }

  Widget _certifications(
    BuildContext context,
    double width,
  ) {
    final columns = width >= 1180
        ? 3
        : width >= 720
            ? 2
            : 1;

    return _sectionCard(
      title: 'MY CERTIFICATIONS',
      subtitle:
          'Your active professional learning pathways.',
      icon: Icons.workspace_premium_outlined,
      child: GridView.count(
        shrinkWrap: true,
        physics:
            const NeverScrollableScrollPhysics(),
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio:
            columns == 1 ? 3.0 : 1.85,
        children: [
          _certificationCard(
            context,
            title: 'CSP 11',
            subtitle:
                'Certified Safety Professional',
            progress: .72,
            completed: '1,332 / 1,850',
            icon: Icons.workspace_premium_rounded,
            color: const Color(0xFF3157A4),
            featured: true,
          ),
          _certificationCard(
            context,
            title: 'NEBOSH IG',
            subtitle:
                'International General Certificate',
            progress: .43,
            completed: '645 / 1,500',
            icon: Icons.public_rounded,
            color: const Color(0xFF7257B7),
          ),
          _certificationCard(
            context,
            title: 'ASP',
            subtitle:
                'Associate Safety Professional',
            progress: .15,
            completed: '165 / 1,100',
            icon: Icons.shield_outlined,
            color: const Color(0xFFC7862E),
          ),
        ],
      ),
    );
  }

  Widget _certificationCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required double progress,
    required String completed,
    required IconData icon,
    required Color color,
    bool featured = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(19),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: featured
                ? const Color(0xFFF7F9FE)
                : Colors.white,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: featured
                  ? color.withValues(alpha: .22)
                  : const Color(0xFFE4E8F0),
            ),
            boxShadow: [
              if (featured)
                BoxShadow(
                  color: color.withValues(alpha: .06),
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .09),
                      borderRadius:
                          BorderRadius.circular(13),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 21,
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
                            color: Color(0xFF172033),
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF7A8495),
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (featured)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .08),
                        borderRadius:
                            BorderRadius.circular(7),
                      ),
                      child: Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: color,
                          fontSize: 6.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .6,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    '${(progress * 100).round()}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor:
                            const Color(0xFFE8ECF2),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(
                          color,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  Text(
                    completed,
                    style: const TextStyle(
                      color: Color(0xFF7B8493),
                      fontSize: 7.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: color,
                    size: 14,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickPractice(
    BuildContext context,
    double width,
  ) {
    final columns = width >= 1000
        ? 3
        : width >= 680
            ? 2
            : 1;

    return _sectionCard(
      title: 'QUICK PRACTICE',
      subtitle:
          'Choose the fastest way to sharpen your skills.',
      icon: Icons.bolt_rounded,
      child: GridView.count(
        shrinkWrap: true,
        physics:
            const NeverScrollableScrollPhysics(),
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio:
            columns == 1 ? 3.0 : 2.05,
        children: [
          _practiceCard(
            'DAILY CHALLENGE',
            'A focused set to keep your momentum alive.',
            Icons.today_rounded,
            const Color(0xFF3157A4),
          ),
          _practiceCard(
            'WEAK AREAS',
            'Practice the topics where you need the most work.',
            Icons.track_changes_rounded,
            const Color(0xFF7257B7),
          ),
          _practiceCard(
            'RANDOM QUIZ',
            'Mix questions across your active preparation.',
            Icons.shuffle_rounded,
            const Color(0xFFC7862E),
          ),
        ],
      ),
    );
  }

  Widget _practiceCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(15),
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
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .09),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
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
                        letterSpacing: .8,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF667083),
                        fontSize: 9,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
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

  Widget _lowerDashboard(
    BuildContext context,
    double width,
  ) {
    final sideBySide = width >= 900;

    if (sideBySide) {
      return Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _recentActivity(),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: _professionalMomentum(),
          ),
        ],
      );
    }

    return Column(
      children: [
        _recentActivity(),
        const SizedBox(height: 18),
        _professionalMomentum(),
      ],
    );
  }

  Widget _recentActivity() {
    return _sectionCard(
      title: 'RECENT ACTIVITY',
      subtitle:
          'Your latest learning milestones.',
      icon: Icons.history_rounded,
      child: Column(
        children: const [
          _ActivityRow(
            icon: Icons.check_circle_outline_rounded,
            title: 'Completed CSP11 practice',
            subtitle: '20 questions • 85% score',
            time: 'Today',
          ),
          Divider(
            height: 22,
            color: Color(0xFFE7EAF0),
          ),
          _ActivityRow(
            icon: Icons.menu_book_rounded,
            title: 'Studied Risk Management',
            subtitle: 'Topic session • 34 minutes',
            time: 'Yesterday',
          ),
          Divider(
            height: 22,
            color: Color(0xFFE7EAF0),
          ),
          _ActivityRow(
            icon: Icons.local_fire_department_outlined,
            title: 'Extended your study streak',
            subtitle: '12 consecutive days',
            time: 'Yesterday',
          ),
        ],
      ),
    );
  }

  Widget _professionalMomentum() {
    return _sectionCard(
      title: 'PROFESSIONAL MOMENTUM',
      subtitle:
          'Keep building consistent learning habits.',
      icon: Icons.trending_up_rounded,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'THIS WEEK',
            style: TextStyle(
              color: Color(0xFF7A8495),
              fontSize: 7,
              fontWeight: FontWeight.w900,
              letterSpacing: .9,
            ),
          ),
          const SizedBox(height: 7),
          const Row(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              Text(
                '6h 42m',
                style: TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(width: 8),
              Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  '+18% vs last week',
                  style: TextStyle(
                    color: Color(0xFF3157A4),
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              _bar(0.42, 'M'),
              _bar(0.58, 'T'),
              _bar(0.78, 'W'),
              _bar(0.52, 'T'),
              _bar(0.91, 'F'),
              _bar(0.67, 'S'),
              _bar(0.35, 'S'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bar(double value, String label) {
    return Expanded(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 3),
        child: Column(
          children: [
            Container(
              height: 65,
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: value,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3157A4),
                    borderRadius:
                        BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8993A3),
                fontSize: 7,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
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
                  color: const Color(0xFFEEF3FF),
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
                        fontWeight: FontWeight.w900,
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
            ],
          ),
          const SizedBox(height: 17),
          child,
        ],
      ),
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

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroPill({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 7,
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
          Icon(
            icon,
            color: const Color(0xFFB8C9E9),
            size: 13,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFFB8C9E9),
              fontSize: 7,
              fontWeight: FontWeight.w900,
              letterSpacing: .7,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String value;
  final String label;

  const _HeroMetric({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF9FB3D8),
            fontSize: 7,
            fontWeight: FontWeight.w900,
            letterSpacing: .7,
          ),
        ),
      ],
    );
  }
}

class _HeroBar extends StatelessWidget {
  final String label;
  final double value;

  const _HeroBar({
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
                const AlwaysStoppedAnimation<Color>(
              Color(0xFF9DB6E5),
            ),
          ),
        ),
      ],
    );
  }
}

class _SnapshotData {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;

  const _SnapshotData(
    this.label,
    this.value,
    this.subtitle,
    this.icon,
  );
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
          'CSP 11 • CERTIFIED SAFETY PROFESSIONAL',
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
          '1,332 of 1,850 questions completed • 72% progress',
          style: TextStyle(
            color: Color(0xFF737D8D),
            fontSize: 9,
          ),
        ),
        SizedBox(height: 10),
        SizedBox(
          width: 330,
          child: ClipRRect(
            borderRadius:
                BorderRadius.all(Radius.circular(99)),
            child: LinearProgressIndicator(
              value: .72,
              minHeight: 6,
              backgroundColor: Color(0xFFE3E8F0),
              valueColor:
                  AlwaysStoppedAnimation<Color>(
                Color(0xFF3157A4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;

  const _ActivityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 37,
          height: 37,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF3FF),
            borderRadius: BorderRadius.circular(11),
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
                  color: Color(0xFF263247),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF7A8495),
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          time,
          style: const TextStyle(
            color: Color(0xFF9AA3B2),
            fontSize: 7,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
