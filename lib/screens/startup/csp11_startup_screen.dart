import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'startup_timeline.dart';

class Csp11StartupScreen extends StatefulWidget {
  const Csp11StartupScreen({super.key, required this.child});

  final Widget child;

  @override
  State<Csp11StartupScreen> createState() => _Csp11StartupScreenState();
}

class _Csp11StartupScreenState extends State<Csp11StartupScreen>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 4800);

  late final AnimationController _controller;
  bool _showOverlay = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _showOverlay = false);
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_showOverlay)
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final value = _controller.value;
                final exitProgress =
                    ((value - (132 / 144)) / (12 / 144)).clamp(0.0, 1.0).toDouble();
                final opacity =
                    1 - Curves.easeInCubic.transform(exitProgress);
                final scale = 1 + (0.018 * exitProgress);

                return Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: _StartupCanvas(
                      progress: value,
                      animation: _controller,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _StartupCanvas extends StatelessWidget {
  const _StartupCanvas({
    required this.progress,
    required this.animation,
  });

  final double progress;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final beat = StartupTimeline.beatForProgress(progress);
    final beatProgress = StartupTimeline.beatProgress(progress, beat);
    final presentation = _BeatPresentation.forBeat(beat);
    final introProgress = (progress / (18 / 144)).clamp(0.0, 1.0).toDouble();
    final brandOpacity = Curves.easeOut.transform(introProgress);
    final brandScale = 0.92 + (0.08 * Curves.easeOutBack.transform(
      introProgress,
    ));

    return ColoredBox(
      color: const Color(0xFF080B10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.05),
            radius: 1.08,
            colors: [
              presentation.accent.withValues(alpha: 0.13),
              const Color(0xFF0A1018),
              const Color(0xFF080B10),
            ],
            stops: const [0, 0.5, 1],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final shortest =
                  math.min(constraints.maxWidth, constraints.maxHeight);
              final lottieSize = math.min(390.0, shortest * 0.64);

              return Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: _ParticleFieldPainter(
                      progress: progress,
                      beat: beat,
                      accent: presentation.accent,
                    ),
                  ),
                  CustomPaint(
                    painter: _KnowledgeCorePainter(
                      progress: progress,
                      beat: beat,
                      accent: presentation.accent,
                    ),
                  ),
                  Align(
                    alignment: const Alignment(0, -0.82),
                    child: Opacity(
                      opacity: brandOpacity,
                      child: Transform.scale(
                        scale: brandScale,
                        child: const _BrandLockup(),
                      ),
                    ),
                  ),
                  Center(
                    child: SizedBox.square(
                      dimension: lottieSize,
                      child: Lottie.asset(
                        'assets/startup/csp11_startup_master.json',
                        controller: animation,
                        repeat: false,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Align(
                    alignment: const Alignment(0, 0.69),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: _BeatGlassCard(
                        presentation: presentation,
                        beatProgress: beatProgress,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 26),
                      child: _SegmentedTimeline(
                        activeBeat: beat,
                        progress: progress,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'CSP11',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 3.4,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'LEARNING SYSTEM',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white54,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.1,
              ),
        ),
      ],
    );
  }
}

class _BeatGlassCard extends StatelessWidget {
  const _BeatGlassCard({
    required this.presentation,
    required this.beatProgress,
  });

  final _BeatPresentation presentation;
  final double beatProgress;

  @override
  Widget build(BuildContext context) {
    final enter = Curves.easeOutCubic.transform(
      (beatProgress / 0.28).clamp(0.0, 1.0).toDouble(),
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Transform.translate(
        key: ValueKey(presentation.beat),
        offset: Offset(0, 8 * (1 - enter)),
        child: Opacity(
          opacity: enter,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 430),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 15),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.055),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: presentation.accent.withValues(alpha: 0.23),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: presentation.accent.withValues(alpha: 0.12),
                        border: Border.all(
                          color: presentation.accent.withValues(alpha: 0.32),
                        ),
                      ),
                      child: Icon(
                        presentation.icon,
                        size: 20,
                        color: presentation.accent,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            presentation.title,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: presentation.accent,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            presentation.message,
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.78,
                                      ),
                                      fontWeight: FontWeight.w500,
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
      ),
    );
  }
}

