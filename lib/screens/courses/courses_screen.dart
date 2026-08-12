import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';

import 'csp/csp_overview_screen.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  static const _domains = <_DomainData>[
    _DomainData(
      number: '01',
      title: 'Foundation & General Knowledge',
      progress: .82,
      status: 'Strong',
      color: Color(0xFF3157A4),
    ),
    _DomainData(
      number: '02',
      title: 'Risk Management',
      progress: .64,
      status: 'Developing',
      color: Color(0xFF4C73B8),
    ),
    _DomainData(
      number: '03',
      title: 'Emergency Preparedness',
      progress: .47,
      status: 'Developing',
      color: Color(0xFF6A86B9),
    ),
    _DomainData(
      number: '04',
      title: 'Environmental Management',
      progress: .31,
      status: 'Needs Focus',
      color: Color(0xFF8A6BC1),
    ),
    _DomainData(
      number: '05',
      title: 'Occupational Health',
      progress: .22,
      status: 'Needs Focus',
      color: Color(0xFFD18B2D),
    ),
    _DomainData(
      number: '06',
      title: 'Training & Education',
      progress: .14,
      status: 'Not Started',
      color: Color(0xFF7B879A),
    ),
    _DomainData(
      number: '07',
      title: 'Safety & Health Program Management',
      progress: .08,
      status: 'Not Started',
      color: Color(0xFF7B879A),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Courses'), elevation: 0),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1000;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              wide ? 32 : 16,
              24,
              wide ? 32 : 16,
              42,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1450),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _pageHeader(),
                    const SizedBox(height: 22),
                    _hero(context, wide),
                    const SizedBox(height: 20),
                    _learningPulse(wide),
                    const SizedBox(height: 20),
                    _continueLearning(context, wide),
                    const SizedBox(height: 20),
                    _domainJourney(context, wide),
                    const SizedBox(height: 20),
                    _learningModes(context, wide),
                    const SizedBox(height: 20),
                    _readinessPanel(wide),
                    const SizedBox(height: 28),
                    _comingSoonSection(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _pageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR LEARNING HUB',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        Text('Build your CSP11 journey.', style: AppTextStyles.heading),
        const SizedBox(height: 5),
        Text(
          'Choose a certification, continue where you left off, and track your readiness from one place.',
          style: AppTextStyles.body,
        ),
      ],
    );
  }

  Widget _hero(BuildContext context, bool wide) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(wide ? 28 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF101D36), Color(0xFF203B6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18101D36),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: wide
          ? Row(
              children: [
                Expanded(child: _heroCopy(context)),
                const SizedBox(width: 28),
                SizedBox(width: 340, child: _heroProgress()),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heroCopy(context),
                const SizedBox(height: 24),
                _heroProgress(),
              ],
            ),
    );
  }

  Widget _heroCopy(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: .08)),
          ),
          child: const Text(
            'CERTIFICATION TRACK',
            style: TextStyle(
              color: Color(0xFFB8C9E9),
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'CSP 11',
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: -.8,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Certified Safety Professional',
          style: TextStyle(
            color: Color(0xFFD8E2F5),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 13),
        Text(
          'Your complete certification pathway for structured study, targeted practice, and exam preparation.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: .68),
            fontSize: 11,
            height: 1.5,
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
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CSPOverviewScreen()),
            );
          },
          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
          label: const Text('CONTINUE CSP11'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF172A4C),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
        ),
      ],
    );
  }

  Widget _heroProgress() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .055),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .09)),
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
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              SizedBox(
                width: 92,
                height: 92,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: .72,
                        strokeWidth: 8,
                        backgroundColor: Color(0x223E609B),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF9DB6E5),
                        ),
                      ),
                    ),
                    const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '72%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'complete',
                          style: TextStyle(
                            color: Color(0xFF9FB3D8),
                            fontSize: 8,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MiniProgress(label: 'Content', value: .78),
                    SizedBox(height: 12),
                    _MiniProgress(label: 'Practice', value: .66),
                    SizedBox(height: 12),
                    _MiniProgress(label: 'Readiness', value: .71),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _learningPulse(bool wide) {
    return _sectionCard(
      title: 'LEARNING PULSE',
      subtitle: 'A quick snapshot of your current momentum.',
      icon: Icons.insights_rounded,
      child: wide
          ? Row(
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
            )
          : Column(
              children: [
                _pulseMetric(
                  'STUDY PROGRESS',
                  '72%',
                  'Overall CSP11 pathway',
                  Icons.track_changes_rounded,
                ),
                const Divider(height: 28),
                _pulseMetric(
                  'QUESTIONS TODAY',
                  '126',
                  '+18% from last week',
                  Icons.quiz_outlined,
                ),
                const Divider(height: 28),
                _pulseMetric(
                  'CURRENT STREAK',
                  '12 days',
                  'Keep the momentum',
                  Icons.local_fire_department_outlined,
                ),
                const Divider(height: 28),
                _pulseMetric(
                  'STRONGEST AREA',
                  'Domain 01',
                  '82% coverage',
                  Icons.workspace_premium_outlined,
                ),
              ],
            ),
    );
  }

  Widget _continueLearning(BuildContext context, bool wide) {
    return _sectionCard(
      title: 'CONTINUE LEARNING',
      subtitle: 'Pick up exactly where you stopped.',
      icon: Icons.play_circle_outline_rounded,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E9F0)),
        ),
        child: wide
            ? Row(
                children: [
                  _continueIcon(),
                  const SizedBox(width: 15),
                  const Expanded(child: _ContinueCopy()),
                  const SizedBox(width: 20),
                  _continueButton(context),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _continueIcon(),
                  const SizedBox(height: 13),
                  const _ContinueCopy(),
                  const SizedBox(height: 15),
                  _continueButton(context),
                ],
              ),
      ),
    );
  }

  Widget _domainJourney(BuildContext context, bool wide) {
    return _sectionCard(
      title: 'CSP11 DOMAIN JOURNEY',
      subtitle: 'Move through the seven examination domains.',
      icon: Icons.account_tree_rounded,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _domains.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: wide ? 3 : 1,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: wide ? 3.05 : 3.15,
        ),
        itemBuilder: (context, index) {
          final domain = _domains[index];
          return _domainCard(context, domain);
        },
      ),
    );
  }

  Widget _domainCard(BuildContext context, _DomainData domain) {
    final percent = (domain.progress * 100).round();

    final String status;
    final IconData statusIcon;

    if (domain.progress >= 0.75) {
      status = 'STRONG';
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (domain.progress >= 0.50) {
      status = 'IN PROGRESS';
      statusIcon = Icons.timelapse_rounded;
    } else if (domain.progress >= 0.25) {
      status = 'NEEDS FOCUS';
      statusIcon = Icons.arrow_forward_rounded;
    } else {
      status = 'NOT STARTED';
      statusIcon = Icons.lock_outline_rounded;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CSPOverviewScreen()),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFE3E7EE)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: domain.color.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  domain.number,
                  style: TextStyle(
                    color: domain.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'DOMAIN ${domain.number}',
                          style: TextStyle(
                            color: domain.color,
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),

                        const Spacer(),

                        Text(
                          '$percent%',
                          style: TextStyle(
                            color: domain.color,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 3),

                    Text(
                      domain.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF172033),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 7),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: domain.progress,
                        minHeight: 5,
                        backgroundColor: const Color(0xFFE9EDF3),
                        valueColor: AlwaysStoppedAnimation<Color>(domain.color),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Icon(statusIcon, size: 11, color: domain.color),
                        const SizedBox(width: 4),
                        Text(
                          status,
                          style: TextStyle(
                            color: domain.color,
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

              const SizedBox(width: 10),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 11,
                color: Color(0xFF9AA3B2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _learningModes(BuildContext context, bool wide) {
    return _sectionCard(
      title: 'CHOOSE YOUR MODE',
      subtitle: 'Use the pathway that matches your current goal.',
      icon: Icons.tune_rounded,
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: wide ? 3 : 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: wide ? 1.85 : 3.4,
        children: [
          _modeCard(
            context,
            icon: Icons.menu_book_rounded,
            title: 'STUDY',
            subtitle: 'Structured notes and core concepts.',
            color: const Color(0xFF3157A4),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CSPOverviewScreen()),
              );
            },
          ),
          _modeCard(
            context,
            icon: Icons.quiz_outlined,
            title: 'PRACTICE',
            subtitle: 'Target weak areas with focused questions.',
            color: const Color(0xFF7257B7),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CSPOverviewScreen()),
              );
            },
          ),
          _modeCard(
            context,
            icon: Icons.timer_outlined,
            title: 'EXAM',
            subtitle: 'Build full exam readiness under pressure.',
            color: const Color(0xFFD18B2D),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CSPOverviewScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _readinessPanel(bool wide) {
    return _sectionCard(
      title: 'CERTIFICATION READINESS',
      subtitle: 'A high-level view of your current preparation.',
      icon: Icons.verified_user_outlined,
      child: wide
          ? Row(
              children: [
                SizedBox(width: 145, height: 145, child: _readinessRing()),
                const SizedBox(width: 28),
                Expanded(
                  child: Column(
                    children: [
                      _readinessRow('Content completion', .72),
                      _readinessRow('Question mastery', .68),
                      _readinessRow('Domain coverage', .74),
                      _readinessRow('Mock exam performance', .81),
                    ],
                  ),
                ),
                const SizedBox(width: 28),
                _readinessInsight(),
              ],
            )
          : Column(
              children: [
                SizedBox(width: 145, height: 145, child: _readinessRing()),
                const SizedBox(height: 22),
                _readinessRow('Content completion', .72),
                _readinessRow('Question mastery', .68),
                _readinessRow('Domain coverage', .74),
                _readinessRow('Mock exam performance', .81),
                const SizedBox(height: 10),
                _readinessInsight(),
              ],
            ),
    );
  }

  Widget _readinessRing() {
    return Stack(
      alignment: Alignment.center,
      children: [
        const SizedBox.expand(
          child: CircularProgressIndicator(
            value: .74,
            strokeWidth: 11,
            backgroundColor: Color(0xFFE9EDF3),
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3157A4)),
          ),
        ),
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '74%',
              style: TextStyle(
                color: Color(0xFF172033),
                fontSize: 28,
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

  Widget _readinessRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 7,
                backgroundColor: const Color(0xFFE9EDF3),
                valueColor: const AlwaysStoppedAnimation<Color>(
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
      width: 235,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5E9F0)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEXT BEST ACTION',
            style: TextStyle(
              color: Color(0xFF3157A4),
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Strengthen Domain 04',
            style: TextStyle(
              color: Color(0xFF172033),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Your current coverage is 31%. Focused study and practice here can improve overall readiness.',
            style: TextStyle(
              color: Color(0xFF6F7888),
              fontSize: 9,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _comingSoonSection() {
    final courses = [
      ('ASP', 'Associate Safety Professional'),
      ('NEBOSH IDIP', 'International Diploma'),
      ('NEBOSH IGC', 'International General Certificate'),
      ('CRSP', 'Canadian Registered Safety Professional'),
      ('IOSH', 'Professional Safety Training'),
      ('OPITO', 'Offshore Safety Training'),
    ];

    return _sectionCard(
      title: 'EXPANDING THE ACADEMY',
      subtitle: 'Additional certification pathways are being prepared.',
      icon: Icons.auto_awesome_outlined,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: courses.map((course) {
          return Container(
            width: 250,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE7EAF0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFF8993A3),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.$1,
                        style: const TextStyle(
                          color: Color(0xFF273247),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        course.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF7A8495),
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E9F0)),
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
                  color: AppColors.primary.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: AppColors.primary, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        fontSize: 8,
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

  Widget _pulseMetric(
    String title,
    String value,
    String subtitle,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                style: const TextStyle(color: Color(0xFF8993A3), fontSize: 7),
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
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: const Color(0xFFE7EAF0),
    );
  }

  Widget _continueIcon() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF3157A4).withValues(alpha: .09),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.play_arrow_rounded,
        color: Color(0xFF3157A4),
        size: 27,
      ),
    );
  }

  Widget _continueButton(BuildContext context) {
    return SizedBox(
      width: 160,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CSPOverviewScreen()),
          );
        },
        icon: const Icon(Icons.arrow_forward_rounded, size: 15),
        label: const Text('CONTINUE'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _modeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E9F0)),
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF596477),
                        fontSize: 9,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: Color(0xFF9AA3B2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .055),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white.withValues(alpha: .07)),
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

  const _MiniProgress({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 5,
            backgroundColor: const Color(0x223E609B),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9DB6E5)),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DOMAIN 01 • RISK ASSESSMENT PRINCIPLES',
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
          style: TextStyle(color: Color(0xFF737D8D), fontSize: 9),
        ),
      ],
    );
  }
}

class _DomainData {
  final String number;
  final String title;
  final double progress;
  final String status;
  final Color color;

  const _DomainData({
    required this.number,
    required this.title,
    required this.progress,
    required this.status,
    required this.color,
  });
}
