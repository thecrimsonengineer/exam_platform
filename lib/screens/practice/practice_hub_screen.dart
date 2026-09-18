import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';

import '../../services/practice/practice_mode_service.dart';
import '../courses/csp/csp_practice_screen.dart';
import '../courses/csp/csp_practice_screen_dark.dart';
import 'practice_quick_launch_screen.dart';

class PracticeHubScreen extends StatelessWidget {
  const PracticeHubScreen({super.key});

  void _openPractice(
    BuildContext context, {
    required String title,
    required String description,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => isDarkMode
            ? DarkCspPracticeScreen(title: title, description: description)
            : CspPracticeScreen(title: title, description: description),
      ),
    );
  }

  void _openQuickPractice(BuildContext context, PracticeMode mode) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            PracticeQuickLaunchScreen(mode: mode, isDarkMode: isDarkMode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    final modes = <_PracticeMode>[
      _PracticeMode(
        keyName: 'practice-hub-daily',
        icon: Icons.local_fire_department_rounded,
        title: 'Daily Challenge',
        subtitle: 'A compact daily set from the published CSP11 catalogue.',
        accent: scheme.tertiary,
        actionLabel: 'START',
        onTap: () => _openQuickPractice(context, PracticeMode.dailyChallenge),
      ),
      _PracticeMode(
        keyName: 'practice-hub-weak',
        icon: Icons.track_changes_rounded,
        title: 'Weak Areas',
        subtitle:
            'Targets an evidence-backed weak domain from your question history.',
        accent: scheme.secondary,
        actionLabel: 'START',
        onTap: () => _openQuickPractice(context, PracticeMode.weakAreas),
      ),
      _PracticeMode(
        keyName: 'practice-hub-random',
        icon: Icons.shuffle_rounded,
        title: 'Random Quiz',
        subtitle: 'Mixes a fresh set across the published CSP11 question bank.',
        accent: scheme.primary,
        actionLabel: 'START',
        onTap: () => _openQuickPractice(context, PracticeMode.randomQuiz),
      ),
      _PracticeMode(
        keyName: 'practice-hub-custom',
        icon: Icons.tune_rounded,
        title: 'Custom Quiz',
        subtitle:
            'Choose scope, difficulty, cognitive level, and question count.',
        accent: scheme.primary,
        actionLabel: 'BUILD',
        onTap: () => _openPractice(
          context,
          title: 'Custom Quiz',
          description:
              'Build a CSP11 quiz by domain, competency, subtopic, difficulty, or cognitive level.',
        ),
      ),
      _PracticeMode(
        keyName: 'practice-hub-ultra-hard',
        icon: Icons.workspace_premium_rounded,
        title: 'Ultra Hard • DQG300',
        subtitle:
            'Readiness stress-test using only questions that passed DQG300 at 300/300 with DQS 100.',
        accent: const Color(0xFFA855F7),
        actionLabel: 'TEST READINESS',
        badge: 'DQG300',
        featured: true,
        onTap: () =>
            _openQuickPractice(context, PracticeMode.ultraHardExamReadiness),
      ),
    ];

    return StudentGlassScaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        key: const ValueKey('practice-hub-glass-background'),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? const [
                    Color(0xFF070D18),
                    Color(0xFF101B32),
                    Color(0xFF1C1030),
                  ]
                : const [
                    Color(0xFFF4F7FF),
                    Color(0xFFEFF4FF),
                    Color(0xFFF7F1FF),
                  ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -100,
              right: -70,
              child: _AmbientOrb(
                size: 290,
                color: scheme.primary.withValues(
                  alpha: isDarkMode ? 0.20 : 0.12,
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              left: -110,
              child: _AmbientOrb(
                size: 320,
                color: const Color(
                  0xFFA855F7,
                ).withValues(alpha: isDarkMode ? 0.16 : 0.09),
              ),
            ),
            SafeArea(
              child: CustomScrollView(
                key: const PageStorageKey<String>('csp11-practice-hub-scroll'),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 36),
                    sliver: SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1080),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _PracticeHero(
                                isDarkMode: isDarkMode,
                                scheme: scheme,
                              ),
                              const SizedBox(height: 24),
                              _SectionHeading(
                                scheme: scheme,
                                title: 'Choose your training mode',
                                subtitle:
                                    'Move from daily reps to focused DQG300 testing without leaving the same practice hub.',
                              ),
                              const SizedBox(height: 16),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final columns = constraints.maxWidth >= 820
                                      ? 2
                                      : 1;
                                  const gap = 14.0;
                                  final width = columns == 1
                                      ? constraints.maxWidth
                                      : (constraints.maxWidth - gap) / 2;

                                  return Wrap(
                                    spacing: gap,
                                    runSpacing: gap,
                                    children: modes
                                        .map(
                                          (mode) => SizedBox(
                                            width: width,
                                            child: _PracticeModeCard(
                                              mode: mode,
                                              scheme: scheme,
                                              isDarkMode: isDarkMode,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  );
                                },
                              ),
                              const SizedBox(height: 18),
                              _GlassPanel(
                                key: const ValueKey(
                                  'practice-hub-published-catalogue-panel',
                                ),
                                isDarkMode: isDarkMode,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: scheme.primary.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                      child: Icon(
                                        Icons.cloud_done_rounded,
                                        color: scheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'One published catalogue, two quality lanes',
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w900,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Standard modes use the existing published bank. Ultra Hard filters only the separately validated DQG300 300/300 set.',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color:
                                                      scheme.onSurfaceVariant,
                                                  height: 1.45,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _PracticeHero extends StatelessWidget {
  const _PracticeHero({required this.isDarkMode, required this.scheme});

  final bool isDarkMode;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _GlassPanel(
      key: const ValueKey('practice-hub-glass-hero'),
      isDarkMode: isDarkMode,
      padding: const EdgeInsets.all(26),
      child: Stack(
        children: [
          Positioned(
            right: -4,
            top: -26,
            child: Icon(
              Icons.psychology_alt_rounded,
              size: 160,
              color: scheme.primary.withValues(alpha: 0.07),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeroPill(
                    icon: Icons.bolt_rounded,
                    label: 'CSP11 PRACTICE LAB',
                    foreground: scheme.primary,
                  ),
                  const _HeroPill(
                    icon: Icons.verified_rounded,
                    label: 'DQG300 READY',
                    foreground: Color(0xFFA855F7),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Text(
                'Practice with precision.',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 690),
                child: Text(
                  'Train by habit, weakness, randomness, custom scope, or push into Ultra Hard DQG300 when you want the strictest question set.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.55,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.scheme,
    required this.title,
    required this.subtitle,
  });

  final ColorScheme scheme;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRACTICE MODES',
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.icon,
    required this.label,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.9,
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeModeCard extends StatelessWidget {
  const _PracticeModeCard({
    required this.mode,
    required this.scheme,
    required this.isDarkMode,
  });

  final _PracticeMode mode;
  final ColorScheme scheme;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _GlassPanel(
      key: ValueKey<String>(mode.keyName),
      isDarkMode: isDarkMode,
      padding: EdgeInsets.zero,
      borderColor: mode.featured ? mode.accent.withValues(alpha: 0.42) : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: mode.onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            constraints: const BoxConstraints(minHeight: 164),
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        mode.accent.withValues(alpha: 0.22),
                        mode.accent.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: mode.accent.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Icon(mode.icon, color: mode.accent, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (mode.badge != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: mode.accent.withValues(alpha: 0.11),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            mode.badge!,
                            style: TextStyle(
                              color: mode.accent,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        mode.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        mode.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Text(
                            mode.actionLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: mode.accent,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 15,
                            color: mode.accent,
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
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    super.key,
    required this.isDarkMode,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderColor,
  });

  final bool isDarkMode;
  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: (isDarkMode ? Colors.white : Colors.white).withValues(
              alpha: isDarkMode ? 0.065 : 0.58,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color:
                  borderColor ??
                  (isDarkMode ? Colors.white : scheme.outlineVariant)
                      .withValues(alpha: isDarkMode ? 0.13 : 0.44),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.22 : 0.07),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PracticeMode {
  const _PracticeMode({
    required this.keyName,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.actionLabel,
    required this.onTap,
    this.badge,
    this.featured = false,
  });

  final String keyName;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final String actionLabel;
  final VoidCallback onTap;
  final String? badge;
  final bool featured;
}