class _SegmentedTimeline extends StatelessWidget {
  const _SegmentedTimeline({
    required this.activeBeat,
    required this.progress,
  });

  final StartupBeat activeBeat;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final activeIndex = StartupBeat.values.indexOf(activeBeat);

    return Row(
      children: [
        for (var index = 0; index < StartupBeat.values.length; index++) ...[
          Expanded(
            child: _TimelineSegment(
              fill: _segmentFill(index, activeIndex),
            ),
          ),
          if (index != StartupBeat.values.length - 1)
            const SizedBox(width: 6),
        ],
      ],
    );
  }

  double _segmentFill(int index, int activeIndex) {
    if (index < activeIndex) {
      return 1;
    }
    if (index > activeIndex) {
      return 0;
    }

    return StartupTimeline.beatProgress(
      progress,
      StartupBeat.values[index],
    );
  }
}

class _TimelineSegment extends StatelessWidget {
  const _TimelineSegment({required this.fill});

  final double fill;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 3,
        child: ColoredBox(
          color: Colors.white.withValues(alpha: 0.09),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fill.clamp(0.0, 1.0).toDouble(),
            child: const ColoredBox(
              color: Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}

class _BeatPresentation {
  const _BeatPresentation({
    required this.beat,
    required this.title,
    required this.message,
    required this.icon,
    required this.accent,
  });

  final StartupBeat beat;
  final String title;
  final String message;
  final IconData icon;
  final Color accent;

  static _BeatPresentation forBeat(StartupBeat beat) {
    switch (beat) {
      case StartupBeat.ignite:
        return const _BeatPresentation(
          beat: StartupBeat.ignite,
          title: 'CSP11',
          message: 'Your learning environment is coming online',
          icon: Icons.hub_outlined,
          accent: Color(0xFFB6E4FF),
        );
      case StartupBeat.learn:
        return const _BeatPresentation(
          beat: StartupBeat.learn,
          title: 'LEARN',
          message: 'Continue where you stopped',
          icon: Icons.menu_book_outlined,
          accent: Color(0xFF67B7FF),
        );
      case StartupBeat.practice:
        return const _BeatPresentation(
          beat: StartupBeat.practice,
          title: 'PRACTICE',
          message: 'Turn knowledge into confident answers',
          icon: Icons.gps_fixed_rounded,
          accent: Color(0xFF62EEE8),
        );
      case StartupBeat.lab:
        return const _BeatPresentation(
          beat: StartupBeat.lab,
          title: 'DECISION LAB',
          message: 'Make decisions and see their consequences',
          icon: Icons.account_tree_outlined,
          accent: Color(0xFF91A4FF),
        );
      case StartupBeat.remember:
        return const _BeatPresentation(
          beat: StartupBeat.remember,
          title: 'REMEMBER',
          message: 'Strengthen key concepts with flashcards',
          icon: Icons.style_outlined,
          accent: Color(0xFFB39CFF),
        );
      case StartupBeat.converge:
        return const _BeatPresentation(
          beat: StartupBeat.converge,
          title: 'READY',
          message: 'Your learning continues',
          icon: Icons.arrow_forward_rounded,
          accent: Color(0xFFD8F7FF),
        );
    }
  }
}

class _KnowledgeCorePainter extends CustomPainter {
  _KnowledgeCorePainter({
    required this.progress,
    required this.beat,
    required this.accent,
  });

  final double progress;
  final StartupBeat beat;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) * 0.27;
    final intro = (progress / (18 / 144)).clamp(0.0, 1.0).toDouble();
    final introEase = Curves.easeOutCubic.transform(intro);
    final converge = beat == StartupBeat.converge
        ? StartupTimeline.beatProgress(progress, beat)
        : 0.0;

    final glowShader = RadialGradient(
      colors: [
        accent.withValues(alpha: 0.10 + (0.08 * (1 - converge))),
        accent.withValues(alpha: 0),
      ],
    ).createShader(
      Rect.fromCircle(center: center, radius: radius * 1.35),
    );
    canvas.drawCircle(
      center,
      radius * 1.35,
      Paint()..shader = glowShader,
    );

    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = accent.withValues(alpha: 0.12 * introEase);

    final connectionPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.white.withValues(alpha: 0.055 * introEase);

    final nodePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: 0.78 * introEase);

