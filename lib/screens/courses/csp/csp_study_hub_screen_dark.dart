import 'package:exam_platform/features/learning_twin/integration/learning_twin_study_hub_guidance.dart';
import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../app/theme.dart';
import '../../../data/csp11_blueprint.dart';
import 'domain_screen_dark.dart';

class DarkCspStudyHubScreen extends StatelessWidget {
  const DarkCspStudyHubScreen({super.key});

  static const _background = Color(0xFF0A111D);
  static const _surface = Color(0xFF111B2C);
  static const _navy = Color(0xFF5F93D8);
  static const _blue = Color(0xFF6EA8FF);
  static const _violet = Color(0xFF9A7CF4);
  static const _textPrimary = Color(0xFFF4F7FB);
  static const _textMuted = Color(0xFFA5B1C4);
  static const _border = Color(0xFF25344A);

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
          child: CustomScrollView(
            key: const PageStorageKey<String>('csp11-study-hub-scroll'),
            physics: const BouncingScrollPhysics(),
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
                          _buildHero(context),
                          const SizedBox(height: 28),
                          _buildPathStrip(context),
                          const SizedBox(height: 18),
                          Theme(
                            data: AppTheme.darkTheme,
                            child: const LearningTwinStudyHubGuidance(),
                          ),
                          const SizedBox(height: 30),
                          _sectionHeading(),
                          const SizedBox(height: 14),
                          _buildDomainGrid(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
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

  SliverAppBar _buildAppBar() {
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
              Icons.menu_book_rounded,
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
            'Study',
            style: TextStyle(
              color: _textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final competencyCount = csp11Domains.fold<int>(
      0,
      (sum, domain) => sum + domain.competencies.length,
    );

    final compact = MediaQuery.sizeOf(context).width < 650;

    return Container(
      key: const ValueKey('study-hub-hero'),
      width: double.infinity,
      constraints: BoxConstraints(minHeight: compact ? 350 : 320),
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
            top: -76,
            right: -44,
            child: IgnorePointer(
              child: Container(
                width: 225,
                height: 225,
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
            right: compact ? 10 : 34,
            bottom: compact ? -18 : 16,
            child: IgnorePointer(
              child: Icon(
                Icons.route_rounded,
                size: compact ? 120 : 165,
                color: Colors.white.withValues(alpha: 0.045),
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
                    icon: Icons.workspace_premium_rounded,
                    text: 'CSP11 STUDY MAP',
                  ),
                  _heroPill(
                    icon: Icons.shield_rounded,
                    text: '7 DOMAINS',
                    accent: Colors.amber.shade300,
                  ),
                ],
              ),
              const SizedBox(height: 26),
              const Text(
                'Master the blueprint,\none Domain at a time.',
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
                constraints: const BoxConstraints(maxWidth: 680),
                child: Text(
                  'Enter the canonical CSP11 pathway and move from Domain to Competency, Topic, Subtopic, and focused learning content.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.80),
                    fontSize: 14,
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Wrap(
                spacing: 22,
                runSpacing: 14,
                children: [
                  _heroMetric(Icons.shield_outlined, '7', 'Domains'),
                  _heroMetric(
                    Icons.account_tree_outlined,
                    '$competencyCount',
                    'Competencies',
                  ),
                  _heroMetric(
                    Icons.assessment_outlined,
                    '100%',
                    'Exam Blueprint',
                  ),
                ],
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

  Widget _heroMetric(IconData icon, String value, String label) {
    return Row(
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
            icon,
            color: Colors.white.withValues(alpha: 0.90),
            size: 19,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPathStrip(BuildContext context) {
    final items = const [
      ('01', 'Domain', Icons.shield_outlined),
      ('02', 'Competency', Icons.account_tree_outlined),
      ('03', 'Topic', Icons.layers_outlined),
      ('04', 'Subtopic', Icons.segment_outlined),
      ('05', 'Learn', Icons.auto_stories_outlined),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.045),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 660) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items
                  .map(
                    (item) => _pathNode(
                      number: item.$1,
                      label: item.$2,
                      icon: item.$3,
                    ),
                  )
                  .toList(),
            );
          }

          final children = <Widget>[];

          for (var i = 0; i < items.length; i++) {
            final item = items[i];

            children.add(
              Expanded(
                child: _pathNode(
                  number: item.$1,
                  label: item.$2,
                  icon: item.$3,
                ),
              ),
            );

            if (i < items.length - 1) {
              children.add(
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                    color: _textMuted,
                  ),
                ),
              );
            }
          }

          return Row(children: children);
        },
      ),
    );
  }

  Widget _pathNode({
    required String number,
    required String label,
    required IconData icon,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 96),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF101A2A),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 15),
              const Spacer(),
              Text(
                number,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 7.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 9.25,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CSP11 DOMAINS',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.15,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Choose your learning arena',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 22,
            height: 1.12,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.45,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Each card shows its official exam weight and canonical competency count.',
          style: TextStyle(color: _textMuted, fontSize: 11.5, height: 1.45),
        ),
      ],
    );
  }

  Widget _buildDomainGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 930 ? 2 : 1;

        const gap = 14.0;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - gap) / 2;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: csp11Domains
              .map(
                (domain) =>
                    SizedBox(width: width, child: _domainCard(context, domain)),
              )
              .toList(),
        );
      },
    );
  }

  Widget _domainCard(BuildContext context, Csp11Domain domain) {
    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        key: ValueKey('study-domain-${domain.number}'),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DarkDomainScreen(domainNumber: domain.number),
            ),
          );
        },
        borderRadius: BorderRadius.circular(21),
        child: Container(
          constraints: const BoxConstraints(minHeight: 178),
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: _navy.withValues(alpha: 0.04),
                blurRadius: 15,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_navy, _blue],
                  ),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Text(
                  domain.number.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _smallPill(
                          '${domain.weightPercent}% EXAM WEIGHT',
                          AppColors.primary,
                        ),
                        _smallPill(
                          '${domain.competencies.length} COMPETENCIES',
                          _violet,
                        ),
                      ],
                    ),
                    const SizedBox(height: 11),
                    Text(
                      domain.title,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 15,
                        height: 1.25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 9),
                    const Row(
                      children: [
                        Text(
                          'OPEN DOMAIN',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.7,
                          ),
                        ),
                        SizedBox(width: 5),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.primary,
                          size: 15,
                        ),
                      ],
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

  Widget _smallPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 7.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
