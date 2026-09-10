import 'package:flutter/material.dart';

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

  static const _navy = Color(0xFF071A2B);
  static const _deepBlue = Color(0xFF0D2D48);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_navy, _deepBlue, Color(0xFF102F43)],
              ),
            ),
          ),
          const Positioned(
            left: -130,
            top: -120,
            child: _GlowOrb(size: 360, color: Color(0x3323D8C0)),
          ),
          const Positioned(
            right: -100,
            bottom: -140,
            child: _GlowOrb(size: 420, color: Color(0x332B7FFF)),
          ),
          SafeArea(
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
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          child: Column(
                            children: [
                              _HeroPanel(
                                eyebrow: eyebrow,
                                title: title,
                                subtitle: subtitle,
                                compact: true,
                              ),
                              const SizedBox(height: 26),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 520,
                                ),
                                child: child,
                              ),
                            ],
                          ),
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
        ],
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
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 60,
            offset: Offset(0, 24),
            color: Color(0x55000000),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF0C2B45),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Color(0xFF55E1CE),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'CSP11',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: Color(0xFF0A2135),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8F5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'SECURE ACCESS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Color(0xFF087D70),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Text(
            title,
            style: const TextStyle(
              fontSize: 30,
              height: 1.08,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0A2135),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(height: 1.45, color: Color(0xFF5B6B78)),
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
            style: const TextStyle(
              color: Color(0xFF67E4D3),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.2,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: compact ? TextAlign.center : TextAlign.left,
            style: TextStyle(
              color: Colors.white,
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
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.74),
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
              _TrustChip(icon: Icons.route_rounded, label: 'Guided study path'),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF67E4D3)),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