    final activeNodePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = accent.withValues(alpha: 0.96 * introEase);

    canvas.drawCircle(center, radius, orbitPaint);

    final sweep = progress * math.pi * 2;
    final points = <Offset>[];
    for (var index = 0; index < 7; index++) {
      final base = (math.pi * 2 / 7) * index - math.pi / 2;
      final angle = base + (sweep * 0.055);
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      points.add(point);
      canvas.drawLine(center, point, connectionPaint);

      final pulse =
          1 + (0.26 * math.sin((progress * math.pi * 5) + (index * 0.8)));
      canvas.drawCircle(
        point,
        3.2 * pulse,
        index == _highlightedNode ? activeNodePaint : nodePaint,
      );
    }

    for (var index = 0; index < points.length; index++) {
      canvas.drawLine(
        points[index],
        points[(index + 1) % points.length],
        connectionPaint,
      );
    }

    final arcRect = Rect.fromCircle(center: center, radius: radius + 12);
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: 0.42 * introEase);
    canvas.drawArc(
      arcRect,
      -math.pi / 2 + (progress * math.pi * 0.8),
      math.pi * 0.34,
      false,
      arcPaint,
    );

    final pulseRadius =
        48 + (22 * math.sin(progress * math.pi * 3).abs()) + (28 * converge);
    canvas.drawCircle(
      center,
      pulseRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = accent.withValues(alpha: 0.16 * introEase),
    );
  }

  int get _highlightedNode {
    switch (beat) {
      case StartupBeat.ignite:
        return 0;
      case StartupBeat.learn:
        return 1;
      case StartupBeat.practice:
        return 2;
      case StartupBeat.lab:
        return 3;
      case StartupBeat.remember:
        return 4;
      case StartupBeat.converge:
        return 6;
    }
  }

  @override
  bool shouldRepaint(covariant _KnowledgeCorePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.beat != beat ||
        oldDelegate.accent != accent;
  }
}

class _ParticleFieldPainter extends CustomPainter {
  _ParticleFieldPainter({
    required this.progress,
    required this.beat,
    required this.accent,
  });

  final double progress;
  final StartupBeat beat;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final shortest = math.min(size.width, size.height);
    final converge = beat == StartupBeat.converge
        ? StartupTimeline.beatProgress(progress, beat)
        : 0.0;

    for (var index = 0; index < 34; index++) {
      final seed = index / 34;
      final phase = (progress * 0.78 + seed) % 1.0;
      final direction = (index * 2.399963) + (progress * 0.65);
      final outwardRadius = shortest * (0.08 + (phase * 0.52));
      final inwardRadius =
          shortest * (0.60 - (phase * 0.48)).clamp(0.08, 0.60).toDouble();
      final radius = outwardRadius * (1 - converge) + inwardRadius * converge;
      final drift = math.sin((progress * math.pi * 2) + index) * 8;

      final point = Offset(
        center.dx + math.cos(direction) * radius + drift,
        center.dy + math.sin(direction) * radius - drift,
      );

      final life = math.sin(phase * math.pi).clamp(0.0, 1.0).toDouble();
      final alpha = (0.035 + (0.14 * life)) * (1 - (0.25 * converge));
      final particleRadius = 0.7 + (1.6 * life);

      canvas.drawCircle(
        point,
        particleRadius,
        Paint()
          ..color = (index.isEven ? accent : Colors.white)
              .withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleFieldPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.beat != beat ||
        oldDelegate.accent != accent;
  }
}
