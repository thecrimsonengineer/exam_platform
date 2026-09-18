import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';

class AuthExperienceShell extends StatelessWidget {
  const AuthExperienceShell({
    super.key,
    required this.child,
    this.eyebrow = 'CSP11 LEARNING PLATFORM',
    this.title = 'Build exam-ready judgment.',
    this.subtitle =
        'Structured CSP11 learning, practice and progress in one focused workspace.',
  });

  final Widget child;
  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return StudentGlassScaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;

            final content = ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: wide
                  ? Row(
                      children: [
                        Expanded(
                          child: _HeroPanel(
                            eyebrow: eyebrow,
                            title: title,
                            subtitle: subtitle,
                          ),
                        ),
                        const SizedBox(width: 44),
                        SizedBox(width: 470, child: child),
                      ],
                    )
                  : Column(
                      children: [
                        _HeroPanel(
                          eyebrow: eyebrow,
                          title: title,
                          subtitle: subtitle,
                          compact: true,
                        ),
                        const SizedBox(height: 26),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: child,
                        ),
                      ],
                    ),
            );

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? 44 : 20,
                  vertical: 24,
                ),
                child: content,
              ),
            );
          },
        ),
      ),
    );
  }
}

class AuthCard extends StatelessWidget {
  const AuthCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return StudentGlassSurface(
      padding: const EdgeInsets.all(30),
      borderRadius: BorderRadius.circular(28),
      tint: scheme.surface.withValues(alpha: 0.58),
      borderColor: scheme.outlineVariant.withValues(alpha: 0.62),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              StudentGlassSurface(
                padding: const EdgeInsets.all(12),
                borderRadius: BorderRadius.circular(14),
                tint: scheme.primary.withValues(alpha: 0.14),
                borderColor: scheme.primary.withValues(alpha: 0.20),
                child: Icon(
                  Icons.school_rounded,
                  color: scheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'CSP11',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.16),
                  ),
                ),
                child: Text(
                  'SECURE ACCESS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.08,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.45,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.all(compact ? 8 : 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: compact
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            textAlign: compact ? TextAlign.center : TextAlign.left,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.2,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: compact ? TextAlign.center : TextAlign.left,
            style: theme.textTheme.displaySmall?.copyWith(
              color: scheme.onSurface,
              fontSize: compact ? 38 : 58,
              height: 1.02,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.6,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            subtitle,
            textAlign: compact ? TextAlign.center : TextAlign.left,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: compact ? 16 : 18,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 28),
          Wrap(
            alignment: compact ? WrapAlignment.center : WrapAlignment.start,
            spacing: 10,
            runSpacing: 10,
            children: const [
              _TrustChip(
                icon: Icons.verified_user_rounded,
                label: 'Verified learners',
              ),
              _TrustChip(
                icon: Icons.route_rounded,
                label: 'Guided study path',
              ),
              _TrustChip(
                icon: Icons.insights_rounded,
                label: 'Progress tracking',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrustChip extends StatelessWidget {
  const _TrustChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return StudentGlassSurface(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      borderRadius: BorderRadius.circular(999),
      tint: scheme.surface.withValues(alpha: 0.44),
      borderColor: scheme.outlineVariant.withValues(alpha: 0.56),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 7),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
