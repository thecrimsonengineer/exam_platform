import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

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
                final fade = value < 0.82
                    ? 1.0
                    : (1.0 - ((value - 0.82) / 0.18)).clamp(0.0, 1.0);

                return Opacity(
                  opacity: fade,
                  child: _StartupCanvas(progress: value),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _StartupCanvas extends StatelessWidget {
  const _StartupCanvas({required this.progress});

  final double progress;

  static const _messages = [
    'Continue where you stopped',
    'Follow today\'s learning plan',
    'Practice intelligently',
    'Make decisions in LAB',
    'Remember with flashcards',
  ];

  @override
  Widget build(BuildContext context) {
    final messageIndex =
        math.min((_messages.length * progress).floor(), _messages.length - 1);

    return ColoredBox(
      color: const Color(0xFF080B10),
      child: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _KnowledgeCorePainter(progress: progress),
            ),
            Center(
              child: SizedBox(
                width: 330,
                height: 330,
                child: Lottie.asset(
                  'assets/startup/csp11_startup_master.json',
                  repeat: false,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'CSP11',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                        ),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .scaleXY(begin: 0.92, end: 1),
                  const SizedBox(height: 18),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: Text(
                      _messages[messageIndex],
                      key: ValueKey(messageIndex),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 28,
              right: 28,
              bottom: 34,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  value: progress,
                  backgroundColor: Colors.white10,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KnowledgeCorePainter extends CustomPainter {
  _KnowledgeCorePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) * 0.27;

    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.10);

    final nodePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: 0.72);

    final pulsePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = Colors.white.withValues(alpha: 0.18);

    canvas.drawCircle(center, radius, orbitPaint);

    final sweep = progress * math.pi * 2;
    for (var i = 0; i < 7; i++) {
      final base = (math.pi * 2 / 7) * i - math.pi / 2;
      final angle = base + sweep * 0.08;
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      canvas.drawCircle(point, 3.5, nodePaint);
    }

    final pulseRadius = 42 + (progress * 38);
    canvas.drawCircle(center, pulseRadius, pulsePaint);
  }

  @override
  bool shouldRepaint(covariant _KnowledgeCorePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
