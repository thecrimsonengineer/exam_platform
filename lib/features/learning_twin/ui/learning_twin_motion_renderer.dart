import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import 'learning_twin_motion_controller.dart';
import 'learning_twin_motion_fallback.dart';
import 'learning_twin_motion_manifest.dart';
import 'learning_twin_motion_policy.dart';
import 'learning_twin_motion_state.dart';

class LearningTwinMotionRenderer extends StatefulWidget {
  const LearningTwinMotionRenderer({
    super.key,
    required this.state,
    this.size = 56,
    this.animationEnabled = true,
    this.decorative = false,
    this.compactCrop = true,
    this.semanticLabel = 'Naveed Learning Guide',
    this.eventKey,
    this.visible = true,
    this.compactSurface = false,
    this.compactMotionAllowed = true,
    this.developerForceStatic = false,
    this.developerForceAnimation = false,
    this.fallbackAssetPath,
    this.manifest,
    this.manifestLoader = const LearningTwinMotionManifestLoader(),
    this.controller,
    this.onCompleted,
    this.debugSurface = 'avatar',
  }) : assert(size > 0);

  final LearningTwinMotionState state;
  final double size;
  final bool animationEnabled;
  final bool decorative;
  final bool compactCrop;
  final String semanticLabel;
  final String? eventKey;
  final bool visible;
  final bool compactSurface;
  final bool compactMotionAllowed;
  final bool developerForceStatic;
  final bool developerForceAnimation;
  final String? fallbackAssetPath;
  final LearningTwinMotionManifest? manifest;
  final LearningTwinMotionManifestLoader manifestLoader;
  final LearningTwinMotionController? controller;
  final VoidCallback? onCompleted;
  final String debugSurface;

  @override
  State<LearningTwinMotionRenderer> createState() =>
      _LearningTwinMotionRendererState();
}

