import 'package:flutter/material.dart';

import '../courses/csp/csp_practice_screen.dart';
import '../courses/csp/csp_practice_screen_dark.dart';

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
        subtitle: 'A short focused session from published CSP11 questions.',
        accent: scheme.tertiary,
        onTap: () => _openPractice(
          context,
          title: 'Daily Challenge',
          description:
              'Use the published-question catalogue for a short, focused CSP11 practice session.',
        ),
      ),
      _PracticeMode(
        keyName: 'practice-hub-weak',
        icon: Icons.track_changes_rounded,
        title: 'Weak Areas',
        subtitle: 'Target the areas that need the most reinforcement.',
        accent: scheme.secondary,
        onTap: () => _openPractice(
          context,
          title: 'Weak Areas',
          description:
              'Target CSP11 learning areas that need more work by domain, competency, or subtopic.',
        ),
      ),
      _PracticeMode(
        keyName: 'practice-hub-random',
        icon: Icons.shuffle_rounded,
        title: 'Random Quiz',
        subtitle: 'Mix questions from the published CSP11 bank.',
        accent: scheme.primary,
        onTap: () => _openPractice(
          context,
          title: 'Random Quiz',
          description:
              'Build a mixed quiz from the published CSP11 question bank.',
        ),
      ),
      _PracticeMode(
        keyName: 'practice-hub-custom',
        icon: Icons.tune_rounded,
        title: 'Custom Quiz',
        subtitle:
            'Choose scope, difficulty, cognitive level, and question count.',
        accent: scheme.primary,
        onTap: () => _openPractice(
          context,
          title: 'Custom Quiz',
          description:
              'Build a CSP11 quiz by domain, competency, subtopic, difficulty, or cognitive level.',
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          key: const PageStorageKey<String>('csp11-practice-hub-scroll'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 36),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1050),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PracticeHero(isDarkMode: isDarkMode, scheme: scheme),
                        const SizedBox(height: 24),
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
                          'Train with purpose',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Every mode uses the learner-safe published question catalogue. '
                          'Draft, review, and validated-only questions stay protected.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 820 ? 2 : 1;
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
                                      ),
                                    ),
                                  )
                                  .toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: scheme.outlineVariant.withValues(
                                alpha: 0.75,
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.cloud_done_rounded,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Published-question catalogue',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'CSP11 warms the published question catalogue when the learner shell opens. '
                                      'Opening another practice mode reuses that session catalogue instead of '
                                      'reloading draft and published repositories.',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
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

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 230),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [scheme.primaryContainer, scheme.surfaceContainerHighest]
              : [
                  scheme.primary,
                  Color.lerp(scheme.primary, scheme.secondary, 0.62)!,
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: isDarkMode ? 0.26 : 0.14),
            blurRadius: 28,
            offset: const Offset(0, 13),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            top: -24,
            child: Icon(
              Icons.quiz_rounded,
              size: 150,
              color: (isDarkMode ? scheme.onSurface : scheme.onPrimary)
                  .withValues(alpha: 0.065),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroPill(
                icon: Icons.bolt_rounded,
                label: 'M6 PRACTICE HUB',
                foreground: isDarkMode
                    ? scheme.onPrimaryContainer
                    : scheme.onPrimary,
              ),
              const SizedBox(height: 24),
              Text(
                'Practice with a plan.',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: isDarkMode
                      ? scheme.onPrimaryContainer
                      : scheme.onPrimary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 660),
                child: Text(
                  'Daily, targeted, random, and custom practice now share one '
                  'published-question pipeline. The same hub works in light and dark mode.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        (isDarkMode
                                ? scheme.onPrimaryContainer
                                : scheme.onPrimary)
                            .withValues(alpha: 0.82),
                    height: 1.5,
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
        color: foreground.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withValues(alpha: 0.14)),
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
  const _PracticeModeCard({required this.mode, required this.scheme});

  final _PracticeMode mode;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: ValueKey<String>(mode.keyName),
        onTap: mode.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 150),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.75),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: mode.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(mode.icon, color: mode.accent, size: 25),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                          'OPEN',
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
    required this.onTap,
  });

  final String keyName;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;
}
