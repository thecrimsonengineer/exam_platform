import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import '../../models/micro_learning/micro_fact.dart';
import '../../services/auth/learner_local_identity.dart';
import 'startup_micro_learning_service.dart';
import 'startup_motion_policy.dart';
import 'startup_personalization_service.dart';
import 'startup_timeline.dart';

class Csp11StartupScreen extends StatefulWidget {
  const Csp11StartupScreen({
    super.key,
    required this.child,
    this.personalizationService,
    this.microLearningService,
    this.microLearningNowProvider,
    this.motionPolicyOverride,
    this.startupAssetPath = 'assets/startup/csp11_startup_master.json',
  });

  final Widget child;
  final StartupPersonalizationService? personalizationService;
  final StartupMicroLearningService? microLearningService;
  final DateTime Function()? microLearningNowProvider;
  final StartupMotionPolicy? motionPolicyOverride;
  final String startupAssetPath;

  @override
  State<Csp11StartupScreen> createState() => _Csp11StartupScreenState();
}

class _Csp11StartupScreenState extends State<Csp11StartupScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _hardTimeout = Duration(seconds: 7);

  late final AnimationController _controller;
  late final StartupPersonalizationService _personalizationService;
  late final StartupMicroLearningService _microLearningService;

  Timer? _watchdog;
  StartupMotionPolicy _motionPolicy = StartupMotionPolicy.full;
  StartupPersonalizationSnapshot _personalization =
      const StartupPersonalizationSnapshot.empty();
  StartupMicroLearningSnapshot _microLearning =
      const StartupMicroLearningSnapshot.empty();
  bool _personalizationLoadStarted = false;
  bool _microLearningLoadStarted = false;
  String? _personalizationUserId;
  bool _showOverlay = true;
  bool _animationStarted = false;
  bool _lottieReady = false;
  bool _highContrast = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _personalizationService =
        widget.personalizationService ?? StartupPersonalizationService();
    _microLearningService =
        widget.microLearningService ?? StartupMicroLearningService();

    _controller =
        AnimationController(
            vsync: this,
            duration: StartupMotionPolicy.full.duration,
            animationBehavior: AnimationBehavior.normal,
          )
          ..addListener(_maybeLoadPersonalization)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _dismissOverlay();
            }
          });

    _watchdog = Timer(_hardTimeout, _dismissOverlay);
    unawaited(_preflightStartupAsset());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startMicroLearningLoad();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _applyMotionPolicy();
    _startAnimationIfNeeded();
  }

  @override
  void didChangeAccessibilityFeatures() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final changed = _applyMotionPolicy();
      if (changed) {
        setState(() {});
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_showOverlay || !_animationStarted) {
      return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
        if (!_controller.isCompleted && !_controller.isAnimating) {
          _controller.forward();
        }
        return;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        if (_controller.isAnimating) {
          _controller.stop(canceled: false);
        }
        return;
      case AppLifecycleState.detached:
        _controller.stop(canceled: false);
        return;
    }
  }

  bool _applyMotionPolicy() {
    final override = widget.motionPolicyOverride;
    final nextPolicy =
        override ??
        StartupMotionPolicy.resolve(
          disableAnimations: MediaQuery.disableAnimationsOf(context),
          reduceMotion: WidgetsBinding
              .instance
              .platformDispatcher
              .accessibilityFeatures
              .reduceMotion,
          logicalSize: MediaQuery.sizeOf(context),
          devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
        );
    final nextHighContrast = MediaQuery.highContrastOf(context);

    final changed =
        nextPolicy != _motionPolicy || nextHighContrast != _highContrast;

    _motionPolicy = nextPolicy;
    _highContrast = nextHighContrast;
    _controller.duration = nextPolicy.duration;

    return changed;
  }

  void _startAnimationIfNeeded() {
    if (_animationStarted || !_showOverlay) {
      return;
    }

    _animationStarted = true;
    _controller.forward();
  }

  Future<void> _preflightStartupAsset() async {
    try {
      final raw = await rootBundle.loadString(widget.startupAssetPath);
      final decoded = jsonDecode(raw);

      if (decoded is! Map<String, dynamic> ||
          decoded['w'] != 512 ||
          decoded['h'] != 512 ||
          decoded['fr'] != 30 ||
          decoded['op'] != 144) {
        throw const FormatException('Startup Lottie contract mismatch.');
      }

      if (!mounted || !_showOverlay) {
        return;
      }

      setState(() => _lottieReady = true);
    } catch (_) {
      _dismissOverlay();
    }
  }

  void _startMicroLearningLoad() {
    if (!mounted || !_showOverlay || _microLearningLoadStarted) {
      return;
    }

    _microLearningLoadStarted = true;
    unawaited(_loadMicroLearning());
  }

  Future<void> _loadMicroLearning() async {
    final snapshot = await _microLearningService.load(
      now: widget.microLearningNowProvider?.call(),
    );

    if (!mounted || !_showOverlay) {
      return;
    }

    setState(() => _microLearning = snapshot);
  }

  void _maybeLoadPersonalization() {
    if (_personalizationLoadStarted) {
      return;
    }

    final userId = LearnerLocalIdentity.currentUserId?.trim();
    if (userId == null || userId.isEmpty) {
      return;
    }

    _personalizationLoadStarted = true;
    _personalizationUserId = userId;
    unawaited(_loadPersonalization(userId));
  }

  Future<void> _loadPersonalization(String userId) async {
    final snapshot = await _personalizationService.loadForUser(userId);

    if (!mounted ||
        LearnerLocalIdentity.currentUserId != userId ||
        _personalizationUserId != userId) {
      return;
    }

    setState(() => _personalization = snapshot);
  }

  void _dismissOverlay() {
    if (!mounted || !_showOverlay) {
      return;
    }

    _watchdog?.cancel();
    _watchdog = null;
    _controller.stop(canceled: false);
    setState(() => _showOverlay = false);
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    WidgetsBinding.instance.removeObserver(this);
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
            key: const ValueKey('csp11-startup-overlay'),
            child: Semantics(
              container: true,
              label: 'CSP11 Learning System',
              child: ExcludeSemantics(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    if (_motionPolicy.isReduced) {
                      return _ReducedStartupCanvas(
                        personalization: _personalization,
                        highContrast: _highContrast,
                      );
                    }

                    final value = _controller.value;
                    final exitProgress = ((value - (132 / 144)) / (12 / 144))
                        .clamp(0.0, 1.0)
                        .toDouble();
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
                          personalization: _personalization,
                          microFact: _microLearning.fact,
                          motionPolicy: _motionPolicy,
                          lottieReady: _lottieReady,
                          startupAssetPath: widget.startupAssetPath,
                          highContrast: _highContrast,
                          onLottieError: _dismissOverlay,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ReducedStartupCanvas extends StatelessWidget {
  const _ReducedStartupCanvas({
    required this.personalization,
    required this.highContrast,
  });

  final StartupPersonalizationSnapshot personalization;
  final bool highContrast;

  @override
  Widget build(BuildContext context) {
    final secondary =
        personalization.todaySummary ??
        (personalization.hasResume
            ? 'Continue ${personalization.resumeCode}'
            : 'Your learning continues');

    return ColoredBox(
      color: const Color(0xFF080B10),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CSP11',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'LEARNING SYSTEM',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: highContrast ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  secondary,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: highContrast ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.w600,
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

class _StartupCanvas extends StatelessWidget {
  const _StartupCanvas({
    required this.progress,
    required this.animation,
    required this.personalization,
    required this.microFact,
    required this.motionPolicy,
    required this.lottieReady,
    required this.startupAssetPath,
    required this.highContrast,
    required this.onLottieError,
  });

  final double progress;
  final Animation<double> animation;
  final StartupPersonalizationSnapshot personalization;
  final MicroFact? microFact;
  final StartupMotionPolicy motionPolicy;
  final bool lottieReady;
  final String startupAssetPath;
  final bool highContrast;
  final VoidCallback onLottieError;

  @override
  Widget build(BuildContext context) {
    final beat = StartupTimeline.beatForProgress(progress);
    final beatProgress = StartupTimeline.beatProgress(progress, beat);
    final presentation = _BeatPresentation.forBeat(beat, personalization);
    final introProgress = (progress / (18 / 144)).clamp(0.0, 1.0).toDouble();
    final brandOpacity = Curves.easeOut.transform(introProgress);
    final brandScale =
        0.92 + (0.08 * Curves.easeOutBack.transform(introProgress));

    return ColoredBox(
      color: const Color(0xFF080B10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.05),
            radius: 1.08,
            colors: [
              presentation.accent.withValues(alpha: highContrast ? 0.18 : 0.13),
              const Color(0xFF0A1018),
              const Color(0xFF080B10),
            ],
            stops: const [0, 0.5, 1],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final shortest = math.min(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              final lottieSize = math.min(390.0, shortest * 0.64);

              return Stack(
                fit: StackFit.expand,
                children: [
                  if (motionPolicy.animateAmbient) ...[
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: _ParticleFieldPainter(
                          progress: progress,
                          beat: beat,
                          accent: presentation.accent,
                          particleCount: motionPolicy.particleCount,
                        ),
                      ),
                    ),
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: _KnowledgeCorePainter(
                          progress: progress,
                          beat: beat,
                          accent: presentation.accent,
                        ),
                      ),
                    ),
                  ],
                  Align(
                    alignment: const Alignment(0, -0.82),
                    child: Opacity(
                      opacity: brandOpacity,
                      child: Transform.scale(
                        scale: brandScale,
                        child: const RepaintBoundary(child: _BrandLockup()),
                      ),
                    ),
                  ),
                  if (motionPolicy.playLottie && lottieReady)
                    Center(
                      child: RepaintBoundary(
                        child: SizedBox.square(
                          dimension: lottieSize,
                          child: Lottie.asset(
                            startupAssetPath,
                            controller: animation,
                            repeat: false,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                onLottieError();
                              });
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                    ),
                  if (microFact != null &&
                      beat != StartupBeat.ignite &&
                      beat != StartupBeat.converge)
                    Align(
                      alignment: const Alignment(0, 0.28),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: _StartupMicroFactCard(
                          fact: microFact!,
                          highContrast: highContrast,
                          compact: constraints.maxHeight < 700,
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
                        blurSigma: motionPolicy.blurSigma,
                        highContrast: highContrast,
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

class _StartupMicroFactCard extends StatelessWidget {
  const _StartupMicroFactCard({
    required this.fact,
    required this.highContrast,
    required this.compact,
  });

  final MicroFact fact;
  final bool highContrast;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = fact.display.shortVariant?.trim().isNotEmpty == true
        ? fact.display.shortVariant!.trim()
        : fact.display.displayText.trim();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Container(
        key: ValueKey('csp11-startup-microfact-card|${fact.microFactId}'),
        constraints: const BoxConstraints(maxWidth: 430),
        padding: EdgeInsets.fromLTRB(15, compact ? 10 : 12, 15, compact ? 10 : 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: highContrast ? 0.74 : 0.54),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(
              0xFF9FE8FF,
            ).withValues(alpha: highContrast ? 0.72 : 0.30),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 15,
                  color: Color(0xFFB6EFFF),
                ),
                const SizedBox(width: 7),
                Text(
                  'MICRO LEARNING',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: highContrast
                        ? Colors.white
                        : const Color(0xFFB6EFFF),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Text(
                  _microFactSourceLabel(fact.provenance.sourceRegistryId),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: highContrast ? Colors.white70 : Colors.white54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 5 : 7),
            Text(
              text,
              maxLines: compact ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                height: 1.30,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _microFactSourceLabel(String sourceRegistryId) {
  return switch (sourceRegistryId) {
    'SRC-01' => 'OSHA',
    'SRC-02' => 'NIOSH',
    'SRC-03' => 'ANSI / ASSP',
    'SRC-04' => 'ISO',
    'SRC-05' => 'NFPA',
    'SRC-06' => 'ACGIH',
    'SRC-07' => 'AIHA',
    'SRC-08' => 'EPA',
    'SRC-09' => 'DOT',
    'SRC-10' => 'FEMA / NIMS',
    'SRC-11' => 'AIChE / CCPS',
    'SRC-12' => 'NSC',
    'SRC-13' => 'ASSP',
    'SRC-14' => 'FM Global',
    'SRC-15' => 'UL',
    _ => sourceRegistryId,
  };
}

class _BeatGlassCard extends StatelessWidget {
  const _BeatGlassCard({
    required this.presentation,
    required this.beatProgress,
    required this.blurSigma,
    required this.highContrast,
  });

  final _BeatPresentation presentation;
  final double beatProgress;
  final double blurSigma;
  final bool highContrast;

  @override
  Widget build(BuildContext context) {
    final enter = Curves.easeOutCubic.transform(
      (beatProgress / 0.28).clamp(0.0, 1.0).toDouble(),
    );

    final card = Container(
      constraints: const BoxConstraints(maxWidth: 430),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: highContrast ? 0.16 : 0.055),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: presentation.accent.withValues(
            alpha: highContrast ? 0.58 : 0.23,
          ),
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
              color: presentation.accent.withValues(
                alpha: highContrast ? 0.22 : 0.12,
              ),
              border: Border.all(
                color: presentation.accent.withValues(
                  alpha: highContrast ? 0.72 : 0.32,
                ),
              ),
            ),
            child: Icon(
              presentation.icon,
              size: 20,
              color: highContrast ? Colors.white : presentation.accent,
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
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: highContrast ? Colors.white : presentation.accent,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  presentation.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: highContrast
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (presentation.detail != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    presentation.detail!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: highContrast
                          ? Colors.white70
                          : Colors.white.withValues(alpha: 0.50),
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    final glassCard = blurSigma > 0
        ? BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: card,
          )
        : card;

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
        key: ValueKey(
          '${presentation.beat.name}|${presentation.message}|${presentation.detail ?? ''}',
        ),
        offset: Offset(0, 8 * (1 - enter)),
        child: Opacity(
          opacity: enter,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: glassCard,
          ),
        ),
      ),
    );
  }
}

class _SegmentedTimeline extends StatelessWidget {
  const _SegmentedTimeline({required this.activeBeat, required this.progress});

  final StartupBeat activeBeat;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final activeIndex = StartupBeat.values.indexOf(activeBeat);

    return Row(
      children: [
        for (var index = 0; index < StartupBeat.values.length; index++) ...[
          Expanded(
            child: _TimelineSegment(fill: _segmentFill(index, activeIndex)),
          ),
          if (index != StartupBeat.values.length - 1) const SizedBox(width: 6),
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

    return StartupTimeline.beatProgress(progress, StartupBeat.values[index]);
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
            child: const ColoredBox(color: Colors.white70),
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
    this.detail,
  });

  final StartupBeat beat;
  final String title;
  final String message;
  final IconData icon;
  final Color accent;
  final String? detail;

  static _BeatPresentation forBeat(
    StartupBeat beat,
    StartupPersonalizationSnapshot personalization,
  ) {
    switch (beat) {
      case StartupBeat.ignite:
        return _BeatPresentation(
          beat: StartupBeat.ignite,
          title: 'CSP11',
          message: personalization.hasAnyData
              ? 'Welcome back. Your learning path is ready'
              : 'Your learning environment is coming online',
          icon: Icons.hub_outlined,
          accent: const Color(0xFFB6E4FF),
        );
      case StartupBeat.learn:
        return _BeatPresentation(
          beat: StartupBeat.learn,
          title: 'LEARN',
          message: personalization.hasResume
              ? 'Continue ${personalization.resumeCode}'
              : 'Continue where you stopped',
          detail: personalization.resumeTitle,
          icon: Icons.menu_book_outlined,
          accent: const Color(0xFF67B7FF),
        );
      case StartupBeat.practice:
        return _BeatPresentation(
          beat: StartupBeat.practice,
          title: 'PRACTICE',
          message: 'Turn knowledge into confident answers',
          detail: personalization.todaySummary,
          icon: Icons.gps_fixed_rounded,
          accent: const Color(0xFF62EEE8),
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
        return _BeatPresentation(
          beat: StartupBeat.converge,
          title: 'READY',
          message: personalization.todaySummary ?? 'Your learning continues',
          detail: personalization.hasResume
              ? 'Resume point: ${personalization.resumeCode}'
              : null,
          icon: Icons.arrow_forward_rounded,
          accent: const Color(0xFFD8F7FF),
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
    ).createShader(Rect.fromCircle(center: center, radius: radius * 1.35));
    canvas.drawCircle(center, radius * 1.35, Paint()..shader = glowShader);

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
    required this.particleCount,
  });

  final double progress;
  final StartupBeat beat;
  final Color accent;
  final int particleCount;

  @override
  void paint(Canvas canvas, Size size) {
    if (particleCount <= 0) {
      return;
    }

    final center = size.center(Offset.zero);
    final shortest = math.min(size.width, size.height);
    final converge = beat == StartupBeat.converge
        ? StartupTimeline.beatProgress(progress, beat)
        : 0.0;

    for (var index = 0; index < particleCount; index++) {
      final seed = index / particleCount;
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
          ..color = (index.isEven ? accent : Colors.white).withValues(
            alpha: alpha,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleFieldPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.beat != beat ||
        oldDelegate.accent != accent ||
        oldDelegate.particleCount != particleCount;
  }
}