class _LearningTwinMotionRendererState extends State<LearningTwinMotionRenderer>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static final Map<String, Future<bool>> _assetAvailabilityCache =
      <String, Future<bool>>{};

  late final AnimationController _animationController;
  late LearningTwinMotionController _motionController;
  late bool _ownsMotionController;

  LearningTwinMotionManifestResult? _manifestResult;
  bool _appActive = true;
  bool _platformAnimationsDisabled = false;
  final Set<String> _availableAssetPaths = <String>{};
  final Set<String> _unavailableAssetPaths = <String>{};
  final Set<String> _loggedFallbackPaths = <String>{};
  String? _playbackToken;
  bool _rebuildScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(vsync: this)
      ..addStatusListener(_handleAnimationStatus);
    _bindMotionController(widget.controller);

    final manifest = widget.manifest;
    if (manifest != null) {
      _manifestResult = LearningTwinMotionManifestResult.valid(manifest);
    } else {
      _loadManifest();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _platformAnimationsDisabled =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _synchronizeMotion();
  }

  @override
  void didUpdateWidget(covariant LearningTwinMotionRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      _motionController.removeListener(_handleMotionControllerChanged);
      if (_ownsMotionController) {
        _motionController.dispose();
      }
      _bindMotionController(widget.controller);
    }

    if (oldWidget.manifest != widget.manifest ||
        oldWidget.manifestLoader != widget.manifestLoader) {
      final manifest = widget.manifest;
      if (manifest != null) {
        _manifestResult = LearningTwinMotionManifestResult.valid(manifest);
      } else {
        _manifestResult = null;
        _loadManifest();
      }
    }

    _synchronizeMotion();
  }

  void _bindMotionController(LearningTwinMotionController? external) {
    _ownsMotionController = external == null;
    _motionController = external ?? LearningTwinMotionController();
    _motionController.addListener(_handleMotionControllerChanged);
  }

  Future<void> _loadManifest() async {
    final result = await widget.manifestLoader.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _manifestResult = result;
    });
    _synchronizeMotion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final active = state == AppLifecycleState.resumed;
    if (_appActive == active) {
      return;
    }

    _appActive = active;
    if (active) {
      _motionController.setAppActive(true);
    } else {
      _animationController.stop(canceled: false);
      _motionController.setAppActive(false);
    }

    _scheduleRebuild();
    _synchronizeMotion();
  }

  void _handleMotionControllerChanged() {
    if (!mounted) {
      return;
    }
    _configurePlaybackForCurrent();
    _scheduleRebuild();
  }

  void _scheduleRebuild() {
    if (!mounted || _rebuildScheduled) {
      return;
    }

    _rebuildScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rebuildScheduled = false;
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _synchronizeMotion() {
    if (!mounted) {
      return;
    }

    final result = _manifestResult;
    final manifest = result?.manifest;
    final requestedDescriptor = manifest?.descriptorFor(widget.state);

    final decision = LearningTwinMotionPolicy.resolve(
      widget.state,
      LearningTwinMotionPolicyInput(
        animationEnabled: widget.animationEnabled,
        platformAnimationsDisabled: _platformAnimationsDisabled,
        visible: widget.visible,
        appActive: _appActive,
        manifestValid: result?.isValid ?? false,
        stateAvailable: requestedDescriptor != null,
        compactSurface: widget.compactSurface,
        compactMotionAllowed: widget.compactMotionAllowed,
        developerForceStatic: widget.developerForceStatic,
        developerForceAnimation: widget.developerForceAnimation,
      ),
    );

    if (!decision.animate || requestedDescriptor == null) {
      _animationController.stop(canceled: false);
      _motionController.pause();
      return;
    }

    final assetPath = requestedDescriptor.assetPath;
    if (_unavailableAssetPaths.contains(assetPath)) {
      _animationController.stop(canceled: false);
      _motionController.stopToIdle(
        idleDescriptor: manifest?.descriptorFor(LearningTwinMotionState.idle),
      );
      return;
    }

    if (!_availableAssetPaths.contains(assetPath)) {
      _preflightAsset(assetPath);
      _animationController.stop(canceled: false);
      _motionController.pause();
      return;
    }

    _motionController.request(
      requestedDescriptor,
      eventKey: widget.eventKey,
      forceReplay: widget.developerForceAnimation,
    );
    _configurePlaybackForCurrent();
  }

  Future<void> _preflightAsset(String assetPath) async {
    final available = await (_assetAvailabilityCache[assetPath] ??=
        _assetExists(assetPath));

    if (!mounted) {
      return;
    }

    if (available) {
      if (_availableAssetPaths.add(assetPath)) {
        _scheduleRebuild();
        _synchronizeMotion();
      }
      return;
    }

    if (_unavailableAssetPaths.add(assetPath)) {
      _logFallback(assetPath, 'asset_missing');
      _scheduleRebuild();
    }
  }

  static Future<bool> _assetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _configurePlaybackForCurrent() {
    final descriptor = _motionController.currentDescriptor;
    if (descriptor == null || !_motionController.isPlaying) {
      _animationController.stop(canceled: false);
      return;
    }

    final token =
        '${descriptor.state.manifestKey}:'
        '${_motionController.currentEventKey ?? ''}:'
        '${descriptor.assetPath}';

    if (_playbackToken == token && _animationController.isAnimating) {
      return;
    }

    _playbackToken = token;
    _animationController.duration = descriptor.duration;

    if (descriptor.loop) {
      _animationController.repeat();
    } else {
      _animationController.forward(from: 0);
    }
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) {
      return;
    }

    final manifest = _manifestResult?.manifest;
    final descriptor = _motionController.currentDescriptor;
    if (manifest == null || descriptor == null || descriptor.loop) {
      return;
    }

    _motionController.completeCurrent(
      idleDescriptor: manifest.descriptorFor(LearningTwinMotionState.idle),
    );
    widget.onCompleted?.call();
  }

  void _scheduleAssetFailure(String assetPath) {
    if (_unavailableAssetPaths.contains(assetPath)) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _unavailableAssetPaths.contains(assetPath)) {
        return;
      }

      setState(() {
        _unavailableAssetPaths.add(assetPath);
        _availableAssetPaths.remove(assetPath);
      });
      _assetAvailabilityCache[assetPath] = Future<bool>.value(false);
      _logFallback(assetPath, 'asset_load');
      final manifest = _manifestResult?.manifest;
      _animationController.stop(canceled: false);
      _motionController.stopToIdle(
        idleDescriptor: manifest?.descriptorFor(LearningTwinMotionState.idle),
      );
    });
  }

  void _logFallback(String assetPath, String reason) {
    if (!kDebugMode || !_loggedFallbackPaths.add(assetPath)) {
      return;
    }
    debugPrint(
      'LearningTwinMotion fallback: '
      'surface=${widget.debugSurface} '
      'state=${widget.state.manifestKey} '
      'reason=$reason',
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _manifestResult;
    final manifest = result?.manifest;
    final requestedDescriptor = manifest?.descriptorFor(widget.state);

    final decision = LearningTwinMotionPolicy.resolve(
      widget.state,
      LearningTwinMotionPolicyInput(
        animationEnabled: widget.animationEnabled,
        platformAnimationsDisabled: _platformAnimationsDisabled,
        visible: widget.visible,
        appActive: _appActive,
        manifestValid: result?.isValid ?? false,
        stateAvailable: requestedDescriptor != null,
        compactSurface: widget.compactSurface,
        compactMotionAllowed: widget.compactMotionAllowed,
        developerForceStatic: widget.developerForceStatic,
        developerForceAnimation: widget.developerForceAnimation,
      ),
    );

    final activeDescriptor =
        manifest?.descriptorFor(_motionController.currentState) ??
        requestedDescriptor;

    final activeAssetAvailable =
        activeDescriptor != null &&
        _availableAssetPaths.contains(activeDescriptor.assetPath);

    if (!decision.animate ||
        activeDescriptor == null ||
        !activeAssetAvailable ||
        _unavailableAssetPaths.contains(activeDescriptor.assetPath)) {
      return LearningTwinMotionFallback(
        assetPath:
            widget.fallbackAssetPath ??
            requestedDescriptor?.fallbackSvgPath ??
            learningTwinFallbackPathFor(widget.state),
        size: widget.size,
        decorative: widget.decorative,
        semanticLabel: widget.semanticLabel,
        compactCrop: widget.compactCrop,
      );
    }

    Widget visual = Lottie.asset(
      activeDescriptor.assetPath,
      controller: _animationController,
      animate: false,
      repeat: false,
      fit: BoxFit.contain,
      onLoaded: (_) {
        if (mounted) {
          _configurePlaybackForCurrent();
        }
      },
      errorBuilder: (context, error, stackTrace) {
        _scheduleAssetFailure(activeDescriptor.assetPath);
        return LearningTwinMotionFallback(
          assetPath:
              widget.fallbackAssetPath ?? activeDescriptor.fallbackSvgPath,
          size: widget.size,
          decorative: widget.decorative,
          semanticLabel: widget.semanticLabel,
          compactCrop: widget.compactCrop,
        );
      },
    );

    if (widget.compactCrop && widget.size <= 72) {
      visual = ClipRect(
        child: Transform.scale(
          scale: 1.75,
          alignment: Alignment.topCenter,
          child: visual,
        ),
      );
    }

    final framed = SizedBox.square(
      dimension: widget.size,
      child: ColoredBox(
        color: Theme.of(context).colorScheme.inverseSurface,
        child: visual,
      ),
    );

    if (widget.decorative) {
      return ExcludeSemantics(child: framed);
    }

    return Semantics(
      image: true,
      label: widget.semanticLabel,
      child: ExcludeSemantics(child: framed),
    );
  }

  @visibleForTesting
  static void clearAssetAvailabilityCacheForTesting() {
    _assetAvailabilityCache.clear();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _motionController.removeListener(_handleMotionControllerChanged);
    if (_ownsMotionController) {
      _motionController.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }
}
